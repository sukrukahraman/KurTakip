#!/usr/bin/env python3
"""Scorecard for a generated iOS project: eight categories, weighted to 100 (Stage E).

Usage: audit_score.py <project-root> [--out docs/audit] [--json]

This is the skill's own rubric, not an external audit. Each category starts at 10 and loses points for measurable
findings; the evidence for every deduction is printed next to the score. Target: overall >= 80 and every category >= 8.
Weights: Architecture 20, Security 15, Code Quality 15, Testing 15, Performance 10, Build Health 10, CI/CD 8, Deprecated APIs 7.

Inputs it gathers itself: check_rules.py findings, SwiftLint's JSON report, dead_code_scan.py candidates, the newest
coverage/test result bundles in build/gate, the CI and fastlane files, the hardening table in docs/SPEC.md, and the
pins in every Package.swift compared with the newest stable tags (needs network; skipped quietly without it).
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
WEIGHTS = {"Architecture": 20, "Security": 15, "Code Quality": 15, "Testing": 15,
           "Performance": 10, "Build Health": 10, "CI/CD": 8, "Deprecated APIs": 7}
GROUPS = {
    "Architecture": ("ARCH-", "CORE-02", "DS-", "UI-01", "UI-03", "DATA-01", "DATA-05"),
    "Security": ("SEC-", "HARD-07", "PRIV-"),
    "Code Quality": ("CORE-06", "CORE-07", "CORE-09", "CORE-10", "ERR-", "I18N-", "A11Y-", "RES-", "UI-04", "UI-05", "UI-06", "ENV-"),
    "Testing": ("TEST-",),
    "Performance": ("PERF-", "CONC-", "DATA-02", "DATA-03", "DATA-04"),
    "Build Health": ("BUILD-",),
    "Deprecated APIs": ("DEPR-",),
}


def run(cmd, cwd=None):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)


def clamp(value):
    return max(0.0, min(10.0, value))


def swift_files(root, pattern):
    return [p for p in glob.glob(os.path.join(root, pattern), recursive=True) if "/build/" not in p and "/.build/" not in p]


def kloc(root):
    lines = 0
    for path in swift_files(root, "Packages/*/Sources/**/*.swift") + swift_files(root, "App/**/*.swift"):
        with open(path, encoding="utf-8", errors="replace") as fh:
            lines += sum(1 for _ in fh)
    return max(lines / 1000.0, 0.1)


def gather(root):
    rules = run([sys.executable, os.path.join(HERE, "check_rules.py"), root, "--json", "--final"])
    findings = json.loads(rules.stdout) if rules.stdout.strip() else {"findings": [], "test_ratio": {"ratio": 0}}
    lint = run(["swiftlint", "lint", "--quiet", "--reporter", "json"], cwd=root)
    try:
        lint_findings = json.loads(lint.stdout) if lint.stdout.strip() else []
    except ValueError:
        lint_findings = []
    dead = run([sys.executable, os.path.join(HERE, "dead_code_scan.py"), root, "--json"])
    try:
        dead_candidates = json.loads(dead.stdout)["candidates"]
    except (ValueError, KeyError):
        dead_candidates = []
    results = glob.glob(os.path.join(root, "build", "gate", "*.xcresult"))
    coverage = None
    if results:
        cov = run([sys.executable, os.path.join(HERE, "coverage.py"), root, *results, "--json"])
        try:
            coverage = json.loads(cov.stdout)
        except ValueError:
            coverage = None
    return findings, lint_findings, dead_candidates, coverage


def matches(rule, prefixes):
    return any(rule.startswith(p) for p in prefixes)


def score_from_rules(findings, prefixes, per_violation=1.0, per_warning=0.25):
    hits = [f for f in findings if matches(f["rule"], prefixes)]
    violations = [f for f in hits if f["severity"] == "violation"]
    warnings = [f for f in hits if f["severity"] != "violation"]
    penalty = per_violation * len(violations) + per_warning * len(warnings)
    evidence = ["%s %s:%s %s" % (f["rule"], f["file"], f["line"], f["message"]) for f in (violations + warnings)[:5]]
    return penalty, evidence, len(violations) + len(warnings)


def hardening_present(root):
    def text(path):
        p = os.path.join(root, path)
        return open(p, encoding="utf-8", errors="replace").read() if os.path.exists(p) else ""

    sources = "\n".join(open(p, encoding="utf-8", errors="replace").read()
                        for p in swift_files(root, "Packages/*/Sources/**/*.swift") + swift_files(root, "App/**/*.swift"))
    project = text("project.yml")
    prod = text("Config/Production.xcconfig")
    return {
        "HARD-01 pinning": bool(re.search(r"^API_CERT_PINS\s*=\s*sha256/", prod, re.MULTILINE)),
        "HARD-02 encryption at rest": "KeychainSecureStore" in sources or "SecItemAdd" in sources,
        "HARD-03 release hardening": "STRIP_INSTALLED_PRODUCT: YES" in project and "ENABLE_TESTABILITY: NO" in project,
        "HARD-04 App Attest": "DCAppAttestService" in sources,
        "HARD-05 capture protection": "isCaptured" in sources or "scenePhase" in sources,
        "HARD-06 biometric step-up": "LAContext" in sources,
        "HARD-07 signing secrets": not glob.glob(os.path.join(root, "**", "*.p12"), recursive=True),
        "HARD-08 dependency scan": os.path.exists(os.path.join(root, ".github/workflows/dependency-scan.yml")),
    }


def applies(root):
    spec = os.path.join(root, "docs", "SPEC.md")
    result = {}
    if os.path.exists(spec):
        for line in open(spec, encoding="utf-8"):
            m = re.match(r"\|\s*(\d)\s*\|[^|]*\|\s*(yes|N/A)", line, re.IGNORECASE)
            if m:
                result[int(m.group(1))] = m.group(2).lower() == "yes"
    return result


def stale_packages(root):
    stale, checked = [], 0
    for manifest in glob.glob(os.path.join(root, "Packages", "*", "Package.swift")):
        for url, version in re.findall(r'\.package\(url:\s*"([^"]+)",\s*exact:\s*"([^"]+)"', open(manifest).read()):
            checked += 1
            out = run(["git", "ls-remote", "--tags", "--refs", url])
            tags = [t.split("refs/tags/")[1].lstrip("v") for t in out.stdout.splitlines() if "refs/tags/" in t]
            stable = [t for t in tags if re.fullmatch(r"\d+(\.\d+){1,2}", t)]
            if not stable:
                continue
            newest = max(stable, key=lambda t: [int(x) for x in t.split(".")])
            if int(newest.split(".")[0]) > int(version.split(".")[0]):
                stale.append("%s %s (newest %s)" % (url.rsplit("/", 1)[-1], version, newest))
    return stale, checked


def build_scorecard(root):
    findings, lint, dead, coverage = gather(root)
    items = findings["findings"]
    size = kloc(root)
    categories = {}

    def record(name, score, evidence):
        categories[name] = {"score": round(clamp(score), 1), "weight": WEIGHTS[name], "evidence": evidence or ["no findings"]}

    for name in ("Architecture", "Security", "Code Quality", "Testing", "Performance", "Build Health", "Deprecated APIs"):
        penalty, evidence, count = score_from_rules(items, GROUPS[name], per_violation=1.5 if name != "Deprecated APIs" else 0.0)
        if name == "Architecture":
            big = [f for f in items if f["rule"] == "CORE-02" and "500" in f["message"]]
            penalty += 2 * len(big)
            record(name, 10 - penalty, evidence)
        elif name == "Security":
            present = hardening_present(root)
            required = applies(root)
            missing = [k for i, (k, v) in enumerate(present.items(), start=1) if not v and required.get(i, i in (2, 3, 7, 8))]
            evidence = evidence + (["hardening missing: %s" % ", ".join(missing)] if missing else [])
            score = 10 - penalty - 1.0 * len(missing)
            if any(k.startswith(("HARD-01", "HARD-02", "HARD-03")) for k in missing) and len(missing) >= 3:
                score = min(score, 5)
            record(name, score, evidence)
        elif name == "Code Quality":
            lint_density = len(lint) / size
            dead_high = [d for d in dead if d["confidence"] == "high"]
            dead_note = ["dead code: %d candidate(s)" % len(dead)] if dead else []
            lint_note = ["SwiftLint: %.1f findings per KLOC" % lint_density] if lint else []
            record(name, 10 - penalty - min(3, lint_density) - 0.5 * len(dead_high), evidence + dead_note + lint_note)
        elif name == "Testing":
            ratio = findings["test_ratio"]["ratio"]
            ratio_penalty = max(0.0, (0.5 - ratio) * 10) if ratio < 0.5 else 0.0
            cov_notes, cov_penalty = [], 0.0
            if coverage:
                low = {k: v for k, v in coverage["modules"].items() if v < 80}
                cov_penalty = 1.5 * len(low)
                cov_notes = ["coverage below 80%%: %s" % ", ".join("%s %.0f%%" % kv for kv in low.items())] if low else []
            has_ui_tests = bool(swift_files(root, "AppUITests/*.swift"))
            record(name, 10 - penalty - ratio_penalty - cov_penalty - (0 if has_ui_tests else 1),
                   evidence + ["test/source ratio %.2f" % ratio] + cov_notes + ([] if has_ui_tests else ["no UI smoke test"]))
        elif name == "Performance":
            stale, checked = stale_packages(root)
            record(name, 10 - penalty - 1.0 * len(stale), evidence + (["stale packages: %s" % "; ".join(stale)] if stale else []))
        elif name == "Build Health":
            record(name, 10 - penalty - min(3, len(lint) / size), evidence)
        else:  # Deprecated APIs: share of files touching deprecated symbols
            files = len(swift_files(root, "Packages/*/Sources/**/*.swift") + swift_files(root, "App/**/*.swift")) or 1
            touched = len({f["file"] for f in items if f["rule"].startswith("DEPR-")})
            share = 100.0 * touched / files
            score = 10 if share < 1 else 8 if share < 3 else 6 if share < 6 else 4 if share < 10 else 2
            record(name, score, ["%.1f%% of files use deprecated or legacy APIs" % share] + evidence)

    ci = [
        (".github/workflows/ci.yml", 4, "PR gate"), (".github/workflows/release.yml", 2, "release automation"),
        (".github/workflows/dependency-scan.yml", 1, "dependency scan"), (".github/dependabot.yml", 1, "dependabot"),
        ("fastlane/Fastfile", 2, "fastlane lanes"),
    ]
    got = [(label, pts) for path, pts, label in ci if os.path.exists(os.path.join(root, path))]
    record("CI/CD", sum(p for _, p in got), ["have: " + ", ".join(label for label, _ in got)] +
           ["missing: " + ", ".join(label for path, _, label in ci if not os.path.exists(os.path.join(root, path)))]
           if len(got) < len(ci) else ["have: " + ", ".join(label for label, _ in got)])

    overall = sum(c["score"] * c["weight"] for c in categories.values()) / 10.0
    band = "Excellent" if overall >= 90 else "Healthy" if overall >= 80 else "Needs work" if overall >= 60 else "Poor"
    return {"overall": round(overall, 1), "band": band, "categories": categories,
            "target_met": overall >= 80 and all(c["score"] >= 8 for c in categories.values())}


def render_markdown(card):
    lines = ["# Scorecard", "", "**Overall: %.1f / 100 (%s)**%s" % (card["overall"], card["band"], "" if card["target_met"] else " - target not met"),
             "", "| Category | Score | Weight | Evidence |", "|---|---|---|---|"]
    for name, c in card["categories"].items():
        lines.append("| %s | %.1f | %d | %s |" % (name, c["score"], c["weight"], "<br>".join(c["evidence"][:4]).replace("|", "/")))
    lines += ["", "Target: overall >= 80 and every category >= 8. Rubric: scripts/audit_score.py (weights follow the Android skill's audit)."]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    parser.add_argument("--out", default="docs/audit")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = os.path.realpath(args.root)
    card = build_scorecard(root)
    out_dir = os.path.join(root, args.out)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "scorecard.json"), "w") as fh:
        json.dump(card, fh, indent=2)
    with open(os.path.join(out_dir, "scorecard.md"), "w") as fh:
        fh.write(render_markdown(card))
    print(json.dumps(card, indent=2) if args.json else render_markdown(card))
    sys.exit(0 if card["target_met"] else 1)


if __name__ == "__main__":
    main()
