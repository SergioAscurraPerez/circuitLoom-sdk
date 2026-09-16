extends GdUnitTestSuite

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func test_direct_wire_short() -> void:
	var arduino := F.arduino()
	var circuit := F.doc([arduino], [F.edge("w1", "arduino_1", "5V", "arduino_1", "GND")])

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["short_circuits"]).is_not_empty()


func test_short_through_breadboard_power_rails() -> void:
	var arduino := F.arduino()
	var bb := F.breadboard()
	var edges := [
		F.edge("w1", "arduino_1", "5V", "breadboard_1", "PWR_RAIL_POS"),
		F.edge("w2", "arduino_1", "GND", "breadboard_1", "PWR_RAIL_NEG"),
		F.edge("w3", "breadboard_1", "PWR_RAIL_POS", "breadboard_1", "PWR_RAIL_NEG"),
	]
	var circuit := F.doc([arduino, bb], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["short_circuits"]).is_not_empty()


func test_closed_switch_short() -> void:
	var arduino := F.arduino()
	var button := F.push_button("button_1", false)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "button_1", "leg_a"),
		F.edge("w2", "button_1", "leg_b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, button], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["short_circuits"]).is_not_empty()


func test_zero_ohm_resistor_short() -> void:
	var arduino := F.arduino()
	var faulty_resistor := F.resistor("resistor_1", 0.0)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, faulty_resistor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["short_circuits"]).is_not_empty()
	assert_str(result["short_circuits"][0]["cause"]).is_equal("zero_resistance_path")


func test_short_is_detected_alongside_an_otherwise_valid_branch() -> void:
	var arduino := F.arduino()
	var good_resistor := F.resistor("resistor_1", 220.0)
	var good_led := F.led("led_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "arduino_1", "GND"),
		F.edge("w2", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w3", "resistor_1", "b", "led_1", "anode"),
		F.edge("w4", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, good_resistor, good_led], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["short_circuits"]).is_not_empty()
