extends SceneTree

const RunScreenScene = preload("res://scenes/game/run_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen = RunScreenScene.instantiate()
	root.add_child(screen)
	for cleared_floor in range(1, 16):
		assert(screen.get_run_snapshot().floor == cleared_floor, "expected floor %d" % cleared_floor)
		if screen.needs_quirk_choice():
			screen.choose_quirk(screen.available_quirks()[0])
		screen.submit_challenge(screen.success_input_for_current_challenge())
		screen.continue_flow()
		if cleared_floor in [5, 10, 15]:
			screen.continue_flow()

	var snapshot: Dictionary = screen.get_run_snapshot()
	assert(snapshot.status == "complete", "the full run completes")
	assert(snapshot.floor == 15, "completion stays on floor 15")
	assert(snapshot.story_event_ids.size() == 3, "all story beats are shown")
	assert(snapshot.quirks.size() == 3, "three Quirks are selected")
	screen.free()

	print("PASS playable_loop_test")
	quit(0)
