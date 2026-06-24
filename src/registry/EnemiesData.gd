class_name EnemiesData
extends RefCounted
## Catalogue des ennemis du premier chapitre « Les Ruines de Cendre ».

const E := GameEnums.Element
const R := GameEnums.Role

static func _mk(cfg: Dictionary) -> EnemyDefinition:
	var e := EnemyDefinition.new()
	e.id = cfg["id"]
	e.nom = cfg["nom"]
	e.element = cfg["element"]
	e.role = cfg["role"]
	e.stats = cfg["stats"]
	e.skill_ids.assign(cfg["skills"])
	e.ai_profile = cfg["ai"]
	e.is_boss = cfg.get("boss", false)
	e.size_scale = cfg.get("size", 1.0)
	e.half_hp_enrage = cfg.get("enrage", false)
	e.gauge_on_minion_death = cfg.get("gauge_on_death", 0.0)
	e.reward_or = cfg.get("or", 0)
	e.reward_xp = cfg.get("xp", 0)
	e.reward_cristaux = cfg.get("cr", 0)
	e.primary_color = cfg["primary"]
	e.secondary_color = cfg["secondary"]
	e.body_type = cfg.get("body", "brute")
	e.weapon = cfg.get("weapon", "axe")
	return e

static func build() -> Array:
	var l: Array = []

	l.append(_mk({
		"id": "ember_grunt", "nom": "Fantassin de braise", "element": E.FEU, "role": R.ATTAQUANT,
		"stats": Stats.make(720, 110, 60, 95, 0.10, 1.5, 0.0, 0.0),
		"skills": ["e_strike", "e_heavy"], "ai": "attaquant",
		"primary": Color("b8472d"), "secondary": Color("3a1f16"), "body": "brute", "weapon": "axe",
	}))
	l.append(_mk({
		"id": "ember_acolyte", "nom": "Acolyte des cendres", "element": E.FEU, "role": R.SOIGNEUR,
		"stats": Stats.make(640, 95, 55, 100, 0.10, 1.5, 0.05, 0.0),
		"skills": ["e_heal", "e_strike"], "ai": "soigneur",
		"primary": Color("d98b3a"), "secondary": Color("4a2a16"), "body": "robed", "weapon": "staff",
	}))
	l.append(_mk({
		"id": "ash_defender", "nom": "Sentinelle de scorie", "element": E.FEU, "role": R.DEFENSEUR,
		"stats": Stats.make(1550, 95, 150, 84, 0.08, 1.5, 0.0, 0.12),
		"skills": ["e_guard", "e_strike"], "ai": "defenseur", "size": 1.15,
		"primary": Color("8a5a3a"), "secondary": Color("3a3a40"), "body": "heavy", "weapon": "shield",
	}))
	l.append(_mk({
		"id": "ash_attacker", "nom": "Rôdeur incandescent", "element": E.FEU, "role": R.ATTAQUANT,
		"stats": Stats.make(880, 140, 70, 102, 0.15, 1.5, 0.05, 0.0),
		"skills": ["e_heavy", "e_strike"], "ai": "attaquant",
		"primary": Color("c75a2d"), "secondary": Color("2a1812"), "body": "slim", "weapon": "dagger",
	}))
	l.append(_mk({
		"id": "thorn_stalker", "nom": "Ronce rampante", "element": E.NATURE, "role": R.ATTAQUANT,
		"stats": Stats.make(800, 125, 65, 106, 0.12, 1.5, 0.10, 0.0),
		"skills": ["e_weaken", "e_strike"], "ai": "attaquant",
		"primary": Color("4f8a3a"), "secondary": Color("23381c"), "body": "slim", "weapon": "dagger",
	}))
	l.append(_mk({
		"id": "cinder_servant", "nom": "Servant de cendre", "element": E.FEU, "role": R.ATTAQUANT,
		"stats": Stats.make(680, 118, 62, 98, 0.12, 1.5, 0.0, 0.0),
		"skills": ["e_strike"], "ai": "attaquant",
		"primary": Color("a83f2a"), "secondary": Color("2a1510"), "body": "brute", "weapon": "axe",
	}))

	# --- BOSS ---
	l.append(_mk({
		"id": "gardien_cendres", "nom": "Gardien des Cendres", "element": E.FEU, "role": R.DEFENSEUR,
		"stats": Stats.make(5200, 150, 120, 90, 0.12, 1.55, 0.10, 0.20),
		"skills": ["boss_frappe", "boss_onde", "e_strike"], "ai": "boss", "boss": true, "size": 1.7,
		"enrage": true, "gauge_on_death": 0.25,
		"primary": Color("e0561f"), "secondary": Color("2a1208"), "body": "brute", "weapon": "axe",
	}))

	return l
