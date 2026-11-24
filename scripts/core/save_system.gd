class_name SaveSystem
extends RefCounted
## Reads and writes the 20 save files: one readable JSON file per slot (slot_01.json .. slot_20.json).
## Damaged or unknown-version files read as "unreadable" and never crash. No autoload; static only.

const SLOT_COUNT := 20
const SAVE_VERSION := 1

static var save_dir := "user://saves/"


static func slot_path(n: int) -> String:
	return save_dir.path_join("slot_%02d.json" % n)


static func _valid_slot(n: int) -> bool:
	return n >= 1 and n <= SLOT_COUNT


## Writes data (stamped with the current version) to slot n via a temp file + rename.
static func save_slot(n: int, data: Dictionary) -> bool:
	if not _valid_slot(n):
		return false
	if DirAccess.make_dir_recursive_absolute(save_dir) != OK and not DirAccess.dir_exists_absolute(save_dir):
		return false
	var out: Dictionary = data.duplicate(true)
	out["version"] = SAVE_VERSION
	var path := slot_path(n)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true


## Returns the slot's data, or an empty dictionary if the slot is missing or damaged.
static func load_slot(n: int) -> Dictionary:
	return _read(n).get("data", {})


## {exists, damaged, area_label, playtime_sec, saved_at}
static func slot_summary(n: int) -> Dictionary:
	var s := {"exists": false, "damaged": false, "area_label": "", "playtime_sec": 0.0, "saved_at": ""}
	var r := _read(n)
	if r["status"] == "missing":
		return s
	s["exists"] = true
	if r["status"] == "damaged":
		s["damaged"] = true
		return s
	var d: Dictionary = r["data"]
	s["area_label"] = str(d.get("area_label", ""))
	s["playtime_sec"] = float(d.get("playtime_sec", 0.0))
	s["saved_at"] = str(d.get("saved_at", ""))
	return s


## True if at least one slot holds a file (damaged ones count: they can be seen and overwritten).
static func any_saves() -> bool:
	for n in range(1, SLOT_COUNT + 1):
		if FileAccess.file_exists(slot_path(n)):
			return true
	return false


## Internal: {status: "missing"|"damaged"|"ok", data: Dictionary}
static func _read(n: int) -> Dictionary:
	if not _valid_slot(n) or not FileAccess.file_exists(slot_path(n)):
		return {"status": "missing", "data": {}}
	var f := FileAccess.open(slot_path(n), FileAccess.READ)
	if f == null:
		return {"status": "damaged", "data": {}}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"status": "damaged", "data": {}}
	var d: Dictionary = json.data
	if typeof(d.get("version")) not in [TYPE_INT, TYPE_FLOAT] or int(d["version"]) != SAVE_VERSION:
		return {"status": "damaged", "data": {}}
	if not _valid_shape(d):
		return {"status": "damaged", "data": {}}
	return {"status": "ok", "data": d}


static func _is_num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


## True if the file has everything Main needs to restore it (so a loadable slot never half-fails).
static func _valid_shape(d: Dictionary) -> bool:
	if typeof(d.get("area_id")) != TYPE_STRING or str(d["area_id"]) == "":
		return false
	var c: Variant = d.get("cell")
	if typeof(c) != TYPE_ARRAY or (c as Array).size() != 2 or not _is_num(c[0]) or not _is_num(c[1]):
		return false
	if typeof(d.get("facing")) != TYPE_STRING:
		return false
	if typeof(d.get("state")) != TYPE_DICTIONARY:
		return false
	if d.has("playtime_sec") and not _is_num(d["playtime_sec"]):
		return false
	for k in ["area_label", "saved_at", "save_point"]:
		if d.has(k) and typeof(d[k]) != TYPE_STRING:
			return false
	return true
