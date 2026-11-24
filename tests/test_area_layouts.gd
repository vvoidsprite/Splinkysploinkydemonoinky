extends SceneTree
## Layouts of the gate, the entrance hall and Maren's room: walk paths, talk spots and spawns are
## free, edges and furniture are solid, every stand cell is reachable from the spawn, animated
## lights animate, every cut-out sprite region fits its sheet, border metadata is right, the hall
## and room are smaller than the view, and the hall has no free-standing pillar colliders.
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_area_layouts.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const GATE := "res://scenes/areas/prologue/gate.tscn"
const HALL := "res://scenes/areas/prologue/entrance_hall.tscn"
const ROOM := "res://scenes/areas/prologue/maren_room.tscn"
const FRAME_LOOP := "res://scripts/world/frame_loop.gd"
const VIEW := Vector2i(640, 360)

var fails := 0


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func check(label: String, cond: bool, extra := "") -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label + ("" if extra == "" else "  [" + extra + "]"))


func _initialize() -> void:
	run.call_deferred()


## Cells (x0..x1, y0..y1) inclusive.
func rect_cells(x0: int, x1: int, y0: int, y1: int) -> Array:
	var out := []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			out.append(Vector2i(x, y))
	return out


func blocked_list(space: PhysicsDirectSpaceState2D, cells: Array, exclude: Array[RID] = []) -> String:
	var bad := []
	for c in cells:
		if NavGrid.tile_blocked(space, c, 1, exclude):
			bad.append(str(c))
	return ", ".join(bad)


func open_list(space: PhysicsDirectSpaceState2D, cells: Array, exclude: Array[RID] = []) -> String:
	var bad := []
	for c in cells:
		if not NavGrid.tile_blocked(space, c, 1, exclude):
			bad.append(str(c))
	return ", ".join(bad)


## RIDs of the bodies under a node (a character standing there is not a wall).
func bodies_under(n: Node) -> Array[RID]:
	var out: Array[RID] = []
	if n == null:
		return out
	for b in n.find_children("*", "StaticBody2D", true, false):
		out.append((b as StaticBody2D).get_rid())
	return out


func lights_in(area: Node) -> Array:
	var out := []
	for n in area.find_children("*", "Sprite2D", true, false):
		var s := n.get_script() as Script
		if s != null and s.resource_path == FRAME_LOOP:
			out.append(n)
	return out


## Cells reachable from `start` over free cells inside the map (4-neighbour).
func flood(space: PhysicsDirectSpaceState2D, start: Vector2i, size: Vector2i, exclude: Array[RID]) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var cols := size.x / 16
	var rows := size.y / 16
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows or seen.has(n):
				continue
			if NavGrid.tile_blocked(space, n, 1, exclude):
				continue
			seen[n] = true
			queue.append(n)
	return seen


func spawn_cells(area: Node) -> Array:
	var out := []
	for m in area.get_node("Spawns").get_children():
		out.append(NavGrid.cell_of((m as Node2D).global_position))
	return out


## Shared checks: walkable and blocked cells, reachability, lights, regions, border, size.
func common(tag: String, area: Node2D, free: Array, solid: Array, stands: Array, size: Vector2i, border: String) -> void:
	await frames(3)
	var space := root.world_2d.direct_space_state
	var edrin := bodies_under(area.get_node_or_null("Edrin"))
	var spawns := spawn_cells(area)
	var all_free := free + stands + spawns
	var bad := blocked_list(space, all_free, edrin)
	check(tag + "1 walk path, talk spots and spawns are free", bad == "", "blocked: " + bad)
	var open := open_list(space, solid, edrin)
	check(tag + "2 edges and furniture are solid", open == "", "open: " + open)
	check(tag + "3 area_size is %s" % size, Vector2i(area.get_meta("area_size")) == size, str(area.get_meta("area_size")))
	check(tag + "4 border is '%s'" % border, str(area.get_meta("border", "")) == border, str(area.get_meta("border", "")))
	var reach := flood(space, spawns[0], size, edrin)
	var cut := []
	for c in stands:
		if not reach.has(c):
			cut.append(str(c))
	check(tag + "5 every stand cell is reachable from the spawn", cut.is_empty(), "unreached: " + ", ".join(cut))

	var lights := lights_in(area)
	var seen := {}
	for l in lights:
		var s := l as Sprite2D
		var ok: bool = s.texture != null and s.hframes * s.vframes >= s.frame_count and s.frame_count > 1
		check(tag + "6 light has texture and enough frames: " + str(s.get_path()), ok,
				"hframes %d vframes %d frame_count %d" % [s.hframes, s.vframes, s.frame_count])
		seen[s] = {s.frame: true}
	for i in 60:
		await process_frame
		for l in lights:
			seen[l][(l as Sprite2D).frame] = true
	for l in lights:
		check(tag + "7 light animates within 1s: " + str((l as Sprite2D).get_path()), seen[l].size() > 1, str(seen[l].keys()))

	var cuts := 0
	var bad_cuts := []
	for n in area.find_children("*", "Sprite2D", true, false):
		var s := n as Sprite2D
		if not s.region_enabled:
			continue
		cuts += 1
		if s.texture == null:
			bad_cuts.append(str(s.get_path()) + " has no texture")
			continue
		var sheet := Rect2(Vector2.ZERO, s.texture.get_size())
		if s.region_rect.size.x <= 0 or s.region_rect.size.y <= 0 or not sheet.encloses(s.region_rect):
			bad_cuts.append("%s %s outside %s" % [s.get_path(), s.region_rect, s.texture.get_size()])
	check(tag + "8 every cut-out region fits its sheet (%d checked)" % cuts, bad_cuts.is_empty(), "; ".join(bad_cuts))


func run() -> void:
	# --- Gate: column 14 is the walk from the spawn up to the door; rows 0-20 are the castle.
	var gate: Node2D = (load(GATE) as PackedScene).instantiate()
	root.add_child(gate)
	var gate_free := rect_cells(14, 14, 22, 37)
	var gate_solid := rect_cells(0, 28, 0, 20)
	for x in 29:
		if x != 14:
			gate_solid.append(Vector2i(x, 21))
	gate_solid.append(Vector2i(8, 23))  # bell post
	var gate_stands := [Vector2i(14, 24), Vector2i(8, 24), Vector2i(9, 34), Vector2i(23, 22)]
	await common("G", gate, gate_free, gate_solid, gate_stands, Vector2i(464, 624), "trees")
	check("G9 gate has a TreeBorder", gate.get_node_or_null("TreeBorder") != null)
	check("G10 gate has at least 2 animated lights", lights_in(gate).size() >= 2, str(lights_in(gate).size()))
	gate.queue_free()
	await frames(2)

	# --- Hall: row 9 runs the whole corridor; row 7 is wall except the stair cells.
	var hall: Node2D = (load(HALL) as PackedScene).instantiate()
	root.add_child(hall)
	var hall_free := rect_cells(2, 33, 9, 9) + rect_cells(2, 5, 12, 13)
	var hall_solid := []
	for x in 36:
		if x != 31 and x != 32:
			hall_solid.append(Vector2i(x, 7))
	var hall_stands := [Vector2i(4, 13), Vector2i(4, 8), Vector2i(21, 8), Vector2i(31, 8), Vector2i(32, 8)]
	await common("H", hall, hall_free, hall_solid, hall_stands, Vector2i(576, 256), "black")
	var hsize := Vector2i(hall.get_meta("area_size"))
	check("H9 hall is smaller than the 640x360 view", hsize.x < VIEW.x and hsize.y < VIEW.y, str(hsize))
	check("H10 hall has no TreeBorder", hall.get_node_or_null("TreeBorder") == null)
	check("H11 hall has at least 2 animated torches", lights_in(hall).size() >= 2, str(lights_in(hall).size()))
	var loose := []
	for b in hall.find_children("*", "StaticBody2D", true, false):
		var n := b as StaticBody2D
		var skip := false
		var p: Node = n
		while p != null and p != hall:
			if p.name == "Walls" or p.name == "Edrin":
				skip = true
			p = p.get_parent()
		if skip:
			continue
		var cy := NavGrid.cell_of(n.global_position).y
		if cy >= 8 and cy <= 13:
			loose.append(str(n.get_path()))
	check("H12 no free-standing bodies on the hall floor", loose.is_empty(), ", ".join(loose))
	var pillar_bodies := []
	for n in hall.find_children("Pillar*", "", true, false):
		if not n.find_children("*", "StaticBody2D", true, false).is_empty():
			pillar_bodies.append(str(n.get_path()))
	check("H13 wall pillars carry no colliders", pillar_bodies.is_empty(), ", ".join(pillar_bodies))
	hall.queue_free()
	await frames(2)

	# --- Maren's room: furniture blocks its cells; the floor in front of it is free.
	var room: Node2D = (load(ROOM) as PackedScene).instantiate()
	root.add_child(room)
	var room_free := rect_cells(2, 21, 7, 8) + rect_cells(2, 15, 9, 13) + rect_cells(16, 21, 10, 13)
	for c in [Vector2i(2, 9), Vector2i(18, 7), Vector2i(19, 7), Vector2i(20, 7), Vector2i(19, 8), Vector2i(20, 8)]:
		room_free.erase(c)
	var room_solid := rect_cells(16, 17, 6, 6) + [Vector2i(18, 6), Vector2i(2, 9)] \
			+ rect_cells(19, 20, 6, 9) \
			+ rect_cells(0, 23, 0, 5) + rect_cells(0, 1, 6, 15) + rect_cells(22, 23, 6, 15) + rect_cells(0, 23, 14, 15)
	var room_stands := [Vector2i(18, 7), Vector2i(3, 6), Vector2i(4, 6), Vector2i(7, 6), Vector2i(9, 6),
			Vector2i(11, 6), Vector2i(14, 6), Vector2i(10, 12)]
	await common("R", room, room_free, room_solid, room_stands, Vector2i(384, 256), "black")
	var rsize := Vector2i(room.get_meta("area_size"))
	check("R9 room is smaller than the 640x360 view", rsize.x < VIEW.x and rsize.y < VIEW.y, str(rsize))
	check("R10 room has no TreeBorder", room.get_node_or_null("TreeBorder") == null)
	room.queue_free()
	await frames(2)

	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
