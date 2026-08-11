class_name FlockRunState
extends RefCounted

const ACT_IDS := ["entry", "brawl", "chain", "choice", "complete"]
const CHOICE_IDS := ["dash_power", "route_width", "guard"]

var seed: int
var act_id := "entry"
var companions: Array = []
var build := {"dash_power": 0, "route_width": 0, "guard": 0}
var event_ledger: Array = []
var choice_applied := ""
var _rng := RandomNumberGenerator.new()
var _choices: Array = []


static func new_run(run_seed: int) -> FlockRunState:
	var state := new()
	state.seed = run_seed
	state._rng.seed = run_seed
	return state


func begin_act(next_act_id: String) -> void:
	if ACT_IDS.has(next_act_id):
		act_id = next_act_id


func rescue(companion_id: String, species: String) -> bool:
	if companions.size() >= 5 or companion_id.is_empty() or species.is_empty() or companions.any(func(companion): return companion.id == companion_id):
		return false
	companions.append({"id": companion_id, "species": species})
	return true


func record_event(kind: String, payload := {}) -> void:
	event_ledger.append({"kind": kind, "payload": payload.duplicate(true)})


func choice_options() -> Array:
	if _choices.is_empty():
		_choices = CHOICE_IDS.duplicate()
		for index in range(_choices.size() - 1, 0, -1):
			var swap_index := _rng.randi_range(0, index)
			var choice_id = _choices[index]
			_choices[index] = _choices[swap_index]
			_choices[swap_index] = choice_id
	return _choices.map(func(choice_id): return {"id": choice_id})


func apply_choice(choice_id: String) -> bool:
	if not choice_applied.is_empty() or not CHOICE_IDS.has(choice_id):
		return false
	if choice_options().any(func(option): return option.id == choice_id):
		build[choice_id] = int(build[choice_id]) + 1
		choice_applied = choice_id
		return true
	return false


func snapshot() -> Dictionary:
	return {
		"seed": seed,
		"act_id": act_id,
		"companions": companions.duplicate(true),
		"build": build.duplicate(),
		"event_ledger": event_ledger.duplicate(true),
		"choice_applied": choice_applied,
		"choices": _choices.duplicate(),
		"rng_state": _rng.state,
	}
