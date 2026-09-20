class_name ModelLoader
extends RefCounted

## Loads the realistic glTF model of a component (models/<type>.glb) and checks it
## against the model contract (data/model_contract.json). Returns null when the model
## is missing or breaks the contract, so ComponentCatalog can fall back to the
## primitive placeholder instead of leaving a broken or unanchored component in the scene.

const MODELS_DIR := "res://addons/circuitloom_sdk/models/"
const CONTRACT_PATH := "res://addons/circuitloom_sdk/data/model_contract.json"
const PIN_PREFIX := "PIN_"


static func model_path(component_type: String) -> String:
	return "%s%s.glb" % [MODELS_DIR, component_type]


## The contract for every component type: { type: { pins, parts, extent_m } }.
static func contract() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if parsed is Dictionary and parsed.has("components"):
		return parsed["components"]
	return {}


static func load_model(component_type: String) -> Node3D:
	var path := model_path(component_type)
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("CircuitLoom: could not load %s; using the primitive fallback." % path)
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null

	var problems := validate(instance, component_type)
	if not problems.is_empty():
		push_warning(
			(
				"CircuitLoom: %s breaks the model contract (%s); using the primitive fallback."
				% [path, ", ".join(problems)]
			)
		)
		instance.free()
		return null
	return instance


## Problems that make `root` unusable as the model of `component_type`; empty when it
## satisfies the contract: every contract pin and part is present and no PIN_ node
## is unknown.
static func validate(root: Node, component_type: String) -> PackedStringArray:
	var problems := PackedStringArray()
	var entry: Variant = contract().get(component_type)
	if entry == null:
		problems.append("no contract for type '%s'" % component_type)
		return problems

	for pin: String in entry["pins"]:
		if root.find_child(PIN_PREFIX + pin, true, false) == null:
			problems.append("missing %s%s" % [PIN_PREFIX, pin])
	for part: String in entry["parts"]:
		if root.find_child(part, true, false) == null:
			problems.append("missing %s" % part)

	for node in root.find_children(PIN_PREFIX + "*", "", true, false):
		if not (entry["pins"] as Array).has(str(node.name).trim_prefix(PIN_PREFIX)):
			problems.append("unknown %s" % node.name)
	return problems
