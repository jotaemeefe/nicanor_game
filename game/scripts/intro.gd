extends Control

## Plays the intro cinematic once, then hands off to the office scene.
## Any click/key skips straight to the office. If the video stream is
## missing or never actually starts playing, falls back to the office
## scene automatically instead of leaving the player stuck on black.

const OFFICE_SCENE_PATH := "res://scenes/office/oficina_recepcion.tscn"
const STARTUP_GRACE_SECONDS := 1.5

@onready var _player: VideoStreamPlayer = $VideoStreamPlayer
@onready var _skip_label: Label = $SkipLabel

var _advanced: bool = false

func _ready() -> void:
	_skip_label.hide()
	_player.finished.connect(_go_to_office)

	if _player.stream == null:
		push_warning("Intro: no video stream assigned, skipping to office.")
		_go_to_office()
		return

	_player.play()
	get_tree().create_timer(STARTUP_GRACE_SECONDS).timeout.connect(_check_playback_started)
	get_tree().create_timer(0.5).timeout.connect(func() -> void: _skip_label.show())

func _check_playback_started() -> void:
	if _advanced:
		return
	if not _player.is_playing():
		push_warning("Intro: video failed to start playing, skipping to office.")
		_go_to_office()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_go_to_office()
	elif event is InputEventKey and event.pressed:
		_go_to_office()

func _go_to_office() -> void:
	if _advanced:
		return
	_advanced = true
	if _player.is_playing():
		_player.stop()
	get_tree().change_scene_to_file(OFFICE_SCENE_PATH)
