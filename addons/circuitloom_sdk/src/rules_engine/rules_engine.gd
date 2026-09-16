class_name RulesEngine
extends RefCounted

## Simplified circuit rules engine: consumes a schema v1 circuit graph and
## computes per-pin voltage and per-component current, flagging short
## circuits and overcurrent (damaged) components.

const MAX_PATH_HOPS := 12
const MAX_PATHS_PER_SOURCE := 500
const EPSILON := 1e-6

## type -> [voltage spec key, current spec key], for load types whose effective
## resistance is derived (rated voltage / rated current) rather than given
## directly as a resistance spec.
const RATED_VOLTAGE_CURRENT_SPEC_KEYS := {
	"led": ["forward_voltage_v", "max_current_ma"],
	"buzzer": ["rated_voltage_v", "max_current_ma"],
	"servo_motor": ["operating_voltage_v", "stall_current_ma"],
	"ultrasonic_sensor": ["operating_voltage_v", "max_current_ma"],
}


class _UnionFind:
	var _parent: Dictionary = {}

	func make_set(key: String) -> void:
		if not _parent.has(key):
			_parent[key] = key

	func find(key: String) -> String:
		make_set(key)
		var root: String = key
		while _parent[root] != root:
			root = _parent[root]
		var cur: String = key
		while _parent[cur] != root:
			var next_cur: String = _parent[cur]
			_parent[cur] = root
			cur = next_cur
		return root

	func union(a: String, b: String) -> void:
		var root_a: String = find(a)
		var root_b: String = find(b)
		if root_a != root_b:
			_parent[root_a] = root_b


func evaluate(circuit_doc: Dictionary) -> Dictionary:
	var circuit: Dictionary = circuit_doc.get("circuit", {})
	var nodes: Array = circuit.get("nodes", [])
	var edges: Array = circuit.get("edges", [])

	var uf := _UnionFind.new()
	for node in nodes:
		for pin in node["pins"]:
			uf.make_set(_pin_key(node["id"], pin["id"]))

	for edge in edges:
		var from_key := _pin_key(edge["from"]["node_id"], edge["from"]["pin_id"])
		var to_key := _pin_key(edge["to"]["node_id"], edge["to"]["pin_id"])
		uf.union(from_key, to_key)

	# A normally-closed button behaves as an ideal wire; fold it into the net
	# union step so it's indistinguishable from a hardwired connection.
	for node in nodes:
		if node["type"] == "push_button":
			var specs: Dictionary = node["specs"]
			if specs.get("normally_open", true) == false:
				var branch := _branch_pins(node)
				if branch.size() == 2:
					uf.union(_pin_key(node["id"], branch[0]), _pin_key(node["id"], branch[1]))

	var power_nets: Dictionary = {}  # net root -> source voltage
	var ground_nets: Dictionary = {}  # net root -> true
	for node in nodes:
		if node["type"] != "arduino_uno":
			continue
		var voltage: float = float(node["specs"]["operating_voltage_v"])
		for pin in node["pins"]:
			var root := uf.find(_pin_key(node["id"], pin["id"]))
			if pin["role"] == "power":
				power_nets[root] = voltage
			elif pin["role"] == "ground":
				ground_nets[root] = true

	var short_circuits: Array = []
	for root in power_nets.keys():
		if ground_nets.has(root):
			(
				short_circuits
				. append(
					{
						"cause": "direct_short",
						"component_id": "",
						"net_id": root,
					}
				)
			)

	var adjacency: Dictionary = {}  # net root -> Array[hop]
	for node in nodes:
		if node["type"] == "push_button":
			continue  # switches only ever become a wire (above) or an open gap
		var branch := _branch_pins(node)
		if branch.size() != 2:
			continue
		var root_a := uf.find(_pin_key(node["id"], branch[0]))
		var root_b := uf.find(_pin_key(node["id"], branch[1]))
		if root_a == root_b:
			continue  # already tied together by a wire; no divider to compute
		var resistance := _effective_resistance_ohm(node)
		var max_current := _max_current_ma(node)
		_add_adjacency(adjacency, root_a, root_b, resistance, max_current, node["id"])
		_add_adjacency(adjacency, root_b, root_a, resistance, max_current, node["id"])

	var damaged: Array = []
	var node_currents: Dictionary = {}
	var net_voltages: Dictionary = {}
	for root in ground_nets.keys():
		net_voltages[root] = 0.0

	var ground_roots: Array = ground_nets.keys()
	for power_root in power_nets.keys():
		if ground_nets.has(power_root):
			continue  # rail is already dead-shorted; no meaningful divider downstream
		var source_voltage: float = power_nets[power_root]
		net_voltages[power_root] = source_voltage
		var paths := _find_paths(adjacency, power_root, ground_roots)
		for path in paths:
			_apply_path(
				path,
				source_voltage,
				short_circuits,
				damaged,
				node_currents,
				net_voltages,
				power_root
			)

	var pin_voltages: Dictionary = {}
	for node in nodes:
		for pin in node["pins"]:
			var root := uf.find(_pin_key(node["id"], pin["id"]))
			if net_voltages.has(root):
				pin_voltages[_pin_key(node["id"], pin["id"])] = net_voltages[root]

	short_circuits = _dedupe_short_circuits(short_circuits)
	damaged = _dedupe_damaged(damaged)

	return {
		"is_valid": short_circuits.is_empty() and damaged.is_empty(),
		"short_circuits": short_circuits,
		"damaged_components": damaged,
		"node_currents_ma": node_currents,
		"pin_voltages": pin_voltages,
	}


func _apply_path(
	path: Array,
	source_voltage: float,
	short_circuits: Array,
	damaged: Array,
	node_currents: Dictionary,
	net_voltages: Dictionary,
	power_root: String
) -> void:
	var total_resistance := 0.0
	for hop in path:
		total_resistance += hop["resistance"]

	if total_resistance <= EPSILON:
		(
			short_circuits
			. append(
				{
					"cause": "zero_resistance_path",
					"component_id": path[0]["node_id"],
					"net_id": power_root,
				}
			)
		)
		return

	var current_a: float = source_voltage / total_resistance
	var current_ma: float = current_a * 1000.0
	var cumulative_resistance := 0.0
	for hop in path:
		var node_id: String = hop["node_id"]
		node_currents[node_id] = max(node_currents.get(node_id, 0.0), current_ma)
		if current_ma > hop["max_current_ma"] + EPSILON:
			(
				damaged
				. append(
					{
						"node_id": node_id,
						"current_ma": current_ma,
						"max_current_ma": hop["max_current_ma"],
					}
				)
			)
		cumulative_resistance += hop["resistance"]
		net_voltages[hop["to"]] = source_voltage - current_a * cumulative_resistance


func _find_paths(adjacency: Dictionary, start: String, targets: Array) -> Array:
	var results: Array = []
	var visited: Dictionary = {start: true}
	_dfs_paths(adjacency, start, targets, [], visited, results)
	return results


func _dfs_paths(
	adjacency: Dictionary,
	current: String,
	targets: Array,
	path_so_far: Array,
	visited: Dictionary,
	results: Array
) -> void:
	if results.size() >= MAX_PATHS_PER_SOURCE or path_so_far.size() >= MAX_PATH_HOPS:
		return
	for hop in adjacency.get(current, []):
		var next_net: String = hop["to"]
		if visited.has(next_net):
			continue
		var extended: Array = path_so_far.duplicate()
		extended.append(hop)
		if targets.has(next_net):
			results.append(extended)
			if results.size() >= MAX_PATHS_PER_SOURCE:
				return
			continue
		visited[next_net] = true
		_dfs_paths(adjacency, next_net, targets, extended, visited, results)
		visited.erase(next_net)


func _branch_pins(node: Dictionary) -> Array:
	var pins: Array = node["pins"]
	match node["type"]:
		"resistor", "led", "buzzer", "potentiometer", "push_button", "photoresistor":
			var usable: Array = []
			for pin in pins:
				if pin["role"] != "wiper":
					usable.append(pin["id"])
				if usable.size() == 2:
					break
			return usable if usable.size() == 2 else []
		"servo_motor", "ultrasonic_sensor":
			var power_pin := _find_pin_id_by_role(pins, "power")
			var ground_pin := _find_pin_id_by_role(pins, "ground")
			return [power_pin, ground_pin] if power_pin != "" and ground_pin != "" else []
		_:
			return []


func _find_pin_id_by_role(pins: Array, role: String) -> String:
	for pin in pins:
		if pin["role"] == role:
			return pin["id"]
	return ""


func _effective_resistance_ohm(node: Dictionary) -> float:
	var specs: Dictionary = node["specs"]
	var type: String = node["type"]

	if type == "resistor" or type == "potentiometer":
		return float(specs.get("resistance_ohm", 0.0))

	if type == "photoresistor":
		# v1 has no light model — evaluate at the datasheet's dark-state
		# resistance (its highest, most conservative reading).
		return float(specs.get("dark_resistance_ohm", 0.0))

	if RATED_VOLTAGE_CURRENT_SPEC_KEYS.has(type):
		var spec_keys: Array = RATED_VOLTAGE_CURRENT_SPEC_KEYS[type]
		return _voltage_over_current(specs.get(spec_keys[0], 0.0), specs.get(spec_keys[1], 0.0))

	return 0.0


func _voltage_over_current(voltage: Variant, current_ma: Variant) -> float:
	var current_a: float = float(current_ma) / 1000.0
	if current_a <= 0.0:
		return 0.0
	return float(voltage) / current_a


func _max_current_ma(node: Dictionary) -> float:
	var specs: Dictionary = node["specs"]
	var type: String = node["type"]
	if type == "resistor":
		var resistance: float = float(specs.get("resistance_ohm", 0.0))
		if specs.has("max_power_w") and resistance > 0.0:
			return sqrt(float(specs["max_power_w"]) / resistance) * 1000.0
		return INF
	if type == "led" or type == "buzzer" or type == "ultrasonic_sensor":
		return float(specs.get("max_current_ma", INF))
	if type == "servo_motor":
		return float(specs.get("stall_current_ma", INF))
	return INF


func _add_adjacency(
	adjacency: Dictionary,
	from_root: String,
	to_root: String,
	resistance: float,
	max_current_ma: float,
	node_id: String
) -> void:
	if not adjacency.has(from_root):
		adjacency[from_root] = []
	(
		adjacency[from_root]
		. append(
			{
				"to": to_root,
				"resistance": resistance,
				"max_current_ma": max_current_ma,
				"node_id": node_id,
			}
		)
	)


func _pin_key(node_id: String, pin_id: String) -> String:
	return "%s:%s" % [node_id, pin_id]


func _dedupe_short_circuits(list: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for item in list:
		var key: String = "%s|%s|%s" % [item["cause"], item["component_id"], item["net_id"]]
		if not seen.has(key):
			seen[key] = true
			result.append(item)
	return result


func _dedupe_damaged(list: Array) -> Array:
	var index_by_node: Dictionary = {}
	var result: Array = []
	for item in list:
		var node_id: String = item["node_id"]
		if index_by_node.has(node_id):
			var idx: int = index_by_node[node_id]
			if item["current_ma"] > result[idx]["current_ma"]:
				result[idx] = item
			continue
		index_by_node[node_id] = result.size()
		result.append(item)
	return result
