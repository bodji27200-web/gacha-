class_name SkillsData
extends RefCounted
## Catalogue des compétences (héros, ennemis, boss).
## Toutes les valeurs d'équilibrage sont centralisées ici, jamais dans la logique.

const T := GameEnums.Target

static func _mk(cfg: Dictionary) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = cfg.get("id", "")
	s.nom = cfg.get("nom", "")
	s.description = cfg.get("desc", "")
	s.icon_key = cfg.get("icon", cfg.get("id", ""))
	s.cooldown = cfg.get("cd", 0)
	s.target = cfg.get("target", T.ENEMY_ONE)
	s.power = cfg.get("power", 0.0)
	s.hits = cfg.get("hits", 1)
	s.element = cfg.get("element", -1)
	s.ai_priority = cfg.get("ai", 1)
	s.bonus_if_status = cfg.get("bonus_if_status", "")
	s.bonus_if_status_mult = cfg.get("bonus_if_status_mult", 1.0)
	s.bonus_per_debuff = cfg.get("bonus_per_debuff", 0.0)
	s.execute_threshold = cfg.get("execute_threshold", 0.0)
	s.execute_mult = cfg.get("execute_mult", 1.0)
	s.effects = cfg.get("effects", [])
	return s

static func build() -> Array:
	var l: Array = []

	# ============================ KAELEN (Feu / Attaquant) ============================
	l.append(_mk({
		"id": "kaelen_1", "nom": "Taillade ardente", "target": T.ENEMY_ONE, "power": 1.0, "ai": 1,
		"desc": "Frappe une cible. 40 % de chance d'appliquer Brûlure (2 tours).",
		"effects": [{"kind": "status", "status": "brulure", "chance": 0.40, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "kaelen_2", "nom": "Assaut embrasé", "target": T.ENEMY_ONE, "power": 1.8, "cd": 3, "ai": 3,
		"bonus_if_status": "brulure", "bonus_if_status_mult": 1.4,
		"desc": "Attaque puissante. Dégâts +40 % si la cible est déjà brûlée.",
	}))
	l.append(_mk({
		"id": "kaelen_3", "nom": "Cœur de braise", "target": T.SELF, "power": 0.0, "cd": 4, "ai": 2,
		"desc": "Augmente sa propre attaque et son taux critique, et gagne de la jauge.",
		"effects": [
			{"kind": "status", "status": "atk_up", "chance": 1.0, "duration": 3, "to": "self"},
			{"kind": "status", "status": "crit_up", "chance": 1.0, "duration": 3, "to": "self"},
			{"kind": "gauge", "amount": 0.25, "to": "self"},
		],
	}))

	# ============================ BRASK (Feu / Défenseur) ============================
	l.append(_mk({
		"id": "brask_1", "nom": "Coup de bouclier", "target": T.ENEMY_ONE, "power": 0.9, "ai": 1,
		"desc": "Frappe une cible. 50 % de chance de réduire sa vitesse.",
		"effects": [{"kind": "status", "status": "spd_down", "chance": 0.50, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "brask_2", "nom": "Défi du gardien", "target": T.ENEMY_ALL, "power": 0.7, "cd": 3, "ai": 3,
		"desc": "Frappe tous les ennemis. 60 % de chance de les provoquer (1 tour).",
		"effects": [{"kind": "status", "status": "provocation", "chance": 0.60, "duration": 1, "to": "all_enemies"}],
	}))
	l.append(_mk({
		"id": "brask_3", "nom": "Mur de fer", "target": T.ALLY_ALL, "power": 0.0, "cd": 4, "ai": 4,
		"desc": "Donne un bouclier à toute l'équipe et augmente sa propre défense.",
		"effects": [
			{"kind": "status", "status": "bouclier", "chance": 1.0, "duration": 2, "to": "all_allies"},
			{"kind": "status", "status": "def_up", "chance": 1.0, "duration": 3, "to": "self"},
		],
	}))

	# ============================ NÉRIA (Eau / Soigneur) ============================
	l.append(_mk({
		"id": "neria_1", "nom": "Éclat d'eau", "target": T.ENEMY_ONE, "power": 0.9, "ai": 1,
		"desc": "Frappe une cible et soigne l'allié le plus faible.",
		"effects": [{"kind": "heal", "power": 0.6, "to": "ally_lowest"}],
	}))
	l.append(_mk({
		"id": "neria_2", "nom": "Vague apaisante", "target": T.ALLY_ONE, "power": 0.0, "cd": 3, "ai": 3,
		"desc": "Soigne un allié et retire un debuff.",
		"effects": [
			{"kind": "heal", "power": 1.4, "to": "target"},
			{"kind": "cleanse", "count": 1, "to": "target"},
		],
	}))
	l.append(_mk({
		"id": "neria_3", "nom": "Marée de vie", "target": T.ALLY_ALL, "power": 0.0, "cd": 5, "ai": 4,
		"desc": "Soigne toute l'équipe et applique Régénération (2 tours).",
		"effects": [
			{"kind": "heal", "power": 1.0, "to": "all_allies"},
			{"kind": "status", "status": "regen", "chance": 1.0, "duration": 2, "to": "all_allies"},
		],
	}))

	# ============================ SELKA (Eau / Soutien) ============================
	l.append(_mk({
		"id": "selka_1", "nom": "Aiguille de givre", "target": T.ENEMY_ONE, "power": 1.0, "ai": 1,
		"desc": "Frappe une cible. 50 % de chance de réduire sa vitesse.",
		"effects": [{"kind": "status", "status": "spd_down", "chance": 0.50, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "selka_2", "nom": "Prison gelée", "target": T.ENEMY_ONE, "power": 1.1, "cd": 3, "ai": 3,
		"desc": "Frappe une cible. 75 % de chance de la geler (1 tour).",
		"effects": [{"kind": "status", "status": "gel", "chance": 0.75, "duration": 1, "to": "target"}],
	}))
	l.append(_mk({
		"id": "selka_3", "nom": "Hiver silencieux", "target": T.ENEMY_ALL, "power": 0.8, "cd": 5, "ai": 4,
		"desc": "Frappe tous les ennemis, réduit leur jauge et peut réduire leur vitesse.",
		"effects": [
			{"kind": "gauge", "amount": -0.30, "to": "all_enemies"},
			{"kind": "status", "status": "spd_down", "chance": 0.50, "duration": 2, "to": "all_enemies"},
		],
	}))

	# ============================ ELYRA (Nature / Soutien) ============================
	l.append(_mk({
		"id": "elyra_1", "nom": "Flèche verdoyante", "target": T.ENEMY_ONE, "power": 1.0, "ai": 1,
		"desc": "Frappe une cible. 50 % de chance de réduire sa défense.",
		"effects": [{"kind": "status", "status": "def_down", "chance": 0.50, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "elyra_2", "nom": "Souffle du bosquet", "target": T.ALLY_OTHER, "power": 0.0, "cd": 3, "ai": 3,
		"desc": "Augmente la vitesse d'un allié et remplit une partie de sa jauge.",
		"effects": [
			{"kind": "status", "status": "spd_up", "chance": 1.0, "duration": 2, "to": "target"},
			{"kind": "gauge", "amount": 0.30, "to": "target"},
		],
	}))
	l.append(_mk({
		"id": "elyra_3", "nom": "Appel de la canopée", "target": T.ALLY_ALL, "power": 0.0, "cd": 5, "ai": 4,
		"desc": "Augmente l'attaque et la vitesse de toute l'équipe.",
		"effects": [
			{"kind": "status", "status": "atk_up", "chance": 1.0, "duration": 2, "to": "all_allies"},
			{"kind": "status", "status": "spd_up", "chance": 1.0, "duration": 2, "to": "all_allies"},
		],
	}))

	# ============================ VAERON (Nature / Attaquant) ============================
	l.append(_mk({
		"id": "vaeron_1", "nom": "Lame toxique", "target": T.ENEMY_ONE, "power": 1.0, "ai": 1,
		"desc": "Frappe une cible. 80 % de chance d'appliquer Poison (3 tours).",
		"effects": [{"kind": "status", "status": "poison", "chance": 0.80, "duration": 3, "to": "target"}],
	}))
	l.append(_mk({
		"id": "vaeron_2", "nom": "Pas du prédateur", "target": T.ENEMY_ONE, "power": 1.4, "cd": 3, "ai": 3,
		"bonus_per_debuff": 0.20,
		"desc": "Attaque dont les dégâts augmentent de 20 % par debuff sur la cible.",
	}))
	l.append(_mk({
		"id": "vaeron_3", "nom": "Fin de la chasse", "target": T.ENEMY_ONE, "power": 2.2, "cd": 5, "ai": 5,
		"execute_threshold": 0.40, "execute_mult": 1.7,
		"desc": "Attaque dévastatrice. Dégâts +70 % si la cible est sous 40 % de PV.",
	}))

	# ============================ ENNEMIS GÉNÉRIQUES ============================
	l.append(_mk({
		"id": "e_strike", "nom": "Frappe", "target": T.ENEMY_ONE, "power": 1.0, "ai": 1,
		"desc": "Une attaque simple.",
	}))
	l.append(_mk({
		"id": "e_heavy", "nom": "Coup lourd", "target": T.ENEMY_ONE, "power": 1.4, "cd": 2, "ai": 3,
		"desc": "Une attaque renforcée.",
	}))
	l.append(_mk({
		"id": "e_weaken", "nom": "Entaille affaiblissante", "target": T.ENEMY_ONE, "power": 0.9, "cd": 2, "ai": 2,
		"desc": "Frappe et réduit la défense.",
		"effects": [{"kind": "status", "status": "def_down", "chance": 0.6, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "e_guard", "nom": "Posture défensive", "target": T.SELF, "power": 0.0, "cd": 3, "ai": 3,
		"desc": "Se protège et renforce sa défense.",
		"effects": [
			{"kind": "status", "status": "bouclier", "chance": 1.0, "duration": 2, "to": "self"},
			{"kind": "status", "status": "def_up", "chance": 1.0, "duration": 2, "to": "self"},
		],
	}))
	l.append(_mk({
		"id": "e_buff", "nom": "Cri de guerre", "target": T.ALLY_OTHER, "power": 0.0, "cd": 3, "ai": 3,
		"desc": "Augmente l'attaque d'un allié.",
		"effects": [{"kind": "status", "status": "atk_up", "chance": 1.0, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "e_heal", "nom": "Prière", "target": T.ALLY_LOWEST, "power": 0.0, "cd": 0, "ai": 3,
		"desc": "Soigne l'allié le plus faible.",
		"effects": [{"kind": "heal", "power": 1.1, "to": "ally_lowest"}],
	}))

	# ============================ BOSS : GARDIEN DES CENDRES ============================
	l.append(_mk({
		"id": "boss_frappe", "nom": "Frappe du brasier", "target": T.ENEMY_ONE, "power": 1.3, "ai": 2,
		"desc": "Frappe une cible et applique Brûlure.",
		"effects": [{"kind": "status", "status": "brulure", "chance": 0.8, "duration": 2, "to": "target"}],
	}))
	l.append(_mk({
		"id": "boss_onde", "nom": "Onde de cendre", "target": T.ENEMY_ALL, "power": 1.0, "cd": 3, "ai": 4,
		"desc": "Frappe toute l'équipe et peut réduire l'attaque.",
		"effects": [{"kind": "status", "status": "atk_down", "chance": 0.5, "duration": 2, "to": "all_enemies"}],
	}))

	return l
