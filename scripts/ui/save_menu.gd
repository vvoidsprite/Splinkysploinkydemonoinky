extends CanvasLayer
## The 20-slot file list. open("save") from the crow, open("load") from the title's Continue.
## Saving over an occupied slot happens without asking (RPG Maker style).
## It only picks a slot; the caller does the actual reading/writing.

signal slot_chosen(slot: int)
signal cancelled
## Emitted after either of the above: the slot number, or -1 when cancelled.
signal closed(slot: int)

const SS := preload("res://scripts/core/save_system.gd")
const VISIBLE_ROWS := 6
const COLOR_TEXT := Color("#e8e4ee")
const COLOR_DIM := Color("#9a94a6")
const COLOR_OFF := Color("#5a5566")

var is_open := false
var mode := "load"

var _cursor := 0
var _top := 0
var _summaries: Array = []
var _row_labels: Array[Label] = []

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var rows_box: VBoxContainer = $Panel/Margin/VBox/Rows
@onready var hint_label: Label = $Panel/Margin/VBox/HintLabel


func _ready() -> void:
	add_to_group("save_menu")
	for i in VISIBLE_ROWS:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 12)
		rows_box.add_child(l)
		_row_labels.append(l)
	panel.visible = false


## mode: "save" or "load". Re-reads the slot files every time it opens.
func open(new_mode: String) -> void:
	mode = "save" if new_mode == "save" else "load"
	_summaries = [{}]  # index 0 unused so slot numbers index directly
	for n in range(1, SS.SLOT_COUNT + 1):
		_summaries.append(SS.slot_summary(n))
	_cursor = 0
	if mode == "load":
		for n in range(1, SS.SLOT_COUNT + 1):
			if _pickable(n):
				_cursor = n - 1
				break
	_top = 0
	_scroll_to_cursor()
	title_label.text = "Keep this moment" if mode == "save" else "Continue"
	hint_label.text = "Up/Down: move    Interact: choose    Esc: back"
	is_open = true
	panel.visible = true
	_refresh()


func close() -> void:
	is_open = false
	panel.visible = false


func selected_slot() -> int:
	return _cursor + 1


func _pickable(n: int) -> bool:
	if mode == "save":
		return true
	var s: Dictionary = _summaries[n]
	return bool(s["exists"]) and not bool(s["damaged"])


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(-1)
		return
	if event.is_echo():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_move_cursor(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_move_cursor(1)
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _pickable(_cursor + 1):
			_finish(_cursor + 1)


func _finish(slot: int) -> void:
	close()
	if slot < 0:
		cancelled.emit()
	else:
		slot_chosen.emit(slot)
	closed.emit(slot)


func _move_cursor(step: int) -> void:
	_cursor = posmod(_cursor + step, SS.SLOT_COUNT)
	_scroll_to_cursor()
	_refresh()


func _scroll_to_cursor() -> void:
	if _cursor < _top:
		_top = _cursor
	elif _cursor >= _top + VISIBLE_ROWS:
		_top = _cursor - VISIBLE_ROWS + 1
	_top = clampi(_top, 0, SS.SLOT_COUNT - VISIBLE_ROWS)


func _refresh() -> void:
	for i in VISIBLE_ROWS:
		var n := _top + i + 1
		var l := _row_labels[i]
		l.text = ("> " if n - 1 == _cursor else "   ") + format_row(n, _summaries[n])
		if not _pickable(n):
			l.add_theme_color_override("font_color", COLOR_OFF)
		elif n - 1 == _cursor:
			l.add_theme_color_override("font_color", COLOR_TEXT)
		else:
			l.add_theme_color_override("font_color", COLOR_DIM)


## One row of text, e.g. "File 01   Maren's Room   0:12:34   2026-11-24 21:03".
static func format_row(n: int, summary: Dictionary) -> String:
	var head := "File %02d" % n
	if not summary.get("exists", false):
		return head + "   (empty)"
	if summary.get("damaged", false):
		return head + "   (unreadable)"
	var label := str(summary.get("area_label", ""))
	if label == "":
		label = "-"
	var t := int(summary.get("playtime_sec", 0.0))
	var when := str(summary.get("saved_at", "")).replace("T", " ").left(16)
	return "%s   %s   %d:%02d:%02d   %s" % [head, label, t / 3600, (t / 60) % 60, t % 60, when]
