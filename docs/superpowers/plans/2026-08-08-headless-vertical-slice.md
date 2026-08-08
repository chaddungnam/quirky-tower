# Quirky Tower Headless Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deterministic 15-floor Quirky Tower run that can be smoke-tested and balance-simulated with Godot 4.7 headless before any production UI is added.

**Architecture:** Pure `RefCounted` core classes own challenge evaluation, run state, quirks, story triggers, Sponsor Boosts, and simulation. JSON files own tuneable content. Thin `SceneTree` QA scripts load the core and fail with non-zero exits; no core file depends on Node, UI, ads, billing, or Supabase.

**Tech Stack:** Godot 4.7 stable, GDScript, JSON, shell structure checks, upstream Godot MCP/CLI 0.7.2 development addon.

## Global Constraints

- First playable proof is headless: 15 floors, 3 challenge types, 4 Quirks.
- `.gd` warns above 500 lines and fails above 800; `.md` warns above 600 and fails above 1200.
- `scripts/core` must not reference Node, UI, AdMob, billing, or Supabase.
- Paid and rewarded-ad Sponsor Boost paths produce identical gameplay benefits and limits.
- Country and humorous affiliation choices share one `country` code field and one `국가/소속` category.
- Official/assisted and paid/free rankings are not split; only invalid or cheated results are rejected.
- External addons are installed from an upstream release without local modification.
- Every task ends with tests, commit, and push to `origin/main` without asking for a separate Git confirmation.

---

### Task 1: Development Tooling and Repository Guard

**Files:**
- Create: `addons/godot_mcp/**` from upstream `godot-mcp-addon_0.7.2.zip`
- Modify: `project.godot`
- Create: `scripts_dev/qa/check_project.sh`
- Create: `docs/canonical/README.md`
- Create: `docs/canonical/work_state.md`

**Interfaces:**
- Consumes: Godot 4.7 at `/Applications/Godot.app/Contents/MacOS/Godot`.
- Produces: `bash scripts_dev/qa/check_project.sh`, the single structural QA entrypoint used by all later tasks.

- [x] **Step 1: Fetch and verify the upstream addon**

Download release `v0.7.2` from `regiellis/godot-mcp-go` into a temporary directory. Verify SHA-256 exactly:

```text
5e7321d1848e6a8dc2ca18abfd23884510026be8f2d5cae547c49d3f84f856c5  godot-mcp-addon_0.7.2.zip
```

Extract only the packaged `addons/godot_mcp` tree into this repository. Do not copy House Duck's modified MCP.

- [x] **Step 2: Enable the editor plugin**

Add this project setting, using the actual `plugin.cfg` path found in the verified archive:

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")
```

- [x] **Step 3: Write the failing structure check**

Create `scripts_dev/qa/check_project.sh` so it exits non-zero when:

- a project `.gd` file outside `addons/` exceeds 800 lines;
- a project `.md` file outside `addons/` exceeds 1200 lines;
- a `scripts/core/*.gd` file contains `extends Node`, `Control`, `AdMob`, `Billing`, or `Supabase`;
- a Markdown link in `docs/canonical/README.md` points to a missing canonical file.

It must print warnings at 500 `.gd` lines and 600 `.md` lines, then run Godot headless import/parse:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
```

- [x] **Step 4: Run the check and verify the missing canonical index fails**

Run: `bash scripts_dev/qa/check_project.sh`

Expected: FAIL naming `docs/canonical/README.md` before the index is created.

- [x] **Step 5: Add the canonical index and work state**

`docs/canonical/README.md` links to the approved design, this implementation plan, and `work_state.md`. `work_state.md` records the current P0 as “headless 15-floor vertical slice” and the policy to commit and push completed project work automatically.

- [x] **Step 6: Verify and publish**

Run:

```bash
bash scripts_dev/qa/check_project.sh
git diff --check
git add addons/godot_mcp project.godot scripts_dev/qa/check_project.sh docs/canonical
git commit -m "chore: add Godot tooling and project guard"
git push origin main
```

Expected: structural QA passes and `main` is clean against `origin/main`.

---

### Task 2: Validated Game Catalog

**Files:**
- Create: `data/gameplay/challenges.json`
- Create: `data/gameplay/quirks.json`
- Create: `data/gameplay/floors.json`
- Create: `data/story/events.json`
- Create: `data/economy/sponsor_boost.json`
- Create: `data/localization/country_affiliations.json`
- Create: `scripts/core/run/game_catalog.gd`
- Create: `scripts_dev/qa/headless/catalog_test.gd`

**Interfaces:**
- Produces: `GameCatalog.load_default() -> GameCatalog`, `GameCatalog.validate() -> PackedStringArray`, and dictionaries named `challenges`, `quirks`, `floors`, `story_events`, `sponsor_boost`, `country_entries`.

- [ ] **Step 1: Write the catalog test**

The test loads all six JSON files, asserts there are exactly 3 challenge IDs (`timing_ring`, `tap_panic`, `drag_dodge`), 4 Quirk IDs, 15 floors, story triggers at 5/10/15, one Sponsor Boost, and both `DE` and `ALN` country codes. It also constructs an invalid catalog and asserts `validate()` reports its missing challenge reference.

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/catalog_test.gd
```

Expected: FAIL because `game_catalog.gd` does not exist.

- [ ] **Step 3: Add the minimum JSON content**

- Challenges carry `id`, `base_difficulty`, `base_score`.
- Quirks carry `id` and their one tuneable value.
- Floors contain 15 entries cycling the 3 challenge IDs with rising difficulty; floors 5, 10, and 15 are checkpoints.
- Story events contain floor 5 broadcast glitch, floor 10 host contradiction, and floor 15 finale secret.
- Sponsor Boost contains `id: sponsor_guard`, `hearts: 1`, `run_limit: 1`, `daily_limit: 5`.
- Country entries include ordinary codes `KR`, `DE` and faction codes `ALN`, `SGV`, `RPT`, all in one array.

- [ ] **Step 4: Implement strict loading and validation**

`GameCatalog` uses `FileAccess.get_file_as_string()` and `JSON.parse_string()`. Empty, malformed, or wrong-shaped files produce a validation error containing the exact resource path. Cross-reference every floor challenge ID and reject duplicate country codes.

- [ ] **Step 5: Verify and publish**

Run the catalog test, the project guard, and `git diff --check`; then commit and push:

```bash
git add data scripts/core/run/game_catalog.gd scripts_dev/qa/headless/catalog_test.gd
git commit -m "feat: add validated headless game catalog"
git push origin main
```

---

### Task 3: Challenge Rules and Run State

**Files:**
- Create: `scripts/core/challenges/challenge_rules.gd`
- Create: `scripts/core/run/run_state.gd`
- Create: `scripts_dev/qa/headless/challenge_rules_test.gd`

**Interfaces:**
- Produces: `ChallengeRules.evaluate(challenge_id: String, input_value: float, difficulty: float, modifiers: Dictionary = {}) -> Dictionary` with keys `success`, `quality`, `score`.
- Produces: `RunState.new_run(seed: int, country: String) -> RunState`, `snapshot() -> Dictionary`, and `restore(data: Dictionary) -> RunState`.

- [ ] **Step 1: Write failing rule tests**

Assert these boundaries:

- `timing_ring`: distance from `0.5` within its width succeeds;
- `tap_panic`: normalized input meeting difficulty succeeds;
- `drag_dodge`: input inside the safe interval succeeds;
- `wide_window` increases only the timing success width;
- unknown challenge IDs return an error result rather than silently succeeding.

Assert a `RunState` snapshot round-trip preserves seed, floor, hearts, combo, score, Quirks, checkpoint, boost usage, and `country` including faction code `ALN`.

- [ ] **Step 2: Verify the tests fail**

Run both new test scripts with Godot `--headless --script`.

Expected: FAIL because the rule and state classes are missing.

- [ ] **Step 3: Implement the three direct evaluators**

Use a `match challenge_id` in one class. Do not create a base challenge interface or three one-method classes. Clamp quality to `0.0..1.0` and calculate integer score from quality and difficulty.

- [ ] **Step 4: Implement serializable RunState**

Initial values are floor `1`, hearts `3`, combo `0`, score `0`, empty Quirks, checkpoint floor `1`, and unused Sponsor Boost. Reject snapshots with unsupported `version`, floor outside `1..15`, negative hearts, or non-array Quirks.

- [ ] **Step 5: Verify and publish**

Run both focused tests plus the project guard, then commit and push:

```bash
git add scripts/core/challenges scripts/core/run/run_state.gd scripts_dev/qa/headless
git commit -m "feat: add challenge rules and run state"
git push origin main
```

---

### Task 4: Quirks, Sponsor Boost, and Run Engine

**Files:**
- Create: `scripts/core/quirks/quirk_rules.gd`
- Create: `scripts/core/economy/sponsor_boost.gd`
- Create: `scripts/core/run/run_engine.gd`
- Create: `scripts_dev/qa/headless/run_engine_test.gd`

**Interfaces:**
- Produces: `QuirkRules.modifiers(quirk_ids: Array) -> Dictionary`.
- Produces: `SponsorBoost.apply(state: RunState, source: String) -> Dictionary` where source is `ad` or `paid`.
- Produces: `RunEngine.resolve_floor(state: RunState, catalog: GameCatalog, input_value: float) -> Dictionary`.

- [ ] **Step 1: Write failing engine tests**

Assert:

- success increments combo and score, then advances one floor;
- failure clears combo and consumes one heart;
- floor 5, 10, and 15 results include the matching story event;
- checkpoints update only at configured checkpoint floors;
- `replay` protects exactly one failure;
- `overheat_combo` raises successful combo score and raises failure risk;
- `reroute` changes the next challenge deterministically;
- applying `sponsor_guard` from `ad` and `paid` to identical states produces identical state snapshots;
- a second Boost in one run is refused;
- country `ALN` remains a normal single grouping value in the result.

- [ ] **Step 2: Verify the engine test fails**

Run the test with Godot headless.

Expected: FAIL because the three implementation files are missing.

- [ ] **Step 3: Implement Quirk modifiers**

Support exactly four IDs: `wide_window`, `overheat_combo`, `replay`, `reroute`. Return a flat modifier dictionary consumed by existing challenge and run rules.

- [ ] **Step 4: Implement Boost equality and limits**

Accept only `ad` or `paid`, apply one extra heart for `sponsor_guard`, store source for analytics, and compare gameplay snapshots after removing the analytics-only source key. The second application returns `{ "ok": false, "reason": "run_limit" }`.

- [ ] **Step 5: Implement the run engine**

Resolve one floor per call from catalog data. The engine owns combo, heart, score, checkpoint, story event, and finish/game-over transitions. It emits a result dictionary; it does not print, save files, or touch a scene.

- [ ] **Step 6: Verify and publish**

Run all headless tests and the project guard, then commit and push:

```bash
git add scripts/core/quirks scripts/core/economy scripts/core/run/run_engine.gd scripts_dev/qa/headless
git commit -m "feat: add deterministic headless run engine"
git push origin main
```

---

### Task 5: Fixed-Seed Smoke Run and Checkpoint Recovery

**Files:**
- Create: `scripts/core/simulation/run_simulator.gd`
- Create: `scripts_dev/qa/headless/run_smoke.gd`

**Interfaces:**
- Produces: `RunSimulator.simulate(seed: int, options: Dictionary = {}) -> Dictionary`.
- Produces command: `godot --headless --path . --script scripts_dev/qa/headless/run_smoke.gd -- --seed=424242`.

- [ ] **Step 1: Write the failing smoke assertions**

For seed `424242`, run once without Boost and twice with `ad` and `paid`. Assert:

- each run ends as `complete` or `game_over` with no impossible state;
- repeating a seed and options yields identical summary JSON;
- ad and paid summaries match after removing `boost_source`;
- a checkpoint snapshot restored midway yields the same final summary;
- story event IDs are ordered and never duplicated;
- `country=ALN` is preserved exactly.

- [ ] **Step 2: Verify the smoke fails**

Run the smoke script and expect a missing simulator parse error.

- [ ] **Step 3: Implement the deterministic bot**

Create one `RandomNumberGenerator`, set `seed`, and generate input values with `randf()`. Choose Quirks at floors 4, 8, and 12 from the catalog by the same RNG. Return only JSON-serializable summary data.

- [ ] **Step 4: Verify and publish**

Run the smoke twice, compare output, run all headless tests and the guard, then commit and push:

```bash
git add scripts/core/simulation scripts_dev/qa/headless/run_smoke.gd
git commit -m "test: add deterministic headless run smoke"
git push origin main
```

---

### Task 6: 10,000-Run Balance Report

**Files:**
- Create: `scripts_dev/qa/headless/run_balance.gd`
- Create: `qa_output/.gitkeep`
- Modify: `.gitignore`

**Interfaces:**
- Produces command: `godot --headless --path . --script scripts_dev/qa/headless/run_balance.gd -- --runs=10000`.
- Produces ignored artifact: `qa_output/headless_balance.json`.

- [ ] **Step 1: Write report assertions before aggregation**

The script exits non-zero unless the report includes:

- `run_count` exactly matching the requested count;
- floor reach counts for `1..15` that never increase as floors rise;
- success counts for all three challenge IDs;
- selection counts for all four Quirk IDs;
- combo histogram;
- unboosted, ad-boosted, and paid-boosted completion rates;
- zero impossible states;
- identical ad and paid gameplay aggregates.

- [ ] **Step 2: Run and verify the report fails**

Run with `--runs=10`.

Expected: FAIL because aggregation is not implemented.

- [ ] **Step 3: Implement one-pass aggregation**

Loop seeds `1..run_count`, rotate Boost mode by seed modulo 3, and update dictionaries in memory. Write one JSON result at the end; do not retain every run.

- [ ] **Step 4: Run the full balance pass**

Run with `--runs=10000` and assert it completes without parse errors, impossible states, or ad/paid divergence.

- [ ] **Step 5: Verify and publish**

Ignore generated `qa_output/*.json` while retaining `.gitkeep`. Run all QA and commit code only:

```bash
git add .gitignore qa_output/.gitkeep scripts_dev/qa/headless/run_balance.gd
git commit -m "test: add headless balance simulation"
git push origin main
```

---

### Task 7: Canonical Handoff and Final Verification

**Files:**
- Create: `docs/canonical/product.md`
- Create: `docs/canonical/gameplay.md`
- Create: `docs/canonical/story.md`
- Create: `docs/canonical/economy.md`
- Create: `docs/canonical/architecture.md`
- Create: `docs/canonical/design_policy.md`
- Create: `docs/canonical/qa.md`
- Modify: `docs/canonical/README.md`
- Modify: `docs/canonical/work_state.md`

**Interfaces:**
- Produces: current, linked documentation under 600 lines per file and one copyable QA command sequence.

- [ ] **Step 1: Write concise canonical documents**

Each document records only its current contract and links back to the approved design. `economy.md` states capped pay-or-watch equality; `design_policy.md` states the future Theme/DesignTokens/component rule; `architecture.md` states the core dependency boundary; `qa.md` lists exact headless commands and the real-device gap.

- [ ] **Step 2: Update the current work state**

Mark the headless vertical slice with observed PASS/FAIL counts and balance artifact path. Set the next P0 to human review of simulation balance before creating production UI.

- [ ] **Step 3: Run the complete verification sequence**

```bash
bash scripts_dev/qa/check_project.sh
for test_file in scripts_dev/qa/headless/*_test.gd; do
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "$test_file"
done
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/run_smoke.gd -- --seed=424242
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts_dev/qa/headless/run_balance.gd -- --runs=10000
git diff --check
```

Expected: every command exits `0`; the report records `10,000` runs and zero impossible states.

- [ ] **Step 4: Commit, push, and verify the remote**

```bash
git add docs/canonical
git commit -m "docs: record headless prototype contracts"
git push origin main
git status --short --branch
git ls-remote --heads origin main
```

Expected: clean `main...origin/main` and remote main points at local `HEAD`.
