extends GdUnitTestSuite

## Proves HU SDK-19: LedState can be unbound from a CircuitMonitor, and unbinds itself
## when its LED leaves the scene tree, so creating and removing LEDs leaks no connections.


func _led_model(auto_freed: bool = true) -> Node3D:
	var model := Node3D.new()
	var lens := MeshInstance3D.new()
	lens.name = LedState.LENS_PART
	var mesh := BoxMesh.new()
	mesh.material = StandardMaterial3D.new()
	lens.mesh = mesh
	model.add_child(lens)
	return auto_free(model) if auto_freed else model


func _connection_count(monitor: CircuitMonitor) -> int:
	return (
		monitor.get_signal_connection_list("on_circuit_valid").size()
		+ monitor.get_signal_connection_list("on_short_circuit").size()
		+ monitor.get_signal_connection_list("on_component_damaged").size()
	)


func test_unbind_stops_following_the_monitor() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	led.bind(monitor, "led_1")

	led.unbind()
	monitor.check(HelloCircuitExample.load_circuit("valid"))

	assert_int(led.state).is_equal(LedState.State.OFF)
	assert_int(_connection_count(monitor)).is_equal(0)


func test_unbind_is_safe_when_not_bound() -> void:
	var led := LedState.new(_led_model())

	led.unbind()
	led.unbind()

	assert_int(led.state).is_equal(LedState.State.OFF)


func test_binding_twice_does_not_duplicate_connections() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()

	led.bind(monitor, "led_1")
	led.bind(monitor, "led_1")

	assert_int(_connection_count(monitor)).is_equal(3)


func test_removing_100_leds_from_the_tree_leaves_no_monitor_connections() -> void:
	var monitor := CircuitMonitor.new()
	var models: Array[Node3D] = []
	for i in 100:
		var model := _led_model()
		add_child(model)
		LedState.new(model).bind(monitor, "led_%d" % i)
		models.append(model)
	assert_int(_connection_count(monitor)).is_equal(300)

	for model in models:
		remove_child(model)

	assert_int(_connection_count(monitor)).is_equal(0)


func test_freeing_a_led_in_the_tree_disconnects_it() -> void:
	var monitor := CircuitMonitor.new()
	var model := _led_model(false)
	add_child(model)
	LedState.new(model).bind(monitor, "led_1")

	model.free()

	assert_int(_connection_count(monitor)).is_equal(0)
