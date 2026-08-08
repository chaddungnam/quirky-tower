extends Control

signal play_requested
signal settings_requested

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const UIText = preload("res://scripts/ui/ui_text.gd")
const DisplayFont = preload("res://assets/fonts/DoHyeon-Regular.ttf")

var _locale := "en"
var _pulse := 0.0


func _ready() -> void:
	get_node("Content/Title").add_theme_color_override("font_color", Tokens.color(self, Tokens.PRIMARY))
	get_node("Content/Title").add_theme_font_size_override("font_size", Tokens.TITLE_SIZE)
	get_node("Content/Title").add_theme_font_override("font", DisplayFont)
	get_node("Content/Prototype").add_theme_font_override("font", DisplayFont)
	var tagline := get_node("Content/Tagline") as Label
	tagline.add_theme_color_override("font_color", Tokens.color(self, Tokens.TEXT))
	tagline.add_theme_color_override("font_outline_color", Tokens.color(self, Tokens.BACKGROUND))
	tagline.add_theme_constant_override("outline_size", 8)
	get_node("Content/Prototype").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.SECRET)
	)
	Tokens.style_button(get_node("Content/PlayButton"), Tokens.PRIMARY, Tokens.MAIN_TOUCH_HEIGHT)
	Tokens.style_button(get_node("Content/SettingsButton"), Tokens.SECONDARY)
	get_node("Content/PlayButton").pressed.connect(func() -> void: play_requested.emit())
	get_node("Content/SettingsButton").pressed.connect(func() -> void: settings_requested.emit())


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta, TAU)
	queue_redraw()


func _draw() -> void:
	var background := Tokens.color(self, Tokens.BACKGROUND)
	var surface := Tokens.color(self, Tokens.SURFACE)
	var primary := Tokens.color(self, Tokens.PRIMARY)
	var secret := Tokens.color(self, Tokens.SECRET)
	draw_rect(Rect2(Vector2.ZERO, size), background)
	var sway := sin(_pulse * 0.7) * 26.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.08 + sway, 0.0), Vector2(size.x * 0.42, 0.0),
		Vector2(size.x * 0.62, size.y), Vector2(size.x * 0.28, size.y),
	]), Color(primary, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.92 - sway, 0.0), Vector2(size.x * 0.58, 0.0),
		Vector2(size.x * 0.38, size.y), Vector2(size.x * 0.72, size.y),
	]), Color(secret, 0.10))
	var tower_rect := Rect2(size.x * 0.34, size.y * 0.20, size.x * 0.32, size.y * 0.70)
	draw_style_box(Tokens.panel_style(self, Tokens.SURFACE, 28), tower_rect)
	for floor_index in range(8):
		var y := tower_rect.position.y + 58.0 + floor_index * tower_rect.size.y / 9.0
		draw_rect(
			Rect2(tower_rect.position.x + 32.0, y, tower_rect.size.x - 64.0, 12.0),
			Color(primary, 0.18)
		)
	var antenna_x := size.x * 0.5
	draw_line(
		Vector2(antenna_x, tower_rect.position.y),
		Vector2(antenna_x, tower_rect.position.y - 70.0),
		surface,
		12.0
	)
	draw_circle(
		Vector2(antenna_x, tower_rect.position.y - 82.0),
		18.0 + sin(_pulse * 2.0) * 4.0,
		primary
	)


func set_language(locale: String) -> void:
	_locale = UIText.supported_code(locale)
	get_node("Content/Tagline").text = UIText.text(_locale, "tagline")
	get_node("Content/Prototype").text = UIText.text(_locale, "prototype")
	get_node("Content/PlayButton").text = UIText.text(_locale, "play")
	get_node("Content/SettingsButton").text = UIText.text(_locale, "settings")
