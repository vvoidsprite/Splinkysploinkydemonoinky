extends SceneTree
## Gate (compact yard, cells per docs/plans/compact-areas.md) and entrance hall (long hall): scenes load, Edrin leads Maren in, flags are set, exits work.
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_prologue_gate_hall.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

var M: Node
var P: CharacterBody2D
var fails := 0


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func check(label: String, cond: bool, extra := "") -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label + ("" if extra == "" else "  [" + extra + "]"))


func _initialize() -> void:
	root.add_child.call_deferred((load("res://scenes/main.tscn") as PackedScene).instantiate())
	await process_frame
	await process_frame
	run.call_deferred()


func run() -> void:
	M = root.get_node("Main")
	P = M.get_node("World/Player")
	var G = root.get_node("GameState")
	G.reset()
	M.enter_directly("gate", "start")
	await frames(5)
	check("F1 gate loads", M.current_id == "gate" and M.current_area.get_meta("area_label") == "Hollowmere, the gate")
	check("F2 gate spawn on a free tile facing up", P.cell == Vector2i(14, 37) and P.facing_dir == Vector2i.UP, str(P.cell))
	for s in ["Props/LilyCup/Interact", "Props/BellPost/Interact", "CathedralLook", "Edrin"]:
		check("F3 gate has " + s, M.current_area.get_node_or_null(s) != null)
	check("F4 gate exit locked until Edrin speaks", not M.current_area.get_node("Exit").enabled)
	check("F5 prologue.arrived unset", not G.get_flag("prologue.arrived"))
	# Walk up to Edrin and talk.
	var edrin: Area2D = M.current_area.get_node("Edrin")
	P.place_at(NavGrid.center_of(Vector2i(14, 24)))
	P.face("up")
	await frames(3)
	check("F6 Edrin is the front target", P._front_target() == edrin)
	edrin.interact(P)
	await frames(3)
	var D = root.get_node("Dialogue")
	var n := 0
	while D.is_open and n < 200:
		var e := InputEventAction.new()
		e.action = "interact"
		e.pressed = true
		root.push_input(e)
		var r := InputEventAction.new()
		r.action = "interact"
		r.pressed = false
		root.push_input(r)
		n += 1
		await frames(3)
	check("F7 arrival dialogue finished", not D.is_open)
	await frames(2)
	check("F8 prologue.arrived set", G.get_flag("prologue.arrived"))
	n = 0
	while M.current_id == "gate" and n < 600:
		await frames(1)
		n += 1
	await frames(5)
	# entrance_hall: Main.go_to may fade; wait for the area swap
	n = 0
	while M.current_id != "entrance_hall" and n < 120:
		await frames(1)
		n += 1
	check("F9 Edrin led her to the hall", M.current_id == "entrance_hall")
	await frames(20)
	check("F10 prologue.in_hall set", G.get_flag("prologue.in_hall"))
	var hall: Node2D = M.current_area
	check("F11 hall label", hall.get_meta("area_label") == "Hollowmere, the hall")
	check("F12 player frozen while Edrin walks", P.frozen)
	check("F13 room exit locked during the walk", not hall.get_node("RoomExit").enabled)
	n = 0
	while P.frozen and n < 900:
		await frames(1)
		n += 1
	check("F14 walk finished and player free", not P.frozen, str(n))
	check("F15 Edrin at the door", NavGrid.cell_of(hall.get_node("Edrin").global_position) == Vector2i(30, 8), str(hall.get_node("Edrin").global_position))
	check("F16 room exit enabled", hall.get_node("RoomExit").enabled)
	for s in ["Hooks", "HymnBoard", "FrontDoor"]:
		check("F17 hall has " + s, hall.get_node_or_null(s) != null)
	# Front door: face it and check it is interactable (locked).
	P.place_at(NavGrid.center_of(Vector2i(4, 13)))
	P.face("down")
	await frames(3)
	check("F18 front door is the target", P._front_target() == hall.get_node("FrontDoor"))
	# Hooks reachable
	P.place_at(NavGrid.center_of(Vector2i(4, 8)))
	P.face("up")
	await frames(3)
	check("F19 hooks are the target", P._front_target() == hall.get_node("Hooks"), str(P._front_target()))
	P.place_at(NavGrid.center_of(Vector2i(21, 8)))
	P.face("up")
	await frames(3)
	check("F20 hymn board is the target", P._front_target() == hall.get_node("HymnBoard"), str(P._front_target()))
	# Gate lookables reachable (re-enter the gate through the cache-free path)
	M.enter_directly("gate", "start")
	await frames(5)
	var gate: Node2D = M.current_area
	for t in [[Vector2i(9, 34), "up", "Props/LilyCup/Interact"], [Vector2i(8, 24), "up", "Props/BellPost/Interact"], [Vector2i(23, 22), "up", "CathedralLook"]]:
		P.place_at(NavGrid.center_of(t[0]))
		P.face(t[1])
		await frames(3)
		check("F21 gate target " + t[2], P._front_target() == gate.get_node(t[2]), str(P._front_target()))
	# Gate layout: size, forest ring, blocked castle front, open column 14 down the path.
	check("F22 gate is 464x624 with a tree border", gate.get_meta("area_size") == Vector2i(464, 624) and gate.get_meta("border") == "trees" and gate.get_node_or_null("TreeBorder") != null)
	var space: PhysicsDirectSpaceState2D = gate.get_world_2d().direct_space_state
	var bad_free := []
	for y in range(0, 21):
		for x in [0, 14, 28]:
			if not NavGrid.tile_blocked(space, Vector2i(x, y)):
				bad_free.append(Vector2i(x, y))
	for x in 29:
		if x != 14 and not NavGrid.tile_blocked(space, Vector2i(x, 21)):
			bad_free.append(Vector2i(x, 21))
	check("F23 castle front rows 0-20 and row 21 (except col 14) are blocked", bad_free.is_empty(), str(bad_free))
	var bad_open := []
	for y in range(21, 38):
		if NavGrid.tile_blocked(space, Vector2i(14, y), 1, [gate.get_node("Edrin/Block").get_rid()]):
			bad_open.append(y)
	check("F24 column 14 is walkable from row 21 to the spawn", bad_open.is_empty(), str(bad_open))
	check("F25 Edrin's gate route ends at the door cell", gate.EDRIN_ROUTE[-1] == Vector2i(14, 21))
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
