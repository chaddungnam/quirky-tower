# Drumstack Gate 0 First Turn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the independent `drumstack-battle` repository, finish one reviewable Duck Guard asset vertical slice, and prove one deterministic public turn from boot to enemy hit, with portable standards, reproducible QA, export exclusion, 2400×1080 evidence, and clean Local shutdown.

**Architecture:** Serializable Dictionaries plus pure `RefCounted` modules own state, grid legality, command resolution, and the first bot response. Godot scenes translate public input into commands and render the event ledger; one Duck Guard Blender source owns the cel3D model, rig, animation, expressions, and 2D derivatives. Cloud owns file work/static/pure tests, while bounded Local batches own Blender/Godot visual checkpoints, isolated MCP, runtime, capture, export inspection, and cleanup.

**Tech Stack:** Git/GitHub, Godot 4.7 stable, GDScript, JSON, Bash, Blender GLB 2.0, Godot MovieWriter, community Godot Asset Library `Godot MCP/CLI`.

## Global Constraints

- New repo: `https://github.com/chaddungnam/drumstack-battle`; Local: `/Users/junheechoi/projects/houseduck/drumstack_battle`. Preserve `quirky_tower`; Git handoff only, no project ZIP.
- Scope: one Duck Guard, one 11×9 vertical-slice arena, one tile/UI/VFX set, one training bot, and `boot → village → bot match → move → basic → enemy hit` only.
- Logical `1600×720`, QA `2400×1080`, central critical safe frame `1280×720`.
- Exact result: Duck `[2,4] → [3,4]`, bot `[4,4]`, damage `86`, bot HP `314/400`, Duck shield `50`, seed `424242`.
- Gate 0 command uses the canonical envelope: `{schema_version, command_id, kind, actor_id, move_path, skill_id, target_tile, authority_elapsed_ms}`. Core has no Node/UI/Tween/audio/network/SDK dependency.
- Duck: HP `960`, ATK `90`, DEF `42`, SPD `78`, MOV `3`; basic power `1150` milli, adjacent single, shield `50`. Training bot: HP `400`, DEF `20`. The core contract's integer `round_half_up` produces damage `86`.
- A0 is a grey silhouette checkpoint. A1–A4 then deliver the one approved Duck model, rig, six expressions, required clips, head hold→catch-up, cel material, three skills/hit/KO VFX, AT-readable arena/tile UI, and GLB-derived full/profile/queue 2D images. No other hero or second arena is made.
- Native Godot only. No Context7, second MCP, behavior/state plugin, Dialogic, PhantomCamera, GUT/GdUnit, FMOD/Wwise, Supabase SDK, ads, billing, or StoreKit.
- MCP candidate: Asset Library asset `5367`, version `0.8.0`, `asset-library` commit `14259444dc44a039c659d8f1cb5378e4f88cf42d`, archive SHA `2842e02eec8d18a849c6ab97fbdfc6de6623e96e0e3c66305e9101acd506e459`. Fallback upstream tag `v0.7.2` archive SHA `283dbce06c8ff773f9adae9de5150da544fcd5cee055a78c1067af45f9d113cd` only if isolated 0.8.0 validation fails.
- Committed `project.godot`: MCP disabled, no MCP autoload. Every export excludes `addons/godot_mcp/**`; PCK scan must find zero MCP paths/names.
- Size warn/fail: GD `400/700 lines`; MD `500 lines or 80KB / 900 or 160KB`; JSON/CSV `100/250KB`; HTML master `140/220KB`; tests `500/800 lines`.
- Static, Headless, Runtime, Visual, Human, Device evidence never substitute for one another. macOS is not Android/iPhone proof.
- Track exact agent-owned PID/children. Quit → wait ≤5s → exact TERM → exact KILL last. Never `pkill Godot` or `killall`.
- Follow-up only: full match, 3v3, other nine heroes, final art/audio/VFX, Supabase/PvP/ranking/story/shop/stamina/BM, Android/iOS, device/store proof.

---

## Target File Map

```text
AGENTS.md, THIRD_PARTY.md, project.godot, export_presets.cfg
docs/standards/{three standards,SHARED_STANDARDS.sha256}
docs/canonical/{README,work_state,DECISION_REGISTER,FEATURE_TEST_MAP,qa,DUCK_GUARD_ASSET_TRUTH}.md
data/drumstack/{schemas,heroes,scenarios}/**
scripts/core/battle/{battle_state,grid_rules,battle_rules,bot_policy}.gd
art_source/drumstack/{characters,environments,ui}/**
assets/drumstack/{characters,environments,materials,ui,vfx}/**; themes/drumstack/**
resources/drumstack/**
scenes/{app,outgame,drumstack}/**; scripts/{app,outgame,game/battle}/**
scripts_dev/{qa,tools,art}/**; qa_output/{duck_guard_asset,gate_0_first_turn}/**
```

### Git handoff preflight

At every Cloud ↔ Local boundary, the receiving checkout must run the same four checks before task commands. A dirty checkout stops; ZIP/manual copies are forbidden.

```bash
test -z "$(git status --short)"
git fetch origin
git switch codex/gate-0-first-turn
git merge --ff-only origin/codex/gate-0-first-turn
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/codex/gate-0-first-turn)"
git rev-parse HEAD  # record as the task input SHA
```

### Task 1: New Repository, Standards, and Foundation

**Execution:** Local Git in the clean spec worktree for tag/repo creation; the user's dirty `quirky_tower` root stays untouched. Cloud-safe file work afterward.

**Files:**
- Create: `AGENTS.md`, `.editorconfig`, `.gitattributes`, `.gitignore`, `project.godot`, `icon.svg`, `THIRD_PARTY.md`
- Create: `assets/fonts/DoHyeon-Regular.ttf`, `assets/fonts/DOHYEON_LICENSE.txt`
- Create: `docs/standards/house_duck_{development,asset_art,test_case}_standard.md`, `docs/standards/SHARED_STANDARDS.sha256`
- Create: `docs/canonical/{README,work_state,DECISION_REGISTER,FEATURE_TEST_MAP,qa}.md`, `qa_output/.gdignore`, `qa_output/.gitkeep`

**Interfaces:** Produces private repo with `main`, `develop`, `codex/gate-0-first-turn`; Cloud reads standards without the parent workspace.

- [ ] **Step 1: RED and legacy safety tag**

```bash
drumstack_legacy_repo=/Users/junheechoi/projects/houseduck/quirky_tower/.worktrees/drumstack-master-spec
drumstack_repo=/Users/junheechoi/projects/houseduck/drumstack_battle
test ! -e "$drumstack_repo"
git -C "$drumstack_legacy_repo" fetch origin
test -z "$(git -C "$drumstack_legacy_repo" status --short)"
test "$(git -C "$drumstack_legacy_repo" rev-parse HEAD)" = "$(git -C "$drumstack_legacy_repo" rev-parse '@{upstream}')"
git -C "$drumstack_legacy_repo" tag -a quirky-tower-gate-a-final -m "Quirky Tower safety point before Drumstack split"
git -C "$drumstack_legacy_repo" push origin refs/tags/quirky-tower-gate-a-final
```

Expected: new foundation assertion is RED; the clean, pushed spec worktree is tagged and the user's dirty root is unchanged. If tag exists, verify its SHA instead of recreating it.

- [ ] **Step 2: Initialize and restore only approved Git sources**

```bash
mkdir -p "$drumstack_repo" && cd "$drumstack_repo" && git init -b main
git remote add legacy https://github.com/chaddungnam/quirky-tower.git
git fetch legacy refs/tags/quirky-tower-gate-a-final:refs/tags/quirky-tower-gate-a-final
git restore --source=refs/tags/quirky-tower-gate-a-final -- \
  .editorconfig .gitattributes assets/fonts/DoHyeon-Regular.ttf assets/fonts/DOHYEON_LICENSE.txt \
  docs/drumstack docs/superpowers/specs/2026-08-11-drumstack-3d-asset-vertical-slice-design.md \
  docs/superpowers/specs/2026-08-11-drumstack-core-implementation-contract.md \
  docs/superpowers/plans/2026-08-11-drumstack-gate-0-first-turn.md
```

Expected: no reboot runtime, `flock_*`, old scene, or old QA evidence.

- [ ] **Step 3: Add portable standards and exact lock**

Copy the three shared files byte-for-byte:

```bash
mkdir -p docs/standards
install -m 0644 /Users/junheechoi/projects/houseduck/shared/standards/house_duck_development_standard.md docs/standards/
install -m 0644 /Users/junheechoi/projects/houseduck/shared/standards/house_duck_asset_art_standard.md docs/standards/
install -m 0644 /Users/junheechoi/projects/houseduck/shared/standards/house_duck_test_case_standard.md docs/standards/
```

`SHARED_STANDARDS.sha256` is:

```text
81e06e507d77dc8db8950c428400779175018a6d2b5e943f65e14c78670b2685  house_duck_development_standard.md
029d6a8a7b7b107d05cfd952b37b364c97a00f115b2f661866dae248ae54469e  house_duck_asset_art_standard.md
d1d7e4ff719f9db8a794f4acedd5163757c5877e033dc5927e9c57c46f6f5bff  house_duck_test_case_standard.md
```

`AGENTS.md` requires reading order development → asset → test → canonical, Ponytail before dependencies, Superpowers for material work, before/after visual proof, evidence separation, Git handoff, and exact PID cleanup. Project exceptions live only in `docs/canonical/qa.md`.

- [ ] **Step 4: Add exact project settings and GREEN**

`project.godot` sets name `Drumstack Battle`, main `res://scenes/app/main.tscn`, features `4.7` + `Mobile`, logical viewport `1600×720`, desktop window override `1200×540`, `canvas_items`, aspect `expand`, handheld landscape orientation, Mobile renderer, `[editor_plugins] enabled=PackedStringArray()`, and no `[autoload]`. QA alone renders an exact `2400×1080` SubViewport.

```bash
(cd docs/standards && shasum -a 256 -c SHARED_STANDARDS.sha256)
! rg -n 'flock_|MCPGameInspector|MCPGameInput' project.godot scenes scripts scripts_dev 2>/dev/null
git diff --check
git add AGENTS.md .editorconfig .gitattributes .gitignore project.godot icon.svg THIRD_PARTY.md \
  assets/fonts docs/standards docs/canonical docs/drumstack docs/superpowers qa_output/.gdignore qa_output/.gitkeep
git commit -m "chore: establish Drumstack repository foundation"
gh repo create chaddungnam/drumstack-battle --private --source=. --remote=origin --push
git switch -c develop && git push -u origin develop
git switch -c codex/gate-0-first-turn
```

Expected: three `OK` hashes; initial commit on `main`; feature branch based on `develop`.

### Task 2: Static, Headless, Local, and Process Guards

**Execution:** Cloud.

**Files:**
- Create: `scripts_dev/qa/{run_qa,check_static,run_headless,run_local,run_visual}.sh`
- Create: `scripts_dev/qa/lib/process_guard.sh`
- Create: `scripts_dev/qa/tests/{static_guard,process_guard}_test.sh`

**Interfaces:** `run_qa.sh static|headless|import|runtime|visual|export`; `run_visual.sh --scope NAME` is the generic exact-PID capture wrapper extended by each scope; `static` never launches Godot; Local modes own exact process trees.

- [ ] **Step 1: RED tests**

Static fixtures cover size bytes/lines, standard SHA, broken links, duplicate decision/TC ID, invalid JSON, forbidden core dependency, enabled MCP/autoload, missing export filter, and old runtime paths. Process fixture starts owned and unrelated `sleep 20` PIDs and proves only owned PID stops.

```bash
bash scripts_dev/qa/tests/static_guard_test.sh
bash scripts_dev/qa/tests/process_guard_test.sh
```

Expected: FAIL because guards are absent.

- [ ] **Step 2: Implement split and GREEN**

`process_guard.sh` records baseline and spawned PID/children/cwd plus listeners `9080-9095`, `9100-9115`, `9200-9215`; it uses normal quit, 5s wait, exact TERM/KILL, never broad matching.

```bash
bash scripts_dev/qa/tests/static_guard_test.sh
bash scripts_dev/qa/tests/process_guard_test.sh
bash scripts_dev/qa/run_qa.sh static
git diff --check
git add scripts_dev/qa docs/canonical/qa.md
git commit -m "test: add split QA and process guards" && git push -u origin codex/gate-0-first-turn
```

Expected: `PASS static_guard_test`, `PASS process_guard_test`, `PASS static`; no Godot launched.

### Task 3: Isolated Asset Library MCP and Export Exclusion

**Execution:** One bounded Local shell does download, checksum, isolated Godot 4.7 validation, vendor copy, static/export-config checks, commit, cleanup, and push. No temp addon crosses Cloud↔Local.

**Files:**
- Create: `scripts_dev/tools/validate_godot_mcp.sh`, `addons/godot_mcp/**`, `export_presets.cfg`, `scripts_dev/qa/check_release_export.sh`
- Modify: `THIRD_PARTY.md`

**Interfaces:** `validate_godot_mcp.sh ADDON_DIR EXPECTED_VERSION` passes only on parse/enable/localhost query/clean quit; export guard rejects MCP path/autoload/server strings.

- [ ] **Step 1: RED, fetch, and checksum**

```bash
bash scripts_dev/qa/run_qa.sh static  # expected: MCP provenance/export preset missing
drumstack_mcp_tmp=$(mktemp -d)
trap 'rm -rf "$drumstack_mcp_tmp"' EXIT
curl -fsSL -o "$drumstack_mcp_tmp/mcp.zip" \
  https://github.com/regiellis/godot-mcp-go/archive/14259444dc44a039c659d8f1cb5378e4f88cf42d.zip
printf '%s  %s\n' 2842e02eec8d18a849c6ab97fbdfc6de6623e96e0e3c66305e9101acd506e459 \
  "$drumstack_mcp_tmp/mcp.zip" | shasum -a 256 -c -
unzip -q "$drumstack_mcp_tmp/mcp.zip" -d "$drumstack_mcp_tmp/unpacked"
```

Expected: checksum `OK`; plugin version `0.8.0`. Record Asset Library `https://godotengine.org/asset-library/asset/5367`, Community, MIT. Steps 1–3 remain in this same shell so the temp path is never treated as a handoff artifact.

- [ ] **Step 2: Isolated Local validation and explicit fallback**

```bash
bash scripts_dev/tools/validate_godot_mcp.sh \
  "$drumstack_mcp_tmp/unpacked/godot-mcp-go-14259444dc44a039c659d8f1cb5378e4f88cf42d/project/addons/godot_mcp" 0.8.0
```

Expected: `PASS godot_mcp isolated version=0.8.0 residual_processes=0 residual_listeners=0`. The script uses `mktemp -d`, enables only that temp project, runs one CLI `project info` or equivalent HTTP initialize/query, and removes it. On failure only: restore `addons/godot_mcp` from `quirky-tower-gate-a-final`, verify `0.7.2`, validate identically, and record the 0.8.0 failure plus `selected=0.7.2`. Never patch vendor files.

- [ ] **Step 3: Vendor, exclude, GREEN, commit**

For 0.8.0 run `mkdir -p addons && cp -R "$drumstack_mcp_tmp/unpacked/godot-mcp-go-14259444dc44a039c659d8f1cb5378e4f88cf42d/project/addons/godot_mcp" addons/`; fallback instead runs `git restore --source=refs/tags/quirky-tower-gate-a-final -- addons/godot_mcp`. `Gate0 QA Pack` excludes `addons/godot_mcp/**`, `art_source/**`, `qa_output/**`, `scripts_dev/**`, `docs/**`; project plugin stays disabled and autoload absent. `THIRD_PARTY.md` records version, source, commit/SHA, license, validation, and fallback decision.

```bash
bash scripts_dev/qa/run_qa.sh static
bash scripts_dev/qa/run_qa.sh export
git diff --check
git add addons/godot_mcp THIRD_PARTY.md export_presets.cfg scripts_dev/tools scripts_dev/qa/check_release_export.sh
git commit -m "chore: pin validated Godot MCP 0.8.0" && git push
```

Expected: `PASS release_export_guard addon_files=0 autoloads=0`. Fallback commit message ends `0.7.2 fallback`.

### Task 4: Pure Schemas and Deterministic First Turn

**Execution:** Cloud-preferred; one short Local headless fallback if Cloud lacks Godot 4.7.

**Files:**
- Create: `data/drumstack/schemas/{hero,scenario,battle_state,command,event}.schema.json`
- Create: `data/drumstack/heroes/{duck_guard,training_bot}.json`, `data/drumstack/scenarios/gate_0_first_turn.json`
- Create: `scripts/core/battle/{battle_state,grid_rules,battle_rules,bot_policy}.gd`
- Create: `scripts_dev/qa/headless/{schema_contract,first_turn_rules,bot_policy}_test.gd`

**Interfaces:** Use the field names, ordering, integer math, and event envelopes from `docs/superpowers/specs/2026-08-11-drumstack-core-implementation-contract.md`. `BattleState.load_scenario/validate`, `GridRules.legal_move_paths/is_adjacent`, `BattleRules.validate/apply -> {ok,state,events,error}`, `BotPolicy.choose_command(state,actor_id,seed)`.

- [ ] **Step 1: RED exact contract**

```gdscript
var command := {"schema_version":1, "command_id":"c_0001", "kind":"ACTION",
    "actor_id":"a_duck", "move_path":[[2,4],[3,4]],
    "skill_id":"DUCK_BASIC", "target_tile":[4,4], "authority_elapsed_ms":1000}
```

Assert ordered events `ACTION_STARTED, MOVE_STEP, SKILL_USED, DAMAGE_APPLIED, SHIELD_APPLIED, ACTION_ENDED`, `86/314/50`, identical state/event hashes on repeat, and stable non-mutating errors for invalid path/range, occupied tile, wrong actor, and duplicate command ID. `schema_contract_test` also proves: the exact two-unit state passes as `gate-0-first-turn-v1`; the same state fails as `gate-a-v1`; and any unit↔gauge ID mismatch fails. Friendly-target validation belongs to the six-unit Gate A fixture because Gate 0 intentionally has one unit per team.

```bash
bash scripts_dev/qa/run_headless.sh schema_contract_test first_turn_rules_test bot_policy_test
```

Expected: FAIL naming missing core scripts.

- [ ] **Step 2: Minimal implementation and GREEN**

Use deep-copied Dictionaries and integer tile arrays. Damage uses the core contract's integer `round_half_up`; floats are forbidden. The two-unit `gate-0-first-turn-v1` fixture keeps every required BattleState key but is explicitly not a valid six-unit Gate A match. Bot uses the same legal list and returns deterministic guard at seed `424242`. Implement only schema/hash, explicit path, adjacent basic, shield, event order, and the turn state needed by this fixture; full 3v3, score, status/cooldown coverage, save, server envelope, and 10k remain Gate A and cannot be marked complete here.

```bash
bash scripts_dev/qa/run_qa.sh static
bash scripts_dev/qa/run_headless.sh schema_contract_test first_turn_rules_test bot_policy_test
git diff --check
git add data/drumstack scripts/core/battle scripts_dev/qa/headless
git commit -m "test: define deterministic Gate 0 battle contracts" && git push
```

Expected: `PASS first_turn_rules_test damage=86 shield=50`; bot `deterministic=1 illegal=0`.

### Task 5: Duck Guard A0–A4 Asset Truth Kit

**Execution:** Cloud contracts/export checks; bounded Local Blender/Godot batches at each visual stop. First-turn scene work does not start until A4 and owner review pass.

**Files:**
- Create: `docs/canonical/DUCK_GUARD_ASSET_TRUTH.md`, `scripts_dev/art/export_duck_guard_vertical_slice.py`
- Create: `art_source/drumstack/characters/hero_duck_guard/hero_duck_guard.blend`, `art_source/drumstack/environments/arena_service_rooftop_01/arena_service_rooftop_01.blend`
- Create: `assets/drumstack/characters/hero_duck_guard/hero_duck_guard.glb`, `assets/drumstack/environments/arena_service_rooftop_01/arena_service_rooftop_01.glb`, `assets/drumstack/ui/derivatives/hero_duck_guard/**`
- Create: `art_source/drumstack/ui/battle_house_duck_v1/**`, `assets/drumstack/ui/battle_house_duck_v1/**`, `assets/drumstack/materials/{shaders,*.tres}`
- Create: `assets/drumstack/vfx/tiles/tile_overlay.gdshader`, `themes/drumstack/battle_house_duck_v1.tres`
- Create: `resources/drumstack/{asset_manifest.schema,asset_manifest,characters/hero_duck_guard_animation_events}.json`, `resources/drumstack/contracts/{glb_character_import_v1,glb_environment_import_v1}.json`, `resources/drumstack/profiles/{derivative_hero_v1,camera_battle_20x9,world_mobile_mid,world_portrait_v1}.*`
- Create: `scenes/drumstack/battle/actors/hero_duck_guard.tscn`, `scenes/drumstack/battle/arenas/arena_service_rooftop_01.tscn`, `scenes/drumstack/vfx/hero_duck_guard/**`, `scenes/drumstack/asset_gallery/duck_guard_gallery.tscn`
- Create: `scenes/drumstack/battle/tiles/tile_overlay.tscn`, `scenes/drumstack/ui/battle/{battle_hud,bird_speech_bubble}.tscn`
- Create: `scripts_dev/qa/headless/asset_truth_test.gd`, `scripts_dev/qa/runtime/duck_guard_gallery_test.gd`
- Create: `qa_output/duck_guard_asset/{a0_blockout,a1_source,a2_import,a3_map_ui,a4_runtime}/**`

**Interfaces:** The approved asset contract owns exact bones, sockets, clips, markers, material channels, camera, grid, VFX, derivatives, budgets, and manifest. The export script validates and renders the deliberately modeled `.blend`; it does not procedurally invent a final character or paint generated textures.

- [ ] **Step 1: RED truth test and A0 silhouette stop**

Assert one hero/arena, source/runtime provenance, no GLB camera/light, and exact hashes. Model the grey Duck Guard and arena blockout, then render the fixed `front / 3-4 / side / back / move arc / basic contact` board plus eight-view turntable. A0 passes only when the user can read duck, tank, broad tail/duck butt, shield, joints, and Project K-like front/side/back mass consistency. Rejected A0 is revised before rigging.

```bash
bash scripts_dev/qa/run_headless.sh asset_truth_test  # RED
blender --background --python scripts_dev/art/export_duck_guard_vertical_slice.py -- --stage a0
bash scripts_dev/qa/run_headless.sh asset_truth_test  # A0 contract GREEN
# Show the fixed board and eight-view turntable to the user and record Passed/Blocked.
# If Blocked, revise A0 and repeat; A1 rigging and the commit below are forbidden.
git add docs/canonical/DUCK_GUARD_ASSET_TRUTH.md scripts_dev/art art_source resources/drumstack \
  qa_output/duck_guard_asset/a0_blockout
git commit -m "art: establish Duck Guard A0 silhouette" && git push
```

- [ ] **Step 2: A1 source and A2 Godot import**

Finish the cel3D source under the existing silhouette: exact skeleton/sockets, six expressions, all required clips, head hold→catch-up, scarf/shield secondary motion, 1024 albedo/mask, and modular rooftop arena materials/colliders. Build basic/active/signature/hit VFX from native Godot particles/mesh. Derive 400×800 full, 256/128 profile, and 96 queue images from the approved GLB; shop art remains deferred.

```bash
blender --background --python scripts_dev/art/export_duck_guard_vertical_slice.py -- --stage a1
bash scripts_dev/qa/run_qa.sh import
bash scripts_dev/qa/run_headless.sh asset_truth_test
```

Expected: exact bone/socket/clip/marker/material/manifest/import checks PASS; source and imported poses match; residual Blender/Godot 0. Any missing skin, clip, expression, socket, or derivative blocks runtime work.

- [ ] **Step 3: A3/A4 gallery, motion, and visual review**

The public gallery cycles neutral/focus/assertive/hit/uneasy/victory; idle/move/turn; basic/active/signature; guard/hit/push/KO/victory; four VFX; tile idle/move/range/danger/occupied; normal and Reduce Motion cameras. A3 also renders the exact four-action HUD (`basic/active/signature/guard`), selected/cooldown/disabled states, vertical `EXECUTE/CANCEL` at 96 logical px, and the bird speech bubble plus long German/Arabic fallback without covering HP, range, prediction, or action buttons. Capture stable contact frames and the bird head-hold measurements. The owner review times one public `select → move → range → target → result` sequence and records whether all five states were read within 3 seconds; a miss blocks A3. No screenshot substitutes for direct Godot playback.

```bash
bash scripts_dev/qa/run_local.sh runtime --script scripts_dev/qa/runtime/duck_guard_gallery_test.gd
bash scripts_dev/qa/run_visual.sh --scope duck_guard_asset
# Show the turntable and Godot gallery; record explicit Passed/Blocked in ASSET_TRUTH.
# If Blocked, revise A1-A4 and repeat; the commit below and Task 6 are forbidden.
git add art_source assets/drumstack themes/drumstack resources/drumstack scenes/drumstack scripts_dev/qa \
  qa_output/duck_guard_asset docs/canonical/DUCK_GUARD_ASSET_TRUTH.md
git commit -m "feat: complete Duck Guard asset vertical slice" && git push
```

Expected: A1–A4 P0/P1 findings 0, same-camera blockout→source→import comparison, six expressions readable, three skills/hit/KO causal, head stabilization within contract, no generated-image approval evidence, and explicit owner `Passed` already present in the committed truth file. If review remains `Blocked`, no A4 commit is made. Chicken/Pigeon and Task 6 remain blocked.

### Task 6: One Public First Turn

**Execution:** Cloud implementation; one Local runtime check after assembly.

**Files:**
- Create: `scenes/app/{main,boot}.tscn`, `scripts/app/{main,boot}.gd`
- Create: `scenes/outgame/village_shell.tscn`, `scripts/outgame/village_shell.gd`
- Create: `scenes/drumstack/battle/gate_0_first_turn.tscn`
- Create: `scripts/game/battle/{first_turn_controller,first_turn_view}.gd`
- Create: `scripts_dev/qa/headless/main_scene_contract_test.gd`, `scripts_dev/qa/runtime/public_first_turn_test.gd`

**Interfaces:** `Main.show_village/start_gate_0_match/return_to_village`; controller submits one command and emits events; view renders state/events without calculating damage.

Precondition: Task 5 A4 and owner review are current. The battle scene reuses its approved Duck wrapper, arena, tile material, camera profile, expressions, speech bubble, and VFX; it does not make grey replacement assets.

- [ ] **Step 1: RED public route**

Tests require project settings, no MCP autoload, one active route, and public state IDs `boot,village,turn_start,move_preview,move_committed,basic_preview,contact,enemy_hit,first_turn_complete`.

```bash
bash scripts_dev/qa/run_headless.sh main_scene_contract_test
bash scripts_dev/qa/run_local.sh runtime --script scripts_dev/qa/runtime/public_first_turn_test.gd
```

Expected: FAIL on missing scenes/signals.

- [ ] **Step 2: Implement minimal understandable flow**

Boot holds `0.35s`; village shows only `BOT MATCH` and `Gate 0 · First Turn`. Battle shows board, Duck, red bot, actor/HP, one `BASIC`, and `덕 대장: 한 칸 다가가서 부리방패!`. Input: Duck → `[3,4]` → BASIC → bot `[4,4]` → vertical `EXECUTE` over `CANCEL`. Resolve locks input; movement uses `move_loop` for `0.36s`, then the approved `basic_beak_shield` clip runs `0.88s` including anticipation, 2-frame contact, result, and recovery. Show `-86`, `314/400`, shield `50`, then hold `FIRST TURN COMPLETE` through `1.45s` and expose `BACK TO VILLAGE`. Camera axis never changes; zoom ≤110%; Reduce Motion has no camera transform change.

- [ ] **Step 3: GREEN and commit**

```bash
bash scripts_dev/qa/run_qa.sh static
bash scripts_dev/qa/run_headless.sh main_scene_contract_test first_turn_rules_test
bash scripts_dev/qa/run_local.sh runtime --script scripts_dev/qa/runtime/public_first_turn_test.gd
git diff --check
git add project.godot scenes/app scenes/outgame scenes/drumstack/battle/gate_0_first_turn.tscn \
  scripts/app scripts/outgame scripts/game scripts_dev/qa/headless/main_scene_contract_test.gd \
  scripts_dev/qa/runtime/public_first_turn_test.gd
git commit -m "feat: add public Duck Guard first turn" && git push
```

Expected: `PASS public_first_turn route=boot,village,bot_match damage=86 shield=50`; runtime errors 0; residual process/listener 0.

### Task 7: 2400×1080 Visual, Video, and Export Proof

**Execution:** One bundled Local batch on MacBook Air M2.

**Files:**
- Create: `data/qa/gate_0_visual_states.json`, `scripts_dev/qa/runtime/capture_gate_0_first_turn.gd`
- Modify: `scripts_dev/qa/run_visual.sh`
- Create: `qa_output/gate_0_first_turn/{01_boot,02_village,03_turn_start,04_move_preview,05_move_committed,06_basic_preview,07_contact,08_enemy_hit}.png`
- Create: `qa_output/gate_0_first_turn/first_turn.avi`, `manifest.json`, `GATE_0_QA_REPORT.md`

**Interfaces:** capture uses the same public input. The harness is committed first; the manifest then stores `tested_source_commit`, seed, locale, renderer, resolutions, camera, public path, decision/TC IDs, file SHA-256, PCK SHA-256, structured export-scan counts, and cleanup. Evidence/docs commits may be newer than the tested source commit but must never relabel it as final `HEAD`.

- [ ] **Step 1: RED, implement harness, commit before capture**

```bash
bash scripts_dev/qa/run_visual.sh --verify-only
bash scripts_dev/qa/run_qa.sh visual
git diff --check
git add data/qa scripts_dev/qa/runtime/capture_gate_0_first_turn.gd scripts_dev/qa/run_visual.sh
git commit -m "test: add Gate 0 capture harness" && git push
```

Expected RED lists eight PNGs/video/manifest. The committed harness itself passes static checks and the working tree is clean before rendering.

- [ ] **Step 2: Export scan and one capture from the clean tested source**

Reject safe-frame overlap, unclear tile/target/contact causality, horizontal confirmations, camera-axis change, or animation after result hold.

```bash
test -z "$(git status --short)"
tested_source_commit=$(git rev-parse HEAD)
bash scripts_dev/qa/run_local.sh export --preset "Gate0 QA Pack" --output build/gate0/drumstack_gate0.pck
bash scripts_dev/qa/check_release_export.sh build/gate0/drumstack_gate0.pck \
  | tee /tmp/drumstack_gate0_export_scan.log
pck_sha=$(shasum -a 256 build/gate0/drumstack_gate0.pck | awk '{print $1}')
bash scripts_dev/qa/run_visual.sh --capture \
  --tested-source-commit "$tested_source_commit" \
  --pck-sha "$pck_sha" \
  --export-scan-log /tmp/drumstack_gate0_export_scan.log
bash scripts_dev/qa/run_visual.sh --verify-only
```

Expected: every PNG is `2400×1080`, MovieWriter AVI is non-empty, enemy frame reads `314/400` and `-86`, and cleanup reports `residual_processes=0 residual_listeners=0`. The structured manifest/report records the tested source commit, PCK SHA, and `addon_files=0 autoloads=0`; the ignored Local PCK is not a handoff artifact. Report says `비포 캡처 없음: 신규 repo/scene`; A0→runtime is replacement comparison.

- [ ] **Step 3: Visual review and evidence-only commit**

```bash
git diff --check
git add qa_output/gate_0_first_turn
git commit -m "test: capture Gate 0 first-turn evidence" && git push
```

Expected: `PASS release_export_guard addon_files=0 autoloads=0`; `PASS visual_manifest files=9 sha_mismatch=0`; no tracked QA `.import`.

### Task 8: Reconcile and Handoff

**Execution:** Cloud after Local evidence is pushed.

**Files:**
- Modify: `docs/canonical/{work_state,DECISION_REGISTER,FEATURE_TEST_MAP,qa}.md`
- Modify: `qa_output/gate_0_first_turn/GATE_0_QA_REPORT.md`

**Interfaces:** Every requirement maps to implementation, test, evidence, and `Complete/Partial/Blocked/Not Applicable`.

- [ ] **Step 1: Final gates and truth reconciliation**

```bash
bash scripts_dev/qa/run_qa.sh static
bash scripts_dev/qa/run_qa.sh headless
bash scripts_dev/qa/run_visual.sh --verify-only
tested_source_commit=$(python3 -c 'import json; print(json.load(open("qa_output/gate_0_first_turn/manifest.json"))["tested_source_commit"])')
git merge-base --is-ancestor "$tested_source_commit" HEAD
test "$(find data/drumstack/heroes -name '*.json' | wc -l | tr -d ' ')" = 2
test "$(find assets/drumstack/characters -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 1
! rg -n 'Supabase|AdMob|Billing|StoreKit' scripts scenes --glob '*.gd'
```

Expected: current committed evidence PASS; Duck plus training data only; one character directory; no deferred SDK. The committed report carries Task 7's PCK SHA and `addon_files=0 autoloads=0` scan result; Cloud does not pretend the untracked Local PCK exists. Duck A0–A4 owner review must be `Passed`; if it is still `Blocked`, stop without milestone completion or PR. Android/iPhone/full match/3v3/backend/BM are explicit follow-up, never Gate 0 PASS.

- [ ] **Step 2: Commit, push, and open review**

```bash
git add docs/canonical qa_output/gate_0_first_turn/GATE_0_QA_REPORT.md
git commit -m "docs: reconcile Drumstack Gate 0 evidence" && git push
git status --short
gh pr create --base develop --head codex/gate-0-first-turn \
  --title "Gate 0: prove Duck Guard public first turn" \
  --body "New foundation plus boot-to-enemy-hit proof. Full match, roster, backend, BM, and device proof remain follow-up gates."
```

Expected: clean feature branch and reviewable PR; do not create the PR until evidence is current and the owner has approved the A0–A4 turntable plus Godot gallery.

## Milestone Acceptance

- New repo provenance and three standard hashes pass.
- MCP selected version passes isolated Godot 4.7 validation; any fallback reason is recorded.
- MCP is disabled/autoload-free in source and absent from PCK.
- Pure repeated input produces identical hashes and exact `86/314/50`.
- One Duck Guard A0–A4 source/GLB/wrapper/arena/rig/expressions/clips/VFX/derivatives/turntable/hash manifest exists and has owner review.
- Public input reaches enemy hit from boot through village.
- Eight `2400×1080` frames and one video match the manifest's recorded clean `tested_source_commit`; later evidence/docs commits remain traceable and do not rewrite that source identity.
- Agent-owned Godot/Blender/MCP/debug processes and listeners remaining equal zero.
- Every requirement has status/evidence; no macOS/headless claim is labeled Human or Device proof.
- Branch is pushed/clean; full match, heroes, Supabase, BM, Android/iOS remain outside Gate 0.
