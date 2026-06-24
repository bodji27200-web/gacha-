class_name HeroDefinition
extends Resource
## Définition immuable d'un héros (jamais modifiée par la sauvegarde).

@export var id: String = ""
@export var nom: String = ""
@export var element: int = GameEnums.Element.FEU
@export var role: int = GameEnums.Role.ATTAQUANT
@export var rarete: int = 3                  ## 3, 4 ou 5 étoiles
@export_multiline var description: String = ""

@export var base_stats: Stats                ## statistiques au niveau 1
@export var growth: Stats                    ## gain additif par niveau
@export var skill_ids: Array[String] = []    ## 3 compétences

## Direction artistique procédurale (assets temporaires, voir ROADMAP.md).
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY
@export var body_type: String = "slim"       ## heavy / slim / robed / archer / cloaked / brute
@export var weapon: String = "sword"         ## sword / shield / staff / bow / dagger / axe / orb
@export var tags: Array[String] = []

func stats_at_level(niveau: int) -> Stats:
	return base_stats.leveled(growth, niveau)
