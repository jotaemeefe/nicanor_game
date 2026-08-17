extends Control
class_name DialogueBox

## Content-agnostic dialogue box: typewriter reveal (click/tap to skip to full
## line), an optional speaker portrait, and an optional list of response
## choices. All text/portraits come from callers — this script owns no
## dialogue content (see game/data/dialogues/ and game/resources/dialogue/).

const CHARS_PER_SECOND: float = 45.0

signal advance_requested
signal choice_selected(index: int)

@onready var _speaker_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var _text_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var _continue_hint: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/ContinueHint
@onready var _options_container: VBoxContainer = $Panel/MarginContainer/HBoxContainer/VBoxContainer/OptionsContainer
@onready var _portrait_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/PortraitRect

var _full_text: String = ""
var _reveal_progress: float = 0.0
var _revealing: bool = false
var _choice_mode: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func show_line(speaker: String, text: String, portrait: Texture2D = null) -> void:
	_choice_mode = false
	_options_container.visible = false
	_options_container.hide()
	_speaker_label.text = speaker
	_speaker_label.visible = speaker != ""
	_full_text = text
	_reveal_progress = 0.0
	_revealing = true
	_text_label.text = ""
	_continue_hint.visible = false
	_portrait_rect.visible = portrait != null
	_portrait_rect.texture = portrait
	show()

## options: Array[String]. Emits choice_selected(index) when the player picks one.
func show_choices(options: Array) -> void:
	_choice_mode = true
	_revealing = false
	_continue_hint.visible = false
	for child in _options_container.get_children():
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		button.custom_minimum_size = Vector2(0, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_option_pressed.bind(i))
		_options_container.add_child(button)
	_options_container.visible = true
	_options_container.show()
	show()

func _on_option_pressed(index: int) -> void:
	_options_container.visible = false
	choice_selected.emit(index)

func is_choice_mode() -> bool:
	return _choice_mode

## Called on player click while the box is open. Completes the typewriter
## reveal on the first click, emits advance_requested on the next one. No-op
## while waiting on a choice — the option buttons handle their own input.
func handle_click() -> void:
	if _choice_mode:
		return
	if _revealing:
		_reveal_progress = _full_text.length()
		_text_label.text = _full_text
		_revealing = false
		_continue_hint.visible = true
		return
	advance_requested.emit()

func close() -> void:
	_choice_mode = false
	hide()

func _process(delta: float) -> void:
	if not _revealing:
		return
	_reveal_progress += CHARS_PER_SECOND * delta
	var shown := int(_reveal_progress)
	if shown >= _full_text.length():
		_text_label.text = _full_text
		_revealing = false
		_continue_hint.visible = true
	else:
		_text_label.text = _full_text.substr(0, shown)
