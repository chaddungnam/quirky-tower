# Prototype App Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a playable app-start banner, prototype home, settings, live language switching, and translation-safe vertical choice popups around the existing 15-floor run.

**Architecture:** Expand the existing `Main` scene into a signal-driven app shell with four child screens. Reuse `AppTheme`, `DesignTokens`, and `GameOverlay`; keep all multi-choice actions in the overlay's single vertical scroll path.

**Tech Stack:** Godot 4.7 stable, GDScript, existing Theme/DesignTokens, official Godot MCP 0.7.2.

## Global Constraints

- Supabase, accounts, online rankings, ads, billing, final art, real audio, and real haptics are excluded.
- The app-owned splash including fade must finish within 2 seconds; target 1.5 seconds.
- Every popup choice is vertical, wraps long text, scrolls when needed, and has at least 96px touch height at the 720×1280 base size.
- UI strings cover `ko`, `en`, `de`, `ja`, `fr`, `es`, `it`, `zh_CN`, `zh_TW`, and `ar`, with English fallback.
- Use existing theme tokens; add no dependency and do not copy Quirky Ball monoliths.
- Runtime evidence is macOS 360×640 only and does not prove Android/iOS behavior.

---

### Task 1: Vertical popup contract

**Files:**
- Modify: `scenes/ui/components/game_overlay.tscn`
- Modify: `scripts/ui/game_overlay.gd`
- Modify: `scripts_dev/qa/headless/ui_foundation_test.gd`

**Interfaces:**
- Consumes: existing `show_message` and `show_choices` callers.
- Produces: `show_actions(title, body, options, action)` with vertical wrapped scrollable buttons.

- [ ] **Step 1: Write the failing test**

Add two long German choices, then assert `Actions` is a `VBoxContainer` inside a `ScrollContainer`, every button has `autowrap_mode == TextServer.AUTOWRAP_WORD_SMART`, and every button is at least `96` pixels tall.

- [ ] **Step 2: Run test to verify RED**

Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts_dev/qa/headless/ui_foundation_test.gd`.

Expected: FAIL because the existing actions are not inside a scroll container and use 72px buttons without wrapping.

- [ ] **Step 3: Implement the minimum shared change**

Move `Actions` under `ActionScroll`, raise `DesignTokens.TOUCH_HEIGHT` to 96, enable smart word wrap on every generated button, and route message, choices, and multi-actions through one button builder.

- [ ] **Step 4: Run the focused test**

Run the same command. Expected: `PASS ui_foundation_test`.

### Task 2: App shell, splash, home, and settings

**Files:**
- Create: `scripts/ui/ui_text.gd`
- Create: `scripts/ui/splash_screen.gd`
- Create: `scripts/ui/home_screen.gd`
- Create: `scripts/ui/settings_screen.gd`
- Create: `scenes/ui/screens/splash_screen.tscn`
- Create: `scenes/ui/screens/home_screen.tscn`
- Create: `scenes/ui/screens/settings_screen.tscn`
- Modify: `scenes/app/main.tscn`
- Modify: `scripts/app/main.gd`
- Create: `scripts_dev/qa/headless/app_shell_test.gd`

**Interfaces:**
- `SplashScreen` produces `finished`.
- `HomeScreen` produces `play_requested` and `settings_requested`.
- `SettingsScreen` consumes `set_language(code)` and produces `back_requested` and `language_requested`.
- `Main` produces `show_home()`, `show_run()`, `show_settings()`, and `select_language(code)`.

- [ ] **Step 1: Write the failing app-flow test**

Instantiate `Main`, assert Splash is the only visible screen, call the real splash completion path, emit the Settings button, choose German from the real vertical popup, return home, and emit Play. Assert the visible screen and German settings title after every transition.

- [ ] **Step 2: Run test to verify RED**

Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts_dev/qa/headless/app_shell_test.gd`.

Expected: FAIL because the three UI scenes and app-shell transitions do not exist.

- [ ] **Step 3: Implement minimal screens**

Use container-driven `.tscn` layouts, existing theme colors, and small scripts. Keep the 10-language copy in `ui_text.gd`, with English fallback. Draw the home tower background in `HomeScreen._draw()` so no new art dependency is needed.

- [ ] **Step 4: Add run-to-home exit**

Modify `scripts/game/run_controller.gd` so the run-end overlay uses two vertical actions: `PLAY AGAIN` and `HOME`. Emit `home_requested`; connect it in `Main`.

- [ ] **Step 5: Run focused tests**

Run `app_shell_test.gd`, `ui_foundation_test.gd`, and `playable_loop_test.gd`. Expected: all PASS.

### Task 3: Full verification and handoff

**Files:**
- Modify: `docs/canonical/design_policy.md`
- Modify: `docs/canonical/qa.md`
- Modify: `docs/canonical/work_state.md`

**Interfaces:**
- Consumes: fresh automated and Godot MCP runtime evidence.
- Produces: current UI policy, proof, and explicit device/backend gaps.

- [ ] **Step 1: Run all project checks**

Run `bash scripts_dev/qa/check_project.sh`, every `scripts_dev/qa/headless/*_test.gd`, fixed-seed smoke, and 10,000-run balance.

- [ ] **Step 2: Run actual 360×640 input flow**

After `godot-mcp status`, play main, wait for the home, click Settings, open Language, click Deutsch, return home, click Play, and read back the visible screen after each input.

- [ ] **Step 3: Inspect captures and errors**

Capture settled home and German settings screens, inspect them visually, then confirm `runtime errors` has no game-script errors.

- [ ] **Step 4: Update canonical docs**

Record only observed checks; retain Android/iOS safe area, actual touch, audio, haptics, ads, billing, Supabase, and online ranking as unverified.

- [ ] **Step 5: Commit and push**

Run `git diff --check`, commit the complete app-shell slice, push `main` to `origin/main`, and confirm clean status.
