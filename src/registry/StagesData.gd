class_name StagesData
extends RefCounted
## Premier chapitre : « Les Ruines de Cendre » (3 stages).

const CHAPITRE := "Les Ruines de Cendre"

static func _mk(cfg: Dictionary) -> StageDefinition:
	var s := StageDefinition.new()
	s.id = cfg["id"]
	s.numero = cfg["numero"]
	s.nom = cfg["nom"]
	s.chapitre = CHAPITRE
	s.description = cfg["desc"]
	s.enemy_ids.assign(cfg["enemies"])
	s.decor = cfg.get("decor", "ruines")
	s.has_boss = cfg.get("boss", false)
	s.cost = 0
	s.reward_or = cfg["or"]
	s.reward_xp = cfg["xp"]
	s.reward_cristaux = cfg["cr"]
	s.first_or = cfg["f_or"]
	s.first_xp = cfg["f_xp"]
	s.first_cristaux = cfg["f_cr"]
	return s

static func build() -> Array:
	var l: Array = []

	l.append(_mk({
		"id": "1-1", "numero": 1, "nom": "Entrée des Ruines",
		"desc": "Les premiers gardiens des ruines barrent le passage. Apprenez les bases du combat.",
		"enemies": ["ember_grunt", "ember_grunt", "ember_acolyte"], "decor": "ruines",
		"or": 200, "xp": 70, "cr": 10,
		"f_or": 300, "f_xp": 90, "f_cr": 80,
	}))
	l.append(_mk({
		"id": "1-2", "numero": 2, "nom": "Salle des Gardes",
		"desc": "La garnison s'organise : une sentinelle protège ses alliés. Exploitez buffs et debuffs.",
		"enemies": ["ash_defender", "ash_attacker", "thorn_stalker", "ember_acolyte"], "decor": "salle",
		"or": 320, "xp": 95, "cr": 15,
		"f_or": 500, "f_xp": 130, "f_cr": 120,
	}))
	l.append(_mk({
		"id": "1-3", "numero": 3, "nom": "Le Gardien des Cendres",
		"desc": "Le Gardien des Cendres veille au cœur des ruines, entouré de ses servants. Un vrai défi.",
		"enemies": ["gardien_cendres", "cinder_servant", "cinder_servant"], "decor": "trone", "boss": true,
		"or": 600, "xp": 170, "cr": 25,
		"f_or": 1500, "f_xp": 450, "f_cr": 400,
	}))

	return l
