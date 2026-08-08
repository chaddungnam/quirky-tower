extends SceneTree

const MainScene = preload("res://scenes/app/main.tscn")
const LANGUAGE_CODES := [
	"ko", "en", "de", "ja", "fr", "es", "it", "zh_CN", "zh_TW", "ar",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var app = MainScene.instantiate()
	root.add_child(app)
	assert(app.get_node("SplashScreen").visible, "app starts on the banner")
	assert(not app.get_node("HomeScreen").visible, "home waits for the banner")
	assert(not app.get_node("RunScreen").visible, "the run does not start behind the banner")

	app.get_node("SplashScreen").finish_now()
	assert(app.get_node("HomeScreen").visible, "banner completion opens home")
	assert(not app.get_node("SplashScreen").visible, "banner closes after completion")

	app.get_node("HomeScreen/Content/SettingsButton").pressed.emit()
	assert(app.get_node("SettingsScreen").visible, "settings button opens settings")
	app.get_node("SettingsScreen/Content/Rows/LanguageButton").pressed.emit()
	var overlay = app.get_node("ChoiceOverlay")
	assert(overlay.visible, "language opens the shared choice popup")
	var actions = overlay.get_node("Center/Card/Content/ActionScroll/Actions")
	assert(actions.get_child_count() == 11, "ten languages and one vertical cancel action are shown")
	var language_count := 0
	var german_button: Button
	for button in actions.get_children():
		if button.get_meta("option_id", "") in LANGUAGE_CODES:
			language_count += 1
		if button.get_meta("option_id", "") == "de":
			german_button = button
	assert(language_count == 10, "all supported languages carry stable option identifiers")
	assert(german_button != null, "German choice is present")
	german_button.pressed.emit()
	assert(app.get_node("SettingsScreen/Content/Title").text == "EINSTELLUNGEN", "German applies live")

	app.get_node("SettingsScreen/Content/Rows/BackButton").pressed.emit()
	assert(app.get_node("HomeScreen").visible, "back returns to home")
	app.get_node("HomeScreen/Content/PlayButton").pressed.emit()
	assert(app.get_node("RunScreen").visible, "play opens the existing run")
	assert(not app.get_node("HomeScreen").visible, "home closes during the run")
	await process_frame
	var challenge_slot = app.get_node("RunScreen/ChallengeSlot")
	assert(challenge_slot.get_child_count() == 1, "run restart leaves one active challenge")
	assert(
		challenge_slot.get_child(0).name == "TowerTrial",
		"active challenge keeps its stable scene name"
	)
	app.free()

	print("PASS app_shell_test")
	quit(0)
