extends Node2D
class_name NicanorController

## Click-to-walk controller for Nicanor. Drives an optional AnimatedSprite2D
## child ("walk"/"idle"/"pose_*" animations) when present; scenes without one
## (older prototype scenes using flat Polygon2D art) still work unchanged.
## Also owns simple depth scaling: Nicanor is smaller near the back of the
## walkable area and larger near the front, matching the background's
## perspective instead of a constant size everywhere on the floor.

@export var move_speed: float = 220.0
@export var arrive_threshold: float = 4.0

## Fallback walkable area for scenes that don't define a walkable_polygon
## (the older prototype scenes). Ignored whenever walkable_polygon has at
## least 3 points.
@export var walkable_bounds: Rect2 = Rect2(120, 420, 1040, 240)

## The free floor, as a polygon in the parent's coordinate space. A perspective
## floor with furniture in the near corners is a trapezoid with bites taken out
## of it, which an axis-aligned rectangle (even minus rectangular holes) can't
## describe: the previous rect-plus-exclusions version left Nicanor able to
## stand inside the rolling table's and the front desk's footprints, where he
## read as standing *on* them. A click outside the polygon resolves to the
## closest point on its border, so clicks anywhere still produce a sensible
## walk. See production/decisions.md.
@export var walkable_polygon: PackedVector2Array = PackedVector2Array()

## Sprite scale at the back (small Y) and front (large Y) of the walkable area;
## every point in between is linearly interpolated by Y. See
## production/decisions.md for why this exists — a constant scale made
## Nicanor look like he was walking "across the whole screen" instead of on
## a floor with depth.
@export var scale_at_back: float = 0.42
@export var scale_at_front: float = 0.64

## Nicanor's walk/idle art and dialogue-pose art come from two separately
## generated reference sheets with different apparent character scale; this
## corrects the pose sheet down to match so switching into a dialogue pose
## doesn't visibly pop in size. See game/TODO_ASSETS.md.
const POSE_SCALE_FACTOR: float = 0.843

signal arrived

@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _target_position: Vector2
var _was_walking: bool = false
## The depth-scaled walk/idle scale at Nicanor's current Y — recomputed every
## physics frame while walking/idle, frozen while a dialogue pose is active
## (he isn't moving during a conversation).
var _current_depth_scale: float = 1.0
## Y range the depth scaling interpolates across, derived from whichever
## walkable shape is actually in use.
var _depth_back_y: float = 0.0
var _depth_front_y: float = 0.0

func _ready() -> void:
	_compute_depth_range()
	_target_position = global_position
	_current_depth_scale = _depth_scale_for_y(global_position.y)
	if _sprite:
		_sprite.scale = Vector2.ONE * _current_depth_scale
		_sprite.play("idle")

func walk_to(destination: Vector2) -> void:
	_target_position = _clamp_to_walkable(destination)

func is_walking() -> bool:
	return global_position.distance_to(_target_position) > arrive_threshold

func _clamp_to_walkable(point: Vector2) -> Vector2:
	if walkable_polygon.size() >= 3:
		if Geometry2D.is_point_in_polygon(point, walkable_polygon):
			return point
		return _closest_point_on_polygon(point, walkable_polygon)
	return Vector2(
		clampf(point.x, walkable_bounds.position.x, walkable_bounds.position.x + walkable_bounds.size.x),
		clampf(point.y, walkable_bounds.position.y, walkable_bounds.position.y + walkable_bounds.size.y)
	)

## Nearest point on the polygon's border — used to resolve a click that landed
## off the walkable floor (on a wall, on furniture) to the closest spot he can
## actually stand, rather than ignoring the click.
func _closest_point_on_polygon(point: Vector2, poly: PackedVector2Array) -> Vector2:
	var count := poly.size()
	var best := poly[0]
	var best_distance := INF
	for i in count:
		var candidate := Geometry2D.get_closest_point_to_segment(point, poly[i], poly[(i + 1) % count])
		var distance := point.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func _compute_depth_range() -> void:
	if walkable_polygon.size() >= 3:
		_depth_back_y = walkable_polygon[0].y
		_depth_front_y = walkable_polygon[0].y
		for vertex in walkable_polygon:
			_depth_back_y = minf(_depth_back_y, vertex.y)
			_depth_front_y = maxf(_depth_front_y, vertex.y)
	else:
		_depth_back_y = walkable_bounds.position.y
		_depth_front_y = walkable_bounds.position.y + walkable_bounds.size.y

func _depth_scale_for_y(y: float) -> float:
	if is_equal_approx(_depth_back_y, _depth_front_y):
		return scale_at_back
	var t := clampf(inverse_lerp(_depth_back_y, _depth_front_y, y), 0.0, 1.0)
	return lerpf(scale_at_back, scale_at_front, t)

## Sets a dialogue pose ("pose_neutral", "pose_explicacion", "pose_escepticismo",
## "pose_recitado") or any other named animation on the sprite. No-op if this
## instance has no AnimatedSprite2D child.
func set_pose(pose_name: String) -> void:
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(pose_name):
		_sprite.scale = Vector2.ONE * _current_depth_scale * POSE_SCALE_FACTOR
		_sprite.play(pose_name)

## Leaves dialogue-pose scale/animation and returns to the normal walk/idle art.
func clear_pose() -> void:
	if _sprite:
		_sprite.scale = Vector2.ONE * _current_depth_scale
		_sprite.play("idle")

## "left" or "right".
func face(direction: String) -> void:
	if _sprite:
		_sprite.flip_h = (direction == "left")

func _physics_process(delta: float) -> void:
	var walking := is_walking()
	if walking:
		var to_target := _target_position - global_position
		global_position += to_target.normalized() * move_speed * delta
		_current_depth_scale = _depth_scale_for_y(global_position.y)
		if _sprite:
			if to_target.x != 0.0:
				_sprite.flip_h = to_target.x < 0.0
			_sprite.scale = Vector2.ONE * _current_depth_scale
			if _sprite.animation != "walk":
				_sprite.play("walk")
	elif _was_walking:
		_current_depth_scale = _depth_scale_for_y(global_position.y)
		if _sprite:
			_sprite.scale = Vector2.ONE * _current_depth_scale
			_sprite.play("idle")
		arrived.emit()
	_was_walking = walking
