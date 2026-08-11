extends SceneTree

const FlockRunState = preload("res://scripts/core/reboot/flock_run_state.gd")
const FlockWorldScene = preload("res://scenes/game/reboot/flock_trial.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node3D = FlockWorldScene.instantiate()
	root.add_child(world)
	await process_frame

	var cameras: Array[Node] = world.find_children("*", "Camera3D", true, false)
	assert(cameras.size() == 1, "the flock world has one camera")
	var camera := cameras[0] as Camera3D
	assert(camera.current, "the flock camera is current")
	assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "the flock camera is orthographic")
	assert(absf(camera.rotation.x) > 0.1 and absf(camera.rotation.y) > 0.1, "the camera is fixed and diagonal")

	var leader := world.get_node("Actors/Leader") as CharacterBody3D
	var leader_collision := leader.get_node("Collision") as CollisionShape3D
	assert(leader_collision.shape != null, "the leader has a real collision shape")
	var companion_slots: Node = world.get_node("Actors/CompanionSlots")
	assert(companion_slots.get_child_count() == 2, "the world reserves two companion slots")
	var route_markers: Node = world.get_node("World/RouteMarkers")
	assert(route_markers.get_child_count() == 3, "Approach presents three route markers")
	for legacy_name in ["TowerTrial", "TimingRing", "TapPanic", "DragDodge", "MiniGame"]:
		assert(world.find_child(legacy_name, true, false) == null, "the reboot world has no old mini-game child")

	var state := FlockRunState.new_run(424242)
	world.setup(state)
	world.start_act("entry")
	var start_position := leader.global_position
	var viewport_size: Vector2 = world.get_viewport().get_visible_rect().size
	var drag_position := Vector2(viewport_size.x * 0.78, viewport_size.y * 0.68)
	world.set_drag_target(drag_position)
	var drag_target: Vector3 = world.get("_drag_target")
	assert(is_equal_approx(drag_target.y, 0.56), "drag targets the floor plane")
	assert(camera.unproject_position(drag_target).y < drag_position.y, "drag target stays above the finger")
	for _frame in range(4):
		await physics_frame
	assert(leader.global_position.distance_to(start_position) > 0.01, "drag moves the real leader body")

	world.set_physics_process(false)
	var completed_routes: Array = []
	world.act_completed.connect(
		func(_act_id: String, result: Dictionary) -> void: completed_routes.append(result.route)
	)
	var rescue_area := world.get_node("Encounter/Rescue") as Area3D
	rescue_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(rescue_area.overlaps_body(leader), "native physics reports the rescue overlap")
	assert(state.companions.size() == 1, "the rescue overlap adds one companion")
	assert(state.event_ledger.size() == 1, "the rescue overlap records one event")
	assert(completed_routes.size() == 1, "the first route completes Approach once")
	rescue_area.global_position += Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	var score_area := world.get_node("Encounter/Score") as Area3D
	score_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(state.event_ledger.size() == 1, "an adjacent route cannot resolve after the first")
	assert(completed_routes.size() == 1, "an adjacent route cannot complete Approach twice")
	score_area.global_position += Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	rescue_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(state.companions.size() == 1, "the same rescue cannot add twice")
	assert(state.event_ledger.size() == 1, "the same route cannot record twice")

	var goose := companion_slots.get_node("CompanionSlot1/Goose") as CharacterBody3D
	var pigeon := companion_slots.get_node("CompanionSlot2/Pigeon") as CharacterBody3D
	assert(goose.visible, "the rescued goose occupies the first follow slot")
	assert(not pigeon.visible, "the unrecruited pigeon keeps its slot hidden")
	assert(goose.get_node("Head").position.y > leader.get_node("Head").position.y, "the goose silhouette is taller")
	assert(pigeon.has_node("WingBand"), "the smaller pigeon has a readable wing band")
	for bird in [leader, goose, pigeon]:
		var face := bird.get_node("FaceSurface") as Sprite3D
		assert(face.texture.get_size() == Vector2(16, 16), "bird faces use a 16x16 surface")
		assert(face.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "bird faces keep nearest filtering")

	var weak_point := world.get_node("Encounter/BrawlWeakPoint") as RigidBody3D
	var dash_collision := world.get_node("Actors/Leader/DashHitbox/Collision") as CollisionShape3D
	var collapse_stages: Array[String] = []
	var rewards: Array[int] = []
	var dash_contacts: Array[Vector3] = []
	world.collapse_stage.connect(func(stage: String) -> void: collapse_stages.append(stage))
	world.reward_released.connect(func(value: int) -> void: rewards.append(value))
	world.impact.connect(
		func(kind: String, world_point: Vector3) -> void:
			if kind == "dash":
				dash_contacts.append(world_point)
	)
	world.start_act("brawl")
	assert(collapse_stages == ["warning"], "Brawl warns before any contact feedback")
	world.set_drag_target(Vector2(100.0, 100.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(80.0, 0.0))
	assert(not world.get("_dash_active"), "a slow release does not start a dash")
	assert(dash_collision.disabled, "a slow release keeps the dash collider disabled")
	assert(rewards.is_empty(), "a release without contact cannot reward")

	weak_point.global_position = leader.global_position + Vector3(0.0, 0.0, -1.5)
	weak_point.linear_velocity = Vector3.ZERO
	weak_point.angular_velocity = Vector3.ZERO
	world.set_drag_target(Vector2(300.0, 300.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(0.0, -2000.0))
	assert(world.get("_dash_active"), "a long high-velocity swipe starts one dash")
	assert(not dash_collision.disabled, "a valid dash enables the leader hitbox")
	for _frame in range(90):
		await physics_frame
		if not rewards.is_empty():
			break
	assert(dash_contacts.size() == 1, "the dash hitbox contacts one real rigid enemy")
	assert(weak_point.linear_velocity.z < -0.1, "contact applies forward impulse to the rigid enemy")
	assert(
		collapse_stages == ["warning", "contact", "crack", "pieces", "collapse", "reward"],
		"authored collapse stages preserve causal order"
	)
	assert(rewards == [1], "one collider-triggered collapse releases one reward")
	assert(not world.trigger_collapse("antenna_a", Vector3.FORWARD), "a repeated trigger is rejected")
	world.call("_on_dash_body_entered", weak_point)
	assert(rewards == [1], "repeated trigger and callback cannot release a second reward")
	world.setup(FlockRunState.new_run(424243))
	world.start_act("brawl")
	assert(
		is_equal_approx(world.get_node("Encounter/BrawlTarget").position.y, 0.9),
		"a reused world restores the authored target position"
	)
	for piece in world.get_node("Encounter/DetachedPieces").get_children():
		assert(not piece.visible and piece.freeze, "a reused world hides and freezes detached pieces")
	assert(world.trigger_collapse("antenna_a", Vector3.FORWARD), "a new Brawl can accept its own collapse")

	world.cancel_gesture()
	world.free()
	print("PASS flock_world_test")
	quit(0)
