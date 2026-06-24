class_name StatusEffectDefinition
extends Resource
## Définition d'un effet de statut (buff ou debuff).
##
## Catégories :
##   "stat"   -> modifie une statistique (stat_kind) de `value` (fraction, +/-)
##   "dot"    -> dégâts par tour (magnitude figée à l'application selon `scale`)
##   "shield" -> absorbe des dégâts (magnitude figée selon `scale`)
##   "regen"  -> soigne par tour (magnitude figée selon `scale`)
##   "stun"   -> empêche d'agir (étourdissement)
##   "freeze" -> empêche d'agir (gel)
##   "taunt"  -> force les ennemis à cibler le porteur
##
## `scale` détermine comment la magnitude est calculée à l'application :
##   "none"          -> value telle quelle
##   "atk"           -> lanceur.attaque * value
##   "maxhp_caster"  -> lanceur.pv_max * value
##   "maxhp_target"  -> cible.pv_max * value

@export var id: String = ""
@export var nom: String = ""
@export var type: int = GameEnums.EffectType.BUFF
@export var category: String = "stat"
@export var stat_kind: String = ""          ## pour category == "stat"
@export var value: float = 0.0
@export var scale: String = "none"
@export var default_duration: int = 2
@export var stackable: bool = false
@export var max_stacks: int = 1
## Comportement à la réapplication : "refresh" (remet la durée), "stack" (cumule), "ignore"
@export var refresh_rule: String = "refresh"
@export var icon_key: String = ""
@export var color: Color = Color.WHITE
@export_multiline var description: String = ""

func is_debuff() -> bool:
	return type == GameEnums.EffectType.DEBUFF

func prevents_action() -> bool:
	return category == "stun" or category == "freeze"
