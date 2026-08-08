extends Control

signal finished

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const DisplayFont = preload("res://assets/fonts/DoHyeon-Regular.ttf")
const DURATION := 1.5

var _elapsed := 0.0
var _finished := false


func _ready() -> void:
	get_node("Background").color = Tokens.color(self, Tokens.BACKGROUND)
	get_node("Center/Content/Company").add_theme_font_override("font", DisplayFont)
	get_node("Center/Content/Title").add_theme_font_override("font", DisplayFont)
	get_node("Center/Content/Company").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.PRIMARY)
	)
	get_node("Center/Content/Title").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.TEXT)
	)
	get_node("Center/Content/Hint").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.SECONDARY)
	)


func _process(delta: float) -> void:
	_elapsed += delta
	get_node("Center/Content/Progress").value = 100.0 * minf(1.0, _elapsed / DURATION)
	if _elapsed >= DURATION:
		finish_now()


func finish_now() -> void:
	if _finished:
		return
	_finished = true
	set_process(false)
	finished.emit()
