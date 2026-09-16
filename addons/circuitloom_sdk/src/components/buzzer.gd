class_name CircuitLoomBuzzer
extends Node3D

## Placeholder low-poly active piezo buzzer: a black disc body with a
## sound-hole detail and two leads.

const _BODY_COLOR := Color(0.05, 0.05, 0.05)
const _HOLE_COLOR := Color(0.15, 0.15, 0.15)
const _LEAD_COLOR := Color(0.8, 0.1, 0.1)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_cylinder(self, 0.006, 0.005, Vector3.ZERO, _BODY_COLOR, "Body")
	ComponentBuilder.add_cylinder(
		self, 0.0015, 0.001, Vector3(0, 0.003, 0), _HOLE_COLOR, "SoundHole"
	)
	ComponentBuilder.add_cylinder(
		self, 0.0004, 0.012, Vector3(-0.002, -0.008, 0), _LEAD_COLOR, "LeadPositive"
	)
	ComponentBuilder.add_cylinder(
		self, 0.0004, 0.012, Vector3(0.002, -0.008, 0), Color(0.05, 0.05, 0.05), "LeadNegative"
	)
