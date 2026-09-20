class_name LedState
extends RefCounted

## Drives the visual state of a realistic LED model (models/led.glb): off, on or burned.
## It changes the material of the model's `STATE_Lens` part, so it works with any model
## that satisfies the model contract (see docs/models.md). Each LED gets its own copy of
## the material, so lighting one LED never lights the others sharing the same model.
##
## The LED keeps a reference to this object (as metadata), so there is no need to hold on
## to it after binding it to a CircuitMonitor.

enum State { OFF, ON, BURNED }

const LENS_PART := "STATE_Lens"
const META_KEY := "circuitloom_led_state"
const ON_EMISSION_ENERGY := 3.0
const BURNED_COLOR := Color(0.07, 0.05, 0.05)
const BURNED_ROUGHNESS := 0.85

var state: State = State.OFF

var _material: StandardMaterial3D
var _base_color: Color
var _base_roughness: float


func _init(led_model: Node) -> void:
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
			_material.emission_energy_multiplier = ON_EMISSION_ENERGY
		State.BURNED:
			_material.albedo_color = BURNED_COLOR
			_material.roughness = BURNED_ROUGHNESS


## A burned LED stays burned until reset, like a real one.
func reset() -> void:
	set_state(State.OFF)


## Follows the circuit events for the circuit node `node_id`:
## - on_circuit_valid: on if current flows through the LED, off otherwise;
## - on_short_circuit: off;
## - on_component_damaged for this node: burned.
func bind(monitor: CircuitMonitor, node_id: String) -> void:
	monitor.on_circuit_valid.connect(_on_circuit_valid.bind(monitor, node_id))
	monitor.on_short_circuit.connect(_on_short_circuit)
	monitor.on_component_damaged.connect(_on_component_damaged.bind(node_id))


func _on_circuit_valid(monitor: CircuitMonitor, node_id: String) -> void:
	if state == State.BURNED:
		return
	var currents: Dictionary = monitor.last_result.get("node_currents_ma", {})
	set_state(State.ON if currents.get(node_id, 0.0) > 0.0 else State.OFF)


func _on_short_circuit(_details: Dictionary) -> void:
	if state != State.BURNED:
		set_state(State.OFF)


func _on_component_damaged(details: Dictionary, node_id: String) -> void:
	if details.get("node_id") == node_id:
		set_state(State.BURNED)
