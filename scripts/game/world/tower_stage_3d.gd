extends Node3D

signal player_hit

const AppTheme = preload("res://ui/themes/app_theme.tres")
const Tokens = preload("res://scripts/ui/design_tokens.gd")
const PLAYER_Z := 3.35
const FAR_Z := -10.0
const WRAP_Z := 4.6
const PLAYER_SPAN := 2.85

var _difficulty := 0.5
var _route: Dictionary = {}
var _player_axis := 0.0
var _active := false
var _speed := 5.5
var _touching: Dictionary = {}

@onready var _camera: Camera3D = $Camera
@onready var _player: CharacterBody3D = $Player
@onready var _sprite: Sprite3D = $Player/PixelSprite
@onready var _hazards: Node3D = $Hazards
@onready var _exit: Node3D = $Exit


func _ready() -> void:
	_camera.look_at(Vector3(0.0, 0.15, -2.5))
	_sprite.texture = _make_player_texture()
	_apply_floor_texture()
	reset_stage()


func configure(route: Dictionary, difficulty: float) -> void:
	_route = route.duplicate()
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_speed = 5.0 + _difficulty * 3.0 + float(_route.get("speed_bonus", 0.0)) / 35.0
	_clear_hazards()
	var count := maxi(1, int(_route.get("hazards", 2)))
	for index in range(count):
		_add_hazard(index, count)
	_apply_route_color(_route_color(str(_route.get("id", "safe"))))


func start_dodge() -> void:
	_active = true
	_exit.position.z = FAR_Z
	_exit.scale = Vector3.ONE * 0.42
	_player.position = Vector3(0.0, 0.58, PLAYER_Z)
	for hazard in _hazards.get_children():
		hazard.show()
		(hazard as Area3D).monitoring = true


func set_player_axis(axis: float) -> void:
	_player_axis = clampf(axis, -1.0, 1.0)


func show_smash() -> void:
	_active = false
	for hazard in _hazards.get_children():
		(hazard as Area3D).monitoring = false
		hazard.hide()
	_exit.position.z = -3.8
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_exit, "position:z", -2.9, 0.22).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_exit, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK)


func show_feedback(quality: float) -> void:
	_active = false
	var spread := 2.4 if quality >= 0.62 else 1.65
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Exit/DoorLeft, "position:x", -spread, 0.24).set_trans(Tween.TRANS_BACK)
	tween.tween_property($Exit/DoorRight, "position:x", spread, 0.24).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_sprite, "scale", Vector3(1.25, 0.78, 1.0), 0.1)
	tween.chain().tween_property(_sprite, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func reset_stage() -> void:
	_active = false
	_player_axis = 0.0
	_player.position = Vector3(0.0, 0.58, PLAYER_Z)
	_player.velocity = Vector3.ZERO
	_exit.position = Vector3(0.0, 1.25, -10.1)
	_exit.scale = Vector3.ONE * 0.42
	$Exit/DoorLeft.position.x = -1.4
	$Exit/DoorRight.position.x = 1.4
	_sprite.scale = Vector3.ONE
	_clear_hazards()
	_apply_route_color(_route_color("safe"))


func _physics_process(delta: float) -> void:
	var target_x := _player_axis * PLAYER_SPAN
	_player.velocity = Vector3((target_x - _player.position.x) * 15.0, 0.0, 0.0)
	_player.move_and_slide()
	_player.position.z = PLAYER_Z
	if not _active:
		return
	for index in range(_hazards.get_child_count()):
		var hazard := _hazards.get_child(index) as Area3D
		hazard.position.z += _speed * delta
		if hazard.position.z > WRAP_Z:
			hazard.position.z = -8.5 - float(index) * 2.8
			_touching.erase(hazard.get_instance_id())
		_update_hazard_scale(hazard)
	_report_collisions()


func _add_hazard(index: int, count: int) -> void:
	var hazard := Area3D.new()
	hazard.name = "BroadcastBar%d" % (index + 1)
	hazard.collision_layer = 2
	hazard.collision_mask = 1
	hazard.monitoring = true
	hazard.position = Vector3(_lane_x(index, count), 0.42, -7.8 - float(index) * 3.0)
	_hazards.add_child(hazard)

	var width := 2.35 + float(index % 2) * 0.65
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.62, 0.62)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	hazard.add_child(collision)

	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var visual := MeshInstance3D.new()
	visual.name = "LowPolyVisual"
	visual.mesh = mesh
	visual.material_override = _hazard_material(index)
	hazard.add_child(visual)
	_update_hazard_scale(hazard)


func _lane_x(index: int, count: int) -> float:
	var lanes := [-2.0, 0.0, 2.0, -0.85, 1.15]
	return float(lanes[(index + count) % lanes.size()])


func _hazard_material(index: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var accent := _route_color(str(_route.get("id", "safe")))
	material.albedo_color = accent.darkened(0.12 + float(index % 2) * 0.1)
	material.emission_enabled = true
	material.emission = accent.darkened(0.35)
	material.emission_energy_multiplier = 1.25
	material.roughness = 0.72
	return material


func _report_collisions() -> void:
	# ponytail: four hazards max; use signals only if this count grows materially.
	for child in _hazards.get_children():
		var hazard := child as Area3D
		var key := hazard.get_instance_id()
		if hazard.overlaps_body(_player):
			if not _touching.has(key):
				_touching[key] = true
				player_hit.emit()
		else:
			_touching.erase(key)


func _update_hazard_scale(hazard: Area3D) -> void:
	var progress := clampf(inverse_lerp(-9.0, WRAP_Z, hazard.position.z), 0.0, 1.0)
	var depth_scale := lerpf(0.52, 1.08, progress)
	hazard.scale = Vector3(depth_scale, depth_scale, 1.0)


func _clear_hazards() -> void:
	_touching.clear()
	for child in _hazards.get_children():
		_hazards.remove_child(child)
		child.queue_free()


func _route_color(route_id: String) -> Color:
	match route_id:
		"bold":
			return AppTheme.get_color(Tokens.WARNING, Tokens.THEME_TYPE)
		"chaos":
			return AppTheme.get_color(Tokens.SECRET, Tokens.THEME_TYPE)
	return AppTheme.get_color(Tokens.PRIMARY, Tokens.THEME_TYPE)


func _apply_route_color(accent: Color) -> void:
	for path in ["World/LaneLeft", "World/LaneRight", "Exit/DoorLeft", "Exit/DoorRight", "Exit/Top"]:
		var visual := get_node(path) as MeshInstance3D
		var material := visual.get_active_material(0).duplicate() as StandardMaterial3D
		material.albedo_color = accent
		material.emission = accent.darkened(0.45)
		visual.material_override = material


func _apply_floor_texture() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = _make_floor_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 0.92
	$World/Floor/Visual.material_override = material


func _make_floor_texture() -> ImageTexture:
	var image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var dark := AppTheme.get_color(Tokens.SURFACE, Tokens.THEME_TYPE)
	var line := dark.lightened(0.16)
	for y in range(16):
		for x in range(16):
			var is_line := x % 4 == 0 or y % 4 == 0
			image.set_pixel(x, y, line if is_line else dark)
	return ImageTexture.create_from_image(image)


func _make_player_texture() -> ImageTexture:
	var image := Image.create_empty(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var outline := AppTheme.get_color(Tokens.BACKGROUND, Tokens.THEME_TYPE)
	var face := AppTheme.get_color(Tokens.TEXT, Tokens.THEME_TYPE)
	var jacket := AppTheme.get_color(Tokens.PRIMARY, Tokens.THEME_TYPE)
	var warning := AppTheme.get_color(Tokens.WARNING, Tokens.THEME_TYPE)
	for y in range(4, 12):
		for x in range(4, 12):
			image.set_pixel(x, y, outline if x in [4, 11] or y in [4, 11] else face)
	for y in range(12, 21):
		for x in range(3, 13):
			image.set_pixel(x, y, outline if x in [3, 12] or y == 20 else jacket)
	for x in range(6, 10):
		image.set_pixel(x, 2, warning)
		image.set_pixel(x, 3, warning)
	image.set_pixel(6, 7, outline)
	image.set_pixel(9, 7, outline)
	image.set_pixel(12, 8, warning)
	return ImageTexture.create_from_image(image)
