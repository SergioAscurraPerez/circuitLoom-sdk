class_name CircuitLoomPushButton
extends Node3D

## Placeholder low-poly 6x6mm tactile push button: base + cap + 4 legs.

const _BASE_COLOR := Color(0.05, 0.05, 0.05)
const _CAP_COLOR := Color(0.8, 0.8, 0.2)
const _LEG_COLOR := Color(0.75, 0.75, 0.78)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_box(self, Vector3(0.006, 0.0035, 0.006), Vector3.ZERO, _BASE_COLOR, "Base")
	ComponentBuilder.add_box(
		self, Vector3(0.0035, 0.0015, 0.0035), Vector3(0, 0.0025, 0), _CAP_COLOR, "Cap"
	)
	var offsets := [
		Vector3(-0.003, -0.003, -0.003),
		Vector3(0.003, -0.003, -0.003),
		Vector3(-0.003, -0.003, 0.003),
		Vector3(0.003, -0.003, 0.003)
	]
	for i in offsets.size():
		ComponentBuilder.add_cylinder(self, 0.0003, 0.003, offsets[i], _LEG_COLOR, "Leg%d" % i)
