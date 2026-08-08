extends RefCounted

const THEME_TYPE := "Quirky"
const CREAM := "cream"
const NAVY := "navy"
const CORAL := "coral"
const TEAL := "teal"
const GOLD := "gold"
const RED := "red"
const ORANGE := "orange"
const SPACE := 16
const RADIUS := 20
const TOUCH_HEIGHT := 96
const MAIN_TOUCH_HEIGHT := 112
const TITLE_SIZE := 52
const HEADER_SIZE := 38
const BODY_SIZE := 26
const BUTTON_SIZE := 28
const MICRO_SIZE := 20


static func color(control: Control, role: String) -> Color:
	return control.get_theme_color(role, THEME_TYPE)


static func panel_style(control: Control, role: String, radius := RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color(control, role)
	style.set_corner_radius_all(radius)
	style.content_margin_left = SPACE
	style.content_margin_top = SPACE
	style.content_margin_right = SPACE
	style.content_margin_bottom = SPACE
	return style


static func style_button(button: Button, role: String, height := TOUCH_HEIGHT) -> void:
	button.custom_minimum_size.y = height
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", BUTTON_SIZE)
	button.add_theme_color_override("font_color", color(button, CREAM))
	button.add_theme_color_override("font_hover_color", color(button, CREAM))
	button.add_theme_color_override("font_pressed_color", color(button, CREAM))
	button.add_theme_stylebox_override("normal", panel_style(button, role))
	button.add_theme_stylebox_override("hover", panel_style(button, role))
	button.add_theme_stylebox_override("pressed", panel_style(button, NAVY))
