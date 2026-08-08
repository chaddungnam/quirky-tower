extends Control

signal finished(input_value: float, score_multiplier: float)

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const DODGE_DURATION := 3.0
const FEEDBACK_DURATION := 0.55
const ROUTES := [
	{
		"id": "safe",
		"label": "안전로  ×1.00",
		"detail": "장애물 적음 · 파괴 판정 넓음",
		"multiplier": 1.0,
		"hazards": 2,
		"speed_bonus": -30.0,
		"window_bonus": 0.10,
		"heat": 35,
	},
	{
		"id": "bold",
		"label": "위험로  ×1.25",
		"detail": "기본 난이도 · 높은 점수",
		"multiplier": 1.25,
		"hazards": 3,
		"speed_bonus": 20.0,
		"window_bonus": 0.02,
		"heat": 65,
	},
	{
		"id": "chaos",
		"label": "방송사고  ×1.50",
		"detail": "장애물 많음 · 비밀 자막",
		"multiplier": 1.5,
		"hazards": 4,
		"speed_bonus": 70.0,
		"window_bonus": -0.04,
		"heat": 100,
	},
]

var _difficulty := 0.5
var _modifiers: Dictionary = {}
var _challenge_id := ""
var _phase := "idle"
var _route: Dictionary = {}
var _score_multiplier := 1.0
var _elapsed := 0.0
var _collision_count := 0
var _invulnerability := 0.0
var _dodge_quality := 1.0
var _needle_phase := 0.0
var _result_input := 0.0
var _feedback_elapsed := 0.0
var _flash := 0.0
var _particles: Array = []

@onready var _stage = $StageDisplay/WorldViewport/TowerStage3D


func _ready() -> void:
	var panel_style := Tokens.panel_style(self, Tokens.SURFACE, 28)
	get_node("RoutePanel").add_theme_stylebox_override("panel", panel_style)
	get_node("Heat").add_theme_color_override("font_color", Tokens.color(self, Tokens.DANGER))
	_stage.player_hit.connect(_on_stage_hit)


func setup(difficulty: float, modifiers: Dictionary = {}, challenge_id := "timing_ring") -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_modifiers = modifiers.duplicate()
	_challenge_id = str(challenge_id)


func begin() -> void:
	_phase = "route"
	_route = {}
	_score_multiplier = 1.0
	_elapsed = 0.0
	_collision_count = 0
	_dodge_quality = 1.0
	_particles.clear()
	_stage.reset_stage()
	get_node("Prompt").text = "어느 길로 돌파할까?"
	get_node("Broadcast").text = "생방송은 위험할수록 뜨거워집니다"
	get_node("Heat").text = "방송 열기 0%"
	get_node("RoutePanel").show()
	_build_route_buttons()
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_update_particles(delta)
	match _phase:
		"dodge":
			_update_dodge(delta)
		"smash":
			_needle_phase += delta * (0.85 + _difficulty * 0.9)
			queue_redraw()
		"feedback":
			_feedback_elapsed += delta
			if _feedback_elapsed >= FEEDBACK_DURATION:
				_phase = "done"
				finished.emit(_result_input, _score_multiplier)
			queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _phase == "dodge":
		if event is InputEventScreenDrag:
			_set_player_x(event.position.x)
		elif event is InputEventScreenTouch and event.pressed:
			_set_player_x(event.position.x)
		elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_set_player_x(event.position.x)
		elif event is InputEventMouseButton and event.pressed:
			_set_player_x(event.position.x)
	elif _phase == "smash":
		if event is InputEventScreenTouch and event.pressed:
			_finish_smash()
		elif event is InputEventMouseButton and event.pressed:
			_finish_smash()


func _draw() -> void:
	if _phase in ["smash", "feedback"]:
		_draw_smash()
	_draw_particles()
	if _flash > 0.0:
		var flash_color := Tokens.color(self, Tokens.PRIMARY)
		flash_color.a = _flash * 1.8
		draw_rect(Rect2(Vector2.ZERO, size), flash_color)


func _build_route_buttons() -> void:
	_clear_route_buttons()
	var actions := get_node("RoutePanel/Content/RouteActions")
	var roles := [Tokens.PRIMARY, Tokens.WARNING, Tokens.SECRET]
	for index in range(ROUTES.size()):
		var route: Dictionary = ROUTES[index]
		var role: String = roles[index]
		var button := Button.new()
		button.text = "%s\n%s" % [route.label, route.detail]
		button.custom_minimum_size.y = 104.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		actions.add_child(button)
		var normal := Tokens.panel_style(button, role, 20)
		normal.set_border_width_all(4)
		normal.border_color = Tokens.color(button, Tokens.TEXT).darkened(0.25)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal.duplicate())
		button.add_theme_stylebox_override("pressed", Tokens.panel_style(button, Tokens.SURFACE, 20))
		button.add_theme_color_override("font_color", Tokens.color(button, Tokens.BACKGROUND))
		button.add_theme_color_override("font_hover_color", Tokens.color(button, Tokens.BACKGROUND))
		button.add_theme_color_override("font_pressed_color", Tokens.color(button, Tokens.TEXT))
		button.pressed.connect(func() -> void: _choose_route(route))


func _clear_route_buttons() -> void:
	var actions := get_node("RoutePanel/Content/RouteActions")
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()


func _choose_route(route: Dictionary) -> void:
	if _phase != "route":
		return
	_route = route.duplicate()
	_score_multiplier = float(_route.multiplier)
	get_node("RoutePanel").hide()
	_clear_route_buttons()
	_elapsed = 0.0
	_collision_count = 0
	_invulnerability = 0.0
	_dodge_quality = 1.0
	_stage.configure(_route, _difficulty)
	_stage.start_dodge()
	_phase = "dodge"
	get_node("Prompt").text = "드래그해서 돌파!"
	get_node("Broadcast").text = _broadcast_line()
	get_node("Heat").text = "방송 열기 %d%%  ·  ×%.2f" % [int(_route.heat), _score_multiplier]
	queue_redraw()


func _update_dodge(delta: float) -> void:
	_elapsed += delta
	_invulnerability = maxf(0.0, _invulnerability - delta)
	if _elapsed >= DODGE_DURATION:
		_start_smash()
	queue_redraw()


func _start_smash() -> void:
	_phase = "smash"
	_needle_phase = 0.0
	_stage.show_smash()
	get_node("Prompt").text = "문을 부술 순간 탭!"
	get_node("Broadcast").text = "중앙일수록 더 크게 터집니다"
	queue_redraw()


func _finish_smash() -> void:
	if _phase != "smash":
		return
	var normalized := pingpong(_needle_phase, 1.0)
	var timing_quality := clampf(1.0 - absf(normalized - 0.5) * 2.0, 0.0, 1.0)
	var combined_quality := clampf(_dodge_quality * 0.45 + timing_quality * 0.55, 0.0, 1.0)
	_result_input = _input_for_challenge(combined_quality)
	_feedback_elapsed = 0.0
	_phase = "feedback"
	_flash = 0.42 if combined_quality >= 0.88 else 0.2
	_spawn_debris(combined_quality)
	_stage.show_feedback(combined_quality)
	if combined_quality >= 0.88:
		get_node("Prompt").text = "PERFECT!"
		get_node("Broadcast").text = "타워가 흔들립니다!"
	elif combined_quality >= 0.62:
		get_node("Prompt").text = "GREAT!"
		get_node("Broadcast").text = "문을 돌파했습니다"
	else:
		get_node("Prompt").text = "MISS"
		get_node("Broadcast").text = "콤보가 끊길 위기입니다"
	queue_redraw()


func _input_for_challenge(quality: float) -> float:
	match _challenge_id:
		"timing_ring", "drag_dodge":
			return lerpf(1.0, 0.5, quality)
		"tap_panic":
			return quality
		_:
			return -1.0


func _set_player_x(value: float) -> void:
	var axis := clampf(value / maxf(1.0, size.x) * 2.0 - 1.0, -1.0, 1.0)
	_stage.set_player_axis(axis)


func _arena_rect() -> Rect2:
	return Rect2(28.0, 120.0, maxf(1.0, size.x - 56.0), maxf(1.0, size.y - 178.0))


func _draw_smash() -> void:
	var arena := _arena_rect()
	var track := Rect2(arena.position.x + 54.0, arena.end.y - 100.0, arena.size.x - 108.0, 34.0)
	draw_style_box(Tokens.panel_style(self, Tokens.SURFACE, 17), track)
	var bonus := float(_route.get("window_bonus", 0.0)) + float(_modifiers.get("window_bonus", 0.0))
	var target_width := clampf(0.17 - _difficulty * 0.05 + bonus, 0.08, 0.32)
	var target := Rect2(
		track.get_center() - Vector2(track.size.x * target_width, track.size.y * 0.5),
		Vector2(track.size.x * target_width * 2.0, track.size.y)
	)
	draw_style_box(Tokens.panel_style(self, Tokens.PRIMARY, 17), target)
	var needle_x := track.position.x + track.size.x * pingpong(_needle_phase, 1.0)
	draw_line(
		Vector2(needle_x, track.position.y - 42.0),
		Vector2(needle_x, track.end.y + 42.0),
		Tokens.color(self, Tokens.WARNING),
		12.0,
		true
	)


func _on_stage_hit() -> void:
	if _phase != "dodge" or _invulnerability > 0.0:
		return
	_collision_count += 1
	_dodge_quality = maxf(0.0, 1.0 - float(_collision_count) * 0.34)
	_invulnerability = 0.45
	_flash = 0.13
	get_node("Broadcast").text = "충돌! 마지막 파괴에서 만회하세요"


func _spawn_debris(quality: float) -> void:
	_particles.clear()
	var center := _arena_rect().get_center()
	var count := 18 if quality >= 0.88 else 9
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var speed := 170.0 + float((index * 29) % 120)
		_particles.append({
			"position": center,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": 0.7,
		})


func _update_particles(delta: float) -> void:
	for particle in _particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 420.0 * delta
		particle.life -= delta
	_particles = _particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)


func _draw_particles() -> void:
	for particle in _particles:
		var alpha := clampf(float(particle.life) / 0.7, 0.0, 1.0)
		var color := Tokens.color(self, Tokens.WARNING)
		color.a = alpha
		draw_circle(particle.position, 10.0, color)


func _broadcast_line() -> String:
	match str(_route.id):
		"safe":
			return "안전 규정 준수 중… 시청률은 평범합니다"
		"bold":
			return "관객이 위험을 원합니다!"
		"chaos":
			return "[송출 오류] 진행자는 이미 이 층을 알고 있다"
	return "LIVE"
