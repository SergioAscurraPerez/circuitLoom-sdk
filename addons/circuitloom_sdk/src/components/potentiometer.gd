class_name CircuitLoomPotentiometer
extends Node3D

## Placeholder low-poly 10k ohm linear rotary potentiometer: body + shaft +
## three legs.

const _BODY_COLOR := Color(0.1, 0.25, 0.55)
const _SHAFT_COLOR := Color(0.75, 0.75, 0.78)
const _LEG_COLOR := Color(0.75, 0.75, 0.78)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_cylinder(self, 0.008, 0.005, Vector3.ZERO, _BODY_COLOR, "Body")
	ComponentBuilder.add_cylinder(self, 0.0015, 0.006, Vector3(0, 0.0055, 0), _SHAFT_COLOR, "Shaft")

	var leg_offsets := [
		Vector3(-0.004, -0.005, 0.005), Vector3(0.0, -0.005, 0.006), Vector3(0.004, -0.005, 0.005)
	]
	for i in leg_offsets.size():
		ComponentBuilder.add_cylinder(self, 0.0004, 0.004, leg_offsets[i], _LEG_COLOR, "Leg%d" % i)
