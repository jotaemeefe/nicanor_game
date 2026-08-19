extends Node2D

## Turns the ceiling fan's blades, in the fan's own plane rather than in the
## screen plane.
##
## Two failures led to this shape, both worth keeping in mind before changing it:
##
## 1. It used to be a two-frame AnimatedSprite2D whose frames had been cropped
##    out of the reference sheet with the fan in different spots of the canvas,
##    so it jumped ~42px sideways every 1.4s instead of turning.
## 2. Replacing that with the whole fan as one rotating image pulled the fan
##    apart: the sheet draws its three blades at visibly different radii, so
##    under the projection each blade travelled its own ellipse.
##
## So the children here are three instances of ONE blade, 120° apart. Identical
## blades on one ellipse stay consistent at every angle.
##
## The perspective is in the transform chain, not in the art: the parent
## (FanPlane) squashes Y by the foreshortening the blade is drawn with, and each
## blade undoes that with its own scale — so a blade is drawn exactly as painted
## at its own angle, and correctly projected at every other one. Rotating
## without that pair would tumble the whole ellipse and read as a wobble.
##
## The hub and rod are not children of this node: FanHub draws over the blades,
## hiding their roots and occluding a blade that sweeps up behind the rod.

## "Gira con una lentitud casi filosófica" (its own observe text), so this is
## deliberately far slower than a real fan: one turn every four seconds.
@export var revolutions_per_second: float = 0.25

func _process(delta: float) -> void:
	rotation += TAU * revolutions_per_second * delta
