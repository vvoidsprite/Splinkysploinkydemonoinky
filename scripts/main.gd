extends Node2D
## Game flow and area manager: title -> new game / load -> areas. Owns the persistent Player,
## swaps area scenes under World with a fade, and builds/restores save data.

signal area_leaving(from_id: String, to_id: String)
signal area_entered(area_id: String)

const SS := preload("res://scripts/core/save_system.gd")
const AREAS := {
	"manor_room": "res://scenes/areas/manor_room.tscn",
	"grounds_test": "res://scenes/areas/grounds_test.tscn",
	"gate": "res://scenes/areas/prologue/gate.tscn",
	"entrance_hall": "res://scenes/areas/prologue/entrance_hall.tscn",
	"maren_room": "res://scenes/areas/prologue/maren_room.tscn",
}
const START_AREA := "gate"
const START_SPAWN := "start"
const FADE_TIME := 0.25

var current_id := ""
var current_area: Node2D
var busy := false

var _cache := {}
var _extra_areas := {}  # id -> scene path, added by register_area (tests and tools)

@onready var _world: Node2D = $World
@onready var _player = $World/Player
@onready var _fade: ColorRect = $Fade/Rect
@onready var _title = $TitleScreen
@onready var _save_menu = $SaveMenu


func _ready() -> void:
	_title.new_game.connect(start_new_game)
	_title.load_requested.connect(_on_load_requested)
	_show_title()


func _show_title() -> void:
	_player.frozen = true
	_player.visible = false
	GameState.counting = false
	_title.open()


## Back to the title screen (fades out, drops the current area).
func return_to_title() -> void:
	if busy:
		return
	busy = true
	_player.frozen = true
	await _fade_to(1.0)
	_leave_current()
	current_id = ""
	_show_title()
	await _fade_to(0.0)
	busy = false


func start_new_game() -> void:
	if busy or not _area_exists(START_AREA):
		push_warning("Main: cannot start a new game (busy, or area '%s' missing)" % START_AREA)
		return
	busy = true
	GameState.reset()
	_clear_cache()
	await _fade_to(1.0)
	_title.close()
	_enter(START_AREA, START_SPAWN)
	GameState.counting = true
	await _fade_to(0.0)
	_resume_play()


func _on_load_requested(slot: int) -> void:
	if busy:
		return
	load_game(SS.load_slot(slot))


## Restores a save (the dictionary from SaveSystem.load_slot). Returns false if it can't be used;
## then nothing has changed and the title stays open. Synchronous; the fade-in from black plays after.
func load_game(data: Dictionary) -> bool:
	var area_id := str(data.get("area_id", ""))
	var c = data.get("cell")
	var state = data.get("state")
	if (busy or data.is_empty() or not _area_exists(area_id)
			or typeof(c) != TYPE_ARRAY or c.size() != 2
			or typeof(c[0]) not in [TYPE_INT, TYPE_FLOAT] or typeof(c[1]) not in [TYPE_INT, TYPE_FLOAT]
			or typeof(state) != TYPE_DICTIONARY):
		push_warning("Main: cannot load save (area '%s')" % area_id)
		return false
	busy = true
	_clear_cache()
	GameState.from_dict(state)
	GameState.playtime_sec = float(data.get("playtime_sec", 0.0))
	_title.close()
	_enter(area_id, "", Vector2i(int(c[0]), int(c[1])), str(data.get("facing", "down")))
	GameState.counting = true
	_fade.color.a = 1.0
	_fade_to(0.0)
	_resume_play()
	return true


## Everything needed to write a save slot. save_point is the crow's id (empty if none).
func build_save_data(save_point := "") -> Dictionary:
	return {
		"saved_at": Time.get_datetime_string_from_system(),
		"playtime_sec": GameState.playtime_sec,
		"area_id": current_id,
		"area_label": str(current_area.get_meta("area_label", current_id)) if current_area != null else "",
		"cell": [_player.cell.x, _player.cell.y],
		"facing": _player._name_from_dir(_player.facing_dir),
		"save_point": save_point,
		"state": GameState.to_dict(),
	}


## For tests and tools: jump straight into an area without the title or a fade.
func enter_directly(area_id: String, spawn: String) -> void:
	if not _area_exists(area_id):
		push_warning("Main: unknown area '%s'" % area_id)
		return
	_title.close()
	_enter(area_id, spawn)
	_resume_play()


func go_to(area_id: String, spawn: String) -> void:
	if busy or _player.frozen or not _area_exists(area_id):
		return
	busy = true
	_player.frozen = true
	_player.velocity = Vector2.ZERO
	area_leaving.emit(current_id, area_id)
	await _fade_to(1.0)
	_enter(area_id, spawn)
	await _fade_to(0.0)
	_player.hold_until_release = true
	_player.frozen = false
	busy = false
	area_entered.emit(area_id)


func _resume_play() -> void:
	_player.visible = true
	_player.hold_until_release = true
	_player.frozen = false
	busy = false


## For tests and tools: make an extra area scene loadable by id.
func register_area(area_id: String, path: String) -> void:
	_extra_areas[area_id] = path
	_cache.erase(area_id)


func _area_path(area_id: String) -> String:
	return str(_extra_areas.get(area_id, AREAS.get(area_id, "")))


func _area_exists(area_id: String) -> bool:
	var path := _area_path(area_id)
	return path != "" and ResourceLoader.exists(path)


func _fade_to(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tw.finished


func _leave_current() -> void:
	if current_area != null and current_area.get_parent() == _world:
		_world.remove_child(current_area)
	current_area = null


func _clear_cache() -> void:
	_leave_current()
	for a in _cache.values():
		if is_instance_valid(a) and a.get_parent() == null:
			a.free()
	_cache.clear()


func _enter(area_id: String, spawn: String, at_cell = null, facing := "down") -> void:
	_leave_current()
	var area: Node2D = _cache.get(area_id)
	if area == null:
		area = (load(_area_path(area_id)) as PackedScene).instantiate()
		_cache[area_id] = area
	current_id = area_id
	current_area = area
	_world.add_child(area)
	if at_cell != null:
		_player.place_at(NavGrid.center_of(at_cell))
		_player.face(facing)
	else:
		var marker := area.get_node_or_null("Spawns/" + spawn) as Node2D
		if marker == null:
			push_warning("Main: area '%s' has no spawn '%s'" % [area_id, spawn])
		else:
			_player.place_at(marker.global_position)
			_player.face(str(marker.get_meta("facing", "down")))
	_frame_camera(Vector2i(area.get_meta("area_size", Vector2i(640, 360))))
	if at_cell != null:
		_ensure_free_cell(area, facing)
	_apply_state(area)


## Camera limits for a map of this size. An axis smaller than the view gets limits that centre the
## map and leave the camera nothing to scroll; a larger one scrolls over 0..size as usual.
func _frame_camera(size: Vector2i) -> void:
	var view := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 640)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 360)))
	var cam: Camera2D = _player.get_node("Camera2D")
	var lo := Vector2i.ZERO
	var hi := size
	if size.x < view.x:
		lo.x = floori((size.x - view.x) / 2.0)
		hi.x = lo.x + view.x
	if size.y < view.y:
		lo.y = floori((size.y - view.y) / 2.0)
		hi.y = lo.y + view.y
	cam.limit_left = lo.x
	cam.limit_top = lo.y
	cam.limit_right = hi.x
	cam.limit_bottom = hi.y
	cam.reset_smoothing()


## After a load: if the saved cell is off the map or blocked, move Maren to the nearest free cell
## within 3 steps, else to the area's entrance spawn. Waits one physics frame so colliders exist.
func _ensure_free_cell(area: Node2D, facing: String) -> void:
	await get_tree().physics_frame
	if not is_instance_valid(area) or area != current_area:
		return
	var size := Vector2(Vector2i(area.get_meta("area_size", Vector2i(640, 360))))
	var space: PhysicsDirectSpaceState2D = _player.get_world_2d().direct_space_state
	var mask: int = _player.collision_mask
	var origin: Vector2i = _player.cell
	var free := func(c: Vector2i) -> bool:
		var p := NavGrid.center_of(c)
		return p.x > 0.0 and p.y > 0.0 and p.x < size.x and p.y < size.y \
				and not NavGrid.tile_blocked(space, c, mask)
	if free.call(origin):
		return
	var best := NavGrid.INVALID
	var best_d := 99
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var d := absi(dx) + absi(dy)
			if d == 0 or d > 3 or d >= best_d:
				continue
			var c := origin + Vector2i(dx, dy)
			if free.call(c):
				best = c
				best_d = d
	if best != NavGrid.INVALID:
		push_warning("Main: saved cell %s in '%s' is blocked, moved to %s" % [origin, current_id, best])
		_player.place_at(NavGrid.center_of(best))
		return
	var marker := area.get_node_or_null("Spawns/" + START_SPAWN) as Node2D
	push_warning("Main: saved cell %s in '%s' is blocked, using the entrance" % [origin, current_id])
	if marker != null:
		_player.place_at(marker.global_position)
		_player.face(str(marker.get_meta("facing", facing)))


## Lets story-driven things in the area (flag-dependent props, the crow, puzzles) match GameState.
func _apply_state(area: Node) -> void:
	if area.has_method("apply_state"):
		area.apply_state()
	for n in get_tree().get_nodes_in_group("stateful"):
		if n != area and area.is_ancestor_of(n) and n.has_method("apply_state"):
			n.apply_state()


func _exit_tree() -> void:
	for a in _cache.values():
		if is_instance_valid(a) and a.get_parent() == null:
			a.free()
