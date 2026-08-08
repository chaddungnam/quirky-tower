extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const ACTIVE_DURATION := 4.0

var _difficulty := 0.5
var _modifiers: Dictionary = {}
var _phase := 0.0
var _elapsed := 0.0
var _active := false
var _locked := false
var _impact := 0.0


func setup(difficulty: float, modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_modifiers = modifiers.duplicate()


func begin() -> void:
	_phase = 0.0
	_elapsed = 0.0
	_active = true
	_locked = false
	_impact = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_phase += delta * (0.70 + _difficulty * 0.85)
	if _elapsed >= ACTIVE_DURATION:
		_finish(0.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.pressed:
		_finish(pingpong(_phase, 1.0))
	elif event is InputEventScreenTouch and event.pressed:
		_finish(pingpong(_phase, 1.0))


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.50)
	var radius := minf(size.x * 0.31, 225.0)
	var surface := Tokens.color(self, Tokens.SURFACE)
	var primary := Tokens.color(self, Tokens.PRIMARY)
	var warning := Tokens.color(self, Tokens.WARNING)
	draw_circle(center, radius + 34.0 + _impact * 16.0, surface.darkened(0.16))
	draw_arc(center, radius, 0.0, TAU, 96, surface.lightened(0.22), 38.0, true)

	var bonus := float(_modifiers.get("window_bonus", 0.0))
	var target_width := maxf(0.08, 0.25 - _difficulty * 0.2 + bonus)
	var half_angle := TAU * target_width
	draw_arc(center, radius, -PI * 0.5 - half_angle, -PI * 0.5 + half_angle, 32, primary, 42.0, true)
	draw_circle(center, 64.0, surface)
	draw_circle(center, 24.0, primary if _locked else warning)

	var normalized := pingpong(_phase, 1.0)
	var angle := -PI * 0.5 + (normalized - 0.5) * TAU
	var tip := center + Vector2.from_angle(angle) * (radius - 18.0)
	draw_line(center, tip, warning, 14.0, true)
	draw_circle(tip, 18.0 + _impact * 10.0, warning)

	var time_ratio := clampf(1.0 - _elapsed / ACTIVE_DURATION, 0.0, 1.0)
	draw_arc(center, radius + 58.0, -PI * 0.5, -PI * 0.5 + TAU * time_ratio, 64, primary, 8.0, true)


func _finish(input_value: float) -> void:
	if not _active:
		return
	_active = false
	_locked = true
	_impact = 0.0
	var tween := create_tween()
	tween.tween_property(self, "_impact", 1.0, 0.07)
	tween.tween_property(self, "_impact", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
	finished.emit(input_value)
	queue_redraw()
