extends SceneTree
## Save crow checks (line cycling, save flow, decline, flag visibility, payload).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_save_crow.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const SS := preload("res://scripts/core/save_system.gd")

var fails := 0
var DLG: Node
var GS: Node


class FakePlayer:
	extends Node
	var frozen := false


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


func _press(target: Node, action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	target._input(e)


## Presses interact on the dialogue box until it closes (picks the first choice if one shows).
func _finish_dialogue() -> void:
	var guard := 0
	while DLG.is_open and guard < 600:
		_press(DLG, "interact")
		await process_frame
		guard += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	DLG = root.get_node("Dialogue")
	GS = root.get_node("GameState")
	var d := DLG
	SS.save_dir = "user://test_crow_saves/"
	_wipe(SS.save_dir)
	GS.reset()

	var menu: Node = load("res://scenes/ui/save_menu.tscn").instantiate()
	root.add_child(menu)
	var crow: Area2D = load("res://scenes/world/save_crow.tscn").instantiate()
	crow.crow_id = "crow_test"
	crow.visible_flag = "test.crow_on"
	crow.hidden_flag = "test.crow_off"
	root.add_child(crow)
	var player := FakePlayer.new()
	root.add_child(player)
	await process_frame

	var SC := load("res://scripts/world/save_crow.gd")
	SC.payload_provider = func(): return {"area_id": "test_room", "area_label": "Test", "cell": [1, 2], "facing": "down", "state": GS.to_dict()}

	# Visibility from flags
	check("C1 hidden before appear flag", not crow.visible and not crow.monitorable)
	GS.set_flag("test.crow_on")
	await create_timer(0.7).timeout
	check("C1 visible and talkable after appear flag", crow.visible and crow.monitorable)
	check("C1 in groups", crow.is_in_group("interactable") and crow.is_in_group("stateful"))

	# First visit: first conversation, then prompt
	var played: Array = []
	var orig_ids := {}
	check("C2 first id is crow_room_first", crow.next_conversation_id() == "crow_room_first")
	check("C2 then pool 1", crow.next_conversation_id() == "crow_room_repeat_1")
	check("C2 then pool 2", crow.next_conversation_id() == "crow_room_repeat_2")
	check("C2 then pool 3", crow.next_conversation_id() == "crow_room_repeat_3")
	check("C2 pool wraps to 1", crow.next_conversation_id() == "crow_room_repeat_1")
	GS.crow_pool_index.erase("crow_test")

	# Full interaction: accept save, pick slot 3
	crow.interact(player)
	await process_frame
	check("C3 player frozen during talk", player.frozen)
	check("C3 first conversation text shown", d.text_label.text.begins_with("There you are"))
	var guard := 0
	while not menu.is_open and guard < 600:
		_press(d, "interact")
		await process_frame
		guard += 1
	check("C3 save menu opened in save mode", menu.is_open and menu.mode == "save")
	_press(menu, "ui_down")
	_press(menu, "ui_down")
	_press(menu, "interact")
	await process_frame
	check("C3 saved text shown", d.is_open and d.text_label.text.begins_with("Kept"))
	await _finish_dialogue()
	await process_frame
	check("C3 player unfrozen after", not player.frozen and not crow.busy)
	var data: Dictionary = SS.load_slot(3)
	check("C3 slot 3 written with area_id", data.get("area_id", "") == "test_room")
	check("C3 save_point is crow id", data.get("save_point", "") == "crow_test")
	check("C3 pool index saved in state", int(data.get("state", {}).get("crow_pool_index", {}).get("crow_test", -1)) == 0)

	# Second visit uses the pool and can be declined
	crow.interact(player)
	await process_frame
	check("C4 second visit uses repeat pool", d.text_label.text.begins_with("Still here"))
	guard = 0
	while d.is_open and not d._choosing and guard < 600:
		_press(d, "interact")
		await process_frame
		guard += 1
	_press(d, "ui_down")
	_press(d, "interact")
	await process_frame
	check("C4 declined line shown", d.text_label.text.begins_with("Then I'll only watch"))
	await _finish_dialogue()
	check("C4 no menu opened on decline", not menu.is_open)
	check("C4 slot 1 still empty", not SS.slot_summary(1)["exists"])

	# Cancelling the menu plays the declined line and writes nothing
	crow.interact(player)
	await process_frame
	guard = 0
	while not menu.is_open and guard < 600:
		_press(d, "interact")
		await process_frame
		guard += 1
	_press(menu, "ui_cancel")
	await process_frame
	check("C5 cancel gives declined line", d.is_open and d.text_label.text.begins_with("Then I'll only watch"))
	await _finish_dialogue()
	check("C5 nothing written", not SS.slot_summary(1)["exists"])

	# A failed write is told to the player and never claimed as kept
	var good_dir: String = SS.save_dir
	var blocker := FileAccess.open("user://test_crow_blocked", FileAccess.WRITE)
	blocker.store_string("x")
	blocker.close()
	SS.save_dir = "user://test_crow_blocked/"
	crow.interact(player)
	await process_frame
	guard = 0
	while not menu.is_open and guard < 600:
		_press(d, "interact")
		await process_frame
		guard += 1
	_press(menu, "interact")
	await process_frame
	check("C7 failed write says so, not 'Kept'", d.is_open and d.text_label.text == SC.SAVE_FAILED_LINE
		and not d.text_label.text.begins_with("Kept"))
	await _finish_dialogue()
	await process_frame
	check("C7 player unfrozen and crow free after failed write", not player.frozen and not crow.busy)
	SS.save_dir = good_dir
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_crow_blocked"))

	# Vanish flag
	GS.set_flag("test.crow_off")
	await create_timer(0.7).timeout
	check("C6 vanished and not talkable", not crow.visible and not crow.monitorable)

	SC.payload_provider = Callable()
	player.free()
	crow.free()
	menu.free()
	_wipe(SS.save_dir)
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
