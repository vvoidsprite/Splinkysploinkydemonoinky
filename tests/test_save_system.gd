extends SceneTree
## Save file checks (slots, bounds, missing, damaged, any_saves, state round trip).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_save_system.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const SS := preload("res://scripts/core/save_system.gd")

var fails := 0


func check(label: String, cond: bool) -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label)


func _wipe(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs.path_join(f))
	DirAccess.remove_absolute(abs)


func _init() -> void:
	SS.save_dir = "user://test_saves/"
	_wipe(SS.save_dir)

	var G: Node = load("res://scripts/core/game_state.gd").new()
	G.set_flag("prologue.arrived")
	G.mark_talked("MarenRoom/SaveCrow")
	G.devotion = 2
	G.crow_pool_index["crow_maren_room"] = 1
	var data := {
		"version": 1,
		"saved_at": "2026-11-24T21:03:11",
		"playtime_sec": 754.5,
		"area_id": "maren_room",
		"area_label": "Hollowmere, Maren's room",
		"cell": [24, 20],
		"facing": "down",
		"save_point": "crow_maren_room",
		"state": G.to_dict(),
	}

	# S5 (empty part)
	check("S5 any_saves false on empty dir", not SS.any_saves())

	# S1
	check("S1 save slot 3 ok", SS.save_slot(3, data))
	var back: Dictionary = SS.load_slot(3)
	# JSON turns whole numbers into floats, so compare against the same data after a JSON pass.
	check("S1 load equals saved", back == JSON.parse_string(JSON.stringify(data)))
	check("S1 load keeps every field", back["area_id"] == "maren_room" and back["facing"] == "down"
		and back["save_point"] == "crow_maren_room" and int(back["cell"][0]) == 24 and int(back["cell"][1]) == 20)
	var sm: Dictionary = SS.slot_summary(3)
	check("S1 summary fields", sm["exists"] and not sm["damaged"] and sm["area_label"] == "Hollowmere, Maren's room"
		and is_equal_approx(sm["playtime_sec"], 754.5) and sm["saved_at"] == "2026-11-24T21:03:11")

	# S2
	check("S2 slot 0 refused", not SS.save_slot(0, data))
	check("S2 slot 21 refused", not SS.save_slot(21, data))
	check("S2 slot -1 refused", not SS.save_slot(-1, data))
	check("S2 slots 1 and 20 accepted", SS.save_slot(1, data) and SS.save_slot(20, data))
	check("S2 load out of range empty", SS.load_slot(21).is_empty())

	# S3
	check("S3 missing load empty", SS.load_slot(7).is_empty())
	var m: Dictionary = SS.slot_summary(7)
	check("S3 missing summary", not m["exists"] and not m["damaged"])

	# S4
	var f := FileAccess.open(SS.slot_path(5), FileAccess.WRITE)
	f.store_string("this is { not json")
	f.close()
	check("S4 garbage load empty", SS.load_slot(5).is_empty())
	var dm: Dictionary = SS.slot_summary(5)
	check("S4 garbage summary damaged", dm["exists"] and dm["damaged"])
	f = FileAccess.open(SS.slot_path(6), FileAccess.WRITE)
	f.store_string('{"version": 99, "area_label": "x"}')
	f.close()
	check("S4 unknown version damaged", SS.slot_summary(6)["damaged"] and SS.load_slot(6).is_empty())
	f = FileAccess.open(SS.slot_path(8), FileAccess.WRITE)
	f.store_string("[1, 2, 3]")
	f.close()
	check("S4 non-object json damaged", SS.slot_summary(8)["damaged"])
	check("S4 no temp file left behind", not FileAccess.file_exists(SS.slot_path(3) + ".tmp"))

	# S7: right version but wrong shape reads as unreadable
	var bad_cases := {
		9: {"version": 1, "area_id": "gate", "cell": [1], "facing": "down", "state": {}},
		10: {"version": 1, "area_id": "gate", "cell": ["a", "b"], "facing": "down", "state": {}},
		11: {"version": 1, "area_id": "gate", "cell": [1, 2], "facing": "down", "state": []},
		12: {"version": 1, "cell": [1, 2], "facing": "down", "state": {}},
		13: {"version": 1, "area_id": "gate", "cell": [1, 2], "state": {}},
		14: {"version": 1, "area_id": "gate", "cell": [1, 2], "facing": "down", "state": {}, "playtime_sec": "x"},
	}
	for n in bad_cases:
		f = FileAccess.open(SS.slot_path(n), FileAccess.WRITE)
		f.store_string(JSON.stringify(bad_cases[n]))
		f.close()
		check("S7 bad shape slot %d unreadable" % n, SS.slot_summary(n)["damaged"] and SS.load_slot(n).is_empty())
	f = FileAccess.open(SS.slot_path(15), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "area_id": "gate", "cell": [1, 2], "facing": "down", "state": {}}))
	f.close()
	check("S7 minimal good file still loadable", not SS.slot_summary(15)["damaged"] and not SS.load_slot(15).is_empty())

	# S5 (after save)
	check("S5 any_saves true after save", SS.any_saves())

	# S6
	var H: Node = load("res://scripts/core/game_state.gd").new()
	H.from_dict(back["state"])
	check("S6 state survives file round trip", H.get_flag("prologue.arrived") == true
		and H.has_talked("MarenRoom/SaveCrow") and H.devotion == 2
		and int(H.crow_pool_index["crow_maren_room"]) == 1)
	var K: Node = load("res://scripts/core/game_state.gd").new()
	K.from_dict(G.to_dict())
	check("S6 from_dict(to_dict()) lossless", K.to_dict() == G.to_dict())

	G.free()
	H.free()
	K.free()
	_wipe(SS.save_dir)
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
