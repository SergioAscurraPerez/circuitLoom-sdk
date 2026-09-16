class_name ComponentCatalog
extends RefCounted

## Instantiates the 10 v1 component placeholder models
## (addons/circuitloom_sdk/src/components/*.gd) for a scene. Every entry is a
## preloaded script reference, not a runtime class_name lookup or an external
## .tscn — see CLAUDE.md for why that matters for avoiding broken references.

const GRID_SPACING := 0.1

const _COMPONENT_SCRIPTS := {
	"arduino_uno": preload("res://addons/circuitloom_sdk/src/components/arduino_uno.gd"),
	"led": preload("res://addons/circuitloom_sdk/src/components/led.gd"),
	"resistor": preload("res://addons/circuitloom_sdk/src/components/resistor.gd"),
	"push_button": preload("res://addons/circuitloom_sdk/src/components/push_button.gd"),
	"buzzer": preload("res://addons/circuitloom_sdk/src/components/buzzer.gd"),
	"servo_motor": preload("res://addons/circuitloom_sdk/src/components/servo_motor.gd"),
	"potentiometer": preload("res://addons/circuitloom_sdk/src/components/potentiometer.gd"),
	"ultrasonic_sensor":
	preload("res://addons/circuitloom_sdk/src/components/ultrasonic_sensor.gd"),
	"breadboard": preload("res://addons/circuitloom_sdk/src/components/breadboard.gd"),
	"photoresistor": preload("res://addons/circuitloom_sdk/src/components/photoresistor.gd"),
}


static func component_types() -> Array:
	return _COMPONENT_SCRIPTS.keys()


static func build_component(component_type: String) -> Node3D:
	if not _COMPONENT_SCRIPTS.has(component_type):
		return null
	var script: Script = _COMPONENT_SCRIPTS[component_type]
	var instance: Node3D = script.new()
	instance.name = component_type
	return instance


static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "ComponentCatalog"
	var types := component_types()
	for i in types.size():
		var component := build_component(types[i])
		component.position = Vector3(float(i) * GRID_SPACING, 0, 0)
		root.add_child(component)
	return root
