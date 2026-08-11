# Quirky Tower Gate A 90-Second Greybox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one immediately playable 90-second portrait district where one duck leader rescues a goose and pigeon, moves through Approach → Brawl → Chain Raid without loading, receives one vertical three-choice reward, and leaves screenshot evidence that can be checked against the approved master spec.

**Architecture:** Keep the existing app shell, theme, popup, mascot, main scene, 720×1280 logical canvas, and 1080×2400 desktop override. Replace only the old 15-floor gameplay domain with one pure `FlockRunState`, one Control input owner, and one fixed-camera 3D world using native Godot colliders. Use authored collapse pieces and deterministic discrete event records; never claim deterministic Godot physics.

**Tech Stack:** Godot 4.7, typed GDScript, native `Camera3D`/`Area3D`/`CharacterBody3D`/`RigidBody3D`, existing `AppTheme`/`DesignTokens`/`GameOverlay`/`MascotGuide`, shell and Godot QA scripts, viewport PNG capture after `RenderingServer.frame_post_draw`.

**Execution status (2026-08-11):** Tasks 1–8 produced runtime source `c66e2e0`, visual evidence `6b9818b`, and capture-runner cleanup `e85ecac`. Task 9 reconciliation and Task 10 final regression, independent review, process audit, and Git handoff are complete on `codex/reboot-vertical-slice`. Gate A has **not passed** because the external five-person Human gate is blocked.

## Global Constraints

- Source of truth: `docs/reboot/DECISION_REGISTER.md`, relevant master HTML sections, then `docs/reboot/FEATURE_TEST_MAP.md`.
- Gate A scope: duck leader, goose and pigeon companions, one district, three continuous acts, one vertical three-choice reward.
- Input is one active pointer and only drag, short swipe, and release; transition, popup, focus loss, and restart cancel the gesture.
- The same state keeps leader, companions (maximum five), health, combo, score, build, seed, and event ledger across acts.
- Logical UI remains 720×1280; runtime/capture is 1080×2400 FHD+ 20:9; the 720×1280 safe frame is explicitly centered.
- Gate A gameplay uses a fixed orthographic diagonal `Camera3D`, low-poly shapes, pixel-style face surfaces, and real colliders. These visuals are greybox evidence only; final `quirky_tower_urban_broadcast_cel_v1` art is an untested Gate C deliverable.
- Collapse reads in order: warning → collision → crack → detached pieces → target collapse → reward.
- Three-choice actions reuse the existing vertical `VBoxContainer`, minimum 96 logical px, one callback after repeated taps, and no horizontal choice row.
- Visual completion requires fresh 1080×2400 screenshots from final code. Headless/parser PASS cannot replace screenshot or human evidence.
- Gate A does not add Supabase, AdMob, Billing, StoreKit, analytics SDKs, new runtime plugins, full character art, shop assets, four-stem audio, or five-minute content.
- Existing dirty changes in the primary `main` checkout remain untouched; all work is on `codex/reboot-vertical-slice`.
- Start and end each Local gate with process/port/Git evidence, and terminate only processes started by the agent.

## Requirement → Implementation → Evidence Checklist

Verdicts below separate implementation evidence from Human, Device, and final-art evidence.

| Req | Decisions | Tests | Implementation | Evidence | Verdict |
|---|---|---|---|---|---|
| GA-01 app boot and 20:9 safe frame | `QT-RB-UI-001`, `QT-RB-TECH-001`, `QT-RB-QA-005` | `QT-RB-TC-BAT-001`, `QT-RB-TC-VISUAL-001` | [`project.godot`](../../../project.godot), [`run_screen.tscn`](../../../scenes/game/run_screen.tscn), [`app_shell_test.gd`](../../../scripts_dev/qa/headless/app_shell_test.gd) | [legacy start](../../../qa_output/reboot_gate_a/before/gameplay_start_1080x2400.png), [boot](../../../qa_output/reboot_gate_a/after/boot.png), [entry](../../../qa_output/reboot_gate_a/after/entry.png) | **Partial** — all are 1080×2400, but the removed Timing Ring before state is `not directly comparable` to the reboot. |
| GA-02 one persistent flock state | `QT-RB-PROD-001/002`, `QT-RB-GAME-001/002/003` | `QT-RB-TC-CORE-001` | [`flock_run_state.gd`](../../../scripts/core/reboot/flock_run_state.gd), [`run_controller.gd`](../../../scripts/game/run_controller.gd) | [`flock_run_state_test.gd`](../../../scripts_dev/qa/headless/flock_run_state_test.gd), [entry](../../../qa_output/reboot_gate_a/after/entry.png), [choice](../../../qa_output/reboot_gate_a/after/choice.png), [result](../../../qa_output/reboot_gate_a/after/result.png) | **Complete** — same state and one build mutation verified for the Gate A slice. |
| GA-03 one-pointer ownership | `QT-RB-GAME-004/012` | `QT-RB-TC-TRANSITION-001` | [`flock_trial.gd`](../../../scripts/game/reboot/flock_trial.gd) | [`flock_world_test.gd`](../../../scripts_dev/qa/headless/flock_world_test.gd), [brawl warning](../../../qa_output/reboot_gate_a/after/brawl_warning.png), [choice](../../../qa_output/reboot_gate_a/after/choice.png) | **Partial** — one owner, act/focus/overlay/home cancellation pass; drag→popup stale-release 직접 경로는 미검증이다. |
| GA-04 Approach rescue/dodge | `QT-RB-GAME-007/012` | `QT-RB-TC-ENTRY-001` | [`flock_world_3d.gd`](../../../scripts/game/reboot/flock_world_3d.gd), [`flock_bird_factory.gd`](../../../scripts/game/reboot/flock_bird_factory.gd) | [`flock_world_test.gd`](../../../scripts_dev/qa/headless/flock_world_test.gd), [entry](../../../qa_output/reboot_gate_a/after/entry.png) | **Partial** — drag·Rescue는 pass; hazard/dodge 실행과 Human 이해도는 미검증이다. |
| GA-05 Brawl dash/impact | `QT-RB-GAME-004/007/008/012` | `QT-RB-TC-BRAWL-001` | [`flock_world_3d.gd`](../../../scripts/game/reboot/flock_world_3d.gd) | [warning](../../../qa_output/reboot_gate_a/after/brawl_warning.png), [contact](../../../qa_output/reboot_gate_a/after/brawl_contact.png), [rebound](../../../qa_output/reboot_gate_a/after/brawl_rebound.png) | **Complete** — three authored Desktop QA states; Human cause recognition remains GA-12. |
| GA-06 Chain path/release | `QT-RB-GAME-007/008` | `QT-RB-TC-CHAIN-001` | [`flock_world_3d.gd`](../../../scripts/game/reboot/flock_world_3d.gd) | [path](../../../qa_output/reboot_gate_a/after/chain_path.png), [broken](../../../qa_output/reboot_gate_a/after/chain_broken.png), [strike](../../../qa_output/reboot_gate_a/after/chain_strike.png) | **Complete** — unique target order, broken path, and collider attack path verified. |
| GA-07 authored destruction | `QT-RB-GAME-008`, `QT-RB-TECH-004/007` | `QT-RB-TC-COLLAPSE-001` | [`flock_world_3d.gd`](../../../scripts/game/reboot/flock_world_3d.gd) | [contact](../../../qa_output/reboot_gate_a/after/brawl_contact.png) → [crack](../../../qa_output/reboot_gate_a/after/collapse_crack.png) → [pieces](../../../qa_output/reboot_gate_a/after/collapse_pieces.png) → [target](../../../qa_output/reboot_gate_a/after/collapse_target.png) → [reward](../../../qa_output/reboot_gate_a/after/collapse_reward.png) | **Complete** — authored order and one reward verified; Human cause recognition remains GA-12. |
| GA-08 deterministic discrete rules | `QT-RB-GAME-006/010`, `QT-RB-TECH-002/007` | `QT-RB-TC-RNG-001` | [`flock_run_state.gd`](../../../scripts/core/reboot/flock_run_state.gd) | [`flock_run_state_test.gd`](../../../scripts_dev/qa/headless/flock_run_state_test.gd), [QA report](../../../qa_output/reboot_gate_a/GATE_A_QA_REPORT.md) | **Partial** — same-seed choice/ledger/one mutation은 pass; 다른 seed 분기는 미검증이다. |
| GA-09 vertical three-choice | `QT-RB-GAME-006`, `QT-RB-UI-003/009/011` | `QT-RB-TC-REWARD-001` | [`game_overlay.gd`](../../../scripts/ui/game_overlay.gd), [`run_controller.gd`](../../../scripts/game/run_controller.gd) | [`ui_foundation_test.gd`](../../../scripts_dev/qa/headless/ui_foundation_test.gd), [KO choice](../../../qa_output/reboot_gate_a/after/choice.png), [result](../../../qa_output/reboot_gate_a/after/result.png) | **Partial** — vertical cards and one mutation pass, but effect across two later acts and DE/AR visual evidence require Gate B/localization QA. |
| GA-10 mascot and transitions | `QT-RB-MASCOT-001/002`, `QT-RB-UI-004/005/010` | `QT-RB-TC-MASCOT-001`, `QT-RB-TC-UI-001` | [`flock_trial.gd`](../../../scripts/game/reboot/flock_trial.gd), [`game_overlay.gd`](../../../scripts/ui/game_overlay.gd) | [`mascot_guide_test.gd`](../../../scripts_dev/qa/headless/mascot_guide_test.gd), [entry](../../../qa_output/reboot_gate_a/after/entry.png), [contact](../../../qa_output/reboot_gate_a/after/brawl_contact.png), [choice](../../../qa_output/reboot_gate_a/after/choice.png), [result](../../../qa_output/reboot_gate_a/after/result.png) | **Complete** for KO Desktop QA; full language/Human response remains unverified. |
| GA-11 restart cleanup | `QT-RB-GAME-003`, `QT-RB-QA-005` | `QT-RB-TC-RESET-001` | [`run_controller.gd`](../../../scripts/game/run_controller.gd), [`flock_trial.gd`](../../../scripts/game/reboot/flock_trial.gd) | [`flock_world_test.gd`](../../../scripts_dev/qa/headless/flock_world_test.gd), [`app_shell_test.gd`](../../../scripts_dev/qa/headless/app_shell_test.gd) | **Partial** — home·restart에서 이전 trial 해제와 1개 재생성은 pass; failure 재시작 경로는 미검증이다. |
| GA-12 external fun gate | `QT-RB-GAME-005/011`, `QT-RB-QA-002/003` | `QT-RB-TC-PACING-001` | external five-person observation | no observation sheet or raw clips | **Blocked** — requires five people; Gate A has not passed. |
| GA-13 process and Git cleanup | `QT-RB-OPS-001/002/003`, `QT-RB-QA-006` | `QT-RB-TC-PROCESS-001` | exact owner PID cleanup in [`run_gate_a_visual.sh`](../../../scripts_dev/qa/run_gate_a_visual.sh) | [QA process record](../../../qa_output/reboot_gate_a/GATE_A_QA_REPORT.md#process-evidence), commit `e85ecac` owner/child reap self-test | **Complete** — final six regressions, project check, cleanup self-test, PID/port audit, commit/push handoff verified. |

---

### Task 1: Record Approval and Freeze Gate A Scope

**Files:**
- Modify: `docs/reboot/DECISION_REGISTER.md`
- Modify: `docs/reboot/FEATURE_TEST_MAP.md`
- Modify: `docs/reboot/WORK_STATE.md`
- Modify: `docs/reboot/QUIRKY_TOWER_REBOOT_MASTER_SPEC.html`

**Interfaces:**
- Consumes: user approval on 2026-08-11 and the checklist above.
- Produces: approved document status, `QT-RB-QA-007`, and the visual evidence rule used by later tasks.

- [ ] **Step 1: Mark the package approved without turning candidate tuning into locked numbers**

Change document-level `Review Candidate` labels to `Approved for Gate A implementation`. Preserve individual `PROPOSED`, `NEEDS_PLAYTEST`, `DEFERRED`, and `CUT` states.

- [ ] **Step 2: Add the screenshot completion decision**

```markdown
| `QT-RB-QA-007` | `LOCKED` | 화면 결과가 바뀌는 구현은 최종 코드에서 새로 만든 1080×2400 비포·애프터 캡처와 명세→구현→증거 대조표가 있어야 완료 후보가 된다. 코드 파싱·headless PASS만으로 Visual 또는 Human PASS를 선언하지 않는다. | House Duck 공통 검증 규칙과 사용자의 명세 승인 조건을 프로젝트 정본에 고정한다. |
```

- [ ] **Step 3: Add `QT-RB-TC-VISUAL-001` to the feature map**

Require final-code 1080×2400 PNGs and keep actual-device and external-human evidence separate.

- [ ] **Step 4: Update work state**

Set phase to `Gate A implementation`, branch to `codex/reboot-vertical-slice`, and next P0 to this plan. Preserve `미검증` until evidence exists.

- [ ] **Step 5: Check and commit**

```bash
git diff --check
rg -n 'Review Candidate|다음 승인 게이트' docs/reboot
git add docs/reboot
git commit -m "docs: approve Quirky Tower Gate A implementation"
```

Expected: document-level gate updated; candidate tuning labels remain.

### Task 2: Capture Old Gameplay Baseline and Verify the Worktree

**Files:**
- Create: `qa_output/reboot_gate_a/before/README.md`
- Create: `qa_output/reboot_gate_a/before/gameplay_start_1080x2400.png`
- Create: `qa_output/reboot_gate_a/before/gameplay_result_1080x2400.png`

**Interfaces:**
- Consumes: current `21f17ea` gameplay and resolution settings.
- Produces: immutable before evidence and a clean baseline result.

- [ ] **Step 1: Record process and port baseline**

Record exact matching process lines and listeners for `6505`, `7777`, `9080–9095`, `9100–9115`, and `9200–9215`. Do not terminate a process that predates this task.

- [ ] **Step 2: Run the existing parser once**

```bash
bash scripts_dev/qa/check_project.sh
```

Expected: `PASS project structure`. A failure stops implementation until its cause is separated.

- [ ] **Step 3: Capture two old gameplay states**

Use a temporary `/tmp` SceneTree script, not a tracked production helper. Instantiate `scenes/app/main.tscn`, finish splash, open the run, await `RenderingServer.frame_post_draw`, assert image size `Vector2i(1080, 2400)`, and save the PNGs above.

- [ ] **Step 4: Inspect both PNGs**

Record only defects visible in the images. Do not infer touch feel, device behavior, or fun from stills.

- [ ] **Step 5: Stop the exact Godot PID and commit evidence**

```bash
git add qa_output/reboot_gate_a/before
git commit -m "test: capture pre-reboot gameplay baseline"
```

### Task 3: Replace 15-Floor Rules with One Persistent Flock State

**Files:**
- Create: `scripts/core/reboot/flock_run_state.gd`
- Create: `scripts_dev/qa/headless/flock_run_state_test.gd`
- Modify: `scripts_dev/qa/check_project.sh`

**Interfaces:**
- Produces: `FlockRunState.new_run(seed: int)`, `begin_act(act_id: String)`, `rescue(companion_id: String, species: String) -> bool`, `record_event(kind: String, payload := {})`, `choice_options() -> Array`, `apply_choice(choice_id: String) -> bool`, `snapshot() -> Dictionary`.
- Act IDs: `entry`, `brawl`, `chain`, `choice`, `complete`.
- Companion keys: `id`, `species`; build keys: `dash_power`, `route_width`, `guard`.

- [ ] **Step 1: Write the failing state test**

```gdscript
var first = FlockRunState.new_run(424242)
var second = FlockRunState.new_run(424242)
assert(first.snapshot() == second.snapshot())
assert(first.rescue("goose_greta", "goose"))
assert(first.rescue("pigeon_pip", "pigeon"))
assert(not first.rescue("goose_greta", "goose"))
assert(first.companions.size() == 2)
first.begin_act("brawl")
first.record_event("collapse", {"target_id": "antenna_a"})
assert(first.event_ledger[-1].kind == "collapse")
var options := first.choice_options()
assert(options.size() == 3)
assert(first.apply_choice(str(options[0].id)))
assert(not first.apply_choice(str(options[0].id)))
```

- [ ] **Step 2: Run RED**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/flock_run_state_test.gd
```

Expected: new preload missing.

- [ ] **Step 3: Implement the smallest pure state**

Use one seeded `RandomNumberGenerator`. Only choice ordering and discrete rules consume it. Do not store positions, collision frames, or trajectories in the ledger.

- [ ] **Step 4: Run GREEN and add this test to `check_project.sh`**

Expected: `PASS flock_run_state_test` and `PASS project structure`.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/reboot/flock_run_state.gd scripts_dev/qa/headless/flock_run_state_test.gd scripts_dev/qa/check_project.sh
git commit -m "feat: add deterministic flock run state"
```

### Task 4: Build Fixed-Camera 3D Flock and Approach

**Files:**
- Create: `scenes/game/reboot/flock_trial.tscn`
- Create: `scripts/game/reboot/flock_world_3d.gd`
- Create: `scripts_dev/qa/headless/flock_world_test.gd`

**Interfaces:**
- Consumes: `FlockRunState`.
- Signals: `act_completed(act_id: String, result: Dictionary)`, `flock_changed(snapshot: Dictionary)`, `impact(kind: String, world_point: Vector3)`, `collapse_stage(stage: String)`.
- Methods: `setup(run_state)`, `start_act(act_id: String)`, `set_drag_target(screen_position: Vector2)`, `release_swipe(screen_position: Vector2, velocity: Vector2)`, `cancel_gesture()`.

- [ ] **Step 1: Write a failing world structure test**

Assert one current orthographic `Camera3D`, one leader `CharacterBody3D` with collision, two companion slots, three route markers, and no old mini-game child.

- [ ] **Step 2: Run RED**

Expected: scene preload missing.

- [ ] **Step 3: Create the scene skeleton**

Use `Environment`, `KeyLight`, `Camera`, `World/Floor`, `World/Bounds`, `Actors`, `Encounter`, and `Effects`. The world fills 20:9; UI safe content is separate.

- [ ] **Step 4: Build recognizable greybox birds**

One `_make_bird_actor(species: String)` helper in `flock_world_3d.gd` creates a low-poly ellipsoid body, head, bill, feet, and nearest-filter 16×16 face. Duck is balanced, goose taller, pigeon smaller with a wing band. Do not create per-species scenes or a factory class for three variants.

- [ ] **Step 5: Implement Approach**

Drag maps through the fixed camera to the floor plane and targets above the finger. Three lanes present hazard, rescue, and score choices. `Area3D.body_entered` records collision or rescue once. Companions use fixed follow offsets, not pathfinding.

- [ ] **Step 6: Run GREEN and commit**

```bash
git add scenes/game/reboot/flock_trial.tscn scripts/game/reboot/flock_world_3d.gd scripts_dev/qa/headless/flock_world_test.gd
git commit -m "feat: add flock approach world"
```

### Task 5: Add Swipe Brawl and Collider-Triggered Collapse

**Files:**
- Modify: `scripts/game/reboot/flock_world_3d.gd`
- Modify: `scripts_dev/qa/headless/flock_world_test.gd`

**Interfaces:**
- `FlockWorld3D.trigger_collapse(target_id: String, force_direction: Vector3) -> bool`.
- Existing world signals add `collapse_stage(stage: String)` and `reward_released(value: int)`.

- [ ] **Step 1: Extend the test**

Assert a slow release does not dash, a velocity over the shared threshold starts one dash, a dash collider can strike one enemy, and a repeated weak-point callback cannot release a second reward.

- [ ] **Step 2: Run RED**

Expected: brawl methods or collapse target missing.

- [ ] **Step 3: Implement the threshold once**

Keep candidate distance and velocity constants in `flock_world_3d.gd`. Normal drag release stops movement. A valid swipe enables a short leader dash hitbox and applies impulse to the contacted `RigidBody3D` enemy.

- [ ] **Step 4: Implement authored collapse**

Enemy overlap at the weak point calls one guarded world method. It changes material through warning/contact/crack, releases pre-created rigid pieces, lowers the tower segment, then emits one reward. Feedback never precedes contact. A separate collapse class is deferred until a second target genuinely needs different behavior.

- [ ] **Step 5: Run GREEN and commit**

```bash
git add scripts/game/reboot/flock_world_3d.gd scripts_dev/qa/headless/flock_world_test.gd
git commit -m "feat: add brawl collapse chain reaction"
```

### Task 6: Add Draw-and-Release Chain Raid

**Files:**
- Modify: `scripts/game/reboot/flock_world_3d.gd`
- Modify: `scripts_dev/qa/headless/flock_world_test.gd`

**Interfaces:**
- `FlockWorld3D` owns unique target IDs, one collider-bearing attack orb, and an `ImmediateMesh` path preview on the floor.

- [ ] **Step 1: Extend the test**

Assert target IDs preserve order, repeated targets are ignored, fewer than two targets reports `broken` without consuming the attack, and a valid release emits one strike per unique target.

- [ ] **Step 2: Run RED**

Expected: chain selection methods missing.

- [ ] **Step 3: Implement path selection**

During `chain`, drag samples nearby weak points in projected screen space. Store stable target IDs rather than nodes or physics coordinates in the discrete ledger.

- [ ] **Step 4: Execute release through actual overlap**

Move one `Area3D` attack orb through selected world points. Each target accepts one overlap, flashes in path order, and triggers authored collapse. Companions visually trail with fixed short delays. Draw the preview in the world script; do not add a one-use overlay abstraction.

- [ ] **Step 5: Run GREEN and commit**

```bash
git add scripts/game/reboot/flock_world_3d.gd scripts_dev/qa/headless/flock_world_test.gd
git commit -m "feat: add draw and release chain raid"
```

### Task 7: Integrate Three Acts, Mascot, HUD, and Vertical Choice

**Files:**
- Create: `scripts/game/reboot/flock_trial.gd`
- Modify: `scenes/game/reboot/flock_trial.tscn`
- Modify: `scenes/game/run_screen.tscn`
- Replace domain logic in: `scripts/game/run_controller.gd`
- Modify: `scripts/ui/run_hud.gd`
- Modify: `scenes/ui/components/run_hud.tscn`
- Modify: `scripts/ui/game_overlay.gd`
- Modify: `scripts/ui/ui_text.gd`
- Modify: `scripts_dev/qa/headless/flock_world_test.gd`

**Interfaces:**
- `FlockTrial.begin(run_state)`, `cancel_input()`, `get_visual_state() -> Dictionary`.
- `FlockTrial` signal `district_finished()` after chain reward.
- `RunController.get_run_snapshot() -> Dictionary`, `restart_run()`, and `home_requested` stay stable for the app shell.

- [ ] **Step 1: Extend the world test with the failing integrated flow**

Instantiate `run_screen.tscn`, assert exactly one `FlockTrial`, advance `entry → brawl → chain → choice`, assert the same state and companions persist, assert three vertical choice buttons, press one twice, and assert one build event and completion.

- [ ] **Step 2: Run RED**

Expected: old `TowerTrial` or 15-floor state remains.

- [ ] **Step 3: Build the single input owner**

`FlockTrial._gui_input()` owns one touch index or mouse button, records press position/time, forwards drag, computes release velocity, and calls one world release. Focus loss, act transitions, overlay open, home, and restart call `cancel_input()`.

- [ ] **Step 4: Connect seamless transitions**

Use signals rather than scene replacement. Each transition updates HUD and one mascot line:

```gdscript
const ACT_COPY := {
    "entry": ["1막 · 구출 진입", "끌어서 동료를 구해!"],
    "brawl": ["2막 · 옥상 난투", "짧게 그어 약점으로 날려!"],
    "chain": ["3막 · 사슬 습격", "약점을 잇고 손을 떼!"],
}
```

- [ ] **Step 5: Reuse the vertical popup**

After `district_finished`, call `GameOverlay.show_actions()` with three seeded options. First valid press disables siblings, mutates state once, then shows stacked `PLAY AGAIN` and `HOME` actions.

- [ ] **Step 6: Remove old floor language from HUD**

Show act, health, score, combo, and flock species. Do not show floor 1/15, a mini-game title, or paragraph instructions.

- [ ] **Step 7: Remove the disconnected legacy gameplay after new integration passes**

Delete the now-unreferenced old paths instead of creating a second legacy source-of-truth folder:

```text
scripts/core/challenges/
scripts/core/quirks/
scripts/core/simulation/
scripts/core/run/
scripts/core/economy/
scripts/game/challenges/
scripts/game/world/
scenes/game/challenges/
scenes/game/world/
data/gameplay/
data/story/events.json
data/economy/sponsor_boost.json
```

Delete old domain tests (`catalog`, `challenge_rules`, `challenge_scene`, `floor_transition`, `playable_loop`, `run_balance`, `run_end_cleanup`, `run_engine`, `run_smoke`, `tower_stage_3d`, `tower_trial`). Keep and update `main_scene`, `app_shell`, `mascot_guide`, and `ui_foundation` tests.

- [ ] **Step 8: Run integration checks and commit**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/flock_world_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/app_shell_test.gd
bash scripts_dev/qa/check_project.sh
git add -A scenes/game scripts/game scripts/core data scripts/ui/run_hud.gd scripts/ui/game_overlay.gd scripts/ui/ui_text.gd scenes/ui/components/run_hud.tscn scripts_dev/qa/headless
git commit -m "feat: integrate Gate A flock run"
```

### Task 8: Add Reproducible Runtime Screenshot Capture

**Files:**
- Create: `scripts_dev/qa/runtime/capture_gate_a.gd`
- Create: `scripts_dev/qa/run_gate_a_visual.sh`
- Create: `qa_output/reboot_gate_a/after/README.md`
- Create generated evidence: `qa_output/reboot_gate_a/after/*.png`

**Interfaces:**
- Capture states: `boot`, `entry`, `brawl_warning`, `brawl_contact`, `brawl_rebound`, `chain_path`, `chain_broken`, `chain_strike`, `collapse_crack`, `collapse_pieces`, `collapse_target`, `collapse_reward`, `choice`, `result`.
- Every PNG is exactly 1080×2400 and comes from the final candidate.

- [ ] **Step 1: Write the capture runner**

Reach states through the real scene and public input/signal paths, wait for settled animations except intentional intermediate frames, then capture. Use the root viewport only when the image is exactly 1080×2400. Otherwise, in this QA script only, instantiate the app under a `SubViewport` with `size = Vector2i(1080, 2400)`, `size_2d_override = Vector2i(720, 1600)`, and stretched override before capturing:

```gdscript
await RenderingServer.frame_post_draw
var image := get_viewport().get_texture().get_image()
assert(image.get_size() == Vector2i(1080, 2400))
assert(image.save_png(output_path) == OK)
```

- [ ] **Step 2: Make one shell entry point**

Record Git SHA and Godot version, create only the intended evidence directory, launch one Godot process, and remove no unrelated file.

- [ ] **Step 3: Run capture once and stop its exact PID**

Recorded: fourteen fresh runtime-source PNGs and no new agent-owned Godot/MCP listener after exit. Commit `e85ecac` additionally guards the exact owner PID, reaps its child, escalates TERM to KILL within bounded waits, and preserves unrelated processes.

- [ ] **Step 4: Inspect every image at original detail**

Check clipping, safe-frame centering, action hierarchy, bird silhouettes, cause/effect order, path readability, mascot obstruction, and result CTA. A visible P0/P1 defect returns to its owning task.

- [ ] **Step 5: Commit runner and intentional evidence**

```bash
git add scripts_dev/qa/runtime/capture_gate_a.gd scripts_dev/qa/run_gate_a_visual.sh qa_output/reboot_gate_a/after
git commit -m "test: add Gate A visual evidence"
```

### Task 9: Reconcile Spec, Implementation, and Evidence

**Files:**
- Modify: `docs/superpowers/plans/2026-08-11-gate-a-90s-greybox.md`
- Modify: `docs/reboot/FEATURE_TEST_MAP.md`
- Modify: `docs/reboot/WORK_STATE.md`
- Create: `qa_output/reboot_gate_a/GATE_A_QA_REPORT.md`

**Interfaces:**
- Consumes: final code, test output, before/after PNGs, and the approved checklist.
- Produces: per-requirement `Complete`, `Partial`, `Blocked`, or `Excluded` verdict with exact evidence.

- [ ] **Step 1: Re-read every Gate A requirement**

For GA-01 through GA-13, link exact implementation files and exact PNG/test evidence. Never mark a visual row complete from code or logs.

- [ ] **Step 2: Create the QA report**

Each executed TC includes House Duck fields: ID, suite, priority, preconditions, action, expected result, platform, automation/manual method, result, evidence, and issue. Desktop runtime stays `Desktop QA`; Android/iOS stay `Not Tested`.

- [ ] **Step 3: Compare before and after**

Use same-resolution links side by side and state only visible changes. If a before state has no semantic equivalent after core replacement, label it `not directly comparable`.

- [ ] **Step 4: Keep the external-human gate blocked**

`QT-RB-TC-PACING-001` remains `Blocked` until five people provide evidence. Report `Gate A implementation candidate complete; Gate A human fun gate blocked`, not `Gate A passed`.

- [ ] **Step 5: Run final checks and commit**

```bash
bash scripts_dev/qa/check_project.sh
git diff --check
git status --short --branch
git add docs/reboot docs/superpowers/plans/2026-08-11-gate-a-90s-greybox.md qa_output/reboot_gate_a/GATE_A_QA_REPORT.md
git commit -m "docs: reconcile Gate A implementation evidence"
```

### Task 10: Independent Review, Push, and Cleanup

**Files:**
- Review only: all changes against `main` and this plan.

**Interfaces:**
- Produces: reviewer findings resolved or recorded, remote branch, and zero new agent-owned residual processes.

- [ ] **Step 1: Run independent spec and code review**

Use separate reviewers for spec coverage and code/over-engineering. Fix P0/P1 findings at the root owner and rerun the smallest affected check.

- [ ] **Step 2: Verify repository scope**

```bash
git diff --check main...HEAD
git status --short --branch
git log --oneline --decorate main..HEAD
```

Expected: no primary-main dirty files, generated `.godot`, temp profiles, logs, or unrelated assets tracked.

- [ ] **Step 3: Verify process cleanup**

Compare exact process/port baseline. Terminate only agent-started PIDs and report pre-existing processes left alone.

- [ ] **Step 4: Push**

```bash
git push -u origin codex/reboot-vertical-slice
```

- [ ] **Step 5: Report evidence boundaries**

Report screenshot links and completed files; explicitly list desktop/headless evidence, external-human blocker, and untested Android/iOS/audio/BM/backend scope.

## Self-Review

- Spec coverage: every Gate A core, UI, mascot, reset, document, and process row maps to Tasks 3–9.
- Scope boundary: Sponsor Ticket retry, merge tuning, full localization, Gate B story, Gate C art/audio/outgame, and Gate D SDK/backend are not pulled into greybox.
- Type consistency: `FlockRunState`, `FlockWorld3D`, and `FlockTrial` names and signatures are defined once and reused.
- Evidence boundary: Visual rows require inspected PNGs; Human and Device rows cannot inherit Desktop/headless PASS.
- Placeholder scan: every implementation step names its concrete file, action, command, and expected result.

## Execution Choice

The approved autonomous workflow selects **Subagent-Driven Development**. Local Godot runs are grouped at baseline, integration, and final visual gates to minimize MacBook Air M2 load.
