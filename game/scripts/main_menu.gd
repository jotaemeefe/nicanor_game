extends Control

## Title screen. The background music loops (the loop is set on the mp3 import,
## not faked here) until the player commits, and is faded rather than cut: the
## intro video that follows carries its own audio, and a hard stop into it is
## audible as a click.

const FADE_SECONDS := 0.35
const FADE_TO_DB := -40.0

@onready var _start_button: Button = %Comenzar
@onready var _musica: AudioStreamPlayer = $Musica

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.grab_focus()

func _on_start_pressed() -> void:
	# The scene stays alive for the length of the fade, so the button has to
	# stop answering or a second click queues a second scene change.
	_start_button.disabled = true
	if _musica and _musica.playing:
		var tween := create_tween()
		tween.tween_property(_musica, "volume_db", FADE_TO_DB, FADE_SECONDS)
		await tween.finished
	get_tree().change_scene_to_file("res://scenes/intro/intro.tscn")
