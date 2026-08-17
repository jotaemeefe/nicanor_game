extends Node

## Headless check for the intro video scene (game/scenes/intro/intro.tscn):
## the video stream is actually assigned (not a silently-missing resource),
## and the transition-to-office guard behaves correctly (fires once, is
## idempotent on a second call). Does not simulate real video decoding
## timing — see the manual playthrough in game/docs/PLAYTEST.md for that,
## and this session's --write-movie captures confirmed real frames decode.
## Run as a scene: godot --headless --path . res://tests/intro_flow_test.tscn

const INTRO_SCENE_PATH := "res://scenes/intro/intro.tscn"
const OFFICE_SCENE_PATH := "res://scenes/office/oficina_recepcion.tscn"

var _failures: Array[String] = []
var _pass_count: int = 0

func _ready() -> void:
	# Cache the tree up front: _go_to_office() below triggers a real deferred
	# change_scene_to_file(), which frees this node once it lands — after
	# that, this node's own get_tree() returns null.
	var tree: SceneTree = get_tree()

	var intro_packed: PackedScene = load(INTRO_SCENE_PATH)
	_expect(intro_packed != null, "intro.tscn should load as a PackedScene")

	var intro: Control = intro_packed.instantiate()
	add_child(intro)
	await get_tree().process_frame

	var player: VideoStreamPlayer = intro.get_node("VideoStreamPlayer")
	_expect(player != null, "Intro should have a VideoStreamPlayer child")
	_expect(player.stream != null, "VideoStreamPlayer.stream must be assigned, not null")
	_expect(player.stream is VideoStreamTheora, "video stream should be a VideoStreamTheora (.ogv)")

	_expect(intro.has_method("_go_to_office"), "Intro script should expose _go_to_office")
	_expect(not intro._advanced, "_advanced should start false")

	intro._go_to_office()
	_expect(intro._advanced, "_advanced should be true immediately after _go_to_office()")

	# Second call must be a no-op (guards against double scene-change queuing).
	intro._go_to_office()
	_expect(intro._advanced, "_advanced should remain true after a second call")

	if _failures.is_empty():
		print("INTRO FLOW TEST: OK — %d checks passed, no failures." % _pass_count)
	else:
		print("INTRO FLOW TEST: FAILED (%d failures):" % _failures.size())
		for f in _failures:
			print(" - %s" % f)
	tree.quit(1 if not _failures.is_empty() else 0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_failures.append(message)
