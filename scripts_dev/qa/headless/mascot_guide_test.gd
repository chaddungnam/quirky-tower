extends SceneTree

const GUIDE_PATH := "res://scenes/ui/components/mascot_guide.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load(GUIDE_PATH) as PackedScene
	assert(scene != null, "the shared Tower host guide exists")
	var guide := scene.instantiate()
	root.add_child(guide)
	assert(guide.has_method("say"), "the host can deliver short contextual lines")
	assert(guide.has_method("react"), "the host reacts to success and failure")
	guide.say("이 문장은 긴 번역에서도 말풍선 안에서 자동으로 줄바꿈되어야 합니다.")
	assert(guide.get_node("Bubble").visible, "speaking reveals the bubble")
	var label := guide.get_node("Bubble/Text") as Label
	assert(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "bubble copy wraps safely")
	guide.free()

	print("PASS mascot_guide_test")
	quit(0)
