extends Node2D

## Oficina de Licencias Poéticas — prototype scene controller.
## Owns hotspot wiring, dialogue flow, and the end-of-test message.
## No dialogue text lives in this script; it is loaded from
## res://resources/dialogue/oficina_licencias.json.

const DIALOGUE_DATA_PATH := "res://resources/dialogue/oficina_licencias.json"
const FUNCIONARIA_HOTSPOT_NAME := "Funcionaria"

@onready var _nicanor: NicanorController = $Nicanor
@onready var _hotspots: Node2D = $Hotspots
@onready var _hover_label: Label = $UI/HoverLabel
@onready var _dialogue_box: DialogueBox = $UI/DialogueBox
@onready var _end_label: Label = $UI/EndLabel

var _dialogue_data: Dictionary = {}
var _conversation_lines: Array = []
var _conversation_index: int = 0
var _in_conversation: bool = false
var _test_finished: bool = false

func _ready() -> void:
	_dialogue_data = _load_dialogue_data(DIALOGUE_DATA_PATH)
	_conversation_lines = _dialogue_data.get("conversacion_funcionaria", [])
	_hover_label.hide()
	_dialogue_box.hide()
	_end_label.hide()
	for hotspot in _hotspots.get_children():
		if hotspot is Hotspot:
			hotspot.hovered.connect(_on_hotspot_hovered)
			hotspot.unhovered.connect(_on_hotspot_unhovered)
			hotspot.interacted.connect(_on_hotspot_interacted)
			hotspot.observed.connect(_on_hotspot_observed)

func _load_dialogue_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Dialogue data not found at %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("Dialogue data at %s did not parse as a Dictionary" % path)
	return {}

func _on_hotspot_hovered(hotspot: Hotspot) -> void:
	_hover_label.text = hotspot.hotspot_name
	_hover_label.show()

func _on_hotspot_unhovered(_hotspot: Hotspot) -> void:
	_hover_label.hide()

func _on_hotspot_observed(hotspot: Hotspot) -> void:
	if _in_conversation:
		return
	_dialogue_box.show_line("", hotspot.observe_text)

func _on_hotspot_interacted(hotspot: Hotspot) -> void:
	if _in_conversation:
		return
	if hotspot.triggers_dialogue:
		_start_conversation()
	else:
		_dialogue_box.show_line("", hotspot.interact_text)

func _start_conversation() -> void:
	_in_conversation = true
	_conversation_index = 0
	_advance_conversation()

func _advance_conversation() -> void:
	if _conversation_index >= _conversation_lines.size():
		_in_conversation = false
		_dialogue_box.close()
		_finish_test()
		return
	var line: Dictionary = _conversation_lines[_conversation_index]
	_dialogue_box.show_line(line.get("speaker", ""), line.get("text", ""))
	_conversation_index += 1

func _finish_test() -> void:
	if _test_finished:
		return
	_test_finished = true
	_end_label.text = "Fin de la prueba"
	_end_label.show()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _dialogue_box.visible:
			if _in_conversation:
				_advance_conversation()
			else:
				_dialogue_box.close()
			return
		_nicanor.walk_to(get_global_mouse_position())
