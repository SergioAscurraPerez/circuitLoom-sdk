extends GdUnitTestSuite

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func test_valid_circuit_emits_on_circuit_valid_only() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())
	var arduino := F.arduino()
	var series_resistor := F.resistor("resistor_1", 220.0)
	var safe_led := F.led("led_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "resistor_1", "a"),
		F.edge("w2", "resistor_1", "b", "led_1", "anode"),
		F.edge("w3", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, series_resistor, safe_led], edges)

	monitor.check(circuit)

	await assert_signal(monitor).is_emitted(monitor.on_circuit_valid)
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_short_circuit, any())
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_component_damaged, any())


func test_short_circuit_emits_on_short_circuit_only() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())
	var arduino := F.arduino()
	var circuit := F.doc([arduino], [F.edge("w1", "arduino_1", "5V", "arduino_1", "GND")])

	monitor.check(circuit)

	await assert_signal(monitor).is_emitted(monitor.on_short_circuit, any())
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_circuit_valid)
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_component_damaged, any())


func test_overcurrent_emits_on_component_damaged_only() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())
	var arduino := F.arduino()
	var bare_led := F.led("led_1")
	var edges := [
		F.edge("w1", "arduino_1", "5V", "led_1", "anode"),
		F.edge("w2", "led_1", "cathode", "arduino_1", "GND"),
	]
	var circuit := F.doc([arduino, bare_led], edges)

	monitor.check(circuit)

	await assert_signal(monitor).is_emitted(monitor.on_component_damaged, any())
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_circuit_valid)
	await assert_signal(monitor).wait_until(50).is_not_emitted(monitor.on_short_circuit, any())


func test_on_short_circuit_payload_matches_the_rules_engine_result() -> void:
	var monitor := CircuitMonitor.new()
	var arduino := F.arduino()
	var circuit := F.doc([arduino], [F.edge("w1", "arduino_1", "5V", "arduino_1", "GND")])

	var result := monitor.check(circuit)

	assert_array(result["short_circuits"]).is_not_equal(null)
	assert_bool(result["is_valid"]).is_false()


func test_check_returns_the_full_rules_engine_result() -> void:
	var monitor := CircuitMonitor.new()
	var arduino := F.arduino()
	var circuit := F.doc([arduino], [])

	var result := monitor.check(circuit)

	assert_dict(result).contains_keys(
		["is_valid", "short_circuits", "damaged_components", "node_currents_ma", "pin_voltages"]
	)
