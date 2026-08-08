extends SceneTree

const TrialScene = preload("res://scenes/game/challenges/tower_trial.tscn")
const AppTheme = preload("res://ui/themes/app_theme.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var trial = TrialScene.instantiate()
	trial.theme = AppTheme
	root.add_child(trial)
	var emitted: Array = []
	trial.finished.connect(
		func(input_value: float, score_multiplier: float) -> void:
			emitted.append({"input": input_value, "multiplier": score_multiplier})
	)
	trial.setup(0.4, {}, "timing_ring")
	trial.begin()
	assert(trial.get("_phase") == "route", "a floor begins with route choice")
	assert(
		trial.get_node("StageDisplay/WorldViewport/TowerStage3D") is Node3D,
		"the floor embeds one reusable native 3D stage"
	)
	var actions = trial.get_node("RoutePanel/Content/RouteActions")
	assert(actions.get_child_count() == 3, "three risk routes are offered")
	var first_button: Button = actions.get_child(0)
	var normal_style: StyleBoxFlat = first_button.get_theme_stylebox("normal")
	assert(
		first_button.get_theme_color("font_color") != normal_style.bg_color,
		"route button text contrasts with its background"
	)
	var route_colors: Array = []
	for button in actions.get_children():
		route_colors.append((button as Button).get_theme_stylebox("normal").bg_color)
	assert(
		route_colors[0] != route_colors[1] and route_colors[1] != route_colors[2],
		"safe, bold, and chaos routes have distinct selection roles"
	)
	actions.get_child(2).pressed.emit()
	assert(trial.get("_phase") == "dodge", "route choice starts direct control")
	assert(is_equal_approx(float(trial.get("_score_multiplier")), 1.5), "chaos route carries x1.5")
	trial.set("_elapsed", 3.1)
	trial._process(0.0)
	assert(trial.get("_phase") == "smash", "surviving the dodge opens the smash timing")
	trial.set("_needle_phase", 0.5)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.position = Vector2(360.0, 640.0)
	tap.pressed = true
	trial._gui_input(tap)
	trial._process(0.6)
	assert(not emitted.is_empty(), "smash feedback emits the floor result")
	assert(float(emitted[0].input) >= 0.0 and float(emitted[0].input) <= 1.0, "input stays normalized")
	assert(is_equal_approx(float(emitted[0].multiplier), 1.5), "selected risk reward reaches the run")
	trial.free()

	print("PASS tower_trial_test")
	quit(0)
