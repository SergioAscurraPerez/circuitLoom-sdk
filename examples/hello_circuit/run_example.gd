extends SceneTree

## CLI entrypoint for the walkthrough in hello_circuit.gd — a plain
## RefCounted script can't be run directly with `godot --script`, it needs a
## SceneTree/MainLoop, so that's kept separate from the reusable example. The
## Node3D below is where hello_circuit.gd spawns the spark/smoke reference
## effects (docs/effects.md) on `on_short_circuit`.


func _init() -> void:
	var effects_root := Node3D.new()
	root.add_child(effects_root)
	HelloCircuitExample.run(effects_root)
	quit()
