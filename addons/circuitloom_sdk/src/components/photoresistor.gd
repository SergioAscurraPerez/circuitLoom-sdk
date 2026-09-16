class_name CircuitLoomPhotoresistor
extends Node3D

## Placeholder low-poly GL5528 photoresistor (LDR): a flat disc with a
## darker zigzag-sensor detail on top, and two leads.

const _BODY_COLOR := Color(0.85, 0.8, 0.55)
const _SENSOR_COLOR := Color(0.35, 0.3, 0.15)
const _LEAD_COLOR := Color(0.75, 0.75, 0.78)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_cylinder(self, 0.0025, 0.0015, Vector3.ZERO, _BODY_COLOR, "Body")
	ComponentBuilder.add_cylinder(
		self, 0.0018, 0.0003, Vector3(0, 0.0009, 0), _SENSOR_COLOR, "SensorSurface"
	)
	ComponentBuilder.add_cylinder(
		self, 0.0003, 0.01, Vector3(-0.0012, -0.005, 0), _LEAD_COLOR, "LeadA"
	)
	ComponentBuilder.add_cylinder(
		self, 0.0003, 0.01, Vector3(0.0012, -0.005, 0), _LEAD_COLOR, "LeadB"
	)
