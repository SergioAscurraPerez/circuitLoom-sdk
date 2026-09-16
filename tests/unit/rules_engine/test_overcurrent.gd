extends GdUnitTestSuite

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func test_led_without_series_resistor_is_flagged_as_damaged() -> void:
	var arduino := F.arduino()
	var bare_led := F.led("led_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "led_1", "anode"),
		F.edge("w2", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, bare_led], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["damaged_components"]).is_not_empty()
	assert_str(result["damaged_components"][0]["node_id"]).is_equal("led_1")


func test_led_with_correctly_sized_resistor_is_not_damaged() -> void:
	var arduino := F.arduino()
	var current_limiter := F.resistor("resistor_1", 220.0)
	var safe_led := F.led("led_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "anode"),
		F.edge("w3", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, current_limiter, safe_led], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_array(result["damaged_components"]).is_empty()
	assert_float(result["node_currents_ma"]["led_1"]).is_equal_approx(15.625, 0.001)


func test_resistor_exceeding_its_power_rating_is_flagged_as_damaged() -> void:
	var arduino := F.arduino()
	# 10 ohm at 5V draws 500mA -> 2.5W, well above a 0.25W-rated resistor.
	var undersized_resistor := F.resistor("resistor_1", 10.0, 0.25)
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, undersized_resistor], edges)

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_false()
	assert_array(result["damaged_components"]).is_not_empty()
	assert_str(result["damaged_components"][0]["node_id"]).is_equal("resistor_1")
