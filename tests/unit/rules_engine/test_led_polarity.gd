extends GdUnitTestSuite

## Proves HU SDK-18: an LED only conducts from anode to cathode; wired backwards its
## branch is open, like a real diode.

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func test_forward_biased_led_conducts() -> void:
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "anode"),
		F.edge("w3", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([F.arduino(), F.resistor("resistor_1", 220.0), F.led("led_1")], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["led_1"]).is_equal_approx(15.625, 0.001)


func test_reverse_biased_led_leaves_its_branch_open() -> void:
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "cathode"),
		F.edge("w3", "led_1", "anode", "arduino_1", "GND"),
	]
	var circuit := F.doc([F.arduino(), F.resistor("resistor_1", 220.0), F.led("led_1")], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_bool(result["node_currents_ma"].has("led_1")).is_false()
	assert_bool(result["node_currents_ma"].has("resistor_1")).is_false()


func test_reverse_biased_led_without_a_resistor_is_not_damaged() -> void:
	var edges := [
		F.edge("w1", "arduino_1", "5V", "led_1", "cathode"),
		F.edge("w2", "led_1", "anode", "arduino_1", "GND"),
	]
	var circuit := F.doc([F.arduino(), F.led("led_1")], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_array(result["damaged_components"]).is_empty()


func test_only_the_forward_led_of_an_antiparallel_pair_conducts() -> void:
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "anode"),
		F.edge("w3", "led_1", "cathode", "arduino_1", "GND"),
		F.edge("w4", "resistor_1", "b", "led_2", "cathode"),
		F.edge("w5", "led_2", "anode", "arduino_1", "GND"),
	]
	var nodes := [F.arduino(), F.resistor("resistor_1", 220.0), F.led("led_1"), F.led("led_2")]
	var circuit := F.doc(nodes, edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["led_1"]).is_equal_approx(15.625, 0.001)
	assert_bool(result["node_currents_ma"].has("led_2")).is_false()


func test_led_without_anode_and_cathode_pins_is_treated_as_non_polar() -> void:
	var led := F.led("led_1")
	led["pins"] = [{"id": "a", "role": "passive"}, {"id": "b", "role": "passive"}]
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "b"),
		F.edge("w3", "led_1", "a", "arduino_1", "GND"),
	]
	var circuit := F.doc([F.arduino(), F.resistor("resistor_1", 220.0), led], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_float(result["node_currents_ma"]["led_1"]).is_equal_approx(15.625, 0.001)
