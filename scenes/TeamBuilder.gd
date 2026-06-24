extends Control
## Composition d'une équipe de 4 héros (anti-doublon, synergies, sauvegarde auto).

var _content: VBoxContainer
var _hint: Label

func _ready() -> void:
	Style.apply(self)
	add_child(Style.bg_rect())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var header := ScreenHeader.new()
	header.setup("Équipe")
	root.add_child(header)

	_hint = Style.label("", 14, Style.ACCENT)
	root.add_child(_hint)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	if not GameState.team_changed.is_connected(_rebuild):
		GameState.team_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in _content.get_children():
		c.queue_free()

	# --- Emplacements + synergies ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	_content.add_child(top)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	for i in 4:
		slots.add_child(_slot(i))
	top.add_child(slots)

	top.add_child(_synergy_panel())

	# --- Collection ---
	var sub := Style.label("Cliquez un héros pour l'ajouter ou le retirer de l'équipe.", 14, Style.DIM)
	_content.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var heroes := GameState.heroes.duplicate()
	heroes.sort_custom(func(a, b): return GameState.power(a) > GameState.power(b))
	for inst in heroes:
		grid.add_child(_collection_card(inst))

func _slot(i: int) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size.x = 124
	var uid: String = GameState.team[i]
	var inst: HeroInstance = GameState.get_instance_by_uid(uid) if uid != "" else null
	if inst != null:
		var card := HeroCard.new()
		card.setup(inst, 120)
		card.pressed.connect(func():
			AudioManager.play_sfx("click")
			GameState.clear_team_slot(i)
			SaveManager.autosave())
		v.add_child(card)
		v.add_child(Style.label("Puissance %d" % GameState.power(inst), 13, Style.ACCENT))
	else:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Style._sb(Style.PANEL2.darkened(0.2), 10, Style.DIM.darkened(0.3), 1))
		p.custom_minimum_size = Vector2(120, 170)
		var l := Style.label("Emplacement\n%d" % (i + 1), 16, Style.DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		v.add_child(p)
		v.add_child(Style.label(" ", 13))
	return v

func _synergy_panel() -> PanelContainer:
	var panel := Style.panel(Style.PANEL)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 16)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	v.add_child(Style.title("Résumé de l'équipe", 20, Style.TEXT))

	var team := GameState.team_instances()
	var elements := {GameEnums.Element.FEU: 0, GameEnums.Element.EAU: 0, GameEnums.Element.NATURE: 0}
	var roles := {}
	var total_power := 0
	for inst in team:
		var def: HeroDefinition = DataRegistry.get_hero(inst.def_id)
		elements[def.element] += 1
		roles[def.role] = int(roles.get(def.role, 0)) + 1
		total_power += GameState.power(inst)

	var erow := HBoxContainer.new()
	erow.add_theme_constant_override("separation", 14)
	for el in [GameEnums.Element.FEU, GameEnums.Element.EAU, GameEnums.Element.NATURE]:
		erow.add_child(_element_count(el, elements[el]))
	v.add_child(erow)

	var role_text := ""
	for r in roles.keys():
		role_text += "%s ×%d   " % [GameEnums.role_name(r), roles[r]]
	v.add_child(Style.label(role_text if role_text != "" else "Aucun héros", 14, Style.DIM))
	v.add_child(Style.label("Puissance totale : %d" % total_power, 16, Style.ACCENT))

	var note := ""
	var distinct := 0
	for el in elements.keys():
		if elements[el] > 0:
			distinct += 1
	if team.size() >= 3 and distinct == 1:
		note = "Mono-élément : vulnérable au contre élémentaire."
	elif distinct == 3:
		note = "Trois éléments : couverture élémentaire complète."
	if note != "":
		v.add_child(Style.label(note, 13, Style.ACCENT2.lightened(0.2)))
	return panel

func _element_count(el: int, n: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	var ico := _ElementBadge.new()
	ico.element = el
	ico.custom_minimum_size = Vector2(22, 22)
	h.add_child(ico)
	h.add_child(Style.label("×%d" % n, 16, Style.TEXT))
	return h

func _collection_card(inst: HeroInstance) -> Control:
	var in_team := inst.uid in GameState.team
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", Style._sb(
		Style.OK.darkened(0.3) if in_team else Color(0, 0, 0, 0), 12,
		Style.OK if in_team else Color(0, 0, 0, 0), 3 if in_team else 0))
	var card := HeroCard.new()
	card.setup(inst, 112)
	card.pressed.connect(func(): _toggle(inst))
	wrap.add_child(card)
	return wrap

func _toggle(inst: HeroInstance) -> void:
	AudioManager.play_sfx("click")
	var slot: int = GameState.team.find(inst.uid)
	if slot != -1:
		GameState.clear_team_slot(slot)
	else:
		var empty: int = GameState.team.find("")
		if empty != -1:
			GameState.set_team_slot(empty, inst.uid)
		else:
			_flash("Équipe complète — retirez un héros d'abord.")
			return
	SaveManager.autosave()

func _flash(text: String) -> void:
	_hint.text = text
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(_hint):
		_hint.text = ""

## Petit badge d'élément dessiné.
class _ElementBadge extends Control:
	var element := 0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		VisualKit.draw_element_icon(self, Rect2(Vector2.ZERO, size), element)
