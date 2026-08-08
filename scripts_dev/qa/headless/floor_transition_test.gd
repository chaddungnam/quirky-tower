extends SceneTree

const RunScreenScene = preload("res://scenes/game/run_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := RunScreenScene.instantiate()
	root.add_child(screen)
	var floor_label := screen.get_node("RunHud/Margin/Row/Floor") as Label
	assert(floor_label.text == "1F", "the first floor begins on 1F")
	screen.submit_challenge(0.5)
	assert(floor_label.text == "1F", "the clear beat keeps the floor that was just cleared")
	screen.continue_flow()
	assert(floor_label.text == "2F", "the HUD advances with the next floor preview")
	screen.free()

	print("PASS floor_transition_test")
	quit(0)
