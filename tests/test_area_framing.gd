extends SceneTree
## Camera framing for small maps, safe arrival on load, and the TreeBorder forest.
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_area_framing.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

var M: Node
var P: CharacterBody2D
var cam: Camera2D
var fails := 0
var GS: Node
const TreeBorder := preload("res://scripts/world/tree_border.gd")


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func check(label: String, cond: bool, extra := "") -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label + ("" if extra == "" else "  [" + extra + "]"))


func make_area(id: String, size: Vector2i, start: Vector2) -> void:
	var root := Node2D.new()
	root.name = id
	root.set_meta("area_size", size)
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	root.add_child(spawns)
	spawns.owner = root
	var m := Marker2D.new()
	m.name = "start"
	m.position = start
	spawns.add_child(m)
	m.owner = root
	# a solid strip along the west edge (x < 32), so a saved cell can land in a wall
	var wall := StaticBody2D.new()
	wall.name = "Wall"
	root.add_child(wall)
	wall.owner = root
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(32, size.y)
	cs.shape = rs
	cs.position = Vector2(16, size.y / 2.0)
	wall.add_child(cs)
	cs.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	var path := "user://test_area_%s.tscn" % id
	ResourceSaver.save(ps, path)
	root.free()
	M.register_area(id, path)


func limits() -> Array:
	return [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom]


func _initialize() -> void:
	_run()


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await frames(10)
	GS = root.get_node("GameState")
	M = current_scene
	P = M.get_node("World/Player")
	cam = P.get_node("Camera2D")

	# F1: a 320x256 map is centred, and the camera can't scroll.
	make_area("tiny", Vector2i(320, 256), Vector2(160, 136))
	M.enter_directly("tiny", "start")
	await frames(5)
	check("F1 limits for 320x256", limits() == [-160, -52, 480, 308], str(limits()))
	var c := cam.get_screen_center_position()
	check("F1 map centred on screen", c.is_equal_approx(Vector2(160, 128)), str(c))

	# F2: 464x624 centres horizontally and scrolls vertically.
	make_area("tall", Vector2i(464, 624), Vector2(232, 600))
	M.enter_directly("tall", "start")
	await frames(5)
	check("F2 limits for 464x624", limits() == [-88, 0, 552, 624], str(limits()))

	# F3: a big area keeps 0..size.
	M.enter_directly("manor_room", "start")
	await frames(5)
	var ms := Vector2i(M.current_area.get_meta("area_size"))
	check("F3 manor_room keeps 0..size", limits() == [0, 0, ms.x, ms.y], str(limits()))

	# F4: a save with a cell that isn't on the map lands Maren on a free cell inside the room.
	var data := {"area_id": "maren_room", "cell": [99, 99], "facing": "up", "playtime_sec": 1.0,
		"state": GS.to_dict()}
	check("F4 load accepted", M.load_game(data))
	await frames(6)
	var area_sz := Vector2(Vector2i(M.current_area.get_meta("area_size")))
	var pos := P.global_position
	var space: PhysicsDirectSpaceState2D = P.get_world_2d().direct_space_state
	check("F4 Maren inside the room", Rect2(Vector2.ZERO, area_sz).has_point(pos), str(pos))
	check("F4 Maren on a free cell", not NavGrid.tile_blocked(space, P.cell, P.collision_mask), str(P.cell))
	check("F4 Maren on a tile centre", pos == NavGrid.center_of(P.cell), str(pos))

	# F5: a cell inside a wall moves her to the nearest free cell; far from any free cell, the entrance.
	data = {"area_id": "tiny", "cell": [0, 5], "facing": "down", "playtime_sec": 1.0, "state": GS.to_dict()}
	check("F5 load accepted", M.load_game(data))
	await frames(6)
	check("F5 wall cell moved to the nearest free cell", P.cell == Vector2i(2, 5), str(P.cell))
	data["cell"] = [500, 500]
	check("F5 second load accepted", M.load_game(data))
	await frames(6)
	check("F5 far off-map falls back to the entrance", P.cell == NavGrid.cell_of(Vector2(160, 136)), str(P.cell))

	# F6: TreeBorder builds a backing and trees, with the same layout for the same seed.
	var host := Node2D.new()
	host.set_meta("area_size", Vector2i(320, 256))
	root.add_child(host)
	var tb_a: Node2D = TreeBorder.new()
	host.add_child(tb_a)
	await frames(2)
	var tb_b: Node2D = TreeBorder.new()
	host.add_child(tb_b)
	await frames(2)
	var sprites: Array = tb_a.get_children().filter(func(n): return n is Sprite2D)
	check("F6 trees created", sprites.size() > 100, str(sprites.size()))
	check("F6 backing made of 4 rects", tb_a.backing != null and tb_a.backing.get_child_count() == 4)
	check("F6 same seed, same layout", tb_a.layout() == tb_b.layout() and tb_a.layout().size() == sprites.size())
	var inside: Array = sprites.filter(func(s): return Rect2(0, 0, 320, 256).grow(-12.0).has_point(s.position))
	check("F6 no tree stands in the map", inside.is_empty(), str(inside.size()))
	tb_b.seed = 7
	check("F6 other seed, other layout", tb_a.layout() != tb_b.layout())
	var pines: int = tb_a.layout().filter(func(t): return t["region"] <= 2).size()
	check("F6 mostly pines", pines * 100 >= tb_a.layout().size() * 55, "%d of %d" % [pines, tb_a.layout().size()])

	# F7: undergrowth fringe and the south edge rule.
	var ug_a: Array = tb_a.undergrowth_layout()
	check("F7 undergrowth not empty", ug_a.size() > 20, str(ug_a.size()))
	var tb_c: Node2D = TreeBorder.new()
	host.add_child(tb_c)
	await frames(2)
	check("F7 undergrowth same seed, same layout", tb_c.undergrowth_layout() == ug_a)
	tb_c.seed = 7
	check("F7 undergrowth other seed, other layout", tb_c.undergrowth_layout() != ug_a)
	var map_r := Rect2(0, 0, 320, 256)
	var ug_in: Array = ug_a.filter(func(t): return map_r.has_point(t["feet"]))
	check("F7 no undergrowth feet inside the map", ug_in.is_empty(), str(ug_in.size()))
	var ug_far: Array = ug_a.filter(func(t): return not map_r.grow(30.0).has_point(t["feet"]))
	check("F7 undergrowth hugs the fringe", ug_far.is_empty(), str(ug_far.size()))
	var ug_node: Node = tb_a.get_node_or_null("Undergrowth")
	check("F7 Undergrowth node holds the sprites", ug_node != null and ug_node.get_child_count() == ug_a.size())
	var regs: Array[Rect2] = TreeBorder.DEFAULT_TREES
	var south: Array = tb_a.layout().filter(func(t): return t["feet"].y > 256.0)
	var low: Array = south.filter(func(t): return t["feet"].y - regs[t["region"]].size.y < 256.0 - 24.0)
	check("F7 south trees exist", south.size() > 10, str(south.size()))
	check("F7 south trees stay out of the bottom rows", low.is_empty(), str(low.size()))
	var kinds := {}
	for t in tb_a.layout():
		kinds[t["region"]] = true
	check("F7 forest mixes at least 6 kinds of tree", kinds.size() >= 6, str(kinds.size()))

	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
