extends Control
## Menu principal : navigation en un clic + ressources + équipe actuelle.

func _ready() -> void:
	Style.apply(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Style.bg_rect())
	AudioManager.play_music("menu")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 30)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	# --- En-tête ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var titlebox := VBoxContainer.new()
	titlebox.add_child(Style.title("Cendres & Cristaux", 38))
	titlebox.add_child(Style.label("Prototype gacha — Phase 1", 15, Style.DIM))
	header.add_child(titlebox)
	header.add_child(Style.spacer())
	var cb := CurrencyBar.new()
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(cb)
	root.add_child(header)

	root.add_child(_hsep())

	# --- Contenu ---
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	nav.custom_minimum_size.x = 360
	nav.add_child(_nav_button("⚔", "Combats", "Affronter les Ruines de Cendre", SceneRouter.STAGES))
	nav.add_child(_nav_button("👥", "Équipe", "Composer son équipe de 4 héros", SceneRouter.TEAM))
	nav.add_child(_nav_button("📖", "Collection", "Consulter et trier ses héros", SceneRouter.COLLECTION))
	nav.add_child(_nav_button("✦", "Invocation", "Invoquer de nouveaux héros", SceneRouter.SUMMON))
	content.add_child(nav)

	content.add_child(_team_panel())

	# --- Pied de page ---
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	var settings_btn := Style.button("  Paramètres  ")
	settings_btn.pressed.connect(_open_settings)
	footer.add_child(settings_btn)
	footer.add_child(Style.spacer())
	footer.add_child(Style.label("v0.1 · Phase 1", 13, Style.DIM))
	if Style.is_debug():
		var dev := Style.button("  Outils Dev  ")
		dev.pressed.connect(_open_dev)
		footer.add_child(dev)
	root.add_child(footer)

func _nav_button(glyph: String, title: String, subtitle: String, scene: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(360, 78)
	b.focus_mode = Control.FOCUS_ALL
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16; h.offset_top = 8; h.offset_right = -12; h.offset_bottom = -8
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var g := Style.label(glyph, 32, Style.ACCENT)
	g.custom_minimum_size.x = 40
	g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(g)
	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(Style.label(title, 24, Style.TEXT))
	v.add_child(Style.label(subtitle, 13, Style.DIM))
	h.add_child(v)
	b.pressed.connect(func():
		AudioManager.play_sfx("click")
		SceneRouter.goto(scene))
	return b

func _team_panel() -> PanelContainer:
	var panel := Style.panel(Style.PANEL)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 18)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	v.add_child(Style.title("Équipe actuelle", 22, Style.TEXT))

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in 4:
		var uid: String = GameState.team[i]
		var hi: HeroInstance = GameState.get_instance_by_uid(uid) if uid != "" else null
		if hi != null:
			var card := HeroCard.new()
			card.setup(hi, 110)
			card.pressed.connect(func(): SceneRouter.goto(SceneRouter.TEAM))
			grid.add_child(card)
		else:
			grid.add_child(_empty_slot())
	v.add_child(grid)

	var edit := Style.button("Modifier l'équipe")
	edit.pressed.connect(func(): SceneRouter.goto(SceneRouter.TEAM))
	v.add_child(edit)
	return panel

func _empty_slot() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Style._sb(Style.PANEL2.darkened(0.2), 10, Style.DIM.darkened(0.3), 1))
	p.custom_minimum_size = Vector2(110, 160)
	var l := Style.label("+", 40, Style.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _hsep() -> Control:
	var r := ColorRect.new()
	r.color = Style.PANEL3
	r.custom_minimum_size.y = 2
	return r

func _open_settings() -> void:
	AudioManager.play_sfx("click")
	add_child(SettingsPopup.new())

func _open_dev() -> void:
	add_child(DevMenu.new())
