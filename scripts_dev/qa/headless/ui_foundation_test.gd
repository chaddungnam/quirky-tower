extends SceneTree

const FlockRunState = preload("res://scripts/core/reboot/flock_run_state.gd")
const HudScene = preload("res://scenes/ui/components/run_hud.tscn")
const OverlayScene = preload("res://scenes/ui/components/game_overlay.tscn")
const Tokens = preload("res://scripts/ui/design_tokens.gd")


func _init() -> void:
	var hud = HudScene.instantiate()
	var state = FlockRunState.new_run(1)
	state.begin_act("brawl")
	state.score = 420
	state.combo = 3
	state.health = 2
	state.rescue("goose_greta", "goose")
	hud.update_state(state, "2막 · 옥상 난투")
	assert(hud.get_node("Margin/Rows").get_child_count() == 2, "HUD uses two compact rows")
	assert(hud.get_node("Margin/Rows/ActRow/Act").text == "2막 · 옥상 난투", "act label updates")
	assert(hud.get_node("Margin/Rows/ActRow/Score").text == "SCORE 000420", "score label updates")
	assert(hud.get_node("Margin/Rows/StateRow/Health").text == "♥ ♥", "health label updates")
	assert(hud.get_node("Margin/Rows/StateRow/Flock").text.contains("GOOSE"), "flock species are visible")

	var overlay = OverlayScene.instantiate()
	overlay.show_message("READY", "Tap", "GO", func(): pass)
	assert(overlay.visible, "message opens the overlay")
	assert(overlay.get_node("Center/Card/Content/Title").text == "READY", "title updates")
	assert(
		overlay.get_node("Center/Card/Content/ActionScroll/Actions").get_child_count() == 1,
		"one action is shown"
	)
	var generic_button := overlay.get_node("Center/Card/Content/ActionScroll/Actions").get_child(0) as Button
	assert(generic_button.get_meta("role", "") == Tokens.WARNING, "generic actions keep the warning role")
	overlay.show_actions("CHOOSE A FLOCK BUILD", "", [{"label": "BUILD", "action": func(): pass}])
	assert(overlay.get_node("MascotGuide/Bubble/Text").text == "Pick one.", "English choice copy keeps the mascot English")
	overlay.show_actions("DISTRICT CLEARED", "", [{"label": "HOME", "action": func(): pass}])
	assert(overlay.get_node("MascotGuide/Bubble/Text").text == "Ready for another raid.", "English result copy keeps the mascot English")
	overlay.show_actions("조류단 강화 선택", "", [{"label": "강화", "action": func(): pass}])
	assert(overlay.get_node("MascotGuide/Bubble/Text").text == "하나 골라!", "Korean choice copy keeps the mascot Korean")
	overlay.show_actions("구역 돌파", "", [{"label": "홈", "action": func(): pass}])
	assert(overlay.get_node("MascotGuide/Bubble/Text").text == "다음 습격도 준비됐어.", "Korean result copy keeps the mascot Korean")
	overlay.show_choices(
		"CHOOSE A FLOCK BUILD",
		[
			{"id": "dash", "label": ">> HEAVY FIRST WING\nBRAWL + CHAIN", "role": Tokens.PRIMARY},
			{"id": "guard", "label": "[] GOOSE GUARD\nAPPROACH + BRAWL", "role": Tokens.SECONDARY},
			{"id": "route", "label": "// PIGEON SHORTCUT\nAPPROACH + CHAIN", "role": Tokens.SECRET},
		],
		func(_id): pass
	)
	var action_scroll = overlay.get_node("Center/Card/Content/ActionScroll")
	var actions = action_scroll.get_node("Actions")
	assert(action_scroll is ScrollContainer, "choices use a vertical scroll container")
	assert(actions is VBoxContainer, "choices are always stacked vertically")
	assert(actions.get_child_count() == 3, "choices replace old actions")
	var choice_labels: Dictionary = {}
	var choice_roles: Dictionary = {}
	for child in actions.get_children():
		var button := child as Button
		assert(button != null, "every choice is a button")
		assert(button.custom_minimum_size.y >= 96.0, "choice meets the mobile touch target")
		assert(
			button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART,
			"long translated choices wrap instead of clipping"
		)
		assert(button.text.split("\n").size() == 2, "each choice has one affected-act cue line")
		choice_labels[button.text] = true
		var role := str(button.get_meta("role", ""))
		choice_roles[role] = true
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		assert(style.bg_color == Tokens.color(button, role), "each choice carries its role accent")
	assert(choice_labels.size() == 3, "choice glyph labels are distinct")
	assert(choice_roles.keys().all(func(role): return role in [Tokens.PRIMARY, Tokens.SECONDARY, Tokens.SECRET]), "choice roles use existing theme accents")
	assert(choice_roles.size() == 3, "each choice uses a distinct role")
	var action_calls := [0]
	overlay.show_message("CHOOSE", "", "FIRST", func() -> void:
		action_calls[0] += 1
		overlay.show_actions("RESULT", "", [
			{"label": "PLAY AGAIN", "action": func(): pass},
			{"label": "HOME", "action": func(): pass},
		])
	)
	var action_button: Button = actions.get_child(0)
	action_button.pressed.emit()
	action_button.pressed.emit()
	assert(action_calls[0] == 1, "an old overlay action resolves only once after replacing its generation")
	assert(
		actions.get_child_count() == 2,
		"an action can replace its own overlay with stacked result buttons"
	)
	overlay.close()
	assert(not overlay.visible, "close hides the overlay")
	overlay.free()
	hud.free()

	print("PASS ui_foundation_test")
	quit(0)
