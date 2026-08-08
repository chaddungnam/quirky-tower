class_name GameCatalog
extends RefCounted

const PATHS := {
	"challenges": "res://data/gameplay/challenges.json",
	"quirks": "res://data/gameplay/quirks.json",
	"floors": "res://data/gameplay/floors.json",
	"story_events": "res://data/story/events.json",
	"sponsor_boost": "res://data/economy/sponsor_boost.json",
	"country_entries": "res://data/localization/country_affiliations.json",
}

var challenges: Dictionary = {}
var quirks: Dictionary = {}
var floors: Array = []
var story_events: Array = []
var sponsor_boost: Dictionary = {}
var country_entries: Array = []
var _load_errors: PackedStringArray = []


static func load_default() -> GameCatalog:
	var catalog := new()
	catalog.challenges = catalog._index_by_id(catalog._load_array(PATHS.challenges), PATHS.challenges)
	catalog.quirks = catalog._index_by_id(catalog._load_array(PATHS.quirks), PATHS.quirks)
	catalog.floors = catalog._load_array(PATHS.floors)
	catalog.story_events = catalog._load_array(PATHS.story_events)
	var boost = catalog._load_json(PATHS.sponsor_boost)
	if boost is Dictionary:
		catalog.sponsor_boost = boost
	else:
		catalog._load_errors.append("%s must contain an object" % PATHS.sponsor_boost)
	catalog.country_entries = catalog._load_array(PATHS.country_entries)
	return catalog


func validate() -> PackedStringArray:
	var errors := _load_errors.duplicate()
	for index in range(floors.size()):
		var floor_data = floors[index]
		if not floor_data is Dictionary:
			errors.append("floor entry %d must be an object" % (index + 1))
			continue
		var floor_number := int(floor_data.get("floor", index + 1))
		var challenge_id := str(floor_data.get("challenge_id", ""))
		if not challenges.has(challenge_id):
			errors.append("unknown challenge_id %s at floor %d" % [challenge_id, floor_number])
	var seen_codes := {}
	for entry in country_entries:
		if not entry is Dictionary:
			errors.append("country entry must be an object")
			continue
		var code := str(entry.get("code", ""))
		if code == "":
			errors.append("country entry missing code")
		elif seen_codes.has(code):
			errors.append("duplicate country code %s" % code)
		else:
			seen_codes[code] = true
	if sponsor_boost.get("id", "") == "":
		errors.append("sponsor boost missing id")
	return errors


func _load_array(path: String) -> Array:
	var value = _load_json(path)
	if value is Array:
		return value
	_load_errors.append("%s must contain an array" % path)
	return []


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_load_errors.append("%s does not exist" % path)
		return null
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(path))
	if error != OK:
		_load_errors.append("%s: %s" % [path, parser.get_error_message()])
		return null
	return parser.data


func _index_by_id(entries: Array, path: String) -> Dictionary:
	var indexed := {}
	for entry in entries:
		if not entry is Dictionary or str(entry.get("id", "")) == "":
			_load_errors.append("%s contains an entry without id" % path)
			continue
		var id := str(entry.id)
		if indexed.has(id):
			_load_errors.append("%s contains duplicate id %s" % [path, id])
		else:
			indexed[id] = entry
	return indexed
