class_name Stats
extends Resource
## Bloc de statistiques d'une unité.
## Les pourcentages (crit, précision, résistance) sont stockés en fraction (0.15 = 15 %).

@export var pv: float = 0.0
@export var attaque: float = 0.0
@export var defense: float = 0.0
@export var vitesse: float = 0.0
@export var crit_taux: float = 0.0      ## chance de critique (0..1)
@export var crit_degats: float = 0.0    ## multiplicateur de critique (1.5 = +50 %)
@export var precision: float = 0.0      ## bonus à l'application des debuffs (0..~1)
@export var resistance: float = 0.0     ## résistance aux debuffs (0..~1)

static func make(p: float, a: float, d: float, v: float,
		ct: float = 0.15, cd: float = 1.5, pr: float = 0.0, re: float = 0.0) -> Stats:
	var s := Stats.new()
	s.pv = p
	s.attaque = a
	s.defense = d
	s.vitesse = v
	s.crit_taux = ct
	s.crit_degats = cd
	s.precision = pr
	s.resistance = re
	return s

func clone() -> Stats:
	return Stats.make(pv, attaque, defense, vitesse, crit_taux, crit_degats, precision, resistance)

## Retourne base + growth * (niveau - 1). Seules PV/ATQ/DEF/VIT croissent.
func leveled(growth: Stats, niveau: int) -> Stats:
	var n := float(maxi(1, niveau) - 1)
	var s := clone()
	s.pv = pv + growth.pv * n
	s.attaque = attaque + growth.attaque * n
	s.defense = defense + growth.defense * n
	s.vitesse = vitesse + growth.vitesse * n
	return s

func get_by_name(stat: String) -> float:
	match stat:
		"pv": return pv
		"attaque": return attaque
		"defense": return defense
		"vitesse": return vitesse
		"crit_taux": return crit_taux
		"crit_degats": return crit_degats
		"precision": return precision
		"resistance": return resistance
	return 0.0
