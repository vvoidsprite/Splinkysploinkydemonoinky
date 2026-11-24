extends Node2D
## Runs the cabinet chase: IDLE -> TELEGRAPH -> RUNNING -> CAUGHT or ESCAPED.
## ESCAPED means the chase ended because the player left the area (through the opened door).

enum State { IDLE, TELEGRAPH, RUNNING, CAUGHT, ESCAPED }

@export var start_delay := 1.2
@export var chaser_speed := 110.0
@export var speed_ramp := 20.0
@export var max_speed := 140.0
## If true, the chase keeps going when the player changes area.
@export var persists_across_areas := false

var state := State.IDLE
var _player: Node2D
var _speed := 0.0
var _cabinet_x := 0.0
var _danger_tween: Tween
var _door_tween: Tween

@onready var _cabinet: Area2D = $Cabinet
@onready var _door_closed: Sprite2D = $Door/Closed
@onready var _door_open: Sprite2D = $Door/Open
@onready var _exit: Area2D = $Exit
@onready var _locked_note: Area2D = $LockedNote
@onready var _chaser_spawn: Marker2D = $ChaserSpawn
@onready var _chaser: CharacterBody2D = $Chaser
@onready var _danger: ColorRect = $Danger/Overlay
@onready var _screen: CanvasLayer = $Screen


func _ready() -> void:
	_cabinet_x = _cabinet.position.x
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		push_warning("ChaseKit: no player found in group 'player'; chase disabled.")
		set_physics_process(false)
		_cabinet.monitorable = false
		return
	_cabinet.opened.connect(_on_cabinet_opened)
	_chaser.caught.connect(_on_caught)
	var mgr := get_tree().get_first_node_in_group("area_manager")
	if mgr != null and mgr.has_signal("area_leaving"):
		mgr.area_leaving.connect(_on_area_leaving)


func _physics_process(delta: float) -> void:
	if state == State.RUNNING:
		_speed = minf(_speed + speed_ramp * delta, max_speed)
		_chaser.speed = _speed


func _on_cabinet_opened() -> void:
	if state != State.IDLE:
		return
	state = State.TELEGRAPH
	_player.can_interact = false

	var chain := _cabinet.get_node_or_null("Body/Chain")
	if chain != null:
		chain.queue_free()

	var shake := create_tween()
	for i in 6:
		shake.tween_property(_cabinet, "position:x", _cabinet_x + (2.0 if i % 2 == 0 else -2.0), 0.05)
	shake.tween_property(_cabinet, "position:x", _cabinet_x, 0.05)

	_door_closed.visible = false
	_door_open.visible = true
	_door_tween = create_tween().set_loops()
	_door_tween.tween_property(_door_open, "modulate", Color(1, 0.9, 0.7), 0.5)
	_door_tween.tween_property(_door_open, "modulate", Color.WHITE, 0.5)
	_exit.enabled = true
	_locked_note.monitorable = false
	_locked_note.visible = false

	_danger_tween = create_tween().set_loops()
	_danger_tween.tween_property(_danger, "color:a", 0.08, 0.6)
	_danger_tween.tween_property(_danger, "color:a", 0.02, 0.6)

	await get_tree().create_timer(start_delay).timeout
	if state != State.TELEGRAPH:
		return
	_speed = chaser_speed
	_chaser.speed = _speed
	_chaser.global_position = _chaser_spawn.global_position
	_chaser.start(_player)
	state = State.RUNNING


func _on_caught() -> void:
	if state != State.RUNNING:
		return
	state = State.CAUGHT
	_kill_tween(_danger_tween)
	_danger_tween = null
	_freeze_player()
	_chaser.stop()
	var dialogue := get_node_or_null("/root/Dialogue")
	if dialogue != null:
		dialogue.close()
	_screen.show_message("Maren was caught.", "Press E to try again")


func _on_area_leaving(_from_id: String, _to_id: String) -> void:
	if persists_across_areas:
		return
	if state != State.TELEGRAPH and state != State.RUNNING:
		return
	state = State.ESCAPED
	_kill_tween(_danger_tween)
	_danger_tween = null
	_kill_tween(_door_tween)
	_door_tween = null
	_door_open.modulate = Color.WHITE
	_danger.color.a = 0.0
	_chaser.stop()
	_chaser.visible = false
	_player.can_interact = true
	var mgr := get_tree().get_first_node_in_group("area_manager")
	if mgr != null:
		mgr.area_entered.connect(_on_area_entered_after_escape, CONNECT_ONE_SHOT)


func _on_area_entered_after_escape(_area_id: String) -> void:
	# The kit is detached from the tree here, so resolve the autoload via the main loop.
	var dialogue := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Dialogue")
	if dialogue != null:
		dialogue.play("door_holds")


func _kill_tween(t: Tween) -> void:
	if t != null:
		t.kill()


func _freeze_player() -> void:
	_player.frozen = true
	if _player is CharacterBody2D:
		_player.velocity = Vector2.ZERO
