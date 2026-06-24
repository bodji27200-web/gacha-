class_name EnemyDefinition
extends Resource
## Définition d'un ennemi (PvE).

@export var id: String = ""
@export var nom: String = ""
@export var element: int = GameEnums.Element.FEU
@export var role: int = GameEnums.Role.ATTAQUANT
@export var stats: Stats
@export var skill_ids: Array[String] = []
@export var ai_profile: String = "attaquant"   ## attaquant / defenseur / soutien / soigneur / boss
@export var is_boss: bool = false
@export var size_scale: float = 1.0

## Mécaniques de boss (optionnelles).
@export var half_hp_enrage: bool = false        ## à < 50 % PV : attaque + vitesse une seule fois
@export var gauge_on_minion_death: float = 0.0  ## jauge gagnée quand un sbire meurt (fraction de 100)

## Récompenses individuelles (sommées au niveau du stage le plus souvent).
@export var reward_or: int = 0
@export var reward_xp: int = 0
@export var reward_cristaux: int = 0

# Visuel procédural
@export var primary_color: Color = Color("8a4b4b")
@export var secondary_color: Color = Color("3a2a2a")
@export var body_type: String = "brute"
@export var weapon: String = "axe"
