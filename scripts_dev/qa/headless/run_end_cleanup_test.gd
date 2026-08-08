extends SceneTree

const RunScreenScene = preload("res://scenes/game/run_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := RunScreenScene.instantiate()
	root.add_child(screen)
	for attempt in range(3):
		screen.submit_challenge(0.0)
		screen.continue_flow()
		if attempt < 2:
			await process_frame
	await process_frame
	assert(screen.get_run_snapshot().status == "game_over", "three misses end the run")
	assert(
		screen.get_node("ChallengeSlot").get_child_count() == 0,
		"game over removes the last floor and its duplicate mascot"
	)
	screen.free()

	print("PASS run_end_cleanup_test")
	quit(0)
