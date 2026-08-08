extends SceneTree

const ChallengeRules = preload("res://scripts/core/challenges/challenge_rules.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")


func _init() -> void:
	assert(ChallengeRules.evaluate("timing_ring", 0.5, 0.5).success, "ring center succeeds")
	assert(not ChallengeRules.evaluate("timing_ring", 0.8, 0.5).success, "ring miss fails")
	assert(ChallengeRules.evaluate("timing_ring", 0.7, 0.5, {"window_bonus": 0.2}).success, "wide window changes timing only")
	assert(ChallengeRules.evaluate("tap_panic", 0.9, 0.8).success, "enough taps succeed")
	assert(not ChallengeRules.evaluate("tap_panic", 0.4, 0.8).success, "too few taps fail")
	assert(ChallengeRules.evaluate("drag_dodge", 0.5, 0.6).success, "safe drag succeeds")
	assert(not ChallengeRules.evaluate("drag_dodge", 0.95, 0.6).success, "hazard drag fails")
	assert(ChallengeRules.evaluate("tap_panic", 0.5, 0.5, {"window_bonus": 1.0}) == ChallengeRules.evaluate("tap_panic", 0.5, 0.5), "wide window does not alter tapping")
	assert(ChallengeRules.evaluate("missing", 0.5, 0.5).error == "unknown challenge missing", "unknown IDs are explicit")

	var state = RunState.new_run(77, "ALN")
	state.floor = 9
	state.hearts = 2
	state.combo = 4
	state.score = 1234
	state.quirks = ["wide_window", "replay"]
	state.checkpoint_floor = 5
	state.boost_used = true
	state.boost_source = "ad"
	var restored = RunState.restore(state.snapshot())
	assert(restored != null, "valid snapshot restores")
	assert(restored.snapshot() == state.snapshot(), "snapshot round-trip is lossless")
	assert(restored.country == "ALN", "faction code uses the country field")
	var bad_snapshot: Dictionary = state.snapshot()
	bad_snapshot.version = 99
	assert(RunState.restore(bad_snapshot) == null, "unsupported saves are rejected")

	print("PASS challenge_rules_test")
	quit(0)
