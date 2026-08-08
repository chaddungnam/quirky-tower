extends Control

const Tokens = preload("res://scripts/ui/design_tokens.gd")


func _ready() -> void:
	var style := Tokens.panel_style(self, Tokens.CREAM)
	get_node("Center/Card").add_theme_stylebox_override("panel", style)


func show_message(title: String, body: String, action_text: String, action: Callable) -> void:
	_clear_actions()
	get_node("Center/Card/Content/Title").text = title
	get_node("Center/Card/Content/Body").text = body
	_add_action(action_text, action)
	show()


func show_choices(title: String, options: Array, action: Callable) -> void:
	_clear_actions()
	get_node("Center/Card/Content/Title").text = title
	get_node("Center/Card/Content/Body").text = "하나를 선택하세요"
	for option in options:
		var option_id := str(option.get("id", ""))
		var label := str(option.get("label", option_id.replace("_", " ").capitalize()))
		_add_action(label, action.bind(option_id))
	show()


func close() -> void:
	hide()
	_clear_actions()


func _add_action(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = Tokens.TOUCH_HEIGHT
	get_node("Center/Card/Content/Actions").add_child(button)
	button.add_theme_stylebox_override("normal", Tokens.panel_style(button, Tokens.CORAL))
	button.add_theme_color_override("font_color", Tokens.color(button, Tokens.CREAM))
	button.pressed.connect(func() -> void: action.call())


func _clear_actions() -> void:
	for child in get_node("Center/Card/Content/Actions").get_children():
		child.free()
