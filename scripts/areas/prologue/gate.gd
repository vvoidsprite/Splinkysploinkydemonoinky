extends Node2D
## The gate at dusk. Edrin waits at the door with a lamp; after he has spoken he leads Maren in.

const NpcWalker := preload("res://scripts/characters/npc_walker.gd")

## Edrin walks from his spot below the door up the steps to the door cell (14,21).
const EDRIN_ROUTE: Array[Vector2i] = [Vector2i(14, 22), Vector2i(14, 21)]

@onready var edrin: Area2D = $Edrin
@onready var door_exit: Area2D = $Exit


func _ready() -> void:
	edrin.talked.connect(_on_edrin_talked)


## Matches the story flags (Main calls this after entering).
func apply_state() -> void:
	var arrived: bool = GameState.get_flag("prologue.arrived")
	door_exit.enabled = arrived
	if arrived:
		_retire_edrin()


func _retire_edrin() -> void:
	edrin.visible = false
	edrin.set_deferred("monitorable", false)
	$Edrin/Block/Shape.set_deferred("disabled", true)


func _on_edrin_talked(id) -> void:
	if id != "edrin_arrival":
		return
	GameState.set_flag("prologue.arrived")
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.frozen = true
	edrin.set_deferred("monitorable", false)
	var sprite: Node = edrin.get_node("Sprite")
	NpcWalker.face(sprite, "up")
	await NpcWalker.walk(edrin, sprite, EDRIN_ROUTE)
	if not is_inside_tree():
		return
	var mgr := get_tree().get_first_node_in_group("area_manager")
	if player != null:
		player.frozen = false
	if mgr != null:
		mgr.go_to("entrance_hall", "start")
