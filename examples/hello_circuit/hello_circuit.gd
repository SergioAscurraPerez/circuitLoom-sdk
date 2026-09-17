class_name HelloCircuitExample
extends RefCounted

## Minimal, runnable walkthrough of CircuitLoom's event system. See
## docs/events.md for the step-by-step explanation. Run headless with:
## godot --headless --script res://examples/hello_circuit/run_example.gd

const CIRCUITS_DIR := "res://examples/hello_circuit/circuits"
const FailureEffects := preload("res://addons/circuitloom_sdk/src/effects/failure_effects.gd")


static func load_circuit(circuit_name: String) -> Dictionary:
	var path := "%s/%s.json" % [CIRCUITS_DIR, circuit_name]
	var text := FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)


## `effects_root`, when given, gets the spark/smoke reference effects
## (docs/effects.md) spawned under it on every `on_short_circuit` — see
## run_example.gd for how the CLI entrypoint wires this up.
static func run(effects_root: Node3D = null) -> void:
	var monitor := CircuitMonitor.new()

	monitor.on_short_circuit.connect(
		func(details: Dictionary) -> void: print("[hello_circuit] short circuit: %s" % details)
	)
	monitor.on_component_damaged.connect(
		func(details: Dictionary) -> void: print("[hello_circuit] component damaged: %s" % details)
	)
	monitor.on_circuit_valid.connect(func() -> void: print("[hello_circuit] circuit is valid"))

	if effects_root != null:
		monitor.on_short_circuit.connect(
			func(_details: Dictionary) -> void: FailureEffects.spawn_short_circuit(effects_root)
		)

	print("--- valid circuit ---")
	monitor.check(load_circuit("valid"))

	print("--- short circuit ---")
	monitor.check(load_circuit("short_circuit"))

	print("--- overcurrent circuit ---")
	monitor.check(load_circuit("overcurrent"))
