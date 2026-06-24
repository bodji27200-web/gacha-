class_name SkillDefinition
extends Resource
## Définition immuable d'une compétence.
##
## Le comportement est entièrement piloté par les données : la logique de combat
## (SkillResolver) interprète ces champs. Aucune valeur n'est codée en dur ailleurs.
##
## Schéma d'un effet (Dictionary) dans `effects` :
##   {
##     "kind": "status" | "heal" | "shield" | "gauge" | "cleanse",
##     "to":   "target" | "self" | "all_enemies" | "all_allies" | "ally_lowest" | "caster",
##     # status:
##     "status": "<id StatusEffectDefinition>", "chance": 0.0..1.0, "duration": int,
##     # heal:   montant = caster.attaque * power  (+ cible.pv_max * hp_frac)
##     "power": float, "hp_frac": float,
##     # gauge:  amount en fraction de 100 (+0.3 = +30 jauge, -0.3 = -30)
##     "amount": float,
##     # cleanse: nombre de debuffs retirés
##     "count": int,
##   }

@export var id: String = ""
@export var nom: String = ""
@export_multiline var description: String = ""
@export var icon_key: String = ""           ## clé visuelle procédurale
@export var cooldown: int = 0               ## en tours de l'unité (0 = aucun)
@export var target: int = GameEnums.Target.ENEMY_ONE
@export var power: float = 1.0              ## multiplicateur de dégâts (0 = pas de dégâts directs)
@export var hits: int = 1                   ## nombre de coups
@export var element: int = -1               ## -1 = hérite de l'élément du lanceur
@export var ai_priority: int = 1            ## plus élevé = privilégié par l'IA

## Modificateurs conditionnels de dégâts sur la cible principale.
@export var bonus_if_status: String = ""    ## ex: "brulure"
@export var bonus_if_status_mult: float = 1.0
@export var bonus_per_debuff: float = 0.0   ## +x par debuff présent sur la cible
@export var execute_threshold: float = 0.0  ## si > 0, bonus si PV cible < seuil
@export var execute_mult: float = 1.0

@export var effects: Array = []             ## liste de Dictionary (voir schéma ci-dessus)

func deals_damage() -> bool:
	return power > 0.0

func is_offensive() -> bool:
	return target == GameEnums.Target.ENEMY_ONE or target == GameEnums.Target.ENEMY_ALL
