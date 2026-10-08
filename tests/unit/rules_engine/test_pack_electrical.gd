extends GdUnitTestSuite

## Proves HU SDK-22: RulesEngine evaluates component-pack nodes from their `electrical`
## model alone, without knowing their type.

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func _pack_node(id: String, pins: Array, electrical: Dictionary) -> Dictionary:
	var pin_list: Array = []
	for pin: Array in pins:
		pin_list.append({"id": pin[0], "role": pin[1]})
	return {"id": id, "type": "test.part", "pins": pin_list, "specs": {}, "electrical": electrical}


func _resistive(id: String, ohms: float, extra: Dictionary = {}) -> Dictionary:
	var electrical := {"model": "resistive", "terminals": ["a", "b"], "resistance_ohm": ohms}
	electrical.merge(extra)
	return _pack_node(id, [["a", "passive"], ["b", "passive"]], electrical)


func _diode(id: String) -> Dictionary:
	return _pack_node(
		id,
		[["anode", "passive"], ["cathode", "passive"]],
		{
			"model": "diode",
			"terminals": ["anode", "cathode"],
			"forward_voltage_v": 2.0,
			"max_current_ma": 20.0,
		}
	)


func _battery(id: String, volts: float) -> Dictionary:
	return _pack_node(
		id, [["pos", "power"], ["neg", "ground"]], {"model": "source", "voltage_v": volts}
	)


func _across_arduino(part_id: String, pin_a: String, pin_b: String) -> Array:
	return [
		F.edge("w1", "arduino_1", "5V", part_id, pin_a),
		F.edge("w2", part_id, pin_b, "arduino_1", "GND"),
	]


func test_resistive_part_draws_ohms_law_current() -> void:
	var circuit := F.doc([F.arduino(), _resistive("r", 250.0)], _across_arduino("r", "a", "b"))

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["r"]).is_equal_approx(20.0, 0.001)


func test_resistive_part_is_damaged_over_its_power_rating() -> void:
	var part := _resistive("r", 10.0, {"max_power_w": 0.25})
	var circuit := F.doc([F.arduino(), part], _across_arduino("r", "a", "b"))

	var result := RulesEngine.new().evaluate(circuit)

	assert_array(result["damaged_components"]).has_size(1)
	assert_str(result["damaged_components"][0]["node_id"]).is_equal("r")


func test_rated_load_uses_its_power_and_ground_pins() -> void:
	var motor := _pack_node(
		"m",
		[["vcc", "power"], ["gnd", "ground"], ["sig", "digital_io"]],
		{"model": "rated_load", "rated_voltage_v": 5.0, "rated_current_ma": 100.0}
	)
	var circuit := F.doc([F.arduino(), motor], _across_arduino("m", "vcc", "gnd"))

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["m"]).is_equal_approx(100.0, 0.001)


func test_diode_conducts_only_from_anode_to_cathode() -> void:
	var forward := (
		F
		. doc(
			[F.arduino(), F.resistor("r", 150.0), _diode("d")],
			[
				F.edge("w1", "arduino_1", "5V", "r", "a"),
				F.edge("w2", "r", "b", "d", "anode"),
				F.edge("w3", "d", "cathode", "arduino_1", "GND"),
			]
		)
	)
	var backwards := F.doc([F.arduino(), _diode("d")], _across_arduino("d", "cathode", "anode"))

	var forward_result := RulesEngine.new().evaluate(forward)
	var backwards_result := RulesEngine.new().evaluate(backwards)

	assert_float(forward_result["node_currents_ma"]["d"]).is_equal_approx(20.0, 0.001)
	assert_bool(backwards_result["is_valid"]).is_true()
	assert_bool(backwards_result["node_currents_ma"].has("d")).is_false()


func test_closed_switch_is_a_wire_and_open_switch_a_gap() -> void:
	var pins := [["a", "passive"], ["b", "passive"]]
	var closed := _pack_node(
		"s", pins, {"model": "switch", "terminals": ["a", "b"], "closed": true}
	)
	var open := _pack_node("s", pins, {"model": "switch", "terminals": ["a", "b"]})

	var closed_result := RulesEngine.new().evaluate(
		F.doc([F.arduino(), closed], _across_arduino("s", "a", "b"))
	)
	var open_result := RulesEngine.new().evaluate(
		F.doc([F.arduino(), open], _across_arduino("s", "a", "b"))
	)

	assert_array(closed_result["short_circuits"]).is_not_empty()
	assert_bool(open_result["is_valid"]).is_true()


func test_source_powers_a_circuit_without_an_arduino() -> void:
	var circuit := F.doc(
		[_battery("bat", 6.0), _resistive("r", 300.0)],
		[F.edge("w1", "bat", "pos", "r", "a"), F.edge("w2", "r", "b", "bat", "neg")]
	)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["r"]).is_equal_approx(20.0, 0.001)
	assert_float(result["pin_voltages"]["bat:pos"]).is_equal_approx(6.0, 0.001)


func test_shorted_source_is_a_direct_short() -> void:
	var circuit := F.doc([_battery("bat", 6.0)], [F.edge("w1", "bat", "pos", "bat", "neg")])

	var result := RulesEngine.new().evaluate(circuit)

	assert_array(result["short_circuits"]).has_size(1)
	assert_str(result["short_circuits"][0]["cause"]).is_equal("direct_short")


func test_none_model_takes_no_part_in_the_circuit() -> void:
	var bracket := _pack_node("x", [["a", "passive"], ["b", "passive"]], {"model": "none"})
	var circuit := F.doc([F.arduino(), bracket], _across_arduino("x", "a", "b"))

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].has("x")).is_false()


func test_registered_pack_node_evaluates_like_a_hand_written_one() -> void:
	ComponentPacks.register("res://examples/component_pack")
	var diode := ComponentPacks.node("example.rectifier_diode", "d")
	var circuit := F.doc(
		[ComponentPacks.node("example.battery_holder_4aa", "bat"), diode],
		[F.edge("w1", "bat", "pos", "d", "anode"), F.edge("w2", "d", "cathode", "bat", "neg")]
	)

	var result := RulesEngine.new().evaluate(circuit)
	ComponentPacks.unregister_all()

	# 6 V straight across a 1.1 V / 1 A diode: ~5.5 A, far over its 1 A rating.
	assert_array(result["damaged_components"]).has_size(1)
	assert_str(result["damaged_components"][0]["node_id"]).is_equal("d")
