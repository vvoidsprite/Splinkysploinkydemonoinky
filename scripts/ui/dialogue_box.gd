extends CanvasLayer

signal finished
signal chose(value: String)

const DATA_PATH := "res://data/dialogue.json"
const CHARS_PER_SEC := 40.0

var is_open := false
var last_choice := ""

var _speakers := {}
var _conversations := {}
var _lines: Array = []
var _index := 0
var _typing := false
var _choosing := false
var _cursor := 0
var _progress := 0.0
var _italic: FontVariation

@onready var box: Panel = $Box
@onready var name_label: Label = $Box/Margin/VBox/NameLabel
@onready var text_label: Label = $Box/Margin/VBox/TextLabel
@onready var choice_label: Label = $Box/Margin/VBox/ChoiceLabel
@onready var marker: Label = $Box/ContinueMarker


func _ready() -> void:
	box.visible = false
	_italic = FontVariation.new()
	_italic.base_font = ThemeDB.fallback_font
	_italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	_load_data()


func _load_data() -> void:
	var raw := FileAccess.get_file_as_string(DATA_PATH)
	var json := JSON.new()
	if json.parse(raw) != OK:
		push_error("dialogue.json parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("dialogue.json: top level must be an object")
		return
	_speakers = json.data.get("speakers", {})
	_conversations = json.data.get("conversations", {})


func play(conversation_id: String) -> void:
	if _conversations.get(conversation_id) is Array and not _conversations[conversation_id].is_empty():
		_lines = _conversations[conversation_id]
	else:
		_lines = [{"speaker": "", "text": "[missing conversation: %s]" % conversation_id}]
	_start()


func show_line(text: String, speaker := "") -> void:
	_lines = [{"speaker": speaker, "text": text}]
	_start()


func close() -> void:
	is_open = false
	_typing = false
	_choosing = false
	choice_label.visible = false
	box.visible = false


func _start() -> void:
	_index = 0
	last_choice = ""
	is_open = true
	box.visible = true
	_show_current()


func _show_current() -> void:
	var line = _lines[_index]
	var speaker := str(line.get("speaker", ""))
	text_label.text = str(line.get("text", ""))
	text_label.visible_characters = 0
	_progress = 0.0
	_typing = true
	_choosing = false
	choice_label.visible = false
	marker.visible = false
	if speaker == "":
		name_label.visible = false
		text_label.add_theme_color_override("font_color", Color("#9a94a6"))
		text_label.add_theme_font_override("font", _italic)
	else:
		name_label.visible = true
		name_label.text = speaker
		name_label.add_theme_color_override("font_color", Color(str(_speakers.get(speaker, "#ffffff"))))
		text_label.add_theme_color_override("font_color", Color("#e8e4ee"))
		text_label.remove_theme_font_override("font")


func _process(delta: float) -> void:
	if not is_open:
		return
	if _typing:
		_progress += delta * CHARS_PER_SEC
		var n := int(_progress)
		if n >= text_label.text.length():
			_typing = false
			text_label.visible_characters = -1
			_begin_choosing()
		else:
			text_label.visible_characters = n
	marker.visible = not _typing and (Time.get_ticks_msec() / 400) % 2 == 0


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if _choosing:
		if event.is_echo():
			return
		if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			_move_cursor(-1)
			return
		if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			_move_cursor(1)
			return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_typing = false
		text_label.visible_characters = -1
		_begin_choosing()
		return
	if _choosing:
		_confirm_choice()
		return
	_advance()


func _begin_choosing() -> void:
	var choices = _lines[_index].get("choices", [])
	if choices is Array and choices.size() >= 2:
		_choosing = true
		_cursor = 0
		choice_label.visible = true
		_refresh_choices()


func _move_cursor(step: int) -> void:
	var count: int = _lines[_index]["choices"].size()
	_cursor = posmod(_cursor + step, count)
	_refresh_choices()


func _refresh_choices() -> void:
	var rows: PackedStringArray = []
	var choices: Array = _lines[_index]["choices"]
	for i in choices.size():
		rows.append(("> " if i == _cursor else "   ") + str(choices[i].get("text", "")))
	choice_label.text = "\n".join(rows)


func _confirm_choice() -> void:
	last_choice = str(_lines[_index]["choices"][_cursor].get("value", ""))
	_choosing = false
	choice_label.visible = false
	chose.emit(last_choice)
	_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		close()
		finished.emit()
	else:
		_show_current()
