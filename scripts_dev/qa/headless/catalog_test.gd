extends SceneTree

const GameCatalog = preload("res://scripts/core/run/game_catalog.gd")


func _init() -> void:
	var catalog = GameCatalog.load_default()
	assert(catalog.validate().is_empty(), "default catalog must be valid")
	assert(catalog.challenges.keys() == ["timing_ring", "tap_panic", "drag_dodge"], "three challenge IDs")
	assert(catalog.quirks.size() == 4, "four Quirks")
	assert(catalog.floors.size() == 15, "fifteen floors")
	assert(_story_floors(catalog.story_events) == [5, 10, 15], "story beats at floors 5, 10, and 15")
	assert(catalog.sponsor_boost.get("id") == "sponsor_guard", "one Sponsor Boost")
	assert(_country_codes(catalog.country_entries).has("DE"), "ordinary countries use the shared list")
	assert(_country_codes(catalog.country_entries).has("ALN"), "funny affiliations use the shared list")

	var invalid = GameCatalog.new()
	invalid.challenges = {}
	invalid.quirks = {}
	invalid.floors = [{"floor": 1, "challenge_id": "missing"}]
	invalid.story_events = []
	invalid.sponsor_boost = {"id": "sponsor_guard"}
	invalid.country_entries = []
	assert("unknown challenge_id missing at floor 1" in invalid.validate(), "broken floor reference must be named")

	print("PASS catalog_test")
	quit(0)


func _story_floors(events: Array) -> Array:
	return events.map(func(event: Dictionary) -> int: return int(event["floor"]))


func _country_codes(entries: Array) -> Array:
	return entries.map(func(entry: Dictionary) -> String: return str(entry["code"]))
