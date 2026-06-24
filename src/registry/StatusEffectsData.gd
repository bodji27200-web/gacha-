class_name StatusEffectsData
extends RefCounted
## Catalogue des effets de statut. Toutes les valeurs sont centralisées ici.

static func _mk(id: String, nom: String, type: int, category: String,
		value: float, scale: String, duration: int, icon: String, color: Color,
		desc: String, stat_kind: String = "", stackable: bool = false,
		max_stacks: int = 1, refresh: String = "refresh") -> StatusEffectDefinition:
	var s := StatusEffectDefinition.new()
	s.id = id
	s.nom = nom
	s.type = type
	s.category = category
	s.value = value
	s.scale = scale
	s.default_duration = duration
	s.icon_key = icon
	s.color = color
	s.description = desc
	s.stat_kind = stat_kind
	s.stackable = stackable
	s.max_stacks = max_stacks
	s.refresh_rule = refresh
	return s

static func build() -> Array:
	const BUFF := GameEnums.EffectType.BUFF
	const DEBUFF := GameEnums.EffectType.DEBUFF
	var list: Array = []

	# --- BUFFS ---
	list.append(_mk("atk_up", "Attaque +", BUFF, "stat", 0.50, "none", 2,
		"buff_atk", Color("e2a33a"), "Augmente l'attaque de 50 %.", "attaque"))
	list.append(_mk("def_up", "Défense +", BUFF, "stat", 0.50, "none", 2,
		"buff_def", Color("c8a23a"), "Augmente la défense de 50 %.", "defense"))
	list.append(_mk("spd_up", "Vitesse +", BUFF, "stat", 0.30, "none", 2,
		"buff_spd", Color("5ad6c2"), "Augmente la vitesse de 30 %.", "vitesse"))
	list.append(_mk("crit_up", "Critique +", BUFF, "stat", 0.25, "none", 2,
		"buff_crit", Color("f05a78"), "Augmente le taux critique de 25 %.", "crit_taux"))
	list.append(_mk("bouclier", "Bouclier", BUFF, "shield", 0.18, "maxhp_caster", 2,
		"shield", Color("8fc7ff"), "Absorbe des dégâts avant les PV."))
	list.append(_mk("regen", "Régénération", BUFF, "regen", 0.10, "maxhp_target", 2,
		"regen", Color("7fe39a"), "Soigne 10 % des PV max au début du tour."))

	# --- DEBUFFS ---
	list.append(_mk("atk_down", "Attaque -", DEBUFF, "stat", -0.35, "none", 2,
		"debuff_atk", Color("8c5a2f"), "Réduit l'attaque de 35 %.", "attaque"))
	list.append(_mk("def_down", "Défense -", DEBUFF, "stat", -0.40, "none", 2,
		"debuff_def", Color("9a6b2f"), "Réduit la défense de 40 %.", "defense"))
	list.append(_mk("spd_down", "Vitesse -", DEBUFF, "stat", -0.30, "none", 2,
		"debuff_spd", Color("4a7c8c"), "Réduit la vitesse de 30 %.", "vitesse"))
	list.append(_mk("brulure", "Brûlure", DEBUFF, "dot", 0.35, "atk", 2,
		"burn", Color("ff7a3a"), "Inflige des dégâts de feu au début du tour."))
	list.append(_mk("poison", "Poison", DEBUFF, "dot", 0.28, "atk", 3,
		"poison", Color("8ad15a"), "Inflige des dégâts de poison au début du tour.",
		"", true, 3, "stack"))
	list.append(_mk("etourdissement", "Étourdissement", DEBUFF, "stun", 0.0, "none", 1,
		"stun", Color("f2d24a"), "Empêche d'agir pendant un tour."))
	list.append(_mk("gel", "Gel", DEBUFF, "freeze", 0.0, "none", 1,
		"freeze", Color("9fd8ff"), "Empêche d'agir pendant un tour."))
	list.append(_mk("provocation", "Provocation", DEBUFF, "taunt", 0.0, "none", 1,
		"taunt", Color("e06a4a"), "Force à attaquer le provocateur."))

	return list
