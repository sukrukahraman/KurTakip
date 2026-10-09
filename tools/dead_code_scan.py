#!/usr/bin/env python3
"""Dead-code scan for generated iOS projects (DEAD-01..05, DEAD-07).

Usage: dead_code_scan.py <project-root> [--json]

Finds, by name, declarations that nothing references:
  unused_declaration      types, functions, properties and cases that are referenced nowhere
  test_only_declaration   production code that only tests reference (fakes in CoreTesting are exempt by design)
  unused_string           catalog keys no Swift file mentions (every language)
  unused_dependency       a Package.swift dependency whose module no source file of that package imports
  unused_module           a package nobody lists as a dependency and the app does not link

Why not Periphery: it cannot analyze local Swift packages that are only reachable through an XcodeGen project, which is
how these projects are laid out. This scanner works on names, so it never reports a declaration that something
mentions; the price is that two declarations sharing a name hide each other. Each finding is `high` confidence (the
name occurs nowhere else) or `medium` (it occurs only in comments' neighbours: tests or previews).

Output: one `KIND file:line symbol` line per finding, or JSON. Exit 1 when anything is reported.
Suppress a genuine false positive (reflection, macro-generated use) with `// rules-ignore: DEAD-01 <reason>`.
"""
import glob
import json
import os
import re
import sys
from collections import Counter

TYPE_KEYWORDS = r"struct|class|enum|actor|protocol|typealias"
DECL = re.compile(
    r"^\s*(?P<mods>(?:(?:public|internal|private|fileprivate|open|final|indirect|static|class|override|nonisolated|"
    r"@MainActor|@Observable|@Model|@ModelActor|@Sendable|mutating|lazy|weak|convenience|required|\(unsafe\)|\(set\))\s+)*)"
    r"(?P<kind>func|let|var|case|%s)\s+(?P<name>[A-Za-z_]\w*)" % TYPE_KEYWORDS
)
IDENT = re.compile(r"[A-Za-z_]\w*")
# names the language, the frameworks or macros use without a visible reference
IMPLICIT = {
    "body", "init", "deinit", "description", "debugDescription", "hash", "hashValue", "makeBody", "previews", "main",
    "CodingKeys", "encode", "decode", "id", "modelContext", "modelExecutor", "modelContainer", "unownedExecutor",
    "default", "value", "self", "Self", "Type", "Element", "Iterator", "next", "makeAsyncIterator", "makeUIView",
    "makeCoordinator", "updateUIView", "scene", "application", "urlSession", "userNotificationCenter", "isEmpty",
    "count", "startIndex", "endIndex", "index", "subscript", "rawValue", "allCases", "customMirror", "Failure", "Success",
    "versionIdentifier", "models", "schemas", "stages", "reduce", "map", "compactMap", "filter", "sorted", "contains",
    "callAsFunction", "wrappedValue", "projectedValue", "defaultValue", "reportMetrics", "observe",
}
SKIP_DIRS = {".build", "build", "DerivedData", ".git", ".swiftpm", "SourcePackages"}


def swift_files(root, pattern):
    for path in glob.glob(os.path.join(root, pattern), recursive=True):
        if not any(part in SKIP_DIRS for part in path.split(os.sep)):
            yield path


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def is_exempt(path):
    """Design tokens are a palette (not every token is used on day one); the router is the app's shared navigation API."""
    return "/CoreDesignSystem/Sources/CoreDesignSystem/Theme/" in path or path.endswith("App/Navigation/Router.swift")


def declarations(path):
    """Yield (line, kind, name) for members and top-level declarations; skips locals and extension witnesses."""
    raw = read(path).split("\n")
    code = strip_comments("\n".join(raw)).split("\n")
    stack = []  # block kinds: type | extension | func | other
    for number, line in enumerate(code, start=1):
        match = DECL.match(line)
        innermost = stack[-1] if stack else "top"
        pending_attr = raw[number - 2].strip() if number >= 2 else ""
        if match and innermost in ("top", "type") and "rules-ignore: DEAD-01" not in raw[number - 1] \
                and "override " not in match.group("mods") and not pending_attr.startswith(("@main", "@objc")):
            kind = match.group("kind")
            if kind in ("case",) and innermost != "type":
                kind = None
            if kind and not (kind in ("let", "var") and line.count("(") > line.count(")") + 3):
                yield number, kind, match.group("name"), line
        for char_index, char in enumerate(line):
            if char == "{":
                before = line[:char_index]
                if re.search(r"\b(%s)\b" % TYPE_KEYWORDS, before) and not re.search(r"\bfunc\b", before):
                    stack.append("type")
                elif re.search(r"\bextension\b", before):
                    stack.append("extension")
                elif re.search(r"\b(func|init|subscript|deinit)\b", before) or re.search(r"\b(var|let)\b[^=]*:\s*[^=]*$", before):
                    stack.append("func")
                else:
                    stack.append("other")
            elif char == "}" and stack:
                stack.pop()


def references(files):
    counts = Counter()
    for path in files:
        counts.update(IDENT.findall(strip_comments(read(path))))
    return counts


def scan(root):
    production = [p for p in swift_files(root, "Packages/*/Sources/**/*.swift") if "/CoreTesting/" not in p]
    production += list(swift_files(root, "App/**/*.swift"))
    testing = list(swift_files(root, "Packages/*/Tests/**/*.swift")) + list(swift_files(root, "AppTests/**/*.swift")) \
        + list(swift_files(root, "AppUITests/**/*.swift")) + list(swift_files(root, "Packages/CoreTesting/**/*.swift"))
    used_in_production = references(production)
    used_in_tests = references(testing)
    declared = Counter()
    found = []
    for path in production:
        for number, kind, name, line in declarations(path):
            declared[name] += 1
            if not is_exempt(path):
                found.append((path, number, kind, name))
    findings = []
    for path, number, kind, name in found:
        if name in IMPLICIT or name.startswith("_"):
            continue
        if used_in_production[name] > declared[name]:
            continue
        rel = os.path.relpath(path, root)
        if used_in_tests[name] > 0:
            findings.append({"kind": "test_only_declaration", "file": rel, "line": number, "symbol": name,
                             "confidence": "medium", "action": "used only by tests: delete it, or move it into CoreTesting"})
        else:
            findings.append({"kind": "unused_declaration", "file": rel, "line": number, "symbol": name,
                             "confidence": "high", "action": "nothing references it: delete it"})
    return findings


def string_findings(root):
    sources = "\n".join(read(p) for p in swift_files(root, "Packages/*/Sources/**/*.swift")) + "\n" + \
        "\n".join(read(p) for p in swift_files(root, "App/**/*.swift"))
    findings = []
    for catalog in glob.glob(os.path.join(root, "Packages/CoreLocalization/Sources/**/*.xcstrings"), recursive=True):
        with open(catalog, encoding="utf-8") as fh:
            keys = json.load(fh).get("strings", {})
        for key in keys:
            base = key.split(" ")[0]
            if not re.search(r'"%s[ "\\]' % re.escape(base), sources):
                findings.append({"kind": "unused_string", "file": os.path.relpath(catalog, root), "line": 1,
                                 "symbol": key, "confidence": "high",
                                 "action": "no Swift file looks this key up: delete it from every language"})
    return findings


def dependency_findings(root):
    findings, linked, listed = [], set(), set()
    project_yml = os.path.join(root, "project.yml")
    if os.path.exists(project_yml):
        text = read(project_yml)
        app_block = re.search(r"^  \w+:\n    type: application.*?(?=^  \w+:\n    type:|^schemes:)", text, re.MULTILINE | re.DOTALL)
        linked = set(re.findall(r"- package: (\w+)\s*$", app_block.group(0) if app_block else "", re.MULTILINE))
    for manifest in glob.glob(os.path.join(root, "Packages/*/Package.swift")):
        module = os.path.basename(os.path.dirname(manifest))
        text = read(manifest)
        deps = set(re.findall(r'\.package\(path: "\.\./(\w+)"\)', text))
        listed |= deps
        main_sources = "\n".join(read(p) for p in swift_files(os.path.dirname(manifest), "Sources/**/*.swift"))
        test_sources = "\n".join(read(p) for p in swift_files(os.path.dirname(manifest), "Tests/**/*.swift"))
        for dep in sorted(deps):
            if not re.search(r"\bimport\s+%s\b" % dep, main_sources) and not re.search(r"\bimport\s+%s\b" % dep, test_sources):
                findings.append({"kind": "unused_dependency", "file": os.path.relpath(manifest, root), "line": 1,
                                 "symbol": dep, "confidence": "high",
                                 "action": "no source file of %s imports %s: remove it from Package.swift (DEAD-03)" % (module, dep)})
    for manifest in glob.glob(os.path.join(root, "Packages/*/Package.swift")):
        module = os.path.basename(os.path.dirname(manifest))
        if module not in listed and module not in linked and module != "CoreTesting" and linked:
            findings.append({"kind": "unused_module", "file": os.path.relpath(manifest, root), "line": 1, "symbol": module,
                             "confidence": "medium", "action": "no package depends on it and the app does not link it"})
    return findings


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    root = os.path.abspath(sys.argv[1])
    findings = scan(root) + string_findings(root) + dependency_findings(root)
    if "--json" in sys.argv:
        print(json.dumps({"candidates": findings}, indent=1))
    else:
        for f in findings:
            print("%-22s %s:%s %s  (%s)" % (f["kind"], f["file"], f["line"], f["symbol"], f["action"]))
        print("dead_code_scan: %d finding(s)" % len(findings))
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
