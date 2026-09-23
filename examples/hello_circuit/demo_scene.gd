extends SceneTree

## Visual demo: the three hello_circuit circuits are checked in turn over a scaled-up
## Arduino UNO next to a breadboard populated with the v1 starter-kit components. The
## LED follows the circuit events through LedState (on, off, burned) and
## `on_short_circuit` spawns the spark/smoke reference effect on the Arduino's 5V/GND
## header. Run it in a window with:
## godot --path . --script res://examples/hello_circuit/demo_scene.gd

const FailureEffects := preload("res://addons/circuitloom_sdk/src/effects/failure_effects.gd")
const BOARD_SCALE := 10.0
# Real-world offsets (meters, pre-scale) so the boards keep their true relative size
# and sit side by side with a gap instead of overlapping.
const BREADBOARD_OFFSET := Vector3(-0.043, 0.0, 0.0)
const ARDUINO_OFFSET := Vector3(0.092, 0.0, 0.0)
const SERVO_OFFSET := Vector3(0.078, 0.0, -0.068)
# How deep a lead goes into a breadboard hole, measured down from the board's top.
const BREADBOARD_TOP_Y := 0.0092
const LEAD_INSERT_DEPTH := 0.007
# Breadboard-local position of each component that plugs into it: [type, x, z, yaw].
const BREADBOARD_PARTS := [
	["push_button", -0.062, 0.0, 0.0],
	["photoresistor", -0.046, -0.009, 0.0],
	["resistor", -0.03, -0.009, 0.0],
	["led", -0.016, -0.009, 0.0],
	["potentiometer", 0.004, -0.012, 0.0],
	["buzzer", 0.026, -0.009, 0.0],
	["ultrasonic_sensor", 0.058, -0.016, 0.0],
]
const LED_NODE_ID := "led_1"

var _status: Label
var _scene_root: Node3D
var _board: Node3D
var _led: Node3D


func _initialize() -> void:
	_build_scene()
	_run_demo()


func _build_scene() -> void:
	_scene_root = Node3D.new()
	root.add_child(_scene_root)

	_add_environment()
	_add_lights()
	_add_table()

	var camera := Camera3D.new()
	camera.fov = 34.0
	_scene_root.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 2.05, 1.95), Vector3(0.0, 0.0, -0.12))
	camera.current = true

	var rig := Node3D.new()
	rig.name = "Boards"
	rig.scale = Vector3.ONE * BOARD_SCALE
	_scene_root.add_child(rig)

	var breadboard: Node3D = ComponentCatalog.build_component("breadboard")
	breadboard.position = BREADBOARD_OFFSET
	rig.add_child(breadboard)

	_board = ComponentCatalog.build_component("arduino_uno")
	_board.position = ARDUINO_OFFSET
	rig.add_child(_board)

	var servo: Node3D = ComponentCatalog.build_component("servo_motor")
	servo.position = SERVO_OFFSET
	rig.add_child(servo)

	for part: Array in BREADBOARD_PARTS:
		var component := _plug_into(breadboard, part[0], part[1], part[2], part[3])
		if part[0] == "led":
			_led = component

	_add_status_label()


func _add_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.2, 0.23, 0.3)
	sky_material.sky_horizon_color = Color(0.42, 0.44, 0.5)
	sky_material.ground_bottom_color = Color(0.06, 0.06, 0.07)
	sky_material.ground_horizon_color = Color(0.3, 0.31, 0.35)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	# The sky only feeds ambient light and reflections; the backdrop stays a flat color.
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.06, 0.065, 0.08)
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.6
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.1

	environment.ssao_enabled = true
	environment.ssao_radius = 0.12
	environment.ssao_intensity = 1.6
	environment.ssr_enabled = true
	environment.ssr_max_steps = 64
	environment.ssr_fade_in = 0.1
	environment.ssr_fade_out = 1.5
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.0
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_scene_root.add_child(world_environment)


func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52, -32, 0)
	key.light_color = Color(1.0, 0.96, 0.9)
	key.light_energy = 1.3
	key.shadow_enabled = true
	key.shadow_blur = 1.5
	key.directional_shadow_max_distance = 6.0
	_scene_root.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28, 145, 0)
	fill.light_color = Color(0.75, 0.82, 1.0)
	fill.light_energy = 0.35
	_scene_root.add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 185, 0)
	rim.light_energy = 0.4
	_scene_root.add_child(rim)


func _add_table() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.16, 0.18)
	material.roughness = 0.75
	material.metallic_specular = 0.3
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	plane.material = material
	var table := MeshInstance3D.new()
	table.name = "Table"
	table.mesh = plane
	_scene_root.add_child(table)


## Seats `component_type` on the breadboard at breadboard-local (x, z), with its leads
## pushed LEAD_INSERT_DEPTH into the holes (its lowest PIN_ node marks the lead tips).
func _plug_into(
	breadboard: Node3D, component_type: String, x: float, z: float, yaw: float
) -> Node3D:
	var component := ComponentCatalog.build_component(component_type)
	var lowest_pin_y := 0.0
	for pin in component.find_children(ModelLoader.PIN_PREFIX + "*", "Node3D", true, false):
		lowest_pin_y = minf(lowest_pin_y, _position_in(component, pin).y)
	var lead_tip_y := BREADBOARD_TOP_Y - LEAD_INSERT_DEPTH
	component.position = Vector3(x, lead_tip_y - lowest_pin_y, z)
	component.rotation_degrees.y = yaw
	breadboard.add_child(component)
	return component


## `node`'s position in `ancestor`'s space, usable before either is in the scene tree.
func _position_in(ancestor: Node, node: Node) -> Vector3:
	var transform := Transform3D.IDENTITY
	while node != ancestor:
		transform = (node as Node3D).transform * transform
		node = node.get_parent()
	return transform.origin


func _add_status_label() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_status = Label.new()
	_status.position = Vector2(28, 22)
	_status.add_theme_font_size_override("font_size", 30)
	_status.add_theme_constant_override("outline_size", 8)
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	layer.add_child(_status)


## Where a bare 5V-to-GND wire would arc: between those two header pins on the Arduino.
func _short_circuit_point() -> Vector3:
	var five_volt := _board.find_child(ModelLoader.PIN_PREFIX + "5V", true, false) as Node3D
	var ground := _board.find_child(ModelLoader.PIN_PREFIX + "GND", true, false) as Node3D
	if five_volt == null or ground == null:
		return Vector3.ZERO
	var midpoint := (five_volt.global_position + ground.global_position) * 0.5
	return _board.to_local(midpoint) + Vector3(0, 0.002, 0)


func _run_demo() -> void:
	var monitor := CircuitMonitor.new()
	LedState.new(_led).bind(monitor, LED_NODE_ID)

	monitor.on_circuit_valid.connect(
		func() -> void: _set_status("on_circuit_valid", Color(0.4, 0.9, 0.5))
	)
	monitor.on_short_circuit.connect(
		func(details: Dictionary) -> void:
			_set_status("on_short_circuit  (%s)" % details.get("cause", ""), Color(1.0, 0.45, 0.3))
			FailureEffects.spawn_short_circuit(_board, _short_circuit_point())
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
	await create_timer(2.0).timeout
	monitor.check(HelloCircuitExample.load_circuit("short_circuit"))
	await create_timer(2.6).timeout
	monitor.check(HelloCircuitExample.load_circuit("overcurrent"))
	await create_timer(2.2).timeout
	quit()


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
