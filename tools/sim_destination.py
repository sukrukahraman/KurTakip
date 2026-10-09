#!/usr/bin/env python3
"""Pick the simulator the gate runs on and print its UDID (one line).

Usage: sim_destination.py [--min-ios 17.0] [--json]
Order of preference: an already booted iPhone on the newest runtime, then the newest iPhone on the newest runtime
at or above --min-ios. Honours GATE_DEVICE (a UDID or a device name) when set. Exit 1 when nothing fits.
Using the UDID (not a name) avoids xcodebuild's "multiple matching destinations" ambiguity.
"""
import json
import os
import re
import subprocess
import sys


def version_key(version):
    return [int(part) for part in re.findall(r"\d+", version)]


def main(argv):
    min_ios = argv[argv.index("--min-ios") + 1] if "--min-ios" in argv else "17.0"
    raw = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"], capture_output=True, text=True)
    if raw.returncode != 0:
        sys.exit("simctl failed: " + raw.stderr.strip())
    candidates = []
    for runtime, devices in json.loads(raw.stdout)["devices"].items():
        match = re.search(r"iOS-(\d+(?:-\d+)*)$", runtime)
        if not match:
            continue
        version = match.group(1).replace("-", ".")
        if version_key(version) < version_key(min_ios):
            continue
        for device in devices:
            if device.get("isAvailable", True) and device["name"].startswith("iPhone"):
                candidates.append({"udid": device["udid"], "name": device["name"], "ios": version,
                                   "booted": device["state"] == "Booted"})
    wanted = os.environ.get("GATE_DEVICE")
    if wanted:
        candidates = [c for c in candidates if wanted in (c["udid"], c["name"])]
    if not candidates:
        sys.exit("no available iPhone simulator for iOS >= %s%s (xcrun simctl list runtimes; Xcode > Settings > Components)"
                 % (min_ios, " matching GATE_DEVICE=" + wanted if wanted else ""))
    # prefer the standard "iPhone NN" over Pro Max/Plus/SE/Air/e variants only as a tie-break
    candidates.sort(key=lambda c: (version_key(c["ios"]), c["booted"], c["name"] == "iPhone 17" or c["name"].endswith("Pro")),
                    reverse=True)
    best = candidates[0]
    if "--json" in argv:
        print(json.dumps(best))
    else:
        print(best["udid"])


if __name__ == "__main__":
    main(sys.argv)
