extends CanvasLayer
## Title screen: "Lychkin" in plain text, then New Game / Continue / Quit.
## API used by Main: open(), close(), is_open, signals new_game and load_requested(slot).
## Up/Down moves, interact chooses. Continue is greyed out when there are no saves;
## otherwise it opens the save menu in load mode.

signal new_game
signal load_requested(slot: int)

const SS := preload("res://scripts/core/save_system.gd")
const COL_ACTIVE := Color("#e8e4ee")
const COL_IDLE := Color("#9a94a6")
const COL_DISABLED := Color("#5a5566")

var is_open := false
var _cursor := 0
var _labels: Array[Label] = []
var _items := ["New Game", "Continue", "Quit"]

@onready var _list: VBoxContainer = $Box/Items
@onready var _hint: Label = $Box/Hint


func _ready() -> void:
	for i in _items.size():
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(l)
		_labels.append(l)
	visible = false


func open() -> void:
	is_open = true
	visible = true
	_cursor = 0
	_refresh()


func close() -> void:
	is_open = false
	visible = false


func _can_pick(i: int) -> bool:
	return i != 1 or SS.any_saves()


func _refresh() -> void:
	for i in _items.size():
		_labels[i].text = ("> " if i == _cursor else "  ") + _items[i]
		var c := COL_ACTIVE if i == _cursor else COL_IDLE
		if not _can_pick(i):
			c = COL_DISABLED
		_labels[i].add_theme_color_override("font_color", c)
	_hint.text = "No saved memories yet." if (_cursor == 1 and not _can_pick(1)) else ""


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var menu := get_tree().get_first_node_in_group("save_menu")
	if menu != null and menu.get("is_open"):
		return
	if event.is_echo():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_cursor = posmod(_cursor - 1, _items.size())
		_refresh()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_cursor = posmod(_cursor + 1, _items.size())
		_refresh()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not _can_pick(_cursor):
			return
		match _cursor:
			0:
				new_game.emit()
			1:
				_continue()
			2:
				get_tree().quit()


func _continue() -> void:
	var menu := get_tree().get_first_node_in_group("save_menu")
	if menu == null:
		return
	menu.open("load")
	var slot: int = await menu.closed
	if slot > 0:
		load_requested.emit(slot)
