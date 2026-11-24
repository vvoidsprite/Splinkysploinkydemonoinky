extends "res://scripts/interaction/interactable.gd"
## The save-point crow. A reusable Interactable: first visit plays first_conversation_id, later
## visits play the next line of repeat_pool (cycling), then it offers crow_save_prompt.
## Choosing "save" opens the save menu; the chosen slot gets the payload from the game.
## The crow never explains or warns about saving; all its words live in dialogue.json.
##
## Appearing/vanishing: set visible_flag (appears when set) and/or hidden_flag (vanishes when set)
## from the Interactable base. Empty = no condition.
##
## Save payload: the crow asks, in order, (1) SaveCrow.payload_provider (a Callable returning a
## Dictionary), (2) the current scene's build_save_data(). It then adds "save_point" = crow_id.
## Repeat position is kept in GameState.crow_pool_index[crow_id]: missing = first visit not yet
## done; N = next pool line to play (wraps).

signal saved(slot: int)

const SS := preload("res://scripts/core/save_system.gd")
const FADE_TIME := 0.5
## Said when the file could not be written. TODO: add to data/dialogue.json as "crow_save_failed"
## (it is used automatically once that id exists). Must never claim the memory was kept.
const SAVE_FAILED_LINE := "My claws slip. It will not hold. Ask me again."

## Optional override for the save payload (static, shared by all crows).
static var payload_provider := Callable()

@export var crow_id := "crow"
@export var first_conversation_id := "crow_room_first"
@export var repeat_pool: PackedStringArray = ["crow_room_repeat_1", "crow_room_repeat_2", "crow_room_repeat_3"]

var busy := false


func _ready() -> void:
	super._ready()
	add_to_group("stateful")
	if not GameState.flag_changed.is_connected(_on_flag_changed):
		GameState.flag_changed.connect(_on_flag_changed)
	var bird := get_node_or_null("Bird")
	if bird != null:
		var bob := create_tween().set_loops()
		bob.tween_property(bird, "position:y", -2.0, 1.2).set_trans(Tween.TRANS_SINE)
		bob.tween_property(bird, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	apply_state()


## Picks the line for this visit and advances the cycle.
func next_conversation_id() -> String:
	var pool: Dictionary = GameState.crow_pool_index
	if not pool.has(crow_id) or repeat_pool.is_empty():
		pool[crow_id] = 0
		return first_conversation_id
	var i: int = int(pool[crow_id])
	pool[crow_id] = i + 1
	return repeat_pool[i % repeat_pool.size()]


func build_payload() -> Dictionary:
	var data := {}
	if payload_provider.is_valid():
		data = payload_provider.call()
	else:
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("build_save_data"):
			data = scene.build_save_data()
	data = data.duplicate(true)
	data["save_point"] = crow_id
	return data


func interact(player) -> void:
	if busy:
		return
	busy = true
	if player != null and "frozen" in player:
		player.frozen = true
	GameState.mark_talked(state_key())
	await _say(next_conversation_id())
	await _say("crow_save_prompt")
	if Dialogue.last_choice == "save":
		await _do_save()
	else:
		await _say("crow_declined")
	if player != null and is_instance_valid(player) and "frozen" in player:
		player.frozen = false
	busy = false


func _say(id: String) -> void:
	Dialogue.play(id)
	await Dialogue.finished


func _do_save() -> void:
	var menu := get_tree().get_first_node_in_group("save_menu")
	if menu == null:
		push_warning("SaveCrow: no save_menu in the scene tree")
		return
	menu.open("save")
	var slot: int = await menu.closed
	if slot < 1:
		await _say("crow_declined")
		return
	if SS.save_slot(slot, build_payload()):
		saved.emit(slot)
		await _say("crow_saved")
	else:
		push_warning("SaveCrow: could not write slot %d" % slot)
		await _say_save_failed()


## The write failed: the crow says so in its own voice and never claims it kept anything.
func _say_save_failed() -> void:
	if Dialogue._conversations.has("crow_save_failed"):
		await _say("crow_save_failed")
	else:
		Dialogue.show_line(SAVE_FAILED_LINE, "Crow")
		await Dialogue.finished


## Fades in when visible_flag turns on, fades out when hidden_flag turns on; otherwise instant.
func _on_flag_changed(_id: String, _value: Variant) -> void:
	var was_visible := visible
	apply_state()
	var now_visible := visible
	if now_visible and not was_visible:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, FADE_TIME)
	elif was_visible and not now_visible:
		visible = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, FADE_TIME)
		tw.tween_callback(func(): visible = false)
	else:
		modulate.a = 1.0 if now_visible else modulate.a
