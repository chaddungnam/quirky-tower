# Quirky Tower 2.5D Stage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat dodge drawing with a playable fixed-camera 2.5D corridor while preserving the existing floor rules and vertical UI flow.

**Architecture:** `TowerTrial` remains the phase/result owner and embeds one `TowerStage3D` through a `SubViewport`. The stage owns native 3D presentation and physics and reports hits with one signal.

**Tech Stack:** Godot 4.7, GDScript, native 3D nodes, existing headless QA scripts.

## Global Constraints

- Godot built-in features only; no new dependency or external 3D asset.
- Keep `RunEngine`, challenge IDs, 15-floor data, and result input contract unchanged.
- Keep popup and multi-choice actions vertical for variable translated text lengths.
- Keep new `.gd` files below 500 lines and new `.md` files below 600 lines.

---

### Task 1: Prove the native 3D stage contract

**Files:**
- Create: `scripts_dev/qa/headless/tower_stage_3d_test.gd`
- Modify: `scripts_dev/qa/headless/tower_trial_test.gd`

**Interfaces:**
- Produces: assertions for `Camera`, `Floor`, `Player`, `Hazards`, and `player_hit`.

- [ ] Write a test that instantiates the wished-for stage, checks an orthographic oblique camera, native bodies/shapes, a nearest-filtered pixel sprite, route hazard count, and real overlap signal.
- [ ] Add a `TowerTrial` assertion for `WorldViewport/TowerStage3D` and stage phase calls.
- [ ] Run both tests and confirm failure because the stage scene/node does not exist.

### Task 2: Build the minimal native stage

**Files:**
- Create: `scenes/game/world/tower_stage_3d.tscn`
- Create: `scripts/game/world/tower_stage_3d.gd`

**Interfaces:**
- Produces: `signal player_hit`, `configure(route, difficulty)`, `start_dodge()`, `set_player_axis(axis)`, `show_smash()`, `show_feedback(quality)`, `reset_stage()`.

- [ ] Build one fixed orthographic `Camera3D`, functional light/environment, collidable floor/walls, and a visible exit.
- [ ] Build the pixel `Sprite3D` player on `CharacterBody3D` and move it on X in `_physics_process`.
- [ ] Create only the selected route's 2–4 low-poly `Area3D` hazards and emit `player_hit` from real physics overlap.
- [ ] Run `tower_stage_3d_test.gd` until it passes, then validate/lint the new script.

### Task 3: Integrate the stage with the floor loop

**Files:**
- Modify: `scenes/game/challenges/tower_trial.tscn`
- Modify: `scripts/game/challenges/tower_trial.gd`

**Interfaces:**
- Consumes: the stage interface from Task 2.
- Preserves: `signal finished(input_value: float, score_multiplier: float)`.

- [ ] Put the stage in a full-rect `SubViewportContainer` behind the existing labels and route panel.
- [ ] Route drag/touch X into `set_player_axis`, replace rectangle collision with `player_hit`, and keep the existing 3-second/timing/result state machine.
- [ ] Keep only the 2D timing gauge and feedback overlay in `_draw`.
- [ ] Run the stage, trial, playable-loop, and app-shell tests.

### Task 4: Apply the Tower visual system once

**Files:**
- Modify: `scripts/ui/design_tokens.gd`
- Modify: `ui/themes/app_theme.tres`
- Modify: `scripts/ui/home_screen.gd`
- Modify: `scripts/ui/settings_screen.gd`
- Modify: `scripts/ui/splash_screen.gd`
- Modify: `scripts/ui/game_overlay.gd`
- Modify: `scripts/game/run_controller.gd`

**Interfaces:**
- Produces: semantic roles `BACKGROUND`, `SURFACE`, `TEXT`, `PRIMARY`, `SECONDARY`, `WARNING`, `SECRET`, `DANGER` with legacy aliases.

- [ ] Change the theme role values once and migrate app-shell callers to semantic roles.
- [ ] Use route-specific lime/peach/lavender selection feedback without copying the reference's space inventory UI.
- [ ] Run UI/app-shell QA and inspect 360×640 screenshots for wrapping and contrast.

### Task 5: Verify and record the working slice

**Files:**
- Modify: `docs/canonical/gameplay.md`
- Modify: `docs/canonical/design_policy.md`
- Modify: `docs/canonical/work_state.md`

**Interfaces:**
- Records: current 2.5D runtime truth and unverified device boundaries.

- [ ] Run every headless test, `check_project.sh`, `git diff --check`, and Godot script validation.
- [ ] Play the main scene through home → route → dodge → smash → result; capture and inspect runtime screenshots and errors.
- [ ] Record that macOS/headless evidence does not prove Android/iOS performance, touch feel, or final font rendering.
- [ ] Review the diff, commit the scoped files, and push `main`.
