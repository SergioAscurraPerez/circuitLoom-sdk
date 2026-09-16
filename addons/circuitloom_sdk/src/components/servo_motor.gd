class_name CircuitLoomServoMotor
extends Node3D

## Placeholder low-poly SG90 micro servo: body + horn + the servo's fixed
## 3-wire cable, colored per its own real convention — brown=GND, red=VCC,
## orange=signal (docs/components.md) — which is NOT the general wire-color
## rule the rest of the SDK's wires follow.

const _BODY_COLOR := Color(0.15, 0.35, 0.65)
const _HORN_COLOR := Color(0.9, 0.9, 0.85)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_box(self, Vector3(0.023, 0.028, 0.012), Vector3.ZERO, _BODY_COLOR, "Body")
	ComponentBuilder.add_box(
		self, Vector3(0.032, 0.003, 0.02), Vector3(0.004, 0.0155, 0), _BODY_COLOR, "MountingTabs"
	)
	ComponentBuilder.add_box(
		self, Vector3(0.02, 0.002, 0.004), Vector3(0, 0.018, 0), _HORN_COLOR, "Horn"
	)

	var cable_offsets := [
		Vector3(-0.001, -0.017, -0.002),
		Vector3(0.0, -0.017, -0.002),
		Vector3(0.001, -0.017, -0.002),
	]
	var cable_colors := [Color(0.35, 0.2, 0.1), Color(0.8, 0.1, 0.1), Color(0.9, 0.5, 0.1)]
	var cable_names := ["GndWire", "VccWire", "SignalWire"]
	for i in cable_offsets.size():
		ComponentBuilder.add_cylinder(
			self, 0.0004, 0.01, cable_offsets[i], cable_colors[i], cable_names[i]
		)
