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
	assert(
		overlay.get_node("Center/Card/Content/ActionScroll/Actions").get_child_count() == 1,
		"one action is shown"
	)
	overlay.show_choices(
		"QUIRK",
		[
			{"id": "safe", "label": "Sicherer Weg mit besonders langem übersetztem Namen"},
			{"id": "risk", "label": "Überraschend riskanter Weg für mutige Kandidaten"},
		],
		func(_id): pass
	)
	var action_scroll = overlay.get_node("Center/Card/Content/ActionScroll")
	var actions = action_scroll.get_node("Actions")
	assert(action_scroll is ScrollContainer, "choices use a vertical scroll container")
	assert(actions is VBoxContainer, "choices are always stacked vertically")
	assert(actions.get_child_count() == 2, "choices replace old actions")
	for child in actions.get_children():
		var button := child as Button
		assert(button != null, "every choice is a button")
		assert(button.custom_minimum_size.y >= 96.0, "choice meets the mobile touch target")
		assert(
			button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART,
			"long translated choices wrap instead of clipping"
		)
	var action_calls := [0]
	overlay.show_message("FAIL", "HEARTS 2", "CONTINUE", func() -> void:
		action_calls[0] += 1
		overlay.close()
	)
	var action_button: Button = actions.get_child(0)
	action_button.pressed.emit()
	action_button.pressed.emit()
	assert(action_calls[0] == 1, "an overlay action resolves only once under repeated input")
	assert(
		actions.get_child_count() == 0,
		"an action can close its own overlay without leaving a locked button"
	)
	overlay.close()
	assert(not overlay.visible, "close hides the overlay")
	overlay.free()
	hud.free()

	print("PASS ui_foundation_test")
	quit(0)
