extends SceneTree
## Dialogue box choices test. Run:
##   <godot> --path . --headless --fixed-fps 60 --script res://tests/test_dialogue_choices.gd

var fails := 0


func _initialize() -> void:
	_run()


func report(label: String, ok: bool) -> void:
	if not ok:
		fails += 1
	print(("PASS " if ok else "FAIL ") + label)


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	await process_frame


func _run() -> void:
	var box = (load("res://scenes/ui/dialogue_box.tscn") as PackedScene).instantiate()
	root.add_child(box)
	await process_frame
	box._conversations["t_choice"] = [
		{"speaker": "Crow", "text": "Shall I keep this one?",
		 "choices": [{"text": "Keep it", "value": "save"}, {"text": "Not now", "value": "no"}]},
		{"speaker": "Crow", "text": "Done."},
	]
	box._conversations["t_plain"] = [{"speaker": "", "text": "One."}, {"speaker": "", "text": "Two."}]
	var got: Array = []
	var done := [false]
	box.chose.connect(func(v): got.append(v))
	box.finished.connect(func(): done[0] = true)

	# C1 mashing interact: first press finishes typing, line is not skipped
	box.play("t_choice")
	await _press("interact")
	report("C1 first press finishes typing, choices shown", box.is_open and box._choosing and box.choice_label.visible and got.is_empty())
	await _press("interact")
	report("C2 second press selects first choice", got == ["save"] and box.last_choice == "save")
	# C3 chose fires before finished
	await _press("interact")
	await _press("interact")
	report("C3 conversation finished afterward", done[0] and not box.is_open)

	# C4 cursor down then confirm
	got.clear()
	done[0] = false
	box.play("t_choice")
	await _press("interact")
	await _press("ui_down")
	await _press("interact")
	report("C4 ui_down picks second choice", got == ["no"] and box.last_choice == "no")
	box.close()

	# C5 wraps and move_up works
	box.play("t_choice")
	await _press("interact")
	await _press("move_up")
	report("C5 move_up wraps to last", box._cursor == 1)
	box.close()

	# C6 plain conversations unchanged
	got.clear()
	done[0] = false
	box.play("t_plain")
	await _press("interact")
	report("C6 plain line has no choices", not box._choosing and not box.choice_label.visible)
	await _press("interact")
	await _press("interact")
	await _press("interact")
	report("C7 plain conversation finishes with no chose", done[0] and got.is_empty())

	print("DONE fails=%d" % fails)
	quit(1 if fails > 0 else 0)
