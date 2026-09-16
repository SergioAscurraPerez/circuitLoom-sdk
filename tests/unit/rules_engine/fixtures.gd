class_name RulesEngineFixtures
extends RefCounted

## Small builders for schema-v1-shaped circuit dictionaries, used only by the
## rules engine test suite (kept out of the addon itself).


static func arduino(id: String = "arduino_1", voltage: float = 5.0) -> Dictionary:
	return {
		"id": id,
		"type": "arduino_uno",
		"pins":
		[
			{"id": "5V", "role": "power"},
			{"id": "GND", "role": "ground"},
		],
		"specs": {"operating_voltage_v": voltage, "digital_pins": 14, "analog_pins": 6},
	}


static func breadboard(id: String = "breadboard_1") -> Dictionary:
	return {
		"id": id,
		"type": "breadboard",
		"pins":
		[
			{"id": "PWR_RAIL_POS", "role": "power"},
			{"id": "PWR_RAIL_NEG", "role": "ground"},
		],
		"specs": {"rows": 30, "columns": 10, "has_power_rails": true},
	}


static func resistor(id: String, ohms: float, max_power_w: Variant = null) -> Dictionary:
	var specs: Dictionary = {"resistance_ohm": ohms}
	if max_power_w != null:
		specs["max_power_w"] = max_power_w
	return {
		"id": id,
		"type": "resistor",
		"pins": [{"id": "a", "role": "passive"}, {"id": "b", "role": "passive"}],
		"specs": specs,
	}


static func led(
	id: String, forward_voltage_v: float = 2.0, max_current_ma: float = 20.0
) -> Dictionary:
	return {
		"id": id,
		"type": "led",
		"pins": [{"id": "anode", "role": "passive"}, {"id": "cathode", "role": "passive"}],
		"specs":
		{"color": "red", "forward_voltage_v": forward_voltage_v, "max_current_ma": max_current_ma},
	}


static func push_button(
	id: String, normally_open: bool = true, max_voltage_v: float = 5.0, max_current_ma: float = 50.0
) -> Dictionary:
	return {
		"id": id,
		"type": "push_button",
		"pins": [{"id": "leg_a", "role": "passive"}, {"id": "leg_b", "role": "passive"}],
		"specs":
		{
			"max_voltage_v": max_voltage_v,
			"max_current_ma": max_current_ma,
			"normally_open": normally_open
		},
	}


static func buzzer(
	id: String, rated_voltage_v: float = 5.0, max_current_ma: float = 30.0, kind: String = "active"
) -> Dictionary:
	return {
		"id": id,
		"type": "buzzer",
		"pins": [{"id": "pos", "role": "power"}, {"id": "neg", "role": "ground"}],
		"specs":
		{"kind": kind, "rated_voltage_v": rated_voltage_v, "max_current_ma": max_current_ma},
	}


static func servo_motor(
	id: String, operating_voltage_v: float = 5.0, stall_current_ma: float = 250.0
) -> Dictionary:
	return {
		"id": id,
		"type": "servo_motor",
		"pins":
		[
			{"id": "vcc", "role": "power"},
			{"id": "gnd", "role": "ground"},
			{"id": "sig", "role": "pwm"},
		],
		"specs":
		{
			"operating_voltage_v": operating_voltage_v,
			"stall_current_ma": stall_current_ma,
			"rotation_range_deg": 180
		},
	}


static func ultrasonic_sensor(
	id: String, operating_voltage_v: float = 5.0, max_current_ma: float = 15.0
) -> Dictionary:
	return {
		"id": id,
		"type": "ultrasonic_sensor",
		"pins":
		[
			{"id": "vcc", "role": "power"},
			{"id": "gnd", "role": "ground"},
			{"id": "trig", "role": "trigger"},
			{"id": "echo", "role": "echo"},
		],
		"specs":
		{
			"operating_voltage_v": operating_voltage_v,
			"max_current_ma": max_current_ma,
			"range_cm_min": 2,
			"range_cm_max": 400
		},
	}


static func potentiometer(
	id: String, resistance_ohm: float = 10000.0, taper: String = "linear"
) -> Dictionary:
	return {
		"id": id,
		"type": "potentiometer",
		"pins":
		[
			{"id": "a", "role": "passive"},
			{"id": "wiper", "role": "wiper"},
			{"id": "b", "role": "passive"},
		],
		"specs": {"resistance_ohm": resistance_ohm, "taper": taper},
	}


static func edge(
	id: String, from_node: String, from_pin: String, to_node: String, to_pin: String
) -> Dictionary:
	return {
		"id": id,
		"from": {"node_id": from_node, "pin_id": from_pin},
		"to": {"node_id": to_node, "pin_id": to_pin},
	}


static func doc(nodes: Array, edges: Array, circuit_id: String = "test-circuit") -> Dictionary:
	return {
		"schema_version": "v1",
		"circuit": {"id": circuit_id, "nodes": nodes, "edges": edges},
	}
