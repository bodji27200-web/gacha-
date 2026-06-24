class_name HeroesData
extends RefCounted
## Catalogue des six héros originaux du prototype.
## Statistiques de base (niv. 1) + croissance par niveau (niveau max phase 1 = 20).

const E := GameEnums.Element
const R := GameEnums.Role

static func _mk(cfg: Dictionary) -> HeroDefinition:
	var h := HeroDefinition.new()
	h.id = cfg["id"]
	h.nom = cfg["nom"]
	h.element = cfg["element"]
	h.role = cfg["role"]
	h.rarete = cfg["rarete"]
	h.description = cfg["desc"]
	h.base_stats = cfg["base"]
	h.growth = cfg["growth"]
	h.skill_ids.assign(cfg["skills"])
	h.primary_color = cfg["primary"]
	h.secondary_color = cfg["secondary"]
	h.body_type = cfg["body"]
	h.weapon = cfg["weapon"]
	h.tags.assign(cfg.get("tags", []))
	return h

static func build() -> Array:
	var l: Array = []

	l.append(_mk({
		"id": "kaelen", "nom": "Kaelen", "element": E.FEU, "role": R.ATTAQUANT, "rarete": 3,
		"desc": "Guerrier offensif simple et efficace, idéal pour débuter. Met le feu à ses ennemis et frappe plus fort ceux qui brûlent.",
		"base": Stats.make(1050, 175, 80, 102, 0.18, 1.5, 0.05, 0.0),
		"growth": Stats.make(60, 11, 4, 0),
		"skills": ["kaelen_1", "kaelen_2", "kaelen_3"],
		"primary": Color("e8552d"), "secondary": Color("5a2418"), "body": "brute", "weapon": "sword",
	}))

	l.append(_mk({
		"id": "brask", "nom": "Brask", "element": E.FEU, "role": R.DEFENSEUR, "rarete": 4,
		"desc": "Gardien lourd qui provoque les ennemis et dresse un mur de boucliers pour protéger l'équipe.",
		"base": Stats.make(1750, 110, 165, 92, 0.10, 1.5, 0.05, 0.15),
		"growth": Stats.make(96, 6, 9, 0),
		"skills": ["brask_1", "brask_2", "brask_3"],
		"primary": Color("c2632e"), "secondary": Color("47474f"), "body": "heavy", "weapon": "shield",
	}))

	l.append(_mk({
		"id": "neria", "nom": "Néria", "element": E.EAU, "role": R.SOIGNEUR, "rarete": 3,
		"desc": "Soigneuse fiable et accessible. Garde l'équipe en vie et purifie les afflictions.",
		"base": Stats.make(1150, 130, 95, 98, 0.12, 1.5, 0.05, 0.10),
		"growth": Stats.make(72, 7, 5, 0),
		"skills": ["neria_1", "neria_2", "neria_3"],
		"primary": Color("3a8ed6"), "secondary": Color("cfe8ff"), "body": "robed", "weapon": "staff",
	}))

	l.append(_mk({
		"id": "selka", "nom": "Selka", "element": E.EAU, "role": R.SOUTIEN, "rarete": 4,
		"desc": "Mage de contrôle qui gèle, ralentit et vole le tempo aux ennemis.",
		"base": Stats.make(980, 150, 80, 108, 0.15, 1.5, 0.20, 0.05),
		"growth": Stats.make(58, 9, 4, 0),
		"skills": ["selka_1", "selka_2", "selka_3"],
		"primary": Color("2f9fb0"), "secondary": Color("bff0ff"), "body": "cloaked", "weapon": "orb",
	}))

	l.append(_mk({
		"id": "elyra", "nom": "Elyra", "element": E.NATURE, "role": R.SOUTIEN, "rarete": 3,
		"desc": "Soutien offensif qui accélère ses alliés et affaiblit les défenses ennemies.",
		"base": Stats.make(980, 145, 78, 112, 0.15, 1.5, 0.15, 0.05),
		"growth": Stats.make(56, 8, 4, 1),
		"skills": ["elyra_1", "elyra_2", "elyra_3"],
		"primary": Color("57b34a"), "secondary": Color("d8f0b0"), "body": "archer", "weapon": "bow",
	}))

	l.append(_mk({
		"id": "vaeron", "nom": "Vaeron", "element": E.NATURE, "role": R.ATTAQUANT, "rarete": 5,
		"desc": "Assassin empoisonneur. Accumule les debuffs sur sa proie puis l'exécute lorsqu'elle est affaiblie.",
		"base": Stats.make(1080, 215, 85, 116, 0.25, 1.6, 0.10, 0.05),
		"growth": Stats.make(62, 14, 4, 1),
		"skills": ["vaeron_1", "vaeron_2", "vaeron_3"],
		"primary": Color("2f7d4a"), "secondary": Color("16241a"), "body": "slim", "weapon": "dagger",
	}))

	return l
