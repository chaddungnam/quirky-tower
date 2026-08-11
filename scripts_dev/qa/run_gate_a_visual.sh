#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
godot="/Applications/Godot.app/Contents/MacOS/Godot"
runner="res://scripts_dev/qa/runtime/capture_gate_a.gd"
evidence_dir="$project_root/qa_output/reboot_gate_a/after"
expected=(
  boot entry brawl_warning brawl_contact brawl_rebound chain_path chain_broken chain_strike
  collapse_crack collapse_pieces collapse_target collapse_reward choice result
)
stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/quirky-tower-gate-a.XXXXXX")"
log_file="$stage_dir/godot.log"
godot_pid=""

children_of() {
  local parent="$1"
  pgrep -P "$parent" 2>/dev/null || true
}

stop_owned_processes() {
  [[ -n "$godot_pid" ]] || return 0
  local child
  while IFS= read -r child; do
    [[ -n "$child" ]] && kill -TERM "$child" 2>/dev/null || true
  done < <(children_of "$godot_pid")
  kill -TERM "$godot_pid" 2>/dev/null || true
}

cleanup() {
  stop_owned_processes
  rm -rf "$stage_dir"
}
trap cleanup EXIT INT TERM

echo "Gate A baseline processes:"
ps -axo pid=,ppid=,stat=,lstart=,command= \
  | rg -i '(/Applications/Godot\.app/Contents/MacOS/Godot|godot-mcp|adb|gradle|lldb)' || true
echo "Gate A baseline listeners:"
for port in 6505 7777 $(seq 9080 9095) $(seq 9100 9115) $(seq 9200 9215); do
  lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
done

"$godot" \
  --path "$project_root" \
  --display-driver macos \
  --rendering-method mobile \
  --resolution 540x960 \
  --position 4960,-89 \
  --script "$runner" \
  -- --output-dir "$stage_dir" >"$log_file" 2>&1 &
godot_pid=$!
echo "Gate A Godot PID: $godot_pid"

deadline=$((SECONDS + 60))
while kill -0 "$godot_pid" 2>/dev/null; do
  if (( SECONDS >= deadline )); then
    echo "FAIL capture timeout after 60 seconds (PID $godot_pid)"
    exit 1
  fi
  sleep 0.25
done
set +e
wait "$godot_pid"
status=$?
set -e
godot_pid=""
cat "$log_file"
if (( status != 0 )) || rg -q 'SCRIPT ERROR|ERROR:' "$log_file"; then
  echo "FAIL Godot capture runner"
  exit 1
fi

actual="$(find "$stage_dir" -maxdepth 1 -type f -name '*.png' -exec basename {} .png \; | sort | tr '\n' ' ')"
wanted="$(printf '%s\n' "${expected[@]}" | sort | tr '\n' ' ')"
if [[ "$actual" != "$wanted" ]]; then
  echo "FAIL expected exactly 14 named PNGs"
  printf 'actual: %s\n' "$actual"
  exit 1
fi

for state in "${expected[@]}"; do
  dimensions="$(sips -g pixelWidth -g pixelHeight "$stage_dir/$state.png" 2>/dev/null)"
  rg -q 'pixelWidth: 1080' <<<"$dimensions" && rg -q 'pixelHeight: 2400' <<<"$dimensions" || {
    echo "FAIL $state.png is not 1080x2400"
    exit 1
  }
done
if [[ "$(shasum -a 256 "$stage_dir"/*.png | awk '{print $1}' | sort -u | wc -l | tr -d ' ')" != 14 ]]; then
  echo "FAIL capture PNGs are not visually unique"
  exit 1
fi

mkdir -p "$evidence_dir"
for state in "${expected[@]}"; do
  rm -f "$evidence_dir/$state.png.import"
done
rm -f "$project_root/scripts_dev/qa/runtime/capture_gate_a.gd.uid"
find "$evidence_dir" -maxdepth 1 -type f ! -name README.md \
  ! -name boot.png ! -name entry.png ! -name brawl_warning.png ! -name brawl_contact.png \
  ! -name brawl_rebound.png ! -name chain_path.png ! -name chain_broken.png \
  ! -name chain_strike.png ! -name collapse_crack.png ! -name collapse_pieces.png \
  ! -name collapse_target.png ! -name collapse_reward.png ! -name choice.png ! -name result.png \
  -print -quit | rg -q . && { echo "FAIL unrelated file in evidence directory"; exit 1; }
for state in "${expected[@]}"; do
  mv "$stage_dir/$state.png" "$evidence_dir/$state.png"
done

head_sha="$(git -C "$project_root" rev-parse HEAD)"
branch="$(git -C "$project_root" branch --show-current)"
godot_version="$(sed -n 's/^GATE_A_GODOT_VERSION=//p' "$log_file" | tail -1)"
renderer="$(sed -n 's/^GATE_A_RENDERER=//p' "$log_file" | tail -1)"
{
  printf '# Gate A final-code visual evidence\n\n'
  printf 'Legacy before images are `not directly comparable` because they show the removed Timing Ring loop, not equivalent reboot states.\n\n'
  printf -- '- HEAD: `%s`\n- Branch: `%s`\n- Godot: `%s`\n- Renderer: `%s`\n' "$head_sha" "$branch" "$godot_version" "$renderer"
  printf -- '- Platform: macOS desktop QA, offscreen window with an independent `SubViewport`\n'
  printf -- '- Locale: `ko`\n- Seed: `424242`\n- Physical viewport: `1080x2400`\n'
  printf -- '- Logical override: `720x1600`, stretch enabled; centered authored safe frame remains `720x1280`\n'
  printf -- '- Source: `res://scenes/app/main.tscn` instantiated once\n'
  printf -- '- Trigger: public Main/RunScreen paths and gameplay touch/drag/release through `SubViewport.push_input()`; transient world signals only pause settled or intentional intermediate captures\n'
  printf -- '- Scope: macOS-rendered greybox structure and readability evidence; not Android/iOS, touch feel, performance, fun, or final art-fidelity proof\n\n'
  printf '| State | Dimensions | SHA-256 |\n| --- | --- | --- |\n'
  for state in "${expected[@]}"; do
    hash="$(shasum -a 256 "$evidence_dir/$state.png" | awk '{print $1}')"
    printf '| `%s.png` | 1080x2400 | `%s` |\n' "$state" "$hash"
  done
} >"$evidence_dir/README.md"

echo "Gate A final processes:"
ps -axo pid=,ppid=,stat=,lstart=,command= \
  | rg -i '(/Applications/Godot\.app/Contents/MacOS/Godot|godot-mcp|adb|gradle|lldb)' || true
echo "Gate A final listeners:"
for port in 6505 7777 $(seq 9080 9095) $(seq 9100 9115) $(seq 9200 9215); do
  lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
done
echo "PASS Gate A visual capture"
