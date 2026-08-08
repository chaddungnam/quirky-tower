extends Control

signal home_requested

const GameCatalog = preload("res://scripts/core/run/game_catalog.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const RunEngine = preload("res://scripts/core/run/run_engine.gd")
const QuirkRules = preload("res://scripts/core/quirks/quirk_rules.gd")
const Tokens = preload("res://scripts/ui/design_tokens.gd")
const TOWER_TRIAL_SCENE = preload("res://scenes/game/challenges/tower_trial.tscn")
const CHALLENGE_IDS := ["timing_ring", "tap_panic", "drag_dodge"]
const QUIRK_FLOORS := [4, 8, 12]

var _catalog
var _state
var _phase := "boot"
var _last_result: Dictionary = {}
var _current_challenge: Control


func _ready() -> void:
	get_node("Background").color = Tokens.color(self, Tokens.BACKGROUND)
	restart_run()


func restart_run() -> void:
	_clear_challenge()
	get_node("GameOverlay").close()
	_catalog = GameCatalog.load_default()
	var errors: PackedStringArray = _catalog.validate()
	if not errors.is_empty():
		_phase = "error"
		get_node("GameOverlay").show_message("DATA ERROR", errors[0], "RETRY", restart_run)
		return
	_state = RunState.new_run(int(Time.get_unix_time_from_system()), "DE")
	_last_result = {}
	_present_floor()


func submit_challenge(input_value: float, score_multiplier := 1.0) -> void:
	if _phase != "challenge":
		return
	_phase = "result"
	_last_result = RunEngine.resolve_floor(_state, _catalog, input_value, score_multiplier)
	_last_result["hearts"] = _state.hearts
	if is_instance_valid(_current_challenge) and _current_challenge.has_method("show_resolution"):
		_current_challenge.show_resolution(_last_result)
	else:
		get_node("GameOverlay").show_message("RESULT", "", "CONTINUE", continue_flow)


func continue_flow() -> void:
	if _phase == "result" and str(_last_result.get("story_event_id", "")) != "":
		_phase = "story"
		_clear_challenge()
		_show_story(str(_last_result.story_event_id))
		return
	if _phase not in ["result", "story"]:
		return
	if _state.status != "running":
		_show_run_end()
	else:
		_present_floor()


func choose_quirk(quirk_id: String) -> void:
	if _phase != "quirk" or quirk_id not in available_quirks():
		return
	_state.quirks.append(quirk_id)
	get_node("GameOverlay").close()
	_spawn_challenge()


func needs_quirk_choice() -> bool:
	if _state == null or _state.floor not in QUIRK_FLOORS:
		return false
	return _state.quirks.size() == QUIRK_FLOORS.find(_state.floor)


func available_quirks() -> Array:
	if _catalog == null or _state == null:
		return []
	var result: Array = []
	for quirk_id in _catalog.quirks.keys():
		if quirk_id not in _state.quirks:
			result.append(str(quirk_id))
	return result


func success_input_for_current_challenge() -> float:
	return 1.0 if current_challenge_id() == "tap_panic" else 0.5


func current_challenge_id() -> String:
	if _state == null or _catalog == null:
		return ""
	return RunEngine.challenge_id_for_floor(_state, _catalog)


func get_run_snapshot() -> Dictionary:
	return _state.snapshot() if _state != null else {}


func _present_floor() -> void:
	_clear_challenge()
	get_node("GameOverlay").close()
	_update_hud()
	if needs_quirk_choice():
		_phase = "quirk"
		var options: Array = []
		for quirk_id in available_quirks():
			var label := str(quirk_id).replace("_", " ").capitalize()
			options.append({"id": quirk_id, "label": label})
		get_node("GameOverlay").show_choices("CHOOSE A QUIRK", options, choose_quirk)
	else:
		_spawn_challenge()


func _spawn_challenge() -> void:
	_clear_challenge()
	var challenge_id := current_challenge_id()
	if challenge_id not in CHALLENGE_IDS:
		_phase = "error"
		get_node("GameOverlay").show_message("SCENE ERROR", challenge_id, "RETRY", restart_run)
		return
	_current_challenge = TOWER_TRIAL_SCENE.instantiate()
	get_node("ChallengeSlot").add_child(_current_challenge)
	var floor_data: Dictionary = _catalog.floors[_state.floor - 1]
	_current_challenge.setup(
		float(floor_data.difficulty),
		QuirkRules.modifiers(_state.quirks),
		challenge_id
	)
	_current_challenge.finished.connect(submit_challenge)
	_current_challenge.resolution_finished.connect(_on_resolution_finished)
	_phase = "challenge"
	_current_challenge.begin()


func _on_resolution_finished() -> void:
	if _phase == "result":
		continue_flow()


func _clear_challenge() -> void:
	if is_instance_valid(_current_challenge):
		_current_challenge.name = "_RetiredChallenge"
		_current_challenge.queue_free()
	_current_challenge = null


func _update_hud() -> void:
	get_node("RunHud").update_state(_state)


func _show_story(event_id: String) -> void:
	for event in _catalog.story_events:
		if str(event.get("id", "")) == event_id:
			var title := str(event.get("speaker", "HOST"))
			var body := str(event.get("text", ""))
			get_node("GameOverlay").show_message(title, body, "CONTINUE", continue_flow)
			return
	get_node("GameOverlay").show_message("STORY", event_id, "CONTINUE", continue_flow)


func _show_run_end() -> void:
	_phase = "end"
	_clear_challenge()
	var title := "TOWER COMPLETE" if _state.status == "complete" else "GAME OVER"
	var body := "SCORE %d" % _state.score
	get_node("GameOverlay").show_actions(title, body, [
		{"label": "PLAY AGAIN", "action": restart_run},
		{"label": "HOME", "action": func() -> void: home_requested.emit()},
	])
