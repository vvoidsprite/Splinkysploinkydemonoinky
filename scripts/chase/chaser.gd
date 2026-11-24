extends CharacterBody2D
## The folded statue. Walks the shortest 4-direction route over the 16px tile grid to the player's
## tile, one tile at a time at a constant pixel speed. Catches by reaching (or stepping onto) the
## player's tile.

signal caught

const TILE := 16.0

var speed := 90.0
var active := false
## The tile it is standing on, or heading to while a step is in progress.
var cell := Vector2i.ZERO
var moving := false

var _player: Node2D
var _grid: NavGrid
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _progress := 0.0


func start(player: Node2D) -> void:
	_player = player
	_grid = NavGrid.for_body(self, true)
	cell = NavGrid.cell_of(global_position)
	if _grid != null:
		var free := _grid.nearest_free_cell(cell)
		if free != NavGrid.INVALID:
			cell = free
	global_position = NavGrid.center_of(cell)
	moving = false
	_progress = 0.0
	active = true
	visible = true


func stop() -> void:
	active = false
	moving = false
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(_player) or _grid == null:
		return
	var left := speed * delta
	if moving:
		left = _advance(left)
	if not moving and left >= 0.0:
		_begin_step(left)
	if active and cell == _target_cell():
		_catch()


## Moves along the current step. Returns the unused distance once the step ends, else -1.
func _advance(dist: float) -> float:
	_progress += dist
	if _progress >= TILE:
		global_position = _to
		moving = false
		return _progress - TILE
	global_position = _from.lerp(_to, _progress / TILE)
	return -1.0


func _begin_step(leftover: float) -> void:
	var t := _target_cell()
	var path := _grid.find_cells(cell, t)
	if path.size() < 2:
		return # already there, or the target cannot be reached: stand still
	if path[1] == t:
		_catch()
		return
	if NavGrid.tile_blocked(get_world_2d().direct_space_state, path[1], collision_mask):
		_grid.refresh_cell(get_world_2d().direct_space_state, path[1])
		return # try again next frame with the corrected grid
	_from = NavGrid.center_of(cell)
	_to = NavGrid.center_of(path[1])
	cell = path[1]
	_progress = 0.0
	moving = true
	_advance(leftover)


func _target_cell() -> Vector2i:
	var c = _player.get("cell")
	if c is Vector2i:
		return c
	return NavGrid.cell_of(_player.global_position)


func _catch() -> void:
	active = false
	moving = false
	velocity = Vector2.ZERO
	caught.emit()
