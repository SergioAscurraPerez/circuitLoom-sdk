class_name LedState
extends RefCounted

## Drives the visual state of a realistic LED model (models/led.glb): off, on or burned.
## It changes the material of the model's `STATE_Lens` part, so it works with any model
## that satisfies the model contract (see docs/models.md). Each LED gets its own copy of
## the material, so lighting one LED never lights the others sharing the same model.
##
## The LED keeps a reference to this object (as metadata), so there is no need to hold on
## to it after binding it to a CircuitMonitor. It unbinds itself when the LED leaves the
## scene tree, so a game can create and remove LEDs without piling up monitor connections.

enum State { OFF, ON, BURNED }

const LENS_PART := "STATE_Lens"
const META_KEY := "circuitloom_led_state"
const ON_EMISSION_ENERGY := 3.0
const BURNED_COLOR := Color(0.07, 0.05, 0.05)
const BURNED_ROUGHNESS := 0.85

var state: State = State.OFF
## Scales the emission of the ON state, from 0 (dark) to 1 (full); see set_brightness().
var brightness: float = 1.0

var _model: Node
var _monitor: CircuitMonitor
var _node_id: String
var _material: StandardMaterial3D
var _base_color: Color
var _base_roughness: float


func _init(led_model: Node) -> void:
	_model = led_model
	var lens := led_model.find_child(LENS_PART, true, false) as MeshInstance3D
	if lens == null:
		return
	var source := lens.get_active_material(0) as StandardMaterial3D
	if source == null:
		return
	_material = source.duplicate() as StandardMaterial3D
	lens.set_surface_override_material(0, _material)
	_base_color = _material.albedo_color
	_base_roughness = _material.roughness
	led_model.set_meta(META_KEY, self)
	set_state(State.OFF)


## False when the model has no usable `STATE_Lens`; the LED is then left untouched.
func is_attached() -> bool:
	return _material != null


func set_state(new_state: State) -> void:
	state = new_state
	if _material == null:
		return
	_material.albedo_color = _base_color
	_material.roughness = _base_roughness
	_material.emission_enabled = false
	match state:
		State.ON:
			_material.emission_enabled = true
			_material.emission = _base_color
			_material.emission_energy_multiplier = ON_EMISSION_ENERGY * brightness
		State.BURNED:
			_material.albedo_color = BURNED_COLOR
			_material.roughness = BURNED_ROUGHNESS


## Sets how bright the LED glows when ON, e.g. an analogWrite() duty cycle (value / 255).
## The factor is clamped to [0, 1] and kept across state changes; an LED that is already ON
## updates right away.
func set_brightness(factor: float) -> void:
	brightness = clampf(factor, 0.0, 1.0)
	if state == State.ON:
		set_state(State.ON)


## A burned LED stays burned until reset, like a real one.
func reset() -> void:
	set_state(State.OFF)


## Follows the circuit events for the circuit node `node_id`:
## - on_circuit_valid: on if current flows through the LED from anode to cathode, off
##   otherwise (an LED wired backwards stays off);
## - on_short_circuit: off;
## - on_component_damaged for this node: burned.
func bind(monitor: CircuitMonitor, node_id: String) -> void:
	unbind()
	_monitor = monitor
	_node_id = node_id
	monitor.on_circuit_valid.connect(_on_circuit_valid)
	monitor.on_short_circuit.connect(_on_short_circuit)
	monitor.on_component_damaged.connect(_on_component_damaged)
	if is_instance_valid(_model):
		_model.tree_exiting.connect(unbind)


## Stops following the monitor's events; the LED keeps its current state. Called on its
## own when the LED's model leaves the scene tree (re-adding it needs a new bind()).
## Safe to call when not bound.
func unbind() -> void:
	if _monitor == null:
		return
	_monitor.on_circuit_valid.disconnect(_on_circuit_valid)
	_monitor.on_short_circuit.disconnect(_on_short_circuit)
	_monitor.on_component_damaged.disconnect(_on_component_damaged)
	_monitor = null
	if is_instance_valid(_model) and _model.tree_exiting.is_connected(unbind):
		_model.tree_exiting.disconnect(unbind)


func _on_circuit_valid() -> void:
	if state == State.BURNED:
		return
	var currents: Dictionary = _monitor.last_result.get("node_currents_ma", {})
	var lit: bool = currents.get(_node_id, 0.0) > 0.0 and _is_forward_biased()
	set_state(State.ON if lit else State.OFF)


## False only when both lead voltages are known and the cathode sits above the anode.
func _is_forward_biased() -> bool:
	var voltages: Dictionary = _monitor.last_result.get("pin_voltages", {})
	var anode_key := "%s:%s" % [_node_id, RulesEngine.LED_ANODE_PIN]
	var cathode_key := "%s:%s" % [_node_id, RulesEngine.LED_CATHODE_PIN]
	if not voltages.has(anode_key) or not voltages.has(cathode_key):
		return true
	return float(voltages[anode_key]) >= float(voltages[cathode_key])


func _on_short_circuit(_details: Dictionary) -> void:
	if state != State.BURNED:
		set_state(State.OFF)


func _on_component_damaged(details: Dictionary) -> void:
	if details.get("node_id") == _node_id:
		set_state(State.BURNED)
