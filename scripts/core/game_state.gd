extends Node
## Story memory: what has happened so far (flags), who Maren has talked to, play time,
## and the hidden devotion tally. Autoload "GameState". Saved/loaded via to_dict/from_dict.

signal flag_changed(id: String, value: Variant)

var flags: Dictionary = {}
var talked: Dictionary = {}
var devotion: int = 0
var crow_pool_index: Dictionary = {}  # crow_id -> next repeat line to play
var playtime_sec: float = 0.0
var counting: bool = false  # play time only advances while true


func _process(delta: float) -> void:
	if counting:
		playtime_sec += delta


func reset() -> void:
	flags = {}
	talked = {}
	devotion = 0
	crow_pool_index = {}
	playtime_sec = 0.0
	counting = false


func set_flag(id: String, value: Variant = true) -> void:
	if flags.has(id) and flags[id] == value:
		return
	flags[id] = value
	flag_changed.emit(id, value)


func get_flag(id: String, default: Variant = false) -> Variant:
	return flags.get(id, default)


func mark_talked(key: String) -> void:
	talked[key] = true


func has_talked(key: String) -> bool:
	return talked.get(key, false)


func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"talked": talked.duplicate(true),
		"devotion": devotion,
		"crow_pool_index": crow_pool_index.duplicate(true),
	}


## Restores state from to_dict() output (also tolerates JSON round-trips, where ints become floats).
func from_dict(d: Dictionary) -> void:
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	talked = (d.get("talked", {}) as Dictionary).duplicate(true)
	devotion = int(d.get("devotion", 0))
	var pool: Dictionary = {}
	for k in (d.get("crow_pool_index", {}) as Dictionary):
		pool[k] = int(d["crow_pool_index"][k])
	crow_pool_index = pool
