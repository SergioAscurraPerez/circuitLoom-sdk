class_name CircuitLoomUltrasonicSensor
extends Node3D

## Placeholder low-poly HC-SR04: green PCB with its two characteristic
## transducer "eyes" plus a 4-pin header.

const _PCB_COLOR := Color(0.1, 0.45, 0.2)
const _TRANSDUCER_COLOR := Color(0.75, 0.75, 0.78)
const _HEADER_COLOR := Color(0.05, 0.05, 0.05)


func _ready() -> void:
	_build()


func _build() -> void:
	ComponentBuilder.add_box(self, Vector3(0.045, 0.002, 0.02), Vector3.ZERO, _PCB_COLOR, "PCB")
	ComponentBuilder.add_cylinder(
		self, 0.008, 0.012, Vector3(-0.011, 0.007, 0), _TRANSDUCER_COLOR, "TransmitterEye"
	)
	ComponentBuilder.add_cylinder(
		self, 0.008, 0.012, Vector3(0.011, 0.007, 0), _TRANSDUCER_COLOR, "ReceiverEye"
	)
	ComponentBuilder.add_box(
		self, Vector3(0.03, 0.004, 0.0025), Vector3(0, -0.003, -0.009), _HEADER_COLOR, "Header"
	)
