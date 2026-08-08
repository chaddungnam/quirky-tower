extends Control

signal finished(input_value: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")

var _difficulty := 0.5
var _active := false
var _dodged := 0
var _hazard_count := 3

@onready var _stage = $StageDisplay/WorldViewport/TowerStage3D


func _ready() -> void:
	_stage.player_hit.connect(_on_player_hit)
	_stage.hazard_dodged.connect(_on_hazard_dodged)
	_stage.all_hazards_cleared.connect(_on_all_hazards_cleared)
	$HitFlash.color = Tokens.color(self, Tokens.DANGER)


func setup(difficulty: float, _modifiers: Dictionary = {}) -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_hazard_count = 3 + int(round(_difficulty * 2.0))


func begin() -> void:
	_dodged = 0
	_active = true
	$Status.text = "0 / %d" % _hazard_count
	$Status.add_theme_color_override("font_color", Tokens.color(self, Tokens.TEXT))
	$HitFlash.modulate.a = 0.0
	_stage.configure({"hazards": _hazard_count, "speed_bonus": 0.0, "id": "safe"}, _difficulty)
	_stage.start_dodge()


func _gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenDrag:
		_set_player_x(event.position.x)
	elif event is InputEventScreenTouch and event.pressed:
		_set_player_x(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_set_player_x(event.position.x)
	elif event is InputEventMouseButton and event.pressed:
		_set_player_x(event.position.x)


func _set_player_x(value: float) -> void:
	var axis := clampf(value / maxf(1.0, size.x) * 2.0 - 1.0, -1.0, 1.0)
	_stage.set_player_axis(axis)


func _on_player_hit() -> void:
	if not _active:
		return
	$Status.text = "BONK!"
	$Status.add_theme_color_override("font_color", Tokens.color(self, Tokens.DANGER))
	$HitFlash.modulate.a = 0.42
	var tween := create_tween()
	tween.tween_property($HitFlash, "modulate:a", 0.0, 0.24)
	_finish(0.0)


func _on_hazard_dodged(near_miss: bool) -> void:
	if not _active:
		return
	_dodged += 1
	$Status.text = "NEAR MISS +" if near_miss else "DODGE %d/%d" % [_dodged, _hazard_count]
	$Status.add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.WARNING if near_miss else Tokens.PRIMARY)
	)
	$Status.pivot_offset = $Status.size * 0.5
	$Status.scale = Vector2(0.72, 0.72)
	var tween := create_tween()
	tween.tween_property($Status, "scale", Vector2(1.18, 1.18), 0.08)
	tween.tween_property($Status, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)


func _on_all_hazards_cleared() -> void:
	if _active:
		_finish(0.5)


func _finish(input_value: float) -> void:
	if not _active:
		return
	_active = false
	finished.emit(input_value)
