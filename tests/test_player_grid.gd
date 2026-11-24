extends SceneTree
## Tile-movement checks for Maren (16px grid, four directions, steps always finish).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_player_grid.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

const HOME := Vector2(392, 376)  # tile (24,23), open floor in the manor room

var D: Node
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


func release_all() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "sprint"]:
		Input.action_release(a)


func press_interact() -> void:
	var e := InputEventAction.new()
	e.action = "interact"
	e.pressed = true
	root.push_input(e)
	var r := InputEventAction.new()
	r.action = "interact"
	r.pressed = false
	root.push_input(r)


func settle() -> void:
	release_all()
	var n := 0
	while P.moving and n < 120:
		await frames(1)
		n += 1
	await frames(1)


func reset(at := HOME, dir := "down") -> void:
	release_all()
	P.frozen = false
	P.place_at(at)
	P.face(dir)
	await frames(3)


func hold(actions: Array, n: int) -> void:
	for a in actions:
		Input.action_press(a)
	await frames(n)


func on_centre(p: Vector2) -> bool:
	return is_equal_approx(fposmod(p.x, 16.0), 8.0) and is_equal_approx(fposmod(p.y, 16.0), 8.0)


func axis_on_centre(p: Vector2) -> bool:
	return is_equal_approx(fposmod(p.x, 16.0), 8.0) or is_equal_approx(fposmod(p.y, 16.0), 8.0)


func close_dialogue() -> void:
	var n := 0
	while D.is_open and n < 60:
		press_interact()
		n += 1
		await frames(2)


func _initialize() -> void:
	_run()


func _run() -> void:
	D = root.get_node("Dialogue")
	change_scene_to_file("res://scenes/main.tscn")
	await frames(10)
	M = current_scene
	P = M.get_node("World/Player")
	M.enter_directly("manor_room", "start")

	# P1: one tap is exactly one tile and lands on a tile centre.
	await reset()
	var s := P.global_position
	await hold(["move_right"], 1)
	await settle()
	var d := P.global_position - s
	check("P1 one tap = 16px right", is_equal_approx(d.x, 16.0) and is_equal_approx(d.y, 0.0), str(d))
	check("P1 lands on tile centre", on_centre(P.global_position), str(P.global_position))

	# P2: releasing mid-step still finishes the step.
	await reset()
	s = P.global_position
	await hold(["move_right"], 3)
	release_all()
	await frames(1)
	check("P2 still mid-step after release", P.moving and P.global_position.x < s.x + 16.0)
	await settle()
	check("P2 step finished (dx=16)", is_equal_approx(P.global_position.x - s.x, 16.0), str(P.global_position))

	# P3: held right moves every frame; ends on a tile.
	await reset()
	s = P.global_position
	Input.action_press("move_right")
	await frames(1)
	var prev := P.global_position.x
	var always_grows := true
	for i in 59:
		await frames(1)
		if P.global_position.x <= prev:
			always_grows = false
		prev = P.global_position.x
	await settle()
	var dx := P.global_position.x - s.x
	check("P3 x grows every frame while held", always_grows)
	check("P3 ends on a tile, 5-6 tiles", fposmod(dx, 16.0) == 0.0 and dx >= 80.0 and dx <= 96.0, str(dx))

	# P4: swapping direction mid-step: no mid-tile turn.
	await reset()
	s = P.global_position
	Input.action_press("move_right")
	await frames(4)
	Input.action_release("move_right")
	Input.action_press("move_down")
	var turn_ok := true
	var y_moved := false
	for i in 40:
		await frames(1)
		var p := P.global_position
		if not y_moved and not is_equal_approx(p.y, s.y):
			y_moved = true
			if not is_equal_approx(p.x, s.x + 16.0):
				turn_ok = false
		if not y_moved and p.x > s.x + 16.0 + 0.001:
			turn_ok = false
		if y_moved and not is_equal_approx(p.x, s.x + 16.0):
			turn_ok = false
	await settle()
	check("P4 finishes right tile before going down", turn_ok and y_moved, str(P.global_position))

	# P5: always on a tile centre line in at least one axis (also with a chord).
	await reset()
	Input.action_press("move_right")
	var line_ok := true
	for i in 60:
		await frames(1)
		line_ok = line_ok and axis_on_centre(P.global_position)
	Input.action_press("move_down")
	for i in 60:
		await frames(1)
		line_ok = line_ok and axis_on_centre(P.global_position)
	await settle()
	check("P5 never off the tile lines", line_ok and on_centre(P.global_position), str(P.global_position))

	# P6: blocked tiles only turn her.
	await reset(Vector2(392, 104), "down")
	s = P.global_position
	await hold(["move_up"], 10)
	await settle()
	check("P6 wall: no movement", P.global_position == s, str(P.global_position))
	check("P6 wall: faces up", P.facing_dir == Vector2i.UP and P.sprite.facing == "up")
	await reset(Vector2(344, 232), "down")  # right of PillarB (tile 20,14)
	s = P.global_position
	await hold(["move_left"], 10)
	await settle()
	check("P6 pillar: no movement", P.global_position == s, str(P.global_position))
	check("P6 pillar: faces left", P.facing_dir == Vector2i.LEFT and P.sprite.facing == "left")

	# P7: sprint covers clearly more ground.
	await reset()
	s = P.global_position
	await hold(["move_right"], 30)
	await settle()
	var walk_d := P.global_position.x - s.x
	await reset()
	s = P.global_position
	await hold(["move_right", "sprint"], 30)
	await settle()
	var sprint_d := P.global_position.x - s.x
	check("P7 sprint >= 1.6x walk", sprint_d >= 1.6 * walk_d, "%d vs %d" % [sprint_d, walk_d])
	check("P7 both whole tiles", fposmod(walk_d, 16.0) == 0.0 and fposmod(sprint_d, 16.0) == 0.0)

	# P8: dialogue and freezing only stop new steps.
	await reset()
	s = P.global_position
	D.play("mirror")
	await frames(3)
	await hold(["move_right"], 20)
	release_all()
	await frames(2)
	check("P8 dialogue open: no move", P.global_position == s and D.is_open, str(P.global_position))
	await close_dialogue()
	await frames(5)
	await reset()
	s = P.global_position
	await hold(["move_right"], 3)
	P.frozen = true
	release_all()
	await settle()
	check("P8 frozen mid-step: step completes", is_equal_approx(P.global_position.x - s.x, 16.0), str(P.global_position))
	var s2 := P.global_position
	await hold(["move_right"], 20)
	release_all()
	await frames(2)
	check("P8 frozen: then stops", P.global_position == s2)
	P.frozen = false

	# P9: only the tile she faces can be talked to (Edrin stands on tile 24,18).
	await reset(Vector2(392, 312), "down")
	press_interact()
	await frames(3)
	check("P9 facing away: nothing opens", not D.is_open)
	P.face("up")
	await frames(2)
	press_interact()
	await frames(3)
	check("P9 facing Edrin: dialogue opens", D.is_open)
	await close_dialogue()
	await frames(5)

	# P10: the chaser walks 8 tiles to a stopped Maren and catches her.
	await reset()
	var kit: Node = M.current_area.get_node("ChaseKit")
	var ch: CharacterBody2D = kit.get_node("Chaser")
	var caught := [false]
	ch.caught.connect(func(): caught[0] = true)
	ch.global_position = Vector2(264, 376)
	ch.speed = 110.0
	ch.start(P)
	var t := 0
	while not caught[0] and t < 200:
		await frames(1)
		t += 1
	var limit := int((8.0 * 16.0 / 110.0 + 0.5) * 60.0)
	var gap: Vector2i = (ch.cell - P.cell).abs()
	check("P10 chaser catches within time", caught[0] and t <= limit, "%d frames, limit %d" % [t, limit])
	check("P10 ends on or beside her tile", gap.x + gap.y <= 1, str(gap))
	ch.stop()

	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
