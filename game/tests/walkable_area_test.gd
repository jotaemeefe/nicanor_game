extends Node

## Headless check for the reception scene's walkable floor and the depth
## sort-order invariants that go with it.
##
## Both of these encode the fix for "Nicanor se para encima de las cosas":
## the rolling table and the front desk occupy floor that used to be inside
## his walkable rectangle, and the table sorted by its sprite centre (y 584)
## instead of by its wheels (y ~690), so he drew in front of a table that is
## actually closer to camera than he can ever stand.
##
## Run as a scene: godot --headless --path . res://tests/walkable_area_test.tscn

const OFFICE_SCENE_PATH := "res://scenes/office/oficina_recepcion.tscn"

## The far edge of the front desk's top surface, measured off the rendered
## background: it runs from (0, 607) to (360, 655) in viewport pixels. Feet
## below this line overlap the desk's painted top.
const DESK_EDGE_LEFT_Y := 607.0
const DESK_EDGE_RIGHT_Y := 655.0
const DESK_EDGE_RIGHT_X := 360.0
## How much visible floor has to stay between his feet and that edge.
const DESK_CLEARANCE := 30.0

## The standing lectern on the left, measured off the rendered background:
## its silhouette spans x 5..118, y 388..610, and its foot rests at y ~610 —
## nearer to camera than any floor Nicanor can reach. It is painted into the
## background too, so the only way he doesn't read as standing on it is to
## never overlap it: his drawn half-width grows with depth, so the clearance
## has to be checked against his scale at that spot, not a fixed margin.
const LECTERN_RIGHT_X := 118.0
## Half the sprite's width in texture pixels (nicanor idle frames are 420 wide).
const SPRITE_HALF_WIDTH := 210.0

func _desk_edge_y(x: float) -> float:
	var t := clampf(x / DESK_EDGE_RIGHT_X, 0.0, 1.0)
	return lerpf(DESK_EDGE_LEFT_Y, DESK_EDGE_RIGHT_Y, t)

var _failures: Array[String] = []
var _pass_count: int = 0

func _ready() -> void:
	var tree: SceneTree = get_tree()

	var office: Node2D = load(OFFICE_SCENE_PATH).instantiate()
	add_child(office)
	await get_tree().process_frame

	var nicanor: NicanorController = office.get_node("World/Nicanor")
	var poly: PackedVector2Array = nicanor.walkable_polygon
	_expect(poly.size() >= 3, "Nicanor should use a walkable_polygon, not the fallback rect")

	# --- the floor itself -------------------------------------------------

	# A spot in the open middle of the room must be left exactly where clicked.
	_expect_walks_to(nicanor, Vector2(400, 620), Vector2(400, 620),
		"a click on open floor should not be moved")

	# Deep inside the rolling table's footprint: must come back to its left.
	var into_table := _resolve(nicanor, Vector2(1100, 640))
	_expect(into_table.x <= 795.0,
		"a click on the rolling table should resolve left of it, got x=%.1f" % into_table.x)

	# On the front desk's top surface: must come back well behind its near
	# edge, or his feet read as resting on the desk. The desk is painted into
	# the background so it can never occlude him — clearance is the only cue.
	var onto_desk := _resolve(nicanor, Vector2(110, 700))
	_expect(onto_desk.y <= _desk_edge_y(onto_desk.x) - DESK_CLEARANCE,
		"a click on the front desk should resolve behind it: got %s, desk edge at y=%.1f there" % [onto_desk, _desk_edge_y(onto_desk.x)])

	# Nowhere he can stand may put his drawn silhouette over the lectern.
	# Swept across the room rather than checked at one point, because the
	# binding constraint moves with depth: he is drawn widest at the front.
	var worst_spot := Vector2.ZERO
	var worst_left_edge := INF
	for sample_x in range(0, 1290, 10):
		for sample_y in range(500, 710, 10):
			var spot := _resolve(nicanor, Vector2(sample_x, sample_y))
			var left_edge: float = spot.x - SPRITE_HALF_WIDTH * nicanor._depth_scale_for_y(spot.y)
			if left_edge < worst_left_edge:
				worst_left_edge = left_edge
				worst_spot = spot
	_expect(worst_left_edge > LECTERN_RIGHT_X,
		"closest reachable spot %s draws out to x=%.0f, over the lectern (right edge %.0f)"
			% [worst_spot, worst_left_edge, LECTERN_RIGHT_X])

	# Far outside the room entirely — still has to produce a usable spot.
	var far_away := _resolve(nicanor, Vector2(-500, 50))
	_expect(Geometry2D.is_point_in_polygon(far_away, poly) or _on_border(far_away, poly),
		"an off-screen click should resolve onto the walkable floor, got %s" % far_away)

	var hotspots: Array[Node] = office.get_node("World/Hotspots").find_children("*", "Hotspot", true, false)

	# Every hotspot's approach point has to land somewhere he can stand,
	# otherwise interacting with it walks him into furniture.
	for hotspot in hotspots:
		var resolved := _resolve(nicanor, hotspot.approach_global_position())
		_expect(Geometry2D.is_point_in_polygon(resolved, poly) or _on_border(resolved, poly),
			"approach point for '%s' should resolve onto the floor, got %s" % [hotspot.hotspot_name, resolved])

	# No two hitboxes may overlap. They are invisible rectangles, so an overlap
	# is not visible while editing the scene, but a click in the shared area
	# goes to whichever Area2D the viewport happens to pick first — the bug is
	# silent until a player clicks the wrong prop. Every hotspot here is a
	# separate object in the room, so "no overlap at all" is the right bar.
	for i in hotspots.size():
		for j in range(i + 1, hotspots.size()):
			var a: Hotspot = hotspots[i]
			var b: Hotspot = hotspots[j]
			var rect_a := Rect2(a.global_position - a.hitbox_size * 0.5, a.hitbox_size)
			var rect_b := Rect2(b.global_position - b.hitbox_size * 0.5, b.hitbox_size)
			_expect(not rect_a.intersects(rect_b),
				"hitboxes for '%s' %s and '%s' %s overlap" % [a.hotspot_name, rect_a, b.hotspot_name, rect_b])

	# --- draw order -------------------------------------------------------

	var front_y := poly[0].y
	for vertex in poly:
		front_y = maxf(front_y, vertex.y)

	var mesa_anchor: Node2D = office.get_node("World/MesaSortAnchor")
	var sello_anchor: Node2D = office.get_node("World/Hotspots/SelloAnchor")

	# The table's sort key must sit at its wheels, past anything Nicanor can
	# reach, so he can never draw on top of it.
	_expect(mesa_anchor.position.y > front_y,
		"mesa sort key (%.0f) must be in front of the walkable floor (%.0f)" % [mesa_anchor.position.y, front_y])
	# ...and the stamp sits on the table, so it sorts after the table.
	_expect(sello_anchor.position.y > mesa_anchor.position.y,
		"sello sort key (%.0f) must be in front of the mesa (%.0f)" % [sello_anchor.position.y, mesa_anchor.position.y])

	# The service window glass stays behind him at every reachable spot.
	var window_anchor: Node2D = office.get_node("World/ServiceWindowSortAnchor")
	var back_y := poly[0].y
	for vertex in poly:
		back_y = minf(back_y, vertex.y)
	_expect(window_anchor.position.y < back_y,
		"window overlay sort key (%.0f) must be behind the walkable floor (%.0f)" % [window_anchor.position.y, back_y])

	if _failures.is_empty():
		print("WALKABLE AREA TEST: OK — %d checks passed, no failures." % _pass_count)
	else:
		print("WALKABLE AREA TEST: FAILED (%d failures):" % _failures.size())
		for f in _failures:
			print(" - %s" % f)
	tree.quit(1 if not _failures.is_empty() else 0)

## Runs a destination through the controller's real clamping and returns where
## he would actually end up.
func _resolve(nicanor: NicanorController, destination: Vector2) -> Vector2:
	nicanor.walk_to(destination)
	return nicanor._target_position

func _expect_walks_to(nicanor: NicanorController, destination: Vector2, expected: Vector2, message: String) -> void:
	var resolved := _resolve(nicanor, destination)
	_expect(resolved.is_equal_approx(expected), "%s (got %s, expected %s)" % [message, resolved, expected])

## is_point_in_polygon() is exclusive on the edge, and clamped points land
## exactly on it by construction.
func _on_border(point: Vector2, poly: PackedVector2Array) -> bool:
	var count := poly.size()
	for i in count:
		if Geometry2D.get_closest_point_to_segment(point, poly[i], poly[(i + 1) % count]).distance_to(point) < 0.5:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_failures.append(message)
