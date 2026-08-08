class_name TowerRunState
extends RefCounted

const SAVE_VERSION := 1

var seed: int
var country: String
var floor := 1
var hearts := 3
var combo := 0
var score := 0
var quirks: Array = []
var checkpoint_floor := 1
var checkpoint_snapshot: Dictionary = {}
var boost_used := false
var boost_source := ""
var replay_used := false
var story_event_ids: Array = []
var status := "running"


static func new_run(run_seed: int, country_code: String) -> TowerRunState:
	var state := new()
	state.seed = run_seed
	state.country = country_code
	return state


static func restore(data: Dictionary) -> TowerRunState:
	if int(data.get("version", 0)) != SAVE_VERSION:
		return null
	if int(data.get("floor", 0)) < 1 or int(data.get("floor", 0)) > 15:
		return null
	if int(data.get("hearts", -1)) < 0 or not data.get("quirks", null) is Array:
		return null
	var state := new_run(int(data.get("seed", 0)), str(data.get("country", "")))
	state.floor = int(data.floor)
	state.hearts = int(data.hearts)
	state.combo = int(data.get("combo", 0))
	state.score = int(data.get("score", 0))
	state.quirks = data.quirks.duplicate()
	state.checkpoint_floor = int(data.get("checkpoint_floor", 1))
	state.checkpoint_snapshot = data.get("checkpoint_snapshot", {}).duplicate(true)
	state.boost_used = bool(data.get("boost_used", false))
	state.boost_source = str(data.get("boost_source", ""))
	state.replay_used = bool(data.get("replay_used", false))
	state.story_event_ids = data.get("story_event_ids", []).duplicate()
	state.status = str(data.get("status", "running"))
	return state


func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"seed": seed,
		"country": country,
		"floor": floor,
		"hearts": hearts,
		"combo": combo,
		"score": score,
		"quirks": quirks.duplicate(),
		"checkpoint_floor": checkpoint_floor,
		"checkpoint_snapshot": checkpoint_snapshot.duplicate(true),
		"boost_used": boost_used,
		"boost_source": boost_source,
		"replay_used": replay_used,
		"story_event_ids": story_event_ids.duplicate(),
		"status": status,
	}
