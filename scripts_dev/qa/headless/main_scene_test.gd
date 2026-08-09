extends SceneTree


func _init() -> void:
	var errors: PackedStringArray = []
	if ProjectSettings.get_setting("application/run/main_scene", "") != "res://scenes/app/main.tscn":
		errors.append("main scene must be res://scenes/app/main.tscn")
	if int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) != 720:
		errors.append("viewport width must be 720")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) != 1280:
		errors.append("viewport height must be 1280")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)) != 1080:
		errors.append("desktop play width must be 1080")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)) != 2400:
		errors.append("desktop play height must be 2400")
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return

	print("PASS main_scene_test")
	quit(0)
