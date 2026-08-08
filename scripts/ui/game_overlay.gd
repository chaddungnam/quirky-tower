extends Control

const Tokens = preload("res://scripts/ui/design_tokens.gd")

var _enter_tween: Tween


func _ready() -> void:
	var style := Tokens.panel_style(self, Tokens.SURFACE)
	get_node("Center/Card").add_theme_stylebox_override("panel", style)
	var card := get_node("Center/Card") as Control
	card.offset_transform_enabled = true
	card.offset_transform_visual_only = true
	card.offset_transform_pivot_ratio = Vector2(0.5, 0.5)


func show_message(title: String, body: String, action_text: String, action: Callable) -> void:
	show_actions(title, body, [{"label": action_text, "action": action}])


func show_choices(title: String, options: Array, action: Callable) -> void:
	var actions: Array = []
	for option in options:
		var option_id := str(option.get("id", ""))
		actions.append({
			"id": option_id,
			"label": str(option.get("label", option_id.replace("_", " ").capitalize())),
			"action": action.bind(option_id),
		})
	show_actions(title, "", actions)


func show_actions(title: String, body: String, options: Array) -> void:
	_clear_actions()
	get_node("Center/Card/Content/Title").text = title
	var body_label := get_node("Center/Card/Content/Body") as Label
	body_label.text = body
	body_label.visible = not body.is_empty()
	for option in options:
		_add_action(
			str(option.get("label", "")),
			option.get("action", Callable()),
			str(option.get("id", ""))
		)
	var action_scroll := get_node("Center/Card/Content/ActionScroll") as ScrollContainer
	action_scroll.custom_minimum_size.y = minf(600.0, options.size() * 110.0)
	show()
	get_node("MascotGuide").say(_host_line(title))
	get_node("MascotGuide").play_entrance()
	_play_entrance()


func close() -> void:
	if _enter_tween and _enter_tween.is_valid():
		_enter_tween.kill()
	hide()
	_clear_actions()


func _add_action(text: String, action: Callable, option_id := "") -> void:
	var button := Button.new()
	button.text = text
	button.set_meta("option_id", option_id)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_node("Center/Card/Content/ActionScroll/Actions").add_child(button)
	Tokens.style_button(button, Tokens.WARNING)
	button.offset_transform_enabled = true
	button.offset_transform_visual_only = true
	button.pressed.connect(func() -> void:
		if action.is_valid():
			action.call()
	)


func _clear_actions() -> void:
	var actions := get_node("Center/Card/Content/ActionScroll/Actions")
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()


func _play_entrance() -> void:
	if _enter_tween and _enter_tween.is_valid():
		_enter_tween.kill()
	var dim := get_node("Dim") as ColorRect
	var card := get_node("Center/Card") as Control
	dim.modulate.a = 0.0
	card.modulate.a = 0.0
	card.offset_transform_position = Vector2(0.0, 34.0)
	card.offset_transform_scale = Vector2(0.86, 0.86)
	if not is_inside_tree():
		dim.modulate.a = 1.0
		card.modulate.a = 1.0
		return
	_enter_tween = create_tween().set_parallel(true)
	_enter_tween.tween_property(dim, "modulate:a", 1.0, 0.16)
	_enter_tween.tween_property(card, "modulate:a", 1.0, 0.12)
	_enter_tween.tween_property(
		card, "offset_transform_position", Vector2.ZERO, 0.24
	).set_trans(Tween.TRANS_BACK)
	_enter_tween.tween_property(
		card, "offset_transform_scale", Vector2.ONE, 0.24
	).set_trans(Tween.TRANS_BACK)
	var actions := get_node("Center/Card/Content/ActionScroll/Actions").get_children()
	for index in range(actions.size()):
		var button := actions[index] as Control
		button.modulate.a = 0.0
		button.offset_transform_position = Vector2(0.0, 22.0)
		var delay := 0.08 + index * 0.05
		_enter_tween.tween_property(button, "modulate:a", 1.0, 0.12).set_delay(delay)
		_enter_tween.tween_property(
			button, "offset_transform_position", Vector2.ZERO, 0.18
		).set_delay(delay).set_trans(Tween.TRANS_BACK)


func _host_line(title: String) -> String:
	if "QUIRK" in title:
		return "하나쯤 이상해야지."
	if "COMPLETE" in title:
		return "끝까지 왔네."
	if "GAME OVER" in title:
		return "벽이 꽤 단단했지."
	if title == "HOST":
		return "방금 건 못 본 걸로."
	if title == "SYSTEM":
		return "그건 대본에 없는데."
	return "골라 봐."
