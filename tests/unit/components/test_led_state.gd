extends GdUnitTestSuite

## Proves HU SDK-12: an LED model shows off / on / burned by changing the material of
## its STATE_Lens part, and follows the CircuitMonitor events.

const F := preload("res://tests/unit/rules_engine/fixtures.gd")


func _led_model(shared_material: StandardMaterial3D = null) -> Node3D:
	var model := Node3D.new()
	var lens := MeshInstance3D.new()
	lens.name = LedState.LENS_PART
	var mesh := BoxMesh.new()
	mesh.material = shared_material if shared_material != null else _red_material()
	lens.mesh = mesh
	model.add_child(lens)
	return auto_free(model)


func _red_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.2, 0.2)
	material.roughness = 0.15
	return material


func _lens_material(model: Node) -> StandardMaterial3D:
	var lens := model.find_child(LedState.LENS_PART, true, false) as MeshInstance3D
	return lens.get_active_material(0)


func test_a_new_led_is_off() -> void:
	var model := _led_model()
	var led := LedState.new(model)

	assert_bool(led.is_attached()).is_true()
	assert_int(led.state).is_equal(LedState.State.OFF)
	assert_bool(_lens_material(model).emission_enabled).is_false()


func test_on_lights_the_lens_with_its_own_color() -> void:
	var model := _led_model()
	var led := LedState.new(model)

	led.set_state(LedState.State.ON)

	var material := _lens_material(model)
	assert_bool(material.emission_enabled).is_true()
	assert_object(material.emission).is_equal(Color(0.9, 0.2, 0.2))
	assert_float(material.emission_energy_multiplier).is_equal(LedState.ON_EMISSION_ENERGY)


func test_burned_turns_the_lens_dark_and_dull() -> void:
	var model := _led_model()
	var led := LedState.new(model)
	led.set_state(LedState.State.ON)

	led.set_state(LedState.State.BURNED)

	var material := _lens_material(model)
	assert_bool(material.emission_enabled).is_false()
	assert_object(material.albedo_color).is_equal(LedState.BURNED_COLOR)
	assert_float(material.roughness).is_equal_approx(LedState.BURNED_ROUGHNESS, 0.001)


func test_reset_restores_the_original_look() -> void:
	var model := _led_model()
	var led := LedState.new(model)
	led.set_state(LedState.State.BURNED)

	led.reset()

	var material := _lens_material(model)
	assert_int(led.state).is_equal(LedState.State.OFF)
	assert_object(material.albedo_color).is_equal(Color(0.9, 0.2, 0.2))
	assert_float(material.roughness).is_equal_approx(0.15, 0.001)


func test_leds_sharing_a_model_material_do_not_light_each_other() -> void:
	var shared := _red_material()
	var first := _led_model(shared)
	var second := _led_model(shared)
	var first_led := LedState.new(first)
	LedState.new(second)

	first_led.set_state(LedState.State.ON)

	assert_bool(_lens_material(first).emission_enabled).is_true()
	assert_bool(_lens_material(second).emission_enabled).is_false()
	assert_bool(shared.emission_enabled).is_false()


func test_model_without_a_lens_is_left_untouched() -> void:
	var model: Node3D = auto_free(Node3D.new())
	var led := LedState.new(model)

	led.set_state(LedState.State.ON)

	assert_bool(led.is_attached()).is_false()


func test_the_model_keeps_its_led_state_alive() -> void:
	var model := _led_model()

	LedState.new(model)

	assert_bool(model.has_meta(LedState.META_KEY)).is_true()


func test_valid_circuit_lights_the_led_that_carries_current() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	led.bind(monitor, "led_1")

	monitor.check(HelloCircuitExample.load_circuit("valid"))

	assert_int(led.state).is_equal(LedState.State.ON)


func test_valid_circuit_keeps_an_unpowered_led_off() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	led.bind(monitor, "led_1")

	monitor.check(F.doc([F.arduino(), F.led("led_1")], []))

	assert_int(led.state).is_equal(LedState.State.OFF)


func test_short_circuit_turns_a_lit_led_off() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	led.bind(monitor, "led_1")
	monitor.check(HelloCircuitExample.load_circuit("valid"))

	monitor.check(HelloCircuitExample.load_circuit("short_circuit"))

	assert_int(led.state).is_equal(LedState.State.OFF)


func test_overcurrent_burns_only_the_damaged_led() -> void:
	var damaged := LedState.new(_led_model())
	var other := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	damaged.bind(monitor, "led_1")
	other.bind(monitor, "led_2")

	monitor.check(HelloCircuitExample.load_circuit("overcurrent"))

	assert_int(damaged.state).is_equal(LedState.State.BURNED)
	assert_int(other.state).is_equal(LedState.State.OFF)


func test_a_burned_led_stays_burned_when_the_circuit_becomes_valid() -> void:
	var led := LedState.new(_led_model())
	var monitor := CircuitMonitor.new()
	led.bind(monitor, "led_1")
	monitor.check(HelloCircuitExample.load_circuit("overcurrent"))

	monitor.check(HelloCircuitExample.load_circuit("valid"))

	assert_int(led.state).is_equal(LedState.State.BURNED)
