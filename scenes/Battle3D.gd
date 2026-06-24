extends Node3D
## Combat 3D (refonte LOT 1) : arène en perspective, créatures originales,
## UI par unité, compétences en icônes, mode AUTO, vitesse. Réutilise CombatEngine.

signal _picked(cid)

var engine: CombatEngine
var cam: Camera3D
var creatures: Dictionary = {}     # cid -> Creature3D
var plates: Dictionary = {}        # cid -> UnitPlate
var overlay: CanvasLayer
var skill_row: HBoxContainer
var info: Label
var auto_btn: Button
var speed_btn: Button
var cancel_btn: Button
var _auto := false
var _priority_cid := -1
var _ended := false
var _rewards_granted := false

func _ready() -> void:
	DataRegistry.load_all()
	if GameState.heroes.is_empty():
		if not SaveManager.load_game():
			GameState.new_game()

	var team_insts: Array
	var enemy_ids: Array
	if SceneRouter.pending_stage_id != "":
		var st: StageDefinition = DataRegistry.get_stage(SceneRouter.pending_stage_id)
		enemy_ids = st.enemy_ids
		team_insts = GameState.team_instances()
	else:
		# Vitrine LOT 1 : 2 contre 2
		team_insts = [_mkinst("p1", "kaelen", 6), _mkinst("p2", "brask", 6)]
		enemy_ids = ["ember_grunt", "cinder_servant"]

	engine = CombatEngine.new(DataRegistry, RNG)
	engine.setup(team_insts, enemy_ids)

	Arena3D.build(self)
	_setup_camera()
	_spawn_creatures()
	_build_overlay()
	AudioManager.play_music("battle")
	_loop()

func _mkinst(uid: String, def_id: String, lvl: int) -> HeroInstance:
	var h := HeroInstance.create(uid, def_id, 0)
	h.niveau = lvl
	return h

# ------------------------------------------------------------------ 3D
func _setup_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 46.0
	cam.position = Vector3(1.7, 5.1, -7.8)
	cam.look_at_from_position(cam.position, Vector3(0.0, 0.6, 0.9), Vector3.UP)
	add_child(cam)

func _anchor(i: int, n: int, ally: bool) -> Vector3:
	var x := (i - (n - 1) * 0.5) * 1.8
	var z := (-1.9 if ally else 2.4) + (-0.4 if i % 2 == 1 else 0.0) * (1 if ally else -1)
	return Vector3(x, 0, z)

func _spawn_creatures() -> void:
	var na := engine.allies.size()
	var ne := engine.enemies.size()
	for i in na:
		_spawn(engine.allies[i], _anchor(i, na, true), true)
	for i in ne:
		_spawn(engine.enemies[i], _anchor(i, ne, false), false)

func _spawn(c: Combatant, pos: Vector3, ally: bool) -> void:
	var kit := CreatureKit3D.for_def(c.def_id, c.element)
	var cr := Creature3D.new()
	cr.position = pos
	add_child(cr)
	cr.build(kit)
	cr.scale = Vector3.ONE * (1.45 if c.is_boss else 1.12)
	cr.face_toward(Vector3(0, 0, -pos.z))
	creatures[c.cid] = cr

# ------------------------------------------------------------------ overlay 2D
func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	add_child(overlay)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Style.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root)

	# plaques par unité
	for cid in creatures:
		var c: Combatant = engine.by_cid(cid)
		var plate := UnitPlate.new()
		plate.setup(c)
		plate.selected.connect(func(scid): _on_plate_clicked(scid))
		root.add_child(plate)
		plates[cid] = plate

	# barre supérieure : titre + AUTO + vitesse
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.position = Vector2(16, 12)
	root.add_child(top)
	var back := Style.button("<  Quitter")
	back.pressed.connect(func(): SceneRouter.goto(SceneRouter.MENU))
	top.add_child(back)

	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 8)
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-360, 12)
	root.add_child(tr)
	auto_btn = Style.button("AUTO : OFF")
	auto_btn.pressed.connect(_toggle_auto)
	tr.add_child(auto_btn)
	speed_btn = Style.button("")
	_refresh_speed()
	speed_btn.pressed.connect(func():
		GameState.settings["combat_speed"] = 2 if int(GameState.settings.get("combat_speed", 1)) == 1 else 1
		_refresh_speed())
	tr.add_child(speed_btn)

	# info + annulation (centre bas)
	info = Style.label("", 16, Style.TEXT)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -150
	info.offset_bottom = -124
	root.add_child(info)

	cancel_btn = Style.button("Annuler")
	cancel_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cancel_btn.position = Vector2(-50, -110)
	cancel_btn.visible = false
	cancel_btn.pressed.connect(func(): _picked.emit(-1))
	root.add_child(cancel_btn)

	# compétences en bas à droite
	skill_row = HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 10)
	skill_row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_row.position = Vector2(-360, -110)
	root.add_child(skill_row)

func _process(_delta: float) -> void:
	# accroche les plaques au-dessus des créatures (projection 3D -> 2D)
	if cam == null:
		return
	for cid in plates:
		var cr: Creature3D = creatures.get(cid)
		var plate: UnitPlate = plates[cid]
		if cr == null or not is_instance_valid(cr):
			continue
		var head: Vector3 = cr.head_world() + Vector3(0, 0.35, 0)
		if cam.is_position_behind(head):
			plate.visible = false
			continue
		plate.visible = true
		var sp := cam.unproject_position(head)
		plate.position = sp - Vector2(plate.size.x * 0.5, plate.size.y)
		plate.refresh()

# ------------------------------------------------------------------ boucle
func _loop() -> void:
	if _ended:
		return
	if engine.finished:
		_end()
		return
	var actor: Combatant = engine.next_actor()
	await _animate(engine.drain())
	if engine.finished or actor == null:
		_end()
		return
	_set_active(actor)
	if actor.is_enemy or _auto:
		await _delay(0.4)
		var d := _decide(actor)
		if d.is_empty():
			engine.ai_execute(actor)
		else:
			_animate_caster(actor, d.skill, d.target)
			info.text = "%s utilise %s" % [_name(actor), d.skill.nom]
			await _delay(0.25)
			engine.execute(actor, d.skill, d.target)
		await _animate(engine.drain())
		_clear_active()
		_loop()
	else:
		_begin_player_turn(actor)

func _decide(actor: Combatant) -> Dictionary:
	var d := EnemyAI.choose(engine, actor)
	# cible prioritaire en AUTO
	if _auto and not actor.is_enemy and _priority_cid >= 0 and not d.is_empty() and d.skill.is_offensive():
		var pr: Combatant = engine.by_cid(_priority_cid)
		if pr != null and pr.is_alive() and pr.is_enemy:
			d["target"] = pr
	return d

func _begin_player_turn(actor: Combatant) -> void:
	info.text = "Au tour de %s" % _name(actor)
	for c in skill_row.get_children():
		c.queue_free()
	for skill in actor.skills:
		skill_row.add_child(_skill_button(actor, skill))

func _skill_button(actor: Combatant, skill: SkillDefinition) -> Control:
	var cd: int = int(actor.cooldowns.get(skill.id, 0))
	var b := SkillButton.new()
	b.setup(skill, actor.element, cd)
	b.pressed.connect(func(): _try_skill(actor, skill))
	return b

func _try_skill(actor: Combatant, skill: SkillDefinition) -> void:
	if int(actor.cooldowns.get(skill.id, 0)) > 0:
		return
	AudioManager.play_sfx("click")
	if engine.needs_target(skill):
		var valid := engine.valid_targets(actor, skill)
		if valid.is_empty():
			return
		for cid in plates:
			plates[cid].set_targetable(valid.has(engine.by_cid(cid)))
		cancel_btn.visible = true
		info.text = "Choisissez une cible"
		var cid_pick: int = await _picked
		for cid in plates:
			plates[cid].set_targetable(false)
		cancel_btn.visible = false
		if cid_pick < 0:
			info.text = "Au tour de %s" % _name(actor)
			return
		await _perform(actor, skill, engine.by_cid(cid_pick))
	else:
		await _perform(actor, skill, null)

func _on_plate_clicked(cid: int) -> void:
	# en sélection de cible
	if cancel_btn.visible and plates[cid]._targetable:
		_picked.emit(cid)
		return
	# sinon : définit la cible prioritaire (utile en AUTO)
	var c: Combatant = engine.by_cid(cid)
	if c != null and c.is_enemy and c.is_alive():
		_priority_cid = cid
		for k in plates:
			plates[k].set_priority(k == cid)

func _perform(actor: Combatant, skill: SkillDefinition, target: Combatant) -> void:
	for c in skill_row.get_children():
		c.queue_free()
	_clear_active()
	_animate_caster(actor, skill, target)
	info.text = "%s utilise %s" % [_name(actor), skill.nom]
	await _delay(0.2)
	engine.execute(actor, skill, target)
	await _animate(engine.drain())
	_loop()

func _animate_caster(actor: Combatant, skill: SkillDefinition, target: Combatant) -> void:
	var cr: Creature3D = creatures.get(actor.cid)
	if cr == null:
		return
	if skill.deals_damage() and skill.is_offensive() and target != null:
		var tc: Creature3D = creatures.get(target.cid)
		if tc:
			cr.lunge_to(tc.position)
		AudioManager.play_sfx("attack")
	else:
		cr.play_cast()
		AudioManager.play_sfx("buff" if not skill.is_offensive() else "attack")

# ------------------------------------------------------------------ animation des événements
func _animate(events: Array) -> void:
	for ev in events:
		match ev.get("t", ""):
			"damage":
				var cr: Creature3D = creatures.get(ev.target)
				if cr: cr.play_hit()
				var col := Color.WHITE
				if ev.get("elem") == "adv": col = Style.OK
				elif ev.get("elem") == "dis": col = Style.DANGER.lightened(0.2)
				_float(ev.target, ("%d" % ev.amount) + (" CRIT" if ev.get("crit") else ""),
					Style.ACCENT if ev.get("crit") else col)
				AudioManager.play_sfx("crit" if ev.get("crit") else "hit")
				await _delay(0.26)
			"dot":
				_float(ev.target, "-%d" % ev.amount, Color("ff8a4a"))
				await _delay(0.16)
			"heal", "regen_tick":
				_float(ev.target, "+%d" % ev.amount, Style.OK)
				AudioManager.play_sfx("heal")
				await _delay(0.16)
			"status":
				_float(ev.target, str(ev.name), Style.OK if ev.get("buff") else Style.ACCENT2.lightened(0.2))
				AudioManager.play_sfx("buff" if ev.get("buff") else "debuff")
				await _delay(0.12)
			"resist":
				_float(ev.target, "Résisté", Style.DIM)
				await _delay(0.1)
			"enrage":
				_float(ev.unit, "ENRAGÉ !", Style.DANGER)
				await _delay(0.4)
			"death":
				var cr2: Creature3D = creatures.get(ev.unit)
				if cr2: cr2.play_death()
				AudioManager.play_sfx("death")
				await _delay(0.35)
			_:
				pass

func _float(cid: int, text: String, color: Color) -> void:
	var cr: Creature3D = creatures.get(cid)
	if cr == null:
		return
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 96
	lbl.pixel_size = 0.006
	lbl.modulate = color
	lbl.outline_size = 16
	lbl.outline_modulate = Color(0, 0, 0, 0.8)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.position = cr.head_world() + Vector3(0, 0.4, 0)
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y + 1.1, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(lbl.queue_free)

# ------------------------------------------------------------------ états / fin
func _set_active(actor: Combatant) -> void:
	_clear_active()
	if creatures.has(actor.cid):
		creatures[actor.cid].set_turn(true)
	if plates.has(actor.cid):
		plates[actor.cid].set_active(true)

func _clear_active() -> void:
	for cid in creatures:
		creatures[cid].set_turn(false)
	for cid in plates:
		plates[cid].set_active(false)

func _toggle_auto() -> void:
	_auto = not _auto
	auto_btn.text = "AUTO : ON" if _auto else "AUTO : OFF"
	AudioManager.play_sfx("click")

func _refresh_speed() -> void:
	speed_btn.text = "Vitesse ×%d" % int(GameState.settings.get("combat_speed", 1))

func _delay(base: float) -> void:
	var scale := 0.5 if int(GameState.settings.get("combat_speed", 1)) == 2 else 1.0
	await get_tree().create_timer(base * scale).timeout

func _name(c: Combatant) -> String:
	return CreatureKit3D.display_name(c.def_id, c.display_name)

func _end() -> void:
	if _ended:
		return
	_ended = true
	for c in skill_row.get_children():
		c.queue_free()
	var victory := engine.result == "victory"
	var summary := {}
	if victory and SceneRouter.pending_stage_id != "" and not _rewards_granted:
		_rewards_granted = true
		var st: StageDefinition = DataRegistry.get_stage(SceneRouter.pending_stage_id)
		summary = GameState.grant_stage_rewards(st, GameState.team)
		SaveManager.autosave()
	AudioManager.play_sfx("victory" if victory else "defeat")
	info.text = ""
	overlay.add_child(_result_panel(victory, summary))

func _result_panel(victory: bool, summary: Dictionary) -> Control:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 26)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)
	v.add_child(Style.title("Victoire !" if victory else "Défaite", 36, Style.OK if victory else Style.DANGER))
	if victory and not summary.is_empty():
		if summary.get("first", false):
			v.add_child(Style.label("★ Première victoire — bonus !", 15, Style.ACCENT))
		v.add_child(Style.label("+%d or   +%d cristaux   +%d XP" % [
			int(summary.get("or", 0)), int(summary.get("cristaux", 0)), int(summary.get("xp", 0))], 16, Style.TEXT))
		for lu in summary.get("level_ups", []):
			v.add_child(Style.label("%s atteint le niveau %d !" % [lu.get("name", ""), lu.get("to", 0)], 14, Style.OK))
	else:
		v.add_child(Style.label("Refonte 3D — Cendres & Cristaux", 14, Style.DIM))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	var stage_id := SceneRouter.pending_stage_id
	var b := Style.button("Rejouer")
	b.pressed.connect(func():
		if stage_id != "": SceneRouter.goto_battle(stage_id)
		else: SceneRouter.goto(SceneRouter.BATTLE3D))
	btns.add_child(b)
	if stage_id != "":
		var st := Style.button("Stages")
		st.pressed.connect(func(): SceneRouter.goto(SceneRouter.STAGES))
		btns.add_child(st)
	var mn := Style.button("Menu")
	mn.pressed.connect(func(): SceneRouter.goto(SceneRouter.MENU))
	btns.add_child(mn)
	v.add_child(btns)
	center.add_child(panel)
	return center

# ==================================================================
#  Plaque d'unité (nom, étoiles, élément, PV, jauge d'action, statuts)
# ==================================================================
class UnitPlate extends Control:
	signal selected(cid)
	var c: Combatant
	var _btn: Button
	var _status_box: HBoxContainer
	var _targetable := false
	var _active := false
	var _priority := false
	var _pulse := 0.0

	func setup(p_c: Combatant) -> void:
		c = p_c
		custom_minimum_size = Vector2(150, 64)
		size = Vector2(150, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.add_theme_constant_override("separation", 1)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)
		var top := Label.new()
		top.text = CreatureKit3D.display_name(c.def_id, c.display_name)
		top.add_theme_font_size_override("font_size", 12)
		top.add_theme_color_override("font_color", Color.WHITE)
		top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(top)
		_status_box = HBoxContainer.new()
		_status_box.alignment = BoxContainer.ALIGNMENT_CENTER
		_status_box.add_theme_constant_override("separation", 1)
		_status_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(_status_box)
		_btn = Button.new()
		_btn.flat = true
		_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn.add_theme_stylebox_override("normal", _empty_sb())
		_btn.add_theme_stylebox_override("hover", _empty_sb())
		_btn.add_theme_stylebox_override("pressed", _empty_sb())
		_btn.pressed.connect(func(): selected.emit(c.cid))
		add_child(_btn)
		set_process(true)

	func _empty_sb() -> StyleBoxEmpty:
		return StyleBoxEmpty.new()

	func set_targetable(on: bool) -> void:
		_targetable = on
		_btn.mouse_filter = Control.MOUSE_FILTER_STOP if (on or true) else Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func set_active(on: bool) -> void:
		_active = on
		queue_redraw()

	func set_priority(on: bool) -> void:
		_priority = on
		queue_redraw()

	func refresh() -> void:
		for ch in _status_box.get_children():
			ch.queue_free()
		for s in c.statuses:
			var ico := StatusIconView.new()
			ico.custom_minimum_size = Vector2(14, 14)
			_status_box.add_child(ico)
			ico.setup(s)
		queue_redraw()

	func _process(delta: float) -> void:
		if _active or _targetable or _priority:
			_pulse = fmod(_pulse + delta * 4.0, TAU)
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var by := 34.0
		# barre PV
		draw_rect(Rect2(0, by, w, 11), Color(0, 0, 0, 0.65))
		var r := c.hp_ratio()
		var hp_col := Style.OK
		if r < 0.3: hp_col = Style.DANGER
		elif r < 0.6: hp_col = Style.ACCENT
		draw_rect(Rect2(0, by, w * r, 11), hp_col)
		var sh := c.total_shield()
		if sh > 0.0:
			draw_rect(Rect2(0, by - 4, w * clampf(sh / c.max_hp, 0, 1), 4), Style.CRYSTAL)
		draw_rect(Rect2(0, by, w, 11), Color(1, 1, 1, 0.18), false, 1.0)
		# jauge d'action
		draw_rect(Rect2(0, by + 13, w, 5), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(0, by + 13, w * (c.gauge / 100.0), 5), Style.ACCENT2.lightened(0.2))
		# élément (pastille)
		VisualKit.draw_element_icon(self, Rect2(w - 18, 0, 16, 16), c.element)
		# surbrillances
		if _active:
			var a := 0.5 + 0.4 * sin(_pulse)
			draw_rect(Rect2(-2, 30, w + 4, 24), Color(Style.ACCENT.r, Style.ACCENT.g, Style.ACCENT.b, a), false, 2.0)
		if _targetable:
			var col := Style.DANGER if c.is_enemy else Style.OK
			var a2 := 0.55 + 0.4 * sin(_pulse)
			draw_rect(Rect2(-2, 30, w + 4, 24), Color(col.r, col.g, col.b, a2), false, 2.0)
		if _priority:
			draw_rect(Rect2(-3, 29, w + 6, 26), Style.ACCENT, false, 2.0)

# ==================================================================
#  Bouton de compétence (icône + cadre élément + recharge)
# ==================================================================
class SkillButton extends Button:
	var skill: SkillDefinition
	var element := 0
	var cd := 0

	func setup(p_skill: SkillDefinition, p_elem: int, p_cd: int) -> void:
		skill = p_skill
		element = p_skill.element if p_skill.element >= 0 else p_elem
		cd = p_cd
		custom_minimum_size = Vector2(78, 78)
		focus_mode = Control.FOCUS_ALL
		disabled = cd > 0
		var col := GameEnums.element_color(element)
		add_theme_stylebox_override("normal", Style._sb(col.darkened(0.45), 12, col, 2))
		add_theme_stylebox_override("hover", Style._sb(col.darkened(0.3), 12, col.lightened(0.2), 3))
		add_theme_stylebox_override("pressed", Style._sb(col.darkened(0.2), 12))
		add_theme_stylebox_override("disabled", Style._sb(Style.PANEL.darkened(0.2), 12))
		tooltip_text = "%s\n%s\n%s" % [skill.nom, _target_label(), skill.description]
		queue_redraw()

	func _target_label() -> String:
		if skill.cooldown > 0:
			return "Recharge : %d tour(s)" % skill.cooldown
		return "Sans recharge"

	func _draw() -> void:
		var icon_rect := Rect2(size.x * 0.5 - 18, 10, 36, 36)
		VisualKit.draw_element_icon(self, icon_rect, element)
		var f := ThemeDB.fallback_font
		var label := skill.nom.left(8)
		draw_string(f, Vector2(4, size.y - 8), label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 11,
			Color.WHITE if not disabled else Style.DIM)
		if cd > 0:
			draw_string(f, Vector2(0, size.y * 0.5 + 8), str(cd), HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Style.ACCENT)
