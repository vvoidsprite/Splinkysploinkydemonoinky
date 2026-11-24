extends SceneTree
## Chaser pathing test on the 16px tile grid. Run after `--import`:
##   <godot> --path . --fixed-fps 60 --headless --script res://tests/test_chaser_pathing.gd
## One line per case, exit code 0 when everything passes, 1 otherwise.
## The reference is an independent 4-direction BFS over NavGrid.tile_blocked (live physics queries).

const SPEED := 110.0
const STALL_MAX_S := 0.3
const FRAME := 1.0 / 60.0

var fails := 0


func _initialize() -> void:
	_run()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func report(label: String, ok: bool, extra := "") -> void:
	if not ok:
		fails += 1
	print(("PASS " if ok else "FAIL ") + label + ("" if extra == "" else "  [" + extra + "]"))


func _make_area(path: String) -> Node2D:
	var area: Node2D = (load(path) as PackedScene).instantiate()
	root.add_child(area)
	return area


func _make_target() -> Node2D:
	var t := Node2D.new()
	root.add_child(t)
	return t


func _chaser_of(area: Node2D) -> CharacterBody2D:
	var kit := area.get_node_or_null("ChaseKit")
	if kit == null:
		kit = (load("res://scenes/chase/chase_kit.tscn") as PackedScene).instantiate()
		area.add_child(kit)
	var c: CharacterBody2D = kit.get_node("Chaser")
	c.speed = SPEED
	return c


# ---- independent reference ---------------------------------------------------------------

## Dictionary {region: Rect2i, solid: {Vector2i: true}} read live from the physics space.
func _ref_scan(area: Node2D, chaser: CharacterBody2D) -> Dictionary:
	var space := chaser.get_world_2d().direct_space_state
	var sz := Vector2i(area.get_meta("area_size"))
	var region := Rect2i(0, 0, sz.x / 16, sz.y / 16)
	var solid := {}
	for y in region.size.y:
		for x in region.size.x:
			if NavGrid.tile_blocked(space, Vector2i(x, y), 1):
				solid[Vector2i(x, y)] = true
	return {"region": region, "solid": solid}


func _ref_free(ref: Dictionary, c: Vector2i) -> bool:
	return (ref.region as Rect2i).has_point(c) and not ref.solid.has(c)


## Shortest 4-neighbour distance in steps, or -1 when unreachable.
func _bfs(ref: Dictionary, a: Vector2i, b: Vector2i) -> int:
	if not _ref_free(ref, a) or not _ref_free(ref, b):
		return -1
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		if c == b:
			return dist[c]
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = c + d
			if _ref_free(ref, n) and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	return -1


func _is_centre(v: float) -> bool:
	return absf(fposmod(v, 16.0) - 8.0) < 0.01


# ---- case runner -------------------------------------------------------------------------

## Runs one chase. Records steps, longest stall, per-frame rule violations.
func _chase(chaser: CharacterBody2D, target: Node2D, ref: Dictionary, from: Vector2i, to: Vector2i,
		max_time: float, mover: Callable = Callable()) -> Dictionary:
	target.global_position = NavGrid.center_of(to)
	chaser.global_position = NavGrid.center_of(from)
	var was_caught := [false]
	var cb := func(): was_caught[0] = true
	chaser.caught.connect(cb)
	chaser.start(target)
	var first_cell: Vector2i = chaser.cell
	var last_cell: Vector2i = chaser.cell
	var steps := 0
	var violations: Array[String] = []
	var hist: Array[Vector2] = [chaser.global_position]
	var still := 0
	var max_still := 0
	var t := 0.0
	var first_move_t := -1.0
	while chaser.active and t < max_time:
		await physics_frame
		t += FRAME
		if mover.is_valid():
			target.global_position = mover.call(t)
		var p := chaser.global_position
		if not (_is_centre(p.x) or _is_centre(p.y)):
			violations.append("off-axis %s at t=%.2f" % [p, t])
		if p.distance_to(hist[hist.size() - 1]) < 0.001:
			still += 1
			max_still = maxi(max_still, still)
		else:
			still = 0
			if first_move_t < 0.0:
				first_move_t = t
		hist.append(p)
		var c: Vector2i = chaser.cell
		if c != last_cell:
			steps += 1
			var d := c - last_cell
			if absi(d.x) + absi(d.y) != 1:
				violations.append("jump %s->%s" % [last_cell, c])
			if not _ref_free(ref, c):
				violations.append("blocked cell %s" % [c])
			last_cell = c
	chaser.caught.disconnect(cb)
	return {"caught": was_caught[0], "steps": steps, "max_still": max_still, "time": t,
			"violations": violations, "hist": hist, "first_cell": first_cell, "end_cell": chaser.cell,
			"first_move_t": first_move_t}


func _check_static(label: String, chaser: CharacterBody2D, target: Node2D, ref: Dictionary,
		from: Vector2i, to: Vector2i, max_time: float, expect_bfs := -1) -> void:
	var bfs := _bfs(ref, from, to)
	var r: Dictionary = await _chase(chaser, target, ref, from, to, max_time)
	var ok: bool = bfs > 0 and r.caught and r.steps == bfs - 1 and r.max_still <= int(STALL_MAX_S / FRAME) \
			and r.violations.is_empty() and (expect_bfs < 0 or bfs == expect_bfs)
	report(label, ok, "bfs=%d steps=%d caught=%s still=%d t=%.2f viol=%s" % [bfs, r.steps, r.caught,
			r.max_still, r.time, str(r.violations.slice(0, 2))])


func _build_box(parent: Node, tile: Vector2i) -> Array[Node]:
	var c := NavGrid.center_of(tile)
	var walls: Array[Node] = []
	for spec in [[Vector2(0, -16), Vector2(48, 16)], [Vector2(0, 16), Vector2(48, 16)],
			[Vector2(-16, 0), Vector2(16, 48)], [Vector2(16, 0), Vector2(16, 48)]]:
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		sb.position = c + spec[0]
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = spec[1]
		cs.shape = rs
		sb.add_child(cs)
		parent.add_child(sb)
		walls.append(sb)
	return walls


func _check_unreachable(label: String, area: Node2D, chaser: CharacterBody2D, target: Node2D,
		from: Vector2i, tile: Vector2i) -> void:
	var walls := _build_box(area, tile)
	await frames(3)
	var ref := _ref_scan(area, chaser)
	var r: Dictionary = await _chase(chaser, target, ref, from, tile, 7.0)
	var h: Array = r.hist
	var tail := 0.0
	for i in range(maxi(1, h.size() - 120), h.size()):
		tail += h[i].distance_to(h[i - 1])
	var near := chaser.global_position.distance_to(NavGrid.center_of(tile))
	report(label, _ref_free(ref, tile) and not r.caught and near <= 60.0 and tail == 0.0 and r.violations.is_empty(),
			"caught=%s dist=%.1f tail_motion=%.3f target_free=%s viol=%s" % [r.caught, near, tail,
			_ref_free(ref, tile), str(r.violations.slice(0, 2))])
	chaser.stop()
	for w in walls:
		area.remove_child(w)
		w.free()
	await frames(3)


func _run() -> void:
	var manor := _make_area("res://scenes/areas/manor_room.tscn")
	await frames(3)
	var target := _make_target()
	var chaser := _chaser_of(manor)
	var ref := _ref_scan(manor, chaser)

	# Solidity sanity.
	var pillar_b: Node2D = manor.get_node("Props/PillarB")
	var pb_cell := NavGrid.cell_of(pillar_b.global_position + Vector2(0, -8))
	report("PillarB cell is solid", not _ref_free(ref, pb_cell), "cell=%s pos=%s" % [pb_cell, pillar_b.global_position])
	report("(2,14) is free", _ref_free(ref, Vector2i(2, 14)))
	var grid := NavGrid.for_body(chaser, true)
	report("NavGrid agrees with reference on every manor cell", _grids_agree(grid, ref))

	await _check_static("1 PillarB detour (18,14)->(22,14)", chaser, target, ref, Vector2i(18, 14), Vector2i(22, 14), 6.0, 6)
	await _check_static("2 spawn to far corner (2,14)->(37,24)", chaser, target, ref, Vector2i(2, 14), Vector2i(37, 24), 12.0)
	await _check_static("3 pillar gap (23,13)->(29,7)", chaser, target, ref, Vector2i(23, 13), Vector2i(29, 7), 8.0)
	await _check_static("4 behind the cabinet (2,12)->(7,7)", chaser, target, ref, Vector2i(2, 12), Vector2i(7, 7), 8.0)

	# 5. Orbiting target (a plain Node2D).
	var centre := Vector2(384, 240)
	var orbit := func(t: float) -> Vector2:
		var a: float = t * 80.0 / 90.0
		return centre + Vector2(cos(a), sin(a)) * 90.0
	var r: Dictionary = await _chase(chaser, target, ref, Vector2i(6, 23), NavGrid.cell_of(orbit.call(0.0)), 8.0, orbit)
	report("5 orbiting target caught, no stall", r.caught and r.max_still <= int(STALL_MAX_S / FRAME)
			and r.violations.is_empty() and r.time < 8.0,
			"caught=%s still=%d t=%.2f viol=%s" % [r.caught, r.max_still, r.time, str(r.violations.slice(0, 2))])

	# 6. Spawn inside PillarA (12,8).
	var pa_cell := Vector2i(12, 8)
	report("6 precondition: (12,8) is solid", not _ref_free(ref, pa_cell))
	r = await _chase(chaser, target, ref, pa_cell, Vector2i(16, 18), 8.0)
	report("6a first cell is free", _ref_free(ref, r.first_cell), "first=%s" % [r.first_cell])
	report("6b moves within 0.5s and catches", r.caught and r.first_move_t >= 0.0 and r.first_move_t <= 0.5 \
			and r.violations.is_empty(), "first_move=%.2f caught=%s viol=%s" % [r.first_move_t, r.caught, str(r.violations.slice(0, 2))])

	# 7. Unreachable target in a sealed box around tile (31,20).
	await _check_unreachable("7 unreachable target (31,20): idles near box", manor, chaser, target, Vector2i(24, 23), Vector2i(31, 20))

	# 9. Speed: 9 steps along a clear row at 110 px/s.
	ref = _ref_scan(manor, chaser)
	var bfs := _bfs(ref, Vector2i(2, 14), Vector2i(12, 14))
	r = await _chase(chaser, target, ref, Vector2i(2, 14), Vector2i(12, 14), 5.0)
	var n: int = r.steps
	var expect := n * 16.0 / SPEED
	report("9 speed: %d steps take %d*16/110 s (+-1 frame)" % [n, n], r.caught and n == bfs - 1 and absf(r.time - expect) <= 1.5 * FRAME,
			"time=%.3f expect=%.3f" % [r.time, expect])

	# 8. Grounds. (The manor shares the physics space, so it goes first.)
	root.remove_child(manor)
	manor.free()
	await frames(3)
	var grounds := _make_area("res://scenes/areas/grounds_test.tscn")
	await frames(3)
	var gchaser := _chaser_of(grounds)
	var gtarget := _make_target()
	var gref := _ref_scan(grounds, gchaser)
	var dt: Node2D = grounds.get_node("Props/DeadTree1")
	var dc := NavGrid.cell_of(dt.global_position + Vector2(0, -8))
	report("8 DeadTree1 cell is solid", not _ref_free(gref, dc), "cell=%s" % [dc])
	await _check_static("8a grounds, detour around DeadTree1", gchaser, gtarget, gref, dc + Vector2i(-3, 0), dc + Vector2i(3, 0), 6.0)
	await _check_static("8b grounds, long crossing (3,18)->(68,32)", gchaser, gtarget, gref, Vector2i(3, 18), Vector2i(68, 32), 20.0)
	await _check_static("8c grounds, vertical detour around DeadTree1", gchaser, gtarget, gref, dc + Vector2i(0, -3), dc + Vector2i(0, 3), 6.0)
	await _check_unreachable("8d grounds unreachable target (43,31)", grounds, gchaser, gtarget, Vector2i(18, 28), Vector2i(43, 31))

	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)


func _grids_agree(grid: NavGrid, ref: Dictionary) -> bool:
	for y in (ref.region as Rect2i).size.y:
		for x in (ref.region as Rect2i).size.x:
			var c := Vector2i(x, y)
			if grid.is_free(c) != _ref_free(ref, c):
				return false
	return true
