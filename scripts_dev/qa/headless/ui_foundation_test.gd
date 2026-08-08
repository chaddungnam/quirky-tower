extends SceneTree

const RunState = preload("res://scripts/core/run/run_state.gd")
const HudScene = preload("res://scenes/ui/components/run_hud.tscn")
const OverlayScene = preload("res://scenes/ui/components/game_overlay.tscn")


func _init() -> void:
	var hud = HudScene.instantiate()
	var state = RunState.new_run(1, "DE")
	state.floor = 7
	state.score = 420
	state.combo = 3
	state.hearts = 2
	hud.update_state(state)
	assert(hud.get_node("Margin/Row/Floor").text == "7F", "floor label updates")
	assert(hud.get_node("Margin/Row/Score").text == "000420", "score label updates")
	assert(hud.get_node("Margin/Row/Hearts").text == "♥ ♥", "heart label updates")

	var overlay = OverlayScene.instantiate()
	overlay.show_message("READY", "Tap", "GO", func(): pass)
	assert(overlay.visible, "message opens the overlay")
	assert(overlay.get_node("Center/Card/Content/Title").text == "READY", "title updates")
	assert(overlay.get_node("Center/Card/Content/Actions").get_child_count() == 1, "one action is shown")
	overlay.show_choices("QUIRK", [{"id": "wide_window", "label": "Wide Window"}], func(_id): pass)
	assert(overlay.get_node("Center/Card/Content/Actions").get_child_count() == 1, "choices replace old actions")
	overlay.close()
	assert(not overlay.visible, "close hides the overlay")
	overlay.free()
	hud.free()

	print("PASS ui_foundation_test")
	quit(0)
