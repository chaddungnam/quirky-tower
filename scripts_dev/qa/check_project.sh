#!/usr/bin/env bash
set -u

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

check_size() {
  local extension="$1"
  local warning_limit="$2"
  local failure_limit="$3"
  while IFS= read -r file; do
    local lines
    lines=$(wc -l < "$file")
    if (( lines > failure_limit )); then
      echo "FAIL size: ${file#$project_root/} has $lines lines (limit $failure_limit)"
      failed=1
    elif (( lines > warning_limit )); then
      echo "WARN size: ${file#$project_root/} has $lines lines (warning $warning_limit)"
    fi
  done < <(find "$project_root" -type f -name "*.$extension" -not -path '*/.git/*' -not -path '*/addons/*' -print)
}

check_size gd 500 800
check_size md 600 1200

if [[ ! -f "$project_root/docs/canonical/README.md" ]]; then
  echo "FAIL docs: missing docs/canonical/README.md"
  failed=1
fi

if [[ -d "$project_root/scripts/core" ]]; then
  while IFS= read -r match; do
    echo "FAIL core dependency: $match"
    failed=1
  done < <(rg -n 'extends[[:space:]]+(Node|Control)|AdMob|Billing|Supabase' "$project_root/scripts/core" -g '*.gd' || true)
fi

if [[ -f "$project_root/docs/canonical/README.md" ]]; then
  while IFS= read -r target; do
    [[ "$target" == http* ]] && continue
    target="${target%%#*}"
    [[ -z "$target" ]] && continue
    if [[ ! -e "$project_root/docs/canonical/$target" ]]; then
      echo "FAIL docs link: docs/canonical/$target"
      failed=1
    fi
  done < <(sed -nE 's/.*\]\(([^)]+)\).*/\1/p' "$project_root/docs/canonical/README.md")
fi

flock_test_output=$(/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$project_root" --script scripts_dev/qa/headless/flock_run_state_test.gd 2>&1)
flock_test_status=$?
printf '%s\n' "$flock_test_output"
if (( flock_test_status != 0 )) || grep -Eq 'SCRIPT ERROR|ERROR' <<<"$flock_test_output" || ! grep -Fxq 'PASS flock_run_state_test' <<<"$flock_test_output"; then
  echo "FAIL flock_run_state_test"
  failed=1
fi

if ! /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$project_root" --editor --quit; then
  echo "FAIL Godot import/parse"
  failed=1
fi

if (( failed != 0 )); then
  exit 1
fi

echo "PASS project structure"
