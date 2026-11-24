extends CharacterBody2D
## Maren, moving tile by tile (16px tiles, four directions) like The Witch's House.
## No physics sliding: each step glides from one tile centre to the next. A step that has
## started always finishes; the direction is only read when a new step begins.

signal step_finished(cell: Vector2i)

const TILE := 16.0
const DIRS := {
	"move_right": Vector2i.RIGHT,
	"move_left": Vector2i.LEFT,
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
}

@export var walk_speed := 90.0
@export var sprint_speed := 160.0

var frozen := false
## Set after an area transition: ignore movement input until all direction keys are released.
var hold_until_release := false
var can_interact := true
var sprinting := false

## The tile Maren stands on, or the tile she is walking into while a step is in progress.
var cell := Vector2i.ZERO
var moving := false
var facing_dir := Vector2i.DOWN

var _step_from := Vector2.ZERO
var _step_dir := Vector2i.ZERO
var _progress := 0.0
var _held: Array[Vector2i] = []  # held directions, newest last
var _probe := RectangleShape2D.new()

@onready var prompt: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	_probe.size = Vector2(NavGrid.PROBE, NavGrid.PROBE)
	cell = NavGrid.cell_of(global_position)
	global_position = NavGrid.center_of(cell)


func _physics_process(delta: float) -> void:
	if not moving and global_position != NavGrid.center_of(cell):
		place_at(global_position)  # someone moved her directly (tests, cutscenes)
	_update_held()
	var any_dir_pressed := false
	for action in DIRS:
		if Input.is_action_pressed(action):
			any_dir_pressed = true
	if hold_until_release and not any_dir_pressed:
		hold_until_release = false
	var blocked := frozen or Dialogue.is_open
	sprinting = Input.is_action_pressed("sprint") and not blocked and not hold_until_release
	var speed := sprint_speed if sprinting else walk_speed
	var dist := speed * delta

	if moving:
		var remaining := (1.0 - _progress) * TILE
		if dist >= remaining:
			dist -= remaining
			_arrive()
		else:
			_progress += dist / TILE
			dist = 0.0
	if not moving and not blocked and not hold_until_release:
		var d := _held_dir()
		if d != Vector2i.ZERO and _try_step(d):
			_progress = dist / TILE
	if moving:
		global_position = _step_from.lerp(NavGrid.center_of(cell), _progress)
		sprite.update_motion(Vector2(_step_dir) * speed, sprinting)
	else:
		sprite.update_motion(Vector2.ZERO, false)
	prompt.visible = not frozen and can_interact and not Dialogue.is_open \
		and not moving and _front_target() != null


## Put Maren on the tile containing p, cancelling any step in progress.
func place_at(p: Vector2) -> void:
	moving = false
	_progress = 0.0
	cell = NavGrid.cell_of(p)
	global_position = NavGrid.center_of(cell)
	sprite.update_motion(Vector2.ZERO, false)


func face(dir: String) -> void:
	facing_dir = _dir_from_name(dir)
	sprite.facing = dir
	sprite.update_motion(Vector2.ZERO, false)


func front_cell() -> Vector2i:
	return cell + facing_dir


func _dir_from_name(dir: String) -> Vector2i:
	match dir:
		"up":
			return Vector2i.UP
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.DOWN


func _name_from_dir(d: Vector2i) -> String:
	if d == Vector2i.UP:
		return "up"
	if d == Vector2i.LEFT:
		return "left"
	if d == Vector2i.RIGHT:
		return "right"
	return "down"


func _update_held() -> void:
	for action in DIRS:
		var d: Vector2i = DIRS[action]
		if Input.is_action_pressed(action):
			if not _held.has(d):
				_held.append(d)
		else:
			_held.erase(d)


func _held_dir() -> Vector2i:
	return _held.back() if not _held.is_empty() else Vector2i.ZERO


## Turn to face dir and, if the tile ahead is open, start walking into it.
func _try_step(dir: Vector2i) -> bool:
	face(_name_from_dir(dir))
	var ex: Array[RID] = [get_rid()]
	var space := get_world_2d().direct_space_state
	if NavGrid.tile_blocked(space, cell + dir, collision_mask, ex):
		return false
	_step_from = NavGrid.center_of(cell)
	_step_dir = dir
	cell += dir
	_progress = 0.0
	moving = true
	return true


func _arrive() -> void:
	global_position = NavGrid.center_of(cell)
	moving = false
	_progress = 0.0
	step_finished.emit(cell)


## The interactable on the tile Maren is facing, if any.
func _front_target() -> Area2D:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _probe
	q.transform = Transform2D(0.0, NavGrid.center_of(front_cell()))
	q.collision_mask = 4
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var best: Area2D = null
	var best_d := INF
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var a := hit.get("collider") as Area2D
		if a == null or not a.is_in_group("interactable") or not a.monitorable or not a.visible:
			continue
		var d := q.transform.origin.distance_squared_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if frozen or not can_interact or Dialogue.is_open or moving:
		return
	var target := _front_target()
	if target:
		get_viewport().set_input_as_handled()
		target.interact(self)
