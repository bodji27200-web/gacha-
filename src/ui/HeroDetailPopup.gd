class_name HeroDetailPopup
extends CanvasLayer
## Fiche compacte d'un héros : portrait/sprite, stats, 3 compétences, fragments.

var inst: HeroInstance

const TARGET_NAMES := {
	GameEnums.Target.ENEMY_ONE: "Un ennemi",
	GameEnums.Target.ENEMY_ALL: "Tous les ennemis",
	GameEnums.Target.ALLY_ONE: "Un allié",
	GameEnums.Target.ALLY_OTHER: "Un autre allié",
	GameEnums.Target.ALLY_ALL: "Toute l'équipe",
	GameEnums.Target.ALLY_LOWEST: "Allié le plus faible",
	GameEnums.Target.SELF: "Soi-même",
}

func setup(p_inst: HeroInstance) -> void:
	inst = p_inst

func _init() -> void:
	layer = 50

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			queue_free())
	add_child(dim)

	var def: HeroDefinition = DataRegistry.get_hero(inst.def_id)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	panel.custom_minimum_size = Vector2(760, 540)
	center.add_child(panel)

	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 20)
	panel.add_child(m)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.add_child(scroll)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.custom_minimum_size.x = 700
	scroll.add_child(root)

	# --- En-tête ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)

	var fig := FigureView.new()
	fig.setup(HeroCard._visual(def), 1, true)
	fig.custom_minimum_size = Vector2(210, 280)
	top.add_child(fig)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	top.add_child(info)

	var namerow := HBoxContainer.new()
	namerow.add_theme_constant_override("separation", 10)
	namerow.add_child(Style.title(def.nom, 32))
	namerow.add_child(_stars(def.rarete))
	info.add_child(namerow)

	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 8)
	badges.add_child(_chip(GameEnums.element_name(def.element), GameEnums.element_color(def.element)))
	badges.add_child(_chip(GameEnums.role_name(def.role), GameEnums.role_color(def.role)))
	badges.add_child(_chip("%d★" % def.rarete, VisualKit.rarity_color(def.rarete)))
	info.add_child(badges)

	info.add_child(Style.label(def.description, 14, Style.DIM))

	# Niveau + XP
	info.add_child(_xp_block(def))

	# Fragments
	var fragbox := HBoxContainer.new()
	fragbox.add_theme_constant_override("separation", 6)
	var ficon := MiniIcon.new()
	ficon.setup("fragment")
	fragbox.add_child(ficon)
	fragbox.add_child(Style.label("Fragments : %d (utilisables en phase 2)" % inst.fragments, 14, Style.DIM))
	info.add_child(fragbox)

	# --- Statistiques ---
	root.add_child(_section_title("Statistiques"))
	root.add_child(_stats_grid(def))

	# --- Compétences ---
	root.add_child(_section_title("Compétences"))
	for skill in DataRegistry.hero_skills(def):
		root.add_child(_skill_row(skill, def))

	var close := Style.button("Fermer")
	close.pressed.connect(func():
		AudioManager.play_sfx("click")
		queue_free())
	root.add_child(close)

func _xp_block(def: HeroDefinition) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	var need := GameState.exp_to_next(inst.niveau)
	v.add_child(Style.label("Niveau %d / %d" % [inst.niveau, GameState.MAX_LEVEL], 18, Style.ACCENT))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 16
	bar.show_percentage = false
	if need < 0:
		bar.max_value = 1; bar.value = 1
		v.add_child(bar)
		v.add_child(Style.label("Niveau maximum atteint", 12, Style.DIM))
	else:
		bar.max_value = need; bar.value = inst.exp
		v.add_child(bar)
		v.add_child(Style.label("XP : %d / %d" % [inst.exp, need], 12, Style.DIM))
	return v

func _stats_grid(def: HeroDefinition) -> GridContainer:
	var s: Stats = def.stats_at_level(inst.niveau)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	var data := [
		["PV", str(int(s.pv))], ["Attaque", str(int(s.attaque))],
		["Défense", str(int(s.defense))], ["Vitesse", str(int(s.vitesse))],
		["Taux crit.", "%d %%" % int(s.crit_taux * 100)],
		["Dégâts crit.", "%d %%" % int(s.crit_degats * 100)],
		["Précision", "%d %%" % int(s.precision * 100)],
		["Résistance", "%d %%" % int(s.resistance * 100)],
	]
	for pair in data:
		var cell := VBoxContainer.new()
		cell.add_child(Style.label(pair[0], 12, Style.DIM))
		cell.add_child(Style.label(pair[1], 18, Style.TEXT))
		grid.add_child(cell)
	return grid

func _skill_row(skill: SkillDefinition, def: HeroDefinition) -> PanelContainer:
	var p := Style.panel(Style.PANEL2)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 12)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	m.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(Style.label(skill.nom, 18, Style.ACCENT))
	head.add_child(Style.spacer())
	if skill.cooldown > 0:
		head.add_child(_chip("Recharge %d" % skill.cooldown, Style.ACCENT2))
	head.add_child(_chip(TARGET_NAMES.get(skill.target, "?"), Style.PANEL3))
	v.add_child(head)
	v.add_child(Style.label(skill.description, 14, Style.TEXT))
	return p

func _section_title(text: String) -> Label:
	return Style.title(text, 20, Style.ACCENT2.lightened(0.25))

func _chip(text: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Style._sb(col.darkened(0.15), 6))
	var l := Style.label(text, 13, Color.WHITE)
	p.add_child(l)
	return p

func _stars(count: int) -> Control:
	var s := _StarRow.new()
	s.count = count
	s.custom_minimum_size = Vector2(count * 22, 22)
	return s

class _StarRow extends Control:
	var count := 3
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		VisualKit.draw_stars(self, Vector2(10, size.y * 0.5), count, 18, VisualKit.rarity_color(count))
