class_name CircuitLoomSparkEffect
extends CPUParticles3D

## Reference "short circuit" spark burst. Built entirely from CPUParticles3D +
## a built-in QuadMesh/StandardMaterial3D (no texture or model assets), so it
## has no dependency outside the Godot engine itself — see docs/effects.md.
## CPUParticles3D (not GPUParticles3D) so it also runs headless/CI without a
## compute-capable renderer. One-shot: frees itself once it finishes.

const _COLOR := Color(1.0, 0.65, 0.05)
const _LIFETIME := 0.5


func _ready() -> void:
	_build()


func _build() -> void:
	mesh = _build_mesh()
	material_override = _build_material()

	one_shot = true
	amount = 40
	lifetime = _LIFETIME
	explosiveness = 0.95
	direction = Vector3(0, 1, 0)
	spread = 50.0
	initial_velocity_min = 1.2
	initial_velocity_max = 3.0
	gravity = Vector3(0, -9.8, 0)
	scale_amount_min = 0.02
	scale_amount_max = 0.05
	color = _COLOR

	emitting = true
	_schedule_cleanup()


func _build_mesh() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.01, 0.01)
	return quad


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = _COLOR
	material.emission_energy_multiplier = 2.0
	return material


func _schedule_cleanup() -> void:
	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = _LIFETIME + 0.2
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(queue_free)
	cleanup_timer.start()
