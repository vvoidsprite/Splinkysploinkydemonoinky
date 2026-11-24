extends Node2D
## The entrance hall. Edrin leads Maren out of the nook by the front door and the whole length
## of the hall to the stair at the right end.

const NpcWalker := preload("res://scripts/characters/npc_walker.gd")
## Edrin's route, as waypoints (cells): out of the nook, along the runner, then up beside the stair.
const NOOK_CELL := Vector2i(4, 11)
const HALL_ENTRY_CELL := Vector2i(4, 9)
const HALL_END_LANE_CELL := Vector2i(30, 9)
const STAIR_FOOT_CELL := Vector2i(30, 8)
const ROUTE_WAYPOINTS: Array[Vector2i] = [NOOK_CELL, HALL_ENTRY_CELL, HALL_END_LANE_CELL, STAIR_FOOT_CELL]

@onready var edrin: Node2D = $Edrin
@onready var door_exit: Area2D = $RoomExit
@onready var front_door: Area2D = $FrontDoor

var _walk_done := false


func _ready() -> void:
	_walk_done = GameState.get_flag("prologue.in_hall")
	GameState.set_flag("prologue.in_hall")
	if _walk_done:
		_place_edrin_at_stair()
		door_exit.enabled = true
	else:
		door_exit.enabled = false
		_lead_the_way.call_deferred()


func apply_state() -> void:
	if _walk_done:
		_place_edrin_at_stair()
		door_exit.enabled = true


func _place_edrin_at_stair() -> void:
	edrin.global_position = NavGrid.center_of(STAIR_FOOT_CELL)
	NpcWalker.face(edrin.get_node("Sprite"), "left")


## Every cell stepped through, from the cell after the first waypoint to the last.
func route_cells() -> Array:
	var cells: Array = []
	for i in range(1, ROUTE_WAYPOINTS.size()):
		var from: Vector2i = ROUTE_WAYPOINTS[i - 1]
		var to: Vector2i = ROUTE_WAYPOINTS[i]
		var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
		var c := from + step
		while true:
			cells.append(c)
			if c == to:
				break
			c += step
	return cells


func _lead_the_way() -> void:
	var mgr := get_tree().get_first_node_in_group("area_manager")
	while mgr != null and mgr.busy and is_inside_tree():
		await get_tree().process_frame
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.frozen = true
	var sprite: Node = edrin.get_node("Sprite")
	await NpcWalker.walk(edrin, sprite, route_cells())
	if not is_inside_tree():
		return
	NpcWalker.face(sprite, "left")
	_walk_done = true
	door_exit.enabled = true
	if player != null:
		player.frozen = false
