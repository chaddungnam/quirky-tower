extends Control

const Tokens = preload("res://scripts/ui/design_tokens.gd")


func _ready() -> void:
	var style := Tokens.panel_style(self, Tokens.CREAM)
	get_node("Center/Card").add_theme_stylebox_override("panel", style)


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
	show_actions(title, "하나를 선택하세요", actions)


func show_actions(title: String, body: String, options: Array) -> void:
	_clear_actions()
	get_node("Center/Card/Content/Title").text = title
	get_node("Center/Card/Content/Body").text = body
	for option in options:
		_add_action(
			str(option.get("label", "")),
			option.get("action", Callable()),
			str(option.get("id", ""))
		)
	var action_scroll := get_node("Center/Card/Content/ActionScroll") as ScrollContainer
	action_scroll.custom_minimum_size.y = minf(600.0, options.size() * 110.0)
	show()


func close() -> void:
	hide()
	_clear_actions()


func _add_action(text: String, action: Callable, option_id := "") -> void:
	var button := Button.new()
	button.text = text
	button.set_meta("option_id", option_id)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_node("Center/Card/Content/ActionScroll/Actions").add_child(button)
	Tokens.style_button(button, Tokens.CORAL)
	button.pressed.connect(func() -> void:
		if action.is_valid():
			action.call()
	)


func _clear_actions() -> void:
	var actions := get_node("Center/Card/Content/ActionScroll/Actions")
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
