class_name ChallengeRules
extends RefCounted

const BASE_SCORES := {
	"timing_ring": 120,
	"tap_panic": 100,
	"drag_dodge": 110,
}


static func evaluate(challenge_id: String, input_value: float, difficulty: float, modifiers: Dictionary = {}) -> Dictionary:
	var value := clampf(input_value, 0.0, 1.0)
	var level := clampf(difficulty, 0.0, 1.0)
	var success := false
	var quality := 0.0
	match challenge_id:
		"timing_ring":
			var width := maxf(0.08, 0.25 - level * 0.2 + float(modifiers.get("window_bonus", 0.0)))
			var distance := absf(value - 0.5)
			success = distance <= width
			quality = clampf(1.0 - distance / width, 0.0, 1.0)
		"tap_panic":
			var threshold := clampf(0.35 + level * 0.45, 0.35, 0.9)
			success = value >= threshold
			quality = clampf((value - threshold) / maxf(0.1, 1.0 - threshold), 0.0, 1.0)
		"drag_dodge":
			var width := clampf(0.65 - level * 0.4, 0.22, 0.65)
			var distance := absf(value - 0.5)
			success = distance <= width * 0.5
			quality = clampf(1.0 - distance / (width * 0.5), 0.0, 1.0)
		_:
			return {"success": false, "quality": 0.0, "score": 0, "error": "unknown challenge %s" % challenge_id}
	var score := int(round(float(BASE_SCORES[challenge_id]) * (1.0 + level) * (0.5 + quality * 0.5))) if success else 0
	return {"success": success, "quality": quality, "score": score, "error": ""}
