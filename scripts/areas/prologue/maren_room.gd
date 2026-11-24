extends Node2D
## Maren's room, first night. Edrin says goodnight and locks her in; the moment she is alone the
## crow is on the sill. The candle puzzle opens the passage behind the mirror; walking into it
## ends the prologue (end card, then back to the title).

const NpcWalker := preload("res://scripts/characters/npc_walker.gd")
const LEFT_FLAG := "prologue.edrin_left"
const SOLVED_FLAG := "prologue.candles_solved"
const DONE_FLAG := "prologue.done"
## Edrin's way out as waypoint corners: from his spot (11,12) down to the door row, then along it
## to the door cell. `_exit_steps` expands the corners into single-cell steps.
const EDRIN_EXIT := [Vector2i(11, 13), Vector2i(10, 13)]

## How long the "End of the prologue" card stays before the title (tests shorten it).
var end_card_seconds := 3.0
var ending := false

@onready var edrin: Node2D = $Edrin
@onready var candles: Node2D = $Candles
@onready var passage: Area2D = $Passage

var _started := false


func _ready() -> void:
	GameState.flag_changed.connect(_on_flag_changed)
	passage.body_entered.connect(_on_passage_body)
	if not GameState.get_flag(LEFT_FLAG):
		_first_night.call_deferred()


## Matches the story flags (Main calls this after entering).
func apply_state() -> void:
	if GameState.get_flag(LEFT_FLAG):
		_retire_edrin()
	candles.apply_state()
	_set_mirror_open(GameState.get_flag(SOLVED_FLAG))


func _retire_edrin() -> void:
	edrin.visible = false
	$Edrin/Block/Shape.set_deferred("disabled", true)


func _set_mirror_open(open: bool) -> void:
	$MirrorBlock/Shape.set_deferred("disabled", open)
	passage.set_deferred("monitoring", open)
	$Opening.visible = open


## Single-cell steps from `from` through each EDRIN_EXIT corner in turn.
func _exit_steps(from: Vector2i) -> Array:
	var steps := []
	var at := from
	for corner: Vector2i in EDRIN_EXIT:
		while at != corner:
			var d := corner - at
			if d.x != 0:
				at.x += signi(d.x)
			else:
				at.y += signi(d.y)
			steps.append(at)
	return steps


func _first_night() -> void:
	if _started or GameState.get_flag(LEFT_FLAG):
		return
	_started = true
	var mgr := get_tree().get_first_node_in_group("area_manager")
	while mgr != null and mgr.busy and is_inside_tree():
		await get_tree().process_frame
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.frozen = true
		player.face("right")
	var sprite: Node = edrin.get_node("Sprite")
	NpcWalker.face(sprite, "left")
	Dialogue.play("edrin_goodnight")
	await Dialogue.finished
	if not is_inside_tree():
		return
	await NpcWalker.walk(edrin, sprite, _exit_steps(NavGrid.cell_of(edrin.global_position)))
	if not is_inside_tree():
		return
	var fade := create_tween()
	fade.tween_property(edrin, "modulate:a", 0.0, 0.5)
	await fade.finished
	if not is_inside_tree():
		return
	_retire_edrin()
	Dialogue.play("room_key_turns")
	await Dialogue.finished
	if not is_inside_tree():
		return
	# Alone. The crow (visible_flag = LEFT_FLAG) fades in, then the arrival is narrated.
	GameState.set_flag(LEFT_FLAG)
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	Dialogue.play("crow_room_arrival")
	await Dialogue.finished
	if player != null and is_instance_valid(player):
		player.frozen = false


func _on_flag_changed(id: String, value: Variant) -> void:
	if id == SOLVED_FLAG and value == true and is_inside_tree():
		_set_mirror_open(true)
		Dialogue.play("room_mirror_open")


func _on_passage_body(body: Node2D) -> void:
	if ending or not GameState.get_flag(SOLVED_FLAG):
		return
	if not body.is_in_group("player") or body.get("frozen") == true:
		return
	_end_prologue()


func _end_prologue() -> void:
	ending = true
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.frozen = true
	GameState.set_flag(DONE_FLAG)
	var card := CanvasLayer.new()
	card.name = "EndCard"
	card.layer = 80
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg)
	var label := Label.new()
	label.text = "End of the prologue"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	card.offset = Vector2.ZERO
	bg.modulate.a = 0.0
	label.modulate.a = 0.0
	add_child(card)
	var tw := create_tween().set_parallel()
	tw.tween_property(bg, "modulate:a", 1.0, 0.8)
	tw.tween_property(label, "modulate:a", 1.0, 0.8)
	await tw.finished
	await get_tree().create_timer(end_card_seconds).timeout
	var mgr := get_tree().get_first_node_in_group("area_manager")
	if mgr != null and mgr.has_method("return_to_title"):
		await mgr.return_to_title()
	card.queue_free()
	ending = false
