class_name DragDodgeChallenge
extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const PLAYER_RADIUS := 34.0

var _difficulty := 0.5
var _active := false
var _elapsed := 0.0
var _player := Vector2.ZERO
var _obstacles: Array[Rect2] = []


func setup(difficulty: float, _modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)


func begin() -> void:
	var arena := _arena_rect()
	_player = Vector2(arena.get_center().x, arena.end.y - 90.0)
	_obstacles = [
		Rect2(arena.position.x + 30.0, arena.position.y + 80.0, 210.0, 36.0),
		Rect2(arena.end.x - 270.0, arena.position.y + 330.0, 240.0, 36.0),
		Rect2(arena.position.x + 150.0, arena.position.y + 580.0, 190.0, 36.0),
	]
	_elapsed = 0.0
	_active = true
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_move_obstacles(delta)
	if _has_collision():
		_finish(0.0)
	elif _elapsed >= 4.0:
		_finish(0.5)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenDrag:
		_set_player_x(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_set_player_x(event.position.x)


func _draw() -> void:
	var arena := _arena_rect()
	draw_style_box(Tokens.panel_style(self, Tokens.CREAM, 28), arena)
	for obstacle in _obstacles:
		draw_style_box(Tokens.panel_style(self, Tokens.NAVY, 18), obstacle)
	draw_circle(_player, PLAYER_RADIUS, Tokens.color(self, Tokens.ORANGE), true, -1.0, true)


func _arena_rect() -> Rect2:
	return Rect2(34.0, 110.0, maxf(1.0, size.x - 68.0), maxf(1.0, size.y - 170.0))


func _set_player_x(value: float) -> void:
	var arena := _arena_rect()
	_player.x = clampf(value, arena.position.x + PLAYER_RADIUS, arena.end.x - PLAYER_RADIUS)
	queue_redraw()


func _move_obstacles(delta: float) -> void:
	var arena := _arena_rect()
	var speed := 150.0 + _difficulty * 180.0
	for index in range(_obstacles.size()):
		_obstacles[index].position.y += speed * delta
		if _obstacles[index].position.y > arena.end.y:
			_obstacles[index].position.y = arena.position.y - 60.0
			_obstacles[index].position.x = arena.position.x + fmod(float(index * 197 + int(_elapsed * 53.0)), maxf(1.0, arena.size.x - _obstacles[index].size.x))


func _has_collision() -> bool:
	var player_rect := Rect2(_player - Vector2.ONE * PLAYER_RADIUS, Vector2.ONE * PLAYER_RADIUS * 2.0)
	for obstacle in _obstacles:
		if player_rect.intersects(obstacle):
			return true
	return false


func _finish(input_value: float) -> void:
	if not _active:
		return
	_active = false
	finished.emit(input_value)
