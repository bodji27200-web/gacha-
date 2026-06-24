class_name StatusEffectInstance
extends RefCounted
## Effet de statut actif sur un combattant (runtime).

var def: StatusEffectDefinition
var remaining: int = 1
var magnitude: float = 0.0   ## valeur figée à l'application (dégâts/tour, bouclier, soin/tour, ou fraction de stat)
var stacks: int = 1
var source_cid: int = -1
var applied_turn: int = -1    ## tour (turn_count) d'application — sert au délai de grâce d'expiration

func _init(p_def: StatusEffectDefinition, p_remaining: int, p_magnitude: float, p_source: int, p_turn: int) -> void:
	def = p_def
	remaining = p_remaining
	magnitude = p_magnitude
	source_cid = p_source
	applied_turn = p_turn
