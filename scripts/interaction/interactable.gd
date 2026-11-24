extends Area2D

signal talked(id)

@export var conversation_id := ""
@export var repeat_conversation_id := ""
## Shown only while this story flag is set (empty = no condition).
@export var visible_flag := ""
## Hidden while this story flag is set (empty = no condition).
@export var hidden_flag := ""


func _ready() -> void:
	add_to_group("interactable")
	if visible_flag != "" or hidden_flag != "":
		add_to_group("stateful")
		GameState.flag_changed.connect(_on_flag_changed)
		apply_state()


## Stable save key: area scene name + path inside that scene.
func state_key() -> String:
	var root: Node = owner if owner != null else self
	return root.name + "/" + str(root.get_path_to(self))


func interact(_player) -> void:
	var id := conversation_id
	var key := state_key()
	if GameState.has_talked(key) and repeat_conversation_id != "":
		id = repeat_conversation_id
	GameState.mark_talked(key)
	Dialogue.play(id)
	await Dialogue.finished
	talked.emit(id)


## Shows/hides this interactable from its flags (also stops it being talkable while hidden).
func apply_state() -> void:
	var show_it := true
	if visible_flag != "" and not GameState.get_flag(visible_flag):
		show_it = false
	if hidden_flag != "" and GameState.get_flag(hidden_flag):
		show_it = false
	visible = show_it
	set_deferred("monitorable", show_it)
	set_deferred("monitoring", show_it)


func _on_flag_changed(_id: String, _value: Variant) -> void:
	apply_state()
