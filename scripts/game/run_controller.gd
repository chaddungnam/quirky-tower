extends Control

signal home_requested

const FlockRunState = preload("res://scripts/core/reboot/flock_run_state.gd")
const FLOCK_TRIAL_SCENE = preload("res://scenes/game/reboot/flock_trial.tscn")
const Tokens = preload("res://scripts/ui/design_tokens.gd")
const UIText = preload("res://scripts/ui/ui_text.gd")
const CHOICE_ROLES := {
	"dash_power": Tokens.PRIMARY,
	"route_width": Tokens.SECRET,
	"guard": Tokens.SECONDARY,
}

var _state: FlockRunState
var _current_trial: FlockTrial
var _locale := "en"


func _ready() -> void:
	get_node("Background").color = Tokens.color(self, Tokens.BACKGROUND)


func restart_run(seed_override := -1) -> void:
	_clear_trial()
	get_node("SafeFrame/GameOverlay").close()
	var run_seed := seed_override if seed_override >= 0 else int(Time.get_unix_time_from_system())
	_state = FlockRunState.new_run(run_seed)
	_current_trial = FLOCK_TRIAL_SCENE.instantiate()
	get_node("ChallengeSlot").add_child(_current_trial)
	_current_trial.state_changed.connect(_on_state_changed)
	_current_trial.district_finished.connect(_on_district_finished)
	_current_trial.set_language(_locale)
	_current_trial.begin(_state)
	_update_hud()


func set_language(locale: String) -> void:
	_locale = UIText.supported_code(locale)
	if is_instance_valid(_current_trial):
		_current_trial.set_language(_locale)
		_update_hud()


func get_run_snapshot() -> Dictionary:
	return _state.snapshot() if _state != null else {}


func _on_state_changed(_snapshot: Dictionary) -> void:
	_update_hud()


func _on_district_finished() -> void:
	if not is_instance_valid(_current_trial) or _state == null:
		return
	_current_trial.cancel_input()
	_current_trial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_trial.get_node("SafeFrame/MascotGuide").hide()
	_update_hud()
	var options: Array = []
	for option in _state.choice_options():
		var choice_id := str(option.id)
		options.append({
			"id": choice_id,
			"label": UIText.text(_locale, "choice_%s" % choice_id),
			"role": CHOICE_ROLES[choice_id],
		})
	get_node("SafeFrame/GameOverlay").show_choices(
		UIText.text(_locale, "choice_title"), options, _choose_build
	)


func _choose_build(choice_id: String) -> void:
	if _state == null or not _state.apply_choice(choice_id):
		return
	_state.begin_act("complete")
	_update_hud()
	var selected_label := UIText.text(_locale, "choice_%s" % choice_id)
	get_node("SafeFrame/GameOverlay").show_actions(
		UIText.text(_locale, "result_title"),
		"%s\n%s" % [UIText.text(_locale, "result_body"), selected_label],
		[
			{"label": UIText.text(_locale, "play_again"), "action": restart_run},
			{"label": UIText.text(_locale, "home"), "action": _request_home},
		]
	)


func _request_home() -> void:
	_clear_trial()
	get_node("SafeFrame/GameOverlay").close()
	home_requested.emit()


func _clear_trial() -> void:
	if is_instance_valid(_current_trial):
		_current_trial.cancel_input()
		_current_trial.name = "_RetiredFlockTrial"
		_current_trial.queue_free()
	_current_trial = null


func _update_hud() -> void:
	if _state == null:
		return
	var act_title := ""
	if is_instance_valid(_current_trial):
		act_title = str(_current_trial.get_visual_state().act_title)
	get_node("SafeFrame/RunHud").update_state(_state, act_title)
