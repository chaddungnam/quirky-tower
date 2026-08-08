extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const CELL_COUNT := 12
const SHAPES := ["■", "▲", "◆", "★", "⬟"]
const DECOY_ROLES := [Tokens.SECONDARY, Tokens.WARNING, Tokens.SECRET, Tokens.SURFACE]

var _difficulty := 0.5
var _goal := 5
var _hits := 0
var _mistakes := 0
var _target_index := 0
var _active := false


func setup(difficulty: float, _modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_goal = maxi(4, int(round(4.0 + _difficulty * 3.0)))


func begin() -> void:
	_hits = 0
	_mistakes = 0
	_target_index = 1
	_active = true
	if $Center/Grid.get_child_count() == 0:
		_build_cells()
	_update_target()
	_update_progress()
	$Feedback.text = ""
	$Timer.start(4.2)


func _build_cells() -> void:
	for index in range(CELL_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(168.0, 120.0)
		button.add_theme_font_size_override("font_size", 42)
		button.offset_transform_enabled = true
		button.offset_transform_visual_only = true
		button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		button.pressed.connect(func() -> void: _on_cell_pressed(index))
		$Center/Grid.add_child(button)


func _on_cell_pressed(index: int) -> void:
	if not _active:
		return
	var button := $Center/Grid.get_child(index) as Button
	if index == _target_index:
		_hits += 1
		$Feedback.text = "POP!"
		_pop(button, true)
		if _hits >= _goal:
			_finish()
			return
		_target_index = (_target_index + 5 + _hits * 2) % CELL_COUNT
		_update_target()
	else:
		_mistakes += 1
		$Feedback.text = "NO!"
		_pop(button, false)
	_update_progress()


func _update_target() -> void:
	for index in range($Center/Grid.get_child_count()):
		var button := $Center/Grid.get_child(index) as Button
		var is_target := index == _target_index
		var role: String = Tokens.PRIMARY if is_target else DECOY_ROLES[index % DECOY_ROLES.size()]
		button.text = "●" if is_target else SHAPES[index % SHAPES.size()]
		button.set_meta("is_target", is_target)
		button.add_theme_stylebox_override("normal", Tokens.panel_style(button, role, 18))
		button.add_theme_stylebox_override("hover", Tokens.panel_style(button, role, 18))
		button.add_theme_stylebox_override("pressed", Tokens.panel_style(button, Tokens.BACKGROUND, 18))
		var text_role := Tokens.BACKGROUND if is_target else Tokens.TEXT
		button.add_theme_color_override("font_color", Tokens.color(button, text_role))
		button.add_theme_color_override("font_hover_color", Tokens.color(button, text_role))


func _update_progress() -> void:
	var dots := ""
	for index in range(_goal):
		dots += "●" if index < _hits else "○"
	$Progress.text = dots


func _pop(button: Control, success: bool) -> void:
	button.offset_transform_scale = Vector2.ONE
	button.offset_transform_rotation = 0.0
	var tween := create_tween().set_parallel(true)
	if success:
		tween.tween_property(button, "offset_transform_scale", Vector2(1.24, 1.24), 0.08)
		tween.chain().tween_property(
			button, "offset_transform_scale", Vector2.ONE, 0.16
		).set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_property(button, "offset_transform_rotation", 0.10, 0.05)
		tween.chain().tween_property(button, "offset_transform_rotation", -0.10, 0.05)
		tween.chain().tween_property(button, "offset_transform_rotation", 0.0, 0.08)


func _finish() -> void:
	if not _active:
		return
	_active = false
	$Timer.stop()
	for button: Button in $Center/Grid.get_children():
		button.disabled = true
	var quality := clampf(float(_hits) / float(_goal) - float(_mistakes) * 0.10, 0.0, 1.0)
	finished.emit(quality)
