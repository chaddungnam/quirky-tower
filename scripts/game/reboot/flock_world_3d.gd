class_name FlockWorld3D
extends Node3D

signal act_completed(act_id: String, result: Dictionary)
signal flock_changed(snapshot: Dictionary)
signal impact(kind: String, world_point: Vector3)
signal collapse_stage(stage: String)

const FOLLOW_OFFSETS := [Vector3(-0.72, 0.0, 0.82), Vector3(0.72, 0.0, 1.28)]
const FLOOR_Y := 0.56
const MAX_SPEED := 8.0
const ARRIVE_GAIN := 7.0
const FOLLOW_GAIN := 8.0
const FINGER_OFFSET := Vector2(0.0, 160.0)

var _run_state: FlockRunState
var _act_id := ""
var _drag_target := Vector3.ZERO
var _has_drag_target := false
var _resolved_routes: Dictionary = {}
var _leader: CharacterBody3D

@onready var _camera: Camera3D = $Camera
@onready var _actors: Node3D = $Actors
@onready var _companion_slots: Node3D = $Actors/CompanionSlots


func _ready() -> void:
	_camera.look_at(Vector3(0.0, 0.0, -3.5))
	_leader = _make_bird_actor("duck")
	_leader.name = "Leader"
	_leader.position = Vector3(0.0, FLOOR_Y, 4.0)
	_actors.add_child(_leader)

	var goose := _make_bird_actor("goose")
	goose.visible = false
	_companion_slots.get_node("CompanionSlot1").add_child(goose)
	var pigeon := _make_bird_actor("pigeon")
	pigeon.visible = false
	_companion_slots.get_node("CompanionSlot2").add_child(pigeon)

	for route_kind in ["hazard", "rescue", "score"]:
		var area := get_node("Encounter/%s" % route_kind.capitalize()) as Area3D
		area.body_entered.connect(_on_route_entered.bind(route_kind))
	_drag_target = _leader.global_position


func setup(run_state: FlockRunState) -> void:
	_run_state = run_state
	_sync_companions()
	flock_changed.emit(_run_state.snapshot())


func start_act(act_id: String) -> void:
	cancel_gesture()
	_act_id = act_id
	_resolved_routes.clear()
	if _run_state != null:
		_run_state.begin_act(act_id)
	set_physics_process(act_id == "entry")


func set_drag_target(screen_position: Vector2) -> void:
	if _act_id != "entry":
		return
	var adjusted_position := screen_position - FINGER_OFFSET
	var ray_origin := _camera.project_ray_origin(adjusted_position)
	var ray_direction := _camera.project_ray_normal(adjusted_position)
	if is_zero_approx(ray_direction.y):
		return
	var distance := (FLOOR_Y - ray_origin.y) / ray_direction.y
	if distance <= 0.0:
		return
	var world_point := ray_origin + ray_direction * distance
	_drag_target = Vector3(
		clampf(world_point.x, -4.0, 4.0),
		FLOOR_Y,
		clampf(world_point.z, -11.5, 4.0)
	)
	_has_drag_target = true


func release_swipe(_screen_position: Vector2, _velocity: Vector2) -> void:
	cancel_gesture()


func cancel_gesture() -> void:
	_has_drag_target = false
	if _leader != null:
		_leader.velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _act_id != "entry" or not _has_drag_target:
		return
	var offset := _drag_target - _leader.global_position
	offset.y = 0.0
	var speed := minf(MAX_SPEED, offset.length() * ARRIVE_GAIN)
	_leader.velocity = offset.normalized() * speed if not offset.is_zero_approx() else Vector3.ZERO
	_leader.move_and_slide()
	_leader.position.y = FLOOR_Y
	_update_companions(delta)


func _update_companions(delta: float) -> void:
	for index in range(_companion_slots.get_child_count()):
		var slot := _companion_slots.get_child(index)
		if slot.get_child_count() == 0:
			continue
		var companion := slot.get_child(0) as CharacterBody3D
		if not companion.visible:
			continue
		var follow_target: Vector3 = _leader.global_position + FOLLOW_OFFSETS[index]
		companion.global_position = companion.global_position.lerp(
			follow_target,
			clampf(FOLLOW_GAIN * delta, 0.0, 1.0)
		)


func _on_route_entered(body: Node3D, route_kind: String) -> void:
	if body != _leader or _act_id != "entry" or not _resolved_routes.is_empty():
		return
	_resolved_routes["resolved"] = route_kind
	var result := {"route": route_kind}
	match route_kind:
		"hazard":
			_run_state.record_event("approach_collision", result)
			impact.emit("hazard", _leader.global_position)
		"rescue":
			if _run_state.rescue("goose_greta", "goose"):
				_run_state.record_event("rescue", {"id": "goose_greta", "species": "goose"})
				_sync_companions()
				flock_changed.emit(_run_state.snapshot())
			impact.emit("rescue", _leader.global_position)
		"score":
			_run_state.record_event("approach_score", {"value": 100})
			impact.emit("score", _leader.global_position)
	cancel_gesture()
	set_physics_process(false)
	act_completed.emit("entry", result)


func _sync_companions() -> void:
	if _run_state == null:
		return
	for slot in _companion_slots.get_children():
		if slot.get_child_count() > 0:
			slot.get_child(0).visible = false
	for companion_data in _run_state.companions:
		var species := str(companion_data.species)
		for slot in _companion_slots.get_children():
			if slot.get_child_count() == 0:
				continue
			var bird := slot.get_child(0) as CharacterBody3D
			if str(bird.get_meta("species")) == species:
				bird.visible = true
				bird.global_position = _leader.global_position + FOLLOW_OFFSETS[slot.get_index()]
				break


func _make_bird_actor(species: String) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.name = species.capitalize()
	actor.set_meta("species", species)
	actor.collision_layer = 1 if species == "duck" else 0
	actor.collision_mask = 4 if species == "duck" else 0

	var body_color := Color(0.93, 0.74, 0.26)
	var head_color := Color(0.98, 0.86, 0.4)
	var body_scale := Vector3(1.0, 0.82, 1.12)
	var head_y := 0.62
	var bill_size := Vector3(0.48, 0.12, 0.38)
	var collision_height := 1.1
	var collision_radius := 0.36
	match species:
		"goose":
			body_color = Color(0.83, 0.86, 0.82)
			head_color = Color(0.93, 0.94, 0.89)
			body_scale = Vector3(0.9, 1.0, 1.15)
			head_y = 1.28
			bill_size = Vector3(0.42, 0.11, 0.52)
			collision_height = 1.75
			collision_radius = 0.34
		"pigeon":
			body_color = Color(0.38, 0.44, 0.56)
			head_color = Color(0.46, 0.53, 0.63)
			body_scale = Vector3(0.72, 0.64, 0.82)
			head_y = 0.47
			bill_size = Vector3(0.3, 0.08, 0.24)
			collision_height = 0.82
			collision_radius = 0.27

	var collision_shape := CapsuleShape3D.new()
	collision_shape.height = collision_height
	collision_shape.radius = collision_radius
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = collision_shape
	actor.add_child(collision)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = body_color
	body_material.roughness = 0.9
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.52
	body_mesh.height = 1.04
	body_mesh.radial_segments = 8
	body_mesh.rings = 4
	body_mesh.material = body_material
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.scale = body_scale
	actor.add_child(body)

	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = head_color
	head_material.roughness = 0.9
	if species == "goose":
		var neck_mesh := CylinderMesh.new()
		neck_mesh.top_radius = 0.19
		neck_mesh.bottom_radius = 0.26
		neck_mesh.height = 0.9
		neck_mesh.radial_segments = 6
		neck_mesh.material = head_material
		var neck := MeshInstance3D.new()
		neck.name = "Neck"
		neck.position.y = 0.76
		neck.mesh = neck_mesh
		actor.add_child(neck)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3 if species != "pigeon" else 0.24
	head_mesh.height = 0.6 if species != "pigeon" else 0.48
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	head_mesh.material = head_material
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, head_y, 0.12)
	head.mesh = head_mesh
	actor.add_child(head)

	var bill_material := StandardMaterial3D.new()
	bill_material.albedo_color = Color(0.95, 0.45, 0.12)
	bill_material.roughness = 0.85
	var bill_mesh := BoxMesh.new()
	bill_mesh.size = bill_size
	bill_mesh.material = bill_material
	var bill := MeshInstance3D.new()
	bill.name = "Bill"
	bill.position = Vector3(0.0, head_y - 0.04, 0.38)
	bill.mesh = bill_mesh
	actor.add_child(bill)

	var foot_material := StandardMaterial3D.new()
	foot_material.albedo_color = Color(0.9, 0.42, 0.1)
	foot_material.roughness = 0.9
	var foot_mesh := BoxMesh.new()
	foot_mesh.size = Vector3(0.22, 0.08, 0.36)
	foot_mesh.material = foot_material
	for side in [-1.0, 1.0]:
		var foot := MeshInstance3D.new()
		foot.name = "FootLeft" if side < 0.0 else "FootRight"
		foot.position = Vector3(side * 0.2, -0.48, 0.14)
		foot.mesh = foot_mesh
		actor.add_child(foot)

	if species == "pigeon":
		var band_material := StandardMaterial3D.new()
		band_material.albedo_color = Color(0.17, 0.74, 0.67)
		band_material.roughness = 0.85
		var band_mesh := BoxMesh.new()
		band_mesh.size = Vector3(0.82, 0.12, 0.52)
		band_mesh.material = band_material
		var wing_band := MeshInstance3D.new()
		wing_band.name = "WingBand"
		wing_band.position = Vector3(0.0, 0.02, 0.03)
		wing_band.mesh = band_mesh
		actor.add_child(wing_band)

	var face_image := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	face_image.fill(Color.TRANSPARENT)
	for y in range(2, 14):
		for x in range(2, 14):
			face_image.set_pixel(x, y, head_color)
	var eye_color := Color(0.04, 0.05, 0.08)
	for eye_x in [5, 10]:
		face_image.set_pixel(eye_x, 6, eye_color)
		face_image.set_pixel(eye_x, 7, eye_color)
	for x in range(6, 10):
		face_image.set_pixel(x, 10, bill_material.albedo_color)
		face_image.set_pixel(x, 11, bill_material.albedo_color)
	var face := Sprite3D.new()
	face.name = "FaceSurface"
	face.position = Vector3(0.0, head_y, 0.43)
	face.pixel_size = 0.025 if species != "pigeon" else 0.021
	face.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	face.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	face.texture = ImageTexture.create_from_image(face_image)
	actor.add_child(face)

	return actor
