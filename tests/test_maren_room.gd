extends SceneTree
## Maren's room: New Game -> gate -> hall -> room is reachable; Edrin's goodnight and the crow's
## appearance; candle puzzle (wrong order resets, old order opens the mirror); save/load restore;
## the passage ends the prologue (end card, back to title).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_maren_room.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const SS := preload("res://scripts/core/save_system.gd")

var M: Node
var P: CharacterBody2D
var D: Node
var G: Node
var fails := 0


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func check(label: String, cond: bool, extra := "") -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label + ("" if extra == "" else "  [" + extra + "]"))


func press_interact() -> void:
	var e := InputEventAction.new()
	e.action = "interact"
	e.pressed = true
	root.push_input(e)
	var r := InputEventAction.new()
	r.action = "interact"
	r.pressed = false
	root.push_input(r)


## Presses interact through any open dialogue for up to n frames (stops once it is closed for good).
func pump(n: int) -> void:
	var idle := 0
	for i in n:
		if D.is_open:
			idle = 0
			press_interact()
		else:
			idle += 1
			if idle > 12:
				return
		await frames(2)


func wait_until(cond: Callable, max_frames: int) -> bool:
	var n := 0
	while not cond.call() and n < max_frames:
		await frames(1)
		n += 1
	return cond.call()


func wipe(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs.path_join(f))
	DirAccess.remove_absolute(abs)


func candle(room: Node, word: String) -> Node:
	for c in room.get_node("Candles").candles():
		if c.word == word:
			return c
	return null


## Reads a candle's plaque and lights it, clicking through every dialogue it opens.
func light(room: Node, word: String) -> void:
	candle(room, word).interact(P)
	await frames(2)
	await pump(160)


func _initialize() -> void:
	root.add_child.call_deferred((load("res://scenes/main.tscn") as PackedScene).instantiate())
	await process_frame
	await process_frame
	run.call_deferred()


func run() -> void:
	M = root.get_node("Main")
	P = M.get_node("World/Player")
	D = root.get_node("Dialogue")
	G = root.get_node("GameState")
	SS.save_dir = "user://test_maren_saves/"
	wipe(SS.save_dir)

	# --- New Game -> gate -> hall -> room ---
	M.start_new_game()
	await wait_until(func(): return M.current_id == "gate" and not M.busy, 240)
	check("R1 new game lands in the gate", M.current_id == "gate")
	await frames(5)
	var gate: Node2D = M.current_area
	var edrin_g: Area2D = gate.get_node("Edrin")
	P.place_at(NavGrid.center_of(Vector2i(14, 24)))
	P.face("up")
	await frames(3)
	edrin_g.interact(P)
	await frames(3)
	await pump(300)
	check("R2 gate leads to the hall", await wait_until(func(): return M.current_id == "entrance_hall" and not M.busy, 900))
	var hall: Node2D = M.current_area
	await wait_until(func(): return hall.get_node("RoomExit").enabled and not P.frozen, 1200)
	check("R3 hall door points at Maren's room", hall.get_node("RoomExit").target_area == "maren_room" and hall.get_node("RoomExit").enabled)
	P.place_at(NavGrid.center_of(Vector2i(31, 8)))
	P.face("up")
	Input.action_press("move_up")
	var in_room: bool = await wait_until(func(): return M.current_id == "maren_room" and not M.busy, 300)
	Input.action_release("move_up")
	check("R4 walking through the hall door reaches Maren's room", in_room)
	if not in_room:
		print("DONE fails=%d" % fails)
		quit(1)
		return

	# --- First night ---
	var room: Node2D = M.current_area
	var crow = room.get_node("SaveCrow")
	check("R5 room label", room.get_meta("area_label") == "Hollowmere, Maren's room")
	await frames(3)
	check("R5b small bedroom, black border", room.get_meta("area_size") == Vector2i(384, 256) and room.get_meta("border") == "black")
	# Furniture blocks its cells; every other floor cell (cols 2-21, rows 6-13) is reachable from the spawn.
	var space := room.get_world_2d().direct_space_state
	var furniture: Array[Vector2i] = [Vector2i(16, 6), Vector2i(17, 6), Vector2i(18, 6), Vector2i(19, 6), Vector2i(20, 6),
		Vector2i(19, 7), Vector2i(20, 7), Vector2i(19, 8), Vector2i(20, 8), Vector2i(19, 9), Vector2i(20, 9), Vector2i(2, 9)]
	var furniture_ok := true
	for c in furniture:
		furniture_ok = furniture_ok and NavGrid.tile_blocked(space, c)
	check("R5c bed, chest, wardrobe, nightstand and washstand block their cells", furniture_ok)
	var seen := {Vector2i(10, 12): true}
	var queue: Array[Vector2i] = [Vector2i(10, 12)]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 2 or n.x > 21 or n.y < 6 or n.y > 13 or seen.has(n) or NavGrid.tile_blocked(space, n):
				continue
			seen[n] = true
			queue.append(n)
	var unreachable := []
	for y in range(6, 14):
		for x in range(2, 22):
			var c := Vector2i(x, y)
			if not furniture.has(c) and c != Vector2i(11, 12) and not seen.has(c):
				unreachable.append(c)
	check("R5d every free floor cell is reachable from the spawn", unreachable.is_empty(), str(unreachable))
	check("R6 spawn on the door side", P.cell == Vector2i(10, 12), str(P.cell))
	check("R7 crow invisible and not talkable while Edrin is here", not crow.visible and not crow.monitorable)
	check("R8 Edrin is in the room, Maren frozen for the goodnight", room.get_node("Edrin").visible and P.frozen and D.is_open)
	check("R9 edrin_left not yet set", not G.get_flag("prologue.edrin_left"))
	var lines := 0
	while D.is_open and lines < 80:
		press_interact()
		lines += 1
		await frames(3)
	check("R10 goodnight dialogue finished", not D.is_open)
	check("R10b key has not turned yet while Edrin walks out", room.get_node("Edrin").visible and not G.get_flag("prologue.edrin_left"))
	check("R10c Edrin fades out at the door", await wait_until(func(): return room.get_node("Edrin").modulate.a < 0.9 and room.get_node("Edrin").visible, 240))
	check("R11a key turns only after Edrin is gone", await wait_until(func(): return D.is_open, 240) and not room.get_node("Edrin").visible and not G.get_flag("prologue.edrin_left") and str(D._lines[0].text).begins_with("The key turns"))
	check("R11b crow not yet there while the key turns", not crow.visible)
	var guard := 0
	while D.is_open and guard < 20:
		press_interact()
		guard += 1
		await frames(3)
	check("R11 edrin_left is set once the key has turned", await wait_until(func(): return G.get_flag("prologue.edrin_left"), 240))
	check("R12 Edrin gone", not room.get_node("Edrin").visible)
	check("R13 crow visible and talkable the moment she is alone", crow.visible and await wait_until(func(): return crow.monitorable, 60))
	check("R13b arrival is narrated automatically", await wait_until(func(): return D.is_open, 120) and str(D._lines[0].text).begins_with("Something taps"))
	check("R13c Maren still frozen during the arrival", P.frozen)
	await pump(60)
	check("R14 Maren free again", await wait_until(func(): return not P.frozen, 120))

	# --- Examinables ---
	var targets := {
		"Prayer": [Vector2i(18, 7), "up"],
		"SillCarving": [Vector2i(3, 6), "up"],
		"Mirror": [Vector2i(14, 6), "up"],
		"Door": [Vector2i(10, 12), "down"],
		"SaveCrow": [Vector2i(4, 6), "up"],
		"Candles/Obey": [Vector2i(7, 6), "up"],
		"Candles/Endure": [Vector2i(9, 6), "up"],
		"Candles/Give": [Vector2i(11, 6), "up"],
	}
	for k in targets:
		P.place_at(NavGrid.center_of(targets[k][0]))
		P.face(targets[k][1])
		await frames(3)
		check("R15 front target is " + k, P._front_target() == room.get_node(k), str(P._front_target()))
	check("R16 crow first talk then repeat pool", crow.next_conversation_id() == "crow_room_first" and crow.next_conversation_id() == "crow_room_repeat_1" and crow.next_conversation_id() == "crow_room_repeat_2")
	G.crow_pool_index.erase("crow_maren_room")
	crow.get_script().payload_provider = M.build_save_data
	var payload: Dictionary = crow.build_payload()
	check("R17 crow payload names the room and the crow", payload.get("area_id") == "maren_room" and payload.get("save_point") == "crow_maren_room")
	check("R18 mirror blocked before the puzzle", NavGrid.tile_blocked(room.get_world_2d().direct_space_state, Vector2i(14, 5)))

	# --- Candle puzzle: the Order's order fails ---
	await light(room, "OBEY")
	check("R19 OBEY lit after reading its plaque", candle(room, "OBEY").lit)
	await light(room, "ENDURE")
	await light(room, "GIVE")
	var cr: Node = room.get_node("Candles")
	check("R20 wrong order: not solved", not G.get_flag("prologue.candles_solved"))
	check("R21 wrong order: candles reset and ready again", cr.candles().all(func(c): return not c.lit) and not cr.locked and cr.sequence.is_empty())
	check("R22 crow still there", crow.visible)

	# --- Save at the crow, then the old order ---
	SS.save_slot(1, payload)

	await light(room, "GIVE")
	await light(room, "ENDURE")
	check("R23 two candles in the old order: still not solved", not G.get_flag("prologue.candles_solved"))
	await light(room, "OBEY")
	check("R24 old order sets candles_solved", G.get_flag("prologue.candles_solved"))
	await frames(80)
	check("R25 crow vanishes", not crow.visible and not crow.monitorable)
	var feather: Area2D = room.get_node("Feather")
	check("R26 feather left and talkable", feather.visible and feather.monitorable)
	check("R27 mirror open: cloth gone, way free", not room.get_node("Mirror").visible and not NavGrid.tile_blocked(room.get_world_2d().direct_space_state, Vector2i(14, 5)) and room.get_node("Passage").monitoring)
	check("R28 candles stay lit", cr.candles().all(func(c): return c.lit))
	P.place_at(NavGrid.center_of(Vector2i(4, 6)))
	P.face("up")
	await frames(3)
	check("R29 feather is the front target", P._front_target() == feather, str(P._front_target()))

	# --- Load the crow save: before the puzzle ---
	check("R30 load_game restores the room", M.load_game(SS.load_slot(1)))
	await frames(5)
	room = M.current_area
	cr = room.get_node("Candles")
	crow = room.get_node("SaveCrow")
	check("R31 loaded into Maren's room", M.current_id == "maren_room")
	check("R32 Edrin absent, crow present, candles unlit", not room.get_node("Edrin").visible and crow.visible and cr.candles().all(func(c): return not c.lit))
	check("R33 loaded: puzzle not solved, feather hidden, mirror closed", not G.get_flag("prologue.candles_solved") and not room.get_node("Feather").visible and room.get_node("Mirror").visible)
	check("R34 loading does not replay the goodnight", not D.is_open and not P.frozen)

	# --- Solve again and walk into the passage ---
	await light(room, "GIVE")
	await light(room, "ENDURE")
	await light(room, "OBEY")
	await frames(10)
	check("R35 solved again after load", G.get_flag("prologue.candles_solved"))
	room.end_card_seconds = 0.2
	P.place_at(NavGrid.center_of(Vector2i(14, 7)))
	P.face("up")
	await frames(3)
	Input.action_press("move_up")
	check("R36 walking into the passage sets prologue.done", await wait_until(func(): return G.get_flag("prologue.done"), 180))
	Input.action_release("move_up")
	check("R37 end card shown", room.get_node_or_null("EndCard") != null and room.get_node("EndCard").get_child(1).text == "End of the prologue")
	check("R38 then back at the title", await wait_until(func(): return M.current_id == "" and not M.busy, 400))

	wipe(SS.save_dir)
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
