class_name CircuitMonitor
extends RefCounted

## Thin, decoupled event layer on top of RulesEngine. Consumers connect to
## these signals from outside — nothing here requires touching
## rules_engine.gd. See docs/events.md for the walkthrough.

signal on_short_circuit(details: Dictionary)
signal on_component_damaged(details: Dictionary)
signal on_circuit_valid


func check(circuit_doc: Dictionary) -> Dictionary:
	var result := RulesEngine.new().evaluate(circuit_doc)

	for short_circuit in result["short_circuits"]:
		on_short_circuit.emit(short_circuit)

	for damaged in result["damaged_components"]:
		on_component_damaged.emit(damaged)

	if result["is_valid"]:
		on_circuit_valid.emit()

	return result
