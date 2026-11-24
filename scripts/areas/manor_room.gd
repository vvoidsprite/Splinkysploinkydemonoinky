extends Node2D

@onready var edrin: Area2D = $Edrin
@onready var crow: Area2D = $Crow


func _ready() -> void:
	crow.visible = false
	crow.monitorable = false
	edrin.talked.connect(_on_edrin_talked)
	var bob := crow.create_tween().set_loops()
	bob.tween_property($Crow/Bird, "position:y", -2.0, 1.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property($Crow/Bird, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE)


func _on_edrin_talked(id) -> void:
	if id != "edrin_first":
		return
	edrin.set_deferred("monitorable", false)
	var t := create_tween()
	t.tween_property(edrin, "modulate:a", 0.0, 0.5)
	await t.finished
	edrin.queue_free()
	crow.modulate.a = 0.0
	crow.visible = true
	crow.set_deferred("monitorable", true)
	create_tween().tween_property(crow, "modulate:a", 1.0, 0.5)
