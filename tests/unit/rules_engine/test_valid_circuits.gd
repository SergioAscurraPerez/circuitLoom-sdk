extends GdUnitTestSuite

const F := RulesEngineFixtures


func test_servo_driven_directly_from_5v_is_valid() -> void:
	var arduino := F.arduino()
	var servo := F.servo_motor("servo_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "servo_1", "vcc"),
		F.edge("w2", "servo_1", "gnd", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, servo], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["servo_1"]).is_equal_approx(250.0, 0.001)


func test_ultrasonic_sensor_driven_directly_from_5v_is_valid() -> void:
	var arduino := F.arduino()
	var sensor := F.ultrasonic_sensor("sensor_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "sensor_1", "vcc"),
		F.edge("w2", "sensor_1", "gnd", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, sensor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()


func test_buzzer_driven_directly_from_5v_is_valid() -> void:
	var arduino := F.arduino()
	var horn := F.buzzer("buzzer_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "buzzer_1", "pos"),
		F.edge("w2", "buzzer_1", "neg", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, horn], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()


func test_potentiometer_is_treated_as_a_fixed_resistor_ignoring_its_wiper() -> void:
	var arduino := F.arduino()
	var pot := F.potentiometer("pot_1", 1000.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "pot_1", "a"),
		F.edge("w2", "pot_1", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, pot], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["pot_1"]).is_equal_approx(5.0, 0.001)


func test_open_button_leaves_its_branch_without_current() -> void:
	var arduino := F.arduino()
	var button := F.push_button("button_1", true)
	var downstream_resistor := F.resistor("resistor_1", 220.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "button_1", "leg_a"),
		F.edge("w2", "button_1", "leg_b", "resistor_1", "a"),
		F.edge("w3", "resistor_1", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, button, downstream_resistor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].has("resistor_1")).is_false()


func test_pin_voltages_reflect_ground_source_and_divider() -> void:
	var arduino := F.arduino()
	var series_resistor := F.resistor("resistor_1", 220.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, series_resistor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	var voltages: Dictionary = result["pin_voltages"]
	assert_float(voltages["arduino_1:5V"]).is_equal_approx(5.0, 0.001)
	assert_float(voltages["arduino_1:GND"]).is_equal_approx(0.0, 0.001)
	assert_float(voltages["resistor_1:b"]).is_equal_approx(0.0, 0.001)


func test_disconnected_component_is_valid_but_carries_no_current() -> void:
	var arduino := F.arduino()
	var floating_led := F.led("led_1")
	var circuit := F.doc([arduino, floating_led], [])

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].has("led_1")).is_false()


func test_parallel_branches_each_get_full_source_voltage() -> void:
	var arduino := F.arduino()
	var resistor_a := F.resistor("resistor_a", 220.0)
	var resistor_b := F.resistor("resistor_b", 470.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_a", "a"),
		F.edge("w2", "resistor_a", "b", "arduino_1", "GND"),
		F.edge("w3", "arduino_1", "5V", "resistor_b", "a"),
		F.edge("w4", "resistor_b", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, resistor_a, resistor_b], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["resistor_a"]).is_equal_approx(22.7273, 0.001)
	assert_float(result["node_currents_ma"]["resistor_b"]).is_equal_approx(10.6383, 0.001)


func test_reference_example_from_schema_v1_has_no_short_circuit() -> void:
	var path := "res://schema/v1/examples/led-button-breadboard.json"
	var text := FileAccess.get_file_as_string(path)
	var circuit: Dictionary = JSON.parse_string(text)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["short_circuits"].is_empty()).is_true()


func test_component_already_tied_together_by_a_wire_is_skipped_as_a_load() -> void:
	var arduino := F.arduino()
	# Both resistor terminals land on the same (power) net via wires, so the
	# resistor can't be a divider element — it should be ignored, not treated
	# as a bridge to nowhere.
	var redundant_resistor := F.resistor("resistor_1", 220.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "arduino_1", "5V", "resistor_1", "b"),
	]
	var circuit := F.doc([arduino, redundant_resistor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].has("resistor_1")).is_false()


func test_path_search_gives_up_beyond_the_max_hop_cap() -> void:
	var arduino := F.arduino()
	var nodes: Array = [arduino]
	var edges: Array = []
	var chain_length := RulesEngine.MAX_PATH_HOPS + 3
	var previous_node := "arduino_1"
	var previous_pin := "5V"
	for i in range(chain_length):
		var resistor_id := "chain_resistor_%d" % i
		nodes.append(F.resistor(resistor_id, 100.0))
		edges.append(F.edge("w_%d" % i, previous_node, previous_pin, resistor_id, "a"))
		previous_node = resistor_id
		previous_pin = "b"
	edges.append(F.edge("w_final", previous_node, previous_pin, "arduino_1", "GND"))
	var circuit := F.doc(nodes, edges, "long-chain")

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].is_empty()).is_true()
