extends SceneTree

## Visual demo: the three hello_circuit circuits are checked in turn and
## `on_short_circuit` spawns the spark/smoke reference effect over a scaled-up
## Arduino UNO placeholder. Run it in a window with:
## godot --path . --script res://examples/hello_circuit/demo_scene.gd

const FailureEffects := preload("res://addons/circuitloom_sdk/src/effects/failure_effects.gd")
const BOARD_SCALE := 10.0

var _status: Label
var _scene_root: Node3D


func _initialize() -> void:
	_build_scene()
	_run_demo()


func _build_scene() -> void:
	_scene_root = Node3D.new()
	root.add_child(_scene_root)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.09, 0.1, 0.13)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.58, 0.65)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_scene_root.add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	_scene_root.add_child(light)

	var camera := Camera3D.new()
	_scene_root.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 0.42, 0.62), Vector3(0.0, 0.16, 0.0))
	camera.current = true

	var board: Node3D = ComponentCatalog.build_component("arduino_uno")
	board.scale = Vector3.ONE * BOARD_SCALE
	_scene_root.add_child(board)

	var layer := CanvasLayer.new()
	root.add_child(layer)
	_status = Label.new()
	_status.position = Vector2(24, 20)
	_status.add_theme_font_size_override("font_size", 30)
	layer.add_child(_status)


func _run_demo() -> void:
	var monitor := CircuitMonitor.new()
	monitor.on_circuit_valid.connect(
		func() -> void: _set_status("on_circuit_valid", Color(0.4, 0.9, 0.5))
	)
	monitor.on_short_circuit.connect(
		func(details: Dictionary) -> void:
			_set_status("on_short_circuit  (%s)" % details.get("cause", ""), Color(1.0, 0.45, 0.3))
			FailureEffects.spawn_short_circuit(_scene_root, Vector3(0.0, 0.05, 0.0))
	)
	monitor.on_component_damaged.connect(
		func(details: Dictionary) -> void:
			_set_status(
				"on_component_damaged  (%s)" % details.get("node_id", ""), Color(1.0, 0.8, 0.3)
			)
	)

	_set_status("CircuitLoom SDK - hello_circuit", Color.WHITE)
	await create_timer(0.8).timeout
	monitor.check(HelloCircuitExample.load_circuit("valid"))
	await create_timer(1.6).timeout
	monitor.check(HelloCircuitExample.load_circuit("short_circuit"))
	await create_timer(3.0).timeout
	monitor.check(HelloCircuitExample.load_circuit("overcurrent"))
	await create_timer(1.6).timeout
	quit()


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
