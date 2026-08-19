@tool
extends Polygon2D
class_name PerspectiveQuad

## Draws a flat, frontally-rendered texture as a foreshortened quad, for props
## that hang on a wall receding from the camera.
##
## Godot's 2D nodes only offer affine transforms (rotation, scale, skew), and
## an affine transform keeps parallel edges parallel — it can tilt a sprite but
## never foreshorten it. The status board's art is rendered dead-on frontal, so
## no combination of those ever made it sit on the office's angled right-hand
## wall: it kept reading as a sticker pasted flat over the background, which is
## what the playtests reported. This maps the texture through a real projective
## transform instead.
##
## The quad is subdivided into a grid because each cell is still rasterised
## affine; sampling the projective map at the grid points keeps the error per
## cell far below anything visible. See production/decisions.md.
##
## Corners are given in this node's own coordinates, in the order
## top-left, top-right, bottom-right, bottom-left.

@export var top_left := Vector2(-64, -48):
	set(value):
		top_left = value
		_rebuild()
@export var top_right := Vector2(64, -48):
	set(value):
		top_right = value
		_rebuild()
@export var bottom_right := Vector2(64, 48):
	set(value):
		bottom_right = value
		_rebuild()
@export var bottom_left := Vector2(-64, 48):
	set(value):
		bottom_left = value
		_rebuild()

## Grid resolution per axis. 8 is already well past the point where the
## per-cell affine error is visible on a wall prop this size.
@export_range(1, 32) var subdivisions: int = 8:
	set(value):
		subdivisions = value
		_rebuild()

func _ready() -> void:
	_rebuild()

## Rebuilds the mesh. Safe to call again if the texture is swapped for one of a
## different size — the office scene doesn't need to, since all three status
## board states share one size (asserted in tests/status_board_test.tscn).
func _rebuild() -> void:
	if texture == null:
		return
	var coefficients := _homography()
	if coefficients.is_empty():
		return
	var texture_size := texture.get_size()
	var vertices := PackedVector2Array()
	var texture_coords := PackedVector2Array()
	for row in subdivisions + 1:
		for column in subdivisions + 1:
			var u := float(column) / float(subdivisions)
			var v := float(row) / float(subdivisions)
			vertices.append(_project(coefficients, u, v))
			texture_coords.append(Vector2(u * texture_size.x, v * texture_size.y))
	var cells := []
	for row in subdivisions:
		for column in subdivisions:
			var corner := row * (subdivisions + 1) + column
			cells.append(PackedInt32Array([
				corner, corner + 1, corner + subdivisions + 2, corner + subdivisions + 1
			]))
	polygon = vertices
	uv = texture_coords
	polygons = cells

## Heckbert's unit-square-to-quad projective map. Returns [a, b, c, d, e, f, g, h] of
##   x = (a*u + b*v + c) / (g*u + h*v + 1)
##   y = (d*u + e*v + f) / (g*u + h*v + 1)
## with (0,0) at top_left, (1,0) top_right, (1,1) bottom_right, (0,1) bottom_left.
## Returns an empty array for a degenerate quad rather than dividing by zero.
func _homography() -> PackedFloat64Array:
	var dx1 := top_right.x - bottom_right.x
	var dx2 := bottom_left.x - bottom_right.x
	var dx3 := top_left.x - top_right.x + bottom_right.x - bottom_left.x
	var dy1 := top_right.y - bottom_right.y
	var dy2 := bottom_left.y - bottom_right.y
	var dy3 := top_left.y - top_right.y + bottom_right.y - bottom_left.y

	var g := 0.0
	var h := 0.0
	# dx3/dy3 both zero means the quad is a parallelogram: the map is affine and
	# the perspective terms stay at zero.
	if not (is_zero_approx(dx3) and is_zero_approx(dy3)):
		var denominator := dx1 * dy2 - dy1 * dx2
		if is_zero_approx(denominator):
			return PackedFloat64Array()
		g = (dx3 * dy2 - dy3 * dx2) / denominator
		h = (dx1 * dy3 - dy1 * dx3) / denominator

	return PackedFloat64Array([
		top_right.x - top_left.x + g * top_right.x,
		bottom_left.x - top_left.x + h * bottom_left.x,
		top_left.x,
		top_right.y - top_left.y + g * top_right.y,
		bottom_left.y - top_left.y + h * bottom_left.y,
		top_left.y,
		g,
		h,
	])

func _project(coefficients: PackedFloat64Array, u: float, v: float) -> Vector2:
	var w: float = coefficients[6] * u + coefficients[7] * v + 1.0
	if is_zero_approx(w):
		return Vector2.ZERO
	return Vector2(
		(coefficients[0] * u + coefficients[1] * v + coefficients[2]) / w,
		(coefficients[3] * u + coefficients[4] * v + coefficients[5]) / w
	)
