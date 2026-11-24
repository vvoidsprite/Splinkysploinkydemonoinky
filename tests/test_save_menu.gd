extends SceneTree
## Save menu checks (row text, save/load mode picking, cancel, scrolling).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_save_menu.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const SS := preload("res://scripts/core/save_system.gd")
const MenuScript := preload("res://scripts/ui/save_menu.gd")

var fails := 0
var chosen: Array = []
var cancels := 0


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



func _key(menu: Node, action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	menu._input(e)


func _init() -> void:
	SS.save_dir = "user://test_menu_saves/"
	_wipe(SS.save_dir)
	SS.save_slot(2, {"area_id": "gate", "cell": [1, 2], "facing": "down", "state": {}, "area_label": "Hollowmere, Maren's room", "playtime_sec": 754.2, "saved_at": "2026-11-24T21:03:11"})
	var f := FileAccess.open(SS.slot_path(4), FileAccess.WRITE)
	f.store_string("garbage {")
	f.close()

	var row2: String = MenuScript.format_row(2, SS.slot_summary(2))
	check("M1 row text", row2 == "File 02   Hollowmere, Maren's room   0:12:34   2026-11-24 21:03")
	check("M1 empty row", MenuScript.format_row(3, SS.slot_summary(3)) == "File 03   (empty)")
	check("M1 unreadable row", MenuScript.format_row(4, SS.slot_summary(4)) == "File 04   (unreadable)")

	var menu: Node = load("res://scenes/ui/save_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu.slot_chosen.connect(func(s): chosen.append(s))
	menu.cancelled.connect(func(): cancels += 1)
	check("M2 in group save_menu", menu.is_in_group("save_menu"))

	# Load mode: cursor starts on first readable slot; empty/unreadable cannot be picked.
	menu.open("load")
	check("M3 load starts on first readable slot", menu.selected_slot() == 2)
	_key(menu, "ui_down")
	check("M3 cursor moves", menu.selected_slot() == 3)
	_key(menu, "interact")
	check("M3 empty slot not pickable in load", menu.is_open and chosen.is_empty())
	_key(menu, "ui_down")
	_key(menu, "interact")
	check("M3 unreadable slot not pickable in load", menu.is_open and chosen.is_empty())
	_key(menu, "ui_up")
	_key(menu, "ui_up")
	_key(menu, "interact")
	check("M3 readable slot chosen, menu closed", chosen == [2] and not menu.is_open)

	# Save mode: any slot, including empty and occupied, with no confirmation.
	menu.open("save")
	check("M4 save starts on slot 1", menu.selected_slot() == 1)
	_key(menu, "ui_up")
	check("M4 cursor wraps to slot 20", menu.selected_slot() == 20)
	check("M4 view scrolled to cursor", menu._top == 20 - MenuScript.VISIBLE_ROWS)
	_key(menu, "interact")
	check("M4 empty slot 20 chosen in save mode", chosen == [2, 20])
	menu.open("save")
	_key(menu, "ui_down")
	_key(menu, "interact")
	check("M4 occupied slot overwritten without asking", chosen == [2, 20, 2])

	# Cancel
	var closed_vals: Array = []
	menu.closed.connect(func(s): closed_vals.append(s))
	menu.open("save")
	_key(menu, "ui_cancel")
	check("M5 cancel closes and emits", not menu.is_open and cancels == 1 and closed_vals == [-1])

	# Closed menu ignores input
	_key(menu, "interact")
	check("M5 closed menu ignores input", chosen.size() == 3)

	menu.free()
	_wipe(SS.save_dir)
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
