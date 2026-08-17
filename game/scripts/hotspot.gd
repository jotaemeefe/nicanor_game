extends Area2D
class_name Hotspot

## Reusable, Inspector-configurable point-and-click hotspot.
## Left click = primary interaction, right click = observe.
## Hitbox and placeholder visual are generated at runtime from exported
## properties, so every instance stays a plain property override in its
## scene file (no per-instance sub-resource overrides needed).

@export var hotspot_name: String = ""
@export var observe_text: String = ""
@export var interact_text: String = ""
## Optional second-variant interact text, meaning depends on the hotspot
## (e.g. "already done" for the formulario). Scene controllers decide when to
## use it; Hotspot itself stays generic.
@export var interact_text_alt: String = ""
@export var triggers_dialogue: bool = false
@export var hitbox_size: Vector2 = Vector2(96, 96)
@export var visual_color: Color = Color(0.55, 0.5, 0.4, 0.9)
## When true, the hitbox/placeholder polygon is not drawn — used for hotspots
## laid directly over a detail already painted into the background art.
@export var invisible: bool = false
## Where Nicanor should stand before this hotspot resolves, relative to the
## hotspot's own position. Zero means "don't walk him anywhere first".
@export var approach_point: Vector2 = Vector2.ZERO
## "left" or "right" — which way Nicanor faces once he arrives.
@export var look_direction: String = "right"

signal hovered(hotspot: Hotspot)
signal unhovered(hotspot: Hotspot)
signal interacted(hotspot: Hotspot)
signal observed(hotspot: Hotspot)

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Visual

func _ready() -> void:
	input_pickable = true
	_apply_hitbox()
	_apply_visual()
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _apply_hitbox() -> void:
	var shape := RectangleShape2D.new()
	shape.size = hitbox_size
	_collision_shape.shape = shape

## Soft highlight tint shown on hover, regardless of `invisible` — the
## debug/placeholder polygon and the hover cue are separate concerns: most
## hotspots have no polygon art of their own (`invisible = true`) but should
## still flash something under the cursor so the player can tell what's
## interactive, alongside the name shown via the `hovered` signal.
const HOVER_COLOR := Color(1, 0.92, 0.6, 0.28)

func _apply_visual() -> void:
	var hw := hitbox_size.x / 2.0
	var hh := hitbox_size.y / 2.0
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	_visual.color = visual_color
	_visual.visible = not invisible

## Approach point in global coordinates (approach_point is stored relative to
## the hotspot so it stays correct if the hotspot is repositioned).
func approach_global_position() -> Vector2:
	return global_position + approach_point

func _on_mouse_entered() -> void:
	_visual.color = HOVER_COLOR if invisible else visual_color.lightened(0.3)
	_visual.visible = true
	hovered.emit(self)

func _on_mouse_exited() -> void:
	_visual.color = visual_color
	_visual.visible = not invisible
	unhovered.emit(self)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			interacted.emit(self)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			observed.emit(self)
			get_viewport().set_input_as_handled()
