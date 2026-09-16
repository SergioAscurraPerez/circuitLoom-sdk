class_name CircuitLoomLed
extends Node3D

## Placeholder low-poly 5mm LED: cylindrical body + dome + two leads. The
## anode lead is modeled longer than the cathode, matching the real
## long-lead-is-anode convention (see docs/components.md).

const _LEAD_COLOR := Color(0.75, 0.75, 0.78)
const _RADIUS := 0.0025
const _BODY_HEIGHT := 0.006

@export var led_color: Color = Color(0.85, 0.1, 0.1)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_cylinder(
		self, _RADIUS, _BODY_HEIGHT, Vector3(0, _BODY_HEIGHT * 0.5, 0), led_color, "Body"
	)
	ComponentBuilder.add_sphere(self, _RADIUS, Vector3(0, _BODY_HEIGHT, 0), led_color, "Dome")
	# Anode (+): longer lead.
	ComponentBuilder.add_cylinder(
		self, 0.0004, 0.012, Vector3(-0.0015, -0.006, 0), _LEAD_COLOR, "AnodeLead"
	)
	# Cathode (-): shorter lead.
	ComponentBuilder.add_cylinder(
		self, 0.0004, 0.008, Vector3(0.0015, -0.004, 0), _LEAD_COLOR, "CathodeLead"
	)
