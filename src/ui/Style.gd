class_name Style
extends RefCounted
## Palette et thème communs à toute l'interface (lisible sur TV, contrastes élevés).

const BG := Color("14101f")
const PANEL := Color("221b33")
const PANEL2 := Color("2e2542")
const PANEL3 := Color("3a2f52")
const ACCENT := Color("e8a33a")
const ACCENT2 := Color("6c5ce7")
const TEXT := Color("f0ead6")
const DIM := Color("aaa2bc")
const DANGER := Color("d2444f")
const OK := Color("3fb98a")
const GOLD := Color("e8c24a")
const CRYSTAL := Color("7fd0ff")

static var _theme: Theme

static func _sb(color: Color, radius: int = 8, border_col: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if border_w > 0:
		s.border_color = border_col
		s.set_border_width_all(border_w)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var th := Theme.new()
	# Police DejaVu Sans (libre) : couvre le français + les symboles (★ ▲ ▼ …)
	# que la police par défaut de Godot n'inclut pas.
	var f: Font = load("res://assets/fonts/DejaVuSans.ttf")
	if f != null:
		th.default_font = f
	th.default_font_size = 18

	th.set_stylebox("normal", "Button", _sb(PANEL2, 8, ACCENT2.darkened(0.2), 1))
	th.set_stylebox("hover", "Button", _sb(PANEL3, 8, ACCENT, 2))
	th.set_stylebox("pressed", "Button", _sb(ACCENT2.darkened(0.1), 8))
	th.set_stylebox("disabled", "Button", _sb(PANEL.darkened(0.1), 8))
	th.set_stylebox("focus", "Button", _sb(Color(0, 0, 0, 0), 8, ACCENT, 2))
	th.set_color("font_color", "Button", TEXT)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", DIM.darkened(0.2))
	th.set_font_size("font_size", "Button", 18)

	th.set_color("font_color", "Label", TEXT)
	th.set_stylebox("panel", "PanelContainer", _sb(PANEL, 12))

	var line := _sb(PANEL.darkened(0.2), 6, ACCENT2.darkened(0.3), 1)
	th.set_stylebox("normal", "LineEdit", line)
	th.set_color("font_color", "LineEdit", TEXT)

	th.set_stylebox("panel", "Panel", _sb(PANEL, 12))
	_theme = th
	return th

static func apply(root: Control) -> void:
	root.theme = theme()

# --------------------------------------------------------- fabriques rapides
static func title(text: String, size: int = 30, color: Color = ACCENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func button(text: String, min_size: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	if min_size != Vector2.ZERO:
		b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	return b

static func panel(bg: Color = PANEL, radius: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(bg, radius))
	return p

static func bg_rect() -> ColorRect:
	var r := ColorRect.new()
	r.color = BG
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func spacer(expand: bool = true) -> Control:
	var c := Control.new()
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

static func is_debug() -> bool:
	return OS.is_debug_build()
