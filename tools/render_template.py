#!/usr/bin/env python3
"""Copy a template tree into the project, replacing {{VAR}} in file contents and __VAR__ in file and folder names.

Usage:
  render_template.py <template-dir> <dest-dir> KEY=VALUE [KEY=VALUE ...] [--resolve firebase,mixpanel] [--force]

Typical first call (project template):
  render_template.py S/templates/project P BUNDLE_ID=com.example.notes APP_NAME="Notes" APP_PREFIX=Notes \\
      MIN_IOS=17.0 LANGUAGES=en,tr FIRST_FEATURE_PASCAL=NotesList APP_DESCRIPTION="Track your notes"

Values are remembered in <dest-dir>/.claude/render-vars.json, so later calls (modules, the app, features) only pass what
is new, for example `FEATURE_PASCAL=NotesList`. Values given on the command line win over remembered ones.

Derived automatically (never pass these unless you must override them):
  PROJECT_NAME          APP_PREFIX
  MIN_IOS_MAJOR         the major part of MIN_IOS, for `.iOS(.v17)`
  DEV_REGION            the first of LANGUAGES
  LOCALIZATIONS_YAML    `[en, tr]` from LANGUAGES
  DEVICE_FAMILY         "1" (iPhone); pass "1,2" for iPhone and iPad
  <KEY>_VERSION         with --resolve: the newest stable release of each package (VIEWINSPECTOR_VERSION is always set)

Existing files are never overwritten (listed as 'skip') unless --force. Placeholders still left in the output are
reported and make the script exit 1, so nothing half-rendered goes unnoticed.
"""
import json
import os
import re
import shutil
import subprocess
import sys

VAR = re.compile(r"\{\{([A-Z_]+)\}\}")
BINARY = {".png", ".webp", ".jpg", ".jpeg", ".heic", ".ttf", ".otf", ".pdf"}
HERE = os.path.dirname(os.path.abspath(__file__))
MEMORY = os.path.join(".claude", "render-vars.json")


def option(args, name):
    if name in args:
        index = args.index(name)
        value = args[index + 1]
        del args[index:index + 2]
        return value
    return None


def derive(values):
    if "LANGUAGES" in values:
        languages = [x.strip() for x in values["LANGUAGES"].strip("[]").split(",") if x.strip()]
        values.setdefault("DEV_REGION", languages[0])
        values["LOCALIZATIONS_YAML"] = "[%s]" % ", ".join(languages)
    if "MIN_IOS" in values:
        values["MIN_IOS_MAJOR"] = values["MIN_IOS"].split(".")[0]
    if "APP_PREFIX" in values:
        values.setdefault("PROJECT_NAME", values["APP_PREFIX"])
    values.setdefault("DEVICE_FAMILY", "1")


def resolve(keys):
    cmd = [sys.executable, os.path.join(HERE, "resolve_versions.py"), "--args"]
    if keys:
        cmd += ["--with", keys]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit("resolve_versions.py failed:\n%s%s" % (out.stdout, out.stderr))
    return dict(pair.split("=", 1) for pair in out.stdout.split())


def main():
    args = sys.argv[1:]
    force = "--force" in args
    args = [a for a in args if a != "--force"]
    keys = option(args, "--resolve")
    if len(args) < 2:
        sys.exit(__doc__)
    src, dst = os.path.abspath(args[0]), os.path.abspath(args[1])
    memory_path = os.path.join(dst, MEMORY)
    values = {}
    if os.path.exists(memory_path):
        with open(memory_path, encoding="utf-8") as fh:
            values.update(json.load(fh))
    values.update(dict(a.split("=", 1) for a in args[2:]))
    derive(values)
    if keys is not None or "VIEWINSPECTOR_VERSION" not in values:
        values.update(resolve(keys or ""))
    os.makedirs(os.path.dirname(memory_path), exist_ok=True)
    with open(memory_path, "w", encoding="utf-8") as fh:
        json.dump(values, fh, indent=2, sort_keys=True)

    leftovers = set()
    for dp, _, fns in os.walk(src):
        for fn in fns:
            if fn == ".DS_Store":
                continue
            s_path = os.path.join(dp, fn)
            rel = os.path.relpath(s_path, src)
            for key, value in values.items():
                rel = rel.replace("__%s__" % key, value)
            if rel.endswith(".tmpl"):
                rel = rel[:-5]
            d_path = os.path.join(dst, rel)
            if os.path.exists(d_path) and not force:
                print("skip   %s" % rel)
                continue
            os.makedirs(os.path.dirname(d_path), exist_ok=True)
            if os.path.splitext(fn)[1] in BINARY:
                shutil.copyfile(s_path, d_path)
            else:
                with open(s_path, encoding="utf-8") as fh:
                    text = fh.read()
                text = VAR.sub(lambda m: values.get(m.group(1), m.group(0)), text)
                leftovers.update(m.group(1) for m in VAR.finditer(text))
                with open(d_path, "w", encoding="utf-8") as fh:
                    fh.write(text)
                if os.access(s_path, os.X_OK):
                    os.chmod(d_path, 0o755)
            print("write  %s" % rel)
    if leftovers:
        print("UNRESOLVED placeholders: %s (pass them as KEY=VALUE)" % ", ".join(sorted(leftovers)))
        sys.exit(1)


if __name__ == "__main__":
    main()
