extends SceneTree


func _init() -> void:
	for challenge_id in ["timing_ring", "tap_panic", "drag_dodge", "tower_trial"]:
		var path := "res://scenes/game/challenges/%s.tscn" % challenge_id
		var scene = load(path)
		assert(scene != null, "%s loads" % path)
		var challenge = scene.instantiate()
		assert(challenge.has_signal("finished"), "%s emits finished" % challenge_id)
		assert(challenge.has_method("setup"), "%s supports setup" % challenge_id)
		assert(challenge.has_method("begin"), "%s supports begin" % challenge_id)
		challenge.setup(0.5)
		challenge.free()

	print("PASS challenge_scene_test")
	quit(0)
