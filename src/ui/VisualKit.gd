class_name VisualKit
extends RefCounted
## Direction artistique procédurale (assets temporaires, voir ROADMAP.md).
## Dessine des silhouettes distinctes (couleur dominante + arme reconnaissable)
## utilisables aussi bien sur un Node2D que sur un Control via leur _draw().
##
## Aucune image externe : tout est vectoriel, donc sans licence.

const SKIN := Color("e8c49a")
const OUTLINE := Color(0, 0, 0, 0.55)

# ------------------------------------------------------------------ figures
## Dessine un personnage dans `rect`. `facing` = 1 (droite) ou -1 (gauche).
## `swing` ∈ [0,1] anime l'arme (0 repos, 1 frappe).
static func draw_figure(ci: CanvasItem, rect: Rect2, v: Dictionary, facing: int = 1, swing: float = 0.0) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var cx := rect.position.x + w * 0.5
	var fy := rect.position.y + h
	var primary: Color = v.get("primary", Color("888888"))
	var secondary: Color = v.get("secondary", Color("444444"))
	var body: String = v.get("body", "slim")
	var weapon: String = v.get("weapon", "sword")

	# proportions selon le type de corps
	var torso_w := h * 0.30
	var shoulder := h * 0.34
	var hip := h * 0.22
	match body:
		"heavy":
			torso_w = h * 0.42; shoulder = h * 0.48; hip = h * 0.30
		"brute":
			torso_w = h * 0.40; shoulder = h * 0.46; hip = h * 0.26
		"robed":
			torso_w = h * 0.30; shoulder = h * 0.30; hip = h * 0.40
		"cloaked":
			torso_w = h * 0.32; shoulder = h * 0.36; hip = h * 0.34
		"archer":
			torso_w = h * 0.28; shoulder = h * 0.32; hip = h * 0.22
		"slim":
			torso_w = h * 0.26; shoulder = h * 0.30; hip = h * 0.20

	# ombre au sol
	ci.draw_circle(Vector2(cx, fy - h * 0.01), w * 0.34, Color(0, 0, 0, 0.22))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.35))
	ci.draw_circle(Vector2(cx, (fy - h * 0.01) / 0.35), w * 0.30, Color(0, 0, 0, 0.18))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var head_r := h * 0.12
	var head_y := fy - h * 0.82
	var shoulder_y := fy - h * 0.66
	var hip_y := fy - h * 0.30

	# jambes
	var leg_col := secondary.darkened(0.1)
	_quad(ci, Vector2(cx - hip * 0.5, hip_y), Vector2(cx - hip * 0.1, hip_y),
		Vector2(cx - hip * 0.15, fy), Vector2(cx - hip * 0.5, fy), leg_col)
	_quad(ci, Vector2(cx + hip * 0.1, hip_y), Vector2(cx + hip * 0.5, hip_y),
		Vector2(cx + hip * 0.5, fy), Vector2(cx + hip * 0.15, fy), leg_col)

	# arme derrière (bouclier dos / carquois) selon type
	if weapon == "bow":
		_draw_bow(ci, Vector2(cx - facing * shoulder * 0.55, shoulder_y), h, primary, facing)

	# torse
	var torso := PackedVector2Array([
		Vector2(cx - shoulder * 0.5, shoulder_y),
		Vector2(cx + shoulder * 0.5, shoulder_y),
		Vector2(cx + hip * 0.5, hip_y),
		Vector2(cx - hip * 0.5, hip_y),
	])
	ci.draw_colored_polygon(torso, primary)
	# jupe/robe
	if body == "robed" or body == "cloaked":
		var robe := PackedVector2Array([
			Vector2(cx - hip * 0.5, hip_y), Vector2(cx + hip * 0.5, hip_y),
			Vector2(cx + hip * 0.95, fy), Vector2(cx - hip * 0.95, fy),
		])
		ci.draw_colored_polygon(robe, primary.darkened(0.08))
	# ceinture / accent
	ci.draw_line(Vector2(cx - hip * 0.5, hip_y), Vector2(cx + hip * 0.5, hip_y), secondary, h * 0.03)

	# bras avant (porte l'arme), avec swing
	var swing_ang := deg_to_rad(lerp(20.0, -70.0, swing)) * facing
	var hand := Vector2(cx + facing * shoulder * 0.45, shoulder_y + h * 0.04).rotated(0.0)
	var elbow := Vector2(cx + facing * shoulder * 0.42, shoulder_y + h * 0.10)
	var hand_pos := elbow + Vector2(facing * h * 0.16, 0).rotated(swing_ang)
	ci.draw_line(Vector2(cx + facing * shoulder * 0.4, shoulder_y), elbow, primary.lightened(0.05), h * 0.06)
	ci.draw_line(elbow, hand_pos, SKIN, h * 0.05)

	# arme dans la main avant
	_draw_weapon(ci, weapon, hand_pos, swing_ang, h, primary, secondary, facing)

	# bras arrière
	ci.draw_line(Vector2(cx - facing * shoulder * 0.4, shoulder_y),
		Vector2(cx - facing * shoulder * 0.3, hip_y), primary.darkened(0.12), h * 0.055)

	# tête + capuche
	if body == "cloaked" or body == "robed":
		var hood := PackedVector2Array([
			Vector2(cx - head_r * 1.3, head_y), Vector2(cx + head_r * 1.3, head_y),
			Vector2(cx + head_r * 0.7, head_y - head_r * 1.4),
			Vector2(cx - head_r * 0.7, head_y - head_r * 1.4),
		])
		ci.draw_colored_polygon(hood, primary.darkened(0.05))
		ci.draw_circle(Vector2(cx + facing * head_r * 0.2, head_y), head_r * 0.78, SKIN.darkened(0.25))
	else:
		ci.draw_circle(Vector2(cx, head_y), head_r, SKIN)
		# casque / cheveux teinté
		var helm := PackedVector2Array([
			Vector2(cx - head_r, head_y), Vector2(cx + head_r, head_y),
			Vector2(cx + head_r * 0.8, head_y - head_r * 1.1),
			Vector2(cx - head_r * 0.8, head_y - head_r * 1.1),
		])
		ci.draw_colored_polygon(helm, secondary)

	# bouclier au bras arrière pour les défenseurs
	if weapon == "shield":
		var sx := cx - facing * shoulder * 0.42
		ci.draw_circle(Vector2(sx, hip_y - h * 0.04), h * 0.16, secondary)
		ci.draw_circle(Vector2(sx, hip_y - h * 0.04), h * 0.16, primary, false, h * 0.02)
		ci.draw_circle(Vector2(sx, hip_y - h * 0.04), h * 0.05, primary)

static func _quad(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([a, b, c, d]), col)

static func _draw_weapon(ci: CanvasItem, weapon: String, hand: Vector2, ang: float,
		h: float, primary: Color, secondary: Color, facing: int) -> void:
	var dir := Vector2(facing, 0).rotated(ang)
	match weapon:
		"sword":
			ci.draw_line(hand, hand + dir * h * 0.42, Color("dfe6f0"), h * 0.035)
			ci.draw_line(hand - dir * h * 0.05, hand + dir * h * 0.02,
				secondary, h * 0.09)   # garde
		"axe":
			var head := hand + dir * h * 0.34
			ci.draw_line(hand, head, secondary.darkened(0.2), h * 0.04)
			ci.draw_circle(head, h * 0.11, Color("c9ccd4"))
			ci.draw_colored_polygon(PackedVector2Array([
				head, head + dir.rotated(1.4) * h * 0.16, head + dir * h * 0.14]), Color("aeb3bd"))
		"dagger":
			ci.draw_line(hand, hand + dir * h * 0.22, Color("d6e0ea"), h * 0.03)
			ci.draw_line(hand - dir * h * 0.03, hand + dir * h * 0.01, secondary, h * 0.07)
		"staff":
			ci.draw_line(hand - dir * h * 0.15, hand + dir * h * 0.45, secondary.darkened(0.1), h * 0.03)
			ci.draw_circle(hand + dir * h * 0.45, h * 0.08, primary.lightened(0.25))
			ci.draw_circle(hand + dir * h * 0.45, h * 0.045, Color(1, 1, 1, 0.8))
		"orb":
			var op := hand + dir * h * 0.16
			ci.draw_circle(op, h * 0.10, primary.lightened(0.2))
			ci.draw_circle(op, h * 0.05, Color(1, 1, 1, 0.85))
		"bow":
			pass   # dessiné derrière
		_:
			ci.draw_line(hand, hand + dir * h * 0.3, Color("dddddd"), h * 0.03)

static func _draw_bow(ci: CanvasItem, pos: Vector2, h: float, primary: Color, facing: int) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := lerpf(-1.1, 1.1, i / 8.0)
		pts.append(pos + Vector2(facing * sin(a) * h * 0.04 + facing * h * 0.18, cos(a) * h * 0.30 - h * 0.0))
	ci.draw_polyline(pts, primary.lightened(0.1), h * 0.025)
	ci.draw_line(pts[0], pts[pts.size() - 1], Color(0.9, 0.9, 0.9, 0.6), h * 0.012)

# ------------------------------------------------------------------ portraits
## Buste stylisé dans `rect` (collection, cartes, fiche).
static func draw_portrait(ci: CanvasItem, rect: Rect2, v: Dictionary) -> void:
	var primary: Color = v.get("primary", Color("888888"))
	var secondary: Color = v.get("secondary", Color("444444"))
	var body: String = v.get("body", "slim")
	# fond dégradé simple
	ci.draw_rect(rect, primary.darkened(0.55))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.5)), primary.darkened(0.45))
	var cx := rect.position.x + rect.size.x * 0.5
	var by := rect.position.y + rect.size.y
	var s := rect.size.y
	# épaules
	var sh := PackedVector2Array([
		Vector2(cx - s * 0.42, by), Vector2(cx - s * 0.34, by - s * 0.28),
		Vector2(cx + s * 0.34, by - s * 0.28), Vector2(cx + s * 0.42, by),
	])
	ci.draw_colored_polygon(sh, primary)
	# cou + tête
	ci.draw_line(Vector2(cx, by - s * 0.28), Vector2(cx, by - s * 0.42), SKIN, s * 0.10)
	if body == "cloaked" or body == "robed":
		var hood := PackedVector2Array([
			Vector2(cx - s * 0.26, by - s * 0.30), Vector2(cx + s * 0.26, by - s * 0.30),
			Vector2(cx + s * 0.16, by - s * 0.72), Vector2(cx - s * 0.16, by - s * 0.72)])
		ci.draw_colored_polygon(hood, primary.darkened(0.08))
		ci.draw_circle(Vector2(cx, by - s * 0.5), s * 0.14, SKIN.darkened(0.25))
	else:
		ci.draw_circle(Vector2(cx, by - s * 0.52), s * 0.16, SKIN)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(cx - s * 0.16, by - s * 0.52), Vector2(cx + s * 0.16, by - s * 0.52),
			Vector2(cx + s * 0.12, by - s * 0.70), Vector2(cx - s * 0.12, by - s * 0.70)]), secondary)

# ------------------------------------------------------------------ icônes éléments
static func draw_element_icon(ci: CanvasItem, rect: Rect2, element: int) -> void:
	var c := rect.position + rect.size * 0.5
	var r := minf(rect.size.x, rect.size.y) * 0.5
	match element:
		GameEnums.Element.FEU:
			var col := Color("e8552d")
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, r), c + Vector2(r * 0.7, r * 0.1),
				c + Vector2(0, -r), c + Vector2(-r * 0.7, r * 0.1)]), col)
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.4, Color("ffd27a"))
		GameEnums.Element.EAU:
			var col := Color("3a8ed6")
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.72, r * 0.4),
				c + Vector2(0, r), c + Vector2(-r * 0.72, r * 0.4)]), col)
			ci.draw_circle(c + Vector2(-r * 0.2, r * 0.2), r * 0.25, Color("bfe4ff"))
		GameEnums.Element.NATURE:
			var col := Color("57b34a")
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.7, 0),
				c + Vector2(0, r), c + Vector2(-r * 0.7, 0)]), col)
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.8), Color("2e6b27"), r * 0.12)

# ------------------------------------------------------------------ icônes statuts
static func draw_status_icon(ci: CanvasItem, rect: Rect2, icon_key: String, color: Color, is_buff: bool) -> void:
	var bg := StyleBoxFlat.new()
	ci.draw_rect(rect, color.darkened(0.2))
	ci.draw_rect(rect, color, false, 1.0)
	var c := rect.position + rect.size * 0.5
	var r := minf(rect.size.x, rect.size.y) * 0.32
	var glyph := Color(1, 1, 1, 0.95)
	match icon_key:
		"buff_atk", "buff_crit":
			_arrow(ci, c, r, true, glyph)
		"buff_def", "buff_spd", "regen":
			_arrow(ci, c, r, true, glyph)
		"debuff_atk", "debuff_def", "debuff_spd":
			_arrow(ci, c, r, false, glyph)
		"shield":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r, -r * 0.5),
				c + Vector2(0, r), c + Vector2(-r, -r * 0.5)]), glyph)
		"burn":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, r), c + Vector2(r * 0.7, 0), c + Vector2(0, -r), c + Vector2(-r * 0.7, 0)]), Color("ffd27a"))
		"poison":
			ci.draw_circle(c, r * 0.8, Color("c8f08a"))
		"stun":
			ci.draw_arc(c, r, 0.0, TAU * 0.8, 10, glyph, 2.0)
		"freeze":
			for k in 3:
				var a := k * PI / 3.0
				ci.draw_line(c - Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a), sin(a)) * r, glyph, 1.5)
		"taunt":
			ci.draw_circle(c, r * 0.7, Color("ff9a7a"))
			ci.draw_circle(c, r * 0.3, color.darkened(0.3))
		_:
			ci.draw_circle(c, r * 0.6, glyph)

static func _arrow(ci: CanvasItem, c: Vector2, r: float, up: bool, col: Color) -> void:
	var s := -1.0 if up else 1.0
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, s * r), c + Vector2(r * 0.7, s * -r * 0.1), c + Vector2(-r * 0.7, s * -r * 0.1)]), col)
	ci.draw_line(c + Vector2(0, s * -r * 0.1), c + Vector2(0, s * -r * 0.9), col, 2.0)

# ------------------------------------------------------------------ étoiles rareté
static func rarity_color(rarete: int) -> Color:
	match rarete:
		5: return Color("f0a830")
		4: return Color("a06cf0")
		3: return Color("4aa6e0")
	return Color("9aa0b0")

static func draw_stars(ci: CanvasItem, pos: Vector2, count: int, size: float, col: Color) -> void:
	for i in count:
		_star(ci, pos + Vector2(i * size * 1.15, 0), size * 0.5, col)

static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2 + i * PI / 5
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	ci.draw_colored_polygon(pts, col)
