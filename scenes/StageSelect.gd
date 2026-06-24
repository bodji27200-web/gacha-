extends Control
## Sélection des stages du chapitre 1.

func _ready() -> void:
	Style.apply(self)
	add_child(Style.bg_rect())
	AudioManager.play_music("menu")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := ScreenHeader.new()
	header.setup("Combats")
	root.add_child(header)

	root.add_child(Style.label("Chapitre 1 — Les Ruines de Cendre", 20, Style.ACCENT2.lightened(0.2)))

	if not GameState.team_is_valid():
		root.add_child(_warning("Votre équipe est vide. Composez une équipe avant de combattre."))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var stages := DataRegistry.get_stages_sorted()
	for i in stages.size():
		var st: StageDefinition = stages[i]
		var unlocked := i == 0 or GameState.stages_cleared.has(stages[i - 1].id)
		list.add_child(_stage_card(st, unlocked))

func _stage_card(st: StageDefinition, unlocked: bool) -> PanelContainer:
	var cleared := GameState.stages_cleared.has(st.id)
	var first_avail := not GameState.first_clear_claimed.has(st.id)
	var panel := Style.panel(Style.PANEL if unlocked else Style.PANEL.darkened(0.25))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 18)
	panel.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	m.add_child(h)

	# Bloc info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	var titlerow := HBoxContainer.new()
	titlerow.add_theme_constant_override("separation", 10)
	titlerow.add_child(Style.title("%s — %s" % [st.id, st.nom], 22, Style.TEXT if unlocked else Style.DIM))
	if st.has_boss:
		titlerow.add_child(_tag("BOSS", Style.DANGER))
	if cleared:
		titlerow.add_child(_tag("Terminé", Style.OK))
	info.add_child(titlerow)
	info.add_child(Style.label(st.description, 14, Style.DIM))

	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 16)
	rewards.add_child(_reward_chip("gold", st.reward_or))
	rewards.add_child(_reward_chip("crystal", st.reward_cristaux))
	rewards.add_child(Style.label("Ennemis : %d" % st.enemy_ids.size(), 13, Style.DIM))
	info.add_child(rewards)
	if first_avail:
		info.add_child(Style.label("★ 1re victoire : +%d or, +%d cristaux, +%d XP"
			% [st.first_or, st.first_cristaux, st.first_xp], 13, Style.ACCENT))
	h.add_child(info)

	# Bouton
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	if unlocked:
		var fight := Style.button("Combattre", Vector2(150, 56))
		fight.disabled = not GameState.team_is_valid()
		fight.pressed.connect(func():
			AudioManager.play_sfx("click")
			SceneRouter.goto_battle(st.id))
		right.add_child(fight)
	else:
		right.add_child(Style.label("Verrouillé", 16, Style.DIM))
		right.add_child(Style.label("Terminez le stage précédent", 12, Style.DIM))
	h.add_child(right)
	return panel

func _reward_chip(kind: String, value: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	var icon := MiniIcon.new()
	icon.setup(kind)
	box.add_child(icon)
	box.add_child(Style.label("+%d" % value, 14, Style.TEXT))
	return box

func _tag(text: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Style._sb(col.darkened(0.2), 6))
	var l := Style.label(text, 12, Color.WHITE)
	p.add_child(l)
	return p

func _warning(text: String) -> PanelContainer:
	var p := Style.panel(Style.DANGER.darkened(0.4))
	p.add_child(Style.label(text, 15, Color.WHITE))
	return p
