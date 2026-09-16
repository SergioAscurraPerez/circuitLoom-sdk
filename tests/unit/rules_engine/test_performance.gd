extends GdUnitTestSuite

const F := preload("res://tests/unit/rules_engine/fixtures.gd")
const MAX_DURATION_USEC := 16000  # 16ms frame budget
const BRANCH_COUNT := 60


func test_full_circuit_evaluation_runs_within_one_frame_budget() -> void:
	var circuit := _build_many_parallel_branches(BRANCH_COUNT)
	var engine := RulesEngine.new()

	var start_usec := Time.get_ticks_usec()
	var result := engine.evaluate(circuit)
	var elapsed_usec := Time.get_ticks_usec() - start_usec

	assert_bool(result["is_valid"]).is_true()
	assert_int(elapsed_usec).is_less(MAX_DURATION_USEC)


func _build_many_parallel_branches(branch_count: int) -> Dictionary:
	var nodes: Array = [F.arduino(), F.breadboard()]
	var edges: Array = [
		F.edge("power_rail", "arduino_1", "5V", "breadboard_1", "PWR_RAIL_POS"),
		F.edge("ground_rail", "arduino_1", "GND", "breadboard_1", "PWR_RAIL_NEG"),
	]
	for i in range(branch_count):
		var resistor_id := "resistor_%d" % i
		var led_id := "led_%d" % i
		nodes.append(F.resistor(resistor_id, 220.0))
		nodes.append(F.led(led_id))
		edges.append(F.edge("w_%d_a" % i, "breadboard_1", "PWR_RAIL_POS", resistor_id, "a"))
		edges.append(F.edge("w_%d_b" % i, resistor_id, "b", led_id, "anode"))
		edges.append(F.edge("w_%d_c" % i, led_id, "cathode", "breadboard_1", "PWR_RAIL_NEG"))
	return F.doc(nodes, edges, "performance-fixture")
