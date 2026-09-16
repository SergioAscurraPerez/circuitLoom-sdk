extends GdUnitTestSuite

## Exercises RulesEngine's internal helpers directly for spec/type edge cases
## that a full circuit fixture can't reach cleanly (guard clauses, unknown
## component types, missing optional spec fields).


func test_voltage_over_current_guards_against_zero_and_negative_current() -> void:
	var engine := RulesEngine.new()

	assert_float(engine._voltage_over_current(5.0, 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(engine._voltage_over_current(5.0, -10.0)).is_equal_approx(0.0, 0.001)
	assert_float(engine._voltage_over_current(2.0, 20.0)).is_equal_approx(100.0, 0.001)


func test_effective_resistance_defaults_to_zero_for_non_load_types() -> void:
	var engine := RulesEngine.new()

	var arduino_resistance := engine._effective_resistance_ohm({"type": "arduino_uno", "specs": {}})
	var breadboard_resistance := engine._effective_resistance_ohm(
		{"type": "breadboard", "specs": {}}
	)

	assert_float(arduino_resistance).is_equal_approx(0.0, 0.001)
	assert_float(breadboard_resistance).is_equal_approx(0.0, 0.001)


func test_max_current_defaults_to_infinite_when_unrated() -> void:
	var engine := RulesEngine.new()

	var resistor_without_power_rating := engine._max_current_ma(
		{"type": "resistor", "specs": {"resistance_ohm": 100.0}}
	)
	var resistor_with_zero_resistance := engine._max_current_ma(
		{"type": "resistor", "specs": {"resistance_ohm": 0.0, "max_power_w": 0.25}}
	)
	var potentiometer_rating := engine._max_current_ma({"type": "potentiometer", "specs": {}})

	assert_bool(is_inf(resistor_without_power_rating)).is_true()
	assert_bool(is_inf(resistor_with_zero_resistance)).is_true()
	assert_bool(is_inf(potentiometer_rating)).is_true()


func test_max_current_derives_from_power_rating_when_present() -> void:
	var engine := RulesEngine.new()

	var current := engine._max_current_ma(
		{"type": "resistor", "specs": {"resistance_ohm": 10.0, "max_power_w": 0.25}}
	)

	assert_float(current).is_equal_approx(158.1139, 0.001)


func test_branch_pins_is_empty_for_multi_pin_component_missing_a_required_role() -> void:
	var engine := RulesEngine.new()

	var pins := (
		engine
		. _branch_pins(
			{
				"type": "servo_motor",
				"pins": [{"id": "sig", "role": "pwm"}],
			}
		)
	)

	assert_array(pins).is_empty()


func test_branch_pins_is_empty_when_fewer_than_two_usable_pins() -> void:
	var engine := RulesEngine.new()

	var pins := (
		engine
		. _branch_pins(
			{
				"type": "resistor",
				"pins": [{"id": "a", "role": "passive"}],
			}
		)
	)

	assert_array(pins).is_empty()


func test_branch_pins_is_empty_for_unbranchable_types() -> void:
	var engine := RulesEngine.new()

	var pins := engine._branch_pins({"type": "breadboard", "pins": []})

	assert_array(pins).is_empty()


func test_find_pin_id_by_role_returns_empty_string_when_missing() -> void:
	var engine := RulesEngine.new()

	var found := engine._find_pin_id_by_role([{"id": "a", "role": "passive"}], "power")

	assert_str(found).is_equal("")


func test_union_find_collapses_chains_and_is_idempotent() -> void:
	var uf := RulesEngine._UnionFind.new()

	uf.union("a", "b")
	uf.union("b", "c")
	uf.union("a", "a")

	assert_str(uf.find("a")).is_equal(uf.find("c"))


func test_dedupe_short_circuits_collapses_matching_entries() -> void:
	var engine := RulesEngine.new()
	var input := [
		{"cause": "direct_short", "component_id": "", "net_id": "n1"},
		{"cause": "direct_short", "component_id": "", "net_id": "n1"},
		{"cause": "direct_short", "component_id": "", "net_id": "n2"},
	]

	var result := engine._dedupe_short_circuits(input)

	assert_array(result).has_size(2)


func test_dedupe_damaged_keeps_the_highest_current_reading() -> void:
	var engine := RulesEngine.new()
	var input := [
		{"node_id": "r1", "current_ma": 30.0, "max_current_ma": 20.0},
		{"node_id": "r1", "current_ma": 45.0, "max_current_ma": 20.0},
		{"node_id": "r1", "current_ma": 10.0, "max_current_ma": 20.0},
	]

	var result := engine._dedupe_damaged(input)

	assert_array(result).has_size(1)
	assert_float(result[0]["current_ma"]).is_equal_approx(45.0, 0.001)
