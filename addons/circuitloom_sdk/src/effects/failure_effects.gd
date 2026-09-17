class_name FailureEffects
extends RefCounted

## Spawns the SDK's reference short-circuit feedback (spark + smoke) under a
## given Node3D — see docs/effects.md. Both effects are preloaded scripts
## (not class_name lookups or a .tscn) for the same reason ComponentCatalog
## avoids them: see CLAUDE.md.

const SparkEffect := preload("res://addons/circuitloom_sdk/src/effects/spark_effect.gd")
const SmokeEffect := preload("res://addons/circuitloom_sdk/src/effects/smoke_effect.gd")


static func spawn_short_circuit(parent: Node3D, position: Vector3 = Vector3.ZERO) -> Array[Node3D]:
	var spark: Node3D = SparkEffect.new()
	var smoke: Node3D = SmokeEffect.new()

	for effect in [spark, smoke]:
		effect.position = position
		parent.add_child(effect)

	return [spark, smoke]
