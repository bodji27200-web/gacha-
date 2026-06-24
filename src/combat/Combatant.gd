class_name Combatant
extends RefCounted
## Unité de combat runtime (héros allié ou ennemi). Contient l'état du combat,
## jamais les données joueur persistantes.

var cid: int = -1
var side: String = "ally"          # "ally" ou "enemy"
var is_enemy: bool = false
var slot: int = 0                  # position d'affichage

var display_name: String = ""
var element: int = GameEnums.Element.FEU
var role: int = GameEnums.Role.ATTAQUANT
var def_id: String = ""            # id de définition (héros ou ennemi)
var hero_uid: String = ""          # si allié issu d'un HeroInstance

var base_stats: Stats              # statistiques de base (niveau appliqué)
var max_hp: float = 1.0
var hp: float = 1.0
var gauge: float = 0.0

var skills: Array = []             # Array[SkillDefinition]
var cooldowns: Dictionary = {}     # skill_id -> tours restants
var statuses: Array = []           # Array[StatusEffectInstance]

var ai_profile: String = "attaquant"
var is_boss: bool = false
var size_scale: float = 1.0
var half_hp_enrage: bool = false
var gauge_on_minion_death: float = 0.0
var enraged: bool = false

# Visuel procédural (pour l'UI)
var visual: Dictionary = {}

func is_alive() -> bool:
	return hp > 0.0

func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0

## Statistique effective (base + modificateurs de statut).
func eff_stat(stat: String) -> float:
	var base := base_stats.get_by_name(stat)
	var sum := 0.0
	for s in statuses:
		if s.def.category == "stat" and s.def.stat_kind == stat:
			sum += s.def.value * s.stacks
	if stat == "attaque" or stat == "defense" or stat == "vitesse":
		return maxf(0.0, base * (1.0 + sum))
	return maxf(0.0, base + sum)

func speed() -> float:
	return maxf(1.0, eff_stat("vitesse"))

func total_shield() -> float:
	var t := 0.0
	for s in statuses:
		if s.def.category == "shield":
			t += s.magnitude
	return t

func is_prevented() -> bool:
	for s in statuses:
		if s.def.prevents_action():
			return true
	return false

func get_status(id: String) -> StatusEffectInstance:
	for s in statuses:
		if s.def.id == id:
			return s
	return null

func has_status(id: String) -> bool:
	return get_status(id) != null

func debuff_count() -> int:
	var c := 0
	for s in statuses:
		if s.def.is_debuff():
			c += 1
	return c

func taunt_source_cid() -> int:
	for s in statuses:
		if s.def.category == "taunt":
			return s.source_cid
	return -1
