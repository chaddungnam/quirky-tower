extends Control

const UIText = preload("res://scripts/ui/ui_text.gd")

var _locale := "en"


func _ready() -> void:
	_locale = UIText.supported_code(TranslationServer.get_locale())
	get_node("SplashScreen").finished.connect(show_home)
	get_node("HomeScreen").play_requested.connect(show_run)
	get_node("HomeScreen").settings_requested.connect(show_settings)
	get_node("SettingsScreen").back_requested.connect(show_home)
	get_node("SettingsScreen").language_requested.connect(_show_language_choices)
	get_node("RunScreen").home_requested.connect(show_home)
	_apply_language()


func restart_run() -> void:
	get_node("RunScreen").restart_run()


func show_home() -> void:
	_show_only(get_node("HomeScreen"))


func show_run() -> void:
	_show_only(get_node("RunScreen"))
	restart_run()


func show_settings() -> void:
	_show_only(get_node("SettingsScreen"))


func select_language(code: String) -> void:
	_locale = UIText.supported_code(code)
	_apply_language()
	get_node("ChoiceOverlay").close()


func _show_language_choices() -> void:
	var options: Array = []
	for code in UIText.LANGUAGE_CODES:
		options.append({"id": code, "label": UIText.language_name(code)})
	var actions := _build_language_actions(options)
	actions.append({
		"id": "cancel",
		"label": UIText.text(_locale, "cancel"),
		"action": get_node("ChoiceOverlay").close,
	})
	get_node("ChoiceOverlay").show_actions(
		UIText.text(_locale, "choose_language"),
		UIText.text(_locale, "choose_one"),
		actions
	)


func _build_language_actions(options: Array) -> Array:
	var actions: Array = []
	for option in options:
		var code := str(option.id)
		actions.append({"id": code, "label": str(option.label), "action": select_language.bind(code)})
	return actions


func _apply_language() -> void:
	get_node("HomeScreen").set_language(_locale)
	get_node("SettingsScreen").set_language(_locale)


func _show_only(screen: Control) -> void:
	for path in ["SplashScreen", "HomeScreen", "SettingsScreen", "RunScreen"]:
		get_node(path).visible = get_node(path) == screen
	get_node("ChoiceOverlay").close()
