extends SceneTree

const RunSimulator = preload("res://scripts/core/simulation/run_simulator.gd")


func _init() -> void:
	var seed := _seed_arg(424242)
	var options := {"country": "ALN", "bot_skill": 0.8}
	var normal: Dictionary = RunSimulator.simulate(seed, options)
	var repeated: Dictionary = RunSimulator.simulate(seed, options)
	assert(normal == repeated, "same seed and options must match exactly")
	assert(normal.status in ["complete", "game_over"], "run has an explicit terminal state")
	assert(not normal.impossible, "run never reaches an impossible state")
	assert(normal.country == "ALN", "country/faction code is preserved")
	assert(_ordered_unique(normal.story_event_ids), "story events are ordered and unique")

	var ad: Dictionary = RunSimulator.simulate(seed, options.merged({"boost_source": "ad"}, true))
	var paid: Dictionary = RunSimulator.simulate(seed, options.merged({"boost_source": "paid"}, true))
	assert(_without(ad, ["boost_source"]) == _without(paid, ["boost_source"]), "ad and paid gameplay summaries match")

	var restored: Dictionary = RunSimulator.simulate(seed, options.merged({"resume_checkpoint": true}, true))
	assert(restored.checkpoint_restored, "smoke seed reaches and restores a checkpoint")
	assert(_without(normal, ["checkpoint_restored"]) == _without(restored, ["checkpoint_restored"]), "checkpoint restore reaches the same final summary")

	print("PASS run_smoke %s" % JSON.stringify(normal))
	quit(0)


func _seed_arg(default_seed: int) -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			return int(argument.trim_prefix("--seed="))
	return default_seed


func _without(source: Dictionary, keys: Array) -> Dictionary:
	var copy := source.duplicate(true)
	for key in keys:
		copy.erase(key)
	return copy


func _ordered_unique(ids: Array) -> bool:
	var expected := ["broadcast_glitch", "host_contradiction", "finale_secret"]
	var last_index := -1
	for id in ids:
		var index := expected.find(id)
		if index <= last_index:
			return false
		last_index = index
	return true
