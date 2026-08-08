extends SceneTree

const StageScene = preload("res://scenes/game/world/tower_stage_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage = StageScene.instantiate()
	root.add_child(stage)
	await process_frame

	var camera := stage.get_node("Camera") as Camera3D
	assert(
		camera.projection == Camera3D.PROJECTION_ORTHOGONAL,
		"the corridor uses a fixed ortho camera"
	)
	assert(
		absf(camera.rotation.x) > 0.1 and absf(camera.rotation.y) > 0.1,
		"camera is oblique on two axes"
	)

	var floor := stage.get_node("World/Floor") as StaticBody3D
	assert(floor.get_node("Collision").shape != null, "the low-poly floor has a real collider")
	var player := stage.get_node("Player") as CharacterBody3D
	assert(player.get_node("Collision").shape != null, "the pixel player has a real collider")
	var sprite := player.get_node("PixelSprite") as Sprite3D
	assert(sprite.texture != null, "the player is rendered as a 2D pixel surface")
	assert(
		sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
		"pixel art keeps nearest filtering"
	)

	stage.configure({"hazards": 2, "speed_bonus": 0.0, "id": "safe"}, 0.5)
	stage.start_dodge()
	var hazards: Node = stage.get_node("Hazards")
	assert(hazards.get_child_count() == 2, "route hazard count reaches the 3D world")
	for hazard in hazards.get_children():
		assert(hazard is Area3D, "hazards use native Area3D overlap")
		assert(hazard.get_node("Collision").shape != null, "each hazard has a real shape")
	var approaching := hazards.get_child(0) as Area3D
	var initial_z := approaching.position.z
	var initial_scale := approaching.scale.x
	stage.set("_speed", 10.0)
	stage.call("_physics_process", 0.1)
	assert(approaching.position.z > initial_z, "hazards approach through real world depth")
	assert(approaching.scale.x > initial_scale, "approach gives a visible depth telegraph")

	var hits: Array = []
	stage.player_hit.connect(func() -> void: hits.append(true))
	assert(stage.has_signal("hazard_dodged"), "a cleared wall is distinct from a hit")
	var dodges: Array = []
	stage.hazard_dodged.connect(func(_near_miss: bool) -> void: dodges.append(true))
	var first_hazard := hazards.get_child(0) as Area3D
	stage.set_physics_process(false)
	first_hazard.global_position = player.global_position
	await physics_frame
	await physics_frame
	assert(first_hazard.overlaps_body(player), "native physics reports the collider overlap")
	stage.call("_physics_process", 0.0)
	assert(hits.size() == 1, "a real Area3D and CharacterBody3D overlap emits one hit")

	stage.reset_stage()
	stage.configure({"hazards": 2, "speed_bonus": 0.0, "id": "safe"}, 0.5)
	stage.start_dodge()
	var cleared_hazard := stage.get_node("Hazards").get_child(0) as Area3D
	cleared_hazard.position.z = 5.0
	stage.call("_physics_process", 0.0)
	assert(dodges.size() == 1, "passing a wall emits a readable dodge event")
	assert(not cleared_hazard.monitoring, "a passed wall resolves once instead of wrapping")

	stage.free()
	print("PASS tower_stage_3d_test")
	quit(0)
