class_name StageDefinition
extends Resource
## Définition d'un stage de combat.

@export var id: String = ""                 ## ex: "1-1"
@export var numero: int = 1
@export var nom: String = ""
@export var chapitre: String = ""
@export_multiline var description: String = ""
@export var enemy_ids: Array[String] = []   ## ennemis (max 4)
@export var decor: String = "ruines"
@export var has_boss: bool = false
@export var cost: int = 0                    ## reste à 0 pour la phase 1

## Récompenses standard (à chaque victoire).
@export var reward_or: int = 0
@export var reward_xp: int = 0
@export var reward_cristaux: int = 0

## Bonus de première victoire (une seule fois).
@export var first_or: int = 0
@export var first_xp: int = 0
@export var first_cristaux: int = 0
