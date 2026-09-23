# Failure effects (spark + smoke)

CircuitLoom ships a ready-to-use spark + smoke reference effect for short-circuit
feedback, so a consumer doesn't have to build particle effects from scratch just to get
visual feedback when `CircuitMonitor.on_short_circuit` fires (see [events.md](events.md)).

- Spark: `addons/circuitloom_sdk/src/effects/spark_effect.gd` (`CircuitLoomSparkEffect`)
- Smoke: `addons/circuitloom_sdk/src/effects/smoke_effect.gd` (`CircuitLoomSmokeEffect`)
- Spawner: `addons/circuitloom_sdk/src/effects/failure_effects.gd` (`FailureEffects`)

Both effects are `CPUParticles3D` built entirely from Godot's built-in `QuadMesh`,
`StandardMaterial3D` and a radial `GradientTexture2D` generated in code for the round,
soft-edged particles (no image file, model, or other external asset), the same
no-external-dependency approach `ComponentBuilder` uses for the 3D component
placeholders (see [components.md](components.md)). `CPUParticles3D` — not
`GPUParticles3D` — so the effects also run in a headless/CI environment without a
compute-capable renderer. Each effect is one-shot and frees itself once it finishes.

## Spawning the effects

```gdscript
const FailureEffects := preload("res://addons/circuitloom_sdk/src/effects/failure_effects.gd")

FailureEffects.spawn_short_circuit(some_node_3d, position)  # -> [spark, smoke]
```

`spawn_short_circuit` instantiates one spark and one smoke effect, adds both as children
of `parent` at `position` (defaults to `Vector3.ZERO`), and returns them. Both start
emitting immediately — spawning is synchronous, so the effect fires within the same
frame the caller triggers it in.

## Scale and position

The effects are authored at real-world scale, like the component models (1 unit = 1 m):
a spark burst that jumps about a centimeter and a smoke puff that rises a few
centimeters. They simulate in local coordinates, so spawning them under a component
makes them scale and move with it:

```gdscript
# Sparks on the Arduino's power header, even when the board is scaled up for display.
var arduino := ComponentCatalog.build_component("arduino_uno")
var five_volt := arduino.find_child("PIN_5V") as Node3D
FailureEffects.spawn_short_circuit(arduino, five_volt.position)
```

The sparks are brighter than 1.0 (HDR), so they bloom when the scene's `Environment`
has glow enabled.

## Wired into hello_circuit

`examples/hello_circuit/run_example.gd` passes a `Node3D` into
`HelloCircuitExample.run(effects_root)`, which connects it to
`CircuitMonitor.on_short_circuit`:

```gdscript
if effects_root != null:
	monitor.on_short_circuit.connect(
		func(_details: Dictionary) -> void: FailureEffects.spawn_short_circuit(effects_root)
	)
```

Running the example (`circuits/short_circuit.json`) spawns the spark + smoke pair under
`effects_root` the moment `on_short_circuit` fires — see
`tests/unit/effects/test_failure_effects.gd` and
`tests/unit/hello_circuit/test_hello_circuit_example.gd` for the tests proving this.
