class_name TimingRingChallenge
extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")

var _difficulty := 0.5
var _modifiers: Dictionary = {}
var _phase := 0.0
var _active := false


func setup(difficulty: float, modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_modifiers = modifiers


func begin() -> void:
	_phase = 0.0
	_active = true
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_phase += delta * (0.65 + _difficulty * 0.9)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed:
		_finish()
	elif event is InputEventScreenTouch and event.pressed:
		_finish()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.52)
	var track_width := minf(size.x * 0.78, 560.0)
	var track := Rect2(center.x - track_width * 0.5, center.y - 18.0, track_width, 36.0)
	draw_style_box(Tokens.panel_style(self, Tokens.NAVY, 18), track)
	var target_width := maxf(0.08, 0.25 - _difficulty * 0.2 + float(_modifiers.get("window_bonus", 0.0)))
	var target := Rect2(center.x - track_width * target_width, center.y - 18.0, track_width * target_width * 2.0, 36.0)
	draw_style_box(Tokens.panel_style(self, Tokens.TEAL, 18), target)
	var normalized := pingpong(_phase, 1.0)
	var needle_x := track.position.x + track_width * normalized
	draw_line(Vector2(needle_x, center.y - 76.0), Vector2(needle_x, center.y + 76.0), Tokens.color(self, Tokens.CORAL), 12.0, true)


func _finish() -> void:
	_active = false
	finished.emit(pingpong(_phase, 1.0))
