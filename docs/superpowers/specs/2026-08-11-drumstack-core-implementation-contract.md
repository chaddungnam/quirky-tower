# Drumstack Battle Gate A Core Implementation Contract

**Date:** 2026-08-11
**Status:** Gate A implementation authority
**Parent source of truth:** `docs/drumstack/DRUMSTACK_BATTLE_MASTER_SPEC.html`
**Applies to:** `DS-GAME-*`, `DS-MAP-*`, `DS-SKILL-*`, `DS-HERO-*`, `DS-AI-*`, `DS-TECH-*`, and their Gate A test IDs

## 1. Purpose and approval boundary

This document closes only the deterministic contracts that the parent master leaves implicit. It does not repeat the product, UI, art, audio, economy, ranking, or backend specification.

The user's 2026-08-11 approval of the master and follow-up request to proceed authorizes:

- Gate A data, pure battle rules, focused tests, deterministic Easy bot, and 10,000-match simulation;
- the minimal Gate B shell described in section 13 after Gate A passes;
- the parent master's proposed Gate A numbers as `rule_version = "gate-a-v1"` test values, not as launch-final balance.

The parent master now records product and HTML direction as approved while Gate 0 execution remains pending. This document does not authorize deleting legacy runtime, renaming the repository, connecting Supabase/ads/purchases, making final 3D assets, or implementing Gate E/F systems.

Any change to a field, formula, target shape, fixture coordinate, ordering rule, or expected event below requires a new `rule_version` and regenerated golden vectors. Balance-only changes may keep `schema_version = 1`.

## 2. Non-negotiable boundaries

- Core values are JSON-safe facts only. No `Node`, `Resource`, `Vector2/3`, callable, object reference, Tween, animation time, or physics result enters authority state.
- Coordinates are integer arrays `[x, y]`. The board origin is top-left, `x` grows right, `y` grows down.
- All combat numbers are integers. Authored multipliers use thousandths (`1150 = 1.150`). Runtime modifiers use basis points (`10000 = 100%`).
- `BattleRules.validate(state, command)` and `BattleRules.apply(state, command)` are the only authorities for legality and result.
- Preview, bot enumeration, and apply call the same `GridRules` and target-shape functions.
- View code consumes events. View code never changes HP, tiles, score, cooldowns, status, timers, or result.

## 3. Canonical BattleState schema

Every key below is required. A nullable value is present as JSON `null`; it is never omitted.

```json
{
  "schema_version": 1, "rule_version": "gate-a-v1",
  "mode_id": "bot_skirmish_v1", "map_id": "gate_a_arena_11x9_v1",
  "seed": 424242, "authority_elapsed_ms": 0,
  "active_turn_started_ms": 0, "action_index": 0,
  "current_actor_id": "a_chicken", "tie_priority_team": "A",
  "turn_gauges": [
    {"unit_id": "a_chicken", "value": 1080}
  ],
  "score": {"A": 0, "B": 0},
  "units": [
    {
      "unit_id": "a_chicken",
      "team_id": "A",
      "hero_id": "CHICKEN_RUSH",
      "tile": [1, 4],
      "hp": 650, "max_hp": 650,
      "atk": 136, "def": 18,
      "spd": 108, "mov": 4,
      "ko": false, "guard_active": false,
      "shield_hp": 0, "shield_remaining_actions": 0,
      "cooldowns": [
        {"skill_id": "CHICKEN_BASIC", "remaining": 0},
        {"skill_id": "CHICKEN_ACTIVE", "remaining": 0},
        {"skill_id": "CHICKEN_SIGNATURE", "remaining": 1}
      ],
      "statuses": []
    }
  ],
  "obstacles": [
    {"obstacle_id": "wall_01", "kind": "WALL", "tile": [3, 1], "active": true}
  ],
  "event_ledger": [],
  "result": null
}
```

The arrays are one-entry shape examples. `gate-a-v1` requires all six section-7 units and gauges and rejects abbreviated state. The separate `gate-0-first-turn-v1` profile may contain exactly `a_duck` and `b_training` plus both gauges for the public first-turn proof, but it keeps every schema key and can never satisfy Gate A or the 10k fixture.

### 3.1 State ordering and invariants

- `turn_gauges`, `units`, `cooldowns`, `statuses`, `obstacles`, and `event_ledger` are arrays, never object maps.
- `turn_gauges` and `units` sort by `unit_id`; cooldowns by `skill_id`; statuses by the status ordering in section 10; obstacles by `obstacle_id`; events by `event_index`.
- Living units occupy unique, in-bounds, non-blocked tiles. KO units keep their last tile for replay but do not block movement or LOS.
- `current_actor_id` is a living unit or `null` only after `result` is non-null.
- `action_index` is the count of completed authoritative actions. `DOT_KO` and `AUTO_GUARD` each count once.
- `authority_elapsed_ms` and `active_turn_started_ms` are non-negative integers and never decrease.
- `result` is either `null` or:

```json
{
  "outcome": "A_WIN", "reason": "ELIMINATION", "winner_team": "A",
  "score": {"A": 9, "B": 6},
  "tie_break_step": null, "ended_action_index": 17, "ended_at_ms": 183000
}
```

Allowed `outcome`: `A_WIN`, `B_WIN`, `DRAW`. Allowed `reason`: `ELIMINATION`, `ACTION_CAP`, `TIME_CAP`, `SURRENDER`, `SIMULTANEOUS_KO`.

### 3.2 Status entry

```json
{
  "status_id": "DOT",
  "source_id": "b_crow",
  "remaining_actions": 2,
  "value": 250,
  "applied_command_index": 6
}
```

All keys are required. `value` is an integer: fixed HP for shield-like data, stat points for speed, basis points for percent effects, or thousandths for DoT power. Status IDs are exactly `DOT`, `SPEED`, `IMMOBILE`, `MARK`, `WEAKEN`, `CHALLENGE`, `FORTIFY`, and `PUSH_IMMUNE`. Shield remains in the dedicated unit fields because only one shield may exist.

## 4. Canonical BattleCommand schema

```json
{
  "schema_version": 1,
  "command_id": "c_0007",
  "kind": "ACTION",
  "actor_id": "a_chicken",
  "move_path": [[1, 4], [2, 4], [3, 4]],
  "skill_id": "CHICKEN_BASIC",
  "target_tile": [4, 4],
  "authority_elapsed_ms": 12000
}
```

- `kind` is `ACTION`, `AUTO_GUARD`, or `SURRENDER`.
- `command_id` is unique inside one match. Gate A fixtures use `c_` plus zero-padded `action_index + 1`.
- `actor_id` equals `state.current_actor_id`. For surrender it is still the current actor.
- `move_path` always contains the actor's current tile as element 0. Staying is `[current_tile]`.
- `skill_id` is an authored skill ID or `GUARD`. It is `null` only for `SURRENDER`.
- `target_tile` is required for targeted skills and `null` for guard, surrender, and self-centered skills.
- `authority_elapsed_ms` is the trusted clock sample supplied by the local controller. Preview never mutates it.
- Timeout commands are generated by `BattleRules.make_timeout_command(state, now_ms)`. They use `AUTO_GUARD`, the actor's origin-only path, `GUARD`, and `target_tile = null`.
- Move and skill are one atomic command. A move preview that was never submitted is not part of state.

## 5. Canonical BattleEvent schema

Every event has this envelope:

```json
{
  "event_index": 0,
  "command_id": "c_0001",
  "action_index": 0,
  "type": "DAMAGE_APPLIED",
  "actor_id": "a_chicken",
  "source_id": "a_chicken",
  "target_id": "b_duck",
  "tile": [8, 6],
  "amount": 97,
  "status_id": null,
  "data": {"cause": "DIRECT", "hp_before": 960, "hp_after": 863, "shield_before": 0, "shield_after": 0}
}
```

All envelope keys are required. Non-applicable values are `null`; `data` is an object, possibly empty. Allowed Gate A event types, in possible emission order, are:

1. `ACTION_STARTED`
2. `DOT_TICKED`
3. `MOVE_STEP`
4. `SKILL_USED` or `GUARD_USED`
5. `DAMAGE_APPLIED`, `HEAL_APPLIED`, `SHIELD_APPLIED`
6. `PUSH_STEP`, `COLLISION_APPLIED`, `BARREL_TRIGGERED`
7. `STATUS_APPLIED`, `STATUS_REMOVED`
8. `UNIT_KO`
9. `SCORE_CHANGED`
10. `COOLDOWN_CHANGED`, `DURATION_CHANGED`
11. `TURN_GAUGE_CHANGED`, `TURN_ORDER_CHANGED`
12. `ACTION_ENDED`
13. `MATCH_ENDED`

Within one phase, targets sort by `target_id`; tiles by `tile_id`; obstacles by `obstacle_id`; status changes by the status ordering in section 10. `event_index` is the prior ledger length before append. A result event never appears before all authored damage, push, collision, barrel, KO, score, cooldown, and duration events from the command.

`data` accepts only the keys in this table; all listed keys are required for that event type:

| Event type | Exact `data` keys |
|---|---|
| `ACTION_STARTED`, `ACTION_ENDED` | `kind`, `skill_id` |
| `DOT_TICKED`, `DAMAGE_APPLIED` | `cause`, `hp_before`, `hp_after`, `shield_before`, `shield_after` |
| `MOVE_STEP`, `PUSH_STEP` | `from_tile`, `to_tile`, `step_index` |
| `SKILL_USED` | `skill_id`, `target_tile`, `affected_tiles` |
| `GUARD_USED` | `reduction_bp`, `expires_at_actor_start` |
| `HEAL_APPLIED` | `hp_before`, `hp_after`, `raw_heal`, `heal_cap` |
| `SHIELD_APPLIED` | `shield_before`, `shield_after`, `shield_cap`, `remaining_before`, `remaining_after` |
| `COLLISION_APPLIED` | `cause`, `other_unit_id`, `hp_before`, `hp_after`, `shield_before`, `shield_after` |
| `BARREL_TRIGGERED` | `obstacle_id`, `wave` |
| `STATUS_APPLIED`, `STATUS_REMOVED`, `DURATION_CHANGED` | `source_id`, `value`, `remaining_before`, `remaining_after`, `reason` |
| `UNIT_KO` | `cause`, `credited_source_id`, `credited_team_id` |
| `SCORE_CHANGED` | `team_id`, `before`, `after`, `delta`, `reason` |
| `COOLDOWN_CHANGED` | `skill_id`, `before`, `after` |
| `TURN_GAUGE_CHANGED` | `unit_id`, `before`, `after` |
| `TURN_ORDER_CHANGED` | `current_actor_id`, `next_six` |
| `MATCH_ENDED` | `result` |

## 6. Canonical serialization and hashing

- Canonical bytes are UTF-8 JSON with no whitespace or trailing newline.
- Object keys sort lexicographically by Unicode code point. All current keys and IDs are ASCII.
- Array order is preserved after applying section 3.1 ordering.
- Integers use base-10 without leading zero. Floats, `NaN`, infinities, negative zero, and exponent notation are forbidden.
- Strings use JSON escaping; Unicode text is encoded directly, not normalized at runtime.
- Hash is lowercase hexadecimal SHA-256 of canonical bytes.
- `state_hash` hashes the entire BattleState, including `event_ledger` and `authority_elapsed_ms`.
- `event_hash` hashes only the ordered event array returned by the current command.
- Preview output is never included in either hash.
- Before hashing, schema validation must reject unknown keys, missing keys, duplicate IDs, unsorted authoritative arrays, and out-of-range integers.

Positive rational results use one helper:

```text
round_half_up(numerator, denominator) = (numerator + floor(denominator / 2)) / denominator, integer division
```

No intermediate combat calculation rounds. 64-bit signed integers are the minimum implementation type.

## 7. Gate A 11×9 arena fixture

`map_id = "gate_a_arena_11x9_v1"`; valid coordinates are `x = 0..10`, `y = 0..8`. `tile_id = y * 11 + x`.

### 7.1 Spawns

| Unit | Tile |
|---|---:|
| `a_duck` | `[1,2]` |
| `a_chicken` | `[1,4]` |
| `a_pigeon` | `[1,6]` |
| `b_pigeon` | `[9,2]` |
| `b_chicken` | `[9,4]` |
| `b_duck` | `[9,6]` |

Team B is the 180-degree mirror of Team A. Team A uses the parent starter stats; Team B uses identical stats.

### 7.2 Obstacles

| Kind | IDs and tiles | Movement | LOS | Damage response |
|---|---|---|---|---|
| Wall | `wall_01 [3,1]`, `wall_02 [7,1]`, `wall_03 [5,2]`, `wall_04 [5,6]`, `wall_05 [3,7]`, `wall_06 [7,7]` | blocks | blocks | indestructible |
| Low box | `box_01 [4,3]`, `box_02 [6,3]`, `box_03 [4,5]`, `box_04 [6,5]` | blocks | passes | indestructible in Gate A |
| Barrel | `barrel_01 [5,3]`, `barrel_02 [3,4]`, `barrel_03 [7,4]`, `barrel_04 [5,5]` | blocks while active | passes | first damaging affected-tile event triggers it |

The 14 active obstacles occupy 14.14% of the board. No other Gate A object or random event exists in this fixture.

An active barrel hit emits `BARREL_TRIGGERED`, becomes inactive immediately, then deals fixed 60 to every living unit at Chebyshev distance 1 and pushes each affected unit 1 tile directly away using the sign of the coordinate delta. Damage sorts by target ID, then pushes sort by target ID. A barrel reached by this first explosion may trigger in one secondary wave; a secondary explosion cannot trigger another barrel. Each barrel triggers at most once per match. DEF and general modifiers do not apply; shield absorbs first.

Synthetic hazard golden tests may use smaller obstacle subsets, but they keep these barrel rules.

## 8. Movement, corner, range, LOS, and push

### 8.1 Explicit move path

A move path is legal only if all conditions pass:

1. Element 0 equals the actor's state tile; every tile is in bounds.
2. `path.size - 1 <= actor.mov`; an immobilized actor must submit a size-1 path.
3. Consecutive tiles differ by at most 1 on each axis and are not equal.
4. A tile never repeats in one path.
5. Every entered tile is movement-passable and not occupied by a living unit.
6. On a diagonal step, both orthogonal side tiles must be movement-passable and unoccupied. If either side is blocked, the diagonal is illegal.

Tile-tap preview chooses the shortest path. Equal-length paths compare their full `tile_id` sequence lexicographically; the lower sequence wins. Drag input may submit another legal explicit path. Gate A Easy bot uses only the canonical shortest path for each reachable destination.

### 8.2 Distance and LOS

- Movement, radius, and ordinary range use Chebyshev distance.
- A straight line requires `dx = 0`, `dy = 0`, or `abs(dx) = abs(dy)`.
- LOS is the supercover line between tile centers. Every grid cell touched by the segment is included; if the line passes exactly through a corner, both adjacent cells are included.
- Source and target cells do not block their own LOS. Any active intermediate object with `blocks_los = true` blocks it.
- Living and KO units, low boxes, and barrels do not block LOS in Gate A.
- A non-self targeted skill requires LOS unless its authored shape below says `LOS: no`.
- AoE determines affected tiles from the authored shape, then checks units/props on those tiles. It does not re-run LOS from center to each affected unit unless stated.

### 8.3 Push and collision

- Push resolves one tile at a time along the normalized sign vector from source to target.
- Push immunity cancels movement but not the skill's damage.
- An out-of-bounds or movement-blocked destination stops push and deals fixed 50 to the pushed unit.
- A living-unit-occupied destination stops push and deals fixed 35 to both units.
- Shield absorbs fixed collision damage first. DEF and general modifiers do not apply.
- A unit can receive at most one wall/unit collision event from one push instruction.

## 9. Exact starter target shapes

All target checks use the actor's tile after `move_path` resolves.

| Skill ID | Target and affected shape | LOS |
|---|---|---|
| `DUCK_BASIC` | one living enemy or active barrel at Chebyshev distance 1 | yes |
| `DUCK_ACTIVE` | choose one of 8 direction vectors `d`; affect offsets `o` where `1 <= Chebyshev(o) <= 2`, `dot(o,d) > 0`, and `abs(cross(o,d)) <= dot(o,d)` | no; actor-centered fan |
| `DUCK_SIGNATURE` | all living allies, including self, within Chebyshev radius 2 | no |
| `CHICKEN_BASIC` | one living enemy or active barrel at Chebyshev distance 1 | yes |
| `CHICKEN_ACTIVE` | first living enemy or active barrel on one of 8 straight rays at distance 1..3; all intermediate tiles must be movement-passable and unoccupied; actor dashes to the last empty tile before target, then applies hit and push | yes |
| `CHICKEN_SIGNATURE` | one living enemy or active barrel at Chebyshev distance 1, then push 1 if still active/living | yes |
| `PIGEON_BASIC` | one living enemy or active barrel at Chebyshev distance 1..4 | yes |
| `PIGEON_ACTIVE` | one living ally, including self, at Chebyshev distance 0..4 | yes except self |
| `PIGEON_SIGNATURE` | all living allies, including self, within Chebyshev radius 2 | no |
| `GUARD` | self; no target tile | no |

For a fan, `dot(o,d) = ox*dx + oy*dy` and `cross(o,d) = ox*dy - oy*dx`. `target_tile` selects direction only and must be the adjacent tile `actor_tile + d`; it need not contain a unit. Empty affected tiles remain valid. Offensive single-target skills are invalid on an empty target tile.

## 10. Action lifecycle, status, cooldown, and time

### 10.1 Authoritative action order

1. Validate actor, clock, command ID, path, cooldown, target, and shape.
2. Emit `ACTION_STARTED`.
3. Tick actor DoT stacks, then evaluate actor KO.
4. If actor survives, resolve explicit move path and movement contacts.
5. Snapshot skill targets; apply direct damage/heal/shield by target ID.
6. Apply simultaneous KO for the direct phase.
7. Resolve push, collision, barrel primary wave, then one secondary barrel wave.
8. Apply or cleanse statuses; update score.
9. Apply cooldown and duration lifecycle.
10. Increment action index, subtract 1000 from the acting unit gauge, and predict the next actor.
11. Evaluate elimination first, then action/time cap.
12. Emit `ACTION_ENDED`, then `MATCH_ENDED` if applicable.

If step 3 KOs the actor, that DoT tick is consumed, `action_index` increments, and 1000 gauge is subtracted. No move or skill occurs. The triggered DoT stack loses one remaining action; all other cooldowns, shield duration, and statuses on that KO unit freeze. Source KO does not cancel an existing DoT stack.

### 10.2 Cooldown

- Basic and active skills start at 0; signatures start at 1.
- A skill is legal only when its start-of-action `remaining` is 0.
- At action end, cooldowns that were greater than 0 at action start decrement by 1.
- After that decrement, the skill used this action is set to its authored CD. The newly set value never decrements in the same action.
- Guard has no stored cooldown.
- KO units never decrement cooldowns.

Therefore CD 2 blocks the next two actions of that caster and becomes usable on the third; initial CD 1 blocks the first action and is usable on the second.

### 10.3 Status ordering and lifetime

Status sort priority is `DOT`, `SPEED`, `IMMOBILE`, `MARK`, `WEAKEN`, `CHALLENGE`, `FORTIFY`, `PUSH_IMMUNE`, then `source_id`, then `applied_command_index`.

- A one-action status remains active through the target's next completed action and decrements after that action resolves.
- DoT ticks at target action start before other effects. Its own `remaining_actions` decrements after the tick.
- Mark is removed immediately after modifying the next direct-damage event.
- Cleanse removes one harmful status by highest remaining actions, then status priority, then source ID, then applied command index.
- Shield refresh keeps the larger current HP and longer remaining duration; it never adds values.
- A challenge remains even if its source is KO; it expires only by duration or cleanse.
- Guard sets `guard_active = true` at its action end. At that unit's next action start, clear it before DoT ticks; therefore guard does not reduce that next action-start DoT. While active it reduces direct damage and DoT by 15%, but never fixed collision or barrel damage.

### 10.4 Authority clock and timeout

- Bot skirmish uses `turn_limit_ms = 15000`, warning threshold 5000 remaining, `match_limit_ms = 420000`, and `action_cap = 24`.
- `authority_elapsed_ms` is milliseconds since match creation from a trusted monotonic source. It advances only when a command or timeout is submitted to core.
- A normal command is valid when `command.authority_elapsed_ms - active_turn_started_ms < 15000` and total elapsed is `< 420000`.
- At exactly 15000, core accepts only the generated origin-tile `AUTO_GUARD`.
- At exactly 420000, core first resolves that same auto-guard if no command is already resolving, then evaluates `TIME_CAP`.
- A command accepted below 420000 completes even if View playback crosses the wall-clock cap. No View duration enters core.
- After a completed action, `active_turn_started_ms` becomes the command's `authority_elapsed_ms` for the next actor.
- Tutorial mode overrides only `turn_limit_ms = null` and `match_limit_ms = null`; its action cap is 12.

## 11. Integer damage, healing, and shield

### 11.1 Direct damage

Authored power is `power_milli`; outgoing, exposure, and incoming are clamped basis points. Calculate once:

```text
numerator = ATK * power_milli * outgoing_bp * exposure_bp * 100 * incoming_bp
denominator = 1000 * 10000 * 10000 * (100 + DEF) * 10000
final_damage = max(1, round_half_up(numerator, denominator))
```

Shield absorbs first. Only HP removed contributes to damage tie-break. Excess damage and shield-only loss do not.

### 11.2 Healing

```text
raw_heal = round_half_up(ATK * heal_power_milli * heal_outgoing_bp, 1000 * 10000)
heal_cap = floor(target.max_hp * 28 / 100)
actual_heal = min(raw_heal, heal_cap, target.max_hp - target.hp)
```

`heal_outgoing_bp` is 12000 for Pigeon Medic's low-HP passive and 10000 otherwise. Overheal is not recorded as effective heal and does not affect bot score.

### 11.3 Shield

```text
shield_cap = floor(target.max_hp * 18 / 100)
offered_shield = min(authored_fixed_shield, shield_cap)
new_shield_hp = max(current_shield_hp, offered_shield)
shield_added = new_shield_hp - current_shield_hp
```

Remaining duration becomes the greater current/authored duration. Preview and bot evaluation use `actual_heal` and `shield_added`, not authored values.

## 12. Deterministic Easy bot and exact 10k fixture

### 12.1 Legal command generation

For the current actor:

1. Enumerate every reachable destination, including stay, by destination `tile_id`.
2. Use only the canonical shortest path from section 8.1.
3. At each destination enumerate `GUARD`, then skills by `skill_id`, then target tiles by `tile_id`.
4. Validate each candidate through the same `BattleRules.validate` used for player commands.
5. Serialize and deduplicate valid commands after setting `command_id` and clock to fixture values.

### 12.2 Easy evaluation and selection

Gate A Easy uses the parent score weights with these closures:

- `optional_objective_control = 0` and `expected_enemy_damage_next = 0` in base skirmish.
- `effective_damage` is HP removed plus shield removed.
- `effective_heal` is actual heal; `shield_added` is the actual increase.
- `expected_DoT` is retained stack power times remaining ticks after the 3-stack rule.
- `mark_or_debuff_value` counts each newly applied `MARK`, `WEAKEN`, `CHALLENGE`, `IMMOBILE`, or negative `SPEED` once.
- Friendly collision penalty uses actual fixed damage to both allies.
- Illegal commands are discarded before scoring, not represented with infinity.

Sort candidates by score descending, then canonical command bytes ascending. Derive `roll = uint32_be(first 4 bytes of SHA256("easy|seed|action_index|actor_id")) % 100`.

- 3 or more candidates: rank 0 for `0..59`, rank 1 for `60..89`, rank 2 for `90..99`.
- 2 candidates: rank 0 for `0..69`, rank 1 for `70..99`.
- 1 candidate: rank 0.

The selected command uses `authority_elapsed_ms = state.authority_elapsed_ms + 1000`. Re-evaluating the same state returns byte-identical command JSON.

### 12.3 Exact 10,000-match simulation

- Seeds are every integer `0..9999`, one match per seed.
- Map, rosters, stats, skills, and spawns are exactly sections 7 and 9.
- Both teams use the Easy policy above. No progression, city commotion, Spotlight, random accuracy, crit, or backend state exists.
- Initial cross-team tie priority is `A` for even seed and `B` for odd seed.
- Every bot command advances trusted time by exactly 1000 ms.
- A match ends by elimination or 24 actions; the 420000 ms cap remains asserted but is not expected to trigger.
- Required report fields: `rule_version`, seed range, match count, A/B/draw counts, initial-priority wins/losses/draws, mean/p50/p95 actions, mean/p95 bot decision ms, illegal count, hash mismatch count, match-cap violation count, one-shot-full-HP-Duck count.

Gate A passes only when:

- match count is 10000;
- illegal commands, hash mismatches, cap violations, and full-HP Duck one-shots are all 0;
- every match ends at or before action 24;
- initial-priority win rate is 47%..53%, calculated as wins divided by wins plus losses; draws are reported separately;
- repeated runs on the same commit produce byte-identical per-seed result lines and aggregate JSON;
- Easy decision p95 is at most 60 ms on the recorded Cloud runner profile.

The 5-hero 45%..55% balance target and human Easy win target remain later tests; they are not Gate A blockers.

## 13. Minimal Gate B tutorial and village shell

This section resolves the Gate B flow conflict. `village_shell` is a navigation shell, not the full Gate E village.

### 13.1 Public flow

```text
main -> village_shell -> opponent_brief -> tutorial or bot_skirmish
     -> result -> rematch (same mode) or home (village_shell)
```

- First fresh-save Play opens the tutorial brief. Tutorial completion sets one local boolean and returns to result.
- Later Play opens Easy bot-skirmish brief. Normal may remain locked until Easy completes once.
- `village_shell` contains Play, the three starter portraits, Settings, and an unavailable-content label. It has no currencies, store, story, social, ranking, ads, stamina, walking, or backend calls.
- Result always exposes Rematch and Home. No screen is a dead end.
- The full hub, story Chapter 0, economy, unlock screens, shop, profile, and social remain Gate E/F.

### 13.2 Tutorial fixture and guided commands

Tutorial uses `mode_id = "tutorial_v1"`, seed 424242, action cap 12, no turn/match clock, and the same core rules. Units start at:

| Unit | Tile |
|---|---:|
| `a_duck` | `[2,2]` |
| `a_chicken` | `[3,4]` |
| `a_pigeon` | `[2,6]` |
| `b_pigeon` | `[8,2]` |
| `b_chicken` | `[7,4]` |
| `b_duck` | `[8,6]` |

Tutorial obstacles are `box_t1 [5,2]`, `barrel_t1 [5,4]`, and `box_t2 [5,6]`. The first time each player hero becomes current, only this highlighted command is enabled:

1. Chicken: path `[3,4],[4,4]`; target and trigger `barrel_t1` with `CHICKEN_BASIC`.
2. Pigeon: path `[2,6],[3,5],[4,5]`; heal `a_chicken` with `PIGEON_ACTIVE`.
3. Duck: path `[2,2],[3,3],[4,3],[5,3]`; choose east with `DUCK_ACTIVE` so the fan includes `b_chicken` at `[7,4]`.

Opponent scripted policy is: use a legal basic on the lowest-HP player unit; if none is legal, stay and guard. Ties sort by target ID. After the three guided player commands, normal legal controls unlock and the same scripted opponent continues until elimination or action 12.

The tutorial controller records a step only after accepted ledger events show these exact triples: `a_chicken/CHICKEN_BASIC/[5,4]`, `a_pigeon/PIGEON_ACTIVE/[3,4]`, and `a_duck/DUCK_ACTIVE/[6,3]` where the final tile is the adjacent east direction selector. Win/loss/draw does not block completion; the result explains the score and offers Rematch/Home. A guided invalid tap emits no command, changes no state, and keeps the highlight. This tutorial contract must pass `DS-TC-ENTRY-001` and `DS-TC-FLOW-001` before full village work starts.

## 14. Required Gate A evidence

| Contract | Required evidence |
|---|---|
| Schema/hash | malformed schema rejection table plus same input/state/event SHA-256 golden vectors |
| Turn/time/CD | first actor, cross-team tie toggle, 15s auto-guard, 420s final guard, CD 0/2/4, DoT-KO vectors |
| Grid | path, diagonal corner, occupancy, canonical tie path, LOS supercover tables |
| Skills | every starter min/max/shape/target/LOS legal and illegal table |
| Math/status | direct/heal/shield rounding, caps, stack/cleanse, collision/barrel vectors |
| Bot | byte-identical command repeat, top-3 buckets, no illegal command |
| Simulation | exact 10000-line result artifact plus aggregate JSON |

No Gate A completion claim is valid if any required vector is missing, generated from a different `rule_version`, or tested only through View/Godot physics.

## 15. Explicitly still unverified

- All authored balance values remain simulation/playtest candidates.
- The tutorial coordinates and highlighted commands require headless validation after core exists; this document does not claim they already resolve to the intended events.
- Easy bot p95 depends on the recorded Cloud runner and is not a device-performance claim.
- Gate B runtime, 2400×1080 visual clarity, touch feel, external 5-person comprehension, Android/iOS, audio, and fun are not verified here.
- Gate E PvE/story and Gate F async/server golden-vector parity remain deferred.
