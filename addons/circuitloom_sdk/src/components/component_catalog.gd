class_name ComponentCatalog
extends RefCounted

## Instantiates the 10 v1 component models for a scene. A component uses its realistic
## glTF model (models/<type>.glb, see ModelLoader) when one exists and satisfies the
## model contract; otherwise it falls back to the placeholder built by its script
## (addons/circuitloom_sdk/src/components/*.gd). Every fallback entry is a preloaded
## script reference, not a runtime class_name lookup or an external .tscn — see
## CLAUDE.md for why that matters for avoiding broken references.
##
## Components from registered packs (ComponentPacks) build the same way: their model
## from the pack's models/ folder, or a generic placeholder with their pins.

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


## The built-in types followed by the types of every registered pack.
static func component_types() -> Array:
	return _COMPONENT_SCRIPTS.keys() + ComponentPacks.types()


static func build_component(component_type: String) -> Node3D:
	var is_pack := ComponentPacks.has(component_type)
	if not is_pack and not _COMPONENT_SCRIPTS.has(component_type):
		return null
	var instance := ModelLoader.load_model(component_type)
	if instance == null and is_pack:
		instance = _pack_placeholder(ComponentPacks.entry(component_type))
	elif instance == null:
		var script: Script = _COMPONENT_SCRIPTS[component_type]
		instance = script.new()
	# Node names can't hold the "." of a pack type: use the component's own name.
	instance.name = ComponentPacks.entry(component_type)["name"] if is_pack else component_type
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


## A gray box at the middle of the component's size range, with a PIN_ marker per pin
## along its front top edge and an empty node per driven part, so a pack component works
## (wires, pin picking) before it has a model.
static func _pack_placeholder(entry: Dictionary) -> Node3D:
	var root := Node3D.new()
	var extent: Array = entry["extent_m"]
	var length := (float(extent[0]) + float(extent[1])) / 2.0
	var size := Vector3(length, length * 0.3, length * 0.5)
	ComponentBuilder.add_box(
		root, size, Vector3(0, size.y / 2.0, 0), Color(0.55, 0.57, 0.6), "Body"
	)
	var pins: Array = entry["pins"]
	for i in pins.size():
		var marker := Marker3D.new()
		marker.name = ModelLoader.PIN_PREFIX + str(pins[i]["id"])
		var x := -size.x / 2.0 + size.x * (float(i) + 0.5) / float(pins.size())
		marker.position = Vector3(x, size.y, -size.z / 2.0)
		root.add_child(marker)
	for part: String in entry.get("parts", []):
		var part_node := Node3D.new()
		part_node.name = part
		part_node.position = Vector3(0, size.y, 0)
		root.add_child(part_node)
	return root
