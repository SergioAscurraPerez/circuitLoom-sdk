class_name CircuitLoomSmokeEffect
extends CPUParticles3D

## Reference "short circuit" smoke puff. Built entirely from CPUParticles3D +
## a built-in QuadMesh/StandardMaterial3D (no texture or model assets), so it
## has no dependency outside the Godot engine itself — see docs/effects.md.
## CPUParticles3D (not GPUParticles3D) so it also runs headless/CI without a
## compute-capable renderer. One-shot: frees itself once it finishes.
##
## Authored at real-world scale (1 unit = 1 m, like the component models) in local
## coordinates, so it scales with whatever it is spawned under.

const _COLOR := Color(0.36, 0.36, 0.38, 0.45)
const _LIFETIME := 1.8


func _ready() -> void:
	_build()


func _build() -> void:
	mesh = _build_mesh()
	material_override = _build_material()

	one_shot = true
	local_coords = true
	amount = 28
	lifetime = _LIFETIME
	explosiveness = 0.35
	direction = Vector3(0, 1, 0)
	spread = 20.0
	initial_velocity_min = 0.015
	initial_velocity_max = 0.035
	gravity = Vector3(0, 0.02, 0)
	scale_amount_min = 1.5
	scale_amount_max = 2.5
	scale_amount_curve = _build_growth_curve()
	color_ramp = _build_fade_gradient()

	emitting = true
	_schedule_cleanup()


func _build_mesh() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.006, 0.006)
	return quad


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _build_soft_puff_texture()
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# Without it the billboard drops the node's and each particle's scale.
	material.billboard_keep_scale = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


## A round puff that fades out towards its edge, generated in code (no image file).
func _build_soft_puff_texture() -> GradientTexture2D:
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1, 1, 1, 1))
	falloff.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _build_growth_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
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
