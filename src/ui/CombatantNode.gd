class_name CombatantNode
extends Control
## Représentation visuelle d'un combattant : sprite, PV, bouclier, jauge, statuts,
## surbrillance de cible, marqueur d'unité active, et animations.

signal selected(cid)

var combatant: Combatant
var fig: FigureView
var name_l: Label
var hp_text: Label
var status_box: HBoxContainer
var active_arrow: Label
var btn: Button
var _targetable := false
var _active := false
var _pulse := 0.0

func setup(c: Combatant) -> void:
	combatant = c
	var w := 200.0 if c.is_boss else 150.0
	var h := 290.0 if c.is_boss else 224.0
	custom_minimum_size = Vector2(w, h)

	fig = FigureView.new()
	fig.setup(c.visual, -1 if c.is_enemy else 1, false)
	fig.set_anchors_preset(Control.PRESET_FULL_RECT)
	fig.offset_bottom = -46
	fig.offset_top = 18
	add_child(fig)

	name_l = Style.label(c.display_name, 18 if c.is_boss else 14, Style.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(name_l)

	status_box = HBoxContainer.new()
	status_box.add_theme_constant_override("separation", 2)
	status_box.position = Vector2(6, 22)
	add_child(status_box)

	active_arrow = Style.label("▼", 22, Style.ACCENT)
	active_arrow.visible = false
	add_child(active_arrow)

	hp_text = Style.label("", 12, Color.WHITE)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hp_text)

	btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_theme_stylebox_override("normal", Style._sb(Color(0, 0, 0, 0), 8))
	btn.add_theme_stylebox_override("hover", Style._sb(Color(1, 1, 1, 0.06), 8))
	btn.add_theme_stylebox_override("focus", Style._sb(Color(0, 0, 0, 0), 8, Style.ACCENT, 2))
	btn.pressed.connect(func():
		if _targetable:
			AudioManager.play_sfx("click")
			selected.emit(combatant.cid))
	add_child(btn)

	resized.connect(_relayout)
	set_process(true)
	_relayout()
	update_view()

func _relayout() -> void:
	if hp_text:
		hp_text.position = Vector2(0, size.y - 36)
		hp_text.size = Vector2(size.x, 16)
	if active_arrow:
		active_arrow.position = Vector2(size.x * 0.5 - 8, -4)

func _process(delta: float) -> void:
	if _targetable or _active:
		_pulse = fmod(_pulse + delta * 4.0, TAU)
		queue_redraw()

func update_view() -> void:
	var alive := combatant.is_alive()
	hp_text.text = "%d / %d" % [int(ceil(combatant.hp)), int(combatant.max_hp)]
	if not alive:
		fig.modulate = Color(0.35, 0.35, 0.4, 0.45)
		name_l.add_theme_color_override("font_color", Style.DIM)
		hp_text.text = "K.O."
	for c in status_box.get_children():
		c.queue_free()
	for s in combatant.statuses:
		var icon := StatusIconView.new()
		status_box.add_child(icon)
		icon.setup(s)
	queue_redraw()

func set_targetable(on: bool) -> void:
	_targetable = on
	btn.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_active(on: bool) -> void:
	_active = on
	active_arrow.visible = on
	queue_redraw()

func _draw() -> void:
	var bx := 8.0
	var bw := size.x - 16.0
	var hy := size.y - 34.0
	# fond barre PV
	draw_rect(Rect2(bx, hy, bw, 16), Color(0, 0, 0, 0.55))
	var ratio: float = combatant.hp_ratio()
	var hp_col := Style.OK
	if ratio < 0.3:
		hp_col = Style.DANGER
	elif ratio < 0.6:
		hp_col = Style.ACCENT
	draw_rect(Rect2(bx, hy, bw * ratio, 16), hp_col)
	# bouclier (segment cyan au-dessus)
	var shield := combatant.total_shield()
	if shield > 0.0:
		var sr: float = clampf(shield / combatant.max_hp, 0.0, 1.0)
		draw_rect(Rect2(bx, hy - 5, bw * sr, 5), Style.CRYSTAL)
	draw_rect(Rect2(bx, hy, bw, 16), Color(1, 1, 1, 0.15), false, 1.0)
	# jauge d'action
	var gy := hy + 19
	draw_rect(Rect2(bx, gy, bw, 5), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(bx, gy, bw * (combatant.gauge / 100.0), 5), Style.ACCENT2.lightened(0.2))
	# surbrillances
	if _active:
		var a := 0.5 + 0.4 * sin(_pulse)
		draw_rect(Rect2(2, 16, size.x - 4, size.y - 18), Color(Style.ACCENT.r, Style.ACCENT.g, Style.ACCENT.b, a), false, 3.0)
	if _targetable:
		var a2 := 0.55 + 0.4 * sin(_pulse)
		var col := Style.DANGER if combatant.is_enemy else Style.OK
		draw_rect(Rect2(2, 16, size.x - 4, size.y - 18), Color(col.r, col.g, col.b, a2), false, 3.0)

# --------------------------------------------------------------- animations
func play_lunge() -> void:
	var dir := 1.0 if not combatant.is_enemy else -1.0
	var tw := create_tween()
	tw.tween_property(fig, "position:x", dir * 42.0, 0.12)
	tw.tween_property(fig, "position:x", 0.0, 0.16)

func play_cast() -> void:
	var tw := create_tween()
	tw.tween_property(fig, "scale", Vector2(1.08, 1.08), 0.12)
	tw.tween_property(fig, "scale", Vector2.ONE, 0.18)

func play_hit() -> void:
	fig.modulate = Color(1.6, 0.6, 0.6, 1.0)
	var tw := create_tween()
	tw.tween_property(fig, "modulate", Color.WHITE, 0.25)
	var tw2 := create_tween()
	tw2.tween_property(fig, "position:x", 8.0, 0.04)
	tw2.tween_property(fig, "position:x", -8.0, 0.06)
	tw2.tween_property(fig, "position:x", 0.0, 0.05)

func play_death() -> void:
	var tw := create_tween()
	tw.tween_property(fig, "modulate", Color(0.35, 0.35, 0.4, 0.45), 0.4)

func global_center() -> Vector2:
	return global_position + size * 0.5
