class_name FlockWorld3D
extends Node3D

signal act_completed(act_id: String, result: Dictionary)
signal flock_changed(snapshot: Dictionary)
signal impact(kind: String, world_point: Vector3)
signal collapse_stage(stage: String)
signal reward_released(value: int)

const FOLLOW_OFFSETS := [Vector3(-0.72, 0.0, 0.82), Vector3(0.72, 0.0, 1.28)]
const FLOOR_Y := 0.56
const MAX_SPEED := 8.0
const ARRIVE_GAIN := 7.0
const FOLLOW_GAIN := 8.0
const FINGER_OFFSET := Vector2(0.0, 160.0)
const SWIPE_MIN_DISTANCE := 90.0
const SWIPE_MIN_VELOCITY := 900.0
const DASH_SPEED := 16.0
const DASH_DURATION := 0.24
const DASH_IMPULSE := 7.0
const BRAWL_TARGET_ID := "antenna_a"
const CHAIN_TARGET_IDS: Array[String] = [BRAWL_TARGET_ID, "relay_b", "vent_c"]
const CHAIN_PICK_RADIUS := 96.0
const CHAIN_TRAIL_DELAY := 0.06
const CHAIN_PATH_Y := FLOOR_Y + 0.04

var _run_state: FlockRunState
var _act_id := ""
var _drag_target := Vector3.ZERO
var _has_drag_target := false
var _resolved_routes: Dictionary = {}
var _leader: CharacterBody3D
var _swipe_start := Vector2.ZERO
var _has_swipe_candidate := false
var _dash_active := false
var _dash_remaining := 0.0
var _dash_direction := Vector3.ZERO
var _dash_collision: CollisionShape3D
var _brawl_target: Node3D
var _target_material: StandardMaterial3D
var _weak_point: RigidBody3D
var _detached_pieces: Array[RigidBody3D] = []
var _collapsed_targets: Dictionary = {}
var _reward_claimed := false
var _collapse_tween: Tween
var _chain_targets: Dictionary = {}
var _chain_target_ids: Array[String] = []
var _chain_struck_targets: Dictionary = {}
var _chain_status := ""
var _chain_expected_target_id := ""
var _chain_attack_active := false
var _chain_attack_consumed := false
var _chain_reward_claimed := false
var _chain_release_generation := 0
var _chain_path_mesh: ImmediateMesh
var _chain_path_material: StandardMaterial3D
var _attack_orb: Area3D
var _attack_orb_collision: CollisionShape3D

@onready var _camera: Camera3D = $Camera
@onready var _actors: Node3D = $Actors
@onready var _companion_slots: Node3D = $Actors/CompanionSlots

func _ready() -> void:
	_camera.look_at(Vector3(0.0, 0.0, -3.5))
	_leader = _make_bird_actor("duck")
	_leader.name = "Leader"
	_leader.position = Vector3(0.0, FLOOR_Y, 4.0)
	_actors.add_child(_leader)
	_make_dash_hitbox()
	_make_brawl_encounter()
	_make_chain_raid()

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
	_chain_reward_claimed = false
	_sync_companions()
	flock_changed.emit(_run_state.snapshot())

func start_act(act_id: String) -> void:
	cancel_gesture()
	_act_id = act_id
	_resolved_routes.clear()
	if _run_state != null:
		_run_state.begin_act(act_id)
	set_physics_process(act_id == "entry")
	if act_id == "brawl":
		_reset_brawl_encounter()
		collapse_stage.emit("warning")
	elif act_id == "chain":
		_chain_target_ids.clear()
		_chain_struck_targets.clear()
		_chain_status = ""
		_chain_attack_consumed = false
		_draw_chain_path(false)

func set_drag_target(screen_position: Vector2) -> void:
	if _act_id == "chain":
		_select_chain_target(screen_position)
		return
	if _act_id == "brawl":
		if not _has_swipe_candidate:
			_swipe_start = screen_position
			_has_swipe_candidate = true
		return
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

func release_swipe(screen_position: Vector2, velocity: Vector2) -> void:
	if _act_id == "chain":
		_release_chain()
		return
	if (
		_act_id != "brawl"
		or not _has_swipe_candidate
		or screen_position.distance_to(_swipe_start) < SWIPE_MIN_DISTANCE
		or velocity.length() < SWIPE_MIN_VELOCITY
	):
		cancel_gesture()
		return
	_has_swipe_candidate = false
	_dash_direction = Vector3(velocity.x, 0.0, velocity.y).normalized()
	_dash_remaining = DASH_DURATION
	_dash_active = true
	_dash_collision.set_deferred("disabled", false)
	set_physics_process(true)

func cancel_gesture() -> void:
	if _chain_attack_active:
		_chain_attack_consumed = false
	_chain_release_generation += 1
	_chain_attack_active = false
	_chain_expected_target_id = ""
	_chain_target_ids.clear()
	_chain_struck_targets.clear()
	_chain_status = ""
	if _attack_orb_collision != null:
		_attack_orb_collision.set_deferred("disabled", true)
	if _attack_orb != null:
		_attack_orb.visible = false
	if _chain_path_mesh != null:
		_chain_path_mesh.clear_surfaces()
	_has_drag_target = false
	_has_swipe_candidate = false
	_dash_active = false
	_dash_remaining = 0.0
	if _dash_collision != null:
		_dash_collision.set_deferred("disabled", true)
	if _leader != null:
		_leader.velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if _act_id == "brawl":
		if not _dash_active:
			return
		_leader.velocity = _dash_direction * DASH_SPEED
		_leader.move_and_slide()
		_leader.position.y = FLOOR_Y
		_dash_remaining -= delta
		if _dash_remaining <= 0.0:
			cancel_gesture()
		return
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
			for companion in [{"id": "goose_greta", "species": "goose"}, {"id": "pigeon_pip", "species": "pigeon"}]:
				if _run_state.rescue(companion.id, companion.species):
					_run_state.record_event("rescue", companion)
			_sync_companions()
			flock_changed.emit(_run_state.snapshot())
			impact.emit("rescue", _leader.global_position)
		"score":
			_run_state.record_event("approach_score", {"value": 100})
			impact.emit("score", _leader.global_position)
	cancel_gesture()
	set_physics_process(false)
	act_completed.emit("entry", result)

func trigger_collapse(target_id: String, force_direction: Vector3) -> bool:
	if target_id != BRAWL_TARGET_ID or _collapsed_targets.has(target_id):
		return false
	_collapsed_targets[target_id] = true
	var releases_reward := not _reward_claimed
	_reward_claimed = true
	_set_target_color(Color(1.0, 0.93, 0.72))
	collapse_stage.emit("contact")
	_collapse_tween = create_tween()
	_collapse_tween.tween_interval(0.12)
	_collapse_tween.tween_callback(_show_collapse_crack)
	_collapse_tween.tween_interval(0.12)
	_collapse_tween.tween_callback(_release_collapse_pieces.bind(force_direction))
	_collapse_tween.tween_interval(0.12)
	_collapse_tween.tween_callback(_lower_collapse_target)
	if releases_reward:
		_collapse_tween.tween_interval(0.12)
		_collapse_tween.tween_callback(_emit_collapse_reward)
	return true

func _show_collapse_crack() -> void:
	_set_target_color(Color(0.27, 0.29, 0.34))
	collapse_stage.emit("crack")

func _release_collapse_pieces(force_direction: Vector3) -> void:
	for index in range(_detached_pieces.size()):
		var piece := _detached_pieces[index]
		piece.visible = true
		piece.freeze = false
		piece.apply_central_impulse(force_direction * 4.0 + Vector3(index - 1, 2.2, 0.0))
	collapse_stage.emit("pieces")

func _lower_collapse_target() -> void:
	_brawl_target.position.y -= 1.35
	collapse_stage.emit("collapse")

func _emit_collapse_reward() -> void:
	collapse_stage.emit("reward")
	reward_released.emit(1)

func _on_dash_body_entered(body: Node3D) -> void:
	if not _dash_active or body != _weak_point:
		return
	_dash_active = false
	_dash_collision.set_deferred("disabled", true)
	_leader.velocity = Vector3.ZERO
	_weak_point.apply_central_impulse(_dash_direction * DASH_IMPULSE)
	impact.emit("dash", _weak_point.global_position)
	trigger_collapse(str(_weak_point.get_meta("target_id")), _dash_direction)

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

func _select_chain_target(screen_position: Vector2) -> void:
	if _chain_attack_active or _chain_attack_consumed:
		return
	var selected_id := ""
	var selected_distance := CHAIN_PICK_RADIUS
	for target_id in CHAIN_TARGET_IDS:
		var target := _chain_targets.get(target_id) as Node3D
		if target == null or _camera.is_position_behind(target.global_position):
			continue
		var target_distance := _camera.unproject_position(target.global_position).distance_to(screen_position)
		if target_distance <= selected_distance:
			selected_id = target_id
			selected_distance = target_distance
	if selected_id.is_empty() or _chain_target_ids.has(selected_id):
		return
	_chain_target_ids.append(selected_id)
	_chain_status = "drawing"
	_draw_chain_path(false)

func _release_chain() -> void:
	if _chain_attack_active or _chain_attack_consumed:
		return
	if _chain_target_ids.size() < 2:
		_chain_status = "broken"
		_draw_chain_path(true)
		return
	_chain_attack_consumed = true
	_chain_attack_active = true
	_chain_status = "released"
	_chain_struck_targets.clear()
	var released_ids: Array[String] = _chain_target_ids.duplicate()
	_chain_target_ids.clear()
	_draw_chain_path(false)
	_chain_release_generation += 1
	_execute_chain(released_ids, _chain_release_generation)

func _execute_chain(target_ids: Array[String], generation: int) -> void:
	_attack_orb.visible = true
	_attack_orb.global_position = Vector3(0.0, -20.0, 0.0)
	_attack_orb_collision.set_deferred("disabled", false)
	await get_tree().physics_frame
	for index in range(target_ids.size()):
		if generation != _chain_release_generation:
			return
		var target_id := target_ids[index]
		var target := _chain_targets.get(target_id) as Node3D
		if target == null:
			continue
		_chain_expected_target_id = target_id
		_attack_orb.global_position = target.global_position
		for _frame in range(4):
			await get_tree().physics_frame
			if generation != _chain_release_generation:
				return
			if _chain_struck_targets.has(target_id):
				break
		if not _chain_struck_targets.has(target_id):
			continue
		await get_tree().create_timer(CHAIN_TRAIL_DELAY).timeout
		if generation != _chain_release_generation:
			return
		_trail_chain_companion(index, target.global_position)
		_attack_orb.global_position = Vector3(0.0, -20.0, 0.0)
		await get_tree().physics_frame
		if generation != _chain_release_generation:
			return
	if generation != _chain_release_generation:
		return
	if _chain_struck_targets.size() != target_ids.size():
		_chain_status = "broken"
		_chain_attack_active = false
		_chain_attack_consumed = false
		_chain_target_ids = target_ids.duplicate()
		_attack_orb.visible = false
		_attack_orb_collision.set_deferred("disabled", true)
		_draw_chain_path(true)
		return
	if not _collapsed_targets.has(BRAWL_TARGET_ID):
		_reward_claimed = true
		trigger_collapse(BRAWL_TARGET_ID, Vector3.FORWARD)
	if _collapse_tween != null and _collapse_tween.is_valid() and _collapse_tween.is_running():
		await _collapse_tween.finished
		if generation != _chain_release_generation:
			return
	for target_id in target_ids:
		var target := _chain_targets[target_id] as RigidBody3D
		target.freeze = true
		target.position.y = minf(target.position.y, FLOOR_Y - 0.35)
	_chain_expected_target_id = ""
	_chain_attack_active = false
	_attack_orb.visible = false
	_attack_orb_collision.set_deferred("disabled", true)
	if _run_state != null:
		_run_state.record_event("chain_targets", {"target_ids": target_ids})
		for target_id in target_ids:
			_run_state.record_event("chain_strike", {"target_id": target_id})
	if not _chain_reward_claimed:
		_chain_reward_claimed = true
		reward_released.emit(1)
	act_completed.emit("chain", {"status": "released", "target_ids": target_ids})

func _on_attack_orb_body_entered(body: Node3D) -> void:
	if not _chain_attack_active or not body.has_meta("target_id"):
		return
	var target_id := str(body.get_meta("target_id"))
	if target_id != _chain_expected_target_id or _chain_struck_targets.has(target_id):
		return
	_chain_struck_targets[target_id] = true
	_flash_chain_target(body)
	impact.emit("chain_strike", body.global_position)

func _trail_chain_companion(index: int, target_position: Vector3) -> void:
	var visible_companions: Array[CharacterBody3D] = []
	for slot in _companion_slots.get_children():
		if slot.get_child_count() > 0 and slot.get_child(0).visible:
			visible_companions.append(slot.get_child(0) as CharacterBody3D)
	if visible_companions.is_empty():
		return
	var companion := visible_companions[index % visible_companions.size()]
	companion.global_position = target_position + FOLLOW_OFFSETS[index % FOLLOW_OFFSETS.size()] * 0.35

func _flash_chain_target(target: Node3D) -> void:
	var visual := target.get_node_or_null("Visual") as MeshInstance3D
	if visual == null:
		return
	var material := visual.mesh.material as StandardMaterial3D
	var base_color: Color = target.get_meta("chain_color")
	material.albedo_color = Color(1.0, 0.95, 0.5)
	create_tween().tween_property(material, "albedo_color", base_color, 0.18)

func _draw_chain_path(broken: bool) -> void:
	if _chain_path_mesh == null:
		return
	_chain_path_mesh.clear_surfaces()
	if _chain_target_ids.is_empty() and not broken:
		return
	_chain_path_material.albedo_color = Color(1.0, 0.16, 0.2) if broken else Color(0.1, 1.0, 0.86)
	_chain_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _chain_path_material)
	if _chain_target_ids.is_empty():
		var marker_position := _leader.global_position
		_chain_path_mesh.surface_add_vertex(Vector3(marker_position.x - 0.24, CHAIN_PATH_Y, marker_position.z))
		_chain_path_mesh.surface_add_vertex(Vector3(marker_position.x + 0.24, CHAIN_PATH_Y, marker_position.z))
	elif _chain_target_ids.size() == 1:
		var marker_target := _chain_targets[_chain_target_ids[0]] as Node3D
		var marker_position := marker_target.global_position
		_chain_path_mesh.surface_add_vertex(Vector3(marker_position.x - 0.24, CHAIN_PATH_Y, marker_position.z))
		_chain_path_mesh.surface_add_vertex(Vector3(marker_position.x + 0.24, CHAIN_PATH_Y, marker_position.z))
	else:
		for target_id in _chain_target_ids:
			var target := _chain_targets[target_id] as Node3D
			_chain_path_mesh.surface_add_vertex(Vector3(target.global_position.x, CHAIN_PATH_Y, target.global_position.z))
	_chain_path_mesh.surface_end()

func _make_dash_hitbox() -> void:
	var hitbox := Area3D.new()
	hitbox.name = "DashHitbox"
	hitbox.position.z = -0.35
	hitbox.collision_layer = 0
	hitbox.collision_mask = 8
	_leader.add_child(hitbox)
	var shape := SphereShape3D.new()
	shape.radius = 0.72
	_dash_collision = CollisionShape3D.new()
	_dash_collision.name = "Collision"
	_dash_collision.shape = shape
	_dash_collision.disabled = true
	hitbox.add_child(_dash_collision)
	hitbox.body_entered.connect(_on_dash_body_entered)

func _make_brawl_encounter() -> void:
	_brawl_target = Node3D.new()
	_brawl_target.name = "BrawlTarget"
	_brawl_target.position = Vector3(0.0, 0.9, 0.0)
	$Encounter.add_child(_brawl_target)
	_target_material = StandardMaterial3D.new()
	var target_mesh := BoxMesh.new()
	target_mesh.size = Vector3(2.8, 2.2, 1.3)
	target_mesh.material = _target_material
	var target_visual := MeshInstance3D.new()
	target_visual.mesh = target_mesh
	_brawl_target.add_child(target_visual)
	_set_target_color(Color(0.4, 0.44, 0.52))
	_weak_point = RigidBody3D.new()
	_weak_point.name = "BrawlWeakPoint"
	_weak_point.position = Vector3(0.0, FLOOR_Y, 1.35)
	_weak_point.freeze = true
	_weak_point.collision_layer = 8
	_weak_point.collision_mask = 4
	_weak_point.set_meta("target_id", BRAWL_TARGET_ID)
	$Encounter.add_child(_weak_point)
	var weak_shape := SphereShape3D.new()
	weak_shape.radius = 0.46
	var weak_collision := CollisionShape3D.new()
	weak_collision.shape = weak_shape
	_weak_point.add_child(weak_collision)
	var weak_material := StandardMaterial3D.new()
	weak_material.albedo_color = Color(0.94, 0.22, 0.2)
	var weak_mesh := SphereMesh.new()
	weak_mesh.radius = 0.46
	weak_mesh.height = 0.92
	weak_mesh.radial_segments = 8
	weak_mesh.rings = 4
	weak_mesh.material = weak_material
	var weak_visual := MeshInstance3D.new()
	weak_visual.name = "Visual"
	weak_visual.mesh = weak_mesh
	_weak_point.add_child(weak_visual)
	_weak_point.set_meta("chain_color", weak_material.albedo_color)

	var pieces := Node3D.new()
	pieces.name = "DetachedPieces"
	$Encounter.add_child(pieces)
	for index in range(3):
		var piece := RigidBody3D.new()
		piece.position = Vector3((index - 1) * 0.7, 1.45 + index * 0.25, 0.0)
		piece.freeze = true
		piece.visible = false
		piece.collision_layer = 8
		piece.collision_mask = 4
		pieces.add_child(piece)
		var piece_shape := BoxShape3D.new()
		piece_shape.size = Vector3(0.6, 0.45, 0.9)
		var piece_collision := CollisionShape3D.new()
		piece_collision.shape = piece_shape
		piece.add_child(piece_collision)
		var piece_mesh := BoxMesh.new()
		piece_mesh.size = piece_shape.size
		piece_mesh.material = _target_material
		var piece_visual := MeshInstance3D.new()
		piece_visual.mesh = piece_mesh
		piece.add_child(piece_visual)
		_detached_pieces.append(piece)

func _make_chain_raid() -> void:
	_chain_targets[BRAWL_TARGET_ID] = _weak_point
	_chain_targets["relay_b"] = _make_chain_weak_point(
		"ChainRelayB",
		"relay_b",
		Vector3(-2.2, FLOOR_Y, -1.0),
		Color(0.14, 0.88, 0.82)
	)
	_chain_targets["vent_c"] = _make_chain_weak_point(
		"ChainVentC",
		"vent_c",
		Vector3(2.2, FLOOR_Y, -3.0),
		Color(0.69, 0.42, 0.95)
	)

	_chain_path_mesh = ImmediateMesh.new()
	_chain_path_material = StandardMaterial3D.new()
	_chain_path_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chain_path_material.no_depth_test = true
	var chain_path := MeshInstance3D.new()
	chain_path.name = "ChainPath"
	chain_path.mesh = _chain_path_mesh
	$Effects.add_child(chain_path)

	_attack_orb = Area3D.new()
	_attack_orb.name = "AttackOrb"
	_attack_orb.visible = false
	_attack_orb.collision_layer = 0
	_attack_orb.collision_mask = 8
	$Effects.add_child(_attack_orb)
	var orb_material := StandardMaterial3D.new()
	orb_material.albedo_color = Color(1.0, 0.95, 0.5)
	orb_material.emission_enabled = true
	orb_material.emission = orb_material.albedo_color
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.34
	orb_mesh.height = 0.68
	orb_mesh.material = orb_material
	var orb_visual := MeshInstance3D.new()
	orb_visual.name = "Visual"
	orb_visual.mesh = orb_mesh
	_attack_orb.add_child(orb_visual)
	var orb_shape := SphereShape3D.new()
	orb_shape.radius = 0.38
	_attack_orb_collision = CollisionShape3D.new()
	_attack_orb_collision.name = "Collision"
	_attack_orb_collision.shape = orb_shape
	_attack_orb_collision.disabled = true
	_attack_orb.add_child(_attack_orb_collision)
	_attack_orb.body_entered.connect(_on_attack_orb_body_entered)

func _make_chain_weak_point(
	node_name: String,
	target_id: String,
	world_position: Vector3,
	color: Color
) -> RigidBody3D:
	var target := RigidBody3D.new()
	target.name = node_name
	target.position = world_position
	target.freeze = true
	target.collision_layer = 8
	target.collision_mask = 4
	target.set_meta("target_id", target_id)
	target.set_meta("chain_color", color)
	$Encounter.add_child(target)
	var shape := SphereShape3D.new()
	shape.radius = 0.48
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	target.add_child(collision)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.35
	var mesh := SphereMesh.new()
	mesh.radius = 0.48
	mesh.height = 0.96
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = mesh
	target.add_child(visual)
	return target

func _reset_brawl_encounter() -> void:
	if _collapse_tween != null and _collapse_tween.is_valid():
		_collapse_tween.kill()
	_collapsed_targets.clear()
	_reward_claimed = false
	_weak_point.freeze = true
	for piece in _detached_pieces:
		piece.freeze = true
	_brawl_target.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.9, 0.0))
	_weak_point.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, FLOOR_Y, 1.35))
	_weak_point.linear_velocity = Vector3.ZERO
	_weak_point.angular_velocity = Vector3.ZERO
	for index in range(_detached_pieces.size()):
		var piece := _detached_pieces[index]
		piece.transform = Transform3D(
			Basis.IDENTITY,
			Vector3((index - 1) * 0.7, 1.45 + index * 0.25, 0.0)
		)
		piece.linear_velocity = Vector3.ZERO
		piece.angular_velocity = Vector3.ZERO
		piece.visible = false
	_weak_point.freeze = false
	_set_target_color(Color(0.98, 0.67, 0.16))

func _set_target_color(color: Color) -> void:
	_target_material.albedo_color = color

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
