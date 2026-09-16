class_name CircuitLoomResistor
extends Node3D

## Placeholder low-poly resistor: tan body with two wire leads, banded with
## the real 220 ohm 5% color code (red, red, brown, gold) — see
## docs/components.md.

const _BODY_COLOR := Color(0.85, 0.75, 0.55)
const _LEAD_COLOR := Color(0.75, 0.75, 0.78)
const _BAND_COLORS := [
	Color(0.8, 0.1, 0.1),  # red
	Color(0.8, 0.1, 0.1),  # red
	Color(0.4, 0.2, 0.05),  # brown
	Color(0.83, 0.68, 0.21),  # gold
]
const _BODY_LENGTH := 0.0064
const _RADIUS := 0.0013


func _ready() -> void:
	_build()


func _build() -> void:
	var body := ComponentBuilder.add_cylinder(
		self, _RADIUS, _BODY_LENGTH, Vector3.ZERO, _BODY_COLOR, "Body", _RADIUS
	)
	body.rotation_degrees = Vector3(0, 0, 90)

	var band_span := _BODY_LENGTH * 0.6
	var start_x := -band_span * 0.5
	for i in _BAND_COLORS.size():
		var x := start_x + (band_span / (_BAND_COLORS.size() - 1)) * i
		var band := ComponentBuilder.add_cylinder(
			self,
			_RADIUS + 0.0002,
			0.0006,
			Vector3(x, 0, 0),
			_BAND_COLORS[i],
			"Band%d" % i,
			_RADIUS + 0.0002
		)
		band.rotation_degrees = Vector3(0, 0, 90)

	var lead_a := ComponentBuilder.add_cylinder(
		self, 0.0004, 0.01, Vector3(-_BODY_LENGTH * 0.5 - 0.005, 0, 0), _LEAD_COLOR, "LeadA"
	)
	lead_a.rotation_degrees = Vector3(0, 0, 90)

	var lead_b := ComponentBuilder.add_cylinder(
		self, 0.0004, 0.01, Vector3(_BODY_LENGTH * 0.5 + 0.005, 0, 0), _LEAD_COLOR, "LeadB"
	)
	lead_b.rotation_degrees = Vector3(0, 0, 90)
