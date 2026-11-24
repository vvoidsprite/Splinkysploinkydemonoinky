extends Area2D
## Chained reliquary cabinet. First interact warns, second opens it.

signal opened

var _stage := 0
var _busy := false


func _ready() -> void:
	add_to_group("interactable")


func interact(_player) -> void:
	if _busy or _stage >= 2:
		return
	_busy = true
	var conversation := "cabinet_warning" if _stage == 0 else "cabinet_open"
	var dialogue := get_node_or_null("/root/Dialogue")
	if dialogue != null:
		dialogue.play(conversation)
		await dialogue.finished
	_stage += 1
	_busy = false
	if _stage >= 2:
		monitorable = false
		opened.emit()
