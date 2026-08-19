extends Sprite2D

## Spins the ceiling fan rotor, in the fan's own plane rather than in the
## screen plane.
##
## The previous version was a two-frame AnimatedSprite2D, and the two frames
## had been cropped out of the reference sheet with the fan in different spots
## of the canvas, so the fan jumped ~42px sideways every 1.4s instead of
## turning. One image rotating continuously has no such failure mode.
##
## The perspective is handled by the transform chain, not by the art: the
## parent (FanPlane) squashes Y by the fan's foreshortening factor, this node's
## own scale undoes it, so at rest the art is drawn exactly as painted and at
## any other angle it sweeps the same ellipse the blades are drawn on. Rotating
## the sprite alone would tumble the whole ellipse and read as a wobble.
##
## The rod is not part of this node — see FanMount, drawn on top so a blade
## sweeping up behind the rod is occluded by it.

## "Gira con una lentitud casi filosófica" (its own observe text), so this is
## deliberately far slower than a real fan: one turn every four seconds.
@export var revolutions_per_second: float = 0.25

func _process(delta: float) -> void:
	rotation += TAU * revolutions_per_second * delta
