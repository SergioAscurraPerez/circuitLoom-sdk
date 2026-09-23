class_name CircuitLoomSparkEffect
extends CPUParticles3D

## Reference "short circuit" spark burst. Built entirely from CPUParticles3D +
## a built-in QuadMesh/StandardMaterial3D (no texture or model assets), so it
## has no dependency outside the Godot engine itself — see docs/effects.md.
## CPUParticles3D (not GPUParticles3D) so it also runs headless/CI without a
## compute-capable renderer. One-shot: frees itself once it finishes.
##
## Authored at real-world scale (1 unit = 1 m, like the component models) in local
## coordinates, so it scales with whatever it is spawned under.

# Brighter than 1.0 so the sparks bloom when the environment has glow enabled.
const _HOT_COLOR := Color(2.0, 0.75, 0.12)
const _LIFETIME := 0.35


func _ready() -> void:
	_build()


func _build() -> void:
	mesh = _build_mesh()
	material_override = _build_material()

	one_shot = true
	local_coords = true
	amount = 60
	lifetime = _LIFETIME
	explosiveness = 0.7
	direction = Vector3(0, 1, 0)
	spread = 45.0
	initial_velocity_min = 0.25
	initial_velocity_max = 0.6
	damping_min = 1.0
	damping_max = 1.6
	gravity = Vector3(0, -9.8, 0)
	scale_amount_min = 0.6
	scale_amount_max = 1.2
	color_ramp = _build_cooling_gradient()

	# restart(), not `emitting = true`: with the latter this explosive one-shot burst
	# rendered nothing when spawned into a running scene.
	restart()
	_schedule_cleanup()


func _build_mesh() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.0012, 0.0012)
	return quad


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = _HOT_COLOR
	material.albedo_texture = _build_glow_dot_texture()
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# Without it the billboard drops the node's and each particle's scale.
	material.billboard_keep_scale = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


## A round dot with a solid core and a soft edge, generated in code (no image file).
func _build_glow_dot_texture() -> GradientTexture2D:
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1, 1, 1, 1))
	falloff.set_color(1, Color(1, 1, 1, 0))
	falloff.add_point(0.35, Color(1, 1, 1, 1))
	var texture := GradientTexture2D.new()
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _build_cooling_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0))
	gradient.set_color(1, Color(0.8, 0.3, 0.1, 0.0))
	return gradient


func _schedule_cleanup() -> void:
	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = _LIFETIME + 0.2
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(queue_free)
	cleanup_timer.start()
