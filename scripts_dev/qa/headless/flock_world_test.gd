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
	world.set_drag_target(Vector2(viewport_size.x * 0.78, viewport_size.y * 0.68))
	for _frame in range(4):
		await physics_frame
	assert(leader.global_position.distance_to(start_position) > 0.01, "drag moves the real leader body")

	world.set_physics_process(false)
	var rescue_area := world.get_node("Encounter/Rescue") as Area3D
	rescue_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(rescue_area.overlaps_body(leader), "native physics reports the rescue overlap")
	assert(state.companions.size() == 1, "the rescue overlap adds one companion")
	assert(state.event_ledger.size() == 1, "the rescue overlap records one event")
	rescue_area.global_position += Vector3(0.0, 0.0, 4.0)
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

	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	world.cancel_gesture()
	world.free()
	print("PASS flock_world_test")
	quit(0)
