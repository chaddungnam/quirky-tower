extends SceneTree

const FlockRunState = preload("res://scripts/core/reboot/flock_run_state.gd")


func _init() -> void:
	var first = FlockRunState.new_run(424242)
	var second = FlockRunState.new_run(424242)
	assert(first.snapshot() == second.snapshot())
	assert(first.rescue("goose_greta", "goose"))
	assert(first.rescue("pigeon_pip", "pigeon"))
	assert(not first.rescue("goose_greta", "goose"))
	assert(first.companions.size() == 2)
	first.begin_act("brawl")
	first.record_event("collapse", {"target_id": "antenna_a"})
	assert(first.event_ledger[-1].kind == "collapse")
	var options := first.choice_options()
	assert(options.size() == 3)
	assert(first.apply_choice(str(options[0].id)))
	assert(not first.apply_choice(str(options[0].id)))
	print("PASS flock_run_state_test")
	quit(0)
