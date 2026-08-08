class_name QuirkRules
extends RefCounted


static func modifiers(quirk_ids: Array) -> Dictionary:
	var result := {
		"window_bonus": 0.0,
		"combo_multiplier": 1.0,
		"failure_penalty": 0,
		"replay_charges": 0,
		"challenge_shift": 0,
	}
	for quirk_id in quirk_ids:
		match str(quirk_id):
			"wide_window":
				result.window_bonus += 0.12
			"overheat_combo":
				result.combo_multiplier *= 1.5
				result.failure_penalty += 1
			"replay":
				result.replay_charges = 1
			"reroute":
				result.challenge_shift = 1
	return result
