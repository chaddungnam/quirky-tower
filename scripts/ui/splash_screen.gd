extends Control

signal finished

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const DURATION := 1.5

var _elapsed := 0.0
var _finished := false


func _ready() -> void:
	get_node("Background").color = Tokens.color(self, Tokens.NAVY)
	get_node("Center/Content/Company").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.GOLD)
	)
	get_node("Center/Content/Title").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.CREAM)
	)
	get_node("Center/Content/Hint").add_theme_color_override(
		"font_color", Tokens.color(self, Tokens.TEAL)
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
