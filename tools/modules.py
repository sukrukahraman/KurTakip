#!/usr/bin/env python3
"""Edit module wiring through the marker comments the templates ship with, so nobody hand-edits project.yml or
Package.swift (and gets the commas or indentation wrong).

Usage:
  modules.py register <project> <Module> [--app] [--tests-only]
        declare Packages/<Module> in project.yml and add its tests to the Staging scheme (the quality gate runs them);
        --app also links it into the app target (only for modules the app imports), --tests-only into AppTests
  modules.py depend  <project> <Module> <Dependency> [--tests]
        add a local package dependency (../<Dependency>) to Packages/<Module>/Package.swift;
        --tests adds it to the test target instead of the library target
  modules.py depend-remote <project> <Module> --url <git-url> --version <x.y.z> --package <name> --product <product> [--tests]
        add an exact-version remote package and one of its products
  modules.py add-app-package <project> --url <git-url> --version <x.y.z> --package <name> --product <P> [--product <P2>]
        link a remote package's products straight into the app target (Crashlytics, Remote Config glue)
  modules.py add-test-target <project> <Module>
        give a package that has none a test target (Tests/<Module>Tests/); write its first test straight away
  modules.py add-analytics-provider <project> <provider> [--version <x.y.z>]
        wire one analytics SDK into Packages/CoreAnalytics (the provider template must be rendered first):
        package dependency, the line in AnalyticsProviders.swift, and the Info.plist/xcconfig keys it reads.
        providers: firebase, adjust, appsflyer, mixpanel, amplitude, segment
  modules.py list <project>                              print the local packages found under Packages/

Markers (never delete them):
  project.yml:   '# <skill:packages>'   '# <skill:app-dependencies>'   '# <skill:test-dependencies>'
  Package.swift: '// <skill:package-deps>'  '// <skill:target-deps>'  '// <skill:test-deps>'
All edits are idempotent: running a command twice changes nothing the second time.
"""
import json
import os
import re
import sys


def die(message):
    sys.exit("modules.py: " + message)


def read(path):
    if not os.path.exists(path):
        die("%s not found" % path)
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def write(path, text):
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def insert_before_marker(text, marker, line, label):
    """Insert `line` (may span several lines) above the line holding `marker`, at the marker's indentation."""
    pattern = re.compile(r"^([ \t]*)%s[ \t]*$" % re.escape(marker), re.MULTILINE)
    match = pattern.search(text)
    if not match:
        die("marker %r missing in %s - was it deleted?" % (marker, label))
    indent = match.group(1)
    block = "".join(indent + part + "\n" for part in line.split("\n"))
    return text[:match.start()] + block + text[match.start():]


def block_before(text, marker, opener):
    """The text of the list that `marker` closes: from the nearest `opener` above it to the marker."""
    end = text.index(marker)
    return text[text.rfind(opener, 0, end):end]


def listed(text, marker, opener, line):
    """True when `line` is already in the list the marker closes (or anywhere, if this file has no marker)."""
    if marker not in text:
        return line in text
    return line in block_before(text, marker, opener)


def register(project, module, link_app, tests_only):
    path = os.path.join(project, "project.yml")
    text = read(path)
    package_dir = os.path.join(project, "Packages", module)
    if not os.path.isdir(package_dir):
        die("Packages/%s does not exist - render its template first" % module)
    if not re.search(r"^  %s:\s*$" % re.escape(module), text, re.MULTILINE):
        text = insert_before_marker(text, "# <skill:packages>", "%s:\n  path: Packages/%s" % (module, module), "project.yml")
    tests_line = "- package: %s/%sTests" % (module, module)
    if os.path.isdir(os.path.join(package_dir, "Tests")) and not listed(text, "# <skill:scheme-tests>", "targets:", tests_line):
        text = insert_before_marker(text, "# <skill:scheme-tests>", tests_line, "project.yml")
    dep_line = "- package: %s" % module
    for wanted, marker in ((link_app, "# <skill:app-dependencies>"), (tests_only, "# <skill:test-dependencies>")):
        if wanted and not listed(text, marker, "dependencies:", dep_line):
            text = insert_before_marker(text, marker, dep_line, "project.yml")
    write(path, text)
    print("registered %s%s%s" % (module, " +app" if link_app else "", " +app-tests" if tests_only else ""))


def package_file(project, module):
    return os.path.join(project, "Packages", module, "Package.swift")


def depend(project, module, dependency, tests):
    path = package_file(project, module)
    text = read(path)
    package_line = '.package(path: "../%s"),' % dependency
    if package_line not in text:
        text = insert_before_marker(text, "// <skill:package-deps>", package_line, path)
    target_line = '"%s",' % dependency
    marker = "// <skill:test-deps>" if tests else "// <skill:target-deps>"
    if not listed(text, marker, "[", target_line):
        text = insert_before_marker(text, marker, target_line, path)
    write(path, text)
    print("%s now depends on %s%s" % (module, dependency, " (tests)" if tests else ""))


def depend_remote(project, module, url, version, package, product, tests):
    path = package_file(project, module)
    text = read(path)
    package_line = '.package(url: "%s", exact: "%s"),' % (url, version)
    if url not in text:
        text = insert_before_marker(text, "// <skill:package-deps>", package_line, path)
    product_line = '.product(name: "%s", package: "%s"),' % (product, package)
    marker = "// <skill:test-deps>" if tests else "// <skill:target-deps>"
    if not listed(text, marker, "[", product_line):
        text = insert_before_marker(text, marker, product_line, path)
    write(path, text)
    print("%s now uses %s from %s@%s" % (module, product, package, version))


ANALYTICS_PROVIDERS = {
    "firebase": {
        "url": "https://github.com/firebase/firebase-ios-sdk", "package": "firebase-ios-sdk",
        "products": ["FirebaseAnalytics", "FirebaseCore"], "keys": ["FIREBASE_PLIST"],
        "line": 'FirebaseAnalyticsProvider(plistName: info["FIREBASE_PLIST"] as? String),',
    },
    "adjust": {
        "url": "https://github.com/adjust/ios_sdk", "package": "ios_sdk", "products": ["AdjustSdk"],
        "keys": ["ADJUST_APP_TOKEN", "ADJUST_EVENT_TOKENS", "ADJUST_ENVIRONMENT"],
        "line": 'AdjustAnalyticsProvider(appToken: info["ADJUST_APP_TOKEN"] as? String, '
                'eventTokens: info["ADJUST_EVENT_TOKENS"] as? String, '
                'isProduction: info["ADJUST_ENVIRONMENT"] as? String == "production"),',
    },
    "appsflyer": {
        "url": "https://github.com/AppsFlyerSDK/AppsFlyerFramework", "package": "AppsFlyerFramework",
        "products": ["AppsFlyerLib"], "keys": ["APPSFLYER_DEV_KEY", "APPSFLYER_APPLE_APP_ID"],
        "line": 'AppsFlyerAnalyticsProvider(devKey: info["APPSFLYER_DEV_KEY"] as? String, '
                'appleAppId: info["APPSFLYER_APPLE_APP_ID"] as? String),',
    },
    "mixpanel": {
        "url": "https://github.com/mixpanel/mixpanel-swift", "package": "mixpanel-swift", "products": ["Mixpanel"],
        "keys": ["MIXPANEL_TOKEN"], "line": 'MixpanelAnalyticsProvider(token: info["MIXPANEL_TOKEN"] as? String),',
    },
    "amplitude": {
        "url": "https://github.com/amplitude/Amplitude-Swift", "package": "Amplitude-Swift", "products": ["AmplitudeSwift"],
        "keys": ["AMPLITUDE_API_KEY"], "line": 'AmplitudeAnalyticsProvider(apiKey: info["AMPLITUDE_API_KEY"] as? String),',
    },
    "segment": {
        "url": "https://github.com/segmentio/analytics-swift", "package": "analytics-swift", "products": ["Segment"],
        "keys": ["SEGMENT_WRITE_KEY"], "line": 'SegmentAnalyticsProvider(writeKey: info["SEGMENT_WRITE_KEY"] as? String),',
    },
}
ENVIRONMENT_VALUES = {
    "ADJUST_ENVIRONMENT": {"Staging": "sandbox", "Production": "production"},
    "FIREBASE_PLIST": {"Staging": "GoogleService-Info-Staging", "Production": "GoogleService-Info-Production"},
}


def append_once(path, line):
    text = read(path)
    if re.search(r"^%s\b" % re.escape(line.split("=")[0].strip()), text, re.MULTILINE):
        return
    write(path, text.rstrip("\n") + "\n" + line + "\n")


def add_test_target(project, module):
    path = package_file(project, module)
    text = read(path)
    if ".testTarget(" in text:
        print("%s already has a test target" % module)
        return
    block = '        .testTarget(name: "%sTests", dependencies: ["%s"], swiftSettings: strict),\n' % (module, module)
    end = text.rfind("\n    ]\n)")
    if end == -1:
        die("cannot find the end of the targets array in %s" % path)
    write(path, text[:end + 1] + block + text[end + 1:])
    os.makedirs(os.path.join(project, "Packages", module, "Tests", module + "Tests"), exist_ok=True)
    print("%s now has a test target: add Tests/%sTests/<Something>Tests.swift" % (module, module))


def remembered_version(project, provider):
    """The version render_template.py --resolve stored, so callers need not copy it by hand."""
    path = os.path.join(project, ".claude", "render-vars.json")
    key = "%s_VERSION" % provider.upper()
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        if key in data:
            return data[key]
    die("no %s remembered: run render_template.py with --resolve %s first, or pass --version" % (key, provider))


def add_analytics_provider(project, provider, version):
    if provider not in ANALYTICS_PROVIDERS:
        die("unknown provider %r (known: %s)" % (provider, ", ".join(sorted(ANALYTICS_PROVIDERS))))
    spec = ANALYTICS_PROVIDERS[provider]
    for product in spec["products"]:
        depend_remote(project, "CoreAnalytics", spec["url"], version, spec["package"], product, False)
    factory = os.path.join(project, "Packages", "CoreAnalytics", "Sources", "CoreAnalytics", "AnalyticsProviders.swift")
    text = read(factory)
    if spec["line"] not in text:
        write(factory, insert_before_marker(text, "// <skill:providers>", spec["line"], factory))
    yml = os.path.join(project, "project.yml")
    for key in spec["keys"]:
        text = read(yml)
        if not re.search(r"^\s+%s:" % key, text, re.MULTILINE):
            write(yml, insert_before_marker(text, "# <skill:info-plist>", "%s: $(%s)" % (key, key), "project.yml"))
        append_once(os.path.join(project, "Config", "Base.xcconfig"), "%s =" % key)
        for env, value in ENVIRONMENT_VALUES.get(key, {}).items():
            append_once(os.path.join(project, "Config", "%s.xcconfig" % env), "%s = %s" % (key, value))
    print("analytics provider %s wired (keys: %s)" % (provider, ", ".join(spec["keys"]) or "none"))


def add_app_package(project, url, version, package, products):
    """Declare a remote package in project.yml and link some of its products into the app target."""
    path = os.path.join(project, "project.yml")
    text = read(path)
    if not re.search(r"^  %s:\s*$" % re.escape(package), text, re.MULTILINE):
        entry = "%s:\n  url: %s\n  exactVersion: %s" % (package, url, version)
        text = insert_before_marker(text, "# <skill:packages>", entry, "project.yml")
    for product in products:
        line = "- package: %s\n  product: %s" % (package, product)
        if not re.search(r"-\s+package:\s*%s\s*\n\s+product:\s*%s\b" % (re.escape(package), re.escape(product)), text):
            text = insert_before_marker(text, "# <skill:app-dependencies>", line, "project.yml")
    write(path, text)
    print("app links %s from %s@%s" % (", ".join(products), package, version))


def option(args, name):
    if name not in args:
        die("missing %s" % name)
    return args[args.index(name) + 1]


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    command, project = argv[1], argv[2]
    rest = argv[3:]
    flags = {a for a in rest if a.startswith("--")}
    if command == "register":
        register(project, rest[0], "--app" in flags, "--tests-only" in flags)
    elif command == "depend":
        depend(project, rest[0], rest[1], "--tests" in flags)
    elif command == "depend-remote":
        depend_remote(project, rest[0], option(rest, "--url"), option(rest, "--version"),
                      option(rest, "--package"), option(rest, "--product"), "--tests" in flags)
    elif command == "add-app-package":
        add_app_package(project, option(rest, "--url"), option(rest, "--version"), option(rest, "--package"),
                        [rest[i + 1] for i, a in enumerate(rest) if a == "--product"])
    elif command == "add-test-target":
        add_test_target(project, rest[0])
    elif command == "add-analytics-provider":
        version = option(rest, "--version") if "--version" in rest else remembered_version(project, rest[0])
        add_analytics_provider(project, rest[0], version)
    elif command == "list":
        root = os.path.join(project, "Packages")
        for name in sorted(os.listdir(root)) if os.path.isdir(root) else []:
            if os.path.exists(os.path.join(root, name, "Package.swift")):
                print(name)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
