class_name EnemyAI
extends RefCounted
## IA cohérente mais non parfaite (aucune connaissance du futur).
## Sert aux ennemis et, pour les tests automatiques, au pilotage des alliés.

const T := GameEnums.Target

## Retourne {skill: SkillDefinition, target: Combatant}.
static func choose(engine, actor: Combatant) -> Dictionary:
	var avail: Array = engine.available_skills(actor)
	var foes: Array = engine.living_enemies_of(actor)
	var allies: Array = engine.living_allies_of(actor)
	if avail.is_empty() or foes.is_empty():
		return {}

	match actor.ai_profile:
		"soigneur":
			var d := _try_heal(engine, actor, avail, allies)
			if not d.is_empty():
				return d
		"defenseur":
			var d := _try_guard(engine, actor, avail, allies)
			if not d.is_empty():
				return d
		"soutien":
			var d := _try_buff(engine, actor, avail, allies)
			if not d.is_empty():
				return d
		"boss":
			var d := _boss_logic(engine, actor, avail, foes)
			if not d.is_empty():
				return d

	# Par défaut : meilleure attaque disponible sur une cible pertinente
	return _attack(engine, actor, avail, foes)

# --------------------------------------------------------------------
static func _attack(engine, actor: Combatant, avail: Array, foes: Array) -> Dictionary:
	var best: SkillDefinition = null
	for s in avail:
		if s.deals_damage() and s.is_offensive():
			if best == null or s.ai_priority > best.ai_priority \
					or (s.ai_priority == best.ai_priority and s.power > best.power):
				best = s
	if best == null:
		best = avail[0]
	return {"skill": best, "target": _offensive_target(engine, actor, foes)}

static func _offensive_target(engine, actor: Combatant, foes: Array) -> Combatant:
	# Provocation : cible forcée
	var tcid := actor.taunt_source_cid()
	if tcid >= 0:
		for f in foes:
			if f.cid == tcid:
				return f
	# Sinon : cible la plus basse en PV % (peut achever), puis la plus fragile
	var best: Combatant = foes[0]
	for f in foes:
		if f.hp_ratio() < best.hp_ratio() - 0.001:
			best = f
		elif absf(f.hp_ratio() - best.hp_ratio()) <= 0.001 and f.max_hp < best.max_hp:
			best = f
	return best

static func _try_heal(engine, actor: Combatant, avail: Array, allies: Array) -> Dictionary:
	var lowest := _lowest_ally(allies)
	if lowest == null or lowest.hp_ratio() >= 0.75:
		return {}
	for s in avail:
		if _is_heal(s):
			return {"skill": s, "target": lowest}
	return {}

static func _try_guard(engine, actor: Combatant, avail: Array, allies: Array) -> Dictionary:
	var threatened := actor.hp_ratio() < 0.7
	for a in allies:
		if a.hp_ratio() < 0.4:
			threatened = true
	if not threatened:
		return {}
	for s in avail:
		if s.target == T.SELF or _has_effect_kind(s, "status") and s.cooldown > 0:
			# privilégie une compétence défensive (bouclier / def_up)
			if _grants_status(engine, s, "bouclier") or _grants_status(engine, s, "def_up"):
				return {"skill": s, "target": actor}
	return {}

static func _try_buff(engine, actor: Combatant, avail: Array, allies: Array) -> Dictionary:
	for s in avail:
		if s.cooldown > 0 and (_grants_status(engine, s, "atk_up") or _grants_status(engine, s, "spd_up")):
			# cible un allié vivant qui n'a pas encore le buff
			var target: Combatant = null
			for a in allies:
				if a == actor:
					continue
				if not a.has_status("atk_up"):
					if target == null or a.eff_stat("attaque") > target.eff_stat("attaque"):
						target = a
			if target != null:
				return {"skill": s, "target": target}
	return {}

static func _boss_logic(engine, actor: Combatant, avail: Array, foes: Array) -> Dictionary:
	# AoE prioritaire si plusieurs cibles
	for s in avail:
		if s.target == T.ENEMY_ALL and foes.size() >= 2:
			return {"skill": s, "target": foes[0]}
	# sinon meilleure attaque ciblée
	return _attack(engine, actor, avail, foes)

# --------------------------------------------------------------------
static func _lowest_ally(allies: Array) -> Combatant:
	var best: Combatant = null
	for a in allies:
		if best == null or a.hp_ratio() < best.hp_ratio():
			best = a
	return best

static func _is_heal(skill: SkillDefinition) -> bool:
	for e in skill.effects:
		if e.get("kind", "") == "heal":
			return true
	return false

static func _has_effect_kind(skill: SkillDefinition, kind: String) -> bool:
	for e in skill.effects:
		if e.get("kind", "") == kind:
			return true
	return false

static func _grants_status(engine, skill: SkillDefinition, status_id: String) -> bool:
	for e in skill.effects:
		if e.get("kind", "") == "status" and e.get("status", "") == status_id:
			return true
	return false
