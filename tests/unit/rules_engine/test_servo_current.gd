extends GdUnitTestSuite

## Proves HU SDK-21: a servo holding still draws its idle current; only a stalled one
## draws its stall current.

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func _servo_on_5v(servo: Dictionary) -> Dictionary:
	var edges := [
		F.edge("w1", "arduino_1", "5V", "servo_1", "vcc"),
		F.edge("w2", "servo_1", "gnd", "arduino_1", "GND"),
	]
	return F.doc([F.arduino(), servo], edges)


func test_idle_servo_draws_its_idle_current() -> void:
	var circuit := _servo_on_5v(F.servo_motor("servo_1", 5.0, 650.0, 10.0))

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["servo_1"]).is_equal_approx(10.0, 0.001)


func test_stalled_servo_draws_its_stall_current() -> void:
	var circuit := _servo_on_5v(F.servo_motor("servo_1", 5.0, 650.0, 10.0, true))

	var result := RulesEngine.new().evaluate(circuit)

	assert_bool(result["is_valid"]).is_true()
	assert_float(result["node_currents_ma"]["servo_1"]).is_equal_approx(650.0, 0.001)


func test_servo_without_idle_current_keeps_the_stall_current() -> void:
	var circuit := _servo_on_5v(F.servo_motor("servo_1", 5.0, 650.0))

	var result := RulesEngine.new().evaluate(circuit)

	assert_float(result["node_currents_ma"]["servo_1"]).is_equal_approx(650.0, 0.001)


func test_catalog_servo_is_idle_by_default() -> void:
	var path := "res://addons/circuitloom_sdk/data/components.json"
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var entries: Array = catalog["components"].filter(
		func(entry: Dictionary) -> bool: return entry["type"] == "servo_motor"
	)
	var servo := F.servo_motor("servo_1")
	servo["specs"] = entries[0]["specs"]

	var result := RulesEngine.new().evaluate(_servo_on_5v(servo))

	assert_float(result["node_currents_ma"]["servo_1"]).is_equal_approx(
		float(entries[0]["specs"]["idle_current_ma"]), 0.001
	)
