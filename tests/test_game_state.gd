extends SceneTree
## Story memory checks (flags, talked, devotion, play time, round trip, reset).
## Run: <godot> --path . --headless --fixed-fps 60 --script tests/test_game_state.gd
## Prints PASS/FAIL per check and "DONE fails=N"; exit code 1 on any failure.

var fails := 0


func check(label: String, cond: bool) -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + label)


func _init() -> void:
	var G: Node = load("res://scripts/core/game_state.gd").new()
	var seen := []
	G.flag_changed.connect(func(id, v): seen.append([id, v]))
	check("flag default false", G.get_flag("a.b") == false)
	check("flag custom default", G.get_flag("a.b", 5) == 5)
	G.set_flag("a.b")
	G.set_flag("a.b")
	check("flag set and signal once", G.get_flag("a.b") == true and seen.size() == 1)
	G.set_flag("n", 3)
	G.mark_talked("Room/Crow")
	check("talked", G.has_talked("Room/Crow") and not G.has_talked("Room/Edrin"))
	G.devotion = 2
	G.crow_pool_index["c"] = 1
	G._process(1.0)
	check("playtime frozen when not counting", G.playtime_sec == 0.0)
	G.counting = true
	G._process(1.5)
	check("playtime counts", is_equal_approx(G.playtime_sec, 1.5))
	var d: Dictionary = G.to_dict()
	var d2: Dictionary = JSON.parse_string(JSON.stringify(d))  # as a save file would
	var H: Node = load("res://scripts/core/game_state.gd").new()
	H.from_dict(d2)
	check("round trip via JSON", H.get_flag("a.b") == true and int(H.get_flag("n", 0)) == 3
		and H.has_talked("Room/Crow") and H.devotion == 2 and H.crow_pool_index["c"] == 1
		and int(H.crow_pool_index["c"]) == 1)
	var K: Node = load("res://scripts/core/game_state.gd").new()
	K.from_dict(d)
	check("direct round trip lossless", K.to_dict() == d)
	K.free()
	G.reset()
	check("reset clears", G.flags.is_empty() and G.talked.is_empty() and G.devotion == 0
		and G.playtime_sec == 0.0 and not G.counting and G.crow_pool_index.is_empty())
	G.free()
	H.free()
	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
