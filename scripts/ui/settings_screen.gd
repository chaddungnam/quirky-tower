extends Control

signal back_requested
signal language_requested

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const UIText = preload("res://scripts/ui/ui_text.gd")

var _locale := "en"
var _values := {"bgm": true, "sfx": true, "vibration": true}


func _ready() -> void:
	get_node("Background").color = Tokens.color(self, Tokens.CREAM)
	get_node("Content/Title").add_theme_font_size_override("font_size", Tokens.TITLE_SIZE)
	get_node("Content/Title").add_theme_color_override("font_color", Tokens.color(self, Tokens.CORAL))
	get_node("Content/Hint").add_theme_color_override("font_color", Tokens.color(self, Tokens.NAVY))
	for key in ["bgm", "sfx", "vibration"]:
		var button := get_node("Content/Rows/%sButton" % key.capitalize()) as Button
		Tokens.style_button(button, Tokens.NAVY)
		button.pressed.connect(_toggle.bind(key))
	Tokens.style_button(get_node("Content/Rows/LanguageButton"), Tokens.TEAL)
	Tokens.style_button(get_node("Content/Rows/BackButton"), Tokens.CORAL)
	get_node("Content/Rows/LanguageButton").pressed.connect(func() -> void: language_requested.emit())
	get_node("Content/Rows/BackButton").pressed.connect(func() -> void: back_requested.emit())


func set_language(locale: String) -> void:
	_locale = UIText.supported_code(locale)
	get_node("Content/Title").text = UIText.text(_locale, "settings")
	get_node("Content/Hint").text = UIText.text(_locale, "settings_hint")
	get_node("Content/Rows/LanguageButton").text = "%s · %s" % [
		UIText.text(_locale, "language"), UIText.language_name(_locale)
	]
	get_node("Content/Rows/BackButton").text = UIText.text(_locale, "back")
	_refresh_toggles()


func _toggle(key: String) -> void:
	_values[key] = not bool(_values[key])
	_refresh_toggles()


func _refresh_toggles() -> void:
	for key in _values:
		var state_key := "on" if bool(_values[key]) else "off"
		get_node("Content/Rows/%sButton" % key.capitalize()).text = "%s · %s" % [
			UIText.text(_locale, key), UIText.text(_locale, state_key)
		]
