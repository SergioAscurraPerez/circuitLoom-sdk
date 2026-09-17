extends GdUnitTestSuite

## Proves HU SDK-07 acceptance criteria: the spark/smoke reference effects
## ship in the addon, require nothing outside the Godot engine, and fire
## within 200ms of on_short_circuit.

const FailureEffects := preload("res://addons/circuitloom_sdk/src/effects/failure_effects.gd")
const _MAX_REACTION_MS := 200


func test_spawn_short_circuit_adds_one_spark_and_one_smoke_effect() -> void:
	var parent := Node3D.new()
	add_child(auto_free(parent))

	var effects := FailureEffects.spawn_short_circuit(parent)

	assert_array(effects).has_size(2)
	assert_object(effects[0]).is_instanceof(CircuitLoomSparkEffect)
	assert_object(effects[1]).is_instanceof(CircuitLoomSmokeEffect)
	assert_int(parent.get_child_count()).is_equal(2)


func test_spawned_effects_start_emitting_immediately() -> void:
	var parent := Node3D.new()
	add_child(auto_free(parent))

	var effects := FailureEffects.spawn_short_circuit(parent)

	for effect in effects:
		var particle := effect as CPUParticles3D
		assert_bool(particle.emitting).is_true()
		assert_bool(particle.one_shot).is_true()


func test_effects_use_no_external_resources() -> void:
	var parent := Node3D.new()
	add_child(auto_free(parent))

	for effect in FailureEffects.spawn_short_circuit(parent):
		var particle := effect as CPUParticles3D
		assert_object(particle.mesh).is_instanceof(QuadMesh)
		assert_str(particle.mesh.resource_path).is_empty()
		assert_object(particle.material_override).is_instanceof(StandardMaterial3D)


func test_short_circuit_event_triggers_effects_within_200ms() -> void:
	var parent := Node3D.new()
	add_child(auto_free(parent))
	var monitor: CircuitMonitor = CircuitMonitor.new()
	monitor.on_short_circuit.connect(
		func(_details: Dictionary) -> void: FailureEffects.spawn_short_circuit(parent)
	)

	var started_at := Time.get_ticks_msec()
	monitor.on_short_circuit.emit({"cause": "test"})
	var elapsed_ms := Time.get_ticks_msec() - started_at

	assert_int(parent.get_child_count()).is_equal(2)
	assert_int(elapsed_ms).is_less_equal(_MAX_REACTION_MS)
