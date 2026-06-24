class_name Creature3D
extends Node3D
## Créature 3D stylisée low-poly assemblée par code (asset temporaire, voir ROADMAP).
## Silhouette distincte par espèce (corps + tête + membres + appendices + matériaux).
## Animations par transformation des membres (respiration, attaque, impact, mort).

var species := "drakelin"
var primary := Color("c0392b")
var secondary := Color("2c1410")
var glow := Color("ff9a3c")
var height := 1.9

var _body: Node3D          # pivot animé (respiration / déplacement)
var _parts := {}           # membres nommés pour l'animation
var _t := 0.0
var _alive := true
var _ring: MeshInstance3D
var _emissives: Array = []  # matériaux à faire clignoter (impact)

func build(kit: Dictionary) -> void:
	species = kit.get("species", "drakelin")
	primary = kit.get("primary", primary)
	secondary = kit.get("secondary", secondary)
	glow = kit.get("glow", glow)
	_body = Node3D.new()
	add_child(_body)
	match species:
		"drakelin": _build_drakelin()
		"armor": _build_armor()
		"imp": _build_imp()
		_: _build_drakelin()
	_build_turn_ring()
	set_process(true)

# ------------------------------------------------------------------ matériaux
func _mat(col: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

func _emit_mat(col: Color, energy := 2.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	_emissives.append(m)
	return m

func _part(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, euler := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = Vector3(deg_to_rad(euler.x), deg_to_rad(euler.y), deg_to_rad(euler.z))
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m

func _boxm(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _cyl(rt: float, rb: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = 12
	return m

func _node(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

# ------------------------------------------------------------------ DRAKELIN (petit dragon)
func _build_drakelin() -> void:
	height = 1.9
	var scales := _mat(primary, 0.6)
	var belly := _mat(primary.lightened(0.25), 0.7)
	var bone := _mat(Color("e8dcc0"), 0.5)
	var membrane := _mat(primary.darkened(0.25), 0.8)

	# torse (œuf incliné)
	_part(_body, _sphere(0.5), scales, Vector3(0, 0.8, 0), Vector3(10, 0, 0), Vector3(1.0, 0.95, 1.35))
	_part(_body, _sphere(0.42), belly, Vector3(0, 0.7, 0.12), Vector3.ZERO, Vector3(0.9, 0.8, 1.1))

	# cou + tête
	_part(_body, _cyl(0.16, 0.22, 0.5), scales, Vector3(0, 1.15, 0.45), Vector3(55, 0, 0))
	var head := _node(_body, Vector3(0, 1.38, 0.68))
	_parts["head"] = head
	_part(head, _sphere(0.27), scales, Vector3.ZERO)
	_part(head, _cyl(0.06, 0.18, 0.34), scales, Vector3(0, -0.02, 0.24), Vector3(95, 0, 0))  # museau
	_part(head, _boxm(Vector3(0.34, 0.06, 0.14)), bone, Vector3(0, -0.08, 0.22))             # mâchoire
	# cornes
	_part(head, _cyl(0.0, 0.07, 0.28), bone, Vector3(-0.13, 0.2, -0.05), Vector3(-25, 0, -12))
	_part(head, _cyl(0.0, 0.07, 0.28), bone, Vector3(0.13, 0.2, -0.05), Vector3(-25, 0, 12))
	# yeux
	_part(head, _sphere(0.05), _emit_mat(glow, 3.0), Vector3(-0.13, 0.02, 0.2))
	_part(head, _sphere(0.05), _emit_mat(glow, 3.0), Vector3(0.13, 0.02, 0.2))

	# ailes
	var wl := _node(_body, Vector3(-0.35, 1.0, -0.15))
	var wr := _node(_body, Vector3(0.35, 1.0, -0.15))
	_parts["wing_l"] = wl
	_parts["wing_r"] = wr
	_part(wl, _boxm(Vector3(0.7, 0.5, 0.04)), membrane, Vector3(-0.35, 0.05, 0), Vector3(0, 20, 25))
	_part(wr, _boxm(Vector3(0.7, 0.5, 0.04)), membrane, Vector3(0.35, 0.05, 0), Vector3(0, -20, -25))

	# bras + griffes
	_arm(_body, Vector3(-0.34, 0.85, 0.2), -1, scales, bone)
	_arm(_body, Vector3(0.34, 0.85, 0.2), 1, scales, bone)

	# jambes
	_leg(_body, Vector3(-0.25, 0.5, -0.05), scales, bone)
	_leg(_body, Vector3(0.25, 0.5, -0.05), scales, bone)

	# queue (chaîne) avec pointe de feu
	var tail := _node(_body, Vector3(0, 0.7, -0.5))
	_parts["tail"] = tail
	_part(tail, _cyl(0.1, 0.16, 0.4), scales, Vector3(0, -0.05, -0.2), Vector3(80, 0, 0))
	_part(tail, _cyl(0.06, 0.1, 0.35), scales, Vector3(0, -0.12, -0.5), Vector3(70, 0, 0))
	_part(tail, _sphere(0.12), _emit_mat(glow, 3.5), Vector3(0, -0.2, -0.72))

func _arm(parent: Node3D, pos: Vector3, side: int, sk: Material, bone: Material) -> void:
	var a := _node(parent, pos)
	_part(a, _cyl(0.07, 0.09, 0.4), sk, Vector3(side * 0.05, -0.15, 0.1), Vector3(60, 0, side * 10))
	for i in 3:
		_part(a, _cyl(0.0, 0.03, 0.14), bone, Vector3(side * 0.08 + (i - 1) * 0.05, -0.32, 0.28), Vector3(60, 0, 0))

func _leg(parent: Node3D, pos: Vector3, sk: Material, bone: Material) -> void:
	_part(parent, _cyl(0.1, 0.13, 0.45), sk, pos, Vector3(8, 0, 0))
	_part(parent, _boxm(Vector3(0.22, 0.1, 0.34)), sk, pos + Vector3(0, -0.28, 0.1))
	for i in 3:
		_part(parent, _cyl(0.0, 0.03, 0.1), bone, pos + Vector3((i - 1) * 0.07, -0.32, 0.26), Vector3(70, 0, 0))

# ------------------------------------------------------------------ ARMOR (armure vivante)
func _build_armor() -> void:
	height = 2.05
	var metal := _mat(primary, 0.35, 0.85)
	var dark := _mat(secondary.darkened(0.3), 0.5, 0.6)
	var core := _emit_mat(glow, 3.5)

	# torse (plastron trapézoïdal)
	_part(_body, _boxm(Vector3(0.9, 1.0, 0.55)), metal, Vector3(0, 1.0, 0), Vector3(0, 0, 0), Vector3(1, 1, 1))
	_part(_body, _cyl(0.5, 0.62, 0.4), metal, Vector3(0, 0.45, 0), Vector3.ZERO)  # taille
	_part(_body, _sphere(0.15), core, Vector3(0, 1.05, 0.3))                       # noyau
	_part(_body, _cyl(0.2, 0.22, 0.06), dark, Vector3(0, 1.05, 0.31), Vector3(90, 0, 0))

	# pauldrons
	_part(_body, _sphere(0.28), metal, Vector3(-0.52, 1.45, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	_part(_body, _sphere(0.28), metal, Vector3(0.52, 1.45, 0), Vector3.ZERO, Vector3(1, 0.7, 1))

	# heaume flottant (sans visage, yeux luminescents)
	var helm := _node(_body, Vector3(0, 1.72, 0.02))
	_parts["head"] = helm
	_part(helm, _cyl(0.12, 0.26, 0.4), metal, Vector3(0, 0.05, 0))
	_part(helm, _boxm(Vector3(0.28, 0.12, 0.12)), dark, Vector3(0, 0.02, 0.18))
	_part(helm, _boxm(Vector3(0.07, 0.03, 0.04)), _emit_mat(glow, 4.0), Vector3(-0.07, 0.04, 0.22))
	_part(helm, _boxm(Vector3(0.07, 0.03, 0.04)), _emit_mat(glow, 4.0), Vector3(0.07, 0.04, 0.22))
	# crête
	_part(helm, _cyl(0.0, 0.06, 0.3), _emit_mat(glow, 2.0), Vector3(0, 0.28, -0.02))

	# bras
	var ra := _node(_body, Vector3(0.52, 1.4, 0.1))
	_parts["arm_r"] = ra
	_part(ra, _cyl(0.1, 0.12, 0.5), metal, Vector3(0.05, -0.28, 0.05), Vector3(20, 0, 8))
	_part(ra, _boxm(Vector3(0.2, 0.24, 0.24)), dark, Vector3(0.1, -0.52, 0.12))  # gantelet
	_part(_body, _cyl(0.1, 0.12, 0.5), metal, Vector3(-0.55, 1.15, 0.05), Vector3(20, 0, -8))

	# bouclier (bras gauche)
	var shield := _node(_body, Vector3(-0.62, 1.05, 0.25))
	_part(shield, _cyl(0.45, 0.5, 0.1), metal, Vector3.ZERO, Vector3(90, 0, 0))
	_part(shield, _cyl(0.2, 0.22, 0.12), dark, Vector3(0, 0, 0.06), Vector3(90, 0, 0))
	_part(shield, _sphere(0.1), core, Vector3(0, 0, 0.12))

	# jambes
	_part(_body, _cyl(0.13, 0.16, 0.5), metal, Vector3(-0.25, 0.4, 0), Vector3(6, 0, 0))
	_part(_body, _cyl(0.13, 0.16, 0.5), metal, Vector3(0.25, 0.4, 0), Vector3(6, 0, 0))
	_part(_body, _boxm(Vector3(0.26, 0.14, 0.4)), dark, Vector3(-0.25, 0.1, 0.08))
	_part(_body, _boxm(Vector3(0.26, 0.14, 0.4)), dark, Vector3(0.25, 0.1, 0.08))

# ------------------------------------------------------------------ IMP (petit démon ennemi)
func _build_imp() -> void:
	height = 1.45
	var skin := _mat(primary, 0.6)
	var dark := _mat(secondary, 0.7)
	var horn := _mat(Color("3a2418"), 0.5)

	_part(_body, _sphere(0.42), skin, Vector3(0, 0.6, 0), Vector3(12, 0, 0), Vector3(1, 0.95, 1.05))
	_part(_body, _sphere(0.2), skin, Vector3(0, 0.5, 0.28), Vector3.ZERO, Vector3(1, 0.8, 1))  # ventre

	var head := _node(_body, Vector3(0, 1.05, 0.12))
	_parts["head"] = head
	_part(head, _sphere(0.3), skin, Vector3.ZERO, Vector3.ZERO, Vector3(1.1, 1, 1))
	# oreilles pointues
	_part(head, _cyl(0.0, 0.08, 0.3), skin, Vector3(-0.28, 0.05, -0.05), Vector3(0, 0, 60))
	_part(head, _cyl(0.0, 0.08, 0.3), skin, Vector3(0.28, 0.05, -0.05), Vector3(0, 0, -60))
	# cornes
	_part(head, _cyl(0.0, 0.05, 0.22), horn, Vector3(-0.12, 0.24, 0), Vector3(-20, 0, -10))
	_part(head, _cyl(0.0, 0.05, 0.22), horn, Vector3(0.12, 0.24, 0), Vector3(-20, 0, 10))
	# yeux
	_part(head, _sphere(0.06), _emit_mat(glow, 3.5), Vector3(-0.12, 0.0, 0.24))
	_part(head, _sphere(0.06), _emit_mat(glow, 3.5), Vector3(0.12, 0.0, 0.24))
	# crocs
	_part(head, _boxm(Vector3(0.18, 0.05, 0.04)), _mat(Color("efe9d8")), Vector3(0, -0.18, 0.22))

	# bras griffus
	_part(_body, _cyl(0.06, 0.08, 0.42), skin, Vector3(-0.36, 0.62, 0.12), Vector3(40, 0, -20))
	_part(_body, _cyl(0.06, 0.08, 0.42), skin, Vector3(0.36, 0.62, 0.12), Vector3(40, 0, 20))
	# jambes
	_part(_body, _cyl(0.08, 0.1, 0.35), dark, Vector3(-0.2, 0.32, 0), Vector3(6, 0, 0))
	_part(_body, _cyl(0.08, 0.1, 0.35), dark, Vector3(0.2, 0.32, 0), Vector3(6, 0, 0))
	# queue
	var tail := _node(_body, Vector3(0, 0.5, -0.32))
	_parts["tail"] = tail
	_part(tail, _cyl(0.05, 0.09, 0.45), skin, Vector3(0, -0.1, -0.2), Vector3(70, 0, 0))
	_part(tail, _cyl(0.0, 0.12, 0.18), horn, Vector3(0, -0.2, -0.42), Vector3(60, 0, 0))  # pointe

# ------------------------------------------------------------------ anneau de tour
func _build_turn_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.72
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = _emit_mat(Color("ffd36a"), 2.0)
	_ring.position = Vector3(0, 0.05, 0)
	_ring.visible = false
	add_child(_ring)

func set_turn(on: bool) -> void:
	if _ring:
		_ring.visible = on

# ------------------------------------------------------------------ animation
func _process(delta: float) -> void:
	_t += delta
	if not _alive:
		return
	# respiration
	_body.position.y = sin(_t * 2.0) * 0.03
	_body.scale = Vector3.ONE * (1.0 + sin(_t * 2.0) * 0.012)
	if _parts.has("head"):
		_parts["head"].rotation.y = sin(_t * 0.8) * 0.12
	if _parts.has("tail"):
		_parts["tail"].rotation.y = sin(_t * 1.6) * 0.2
	for key in ["wing_l", "wing_r"]:
		if _parts.has(key):
			_parts[key].rotation.z = sin(_t * 3.0) * 0.15
	if _ring and _ring.visible:
		_ring.rotation.y += delta * 1.5

func head_world() -> Vector3:
	return global_position + Vector3(0, height, 0)

func face_toward(target: Vector3) -> void:
	var dir := target - global_position
	dir.y = 0
	if dir.length() > 0.01:
		look_at(global_position - dir, Vector3.UP)  # -dir car le modèle regarde +Z

func play_attack() -> void:
	var tw := create_tween()
	tw.tween_property(_body, "position:z", 0.45, 0.12).set_trans(Tween.TRANS_BACK)
	if _parts.has("arm_r"):
		tw.parallel().tween_property(_parts["arm_r"], "rotation:x", deg_to_rad(-70), 0.12)
	tw.tween_property(_body, "position:z", 0.0, 0.18)
	if _parts.has("arm_r"):
		tw.parallel().tween_property(_parts["arm_r"], "rotation:x", 0.0, 0.18)

func play_cast() -> void:
	var tw := create_tween()
	tw.tween_property(_body, "position:y", 0.25, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_body, "position:y", 0.0, 0.22)

func flash() -> void:
	for m in _emissives:
		m.emission_energy_multiplier = 6.0
	var tw := create_tween()
	tw.tween_method(func(v): _set_emit(v), 6.0, 2.5, 0.3)

func _set_emit(v: float) -> void:
	for m in _emissives:
		m.emission_energy_multiplier = v

func play_hit() -> void:
	flash()
	var tw := create_tween()
	tw.tween_property(_body, "position:z", -0.18, 0.05)
	tw.tween_property(_body, "position:z", 0.0, 0.12)

func play_death() -> void:
	_alive = false
	set_turn(false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", deg_to_rad(80), 0.5)
	tw.tween_property(self, "position:y", global_position.y - 0.3, 0.5)
	tw.tween_property(self, "scale", Vector3.ONE * 0.85, 0.5)
	var fade := create_tween()
	fade.tween_interval(0.3)
	fade.tween_callback(func(): visible = false)
