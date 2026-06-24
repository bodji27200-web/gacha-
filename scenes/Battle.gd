extends Control
## Combat 4v4 : interface, ciblage, animations, IA ennemie, victoire/défaite.

signal _picked(cid)

var engine: CombatEngine
var stage: StageDefinition
var nodes: Dictionary = {}        # cid -> CombatantNode

var order_box: HBoxContainer
var action_panel: PanelContainer
var skill_row: HBoxContainer
var info_label: Label
var cancel_btn: Button
var speed_btn: Button
var _rewards_granted := false
var _ended := false

func _ready() -> void:
	Style.apply(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Style.bg_rect())

	var sid: String = SceneRouter.pending_stage_id
	stage = DataRegistry.get_stage(sid) if sid != "" else DataRegistry.get_stage("1-1")

	engine = CombatEngine.new(DataRegistry, RNG)
	engine.setup(GameState.team_instances(), stage.enemy_ids)

	AudioManager.play_music("boss" if stage.has_boss else "battle")
	_build_ui()
	_update_order()

	if stage.id == "1-1" and not GameState.tutorial_done:
		var tut := TutorialOverlay.new()
		add_child(tut)
		await tut.closed
		GameState.tutorial_done = true
		SaveManager.autosave()

	_loop()

# =====================================================================
#  CONSTRUCTION DE L'INTERFACE
# =====================================================================
func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20; root.offset_top = 14; root.offset_right = -20; root.offset_bottom = -14
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# Barre supérieure
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var abandon := Style.button("Abandonner")
	abandon.pressed.connect(_confirm_abandon)
	top.add_child(abandon)
	top.add_child(Style.title("%s — %s" % [stage.id, stage.nom], 22))
	top.add_child(Style.spacer())
	speed_btn = Style.button("")
	_refresh_speed()
	speed_btn.pressed.connect(func():
		GameState.settings["combat_speed"] = 2 if int(GameState.settings.get("combat_speed", 1)) == 1 else 1
		_refresh_speed(); SaveManager.autosave())
	top.add_child(speed_btn)
	var settings := Style.button("Options")
	settings.pressed.connect(func(): add_child(SettingsPopup.new()))
	top.add_child(settings)
	root.add_child(top)

	# Ordre des tours
	var order_panel := Style.panel(Style.PANEL2)
	var op_m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		op_m.add_theme_constant_override("margin_" + s, 6)
	order_panel.add_child(op_m)
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 8)
	op_m.add_child(orow)
	orow.add_child(Style.label("Prochains tours :", 13, Style.DIM))
	order_box = HBoxContainer.new()
	order_box.add_theme_constant_override("separation", 6)
	orow.add_child(order_box)
	root.add_child(order_panel)

	# Zone de combat
	var field := HBoxContainer.new()
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 20)
	root.add_child(field)

	var ally_grid := _make_formation()
	field.add_child(_align_bottom(ally_grid))
	for c in engine.allies:
		ally_grid.add_child(_make_node(c))
	field.add_child(Style.spacer())
	var enemy_grid := _make_formation()
	field.add_child(_align_bottom(enemy_grid))
	for c in engine.enemies:
		enemy_grid.add_child(_make_node(c))

	# Bas : log + panneau d'action
	info_label = Style.label("", 15, Style.TEXT)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info_label)

	cancel_btn = Style.button("Annuler la sélection")
	cancel_btn.visible = false
	cancel_btn.pressed.connect(func(): _picked.emit(-1))
	var cancel_center := CenterContainer.new()
	cancel_center.add_child(cancel_btn)
	root.add_child(cancel_center)

	action_panel = Style.panel(Style.PANEL)
	action_panel.visible = false
	var ap_m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		ap_m.add_theme_constant_override("margin_" + s, 12)
	action_panel.add_child(ap_m)
	skill_row = HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 12)
	skill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ap_m.add_child(skill_row)
	root.add_child(action_panel)

func _make_formation() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 6)
	return g

func _align_bottom(child: Control) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(Style.spacer())
	child.size_flags_vertical = Control.SIZE_SHRINK_END
	v.add_child(child)
	return v

func _make_node(c: Combatant) -> CombatantNode:
	var n := CombatantNode.new()
	n.setup(c)
	n.selected.connect(func(cid): _picked.emit(cid))
	nodes[c.cid] = n
	return n

# =====================================================================
#  BOUCLE DE COMBAT
# =====================================================================
func _loop() -> void:
	if _ended:
		return
	if engine.finished:
		_end()
		return
	_update_order()
	var actor: Combatant = engine.next_actor()
	await _animate(engine.drain())
	if engine.finished or actor == null:
		_end()
		return
	_refresh_all()
	_set_active(actor)
	if actor.is_enemy:
		await _delay(0.45)
		var d := EnemyAI.choose(engine, actor)
		if d.is_empty():
			engine.ai_execute(actor)
		else:
			_animate_caster(actor, d.skill, d.target)
			info_label.text = "%s utilise %s" % [actor.display_name, d.skill.nom]
			await _delay(0.2)
			engine.execute(actor, d.skill, d.target)
		await _animate(engine.drain())
		_clear_active()
		_loop()
	else:
		_begin_player_turn(actor)

func _begin_player_turn(actor: Combatant) -> void:
	info_label.text = "Au tour de %s" % actor.display_name
	_show_actions(actor)

func _show_actions(actor: Combatant) -> void:
	for c in skill_row.get_children():
		c.queue_free()
	for skill in actor.skills:
		skill_row.add_child(_skill_button(actor, skill))
	action_panel.visible = true

func _skill_button(actor: Combatant, skill: SkillDefinition) -> Button:
	var cd: int = int(actor.cooldowns.get(skill.id, 0))
	var b := Button.new()
	b.custom_minimum_size = Vector2(210, 76)
	b.focus_mode = Control.FOCUS_ALL
	b.disabled = cd > 0
	b.tooltip_text = skill.description
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := Style.label(skill.nom, 17, Style.TEXT if cd <= 0 else Style.DIM)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := "Recharge : %d tour(s)" % cd if cd > 0 else skill.description
	var sl := Style.label(sub, 11, Style.DIM)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.clip_text = true
	v.add_child(sl)
	b.add_child(v)
	b.mouse_entered.connect(func(): info_label.text = "%s — %s" % [skill.nom, skill.description])
	b.pressed.connect(func(): _try_skill(actor, skill))
	return b

func _try_skill(actor: Combatant, skill: SkillDefinition) -> void:
	AudioManager.play_sfx("click")
	if engine.needs_target(skill):
		var valid := engine.valid_targets(actor, skill)
		if valid.is_empty():
			return
		for n in nodes.values():
			n.set_targetable(valid.has(n.combatant))
		cancel_btn.visible = true
		info_label.text = "Choisissez une cible pour %s" % skill.nom
		var cid: int = await _picked
		for n in nodes.values():
			n.set_targetable(false)
		cancel_btn.visible = false
		if cid < 0:
			info_label.text = "Au tour de %s" % actor.display_name
			return
		await _perform(actor, skill, engine.by_cid(cid))
	else:
		await _perform(actor, skill, null)

func _perform(actor: Combatant, skill: SkillDefinition, target: Combatant) -> void:
	action_panel.visible = false
	_clear_active()
	_animate_caster(actor, skill, target)
	info_label.text = "%s utilise %s" % [actor.display_name, skill.nom]
	await _delay(0.18)
	engine.execute(actor, skill, target)
	await _animate(engine.drain())
	_loop()

func _animate_caster(actor: Combatant, skill: SkillDefinition, _target: Combatant) -> void:
	var n: CombatantNode = nodes.get(actor.cid)
	if n == null:
		return
	if skill.deals_damage() and skill.is_offensive():
		n.play_lunge()
		AudioManager.play_sfx("attack")
	else:
		n.play_cast()
		AudioManager.play_sfx("buff" if not skill.is_offensive() else "attack")

# =====================================================================
#  ANIMATION DES ÉVÉNEMENTS
# =====================================================================
func _animate(events: Array) -> void:
	for ev in events:
		match ev.get("t", ""):
			"damage":
				var n: CombatantNode = nodes.get(ev.target)
				if n:
					n.play_hit()
					var col := Color.WHITE
					var prefix := ""
					if ev.get("elem") == "adv":
						col = Style.OK; prefix = "▲"
					elif ev.get("elem") == "dis":
						col = Style.DANGER.lightened(0.2); prefix = "▼"
					var txt := "%s-%d" % [prefix, ev.amount]
					if ev.get("crit", false):
						txt += " CRIT"
					_float(ev.target, txt, Style.DANGER if not ev.get("crit") else Style.ACCENT, ev.get("crit", false))
					AudioManager.play_sfx("crit" if ev.get("crit", false) else "hit")
				_refresh_node(ev.target)
				await _delay(0.26)
			"dot":
				var col := Color("ff8a4a")
				_float(ev.target, "-%d" % ev.amount, col)
				_refresh_node(ev.target)
				await _delay(0.18)
			"heal", "regen_tick":
				_float(ev.target, "+%d" % ev.amount, Style.OK)
				AudioManager.play_sfx("heal")
				_refresh_node(ev.target)
				await _delay(0.18)
			"status":
				var col2 := Style.OK if ev.get("buff", false) else Style.ACCENT2.lightened(0.2)
				_float(ev.target, str(ev.name), col2)
				AudioManager.play_sfx("buff" if ev.get("buff", false) else "debuff")
				_refresh_node(ev.target)
				await _delay(0.14)
			"resist":
				_float(ev.target, "Résisté", Style.DIM)
				await _delay(0.12)
			"shield_gain":
				_float(ev.target, "Bouclier", Style.CRYSTAL)
				_refresh_node(ev.target)
				await _delay(0.1)
			"cleanse":
				_float(ev.target, "Purifié", Style.CRYSTAL)
				_refresh_node(ev.target)
				await _delay(0.12)
			"gauge":
				_refresh_node(ev.target)
			"enrage":
				var n2: CombatantNode = nodes.get(ev.unit)
				if n2:
					n2.play_hit()
				_float(ev.unit, "ENRAGÉ !", Style.DANGER, true)
				AudioManager.play_sfx("crit")
				await _delay(0.5)
			"death":
				var n3: CombatantNode = nodes.get(ev.unit)
				if n3:
					n3.play_death()
				AudioManager.play_sfx("death")
				await _delay(0.3)
			"victory", "defeat", "timeout":
				pass
	_refresh_all()

# =====================================================================
#  AFFICHAGE
# =====================================================================
func _refresh_all() -> void:
	for n in nodes.values():
		n.update_view()

func _refresh_node(cid) -> void:
	var n: CombatantNode = nodes.get(cid)
	if n:
		n.update_view()

func _set_active(actor: Combatant) -> void:
	_clear_active()
	var n: CombatantNode = nodes.get(actor.cid)
	if n:
		n.set_active(true)

func _clear_active() -> void:
	for n in nodes.values():
		n.set_active(false)

func _update_order() -> void:
	for c in order_box.get_children():
		c.queue_free()
	for cid in engine.forecast(7):
		var c: Combatant = engine.by_cid(cid)
		if c == null:
			continue
		var chip := PanelContainer.new()
		var side_col := Style.OK if not c.is_enemy else Style.DANGER
		chip.add_theme_stylebox_override("panel", Style._sb(side_col.darkened(0.45), 6, GameEnums.element_color(c.element), 2))
		var l := Style.label(c.display_name.left(8), 12, Color.WHITE)
		chip.add_child(l)
		order_box.add_child(chip)

func _float(cid, text: String, color: Color, big: bool = false) -> void:
	var n: CombatantNode = nodes.get(cid)
	if n == null:
		return
	var lbl := Style.label(text, 26 if big else 19, color)
	lbl.z_index = 100
	add_child(lbl)
	lbl.global_position = n.global_center() - Vector2(20, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 50, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lbl.queue_free)

func _refresh_speed() -> void:
	speed_btn.text = "Vitesse ×%d" % int(GameState.settings.get("combat_speed", 1))

func _delay(base: float) -> void:
	var scale := 0.5 if int(GameState.settings.get("combat_speed", 1)) == 2 else 1.0
	await get_tree().create_timer(base * scale).timeout

# =====================================================================
#  FIN DE COMBAT
# =====================================================================
func _end() -> void:
	if _ended:
		return
	_ended = true
	action_panel.visible = false
	_clear_active()
	var victory := engine.result == "victory"
	var summary := {}
	if victory and not _rewards_granted:
		_rewards_granted = true
		summary = GameState.grant_stage_rewards(stage, GameState.team)
		SaveManager.autosave()
	AudioManager.play_sfx("victory" if victory else "defeat")
	add_child(_result_overlay(victory, summary))

func _result_overlay(victory: bool, summary: Dictionary) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 40
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	v.add_child(Style.title("Victoire !" if victory else "Défaite", 36, Style.OK if victory else Style.DANGER))

	if victory:
		if summary.get("first", false):
			v.add_child(Style.label("★ Première victoire — récompenses bonus !", 15, Style.ACCENT))
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 16)
		rr.add_child(_reward(("gold"), int(summary.get("or", 0))))
		rr.add_child(_reward("crystal", int(summary.get("cristaux", 0))))
		v.add_child(rr)
		v.add_child(Style.label("+%d XP par héros" % int(summary.get("xp", 0)), 14, Style.DIM))
		for lu in summary.get("level_ups", []):
			v.add_child(Style.label("%s atteint le niveau %d !" % [lu.get("name", ""), lu.get("to", 0)], 14, Style.OK))
	else:
		v.add_child(Style.label("Améliorez vos héros ou modifiez votre équipe, puis réessayez.", 14, Style.DIM))

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	var retry := Style.button("Rejouer")
	retry.pressed.connect(func(): SceneRouter.goto_battle(stage.id))
	btns.add_child(retry)
	var to_stages := Style.button("Stages")
	to_stages.pressed.connect(func(): SceneRouter.goto(SceneRouter.STAGES))
	btns.add_child(to_stages)
	var to_menu := Style.button("Menu")
	to_menu.pressed.connect(func(): SceneRouter.goto(SceneRouter.MENU))
	btns.add_child(to_menu)
	v.add_child(btns)
	return layer

func _reward(kind: String, value: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var ic := MiniIcon.new()
	ic.setup(kind)
	h.add_child(ic)
	h.add_child(Style.label("+%d" % value, 18, Style.TEXT))
	return h

func _confirm_abandon() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 22)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	v.add_child(Style.title("Abandonner le combat ?", 24))
	v.add_child(Style.label("Aucune récompense ne sera gagnée.", 14, Style.DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var yes := Style.button("Abandonner")
	yes.add_theme_color_override("font_color", Style.DANGER)
	yes.pressed.connect(func(): SceneRouter.goto(SceneRouter.STAGES))
	row.add_child(yes)
	var no := Style.button("Continuer")
	no.pressed.connect(layer.queue_free)
	row.add_child(no)
	v.add_child(row)
	center.add_child(panel)
	add_child(layer)
