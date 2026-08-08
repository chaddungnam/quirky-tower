class_name TowerRunEngine
extends RefCounted

const ChallengeRules = preload("res://scripts/core/challenges/challenge_rules.gd")
const QuirkRules = preload("res://scripts/core/quirks/quirk_rules.gd")


static func resolve_floor(state, catalog, input_value: float) -> Dictionary:
	if state.status != "running":
		return {"success": false, "error": "run is not active", "status": state.status}
	var floor_index: int = state.floor - 1
	if floor_index < 0 or floor_index >= catalog.floors.size():
		return {"success": false, "error": "floor out of range", "status": state.status}

	var floor_data: Dictionary = catalog.floors[floor_index]
	var challenge_id := str(floor_data.challenge_id)
	var modifiers := QuirkRules.modifiers(state.quirks)
	if int(modifiers.challenge_shift) != 0:
		var challenge_ids: Array = catalog.challenges.keys()
		var current_index := challenge_ids.find(challenge_id)
		challenge_id = str(challenge_ids[(current_index + int(modifiers.challenge_shift)) % challenge_ids.size()])

	var evaluation: Dictionary = ChallengeRules.evaluate(challenge_id, input_value, float(floor_data.difficulty), modifiers)
	var current_floor: int = state.floor
	var score_delta := 0
	var replayed := false
	if evaluation.success:
		state.combo += 1
		var combo_multiplier := 1.0 + float(state.combo - 1) * 0.15
		score_delta = int(round(float(evaluation.score) * combo_multiplier * float(modifiers.combo_multiplier)))
		state.score += score_delta
		if current_floor == 15:
			state.status = "complete"
		else:
			state.floor += 1
	else:
		state.combo = 0
		if int(modifiers.replay_charges) > 0 and not state.replay_used:
			state.replay_used = true
			replayed = true
		else:
			state.hearts = maxi(0, state.hearts - 1 - int(modifiers.failure_penalty))
			if state.hearts == 0:
				state.status = "game_over"

	var story_event_id := _story_event_for_floor(catalog.story_events, current_floor) if evaluation.success else ""
	if story_event_id != "" and not state.story_event_ids.has(story_event_id):
		state.story_event_ids.append(story_event_id)
	if evaluation.success and bool(floor_data.get("checkpoint", false)):
		state.checkpoint_floor = current_floor
		var checkpoint: Dictionary = state.snapshot()
		checkpoint.checkpoint_snapshot = {}
		state.checkpoint_snapshot = checkpoint

	return {
		"success": bool(evaluation.success),
		"error": str(evaluation.error),
		"challenge_id": challenge_id,
		"floor": current_floor,
		"score_delta": score_delta,
		"story_event_id": story_event_id,
		"replayed": replayed,
		"status": state.status,
		"country": state.country,
	}


static func _story_event_for_floor(events: Array, floor_number: int) -> String:
	for event in events:
		if int(event.get("floor", 0)) == floor_number:
			return str(event.get("id", ""))
	return ""
