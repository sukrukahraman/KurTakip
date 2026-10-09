#!/usr/bin/env python3
"""Line coverage of the logic in each module, read from one or more .xcresult bundles (TEST-03).

Usage:
  coverage.py <project-root> <result.xcresult> [<result.xcresult> ...] [--module CoreRepository ...]
              [--threshold 80] [--json]

A module is a package under Packages/ (or the app's own `App/` folder, reported as `App`). Only *logic* counts, the same
way coverage tools usually skip UI code: files that declare a SwiftUI `body` or a `#Preview`, `@main` entry points and preview
data are excluded, and so is a composition root that carries a `// coverage:exclude <reason>` comment (the factory
that wires concrete types together, which only a running app exercises). `--module` limits the check to the modules the gate was asked
about (coverage reports also contain the dependencies a test run built). Exit 1 when a module is below the threshold.
"""
import argparse
import json
import os
import re
import subprocess
import sys

VIEW_MARKERS = re.compile(r"var\s+body\s*:\s*some\s+(?:View|Scene)|#Preview|^@main\b", re.MULTILINE)
EXCLUDED_NAMES = re.compile(r"PreviewData\.swift$|^Package\.swift$")
EXCLUDE_MARKER = "coverage:exclude"


def run_xccov(result):
    out = subprocess.run(["xcrun", "xccov", "view", "--report", "--json", result], capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit("xccov failed for %s: %s" % (result, out.stderr.strip()))
    return json.loads(out.stdout)


def module_of(root, path):
    rel = os.path.relpath(os.path.realpath(path), root).replace(os.sep, "/")
    match = re.match(r"Packages/([^/]+)/Sources/", rel)
    if match:
        return match.group(1)
    if rel.startswith("App/"):
        return "App"
    return None


def is_logic_file(path):
    if EXCLUDED_NAMES.search(os.path.basename(path)):
        return False
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
            return not VIEW_MARKERS.search(text) and EXCLUDE_MARKER not in text
    except OSError:
        return False


def collect(root, results):
    """file path -> (covered, executable): the best number reported for the file across targets and bundles."""
    files = {}
    for result in results:
        for target in run_xccov(result).get("targets", []):
            for entry in target.get("files", []):
                path = entry["path"]
                covered, executable = entry["coveredLines"], entry["executableLines"]
                if path not in files or covered > files[path][0]:
                    files[path] = (covered, executable)
    return files


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    parser.add_argument("results", nargs="+")
    parser.add_argument("--module", action="append", default=[])
    parser.add_argument("--threshold", type=float, default=80.0)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    root = os.path.realpath(args.root)
    modules = {}
    for path, (covered, executable) in collect(root, args.results).items():
        module = module_of(root, path)
        if module is None or (args.module and module not in args.module) or not is_logic_file(path):
            continue
        data = modules.setdefault(module, {"covered": 0, "executable": 0, "files": {}})
        data["covered"] += covered
        data["executable"] += executable
        data["files"][os.path.relpath(os.path.realpath(path), root)] = (covered, executable)

    report, failed = {}, False
    for module, data in sorted(modules.items()):
        if data["executable"] == 0:
            continue
        percent = 100.0 * data["covered"] / data["executable"]
        report[module] = round(percent, 1)
        if percent < args.threshold:
            failed = True
            if not args.json:
                print("LOW  %-22s %5.1f%% (< %.0f%%)" % (module, percent, args.threshold))
                worst = sorted(data["files"].items(), key=lambda kv: kv[1][0] / max(kv[1][1], 1))[:3]
                for name, (covered, executable) in worst:
                    print("       %-70s %d/%d lines" % (name, covered, executable))
        elif not args.json:
            print("ok   %-22s %5.1f%%" % (module, percent))
    for module in args.module:
        if module not in report:
            if not args.json:
                print("--   %-22s no logic lines to measure" % module)
    if args.json:
        print(json.dumps({"threshold": args.threshold, "modules": report, "ok": not failed}))
    total_covered = sum(d["covered"] for d in modules.values())
    total_exec = sum(d["executable"] for d in modules.values())
    if not args.json and total_exec:
        print("coverage: %.1f%% of logic lines (%d/%d)" % (100.0 * total_covered / total_exec, total_covered, total_exec))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
