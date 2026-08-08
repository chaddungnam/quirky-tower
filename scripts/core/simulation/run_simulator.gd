class_name RunSimulator
extends RefCounted

const GameCatalog = preload("res://scripts/core/run/game_catalog.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const RunEngine = preload("res://scripts/core/run/run_engine.gd")
const QuirkRules = preload("res://scripts/core/quirks/quirk_rules.gd")
const SponsorBoost = preload("res://scripts/core/economy/sponsor_boost.gd")

const QUIRK_FLOORS := [4, 8, 12]
const MAX_TURNS := 100


static func simulate(seed: int, options: Dictionary = {}) -> Dictionary:
	var catalog = GameCatalog.load_default()
	var catalog_errors := catalog.validate()
	if not catalog_errors.is_empty():
		return {"status": "invalid", "impossible": true, "errors": Array(catalog_errors)}

	var state = RunState.new_run(seed, str(options.get("country", "DE")))
	var boost_source := str(options.get("boost_source", ""))
	if boost_source != "":
		SponsorBoost.apply(state, boost_source)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var selected_floors := {}
	var attempts := _challenge_counter(catalog)
	var successes := _challenge_counter(catalog)
	var max_combo := 0
	var max_floor := 1
	var turns := 0
	var checkpoint_restored := false
	var bot_skill := clampf(float(options.get("bot_skill", 0.55)), 0.0, 1.0)

	while state.status == "running" and turns < MAX_TURNS:
		var current_floor: int = state.floor
		max_floor = maxi(max_floor, current_floor)
		if current_floor in QUIRK_FLOORS and not selected_floors.has(current_floor):
			_choose_quirk(state, catalog.quirks.keys(), rng)
			selected_floors[current_floor] = true
		var challenge_id := _challenge_for_state(state, catalog)
		var input_value := lerpf(rng.randf(), _ideal_input(challenge_id), bot_skill)
		var result: Dictionary = RunEngine.resolve_floor(state, catalog, input_value)
		var resolved_id := str(result.get("challenge_id", challenge_id))
		attempts[resolved_id] = int(attempts.get(resolved_id, 0)) + 1
		if bool(result.get("success", false)):
			successes[resolved_id] = int(successes.get(resolved_id, 0)) + 1
		max_combo = maxi(max_combo, state.combo)
		turns += 1
		if bool(options.get("resume_checkpoint", false)) and not checkpoint_restored and not state.checkpoint_snapshot.is_empty():
			state = RunState.restore(state.checkpoint_snapshot)
			checkpoint_restored = true

	var impossible: bool = state.status == "running"
	return {
		"seed": seed,
		"country": state.country,
		"status": state.status,
		"floor_reached": max_floor,
		"hearts": state.hearts,
		"combo": state.combo,
		"max_combo": max_combo,
		"score": state.score,
		"turns": turns,
		"selected_quirks": state.quirks.duplicate(),
		"story_event_ids": state.story_event_ids.duplicate(),
		"challenge_attempts": attempts,
		"challenge_successes": successes,
		"boost_source": boost_source,
		"checkpoint_restored": checkpoint_restored,
		"impossible": impossible,
	}


static func _choose_quirk(state, quirk_ids: Array, rng: RandomNumberGenerator) -> void:
	var available := quirk_ids.filter(func(id: String) -> bool: return not state.quirks.has(id))
	if not available.is_empty():
		state.quirks.append(available[rng.randi_range(0, available.size() - 1)])


static func _challenge_for_state(state, catalog) -> String:
	var challenge_id := str(catalog.floors[state.floor - 1].challenge_id)
	var shift := int(QuirkRules.modifiers(state.quirks).challenge_shift)
	if shift == 0:
		return challenge_id
	var ids: Array = catalog.challenges.keys()
	return str(ids[(ids.find(challenge_id) + shift) % ids.size()])


static func _ideal_input(challenge_id: String) -> float:
	return 1.0 if challenge_id == "tap_panic" else 0.5


static func _challenge_counter(catalog) -> Dictionary:
	var counter := {}
	for challenge_id in catalog.challenges:
		counter[challenge_id] = 0
	return counter
