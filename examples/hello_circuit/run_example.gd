extends SceneTree

## CLI entrypoint for the walkthrough in hello_circuit.gd — a plain
## RefCounted script can't be run directly with `godot --script`, it needs a
## SceneTree/MainLoop, so that's kept separate from the reusable example.


func _init() -> void:
	HelloCircuitExample.run()
	quit()
