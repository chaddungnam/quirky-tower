extends Control

signal finished(input_value: float, score_multiplier: float)
signal resolution_finished

const Tokens = preload("res://scripts/ui/design_tokens.gd")
const PREVIEW_DURATION := 0.72
const RESULT_DURATION := 0.68
const CHALLENGE_SCENES := {
	"timing_ring": preload("res://scenes/game/challenges/timing_ring.tscn"),
	"tap_panic": preload("res://scenes/game/challenges/tap_panic.tscn"),
	"drag_dodge": preload("res://scenes/game/challenges/drag_dodge.tscn"),
}
const COPY := {
	"timing_ring": {
		"title": "SIGNAL LOCK",
		"instruction": "꼭대기에서 탭!",
		"host": "불빛이 위에 올 때.",
	},
	"tap_panic": {
		"title": "COLOR PANIC",
		"instruction": "라임 ●만 눌러!",
		"host": "다른 건 전부 함정이야.",
	},
	"drag_dodge": {
		"title": "WALL RUSH",
		"instruction": "드래그로 피해!",
		"host": "벽은 진짜로 아파.",
	},
}

var _difficulty := 0.5
var _modifiers: Dictionary = {}
var _challenge_id := "timing_ring"
var _phase := "idle"
var _elapsed := 0.0
var _challenge: Control
var _particles: Array[Dictionary] = []

@onready var _challenge_slot: Control = $ChallengeSlot
@onready var _intro_layer: Control = $IntroLayer
@onready var _result_layer: Control = $ResultLayer
@onready var _guide: Control = $MascotGuide


func _ready() -> void:
	$IntroLayer/Center/Card.add_theme_stylebox_override(
		"panel", Tokens.panel_style(self, Tokens.SURFACE, 30)
	)
	$ResultLayer/Center/Card.add_theme_stylebox_override(
		"panel", Tokens.panel_style(self, Tokens.SURFACE, 30)
	)


func setup(difficulty: float, modifiers: Dictionary = {}, challenge_id := "timing_ring") -> void:
	_difficulty = clampf(difficulty, 0.0, 1.0)
	_modifiers = modifiers.duplicate()
	_challenge_id = str(challenge_id)
	if not CHALLENGE_SCENES.has(_challenge_id):
		_challenge_id = "timing_ring"


func begin() -> void:
	_clear_challenge()
	_spawn_challenge()
	_phase = "preview"
	_elapsed = 0.0
	_particles.clear()
	var copy: Dictionary = COPY[_challenge_id]
	$IntroLayer/Center/Card/Content/ModeTitle.text = str(copy.title)
	$IntroLayer/Center/Card/Content/Instruction.text = str(copy.instruction)
	_intro_layer.show()
	_result_layer.hide()
	$GoLabel.hide()
	_challenge.modulate = Color(1.0, 1.0, 1.0, 0.16)
	_guide.show()
	_guide.modulate.a = 1.0
	_guide.say(str(copy.host))
	_guide.play_entrance()
	_play_intro_card()


func show_resolution(result: Dictionary) -> void:
	if _phase not in ["active", "awaiting_result"]:
		return
	_phase = "resolution"
	_elapsed = 0.0
	var success := bool(result.get("success", false))
	$ResultLayer/Center/Card/Content/ResultTitle.text = "CLEAR!" if success else "BONK!"
	$ResultLayer/Center/Card/Content/ResultDetail.text = (
		"+%d" % int(result.get("score_delta", 0)) if success
		else "♥ %d" % int(result.get("hearts", 0))
	)
	$ResultLayer/Flash.color = Tokens.color(self, Tokens.PRIMARY if success else Tokens.DANGER)
	$ResultLayer/Flash.modulate.a = 0.34
	_result_layer.show()
	_guide.show()
	_guide.modulate.a = 1.0
	_guide.offset_transform_position = Vector2.ZERO
	_guide.react("success" if success else "fail")
	_guide.say("그게 되네." if success else "벽도 널 봤어.")
	_guide.play_entrance()
	_spawn_burst(success)
	_play_result_card(success)


func _process(delta: float) -> void:
	match _phase:
		"preview":
			_elapsed += delta
			if _elapsed >= PREVIEW_DURATION:
				_start_active()
		"resolution":
			_elapsed += delta
			_update_particles(delta)
			if _elapsed >= RESULT_DURATION:
				_phase = "done"
				resolution_finished.emit()
	queue_redraw()


func _draw() -> void:
	for particle: Dictionary in _particles:
		var color := Tokens.color(self, str(particle.role))
		color.a = clampf(float(particle.life) / 0.7, 0.0, 1.0)
		draw_circle(particle.position, float(particle.size), color)


func _spawn_challenge() -> void:
	_challenge = CHALLENGE_SCENES[_challenge_id].instantiate()
	_challenge_slot.add_child(_challenge)
	_challenge.setup(_difficulty, _modifiers)
	_challenge.finished.connect(_on_challenge_finished)


func _start_active() -> void:
	if _phase != "preview":
		return
	_phase = "active"
	_elapsed = 0.0
	_intro_layer.hide()
	_challenge.modulate = Color.WHITE
	_challenge.begin()
	$GoLabel.show()
	$GoLabel.scale = Vector2(0.5, 0.5)
	$GoLabel.modulate.a = 1.0
	$GoLabel.pivot_offset = $GoLabel.size * 0.5
	var go_tween := create_tween().set_parallel(true)
	go_tween.tween_property($GoLabel, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK)
	go_tween.tween_property($GoLabel, "modulate:a", 0.0, 0.32).set_delay(0.12)
	go_tween.chain().tween_callback($GoLabel.hide)
	_guide.hide_bubble()
	var guide_tween := create_tween().set_parallel(true)
	guide_tween.tween_property(_guide, "offset_transform_position", Vector2(100.0, 0.0), 0.18)
	guide_tween.tween_property(_guide, "modulate:a", 0.0, 0.14)
	guide_tween.chain().tween_callback(_guide.hide)


func _on_challenge_finished(input_value: float) -> void:
	if _phase != "active":
		return
	_phase = "awaiting_result"
	finished.emit(input_value, 1.0)


func _play_intro_card() -> void:
	var card := $IntroLayer/Center/Card as Control
	card.offset_transform_enabled = true
	card.offset_transform_visual_only = true
	card.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	card.offset_transform_scale = Vector2(0.74, 0.74)
	card.offset_transform_position = Vector2(0.0, 36.0)
	card.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		card, "offset_transform_scale", Vector2.ONE, 0.24
	).set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		card, "offset_transform_position", Vector2.ZERO, 0.22
	).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "modulate:a", 1.0, 0.12)


func _play_result_card(success: bool) -> void:
	var card := $ResultLayer/Center/Card as Control
	card.offset_transform_enabled = true
	card.offset_transform_visual_only = true
	card.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	card.offset_transform_scale = Vector2(0.55, 0.55)
	card.offset_transform_rotation = -0.04 if success else 0.04
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		card, "offset_transform_scale", Vector2(1.08, 1.08), 0.16
	).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "offset_transform_rotation", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property($ResultLayer/Flash, "modulate:a", 0.0, 0.28)


func _spawn_burst(success: bool) -> void:
	_particles.clear()
	var center := size * Vector2(0.5, 0.48)
	var count := 22 if success else 10
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		_particles.append({
			"position": center,
			"velocity": Vector2.from_angle(angle) * (170.0 + float(index % 5) * 26.0),
			"life": 0.7,
			"size": 7.0 + float(index % 3) * 3.0,
			"role": Tokens.PRIMARY if success else Tokens.DANGER,
		})


func _update_particles(delta: float) -> void:
	for particle: Dictionary in _particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 340.0 * delta
		particle.life -= delta
	_particles = _particles.filter(func(particle: Dictionary) -> bool: return particle.life > 0.0)


func _clear_challenge() -> void:
	if not is_instance_valid(_challenge):
		return
	_challenge.queue_free()
	_challenge = null
