class_name CircuitLoomArduinoUno
extends Node3D

## Placeholder low-poly Arduino UNO: a PCB slab, a USB port block, and one
## header strip. Real board is ~68.6mm x 53.4mm.

const _PCB_COLOR := Color(0.086, 0.243, 0.404)
const _USB_COLOR := Color(0.75, 0.75, 0.78)
const _HEADER_COLOR := Color(0.05, 0.05, 0.05)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_box(self, Vector3(0.0686, 0.0016, 0.0534), Vector3.ZERO, _PCB_COLOR, "PCB")
	ComponentBuilder.add_box(
		self, Vector3(0.012, 0.011, 0.016), Vector3(-0.026, 0.007, -0.019), _USB_COLOR, "USBPort"
	)
	ComponentBuilder.add_box(
		self,
		Vector3(0.05, 0.003, 0.004),
		Vector3(0.005, 0.003, 0.023),
		_HEADER_COLOR,
		"HeaderStrip"
	)
