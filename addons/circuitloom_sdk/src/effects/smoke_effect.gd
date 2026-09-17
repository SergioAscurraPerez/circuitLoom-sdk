class_name CircuitLoomSmokeEffect
extends CPUParticles3D

## Reference "short circuit" smoke puff. Built entirely from CPUParticles3D +
## a built-in QuadMesh/StandardMaterial3D (no texture or model assets), so it
## has no dependency outside the Godot engine itself — see docs/effects.md.
## CPUParticles3D (not GPUParticles3D) so it also runs headless/CI without a
## compute-capable renderer. One-shot: frees itself once it finishes.

const _COLOR := Color(0.35, 0.35, 0.35, 0.55)
const _LIFETIME := 1.6


func _ready() -> void:
	_build()


func _build() -> void:
	mesh = _build_mesh()
	material_override = _build_material()

	one_shot = true
	amount = 14
	lifetime = _LIFETIME
	explosiveness = 0.6
	direction = Vector3(0, 1, 0)
	spread = 25.0
	initial_velocity_min = 0.2
	initial_velocity_max = 0.5
	gravity = Vector3(0, 0.15, 0)
	scale_amount_min = 0.03
	scale_amount_max = 0.06
	scale_amount_curve = _build_growth_curve()
	color_ramp = _build_fade_gradient()

	emitting = true
	_schedule_cleanup()


func _build_mesh() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	return quad


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _build_growth_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.0))
	return curve


func _build_fade_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, _COLOR)
	gradient.set_color(1, Color(_COLOR.r, _COLOR.g, _COLOR.b, 0.0))
	return gradient


func _schedule_cleanup() -> void:
	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = _LIFETIME + 0.3
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(queue_free)
	cleanup_timer.start()
