extends SceneTree

const FlockRunState = preload("res://scripts/core/reboot/flock_run_state.gd")
const FlockWorldScene = preload("res://scenes/game/reboot/flock_trial.tscn")
const RunScreenScene = preload("res://scenes/game/run_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _camera_contains(camera: Camera3D, point: Vector3, viewport_size: Vector2, margin := 24.0) -> bool:
	if camera.is_position_behind(point):
		return false
	var screen_point := camera.unproject_position(point)
	return (
		screen_point.x >= margin
		and screen_point.y >= margin
		and screen_point.x <= viewport_size.x - margin
		and screen_point.y <= viewport_size.y - margin
	)


func _run() -> void:
	var trial := FlockWorldScene.instantiate() as Control
	root.add_child(trial)
	await process_frame
	assert(trial != null and trial.name == "FlockTrial", "the integrated scene has one Control input root")
	var world := trial.get_node("FlockWorld3D") as Node3D

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
	trial.begin(state)
	var staged_brawl_target := world.get_node("Encounter/BrawlTarget") as Node3D
	var staged_weak_point := world.get_node("Encounter/BrawlWeakPoint") as RigidBody3D
	var staged_relay := world.get_node("Encounter/ChainRelayB") as RigidBody3D
	var staged_vent := world.get_node("Encounter/ChainVentC") as RigidBody3D
	assert(route_markers.visible, "Entry exposes only its route lanes")
	assert(not staged_brawl_target.visible and not staged_weak_point.visible, "Entry hides the future Brawl encounter")
	assert(not staged_relay.visible and not staged_vent.visible, "Entry hides future Chain targets")
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
		func(act_id: String, result: Dictionary) -> void:
			if act_id == "entry":
				completed_routes.append(result.route)
	)
	var rescue_area := world.get_node("Encounter/Rescue") as Area3D
	rescue_area.global_position = leader.global_position
	for _frame in range(8):
		await physics_frame
		if state.companions.size() == 2:
			break
	assert(rescue_area.overlaps_body(leader), "native physics reports the rescue overlap")
	assert(state.companions.size() == 2, "the rescue overlap adds the goose and pigeon")
	assert(state.event_ledger.size() == 2, "the rescue overlap records both companions")
	var goose := companion_slots.get_node("CompanionSlot1/Goose") as CharacterBody3D
	var pigeon := companion_slots.get_node("CompanionSlot2/Pigeon") as CharacterBody3D
	assert(goose.visible and pigeon.visible, "the actual rescue exposes both birds during Entry")
	assert(completed_routes.is_empty() and state.act_id == "entry", "the rescue holds a renderable Entry beat before completion")
	await process_frame
	assert(completed_routes.is_empty(), "the rescue beat survives a render frame")
	for _frame in range(60):
		await physics_frame
		if not completed_routes.is_empty():
			break
	assert(completed_routes.size() == 1, "the first route completes Approach once after the rescue beat")
	assert(state.act_id == "brawl", "the rescue beat advances to Brawl only after completion")
	rescue_area.global_position += Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	var score_area := world.get_node("Encounter/Score") as Area3D
	score_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(state.event_ledger.size() == 2, "an adjacent route cannot resolve after the first")
	assert(completed_routes.size() == 1, "an adjacent route cannot complete Approach twice")
	score_area.global_position += Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await physics_frame
	rescue_area.global_position = leader.global_position
	await physics_frame
	await physics_frame
	assert(state.companions.size() == 2, "the same rescue cannot add twice")
	assert(state.event_ledger.size() == 2, "the same route cannot record twice")

	assert(goose.visible, "the rescued goose occupies the first follow slot")
	assert(pigeon.visible, "the rescued pigeon occupies the second follow slot")
	assert(goose.get_node("Head").position.y > leader.get_node("Head").position.y, "the goose silhouette is taller")
	assert(pigeon.has_node("WingBand"), "the smaller pigeon has a readable wing band")
	for bird in [leader, goose, pigeon]:
		var face := bird.get_node("FaceSurface") as Sprite3D
		assert(face.texture.get_size() == Vector2(16, 16), "bird faces use a 16x16 surface")
		assert(face.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "bird faces keep nearest filtering")

	var weak_point := staged_weak_point
	var dash_collision := world.get_node("Actors/Leader/DashHitbox/Collision") as CollisionShape3D
	var brawl_target := staged_brawl_target
	var target_visual := brawl_target.get_child(0) as MeshInstance3D
	var target_material := target_visual.mesh.material as StandardMaterial3D
	var detached_pieces := world.get_node("Encounter/DetachedPieces") as Node3D
	var contact_marker := world.get_node("Effects/ContactMarker") as Node3D
	var rebound_marker := world.get_node("Effects/ReboundMarker") as Node3D
	var contact_material := ((contact_marker.get_child(0) as MeshInstance3D).mesh.material as StandardMaterial3D)
	var rebound_material := ((rebound_marker.get_child(0) as MeshInstance3D).mesh.material as StandardMaterial3D)
	var crack_lines := world.get_node("Effects/CrackLines") as Node3D
	var reward_burst := world.get_node("Effects/RewardBurst") as Node3D
	var reward_label := reward_burst.get_node("Value") as Label3D
	var break_marker := world.get_node("Effects/BreakMarker") as Node3D
	var attack_orb := world.get_node("Effects/AttackOrb") as Area3D
	var attack_orb_visual := attack_orb.get_node("Visual") as MeshInstance3D
	var attack_orb_material := attack_orb_visual.mesh.material as StandardMaterial3D
	var collapse_stages: Array[String] = []
	var stage_records: Array[Dictionary] = []
	var rewards: Array[int] = []
	var dash_contacts: Array[Vector3] = []
	var contact_records: Array[Dictionary] = []
	var rebound_records: Array[Dictionary] = []
	var act_at_reward_stage := [""]
	var brawl_reward_order: Array[String] = []
	var reward_signal_frame := [-1]
	world.collapse_stage.connect(
		func(stage: String) -> void:
			if stage == "reward":
				act_at_reward_stage[0] = str(trial.get_visual_state().act_id)
				brawl_reward_order.append("stage")
			var visible_pieces := 0
			for piece in detached_pieces.get_children():
				if piece.visible:
					visible_pieces += 1
			collapse_stages.append(stage)
			stage_records.append({
				"stage": stage,
				"process_frame": Engine.get_process_frames(),
				"physics_frame": Engine.get_physics_frames(),
				"color": target_material.albedo_color,
				"visible_pieces": visible_pieces,
				"target_y": brawl_target.position.y,
				"reward_count": rewards.size(),
				"crack_visible": crack_lines.visible,
				"crack_segments": crack_lines.get_child_count(),
				"reward_visible": reward_burst.visible,
				"reward_position": reward_burst.global_position,
			})
	)
	world.reward_released.connect(func(value: int) -> void:
		if rewards.is_empty():
			reward_signal_frame[0] = Engine.get_process_frames()
		rewards.append(value)
		brawl_reward_order.append("signal")
	)
	world.impact.connect(
		func(kind: String, world_point: Vector3) -> void:
			if kind == "dash":
				dash_contacts.append(world_point)
				contact_records.append({
					"frame": Engine.get_process_frames(),
					"leader_position": leader.global_position,
					"visible": contact_marker.visible,
					"position": contact_marker.global_position,
					"on_camera": _camera_contains(camera, contact_marker.global_position, viewport_size),
					"color": contact_material.albedo_color,
				})
			elif kind == "rebound":
				rebound_records.append({
					"frame": Engine.get_process_frames(),
					"leader_position": leader.global_position,
					"visible": rebound_marker.visible,
					"position": rebound_marker.global_position,
					"on_camera": _camera_contains(camera, rebound_marker.global_position, viewport_size),
					"color": rebound_material.albedo_color,
				})
	)
	world.start_act("brawl")
	assert(not route_markers.visible, "Brawl hides the Entry lanes")
	assert(brawl_target.visible and weak_point.visible, "Brawl exposes its target and weak point")
	assert(not staged_relay.visible and not staged_vent.visible, "Brawl hides non-Brawl Chain targets")
	assert(collapse_stages == ["warning"], "Brawl warns before any contact feedback")
	assert(stage_records[0].color == Color(0.98, 0.67, 0.16), "warning exposes the warning color")
	assert(stage_records[0].visible_pieces == 0, "warning keeps debris hidden")
	assert(stage_records[0].reward_count == 0, "warning cannot reward")

	world.set_drag_target(Vector2(100.0, 100.0))
	world.release_swipe(Vector2(150.0, 100.0), Vector2(2000.0, 0.0))
	await process_frame
	assert(not world.get("_dash_active"), "a high-velocity swipe below minimum distance does not dash")
	assert(dash_collision.disabled, "a short high-velocity release keeps the deferred hitbox disabled")
	world.set_drag_target(Vector2(100.0, 100.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(80.0, 0.0))
	await process_frame
	assert(not world.get("_dash_active"), "a slow release does not start a dash")
	assert(dash_collision.disabled, "a slow release keeps the dash collider disabled")
	assert(rewards.is_empty(), "a release without contact cannot reward")

	weak_point.global_position = leader.global_position + Vector3(0.0, 0.0, -10.0)
	world.set_drag_target(Vector2(300.0, 300.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(0.0, -2000.0))
	assert(dash_collision.disabled, "dash hitbox enable is deferred until a frame boundary")
	await process_frame
	assert(not dash_collision.disabled, "a valid dash enables its hitbox after deferred processing")
	world.cancel_gesture()
	assert(not dash_collision.disabled, "dash hitbox disable is deferred until a frame boundary")
	await process_frame
	assert(dash_collision.disabled, "gesture cancellation disables the hitbox after deferred processing")

	weak_point.global_position = leader.global_position + Vector3(0.0, 0.0, -1.8)
	weak_point.linear_velocity = Vector3.ZERO
	weak_point.angular_velocity = Vector3.ZERO
	world.set_drag_target(Vector2(300.0, 300.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(0.0, -2000.0))
	assert(world.get("_dash_active"), "a long high-velocity swipe starts one dash")
	assert(dash_collision.disabled, "the real-contact dash also waits for deferred hitbox enable")
	await process_frame
	assert(not dash_collision.disabled, "the real-contact dash enables the leader hitbox")
	var weak_impulse_seen := false
	var post_contact_input_sent := false
	for _frame in range(120):
		await physics_frame
		weak_impulse_seen = weak_impulse_seen or weak_point.linear_velocity.z < -0.1
		if not dash_contacts.is_empty() and not post_contact_input_sent:
			post_contact_input_sent = true
			world.set_drag_target(Vector2(320.0, 320.0))
			world.release_swipe(Vector2(320.0, 320.0), Vector2.ZERO)
		if not rewards.is_empty():
			break
	assert(post_contact_input_sent, "the regression releases input after real contact")
	assert(dash_contacts.size() == 1, "the dash hitbox contacts one real rigid enemy")
	assert(contact_records.size() == 1, "real collider contact exposes one contact beat")
	assert(contact_records[0].visible and contact_records[0].on_camera, "the contact marker is visible on camera")
	var contact_offset: Vector3 = contact_records[0].position - dash_contacts[0]
	assert(contact_offset.y >= 0.6 and contact_offset.z >= 0.35, "the contact glyph clears the collider above and toward camera")
	assert(contact_offset.length() < 1.2, "the contact glyph stays attached to the real collision surface")
	assert(
		camera.unproject_position(contact_records[0].position).distance_to(camera.unproject_position(dash_contacts[0])) >= 32.0,
		"the contact glyph is visibly separated from the target on screen"
	)
	assert(rebound_records.size() == 1, "contact advances to one distinct rebound beat")
	assert(rebound_records[0].visible and rebound_records[0].on_camera, "the rebound marker is visible on camera")
	assert(rebound_records[0].frame > contact_records[0].frame, "rebound advances to a later render frame")
	assert(contact_records[0].color != rebound_records[0].color, "contact and rebound use distinct high-contrast materials")
	var rebound_marker_offset: Vector3 = rebound_records[0].position - rebound_records[0].leader_position
	assert(rebound_marker_offset.y >= 0.6 and rebound_marker_offset.z >= 0.35, "the rebound glyph clears the leader silhouette")
	var leader_rebound_distance := (rebound_records[0].leader_position as Vector3).distance_to(contact_records[0].leader_position)
	assert(
		leader_rebound_distance > 0.25 and leader_rebound_distance <= 0.8,
		"visual feedback preserves the authored leader rebound range"
	)
	assert(rebound_marker_offset.z >= 1.0, "the marker, not the gameplay body, exaggerates the opposite-direction rebound")
	assert(
		camera.unproject_position(rebound_records[0].position).distance_to(camera.unproject_position(contact_records[0].position)) >= 48.0,
		"contact and rebound markers occupy unmistakably distinct screen positions"
	)
	assert(weak_impulse_seen, "contact applies forward impulse to the rigid enemy")
	assert(
		collapse_stages == ["warning", "contact", "crack", "pieces", "collapse", "reward"],
		"authored collapse stages preserve causal order"
	)
	for index in range(1, stage_records.size()):
		assert(
			stage_records[index].process_frame > stage_records[index - 1].process_frame,
			"each post-contact stage advances to a later process frame"
		)
		assert(
			stage_records[index].physics_frame > stage_records[index - 1].physics_frame,
			"each post-contact stage advances to a later physics frame"
		)
	assert(stage_records[1].color == Color(1.0, 0.93, 0.72), "contact exposes the flash color")
	assert(stage_records[1].visible_pieces == 0, "contact keeps debris hidden")
	assert(stage_records[2].color == Color(0.27, 0.29, 0.34), "crack exposes the cracked color")
	assert(stage_records[2].crack_visible and stage_records[2].crack_segments >= 2, "crack exposes real seam geometry")
	assert(_camera_contains(camera, crack_lines.global_position, viewport_size), "crack seams remain on camera")
	assert(stage_records[3].visible_pieces == 3, "pieces stage exposes all authored debris")
	assert(stage_records[4].target_y < 0.0, "collapse stage exposes the lowered target")
	for index in range(5):
		assert(stage_records[index].reward_count == 0, "reward is absent before the reward stage")
	assert(stage_records[5].reward_count == 0, "the visible reward stage precedes reward delivery")
	assert(stage_records[5].reward_visible and reward_label.text == "+100", "reward exposes a readable +100 burst")
	assert(_camera_contains(camera, stage_records[5].reward_position, viewport_size), "reward burst stays on camera")
	assert(reward_signal_frame[0] > stage_records[5].process_frame, "reward delivery waits through a visible render beat")
	assert(brawl_reward_order == ["stage", "signal"], "the reward stage emits before reward delivery")
	assert(act_at_reward_stage[0] == "brawl", "the visible reward stage still belongs to Brawl")
	assert(state.act_id == "chain", "the reward signal advances to Chain after the reward stage")
	assert(rewards == [1], "one collider-triggered collapse releases one reward")
	assert(not contact_marker.visible and not rebound_marker.visible, "contact feedback clears after its authored beats")
	assert(not crack_lines.visible and not reward_burst.visible, "act transition clears crack and reward feedback")
	assert(not world.trigger_collapse("antenna_a", Vector3.FORWARD), "a repeated trigger is rejected")
	world.call("_on_dash_body_entered", weak_point)
	assert(rewards == [1], "repeated trigger and callback cannot release a second reward")

	var chain_ids: Array[String] = ["antenna_a", "relay_b", "vent_c"]
	var chain_targets: Dictionary = world.get("_chain_targets")
	var chain_completions: Array[Dictionary] = []
	var chain_signal_order: Array[String] = []
	var chain_flash_ids: Array[String] = []
	var chain_capture := {"active": false}
	world.act_completed.connect(
		func(act_id: String, result: Dictionary) -> void:
			if act_id == "chain":
				chain_completions.append(result)
				if chain_capture.active:
					chain_signal_order.append("complete")
	)
	world.reward_released.connect(
		func(_value: int) -> void:
			if chain_capture.active:
				chain_signal_order.append("reward")
	)
	world.impact.connect(
		func(kind: String, _world_point: Vector3) -> void:
			if kind != "chain_strike":
				return
			var target_id := str(world.get("_chain_expected_target_id"))
			var target := chain_targets[target_id] as RigidBody3D
			var visual := target.get_node("Visual") as MeshInstance3D
			var material := visual.mesh.material as StandardMaterial3D
			if material.albedo_color == Color(1.0, 0.95, 0.5):
				chain_flash_ids.append(target_id)
	)
	world.start_act("chain")
	var chain_path := world.get_node("Effects/ChainPath") as MeshInstance3D
	var chain_mesh := chain_path.mesh as ImmediateMesh
	var ledger_before_chain := state.event_ledger.size()
	assert(not route_markers.visible, "Chain keeps Entry lanes hidden")
	assert(weak_point.visible and staged_relay.visible and staged_vent.visible, "Chain exposes all three raid targets")
	for actor in [leader, goose, pigeon, weak_point, staged_relay, staged_vent]:
		assert(_camera_contains(camera, actor.global_position, viewport_size, 36.0), "Chain staging keeps actors and endpoints camera-safe")

	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	assert(world.get("_chain_status") == "broken", "a zero-target release reports broken")
	assert(chain_mesh.get_surface_count() == 1, "a zero-target broken path keeps one visible surface")
	var zero_vertices: PackedVector3Array = chain_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(zero_vertices.size() >= 6, "a zero-target broken path renders a thick visible marker")
	var zero_midpoint := (zero_vertices[0] + zero_vertices[1]) * 0.5
	assert(zero_midpoint.distance_to(leader.global_position) < 0.5, "the zero-target marker appears near the leader")
	assert(break_marker.visible and break_marker.get_child_count() >= 2, "zero-target release exposes a red break glyph")
	assert(_camera_contains(camera, break_marker.global_position, viewport_size), "the zero-target break glyph is on camera")
	assert(
		(chain_mesh.surface_get_material(0) as StandardMaterial3D).albedo_color == Color(1.0, 0.16, 0.2),
		"the zero-target broken marker is high-contrast red"
	)
	assert(state.event_ledger.size() == ledger_before_chain, "a zero-target release writes no ledger")
	world.cancel_gesture()
	assert(chain_mesh.get_surface_count() == 0 and not break_marker.visible, "cancel clears broken path feedback")

	var antenna := chain_targets.antenna_a as RigidBody3D
	var relay := chain_targets.relay_b as RigidBody3D
	var vent := chain_targets.vent_c as RigidBody3D
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		target.gravity_scale = 0.0
		target.linear_velocity = Vector3.ZERO
		target.angular_velocity = Vector3.ZERO
		target.freeze = false
		target.sleeping = true
	var antenna_screen := camera.unproject_position(antenna.global_position)
	world.set_drag_target(antenna_screen)
	world.set_drag_target(antenna_screen)
	assert(world.get("_chain_target_ids") == ["antenna_a"], "chain selection ignores duplicate IDs")
	world.release_swipe(antenna_screen, Vector2.ZERO)
	assert(world.get("_chain_status") == "broken", "one target reports broken without consuming the attack")
	assert(world.get("_chain_target_ids") == ["antenna_a"], "one-target broken path stays selected")
	assert(break_marker.visible and break_marker.global_position.distance_to(antenna.global_position) < 0.6, "broken glyph marks the last valid target")
	world.set_drag_target(camera.unproject_position(relay.global_position))
	world.set_drag_target(camera.unproject_position(vent.global_position))
	assert(world.get("_chain_target_ids") == chain_ids, "chain target IDs preserve first-seen order")
	var drawn_vertices: PackedVector3Array = chain_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(drawn_vertices.size() >= 12, "three targets create two thick ribbon segments")
	assert(drawn_vertices[0].distance_to(drawn_vertices[1]) >= 0.16, "the chain ribbon has visible world-space width")

	var vent_collision := vent.get_node("Collision") as CollisionShape3D
	vent_collision.set_deferred("disabled", true)
	await process_frame
	var before_miss: Dictionary = {}
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		before_miss[target_id] = {"transform": target.transform, "freeze": target.freeze}
	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	assert(chain_mesh.get_surface_count() == 1, "the released path remains visible during the real attack")
	for _frame in range(240):
		await physics_frame
		if not world.get("_chain_attack_active"):
			break
	assert(chain_completions.is_empty(), "a missed selected target cannot complete Chain")
	assert(rewards == [1], "a missed selected target cannot release the Chain reward")
	assert(state.event_ledger.size() == ledger_before_chain, "a missed chain writes no discrete ledger")
	assert(world.get("_chain_status") == "broken", "a missed target returns the chain to broken")
	assert(break_marker.visible and _camera_contains(camera, break_marker.global_position, viewport_size), "a miss marks its on-camera break point")
	assert(not world.get("_chain_attack_consumed"), "a missed target refunds the chain attack")
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		var expected: Dictionary = before_miss[target_id]
		assert(target.transform.is_equal_approx(expected.transform), "a missed chain preserves every target transform")
		assert(target.freeze == expected.freeze, "a missed chain preserves every target freeze state")
	vent_collision.set_deferred("disabled", false)
	await process_frame
	world.cancel_gesture()
	assert(not break_marker.visible and chain_mesh.get_surface_count() == 0, "cancel resets miss feedback")

	world.set_drag_target(camera.unproject_position(antenna.global_position))
	world.set_drag_target(camera.unproject_position(relay.global_position))
	var antenna_visual := antenna.get_node("Visual") as MeshInstance3D
	var antenna_material := antenna_visual.mesh.material as StandardMaterial3D
	var antenna_base_color: Color = antenna.get_meta("chain_color")
	var before_cancel: Dictionary = {}
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		before_cancel[target_id] = {"transform": target.transform, "freeze": target.freeze}
	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	var canceled_after_overlap := false
	for _frame in range(240):
		await physics_frame
		if world.get("_chain_struck_targets").has("antenna_a"):
			canceled_after_overlap = true
			assert(antenna_material.albedo_color == Color(1.0, 0.95, 0.5), "the first real strike begins bright")
			world.cancel_gesture()
			assert(antenna_material.albedo_color == antenna_base_color, "cancel restores the active flash in the same frame")
			break
	assert(canceled_after_overlap, "cancel regression reaches the first selected target through real overlap")
	await process_frame
	assert(antenna_material.albedo_color == antenna_base_color, "cancel keeps the active flash restored next frame")
	assert(chain_completions.is_empty(), "cancel prevents a late Chain completion")
	assert(rewards == [1], "cancel releases no Chain reward")
	assert(state.event_ledger.size() == ledger_before_chain, "cancel writes no discrete chain ledger")
	assert(not world.get("_chain_attack_consumed"), "cancel refunds an unfinished chain attack")
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		var expected: Dictionary = before_cancel[target_id]
		assert(target.transform.is_equal_approx(expected.transform), "a canceled chain preserves every target transform")
		assert(target.freeze == expected.freeze, "a canceled chain preserves every target freeze state")

	await create_timer(0.12).timeout
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		world.set_drag_target(camera.unproject_position(target.global_position))
	assert(world.get("_chain_target_ids") == chain_ids, "fresh selection succeeds after cancellation")
	assert(world.has_node("Effects/AttackOrb"), "the world owns one attack orb")
	var orb_collision := attack_orb.get_node("Collision") as CollisionShape3D
	assert(attack_orb.get_child_count() == 2 and orb_collision.shape != null, "the single attack orb has a real collider")
	var success_overlap_ids: Array[String] = []
	var chain_strike_visuals: Array[Dictionary] = []
	attack_orb.body_entered.connect(
		func(body: Node3D) -> void:
			if chain_capture.active and body.has_meta("target_id"):
				success_overlap_ids.append(str(body.get_meta("target_id")))
	)
	chain_flash_ids.clear()
	chain_capture.active = true
	var goose_before_chain := goose.global_position
	world.impact.connect(
		func(kind: String, world_point: Vector3) -> void:
			if kind == "chain_strike" and chain_capture.active:
				var visual_position := attack_orb_visual.global_position
				chain_strike_visuals.append({
					"visible": attack_orb.visible and attack_orb_visual.visible,
					"root_at_overlap": attack_orb.global_position.distance_to(world_point) < 0.05,
					"visual_offset": visual_position - world_point,
					"screen_gap": camera.unproject_position(visual_position).distance_to(camera.unproject_position(world_point)),
					"on_camera": _camera_contains(camera, visual_position, viewport_size),
					"emissive": attack_orb_material.emission_enabled,
				})
	)
	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	assert(chain_mesh.get_surface_count() == 1, "the successful released path remains visible while striking")
	for _frame in range(30):
		await physics_frame
		if world.get("_chain_struck_targets").has("antenna_a"):
			break
	assert(antenna_material.albedo_color == Color(1.0, 0.95, 0.5), "a fresh retry starts its own bright flash")
	for _frame in range(3):
		await process_frame
	assert(antenna_material.albedo_color == Color(1.0, 0.95, 0.5), "the canceled attempt cannot overwrite the fresh flash")
	for _frame in range(240):
		await physics_frame
		if not chain_completions.is_empty():
			break
	chain_capture.active = false
	assert(chain_completions == [{"status": "released", "target_ids": chain_ids}], "actual Brawl order completes Chain once")
	assert(success_overlap_ids == chain_ids, "one real physics overlap strikes every unique target in order")
	assert(chain_flash_ids == chain_ids, "every real chain strike exposes the authored flash")
	assert(chain_strike_visuals.size() == chain_ids.size(), "every overlap exposes one visible strike beat")
	for strike in chain_strike_visuals:
		assert(strike.visible and strike.root_at_overlap and strike.on_camera, "AttackOrb collider stays at each real overlap while its visual remains visible")
		assert(strike.visual_offset.y >= 0.55 and strike.visual_offset.z >= 0.3, "AttackOrb visual clears the struck sphere toward camera")
		assert(strike.screen_gap >= 28.0 and strike.emissive, "each strike exposes a separated emissive marker on screen")
	for target_id in chain_ids:
		var target := chain_targets[target_id] as RigidBody3D
		assert(target.global_position.y < 0.3 and target.freeze, "every struck target visibly lowers and freezes")
	assert(chain_signal_order == ["reward", "complete"], "Chain reward emits before act completion")
	assert(rewards == [1, 1], "Brawl and Chain each release one distinct reward")
	assert(goose.global_position.distance_to(goose_before_chain) > 0.1, "the visible companion trails the released chain")
	assert(collapse_stages == ["warning", "contact", "crack", "pieces", "collapse", "reward"], "Chain does not replay Brawl-only pieces")
	for piece in detached_pieces.get_children():
		assert(piece.visible, "the antenna keeps its authored Brawl pieces visible")
	var chain_events: Array = state.event_ledger.slice(ledger_before_chain)
	assert(chain_events.size() == 4, "only successful Chain records target IDs and strikes")
	assert(chain_events[0] == {"kind": "chain_targets", "payload": {"target_ids": chain_ids}}, "Chain stores ordered IDs once")
	for index in range(chain_ids.size()):
		assert(chain_events[index + 1] == {"kind": "chain_strike", "payload": {"target_id": chain_ids[index]}}, "each strike stores one ID only")
	assert(chain_mesh.get_surface_count() == 0 and world.get("_chain_target_ids").is_empty(), "successful Chain consumes and clears its path")
	var ledger_after_chain := state.event_ledger.duplicate(true)
	world.release_swipe(Vector2.ZERO, Vector2.ZERO)
	await physics_frame
	assert(state.event_ledger == ledger_after_chain and rewards == [1, 1], "consumed Chain cannot record or reward twice")
	assert(chain_completions.size() == 1, "consumed Chain cannot complete twice")

	for index in range(detached_pieces.get_child_count()):
		var piece := detached_pieces.get_child(index) as RigidBody3D
		piece.freeze = false
		piece.position = Vector3(4.0 + index, 5.0, -3.0)
		piece.rotation = Vector3(0.2 + index, 0.4, 0.6)
		piece.linear_velocity = Vector3.ONE * 3.0
		piece.angular_velocity = Vector3.ONE * 2.0
	weak_point.rotation = Vector3(0.4, 0.5, 0.6)
	weak_point.linear_velocity = Vector3.ONE * 4.0
	weak_point.angular_velocity = Vector3.ONE * 3.0
	var canceled_state := FlockRunState.new_run(424243)
	trial.begin(canceled_state)
	world.start_act("brawl")
	assert(not contact_marker.visible and not rebound_marker.visible, "setup clears transient collision feedback")
	assert(not crack_lines.visible and not reward_burst.visible and not break_marker.visible, "setup clears collapse and chain feedback")
	assert(chain_mesh.get_surface_count() == 0 and not attack_orb.visible, "setup clears path and strike feedback")
	assert(not weak_point.freeze, "only the intended weak point is reactivated for Brawl")
	assert(weak_point.rotation.is_zero_approx(), "a reused weak point restores zero rotation")
	assert(weak_point.linear_velocity.is_zero_approx(), "a reused weak point clears linear velocity")
	assert(weak_point.angular_velocity.is_zero_approx(), "a reused weak point clears angular velocity")
	await physics_frame
	assert(
		is_equal_approx(brawl_target.position.y, 0.9),
		"a reused world restores the authored target position"
	)
	for index in range(detached_pieces.get_child_count()):
		var piece := detached_pieces.get_child(index) as RigidBody3D
		var authored_position := Vector3((index - 1) * 0.7, 1.45 + index * 0.25, 0.0)
		assert(not piece.visible and piece.freeze, "a reused world hides and freezes detached pieces")
		assert(piece.position.is_equal_approx(authored_position), "a reused piece restores authored position")
		assert(piece.rotation.is_zero_approx(), "a reused piece restores zero rotation")
		assert(piece.linear_velocity.is_zero_approx(), "a reused piece clears linear velocity")
		assert(piece.angular_velocity.is_zero_approx(), "a reused piece clears angular velocity")
	var canceled_stage_count := collapse_stages.size()
	var canceled_reward_count := rewards.size()
	weak_point.global_position = leader.global_position + Vector3(0.0, 0.0, -1.8)
	weak_point.linear_velocity = Vector3.ZERO
	weak_point.angular_velocity = Vector3.ZERO
	world.set_drag_target(Vector2(300.0, 300.0))
	world.release_swipe(Vector2(300.0, 100.0), Vector2(0.0, -2000.0))
	for _frame in range(90):
		await physics_frame
		if collapse_stages.size() > canceled_stage_count:
			break
	assert(collapse_stages[-1] == "contact", "external cancel regression begins through a real collider contact")
	var target_transform_at_cancel := brawl_target.transform
	world.cancel_gesture()
	for _frame in range(50):
		await physics_frame
	assert(collapse_stages.size() == canceled_stage_count + 1, "external cancel stops every later collapse stage")
	assert(brawl_target.transform.is_equal_approx(target_transform_at_cancel), "external cancel prevents delayed target lowering")
	for piece in detached_pieces.get_children():
		assert(not piece.visible and piece.freeze, "external cancel prevents delayed debris release")
	assert(rewards.size() == canceled_reward_count and canceled_state.act_id == "brawl", "external cancel prevents reward and transition")
	assert(not contact_marker.visible and not rebound_marker.visible, "external cancel hides contact and rebound feedback")
	assert(not crack_lines.visible and not reward_burst.visible, "external cancel keeps delayed collapse feedback reset")

	world.cancel_gesture()
	trial.free()

	var run_screen := RunScreenScene.instantiate() as Control
	root.add_child(run_screen)
	await process_frame
	assert(run_screen.get_node("ChallengeSlot").get_child_count() == 0, "hidden gameplay is not pre-created")
	run_screen.set_language("ko")
	run_screen.restart_run(424242)
	await process_frame
	var integrated_trials := run_screen.get_node("ChallengeSlot").get_children()
	assert(integrated_trials.size() == 1, "restart creates exactly one integrated trial")
	var integrated_trial := integrated_trials[0] as Control
	assert(integrated_trial.name == "FlockTrial", "the old TowerTrial is not integrated")
	var integrated_world := integrated_trial.get_node("FlockWorld3D") as Node3D
	var visual: Dictionary = integrated_trial.get_visual_state()
	var integrated_state: FlockRunState = visual.run_state
	assert(integrated_state.seed == 424242 and visual.act_id == "entry", "the seeded run begins in Approach")
	assert(integrated_state.rescue("goose_greta", "goose"))
	assert(integrated_state.rescue("pigeon_pip", "pigeon"))
	integrated_world.setup(integrated_state)

	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = Vector2(240.0, 920.0)
	touch.pressed = true
	integrated_trial.call("_gui_input", touch)
	assert(integrated_trial.get_visual_state().pointer_active, "the first touch owns gameplay input")
	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 5
	second_touch.position = Vector2(300.0, 900.0)
	second_touch.pressed = true
	integrated_trial.call("_gui_input", second_touch)
	assert(integrated_trial.get_visual_state().pointer_id == 4, "a second pointer is ignored")
	integrated_world.act_completed.emit("entry", {"route": "rescue"})
	visual = integrated_trial.get_visual_state()
	assert(visual.act_id == "brawl" and not visual.pointer_active, "the act transition cancels the owned pointer")
	assert(visual.run_state == integrated_state and integrated_state.companions.size() == 2, "the same flock state persists into Brawl")
	assert("날려" in str(visual.mascot_line), "the mascot changes to the Brawl action line")
	assert(run_screen.get_node("SafeFrame/RunHud").get_node("Margin/Rows/ActRow/Act").text.contains("난투"), "the HUD changes to Brawl")

	touch.index = 7
	integrated_trial.call("_gui_input", touch)
	integrated_trial.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not integrated_trial.get_visual_state().pointer_active, "focus loss cancels the gesture")
	integrated_world.reward_released.emit(1)
	visual = integrated_trial.get_visual_state()
	assert(visual.act_id == "chain" and visual.run_state == integrated_state, "the Brawl reward advances the same state to Chain")
	assert(integrated_state.score > 0 and integrated_state.combo == 1, "the Brawl reward updates score and combo")
	assert("손을 떼" in str(visual.mascot_line), "the mascot changes to the Chain action line")
	var score_before_chain_reward := integrated_state.score
	integrated_world.reward_released.emit(1)
	assert(integrated_state.act_id == "chain" and not run_screen.get_node("SafeFrame/GameOverlay").visible, "the shared Chain reward cannot finish the district")
	assert(integrated_state.score == score_before_chain_reward + 100 and integrated_state.combo == 2, "the Chain reward updates score and combo once")
	run_screen.set_language("en")
	integrated_world.act_completed.emit("chain", {"status": "released"})
	assert(integrated_state.act_id == "choice", "Chain completion, not its shared reward, opens the choice")
	var overlay := run_screen.get_node("SafeFrame/GameOverlay") as Control
	assert(overlay.visible, "district completion opens the reused overlay")
	assert(integrated_trial.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the choice disables full-height gameplay input")
	var blocked_touch := InputEventScreenTouch.new()
	blocked_touch.index = 9
	blocked_touch.position = Vector2(80.0, 40.0)
	blocked_touch.pressed = true
	run_screen.get_viewport().push_input(blocked_touch)
	await process_frame
	assert(not integrated_trial.get_visual_state().pointer_active, "real viewport input cannot acquire gameplay during the choice")
	var actions := overlay.get_node("Center/Card/Content/ActionScroll/Actions") as VBoxContainer
	assert(actions.get_child_count() == 3, "the seeded offer has three actions")
	for action in actions.get_children():
		assert((action as Button).custom_minimum_size.y >= 96.0, "choices are vertical mobile touch targets")
	var first_choice := actions.get_child(0) as Button
	var build_before := integrated_state.build.duplicate()
	var build_events_before := integrated_state.event_ledger.filter(func(event): return event.kind == "build_choice").size()
	first_choice.pressed.emit()
	first_choice.pressed.emit()
	var build_delta := 0
	for choice_id in integrated_state.build:
		build_delta += int(integrated_state.build[choice_id]) - int(build_before[choice_id])
	assert(build_delta == 1, "repeated presses mutate the build exactly once")
	assert(integrated_state.event_ledger.filter(func(event): return event.kind == "build_choice").size() == build_events_before + 1, "repeated presses record one build event")
	assert(integrated_state.act_id == "complete", "one choice completes the Gate A run")
	assert(actions.get_child_count() == 2, "the result replaces choices with two actions")
	assert((actions.get_child(0) as Button).text == "PLAY AGAIN" and (actions.get_child(1) as Button).text == "HOME", "result actions stay stacked")
	assert(overlay.get_node("Center/Card/Content/Body").text.contains(first_choice.text), "the result names the selected build")

	var retired_trial := integrated_trial
	run_screen.restart_run(424243)
	await process_frame
	await process_frame
	assert(run_screen.get_node("ChallengeSlot").get_child_count() == 1, "restart leaves exactly one trial")
	assert(not is_instance_valid(retired_trial), "restart frees the old trial and its signals")
	var restarted_trial := run_screen.get_node("ChallengeSlot").get_child(0) as Control
	assert(restarted_trial.mouse_filter == Control.MOUSE_FILTER_STOP, "a new trial restores gameplay input")
	var restarted_world := restarted_trial.get_node("FlockWorld3D") as Node3D
	restarted_world.act_completed.emit("entry", {})
	restarted_world.reward_released.emit(1)
	restarted_world.act_completed.emit("chain", {})
	var restarted_actions := overlay.get_node("Center/Card/Content/ActionScroll/Actions") as VBoxContainer
	(restarted_actions.get_child(0) as Button).pressed.emit()
	var home_actions := overlay.get_node("Center/Card/Content/ActionScroll/Actions") as VBoxContainer
	var home_touch := InputEventScreenTouch.new()
	home_touch.index = 2
	home_touch.position = Vector2(200.0, 800.0)
	home_touch.pressed = true
	restarted_trial.call("_gui_input", home_touch)
	var home_count := [0]
	run_screen.home_requested.connect(func() -> void: home_count[0] += 1)
	(home_actions.get_child(1) as Button).pressed.emit()
	await process_frame
	assert(home_count[0] == 1, "Home requests one navigation")
	assert(run_screen.get_node("ChallengeSlot").get_child_count() == 0, "Home retires the active trial")
	assert(not is_instance_valid(restarted_trial), "Home frees the old world and its signals")
	run_screen.restart_run(424244)
	await process_frame
	assert(run_screen.get_node("ChallengeSlot").get_child_count() == 1, "the next Play still creates exactly one trial")
	run_screen.free()
	print("PASS flock_world_test")
	quit(0)
