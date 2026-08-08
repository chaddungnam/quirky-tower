# Integrated Tower Trial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the disconnected playable challenge rotation with one floor sequence that combines route choice, direct dodging, timed smashing, risk-reward scoring, and immediate catharsis.

**Architecture:** Keep the existing headless challenge IDs and 15-floor `RunEngine`. Route risk enters the engine only as an optional successful-score multiplier. A single `TowerTrial` Control owns the three interactive phases and converts its combined performance back into the input format expected by each existing challenge ID.

**Tech Stack:** Godot 4.7 stable, GDScript, existing Theme/DesignTokens, existing JSON/core rules, official Godot MCP 0.7.2.

## Global Constraints

- Keep the 15-floor run, hearts, combo, checkpoints, story, Quirks, Sponsor Boost equivalence, and country/affiliation field.
- Use the existing 720×1280 portrait project settings and shared theme tokens.
- Do not add dependencies, final art, audio, haptics, ads, billing, Supabase, rankings, home, or tutorial pages.
- Preserve the three existing standalone challenge scenes for reference and existing contract tests.
- Use deferred node deletion during signal callbacks.
- Distinguish macOS mouse evidence from Android/iOS device evidence.

---

### Task 1: Risk-reward score multiplier

**Files:**
- Modify: `scripts/core/run/run_engine.gd`
- Test: `scripts_dev/qa/headless/run_engine_test.gd`

**Interfaces:**
- Consumes: existing `RunEngine.resolve_floor(state, catalog, input_value)` callers.
- Produces: `RunEngine.resolve_floor(state, catalog, input_value, score_multiplier := 1.0) -> Dictionary` with a clamped `1.0..1.5` multiplier applied only to successful score.

- [ ] **Step 1: Write the failing test**

```gdscript
var safe_state = RunState.new_run(20, "DE")
var risky_state = RunState.new_run(20, "DE")
RunEngine.resolve_floor(safe_state, catalog, 0.5, 1.0)
RunEngine.resolve_floor(risky_state, catalog, 0.5, 1.5)
assert(risky_state.score > safe_state.score, "risk route multiplies successful score")
```

- [ ] **Step 2: Run test to verify RED**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts_dev/qa/headless/run_engine_test.gd`

Expected: FAIL because `resolve_floor` accepts only three arguments.

- [ ] **Step 3: Implement the minimum engine change**

Clamp the optional multiplier and include it in the existing successful-score calculation. Do not store route state in `RunState`.

- [ ] **Step 4: Run test to verify GREEN**

Run the same command. Expected: `PASS run_engine_test`.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/run/run_engine.gd scripts_dev/qa/headless/run_engine_test.gd
git commit -m "feat: score risky tower routes"
```

### Task 2: Unified interactive floor scene

**Files:**
- Create: `scenes/game/challenges/tower_trial.tscn`
- Create: `scripts/game/challenges/tower_trial.gd`
- Create: `scripts_dev/qa/headless/tower_trial_test.gd`

**Interfaces:**
- Consumes: `setup(difficulty: float, modifiers: Dictionary, challenge_id: String)` and shared Theme/DesignTokens.
- Produces: `finished(input_value: float, score_multiplier: float)` and `begin()`.

- [ ] **Step 1: Write the failing scene test**

Instantiate `tower_trial.tscn`, call `setup` and `begin`, emit the real first route button, advance the real `_process` with obstacles cleared, send a real mouse press to `_gui_input`, and assert the scene emits a valid input plus the selected route multiplier.

- [ ] **Step 2: Run test to verify RED**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts_dev/qa/headless/tower_trial_test.gd`

Expected: FAIL because the scene does not exist.

- [ ] **Step 3: Implement the scene**

Use one small phase state machine:

```text
route -> dodge (3 seconds) -> smash -> feedback (0.55 seconds) -> finished
```

Build the three route buttons in the existing `RouteActions` container. Draw the arena, participant, falling barriers, smash track, door, heat bar, flash, and debris with native `Control._draw`. Accept horizontal mouse/touch drag only during dodge and one mouse/touch press only during smash. Convert combined dodge/timing quality to the selected challenge ID's existing input scale.

- [ ] **Step 4: Run test to verify GREEN**

Run the same command. Expected: `PASS tower_trial_test`.

- [ ] **Step 5: Validate and lint**

Run:

```bash
godot-mcp script validate --path res://scripts/game/challenges/tower_trial.gd
godot-mcp script lint --path res://scripts/game/challenges/tower_trial.gd
```

Expected: compile success and zero lint errors.

- [ ] **Step 6: Commit**

```bash
git add scenes/game/challenges/tower_trial.tscn scripts/game/challenges/tower_trial.gd scripts_dev/qa/headless/tower_trial_test.gd
git commit -m "feat: add integrated tower trial"
```

### Task 3: Connect every floor to the unified trial

**Files:**
- Modify: `scripts/game/run_controller.gd`
- Modify: `scripts_dev/qa/headless/playable_loop_test.gd`
- Modify: `scripts_dev/qa/headless/challenge_scene_test.gd`

**Interfaces:**
- Consumes: `TowerTrial.setup(difficulty, modifiers, challenge_id)` and two-argument `finished` signal.
- Produces: `RunController.submit_challenge(input_value: float, score_multiplier := 1.0)`.

- [ ] **Step 1: Write the failing integration assertion**

After instantiating `RunScreen`, assert the active child is `TowerTrial`, not one of the standalone samples. Keep the full 15-floor core-driving test to prove story and Quirk flow remains intact.

- [ ] **Step 2: Run test to verify RED**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts_dev/qa/headless/playable_loop_test.gd`

Expected: FAIL because floor 1 still instantiates `TimingRing`.

- [ ] **Step 3: Implement the controller wiring**

Preload one `TOWER_TRIAL_SCENE`, instantiate it for all known challenge IDs, pass the current ID into setup, and forward the route score multiplier to `RunEngine.resolve_floor`. Keep unknown-ID error handling.

- [ ] **Step 4: Run focused tests**

Run the playable loop and challenge scene tests. Expected: both PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/game/run_controller.gd scripts_dev/qa/headless/playable_loop_test.gd scripts_dev/qa/headless/challenge_scene_test.gd
git commit -m "feat: run every floor through tower trial"
```

### Task 4: Honest QA, runtime playtest, and project verification

**Files:**
- Modify: `docs/canonical/qa.md`
- Modify: `docs/canonical/work_state.md`

**Interfaces:**
- Consumes: automated test output and observed Godot MCP runtime state.
- Produces: current evidence and remaining device/human-fun gaps.

- [ ] **Step 1: Run all automated checks**

Run project structure, every headless `*_test.gd`, fixed-seed smoke, and 10,000-run balance. Expected: all commands exit zero.

- [ ] **Step 2: Run actual Godot input path**

Launch exactly one editor after `godot-mcp status`, play main, click a route button, drag the participant, tap the smash target, click the result action, and read back the next floor and runtime errors.

- [ ] **Step 3: Inspect a runtime screenshot**

Capture the route and dodge/smash states and verify that controls, prompt, participant, obstacles, door, multiplier, and broadcast line are legible at 360×640 display scale.

- [ ] **Step 4: Update canonical state**

Record only observed PASS results. Keep Android/iOS, audio, haptics, final art, real ads, billing, Supabase, and human replay-fun explicitly unverified.

- [ ] **Step 5: Final verification and push**

Run `git diff --check`, commit documentation, push all commits to `origin/main`, and confirm a clean status.
