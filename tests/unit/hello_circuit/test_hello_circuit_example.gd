extends GdUnitTestSuite

## Proves the three circuit events actually fire in the reference example
## from docs/events.md (HU SDK-05, acceptance criterion 1) — using the exact
## same circuits/*.json fixtures the example script loads.

const HelloCircuit := preload("res://examples/hello_circuit/hello_circuit.gd")


func test_loads_all_three_reference_circuits() -> void:
	for circuit_name in ["valid", "short_circuit", "overcurrent"]:
		var circuit := HelloCircuit.load_circuit(circuit_name)
		assert_str(circuit["schema_version"]).is_equal("v1")


func test_reference_example_fires_on_circuit_valid() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())

	monitor.check(HelloCircuit.load_circuit("valid"))

	await assert_signal(monitor).is_emitted(monitor.on_circuit_valid)


func test_reference_example_fires_on_short_circuit() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())

	monitor.check(HelloCircuit.load_circuit("short_circuit"))

	await assert_signal(monitor).is_emitted(monitor.on_short_circuit)


func test_reference_example_fires_on_component_damaged() -> void:
	var monitor: CircuitMonitor = monitor_signals(CircuitMonitor.new())

	monitor.check(HelloCircuit.load_circuit("overcurrent"))

	await assert_signal(monitor).is_emitted(monitor.on_component_damaged)


func test_run_executes_without_error() -> void:
	HelloCircuit.run()
