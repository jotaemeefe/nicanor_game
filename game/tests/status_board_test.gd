extends Node

## Headless check for the status board's perspective warp.
##
## The board hangs on the office's receding right-hand wall, but its art is
## rendered dead-on frontal. It was placed as a Sprite2D with a small rotation
## for two playtest rounds and kept being reported as not respecting the
## room's perspective — correctly, since an affine transform can tilt a quad
## but never foreshorten it. It is now a PerspectiveQuad; these checks pin
## down the things that would silently undo that.
##
## Run as a scene: godot --headless --path . res://tests/status_board_test.tscn

const OFFICE_SCENE_PATH := "res://scenes/office/oficina_recepcion.tscn"
const BOARD_TEXTURE_PATHS := [
	"res://assets/props/cartel_estado/cartel_apagado_new.png",
	"res://assets/props/cartel_estado/cartel_ambar_new.png",
	"res://assets/props/cartel_estado/cartel_rojo_new.png",
]

var _failures: Array[String] = []
var _pass_count: int = 0

func _ready() -> void:
	var tree: SceneTree = get_tree()

	# The scene swaps the board's texture per puzzle state but never rebuilds
	# the mesh, so the UVs are only valid while all three states share a size.
	var first_size: Vector2 = (load(BOARD_TEXTURE_PATHS[0]) as Texture2D).get_size()
	for path in BOARD_TEXTURE_PATHS:
		var state_texture: Texture2D = load(path)
		_expect(state_texture != null, "%s should load" % path)
		_expect(state_texture.get_size() == first_size,
			"%s is %s, but the board's UVs assume %s" % [path, state_texture.get_size(), first_size])

	var office: Node2D = load(OFFICE_SCENE_PATH).instantiate()
	add_child(office)
	await get_tree().process_frame

	var board: Node = office.get_node("CartelEstado")
	_expect(board is PerspectiveQuad,
		"CartelEstado must be a PerspectiveQuad — a Sprite2D cannot foreshorten")

	# The warp has to actually be a trapezoid. If the two vertical edges ever
	# come out the same length the board is only tilted, not foreshortened,
	# which is exactly the state that got reported twice.
	var left_height: float = board.bottom_left.y - board.top_left.y
	var right_height: float = board.bottom_right.y - board.top_right.y
	_expect(absf(right_height - left_height) > 4.0,
		"board edges are %.1f and %.1f — that is a parallelogram, not perspective"
			% [left_height, right_height])
	# The wall recedes to the left, so the near (right) edge is the taller one.
	_expect(right_height > left_height,
		"the right edge (%.1f) should be the near one, taller than the left (%.1f)"
			% [right_height, left_height])

	# The generated mesh must interpolate the configured corners exactly,
	# otherwise the homography is wrong in a way that is hard to see by eye.
	var n: int = board.subdivisions
	var expected_vertices := (n + 1) * (n + 1)
	_expect(board.polygon.size() == expected_vertices,
		"expected %d grid vertices, got %d" % [expected_vertices, board.polygon.size()])
	_expect(board.uv.size() == expected_vertices, "uv array must match the vertex count")
	_expect(board.polygons.size() == n * n, "expected %d grid cells, got %d" % [n * n, board.polygons.size()])

	if board.polygon.size() == expected_vertices:
		_expect_corner(board.polygon[0], board.top_left, "top-left")
		_expect_corner(board.polygon[n], board.top_right, "top-right")
		_expect_corner(board.polygon[n * (n + 1)], board.bottom_left, "bottom-left")
		_expect_corner(board.polygon[expected_vertices - 1], board.bottom_right, "bottom-right")

		# A projective map puts the quad's centre away from the average of the
		# corners; an affine one puts it exactly there. This is what separates
		# a real warp from the old tilted sprite.
		var centre: Vector2 = board.polygon[(n / 2) * (n + 1) + n / 2]
		var corner_average: Vector2 = (board.top_left + board.top_right + board.bottom_right + board.bottom_left) / 4.0
		_expect(centre.distance_to(corner_average) > 0.05,
			"mesh centre %s sits at the corner average %s — the map is affine" % [centre, corner_average])

	if _failures.is_empty():
		print("STATUS BOARD TEST: OK — %d checks passed, no failures." % _pass_count)
	else:
		print("STATUS BOARD TEST: FAILED (%d failures):" % _failures.size())
		for f in _failures:
			print(" - %s" % f)
	tree.quit(1 if not _failures.is_empty() else 0)

func _expect_corner(actual: Vector2, expected: Vector2, name: String) -> void:
	_expect(actual.distance_to(expected) < 0.01,
		"%s vertex should land on %s, got %s" % [name, expected, actual])

func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_failures.append(message)
