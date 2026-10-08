class_name ComponentPacks
extends RefCounted

## Component packs: catalogs of extra components that live outside the addon (another
## repo, a private folder, a mod), registered at runtime. A pack is a folder with a
## `pack.json` (schema/v1/component-pack.schema.json) and optional glTF models in
## `models/<name>.glb`. Its components get the type `<pack id>.<name>`, build through
## ComponentCatalog like the built-in ones and carry their own `electrical` model, which
## RulesEngine evaluates without knowing the type (see docs/component-packs.md).

const PACK_FILE := "pack.json"
const SCHEMA_VERSION := "v1"
const NAME_PATTERN := "^[a-z][a-z0-9_]*$"

## How RulesEngine treats a pack component, and the `electrical` keys each model needs.
const ELECTRICAL_REQUIRED := {
	"resistive": ["terminals", "resistance_ohm"],
	"rated_load": ["rated_voltage_v", "rated_current_ma"],
	"diode": ["terminals", "forward_voltage_v", "max_current_ma"],
	"switch": ["terminals"],
	"source": ["voltage_v"],
	"none": [],
}

## The schema v1 pin roles (circuit-graph.schema.json, $defs/pinRole).
const PIN_ROLES := [
	"power",
	"ground",
	"digital_io",
	"analog_io",
	"pwm",
	"passive",
	"trigger",
	"echo",
	"wiper",
	"tie_point",
]

static var _entries: Dictionary = {}  # type -> entry (with "type" and "pack_dir")
static var _packs: Dictionary = {}  # pack id -> folder


## Registers the pack in `dir` (e.g. "res://packs/robotics"). Returns its problems; when
## there are any, nothing from the pack is registered. Registering the same folder again
## reloads it.
static func register(dir: String) -> PackedStringArray:
	dir = dir.trim_suffix("/")
	var path := "%s/%s" % [dir, PACK_FILE]
	if not FileAccess.file_exists(path):
		return PackedStringArray(["no %s in %s" % [PACK_FILE, dir]])
	var pack: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not pack is Dictionary:
		return PackedStringArray(["%s is not a JSON object" % path])

	var problems := validate(pack)
	var pack_id: String = str(pack.get("id", ""))
	if problems.is_empty() and _packs.has(pack_id) and _packs[pack_id] != dir:
		problems.append("pack id '%s' is already registered from %s" % [pack_id, _packs[pack_id]])
	if not problems.is_empty():
		return problems

	unregister(pack_id)
	_packs[pack_id] = dir
	for component: Dictionary in pack["components"]:
		var entry := component.duplicate(true)
		entry["type"] = "%s.%s" % [pack_id, component["name"]]
		entry["pack_dir"] = dir
		_entries[entry["type"]] = entry
	return PackedStringArray()


static func unregister(pack_id: String) -> void:
	_packs.erase(pack_id)
	for component_type: String in _entries.keys():
		if component_type.begins_with(pack_id + "."):
			_entries.erase(component_type)


static func unregister_all() -> void:
	_packs.clear()
	_entries.clear()


static func types() -> Array:
	return _entries.keys()


static func has(component_type: String) -> bool:
	return _entries.has(component_type)


## The pack's catalog entry for `component_type` (display_name, pins, electrical, specs,
## parts, extent_m, sources...), or an empty dictionary.
static func entry(component_type: String) -> Dictionary:
	return _entries.get(component_type, {})


static func model_path(component_type: String) -> String:
	var found := entry(component_type)
	if found.is_empty():
		return ""
	return "%s/models/%s.glb" % [found["pack_dir"], found["name"]]


## { pins, parts, extent_m } like data/model_contract.json, for ModelLoader.
static func contract_entry(component_type: String) -> Dictionary:
	var found := entry(component_type)
	if found.is_empty():
		return {}
	var pins: Array = found["pins"].map(func(pin: Dictionary) -> String: return pin["id"])
	return {"pins": pins, "parts": found.get("parts", []), "extent_m": found["extent_m"]}


## A schema v1 circuit graph node for a pack component, ready for RulesEngine.
static func node(component_type: String, node_id: String) -> Dictionary:
	var found := entry(component_type)
	if found.is_empty():
		return {}
	return {
		"id": node_id,
		"type": component_type,
		"pins": found["pins"].duplicate(true),
		"specs": found.get("specs", {}).duplicate(true),
		"electrical": found["electrical"].duplicate(true),
	}


## Problems with a parsed pack.json; empty when the pack is usable.
static func validate(pack: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	if pack.get("schema_version") != SCHEMA_VERSION:
		problems.append("schema_version must be '%s'" % SCHEMA_VERSION)
	if not _is_name(pack.get("id")):
		problems.append("id must match %s" % NAME_PATTERN)
	var components: Variant = pack.get("components")
	if not components is Array or components.is_empty():
		problems.append("components must be a non-empty array")
		return problems

	var seen: Dictionary = {}
	for i in components.size():
		var component: Variant = components[i]
		if not component is Dictionary:
			problems.append("components[%d] is not an object" % i)
			continue
		var label := "components[%d]" % i
		if _is_name(component.get("name")):
			label = str(component["name"])
			if seen.has(label):
				problems.append("%s: duplicated name" % label)
			seen[label] = true
		else:
			problems.append("%s: name must match %s" % [label, NAME_PATTERN])
		for problem in _validate_component(component):
			problems.append("%s: %s" % [label, problem])
	return problems


static func _validate_component(component: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key in ["display_name", "part_reference", "dimensions_source"]:
		if not component.get(key) is String or str(component[key]).is_empty():
			problems.append("%s is required" % key)

	var pin_ids: Array = []
	var pins: Variant = component.get("pins")
	if not pins is Array or pins.is_empty():
		problems.append("pins must be a non-empty array")
	else:
		for pin: Variant in pins:
			if not pin is Dictionary or not pin.get("id") is String or str(pin["id"]).is_empty():
				problems.append("every pin needs an id")
				continue
			if pin_ids.has(pin["id"]):
				problems.append("duplicated pin '%s'" % pin["id"])
			pin_ids.append(pin["id"])
			if not PIN_ROLES.has(pin.get("role")):
				problems.append("pin '%s' has an unknown role" % pin["id"])

	var extent: Variant = component.get("extent_m")
	if not (
		extent is Array
		and extent.size() == 2
		and _is_number(extent[0])
		and _is_number(extent[1])
		and 0.0 < float(extent[0])
		and float(extent[0]) <= float(extent[1])
	):
		problems.append("extent_m must be [min, max] in meters")

	var parts: Variant = component.get("parts", [])
	if not parts is Array:
		problems.append("parts must be an array")
	else:
		for part: Variant in parts:
			if not (part is String and (part.begins_with("STATE_") or part.begins_with("MOVE_"))):
				problems.append("part '%s' must start with STATE_ or MOVE_" % part)

	if component.has("specs") and not component["specs"] is Dictionary:
		problems.append("specs must be an object")
	problems.append_array(_validate_electrical(component.get("electrical"), pins, pin_ids))
	return problems


static func _validate_electrical(
	electrical: Variant, pins: Variant, pin_ids: Array
) -> PackedStringArray:
	var problems := PackedStringArray()
	if not electrical is Dictionary:
		problems.append("electrical is required")
		return problems
	var model: Variant = electrical.get("model")
	if not ELECTRICAL_REQUIRED.has(model):
		problems.append(
			"electrical.model must be one of %s" % ", ".join(ELECTRICAL_REQUIRED.keys())
		)
		return problems

	for key: String in ELECTRICAL_REQUIRED[model]:
		if not electrical.has(key):
			problems.append("electrical.%s is required for '%s'" % [key, model])
	for key: String in electrical:
		if (
			key.ends_with("_v")
			or key.ends_with("_ma")
			or key.ends_with("_ohm")
			or key.ends_with("_w")
		):
			if not _is_number(electrical[key]) or float(electrical[key]) <= 0.0:
				problems.append("electrical.%s must be a positive number" % key)

	if electrical.has("terminals"):
		var terminals: Variant = electrical["terminals"]
		if not terminals is Array or terminals.size() != 2 or terminals[0] == terminals[1]:
			problems.append("electrical.terminals must be two different pin ids")
		else:
			for terminal: Variant in terminals:
				if not pin_ids.has(terminal):
					problems.append("electrical terminal '%s' is not a pin" % terminal)

	if pins is Array and (model == "rated_load" or model == "source"):
		var roles: Array = pins.map(
			func(pin: Variant) -> Variant: return pin.get("role") if pin is Dictionary else null
		)
		if not (roles.has("power") and roles.has("ground")):
			problems.append("a '%s' needs a power and a ground pin" % model)
	return problems


static func _is_name(value: Variant) -> bool:
	if not value is String:
		return false
	var regex := RegEx.create_from_string(NAME_PATTERN)
	return regex.search(value) != null


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
