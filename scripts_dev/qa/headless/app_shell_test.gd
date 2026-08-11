extends SceneTree

const MainScene = preload("res://scenes/app/main.tscn")
const RunScreenScene = preload("res://scenes/game/run_screen.tscn")
const Tokens = preload("res://scripts/ui/design_tokens.gd")
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
	assert(app.get_node("RunScreen").has_node("SafeFrame"), "the run declares one centered 720x1280 safe frame")
	var safe_frame := app.get_node("RunScreen/SafeFrame") as Control
	assert(
		safe_frame.anchor_left == 0.5 and safe_frame.anchor_top == 0.5
		and safe_frame.offset_left == -360.0 and safe_frame.offset_top == -640.0
		and safe_frame.offset_right == 360.0 and safe_frame.offset_bottom == 640.0,
		"safe UI is centered independently of the full-height world"
	)
	assert(
		app.get_node("RunScreen").process_mode == Node.PROCESS_MODE_DISABLED,
		"hidden gameplay is frozen behind splash and home"
	)
	assert(app.get_node("RunScreen/ChallengeSlot").get_child_count() == 0, "hidden gameplay is not pre-created")

	app.get_node("SplashScreen").finish_now()
	assert(app.get_node("HomeScreen").visible, "banner completion opens home")
	assert(not app.get_node("SplashScreen").visible, "banner closes after completion")
	var home := app.get_node("HomeScreen") as Control
	assert(
		home.get_node("Content/Title").get_theme_color("font_color")
		== Tokens.color(home, Tokens.PRIMARY),
		"home uses the shared Tower primary role"
	)

	app.get_node("HomeScreen/Content/SettingsButton").pressed.emit()
	assert(app.get_node("SettingsScreen").visible, "settings button opens settings")
	app.get_node("SettingsScreen/Content/Rows/LanguageButton").pressed.emit()
	var overlay = app.get_node("ChoiceOverlay")
	assert(overlay.visible, "language opens the shared choice popup")
	var overlay_card := overlay.get_node("Center/Card") as Control
	assert(overlay_card.offset_transform_enabled, "shared popup uses layout-safe entrance motion")
	assert(overlay_card.offset_transform_scale.x < 1.0, "popup starts with a visible pop-in beat")
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

	app.get_node("SettingsScreen/Content/Rows/LanguageButton").pressed.emit()
	assert(overlay.visible, "language popup can be re-entered")
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	app.call("_input", cancel_event)
	await process_frame
	assert(not overlay.visible, "back closes only the top language popup")
	assert(app.get_node("SettingsScreen").visible, "settings stays open after popup back")
	app.call("_input", cancel_event)
	await process_frame
	assert(app.get_node("HomeScreen").visible, "back from settings returns home")

	app.get_node("HomeScreen/Content/PlayButton").pressed.emit()
	assert(app.get_node("RunScreen").visible, "play opens the existing run")
	assert(
		app.get_node("RunScreen").process_mode == Node.PROCESS_MODE_INHERIT,
		"gameplay resumes only after play is pressed"
	)
	assert(not app.get_node("HomeScreen").visible, "home closes during the run")
	assert(not app.get_node("RunScreen/Background").visible, "the opaque shell background stays hidden over the 3D world")
	await process_frame
	var challenge_slot = app.get_node("RunScreen/ChallengeSlot")
	assert(challenge_slot.get_child_count() == 1, "run restart leaves one active challenge")
	assert(
		challenge_slot.get_child(0).name == "FlockTrial",
		"active gameplay is the integrated flock trial"
	)
	assert(challenge_slot.get_child(0).has_node("FlockWorld3D"), "the native 3D world is visible without a SubViewport")
	assert(challenge_slot.get_child(0).has_node("SafeFrame/MascotGuide"), "the mascot stays inside the safe frame")
	app.free()

	var tall_host := Control.new()
	tall_host.size = Vector2(720.0, 1600.0)
	root.add_child(tall_host)
	var tall_run := RunScreenScene.instantiate() as Control
	tall_host.add_child(tall_run)
	await process_frame
	var tall_safe := tall_run.get_node("SafeFrame") as Control
	assert(tall_safe.position == Vector2(0.0, 160.0), "20:9 centers the safe frame below 160 logical px")
	assert(tall_safe.size == Vector2(720.0, 1280.0), "20:9 keeps safe UI at the 720x1280 authored size")
	tall_host.free()

	print("PASS app_shell_test")
	quit(0)
