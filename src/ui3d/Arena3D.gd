class_name Arena3D
extends RefCounted
## Construit une arène 3D stylisée (sol, décor, lumières, ambiance) dans un parent Node3D.
## Optimisé moteur Compatibility / WebGL2 (low-poly, peu de lumières, ombres simples).

static func _mat(col: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

static func _emit(col: Color, e := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = e
	return m

static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, euler := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = Vector3(deg_to_rad(euler.x), deg_to_rad(euler.y), deg_to_rad(euler.z))
	mi.scale = scl
	parent.add_child(mi)
	return mi

## Construit l'arène des Ruines de Cendre.
static func build(parent: Node3D) -> void:
	_environment(parent)
	_ground(parent)
	_decor(parent)
	_ashes(parent)

static func _environment(parent: Node3D) -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2a0e12")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7a4338")
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color("3a1620")
	env.fog_density = 0.018
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	parent.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-52), deg_to_rad(40), 0)
	sun.light_color = Color("ffb27a")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	parent.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-25), deg_to_rad(-150), 0)
	fill.light_color = Color("5a6aa0")
	fill.light_energy = 0.35
	parent.add_child(fill)

	# disque solaire lointain (lune rouge)
	_add(parent, _disc(6.0), _emit(Color("e85a30"), 1.6), Vector3(-14, 12, 26), Vector3(0, 0, 0))

static func _disc(r: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = 0.1
	m.radial_segments = 32
	return m

static func _ground(parent: Node3D) -> void:
	var stone := _mat(Color("4a3a3a"), 0.9)
	var disc := CylinderMesh.new()
	disc.top_radius = 5.0
	disc.bottom_radius = 5.4
	disc.height = 0.5
	disc.radial_segments = 40
	_add(parent, disc, stone, Vector3(0, -0.25, 0))

	# bordure surélevée
	var rim := TorusMesh.new()
	rim.inner_radius = 4.7
	rim.outer_radius = 5.1
	rim.rings = 32
	rim.ring_segments = 16
	_add(parent, rim, _mat(Color("5a4642"), 0.8), Vector3(0, 0.0, 0))

	# emblème central original (anneaux concentriques émissifs)
	_add(parent, _ring_mesh(1.6, 1.8), _emit(Color("e0561f"), 1.2), Vector3(0, 0.02, 0))
	_add(parent, _ring_mesh(0.7, 0.85), _emit(Color("ffb060"), 1.0), Vector3(0, 0.02, 0))
	# fissures lumineuses
	for i in 6:
		var a := i * PI / 3.0
		_add(parent, _boxmesh(Vector3(0.08, 0.02, 2.2)), _emit(Color("ff7a3c"), 1.0),
			Vector3(cos(a) * 2.6, 0.02, sin(a) * 2.6), Vector3(0, rad_to_deg(-a), 0))

static func _ring_mesh(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 40
	t.ring_segments = 8
	return t

static func _boxmesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

static func _decor(parent: Node3D) -> void:
	var stone := _mat(Color("4a3836"), 0.85)
	var dark := _mat(Color("2e2422"), 0.9)
	# arches en ruine autour de l'arène
	var arch_angles := [25.0, 155.0, 205.0, 335.0]
	for deg in arch_angles:
		var a := deg_to_rad(deg)
		var base := Vector3(cos(a) * 6.2, 0, sin(a) * 6.2)
		_pillar(parent, base + Vector3(-0.6, 0, 0), stone)
		_pillar(parent, base + Vector3(0.6, 0, 0), stone)
		_add(parent, _boxmesh(Vector3(1.8, 0.5, 0.6)), stone, base + Vector3(0, 2.6, 0))

	# braseros (lumière chaude) — au bord, hors de la zone de jeu
	for deg2 in [60.0, 120.0, 240.0, 300.0]:
		var b := deg_to_rad(deg2)
		var p := Vector3(cos(b) * 5.7, 0, sin(b) * 5.7)
		_add(parent, _cylmesh(0.18, 0.28, 0.9), dark, p + Vector3(0, 0.45, 0))
		_add(parent, _bowl(), _mat(Color("2a2020"), 0.7), p + Vector3(0, 0.95, 0))
		var fire := _emit(Color("ff8a3c"), 3.5)
		_add(parent, _spheremesh(0.22), fire, p + Vector3(0, 1.05, 0), Vector3.ZERO, Vector3(1, 1.4, 1))
		var ol := OmniLight3D.new()
		ol.light_color = Color("ff9a4a")
		ol.light_energy = 2.2
		ol.omni_range = 6.0
		ol.position = p + Vector3(0, 1.2, 0)
		parent.add_child(ol)

	# cristaux orangés
	for deg3 in [10.0, 130.0, 220.0, 320.0]:
		var c := deg_to_rad(deg3)
		var cp := Vector3(cos(c) * 3.9, 0, sin(c) * 3.9)
		_add(parent, _cylmesh(0.0, 0.18, 0.8), _emit(Color("ff7330"), 1.8), cp + Vector3(0, 0.4, 0), Vector3(8, 0, 6))

	# îlots flottants en arrière-plan (profondeur)
	for spec in [[-9.0, 4.0, 16.0, 2.4], [10.0, 6.0, 18.0, 3.0], [0.0, 8.0, 24.0, 4.0], [-16.0, 2.0, 12.0, 2.0]]:
		_add(parent, _cylmesh(spec[3], spec[3] + 0.4, 0.8), _mat(Color("2a1a1e"), 0.95),
			Vector3(spec[0], spec[1], spec[2]))

static func _pillar(parent: Node3D, pos: Vector3, mat: Material) -> void:
	_add(parent, _cylmesh(0.3, 0.36, 2.6), mat, pos + Vector3(0, 1.3, 0))

static func _cylmesh(rt: float, rb: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = 10
	return m

static func _spheremesh(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m

static func _bowl() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.32
	m.bottom_radius = 0.18
	m.height = 0.22
	m.radial_segments = 12
	return m

static func _ashes(parent: Node3D) -> void:
	var p := CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 6.0
	p.position = Vector3(0, 3, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(7, 3, 7)
	p.direction = Vector3(0.2, -1, 0)
	p.gravity = Vector3(0, -0.25, 0)
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.4
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffae6a")
	mat.emission_enabled = true
	mat.emission = Color("ff8a4a")
	mat.emission_energy_multiplier = 1.5
	p.mesh = _spheremesh(0.5)
	p.material_override = mat
	parent.add_child(p)
