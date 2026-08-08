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
const TOUCH_HEIGHT := 72


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
