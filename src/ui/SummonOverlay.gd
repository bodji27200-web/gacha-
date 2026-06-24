class_name SummonOverlay
extends CanvasLayer
## Animation d'invocation 2D : portail → accumulation de lumière → couleur de rareté
## → silhouette → révélation des cartes. Accélérable / passable.

signal closed

var results: Array = []
var skippable := true
var rarity_max := 3

var _state := "portal"
var _t := 0.0
var _portal: _Portal
var _center: CenterContainer
var _skip_btn: Button

const PORTAL_DUR := 1.25

func setup(p_results: Array, p_skippable: bool) -> void:
	results = p_results
	skippable = p_skippable
	for r in results:
		rarity_max = maxi(rarity_max, int(r.get("rarity", 3)))

func _init() -> void:
	layer = 80

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_portal = _Portal.new()
	_portal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portal.rarity_color = VisualKit.rarity_color(rarity_max)
	_portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portal)

	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center)

	_skip_btn = Style.button("Passer  ⏩")
	_skip_btn.theme = Style.theme()
	_skip_btn.position = Vector2(40, 40)
	_skip_btn.pressed.connect(_skip)
	_skip_btn.visible = skippable
	add_child(_skip_btn)

	AudioManager.play_sfx("summon")
	set_process(true)

func _process(delta: float) -> void:
	if _state != "portal":
		return
	_t += delta
	_portal.phase = clampf(_t / PORTAL_DUR, 0.0, 1.0)
	_portal.queue_redraw()
	if _t >= PORTAL_DUR:
		_reveal()

func _skip() -> void:
	if _state == "portal":
		_t = PORTAL_DUR
		_reveal()

func _reveal() -> void:
	_state = "reveal"
	set_process(false)
	_portal.flash = 1.0
	_portal.queue_redraw()
	_skip_btn.visible = false
	AudioManager.play_sfx("reveal_rare" if rarity_max >= 4 else "click")

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var grid := GridContainer.new()
	grid.columns = mini(5, maxi(1, results.size()))
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for r in results:
		grid.add_child(_result_card(r))
	box.add_child(grid)

	var cont := Style.button("Continuer", Vector2(220, 52))
	cont.theme = Style.theme()
	cont.pressed.connect(func():
		AudioManager.play_sfx("click")
		closed.emit()
		queue_free())
	var center_btn := CenterContainer.new()
	center_btn.add_child(cont)
	box.add_child(center_btn)

	_center.add_child(box)
	# petite apparition
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.25)

func _result_card(r: Dictionary) -> PanelContainer:
	var def: HeroDefinition = DataRegistry.get_hero(r.get("def_id", ""))
	var rc := VisualKit.rarity_color(int(r.get("rarity", 3)))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Style._sb(Style.PANEL.darkened(0.1), 12, rc, 3))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	m.add_child(v)

	var fig := FigureView.new()
	fig.setup(HeroCard._visual(def), 1, true)
	fig.custom_minimum_size = Vector2(150, 190)
	v.add_child(fig)

	var name_l := Style.label(def.nom, 18, Style.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)

	var stars := _StarRow.new()
	stars.count = def.rarete
	stars.custom_minimum_size = Vector2(def.rarete * 18, 18)
	v.add_child(stars)

	var status := Style.label("", 13, Style.OK)
	if r.get("is_new", false):
		status.text = "Nouveau héros !"
		status.add_theme_color_override("font_color", Style.OK)
	else:
		status.text = "Doublon · +%d fragments" % int(r.get("fragments", 0))
		status.add_theme_color_override("font_color", Style.DIM)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(status)
	return panel

# ----------------------------------------------------------- portail dessiné
class _Portal extends Control:
	var phase := 0.0
	var flash := 0.0
	var rarity_color := Color("4aa6e0")

	func _draw() -> void:
		var c := size * 0.5
		var maxr: float = minf(size.x, size.y) * 0.42
		# halo qui s'accumule
		for i in range(8, 0, -1):
			var rr := maxr * (i / 8.0) * (0.3 + 0.7 * phase)
			var a := 0.06 * phase * (1.0 - i / 9.0) + 0.02
			draw_circle(c, rr, Color(rarity_color.r, rarity_color.g, rarity_color.b, a))
		# anneau du portail
		draw_arc(c, maxr * (0.4 + 0.6 * phase), 0.0, TAU, 64, rarity_color, 4.0)
		# rayons
		var rays := 12
		for i in rays:
			var ang := TAU * i / rays + phase * 3.0
			var inner := c + Vector2(cos(ang), sin(ang)) * maxr * 0.2
			var outer := c + Vector2(cos(ang), sin(ang)) * maxr * (0.5 + 0.6 * phase)
			draw_line(inner, outer, Color(1, 1, 1, 0.15 + 0.25 * phase), 2.0)
		# cœur lumineux
		draw_circle(c, maxr * 0.12 * (0.5 + phase), Color(1, 1, 1, 0.5 + 0.5 * phase))
		# flash de révélation
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.5))

class _StarRow extends Control:
	var count := 3
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		VisualKit.draw_stars(self, Vector2(6, size.y * 0.5), count, 16, VisualKit.rarity_color(count))
