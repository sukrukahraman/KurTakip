#!/usr/bin/env python3
"""Resolve the newest STABLE release of every Swift package the generated app uses, from its git tags.

Stdlib only (runs on the macOS system Python 3). Sources: `git ls-remote --tags` on the package repository and the
package's own Package.swift at the candidate tag, so a release that needs a newer Swift than the installed one is
skipped in favour of the newest compatible one.

Usage:
  resolve_versions.py [--with key,key,...] [--json | --args]
    --json   toolchain facts, resolved versions, warnings (default)
    --args   KEY=VERSION pairs for scripts/render_template.py, e.g. VIEWINSPECTOR_VERSION=0.10.5
  resolve_versions.py --list    print the known package keys
Exit code 0 = everything resolved; 1 = some lookups failed (they are listed).
"""
import argparse
import json
import re
import subprocess
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor

# key -> (repository, package identity used in `.product(package:)`, products, is_test_only)
PACKAGES = {
    "viewinspector": ("https://github.com/nalexn/ViewInspector", "ViewInspector", ["ViewInspector"], True),
    "firebase": ("https://github.com/firebase/firebase-ios-sdk", "firebase-ios-sdk",
                 ["FirebaseAnalytics", "FirebaseCrashlytics", "FirebaseMessaging", "FirebaseRemoteConfig"], False),
    "adjust": ("https://github.com/adjust/ios_sdk", "ios_sdk", ["AdjustSdk"], False),
    "appsflyer": ("https://github.com/AppsFlyerSDK/AppsFlyerFramework", "AppsFlyerFramework", ["AppsFlyerLib"], False),
    "mixpanel": ("https://github.com/mixpanel/mixpanel-swift", "mixpanel-swift", ["Mixpanel"], False),
    "amplitude": ("https://github.com/amplitude/Amplitude-Swift", "Amplitude-Swift", ["AmplitudeSwift"], False),
    "segment": ("https://github.com/segmentio/analytics-swift", "analytics-swift", ["Segment"], False),
    "nuke": ("https://github.com/kean/Nuke", "Nuke", ["Nuke", "NukeUI"], False),
    "lottie": ("https://github.com/airbnb/lottie-ios", "lottie-ios", ["Lottie"], False),
    "snapshot": ("https://github.com/pointfreeco/swift-snapshot-testing", "swift-snapshot-testing", ["SnapshotTesting"], True),
}
ALWAYS = ["viewinspector"]
STABLE = re.compile(r"^v?(\d+)\.(\d+)(?:\.(\d+))?$")
MAX_CANDIDATES = 6


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def toolchain():
    xcode = run(["xcodebuild", "-version"]).stdout
    swift = run(["xcrun", "swift", "--version"]).stdout
    sdk = run(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"]).stdout.strip()
    return {
        "xcode": (re.search(r"Xcode (\S+)", xcode) or [None, ""])[1],
        "swift": (re.search(r"Swift version (\d+\.\d+(?:\.\d+)?)", swift) or [None, ""])[1],
        "ios_sdk": sdk,
    }


def version_tuple(text):
    return tuple(int(part) for part in re.findall(r"\d+", text))


def stable_tags(repo):
    out = run(["git", "ls-remote", "--tags", "--refs", repo])
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or "git ls-remote failed")
    tags = [line.split("refs/tags/")[1] for line in out.stdout.splitlines() if "refs/tags/" in line]
    found = [t for t in tags if STABLE.match(t)]
    # firebase-ios-sdk mixes `v8.15.0` and `11.0.0`: compare the numbers, never the spelling
    return sorted(found, key=lambda t: version_tuple(t.lstrip("v")), reverse=True)


def tools_version(repo, tag):
    """swift-tools-version of the package at `tag`, or None when it cannot be read."""
    slug = repo.replace("https://github.com/", "")
    url = "https://raw.githubusercontent.com/%s/%s/Package.swift" % (slug, tag)
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "ios-app-builder"}), timeout=20) as resp:
            head = resp.read(400).decode("utf-8", "replace")
    except Exception:
        return None
    match = re.search(r"swift-tools-version:\s*(\d+(?:\.\d+)*)", head)
    return match.group(1) if match else None


def resolve(key, installed_swift):
    repo, identity, products, test_only = PACKAGES[key]
    tags = stable_tags(repo)
    if not tags:
        raise RuntimeError("no stable tag found")
    skipped = []
    for tag in tags[:MAX_CANDIDATES]:
        needed = tools_version(repo, tag)
        if needed and installed_swift and version_tuple(needed) > version_tuple(installed_swift):
            skipped.append("%s needs Swift %s" % (tag, needed))
            continue
        return {"version": tag.lstrip("v"), "tag": tag, "url": repo, "package": identity, "products": products,
                "test_only": test_only, "skipped": skipped}
    raise RuntimeError("none of the %d newest tags builds with Swift %s (%s)" % (MAX_CANDIDATES, installed_swift, "; ".join(skipped)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--with", dest="extra", default="")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--args", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        print("\n".join(sorted(PACKAGES)))
        return
    wanted = list(dict.fromkeys(ALWAYS + [k.strip() for k in args.extra.split(",") if k.strip()]))
    unknown = [k for k in wanted if k not in PACKAGES]
    if unknown:
        sys.exit("unknown package key(s): %s (known: %s)" % (", ".join(unknown), ", ".join(sorted(PACKAGES))))
    tc = toolchain()
    results, errors, warnings = {}, {}, []

    def one(key):
        try:
            return key, resolve(key, tc["swift"]), None
        except Exception as exc:  # reported per key, never fatal for the others
            return key, None, str(exc)

    with ThreadPoolExecutor(max_workers=6) as pool:
        for key, value, error in pool.map(one, wanted):
            if error:
                errors[key] = error
            else:
                results[key] = value
                for note in value["skipped"]:
                    warnings.append("%s: newest release skipped (%s); using %s" % (key, note, value["version"]))
    if tc["xcode"] and int(tc["xcode"].split(".")[0]) < 26:
        warnings.append("Xcode %s is older than 26: the generated packages need Swift 6.2" % tc["xcode"])

    if args.args:
        print(" ".join("%s_VERSION=%s" % (k.upper(), v["version"]) for k, v in sorted(results.items())))
    else:
        print(json.dumps({"toolchain": tc, "packages": results, "errors": errors, "warnings": warnings}, indent=2))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
