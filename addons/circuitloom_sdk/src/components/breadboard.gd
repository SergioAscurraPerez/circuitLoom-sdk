class_name CircuitLoomBreadboard
extends Node3D

## Placeholder low-poly 830-point breadboard: white body with the red/blue
## power-rail stripes printed on real breadboards along both long edges.

const _BODY_COLOR := Color(0.92, 0.92, 0.9)
const _POSITIVE_RAIL_COLOR := Color(0.8, 0.1, 0.1)
const _NEGATIVE_RAIL_COLOR := Color(0.1, 0.2, 0.7)
const _WIDTH := 0.165
const _DEPTH := 0.055
const _HEIGHT := 0.008


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_box(
		self, Vector3(_WIDTH, _HEIGHT, _DEPTH), Vector3.ZERO, _BODY_COLOR, "Body"
	)

	var stripe_size := Vector3(_WIDTH, 0.0005, 0.002)
	var top_z := -_DEPTH * 0.5 + 0.004
	var bottom_z := _DEPTH * 0.5 - 0.004
	ComponentBuilder.add_box(
		self, stripe_size, Vector3(0, _HEIGHT * 0.5, top_z), _POSITIVE_RAIL_COLOR, "TopPositiveRail"
	)
	ComponentBuilder.add_box(
		self,
		stripe_size,
		Vector3(0, _HEIGHT * 0.5, top_z + 0.003),
		_NEGATIVE_RAIL_COLOR,
		"TopNegativeRail"
	)
	ComponentBuilder.add_box(
		self,
		stripe_size,
		Vector3(0, _HEIGHT * 0.5, bottom_z),
		_NEGATIVE_RAIL_COLOR,
		"BottomNegativeRail"
	)
	ComponentBuilder.add_box(
		self,
		stripe_size,
		Vector3(0, _HEIGHT * 0.5, bottom_z - 0.003),
		_POSITIVE_RAIL_COLOR,
		"BottomPositiveRail"
	)
