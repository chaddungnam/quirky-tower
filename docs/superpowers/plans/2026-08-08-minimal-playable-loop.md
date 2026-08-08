# Quirky Tower Minimal Playable Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make the Godot Run Project button start a directly playable 15-floor run with three touch challenges, Quirk choices, story beats, game over, completion, and restart.

**Architecture:** Existing `scripts/core` and JSON remain unchanged. A thin `RunController` owns scene flow and sends challenge input values into `TowerRunEngine`; each challenge is an isolated `Control` scene that emits one `finished(float)` signal. One HUD and one reusable overlay keep the UI editable from shared theme and token files.

**Tech Stack:** Godot 4.7 stable, GDScript, `.tscn`, `Theme`, existing JSON/core rules, Godot MCP 0.7.2.

## Global Constraints

- Run Project enters floor 1 without a Home screen.
- One run contains 15 floors and the existing three challenge IDs.
- Quirk choice appears before floors 4, 8, and 12; story appears after successful floors 5, 10, and 15.
- The viewport is 720×1280 portrait with `canvas_items` and `expand`.
- UI values live in `AppTheme.tres` and `DesignTokens`; challenge rules never reference UI.
- Do not add Home, ranking, ads, billing, Supabase, save, audio, or haptics in this slice.
- Existing core/headless tests must remain green.
- Android/iOS device behavior remains unverified without explicit device-test approval.
- Commit and push each completed task to `origin/main` without asking.

---

### Task 1: Shared UI Foundation

**Files:**
- Create: `scripts_dev/qa/headless/ui_foundation_test.gd`
- Create: `scripts/ui/design_tokens.gd`
- Create: `scripts/ui/run_hud.gd`
- Create: `scripts/ui/game_overlay.gd`
- Create: `ui/themes/app_theme.tres`
- Create: `scenes/ui/components/run_hud.tscn`
- Create: `scenes/ui/components/game_overlay.tscn`

**Interfaces:**
- Produces: `RunHud.update_state(state: TowerRunState) -> void`.
- Produces: `GameOverlay.show_message(title: String, body: String, action_text: String, action: Callable) -> void`.
- Produces: `GameOverlay.show_choices(title: String, options: Array, action: Callable) -> void`.
- Produces: `GameOverlay.close() -> void`.

- [x] **Step 1: Write the failing UI foundation test**

Create a `SceneTree` script which loads the two component scenes, instantiates them, calls the public methods, and asserts the visible labels/buttons reflect the provided values.

```gdscript
extends SceneTree

func _init() -> void:
    var hud = load("res://scenes/ui/components/run_hud.tscn").instantiate()
    var state := TowerRunState.new_run(1, "DE")
    state.floor = 7
    state.score = 420
    state.combo = 3
    hud.update_state(state)
    assert(hud.get_node("Margin/Row/Floor").text == "7F")
    var overlay = load("res://scenes/ui/components/game_overlay.tscn").instantiate()
    overlay.show_message("READY", "Tap", "GO", func(): pass)
    assert(overlay.visible)
    quit()
```

- [x] **Step 2: Run the test and verify RED**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/ui_foundation_test.gd
```

Expected: parse/load failure because the UI scenes do not exist.

- [x] **Step 3: Implement the shared theme, HUD, and overlay**

`DesignTokens` contains only the approved Cream, Navy, Coral, Teal, Gold, Red, and Orange roles plus spacing and radius constants. `AppTheme.tres` owns default font size and Button/Panel/Label styles. `GameOverlay` rebuilds one action column instead of creating separate popup scenes.

```gdscript
class_name DesignTokens
extends RefCounted

const CREAM := Color("#FFF4D8")
const NAVY := Color("#24324A")
const CORAL := Color("#FF5A5F")
const TEAL := Color("#2FB6A8")
const GOLD := Color("#F4C542")
const ORANGE := Color("#F78C3D")
const SPACE := 16
const RADIUS := 20
```

```gdscript
func update_state(state: TowerRunState) -> void:
    %Floor.text = "%dF" % state.floor
    %Score.text = "%06d" % state.score
    %Combo.text = "COMBO ×%d" % state.combo
    %Hearts.text = "♥ ".repeat(state.hearts).strip_edges()

func show_message(title: String, body: String, action_text: String, action: Callable) -> void:
    _clear_actions()
    %Title.text = title
    %Body.text = body
    _add_action(action_text, action)
    show()
```

- [x] **Step 4: Verify GREEN**

Run the focused test, `bash scripts_dev/qa/check_project.sh`, and `git diff --check`.

- [x] **Step 5: Commit and push**

```bash
git add scripts/ui scenes/ui ui/themes scripts_dev/qa/headless/ui_foundation_test.gd
git commit -m "feat: add shared playable UI foundation"
git push origin main
```

---

### Task 2: Three Playable Challenge Scenes

**Files:**
- Create: `scripts_dev/qa/headless/challenge_scene_test.gd`
- Create: `scripts/game/challenges/timing_ring.gd`
- Create: `scripts/game/challenges/tap_panic.gd`
- Create: `scripts/game/challenges/drag_dodge.gd`
- Create: `scenes/game/challenges/timing_ring.tscn`
- Create: `scenes/game/challenges/tap_panic.tscn`
- Create: `scenes/game/challenges/drag_dodge.tscn`

**Interfaces:**
- Each scene produces: signal `finished(input_value: float)`.
- Each scene produces: `setup(difficulty: float, modifiers: Dictionary = {}) -> void` and `begin() -> void`.

- [x] **Step 1: Write the failing challenge contract test**

```gdscript
extends SceneTree

func _init() -> void:
    for id in ["timing_ring", "tap_panic", "drag_dodge"]:
        var scene = load("res://scenes/game/challenges/%s.tscn" % id)
        assert(scene != null)
        var challenge = scene.instantiate()
        assert(challenge.has_signal("finished"))
        assert(challenge.has_method("setup"))
        assert(challenge.has_method("begin"))
        challenge.setup(0.5)
    quit()
```

- [x] **Step 2: Run the test and verify RED**

Run the new test. Expected: load failure for `timing_ring.tscn`.

- [x] **Step 3: Implement Timing Ring**

Draw a centered horizontal ring/track and oscillating needle. A tap locks input and emits the current normalized position.

```gdscript
func _process(delta: float) -> void:
    if _active:
        _position = pingpong(_position + delta * _speed, 1.0)
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if _active and event is InputEventMouseButton and event.pressed:
        _active = false
        finished.emit(_position)
```

- [x] **Step 4: Implement Tap Panic**

Create a reusable 3×4 button grid. One Coral target moves after each correct tap; wrong taps reduce progress. After four seconds, emit `hits / goal` clamped to `0.0..1.0`.

```gdscript
func _on_cell_pressed(index: int) -> void:
    _hits = _hits + 1 if index == _target_index else maxi(0, _hits - 1)
    if _hits >= _goal:
        _finish()
    else:
        _move_target()

func _finish() -> void:
    if not _active:
        return
    _active = false
    finished.emit(clampf(float(_hits) / float(_goal), 0.0, 1.0))
```

- [x] **Step 5: Implement Drag Dodge**

Draw an Orange player and descending Navy obstacles. Drag updates the player within the arena. Collision emits `0.0`; surviving four seconds emits `0.5`, the current core safe-center value.

```gdscript
func _process(delta: float) -> void:
    if not _active:
        return
    _elapsed += delta
    _move_obstacles(delta)
    if _has_collision():
        _finish(0.0)
    elif _elapsed >= 4.0:
        _finish(0.5)
    queue_redraw()
```

- [x] **Step 6: Verify GREEN**

Run `challenge_scene_test.gd`, all existing headless `*_test.gd` files, the smoke run, and the project guard.

- [x] **Step 7: Commit and push**

```bash
git add scripts/game/challenges scenes/game/challenges scripts_dev/qa/headless/challenge_scene_test.gd
git commit -m "feat: add three playable challenge scenes"
git push origin main
```

---

### Task 3: Complete 15-Floor Run Screen

**Files:**
- Create: `scripts_dev/qa/headless/playable_loop_test.gd`
- Create: `scripts/game/run_controller.gd`
- Create: `scenes/game/run_screen.tscn`
- Create: `scripts/app/main.gd`
- Create: `scenes/app/main.tscn`

**Interfaces:**
- Consumes: the three challenge scene contracts from Task 2.
- Consumes: `GameCatalog.load_default()`, `TowerRunState.new_run(seed, country)`, and `TowerRunEngine.resolve_floor(state, catalog, input_value)`.
- Produces: `RunController.submit_challenge(input_value: float) -> void`.
- Produces: `RunController.choose_quirk(quirk_id: String) -> void`.
- Produces: `RunController.restart_run() -> void`.
- Produces: `RunController.get_run_snapshot() -> Dictionary` for QA and presentation reads.
- Produces: `RunController.needs_quirk_choice() -> bool` and `available_quirks() -> Array`.
- Produces: `RunController.success_input_for_current_challenge() -> float` and `continue_flow() -> void` for deterministic QA without test-only state mutation.

- [x] **Step 1: Write the failing loop test**

The test instantiates `run_screen.tscn`, enters it into the tree, advances each challenge with a guaranteed success value (`0.5` for Timing Ring/Drag Dodge, `1.0` for Tap Panic), selects the first available Quirk when requested, and asserts the final snapshot has status `complete`, floor `15`, three story IDs, and three Quirks.

```gdscript
var screen = load("res://scenes/game/run_screen.tscn").instantiate()
root.add_child(screen)
for turn in range(15):
    if screen.needs_quirk_choice():
        screen.choose_quirk(screen.available_quirks()[0])
    screen.submit_challenge(screen.success_input_for_current_challenge())
    screen.continue_flow()
    if turn + 1 in [5, 10, 15]:
        screen.continue_flow()
var snapshot: Dictionary = screen.get_run_snapshot()
assert(snapshot.status == "complete")
assert(snapshot.story_event_ids.size() == 3)
```

- [x] **Step 2: Run the test and verify RED**

Run the new test. Expected: load failure because `run_screen.tscn` does not exist.

- [x] **Step 3: Implement RunController**

Load and validate the catalog, create one run state, update HUD, show Quirk choices before 4/8/12, instantiate the floor challenge, submit its value to `TowerRunEngine`, then show result/story/end overlays. Reject duplicate submissions while a result is pending.

```gdscript
func submit_challenge(input_value: float) -> void:
    if _phase != "challenge":
        return
    _phase = "result"
    _last_result = TowerRunEngine.resolve_floor(_state, _catalog, input_value)
    %Hud.update_state(_state)
    %Overlay.show_message(
        "SUCCESS" if _last_result.success else "FAIL",
        "+%d" % _last_result.score_delta,
        "CONTINUE",
        continue_flow,
    )

func continue_flow() -> void:
    if _phase == "result" and _last_result.story_event_id != "":
        _phase = "story"
        _show_story(_last_result.story_event_id)
    elif _state.status != "running":
        _show_run_end()
    else:
        _present_floor()
```

- [x] **Step 4: Add the fixed app entry scene**

`main.tscn` contains one full-rect `run_screen.tscn` instance and uses `AppTheme.tres`. `main.gd` exists only to expose `restart_run()` to the root and does not own gameplay state.

```gdscript
extends Control

func restart_run() -> void:
    %RunScreen.restart_run()
```

- [x] **Step 5: Verify GREEN**

Run the focused loop test and every existing headless QA command. Expected final snapshot: `status=complete`, `floor=15`, three story IDs, three selected Quirks.

- [x] **Step 6: Commit and push**

```bash
git add scripts/app scripts/game/run_controller.gd scenes/app scenes/game/run_screen.tscn scripts_dev/qa/headless/playable_loop_test.gd
git commit -m "feat: add complete playable tower run"
git push origin main
```

---

### Task 4: Main Scene Settings and Runtime Proof

**Files:**
- Create: `scripts_dev/qa/headless/main_scene_test.gd`
- Modify via Godot MCP: `project.godot` application and display settings.
- Modify: `docs/canonical/architecture.md`
- Modify: `docs/canonical/qa.md`
- Modify: `docs/canonical/work_state.md`

**Interfaces:**
- Produces: Run Project resolves to `res://scenes/app/main.tscn` at 720×1280 portrait.

- [x] **Step 1: Write and run the failing settings test**

```gdscript
extends SceneTree

func _init() -> void:
    assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/app/main.tscn")
    assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 720)
    assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 1280)
    quit()
```

Expected: FAIL because no main scene is configured.

- [x] **Step 2: Set project settings through Godot MCP**

Preflight with `godot-mcp status`, launch at most one editor, then use `godot-mcp project set-setting` for:

```text
application/run/main_scene = res://scenes/app/main.tscn
display/window/size/viewport_width = 720
display/window/size/viewport_height = 1280
display/window/size/window_width_override = 360
display/window/size/window_height_override = 640
```

Keep the official addon's debug-only `MCPGameInspector` and `MCPGameInput` autoloads while the plugin is enabled so runtime QA works. Disabling the plugin before an export removes both.

- [x] **Step 3: Verify settings GREEN and run full QA**

Run `main_scene_test.gd`, every focused/headless test, smoke, 10,000-run balance, project guard, and `git diff --check`.

- [x] **Step 4: Runtime playtest through Godot MCP**

Run the main scene, inspect the live tree, complete each of the three challenge inputs, verify Quirk/story overlays, force and restart a game-over run, complete floor 15, inspect runtime errors, and capture a screenshot for visual review.

- [x] **Step 5: Update current documentation**

Record the new folder ownership, main scene, observed macOS runtime proof, and remaining Android/iOS/audio/haptic/monetization gaps. Do not claim device verification.

- [x] **Step 6: Commit and push**

```bash
git add project.godot scripts_dev/qa/headless/main_scene_test.gd docs/canonical
git commit -m "chore: configure playable main scene"
git push origin main
```

- [x] **Step 7: Final repository check**

Verify `git status --short` is empty and `git rev-parse HEAD` matches `git rev-parse origin/main`.
