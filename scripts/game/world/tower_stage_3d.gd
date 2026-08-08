extends Node3D

signal player_hit
signal hazard_dodged(near_miss: bool)
signal all_hazards_cleared

const AppTheme = preload("res://ui/themes/app_theme.tres")
const Tokens = preload("res://scripts/ui/design_tokens.gd")
const PLAYER_Z := 3.35
const FAR_Z := -10.0
const PASS_Z := 4.45
const PLAYER_SPAN := 2.85

var _difficulty := 0.5
var _route: Dictionary = {}
var _player_axis := 0.0
var _active := false
var _speed := 5.5
var _resolved: Dictionary = {}
var _cleared_count := 0

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
	_speed = 5.6 + _difficulty * 2.4 + float(_route.get("speed_bonus", 0.0)) / 70.0
	_clear_hazards()
	var count := maxi(2, int(_route.get("hazards", 3)))
	for index in range(count):
		_add_hazard(index, count)
	_apply_route_color(_route_color(str(_route.get("id", "safe"))))


func start_dodge() -> void:
	_active = true
	_resolved.clear()
	_cleared_count = 0
	_exit.position.z = FAR_Z
	_exit.scale = Vector3.ONE * 0.42
	_player.position = Vector3(0.0, 0.58, PLAYER_Z)
	_sprite.modulate = Color.WHITE
	for hazard: Area3D in _hazards.get_children():
		hazard.show()
		hazard.monitoring = true
		var visual := hazard.get_node("LowPolyVisual") as GeometryInstance3D
		visual.transparency = 0.0


func set_player_axis(axis: float) -> void:
	_player_axis = clampf(axis, -1.0, 1.0)


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
	_sprite.modulate = Color.WHITE
	_resolved.clear()
	_cleared_count = 0
	_clear_hazards()
	_apply_route_color(_route_color("safe"))


func _physics_process(delta: float) -> void:
	var target_x := _player_axis * PLAYER_SPAN
	_player.velocity = Vector3((target_x - _player.position.x) * 16.0, 0.0, 0.0)
	_player.move_and_slide()
	_player.position.z = PLAYER_Z
	if not _active:
		return
	for hazard: Area3D in _hazards.get_children():
		if _resolved.has(hazard.get_instance_id()):
			continue
		hazard.position.z += _speed * delta
		_update_hazard_scale(hazard)
		if hazard.overlaps_body(_player):
			_resolve_hit(hazard)
			break
		if hazard.position.z > PASS_Z:
			_resolve_dodge(hazard)


func _resolve_hit(hazard: Area3D) -> void:
	var key := hazard.get_instance_id()
	if _resolved.has(key):
		return
	_resolved[key] = "hit"
	_active = false
	for other: Area3D in _hazards.get_children():
		other.monitoring = false
	var visual := hazard.get_node("LowPolyVisual") as MeshInstance3D
	var material := visual.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_color = AppTheme.get_color(Tokens.DANGER, Tokens.THEME_TYPE)
	material.emission = material.albedo_color.darkened(0.25)
	visual.material_override = material
	_sprite.modulate = AppTheme.get_color(Tokens.DANGER, Tokens.THEME_TYPE)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hazard, "scale", hazard.scale * 1.18, 0.08)
	tween.tween_property(_sprite, "scale", Vector3(1.35, 0.65, 1.0), 0.08)
	var hit_direction := signf(hazard.position.x + 0.01)
	tween.tween_property(_sprite, "position:x", _sprite.position.x - hit_direction * 0.24, 0.08)
	player_hit.emit()


func _resolve_dodge(hazard: Area3D) -> void:
	var key := hazard.get_instance_id()
	if _resolved.has(key):
		return
	_resolved[key] = "dodge"
	hazard.monitoring = false
	_cleared_count += 1
	var shape := hazard.get_node("Collision").shape as BoxShape3D
	var half_width := shape.size.x * hazard.scale.x * 0.5
	var near_miss := absf(_player.position.x - hazard.position.x) < half_width + 0.55
	var visual := hazard.get_node("LowPolyVisual") as GeometryInstance3D
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hazard, "scale", Vector3(hazard.scale.x * 1.12, 0.04, 1.0), 0.16)
	tween.tween_property(visual, "transparency", 1.0, 0.16)
	tween.chain().tween_callback(hazard.hide)
	hazard_dodged.emit(near_miss)
	if _cleared_count == _hazards.get_child_count():
		_active = false
		_open_exit()
		all_hazards_cleared.emit()


func _open_exit() -> void:
	_exit.position.z = -3.2
	_exit.scale = Vector3.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Exit/DoorLeft, "position:x", -2.5, 0.24).set_trans(Tween.TRANS_BACK)
	tween.tween_property($Exit/DoorRight, "position:x", 2.5, 0.24).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_sprite, "scale", Vector3(0.82, 1.22, 1.0), 0.10)
	tween.chain().tween_property(_sprite, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK)


func _add_hazard(index: int, count: int) -> void:
	var hazard := Area3D.new()
	hazard.name = "BroadcastBar%d" % (index + 1)
	hazard.collision_layer = 2
	hazard.collision_mask = 1
	hazard.monitoring = true
	hazard.position = Vector3(_lane_x(index, count), 0.42, -7.2 - float(index) * 2.35)
	_hazards.add_child(hazard)

	var width := 2.25 + float(index % 2) * 0.72
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


func _update_hazard_scale(hazard: Area3D) -> void:
	var progress := clampf(inverse_lerp(-9.0, PASS_Z, hazard.position.z), 0.0, 1.0)
	var depth_scale := lerpf(0.52, 1.08, progress)
	hazard.scale = Vector3(depth_scale, depth_scale, 1.0)


func _clear_hazards() -> void:
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
			image.set_pixel(x, y, line if x % 4 == 0 or y % 4 == 0 else dark)
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
