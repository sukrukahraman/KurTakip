#!/usr/bin/env python3
"""Create and check String Catalogs (.xcstrings) without hand-editing JSON.

Usage:
  strings_tool.py set <catalog.xcstrings> <key> <lang>=<text> [<lang>=<text> ...]
      Creates the catalog and the key when missing; replaces the given languages and keeps the rest.
      Plural forms: <lang>.<category>=<text> with categories zero|one|two|few|many|other, e.g.
        strings_tool.py set noteslist.xcstrings "noteslist_count %lld" en.one="%lld note" en.other="%lld notes" tr.other="%lld not"
  strings_tool.py missing <Resources-dir> <lang,lang,...>
      Lists every key that lacks a translated value in one of the languages, per catalog. Exit 1 if anything is missing.
  strings_tool.py languages <Resources-dir>
      Prints the languages used across the catalogs.

Key rules (see references/rules/i18n.md): a catalog's file name is its table (`noteslist.xcstrings` -> table "noteslist"),
every key starts with that table name and an underscore, and a key with an interpolated value ends with its format
specifier (`noteslist_count %lld`, `profile_greeting %@`). Keys are marked "manual" so Xcode never flags them stale.
"""
import glob
import json
import os
import re
import sys

PLURAL_CATEGORIES = {"zero", "one", "two", "few", "many", "other"}


def load(path):
    if not os.path.exists(path):
        return {"sourceLanguage": "en", "strings": {}, "version": "1.0"}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def save(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    text = json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False, separators=(",", " : "))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text + "\n")


def unit(text):
    return {"stringUnit": {"state": "translated", "value": text}}


def cmd_set(path, key, assignments):
    table = os.path.splitext(os.path.basename(path))[0]
    if not re.match(r"^%s_[a-z0-9_]+( %%(lld|@|lf|d|f))*$" % re.escape(table), key):
        sys.exit("key %r must start with '%s_' and use lowercase snake_case "
                 "(an interpolated value adds its specifier after a space, e.g. 'x_count %%lld')" % (key, table))
    data = load(path)
    entry = data["strings"].setdefault(key, {"extractionState": "manual", "localizations": {}})
    entry["extractionState"] = "manual"
    plural = {}
    for assignment in assignments:
        if "=" not in assignment:
            sys.exit("expected <lang>=<text>, got %r" % assignment)
        lang, text = assignment.split("=", 1)
        if "." in lang:
            lang, category = lang.split(".", 1)
            if category not in PLURAL_CATEGORIES:
                sys.exit("unknown plural category %r" % category)
            plural.setdefault(lang, {})[category] = unit(text)
        else:
            entry["localizations"][lang] = unit(text)
    for lang, forms in plural.items():
        if "other" not in forms:
            sys.exit("plural forms for %r need an 'other' category" % lang)
        entry["localizations"][lang] = {"variations": {"plural": forms}}
    save(path, data)
    print("%s: %s -> %s" % (os.path.basename(path), key, ", ".join(sorted(entry["localizations"]))))


def has_value(localization):
    if not localization:
        return False
    if "stringUnit" in localization:
        unit_ = localization["stringUnit"]
        return unit_.get("state") == "translated" and bool(unit_.get("value", "").strip())
    forms = localization.get("variations", {}).get("plural", {})
    return "other" in forms and has_value(forms["other"])


def catalogs(directory):
    return sorted(glob.glob(os.path.join(directory, "*.xcstrings")))


def cmd_missing(directory, languages):
    missing = 0
    for path in catalogs(directory):
        data = load(path)
        for key, entry in sorted(data.get("strings", {}).items()):
            if entry.get("shouldTranslate") is False:
                continue
            for lang in languages:
                if not has_value(entry.get("localizations", {}).get(lang)):
                    print("%s: %r has no translated %s value" % (os.path.basename(path), key, lang))
                    missing += 1
    print("missing translations: %d" % missing)
    sys.exit(1 if missing else 0)


def cmd_languages(directory):
    found = set()
    for path in catalogs(directory):
        for entry in load(path).get("strings", {}).values():
            found.update(entry.get("localizations", {}))
    print(",".join(sorted(found)))


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    command = argv[1]
    if command == "set" and len(argv) >= 5:
        cmd_set(argv[2], argv[3], argv[4:])
    elif command == "missing" and len(argv) == 4:
        cmd_missing(argv[2], [lang for lang in argv[3].split(",") if lang])
    elif command == "languages":
        cmd_languages(argv[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
