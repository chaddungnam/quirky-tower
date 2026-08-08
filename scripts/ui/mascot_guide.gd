extends Control

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const BOB_HEIGHT := 4.0
const BOB_SPEED := 2.4

var _time := 0.0
var _blink_left := 0.0
var _next_blink := 2.2
var _reaction := "idle"
var _reaction_scale := Vector2.ONE

@onready var _bubble: PanelContainer = $Bubble
@onready var _text: Label = $Bubble/Text


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bubble_style := Tokens.panel_style(self, Tokens.TEXT, 22)
	bubble_style.set_border_width_all(4)
	bubble_style.border_color = Tokens.color(self, Tokens.PRIMARY)
	_bubble.add_theme_stylebox_override("panel", bubble_style)
	_text.add_theme_color_override("font_color", Tokens.color(self, Tokens.BACKGROUND))
	queue_redraw()


func say(line: String) -> void:
	var bubble := $Bubble as PanelContainer
	var text_label := $Bubble/Text as Label
	text_label.text = line
	bubble.show()
	bubble.offset_transform_enabled = true
	bubble.offset_transform_visual_only = true
	bubble.offset_transform_pivot_ratio = Vector2(0.85, 0.5)
	bubble.offset_transform_scale = Vector2(0.76, 0.76)
	bubble.modulate.a = 0.0
	if not is_inside_tree():
		bubble.offset_transform_scale = Vector2.ONE
		bubble.modulate.a = 1.0
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		bubble, "offset_transform_scale", Vector2.ONE, 0.20
	).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.12)
	queue_redraw()


func hide_bubble() -> void:
	$Bubble.hide()
	queue_redraw()


func react(kind: String) -> void:
	_reaction = kind
	var squash := Vector2(1.22, 0.78) if kind == "fail" else Vector2(0.82, 1.22)
	_reaction_scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(self, "_reaction_scale", squash, 0.08)
	tween.tween_property(self, "_reaction_scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func() -> void: _reaction = "idle")


func play_entrance() -> void:
	offset_transform_enabled = true
	offset_transform_visual_only = true
	offset_transform_position = Vector2(90.0, 0.0)
	modulate.a = 0.0
	if not is_inside_tree():
		offset_transform_position = Vector2.ZERO
		modulate.a = 1.0
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		self, "offset_transform_position", Vector2.ZERO, 0.28
	).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)


func _process(delta: float) -> void:
	_time += delta
	_next_blink -= delta
	_blink_left = maxf(0.0, _blink_left - delta)
	if _next_blink <= 0.0:
		_blink_left = 0.12
		_next_blink = 2.4 + fmod(_time, 1.8)
	queue_redraw()


func _draw() -> void:
	var host := Vector2(size.x - 48.0, size.y - 48.0)
	host.y += sin(_time * BOB_SPEED) * BOB_HEIGHT
	if $Bubble.visible:
		var tail := PackedVector2Array([
			Vector2(246.0, 62.0),
			Vector2(276.0, 74.0),
			Vector2(246.0, 82.0),
		])
		draw_colored_polygon(tail, Tokens.color(self, Tokens.TEXT))

	var shadow_scale := 1.0 - sin(_time * BOB_SPEED) * 0.06
	draw_set_transform(host + Vector2(0.0, 37.0), 0.0, Vector2(shadow_scale, 0.32))
	draw_circle(Vector2.ZERO, 34.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(host, 0.0, _reaction_scale)

	var outline := Tokens.color(self, Tokens.BACKGROUND)
	var body := Tokens.color(self, Tokens.PRIMARY)
	var visor := Tokens.color(self, Tokens.SURFACE)
	var bill := Tokens.color(self, Tokens.WARNING)
	draw_rect(Rect2(-32.0, -30.0, 64.0, 62.0), outline)
	draw_rect(Rect2(-27.0, -25.0, 54.0, 52.0), body)
	draw_rect(Rect2(-20.0, -13.0, 40.0, 19.0), visor)
	draw_rect(Rect2(18.0, 5.0, 22.0, 11.0), outline)
	draw_rect(Rect2(22.0, 7.0, 20.0, 7.0), bill)
	draw_line(Vector2(0.0, -30.0), Vector2(0.0, -46.0), outline, 6.0)
	draw_circle(Vector2(0.0, -49.0), 6.0, bill)
	if _blink_left > 0.0 or _reaction == "fail":
		draw_line(Vector2(-12.0, -4.0), Vector2(-4.0, -4.0), Tokens.color(self, Tokens.TEXT), 4.0)
		draw_line(Vector2(5.0, -4.0), Vector2(13.0, -4.0), Tokens.color(self, Tokens.TEXT), 4.0)
	else:
		draw_rect(Rect2(-12.0, -8.0, 7.0, 9.0), Tokens.color(self, Tokens.TEXT))
		draw_rect(Rect2(6.0, -8.0, 7.0, 9.0), Tokens.color(self, Tokens.TEXT))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
