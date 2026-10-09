#!/usr/bin/env bash
# Quality gate run after every task.
# Usage: gate.sh <project-root> [<Module> ...]
#   gate.sh .                            whole project: one build, one test run over every package, all checks
#   gate.sh . CoreRepository FeatureX    only these modules (package folder names under Packages/, or `App`)
# Env: GATE_SKIP_DEAD_CODE=1  scaffold stage only: shared helpers get their first callers in Stage D
#      GATE_FINAL=1           Stage E: the project-wide test ratio is enforced
#      GATE_DEVICE=<udid|name> simulator to use (default: the newest iOS runtime's iPhone, see sim_destination.py)
#      GATE_LANGUAGE=<xx>     language the tests run in (default: the project's development language)
# Prints one result line per step, a `SUMMARY:` line that is reused in the commit message, and a final
# `GATE: PASS|FAIL`. Logs are in <project>/build/gate/. Exit 0 only when every step passed.
set -uo pipefail
ROOT="$(cd "${1:-.}" && pwd -P)"; shift || true
MODULES=("$@")
HERE="$(cd "$(dirname "$0")" && pwd)"   # works from the skill's scripts/ and from the project's tools/
LOG_DIR="$ROOT/build/gate"; mkdir -p "$LOG_DIR"
cd "$ROOT"

fail=0; summary=()
short() { sed -e "s#$ROOT/##g" -e "s#${ROOT#/private}/##g"; }
report() { # name status [log]
  local name="$1" status="$2" log="${3:-}"
  if [ "$status" = 0 ]; then echo "PASS  $name"; summary+=("$name ✓")
  else
    echo "FAIL  $name${log:+  (log: ${log#$ROOT/})}"; summary+=("$name ✗"); fail=1
    if [ -n "$log" ]; then
      { grep -E "error:|✘|^LOW|^VIOLATION|swiftformat:" "$log" | grep -v "CoreData:" | short | head -30; } | sed 's/^/      /'
    fi
  fi
}

# ---- project facts
PROJECT_YML="project.yml"
APP_PREFIX=""; PROJECT_NAME=""; MIN_IOS="17.0"; LANG_CODE="${GATE_LANGUAGE:-}"
if [ -f "$PROJECT_YML" ]; then
  PROJECT_NAME="$(sed -nE 's/^name: *([A-Za-z0-9_]+).*/\1/p' "$PROJECT_YML" | head -1)"
  APP_PREFIX="$(awk '/^schemes:/{inside=1; next} inside && /^  [A-Za-z0-9_]+-Staging:/{sub(/-Staging:.*/,""); gsub(/ /,""); print; exit}' "$PROJECT_YML")"
  MIN_IOS="$(sed -nE 's/^ *iOS: *"?([0-9.]+)"?.*/\1/p' "$PROJECT_YML" | head -1)"
  [ -z "$LANG_CODE" ] && LANG_CODE="$(sed -nE 's/^ *developmentLanguage: *([A-Za-z-]+).*/\1/p' "$PROJECT_YML" | head -1)"
fi
[ -z "$LANG_CODE" ] && LANG_CODE="$(grep -rhoE 'defaultLocalization: "[A-Za-z-]+"' Packages/*/Package.swift 2>/dev/null | head -1 | sed -E 's/.*"(.*)"/\1/')"
LANG_CODE="${LANG_CODE:-en}"
case "$LANG_CODE" in en) REGION=US ;; *) REGION="$(echo "$LANG_CODE" | tr '[:lower:]' '[:upper:]')" ;; esac
UDID="$(python3 "$HERE/sim_destination.py" --min-ios "${MIN_IOS:-17.0}")" || { echo "FAIL  simulator: $UDID"; exit 1; }
HAS_PROJECT=0; [ -f "$PROJECT_YML" ] && [ -n "$APP_PREFIX" ] && HAS_PROJECT=1
SCHEME="${APP_PREFIX}-Staging"
# SWIFT_SUPPRESS_WARNINGS=NO: Xcode silences warnings of packages the root package depends on, which would clash
# with the `.treatAllWarnings(as: .error)` every module sets.
BUILD_FLAGS=(-destination "id=$UDID" CODE_SIGNING_ALLOWED=NO SWIFT_SUPPRESS_WARNINGS=NO)
TEST_FLAGS=("${BUILD_FLAGS[@]}" -testLanguage "$LANG_CODE" -testRegion "$REGION" -enableCodeCoverage YES)

generate_project() { [ "$HAS_PROJECT" = 1 ] && xcodegen generate --quiet >"$LOG_DIR/0-xcodegen.log" 2>&1; }
module_dir() { echo "Packages/$1"; }
has_tests() { [ -n "$(find "$(module_dir "$1")/Tests" -name '*.swift' 2>/dev/null | head -1)" ]; }
all_packages() { ls -d Packages/*/ 2>/dev/null | xargs -n1 basename; }

run_build() { # logfile
  local log="$1" status=0
  : >"$log"
  if [ ${#MODULES[@]} -eq 0 ]; then
    if [ "$HAS_PROJECT" = 1 ]; then
      generate_project || { cat "$LOG_DIR/0-xcodegen.log" >>"$log"; return 1; }
      xcodebuild build -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" "${BUILD_FLAGS[@]}" -derivedDataPath build/dd/app >>"$log" 2>&1 || status=1
    else
      for m in $(all_packages); do ( cd "$(module_dir "$m")" && xcodebuild build -scheme "$m" "${BUILD_FLAGS[@]}" -derivedDataPath "$ROOT/build/dd/$m" ) >>"$log" 2>&1 || status=1; done
    fi
  else
    for m in "${MODULES[@]}"; do
      if [ "$m" = App ]; then
        generate_project || { cat "$LOG_DIR/0-xcodegen.log" >>"$log"; return 1; }
        xcodebuild build -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" "${BUILD_FLAGS[@]}" -derivedDataPath build/dd/app >>"$log" 2>&1 || status=1
      else
        ( cd "$(module_dir "$m")" && xcodebuild build -scheme "$m" "${BUILD_FLAGS[@]}" -derivedDataPath "$ROOT/build/dd/$m" ) >>"$log" 2>&1 || status=1
      fi
    done
  fi
  return $status
}

run_static() { # logfile
  local log="$1" status=0 paths=()
  : >"$log"
  if [ ${#MODULES[@]} -eq 0 ]; then for d in Packages App AppTests AppUITests; do [ -d "$d" ] && paths+=("$d"); done
  else for m in "${MODULES[@]}"; do [ "$m" = App ] && paths+=(App AppTests AppUITests) || paths+=("$(module_dir "$m")"); done; fi
  swiftformat "${paths[@]}" --lint >>"$log" 2>&1 || { status=1; echo "swiftformat: run 'swiftformat .' to fix formatting" >>"$log"; }
  swiftlint lint --strict --quiet "${paths[@]}" 2>&1 | short >>"$log"; [ "${PIPESTATUS[0]}" = 0 ] || status=1
  return $status
}

run_tests() { # logfile
  local log="$1" status=0 results=()
  : >"$log"
  rm -rf "$LOG_DIR"/*.xcresult
  if [ ${#MODULES[@]} -eq 0 ] && [ "$HAS_PROJECT" = 1 ]; then
    generate_project || return 1
    xcodebuild test -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" "${TEST_FLAGS[@]}" -derivedDataPath build/dd/app \
      -resultBundlePath "$LOG_DIR/all.xcresult" >>"$log" 2>&1 || status=1
    results+=("$LOG_DIR/all.xcresult")
    python3 "$HERE/coverage.py" "$ROOT" "${results[@]}" >>"$log" 2>&1 || status=1
  else
    local targets=()
    if [ ${#MODULES[@]} -eq 0 ]; then targets=($(all_packages)); else targets=("${MODULES[@]}"); fi
    for m in "${targets[@]}"; do
      if [ "$m" = App ]; then
        generate_project || return 1
        xcodebuild test -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" "${TEST_FLAGS[@]}" -only-testing:"${APP_PREFIX}Tests" \
          -derivedDataPath build/dd/app -resultBundlePath "$LOG_DIR/App.xcresult" >>"$log" 2>&1 || status=1
      elif has_tests "$m"; then
        ( cd "$(module_dir "$m")" && xcodebuild test -scheme "$m" "${TEST_FLAGS[@]}" -derivedDataPath "$ROOT/build/dd/$m" \
            -resultBundlePath "$LOG_DIR/$m.xcresult" ) >>"$log" 2>&1 || status=1
      else
        echo "no tests in $m (CoreModel-style modules without logic need none)" >>"$log"; continue
      fi
      python3 "$HERE/coverage.py" "$ROOT" "$LOG_DIR/$m.xcresult" --module "$m" >>"$log" 2>&1 || status=1
    done
  fi
  return $status
}

run_rules() { # logfile
  local log="$1" status=0
  : >"$log"
  if [ ${#MODULES[@]} -eq 0 ]; then
    local final=""; [ "${GATE_FINAL:-0}" = "1" ] && final="--final"
    python3 "$HERE/check_rules.py" "$ROOT" $final >>"$log" 2>&1 || status=1
  else
    for m in "${MODULES[@]}"; do
      local path="Packages/$m"; [ "$m" = App ] && path=App
      python3 "$HERE/check_rules.py" "$ROOT" --module "$path" >>"$log" 2>&1 || status=1
    done
  fi
  [ "$status" = 0 ] || sed -i.bak -E 's/^(VIOLATION)/VIOLATION/' "$log" && rm -f "$log.bak"
  return $status
}

step() { # name logfile function
  local name="$1" log="$2" fn="$3"
  "$fn" "$log"; report "$name" $? "$log"
}

step "build" "$LOG_DIR/1-build.log" run_build
step "static-analysis" "$LOG_DIR/2-static.log" run_static
step "tests+coverage" "$LOG_DIR/3-tests.log" run_tests
step "rules" "$LOG_DIR/4-rules.log" run_rules

if [ ${#MODULES[@]} -eq 0 ]; then
  if [ "${GATE_SKIP_DEAD_CODE:-0}" = "1" ]; then
    echo "SKIP  dead-code (scaffold stage: shared helpers get their first callers in Stage D)"; summary+=("dead-code skipped")
  else
    python3 "$HERE/dead_code_scan.py" "$ROOT" >"$LOG_DIR/5-dead-code.log" 2>&1
    status=$?; count="$(grep -cE '^(unused|test_only)' "$LOG_DIR/5-dead-code.log" || true)"
    if [ "$status" = 0 ]; then echo "PASS  dead-code"; summary+=("dead-code 0 ✓")
    else
      echo "FAIL  dead-code  ($count candidates; real dead code is deleted, a false positive gets a rules-ignore note in SPEC.md)"
      grep -E '^(unused|test_only)' "$LOG_DIR/5-dead-code.log" | head -20 | sed 's/^/      /'
      summary+=("dead-code $count ✗"); fail=1
    fi
  fi
fi

ratio="$( (python3 "$HERE/check_rules.py" "$ROOT" --json 2>/dev/null || true) | python3 -c 'import json,sys; print(json.load(sys.stdin)["test_ratio"]["ratio"])' 2>/dev/null || true)"
cov="$(grep -h '^coverage:' "$LOG_DIR/3-tests.log" 2>/dev/null | tail -1 | sed -E 's/coverage: ([0-9.]+)%.*/\1 % coverage/')"
echo "SUMMARY: $(IFS=' · '; echo "${summary[*]}") · test-ratio ${ratio:-n/a}${cov:+ · $cov}"
if [ "$fail" = 0 ]; then echo "GATE: PASS"; else echo "GATE: FAIL"; fi
exit $fail
