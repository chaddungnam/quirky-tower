extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const CELL_COUNT := 12

var _difficulty := 0.5
var _goal := 5
var _hits := 0
var _target_index := 0
var _active := false


func setup(difficulty: float, _modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_goal = maxi(3, int(round(3.0 + _difficulty * 4.0)))


func begin() -> void:
	_hits = 0
	_target_index = 0
	_active = true
	_build_cells()
	_update_target()
	get_node("Timer").start(4.0)


func _build_cells() -> void:
	var grid := get_node("Center/Grid")
	for child in grid.get_children():
		child.free()
	for index in range(CELL_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 120)
		button.text = "●"
		button.pressed.connect(func() -> void: _on_cell_pressed(index))
		grid.add_child(button)


func _on_cell_pressed(index: int) -> void:
	if not _active:
		return
	_hits = _hits + 1 if index == _target_index else maxi(0, _hits - 1)
	get_node("Progress").text = "%d / %d" % [_hits, _goal]
	if _hits >= _goal:
		_finish()
	else:
		_target_index = (_target_index + 5) % CELL_COUNT
		_update_target()


func _update_target() -> void:
	var cells := get_node("Center/Grid").get_children()
	for index in range(cells.size()):
		var role := Tokens.CORAL if index == _target_index else Tokens.NAVY
		cells[index].add_theme_stylebox_override("normal", Tokens.panel_style(cells[index], role))
		cells[index].add_theme_color_override("font_color", Tokens.color(cells[index], Tokens.CREAM))


func _finish() -> void:
	if not _active:
		return
	_active = false
	get_node("Timer").stop()
	for button in get_node("Center/Grid").get_children():
		button.disabled = true
	finished.emit(clampf(float(_hits) / float(_goal), 0.0, 1.0))
