class_name CombatEngine
extends RefCounted
## Moteur de combat 4 contre 4 au tour par tour avec jauge d'action.
##
## Règle de jauge documentée : chaque unité remplit une jauge 0→100 à une vitesse
## proportionnelle à sa statistique de Vitesse. L'unité qui atteint 100 agit ; après
## son action, sa jauge est réduite de 100 (le surplus éventuel est conservé).
##
## La logique produit un journal d'événements (drain()) que l'UI rejoue en animation.
## Aucune dépendance à la scène : entièrement exécutable en headless.

const T := GameEnums.Target

var registry
var rng

var allies: Array = []      # Array[Combatant]
var enemies: Array = []
var all: Array = []

var finished := false
var result := ""            # "victory" / "defeat"
var turn_count := 0
var max_turns := 800        # garde-fou anti-boucle infinie

var _events: Array = []

func _init(p_registry, p_rng) -> void:
	registry = p_registry
	rng = p_rng

# =====================================================================
#  MISE EN PLACE
# =====================================================================
func setup(team_instances: Array, enemy_ids: Array) -> void:
	allies.clear()
	enemies.clear()
	var cid := 0
	for inst in team_instances:
		var def: HeroDefinition = registry.get_hero(inst.def_id)
		if def == null:
			continue
		allies.append(_make_ally(inst, def, cid))
		cid += 1
	cid = 100
	for eid in enemy_ids:
		var edef: EnemyDefinition = registry.get_enemy(eid)
		if edef == null:
			continue
		enemies.append(_make_enemy(edef, cid))
		cid += 1
	all = allies + enemies

func _make_ally(inst: HeroInstance, def: HeroDefinition, cid: int) -> Combatant:
	var c := Combatant.new()
	c.cid = cid
	c.side = "ally"
	c.is_enemy = false
	c.slot = cid
	c.display_name = def.nom
	c.element = def.element
	c.role = def.role
	c.def_id = def.id
	c.hero_uid = inst.uid
	c.base_stats = def.stats_at_level(inst.niveau)
	c.max_hp = c.base_stats.pv
	c.hp = c.max_hp
	c.skills = registry.hero_skills(def)
	c.ai_profile = _role_to_profile(def.role)
	c.visual = {
		"primary": def.primary_color, "secondary": def.secondary_color,
		"body": def.body_type, "weapon": def.weapon, "element": def.element,
		"role": def.role, "level": inst.niveau, "rarity": def.rarete,
	}
	return c

func _make_enemy(edef: EnemyDefinition, cid: int) -> Combatant:
	var c := Combatant.new()
	c.cid = cid
	c.side = "enemy"
	c.is_enemy = true
	c.slot = cid - 100
	c.display_name = edef.nom
	c.element = edef.element
	c.role = edef.role
	c.def_id = edef.id
	c.base_stats = edef.stats.clone()
	c.max_hp = c.base_stats.pv
	c.hp = c.max_hp
	c.skills = _resolve_skills(edef.skill_ids)
	c.ai_profile = edef.ai_profile
	c.is_boss = edef.is_boss
	c.size_scale = edef.size_scale
	c.half_hp_enrage = edef.half_hp_enrage
	c.gauge_on_minion_death = edef.gauge_on_minion_death
	c.visual = {
		"primary": edef.primary_color, "secondary": edef.secondary_color,
		"body": edef.body_type, "weapon": edef.weapon, "element": edef.element,
		"role": edef.role, "boss": edef.is_boss, "size": edef.size_scale,
	}
	return c

func _resolve_skills(ids: Array) -> Array:
	var arr: Array = []
	for sid in ids:
		var s: SkillDefinition = registry.get_skill(sid)
		if s != null:
			arr.append(s)
	return arr

func _role_to_profile(role: int) -> String:
	match role:
		GameEnums.Role.DEFENSEUR: return "defenseur"
		GameEnums.Role.SOUTIEN: return "soutien"
		GameEnums.Role.SOIGNEUR: return "soigneur"
	return "attaquant"

# =====================================================================
#  LISTES UTILITAIRES
# =====================================================================
func living() -> Array:
	return all.filter(func(c): return c.is_alive())

func living_allies_of(c: Combatant) -> Array:
	var arr: Array = allies if c.side == "ally" else enemies
	return arr.filter(func(x): return x.is_alive())

func living_enemies_of(c: Combatant) -> Array:
	var arr: Array = enemies if c.side == "ally" else allies
	return arr.filter(func(x): return x.is_alive())

func _same_side(c: Combatant) -> Array:
	return allies if c.side == "ally" else enemies

func _lowest(arr: Array) -> Combatant:
	var best: Combatant = null
	for a in arr:
		if best == null or a.hp_ratio() < best.hp_ratio():
			best = a
	return best

func by_cid(cid: int) -> Combatant:
	for c in all:
		if c.cid == cid:
			return c
	return null

# =====================================================================
#  ORDRE DES TOURS (JAUGE D'ACTION)
# =====================================================================
## Avance jusqu'au prochain acteur capable d'agir. Retourne le Combatant, ou null
## si le combat est terminé. Les événements de début de tour (DoT, régén, étourdis-
## sement) sont placés dans le journal.
func next_actor() -> Combatant:
	while not finished:
		if turn_count > max_turns:
			_resolve_timeout()
			return null
		var actor := _advance_gauges()
		if actor == null:
			_resolve_timeout()
			return null
		turn_count += 1
		_process_turn_start(actor)
		if _check_end():
			return null
		if not actor.is_alive():
			_end_turn(actor, "")
			continue
		if actor.is_prevented():
			_emit({"t": "stunned", "unit": actor.cid})
			_end_turn(actor, "")
			continue
		return actor
	return null

func _advance_gauges() -> Combatant:
	var units := living()
	if units.is_empty():
		return null
	var best_t := INF
	for u in units:
		var t: float = (100.0 - u.gauge) / u.speed()
		best_t = minf(best_t, t)
	best_t = maxf(0.0, best_t)
	for u in units:
		u.gauge += u.speed() * best_t
	var actor: Combatant = null
	for u in units:
		if u.gauge >= 100.0 - 0.0001:
			if actor == null or u.gauge > actor.gauge \
					or (is_equal_approx(u.gauge, actor.gauge) and u.speed() > actor.speed()) \
					or (is_equal_approx(u.gauge, actor.gauge) and is_equal_approx(u.speed(), actor.speed()) and u.cid < actor.cid):
				actor = u
	return actor

func _process_turn_start(actor: Combatant) -> void:
	for s in actor.statuses.duplicate():
		if not actor.is_alive():
			break
		if s.def.category == "dot":
			var dmg := int(maxf(1.0, round(s.magnitude * s.stacks)))
			_deal_true_damage(actor, dmg, s.def.id)
		elif s.def.category == "regen":
			var heal := int(round(s.magnitude))
			_heal_unit(actor, actor, heal, true)

func _end_turn(actor: Combatant, used_skill_id: String) -> void:
	for sid in actor.cooldowns.keys():
		if sid == used_skill_id:
			continue
		actor.cooldowns[sid] = maxi(0, actor.cooldowns[sid] - 1)
	for s in actor.statuses.duplicate():
		if s.applied_turn == turn_count:
			continue
		s.remaining -= 1
		if s.remaining <= 0:
			actor.statuses.erase(s)
			_emit({"t": "status_expire", "unit": actor.cid, "status": s.def.id})
	actor.gauge = maxf(0.0, actor.gauge - 100.0)

# =====================================================================
#  ACTIONS DISPONIBLES / CIBLAGE
# =====================================================================
func available_skills(actor: Combatant) -> Array:
	return actor.skills.filter(func(s): return int(actor.cooldowns.get(s.id, 0)) <= 0)

func needs_target(skill: SkillDefinition) -> bool:
	return skill.target == T.ENEMY_ONE or skill.target == T.ALLY_ONE or skill.target == T.ALLY_OTHER

func valid_targets(actor: Combatant, skill: SkillDefinition) -> Array:
	match skill.target:
		T.ENEMY_ONE:
			var foes := living_enemies_of(actor)
			var tcid := actor.taunt_source_cid()
			if tcid >= 0:
				var forced := foes.filter(func(f): return f.cid == tcid)
				if not forced.is_empty():
					return forced
			return foes
		T.ALLY_ONE:
			return living_allies_of(actor)
		T.ALLY_OTHER:
			return living_allies_of(actor).filter(func(a): return a != actor)
	return []

# =====================================================================
#  EXÉCUTION D'UNE ACTION
# =====================================================================
func execute(actor: Combatant, skill: SkillDefinition, primary: Combatant) -> void:
	_emit({
		"t": "skill", "unit": actor.cid, "skill": skill.id, "name": skill.nom,
		"target": primary.cid if primary != null else -1, "target_type": skill.target,
	})
	if skill.deals_damage():
		for tg in _gather_main_targets(actor, skill, primary):
			if not tg.is_alive():
				continue
			var mult := _conditional_mult(skill, tg)
			for _h in skill.hits:
				if not tg.is_alive():
					break
				var r := DamageFormula.compute(actor, tg, skill, rng, mult)
				_apply_damage(actor, tg, r.amount, r.crit, r.elem)
	for e in skill.effects:
		_apply_effect(actor, skill, primary, e)
	if skill.cooldown > 0:
		actor.cooldowns[skill.id] = skill.cooldown
	_end_turn(actor, skill.id)
	_check_end()

## Fait jouer l'IA pour cet acteur (ennemis et tests).
func ai_execute(actor: Combatant) -> void:
	var d := EnemyAI.choose(self, actor)
	if d.is_empty():
		_end_turn(actor, "")
		return
	execute(actor, d.skill, d.target)

func _gather_main_targets(actor: Combatant, skill: SkillDefinition, primary: Combatant) -> Array:
	match skill.target:
		T.ENEMY_ONE:
			return [primary] if primary != null else living_enemies_of(actor)
		T.ENEMY_ALL:
			return living_enemies_of(actor)
		T.ALLY_ONE, T.ALLY_OTHER:
			return [primary] if primary != null else []
		T.ALLY_ALL:
			return living_allies_of(actor)
		T.ALLY_LOWEST:
			var l := _lowest(living_allies_of(actor))
			return [l] if l != null else []
		T.SELF:
			return [actor]
	return []

func _effect_targets(actor: Combatant, primary: Combatant, to: String) -> Array:
	match to:
		"target":
			return [primary] if primary != null else []
		"self", "caster":
			return [actor]
		"all_enemies":
			return living_enemies_of(actor)
		"all_allies":
			return living_allies_of(actor)
		"ally_lowest":
			var l := _lowest(living_allies_of(actor))
			return [l] if l != null else []
	return []

func _conditional_mult(skill: SkillDefinition, target: Combatant) -> float:
	var m := 1.0
	if skill.bonus_if_status != "" and target.has_status(skill.bonus_if_status):
		m *= skill.bonus_if_status_mult
	if skill.bonus_per_debuff > 0.0:
		m *= (1.0 + skill.bonus_per_debuff * target.debuff_count())
	if skill.execute_threshold > 0.0 and target.hp_ratio() < skill.execute_threshold:
		m *= skill.execute_mult
	return m

func _apply_effect(actor: Combatant, skill: SkillDefinition, primary: Combatant, e: Dictionary) -> void:
	var kind: String = e.get("kind", "")
	var to: String = e.get("to", "target")
	var targets := _effect_targets(actor, primary, to)
	match kind:
		"status":
			var sid: String = e.get("status", "")
			var chance: float = e.get("chance", 1.0)
			var dur: int = e.get("duration", 0)
			for tg in targets:
				if tg.is_alive():
					_apply_status(actor, tg, sid, chance, dur)
		"heal":
			var p: float = e.get("power", 0.0)
			var hf: float = e.get("hp_frac", 0.0)
			for tg in targets:
				if tg.is_alive():
					var amt := int(round(actor.eff_stat("attaque") * p + tg.max_hp * hf))
					_heal_unit(actor, tg, amt, false)
		"gauge":
			var amount: float = e.get("amount", 0.0)
			for tg in targets:
				if tg.is_alive():
					_apply_gauge(tg, amount * 100.0)
		"cleanse":
			var cnt: int = e.get("count", 1)
			for tg in targets:
				if tg.is_alive():
					_cleanse(tg, cnt)

# =====================================================================
#  APPLICATION DES EFFETS
# =====================================================================
func _apply_damage(source: Combatant, target: Combatant, amount: int, crit: bool, elem: String) -> void:
	var was_alive := target.is_alive()
	var absorbed := 0
	var shield := target.total_shield()
	if shield > 0.0:
		absorbed = int(minf(shield, float(amount)))
		_reduce_shield(target, float(absorbed))
	var to_hp := amount - absorbed
	target.hp = maxf(0.0, target.hp - to_hp)
	var killed := was_alive and not target.is_alive()
	_emit({
		"t": "damage", "source": source.cid, "target": target.cid, "amount": amount,
		"crit": crit, "elem": elem, "shield": absorbed, "killed": killed,
	})
	if killed:
		_on_death(target)
	elif target.is_boss:
		_check_enrage(target)

func _deal_true_damage(target: Combatant, amount: int, status_id: String) -> void:
	var was_alive := target.is_alive()
	target.hp = maxf(0.0, target.hp - amount)
	var killed := was_alive and not target.is_alive()
	_emit({"t": "dot", "target": target.cid, "status": status_id, "amount": amount, "killed": killed})
	if killed:
		_on_death(target)
	elif target.is_boss:
		_check_enrage(target)

func _reduce_shield(target: Combatant, amount: float) -> void:
	var remaining := amount
	for s in target.statuses.duplicate():
		if remaining <= 0.0:
			break
		if s.def.category == "shield":
			var take: float = minf(s.magnitude, remaining)
			s.magnitude -= take
			remaining -= take
			if s.magnitude <= 0.0:
				target.statuses.erase(s)

func _heal_unit(source: Combatant, target: Combatant, amount: int, is_regen: bool) -> void:
	if amount <= 0:
		return
	var before := target.hp
	target.hp = minf(target.max_hp, target.hp + amount)
	var healed := int(target.hp - before)
	if healed <= 0:
		return
	if is_regen:
		_emit({"t": "regen_tick", "target": target.cid, "amount": healed})
	else:
		_emit({"t": "heal", "source": source.cid, "target": target.cid, "amount": healed})

func _apply_gauge(target: Combatant, delta: float) -> void:
	target.gauge = clampf(target.gauge + delta, 0.0, 100.0)
	_emit({"t": "gauge", "target": target.cid, "delta": delta})

func _cleanse(target: Combatant, count: int) -> void:
	var removed: Array = []
	for s in target.statuses.duplicate():
		if removed.size() >= count:
			break
		if s.def.is_debuff():
			target.statuses.erase(s)
			removed.append(s.def.id)
	if not removed.is_empty():
		_emit({"t": "cleanse", "target": target.cid, "removed": removed})

func _apply_status(source: Combatant, target: Combatant, status_id: String, chance: float, duration: int) -> void:
	var def: StatusEffectDefinition = registry.get_status(status_id)
	if def == null:
		return
	var adv := GameEnums.has_element_advantage(source.element, target.element)
	var success: bool
	if def.is_debuff():
		success = rng.chance(DamageFormula.debuff_chance(chance, source, target, adv))
	else:
		success = rng.chance(clampf(chance, 0.0, 1.0))
	if not success:
		_emit({"t": "resist", "target": target.cid, "status": status_id, "name": def.nom})
		return
	var dur: int = duration if duration > 0 else def.default_duration
	var existing := target.get_status(status_id)
	if existing != null:
		match def.refresh_rule:
			"refresh":
				existing.remaining = maxi(existing.remaining, dur)
				existing.applied_turn = turn_count
			"stack":
				existing.stacks = mini(def.max_stacks, existing.stacks + 1)
				existing.remaining = maxi(existing.remaining, dur)
				existing.applied_turn = turn_count
			"ignore":
				pass
		_emit({"t": "status", "target": target.cid, "status": status_id, "name": def.nom,
			"duration": existing.remaining, "stacks": existing.stacks, "buff": not def.is_debuff(), "refreshed": true})
		return
	var mag := _status_magnitude(def, source, target)
	target.statuses.append(StatusEffectInstance.new(def, dur, mag, source.cid, turn_count))
	_emit({"t": "status", "target": target.cid, "status": status_id, "name": def.nom,
		"duration": dur, "stacks": 1, "buff": not def.is_debuff()})
	if def.category == "shield":
		_emit({"t": "shield_gain", "target": target.cid, "amount": int(mag)})

func _status_magnitude(def: StatusEffectDefinition, source: Combatant, target: Combatant) -> float:
	match def.scale:
		"atk":
			return source.eff_stat("attaque") * def.value
		"maxhp_caster":
			return source.max_hp * def.value
		"maxhp_target":
			return target.max_hp * def.value
	return def.value

# =====================================================================
#  MORT / BOSS
# =====================================================================
func _on_death(unit: Combatant) -> void:
	_emit({"t": "death", "unit": unit.cid})
	if not unit.is_boss:
		for b in _same_side(unit):
			if b.is_alive() and b.is_boss and b.gauge_on_minion_death > 0.0:
				b.gauge = clampf(b.gauge + b.gauge_on_minion_death * 100.0, 0.0, 100.0)
				_emit({"t": "boss_gauge", "unit": b.cid, "delta": b.gauge_on_minion_death * 100.0})

func _check_enrage(boss: Combatant) -> void:
	if boss.half_hp_enrage and not boss.enraged and boss.hp_ratio() < 0.5:
		boss.enraged = true
		_apply_status(boss, boss, "atk_up", 1.0, 999)
		_apply_status(boss, boss, "spd_up", 1.0, 999)
		_emit({"t": "enrage", "unit": boss.cid})

# =====================================================================
#  FIN DE COMBAT
# =====================================================================
func _check_end() -> bool:
	if finished:
		return true
	var enemies_alive := enemies.filter(func(c): return c.is_alive())
	var allies_alive := allies.filter(func(c): return c.is_alive())
	if enemies_alive.is_empty():
		finished = true
		result = "victory"
		_emit({"t": "victory"})
		return true
	if allies_alive.is_empty():
		finished = true
		result = "defeat"
		_emit({"t": "defeat"})
		return true
	return false

func _resolve_timeout() -> void:
	if finished:
		return
	finished = true
	var a := 0.0
	var e := 0.0
	for c in allies:
		a += c.hp_ratio()
	for c in enemies:
		e += c.hp_ratio()
	result = "victory" if a >= e else "defeat"
	_emit({"t": "timeout"})
	_emit({"t": result})

# =====================================================================
#  JOURNAL D'ÉVÉNEMENTS
# =====================================================================
func _emit(ev: Dictionary) -> void:
	_events.append(ev)

func drain() -> Array:
	var e := _events
	_events = []
	return e
