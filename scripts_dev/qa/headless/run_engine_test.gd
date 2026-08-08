extends SceneTree

const GameCatalog = preload("res://scripts/core/run/game_catalog.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const QuirkRules = preload("res://scripts/core/quirks/quirk_rules.gd")
const SponsorBoost = preload("res://scripts/core/economy/sponsor_boost.gd")
const RunEngine = preload("res://scripts/core/run/run_engine.gd")


func _init() -> void:
	var catalog = GameCatalog.load_default()
	var success_state = RunState.new_run(1, "DE")
	var success: Dictionary = RunEngine.resolve_floor(success_state, catalog, 0.5)
	assert(success.success and success_state.floor == 2, "success advances one floor")
	assert(success_state.combo == 1 and success_state.score > 0, "success builds combo and score")

	var fail_state = RunState.new_run(2, "DE")
	fail_state.combo = 3
	var failure: Dictionary = RunEngine.resolve_floor(fail_state, catalog, 1.0)
	assert(not failure.success and fail_state.floor == 1, "failure retries the same floor")
	assert(fail_state.combo == 0 and fail_state.hearts == 2, "failure clears combo and costs one heart")

	for story_floor in [5, 10, 15]:
		var story_state = RunState.new_run(story_floor, "KR")
		story_state.floor = story_floor
		var result: Dictionary = RunEngine.resolve_floor(story_state, catalog, 0.5 if story_floor != 5 else 1.0)
		assert(str(result.get("story_event_id", "")) != "", "story floor %d emits an event" % story_floor)

	var checkpoint_state = RunState.new_run(3, "DE")
	checkpoint_state.floor = 5
	RunEngine.resolve_floor(checkpoint_state, catalog, 1.0)
	assert(checkpoint_state.checkpoint_floor == 5, "configured checkpoint is recorded")
	assert(checkpoint_state.checkpoint_snapshot.get("floor") == 6, "checkpoint resumes after the cleared floor")

	var replay_state = RunState.new_run(4, "DE")
	replay_state.quirks = ["replay"]
	RunEngine.resolve_floor(replay_state, catalog, 1.0)
	assert(replay_state.hearts == 3 and replay_state.replay_used, "replay protects one failure")
	RunEngine.resolve_floor(replay_state, catalog, 1.0)
	assert(replay_state.hearts == 2, "replay does not protect twice")

	var normal_success = RunState.new_run(5, "DE")
	RunEngine.resolve_floor(normal_success, catalog, 0.5)
	var hot_success = RunState.new_run(5, "DE")
	hot_success.quirks = ["overheat_combo"]
	RunEngine.resolve_floor(hot_success, catalog, 0.5)
	assert(hot_success.score > normal_success.score, "overheat raises successful combo score")
	var hot_failure = RunState.new_run(6, "DE")
	hot_failure.quirks = ["overheat_combo"]
	RunEngine.resolve_floor(hot_failure, catalog, 1.0)
	assert(hot_failure.hearts == 1, "overheat increases failure loss")

	var reroute_state = RunState.new_run(7, "DE")
	reroute_state.quirks = ["reroute"]
	assert(RunEngine.challenge_id_for_floor(reroute_state, catalog) == "tap_panic", "UI and engine share rerouted challenge lookup")
	var rerouted: Dictionary = RunEngine.resolve_floor(reroute_state, catalog, 1.0)
	assert(rerouted.challenge_id != "timing_ring", "reroute deterministically changes the challenge")

	var ad_state = RunState.new_run(8, "ALN")
	var paid_state = RunState.new_run(8, "ALN")
	assert(SponsorBoost.apply(ad_state, "ad").ok, "ad Boost applies")
	assert(SponsorBoost.apply(paid_state, "paid").ok, "paid Boost applies")
	assert(_gameplay_snapshot(ad_state) == _gameplay_snapshot(paid_state), "ad and paid Boost gameplay is identical")
	assert(not SponsorBoost.apply(ad_state, "ad").ok, "one Boost per run")
	var grouped: Dictionary = RunEngine.resolve_floor(ad_state, catalog, 0.5)
	assert(grouped.country == "ALN", "faction code is the one country grouping value")
	assert(QuirkRules.modifiers(["wide_window"]).window_bonus > 0.0, "Quirks expose flat modifiers")

	print("PASS run_engine_test")
	quit(0)


func _gameplay_snapshot(state) -> Dictionary:
	var data: Dictionary = state.snapshot()
	data.erase("boost_source")
	return data
