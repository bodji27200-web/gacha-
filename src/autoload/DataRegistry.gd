extends Node
## Registre central de toutes les définitions immuables (data-driven).
## Utilisable comme autoload (UI) ou instancié directement (tests) via load_all().

var heroes: Dictionary = {}          # id -> HeroDefinition
var skills: Dictionary = {}          # id -> SkillDefinition
var status_effects: Dictionary = {}  # id -> StatusEffectDefinition
var enemies: Dictionary = {}         # id -> EnemyDefinition
var stages: Dictionary = {}          # id -> StageDefinition
var banners: Dictionary = {}         # id -> SummonBannerDefinition

var _loaded := false

func _ready() -> void:
	load_all()

func load_all() -> void:
	if _loaded:
		return
	_index(HeroesData.build(), heroes)
	_index(SkillsData.build(), skills)
	_index(StatusEffectsData.build(), status_effects)
	_index(EnemiesData.build(), enemies)
	_index(StagesData.build(), stages)
	_index(BannersData.build(), banners)
	_loaded = true

func _index(list: Array, target: Dictionary) -> void:
	for item in list:
		assert(not target.has(item.id), "Identifiant en double : %s" % item.id)
		target[item.id] = item

# --- Accès typés ---
func get_hero(id: String) -> HeroDefinition:
	return heroes.get(id)

func get_skill(id: String) -> SkillDefinition:
	return skills.get(id)

func get_status(id: String) -> StatusEffectDefinition:
	return status_effects.get(id)

func get_enemy(id: String) -> EnemyDefinition:
	return enemies.get(id)

func get_stage(id: String) -> StageDefinition:
	return stages.get(id)

func get_banner(id: String) -> SummonBannerDefinition:
	return banners.get(id)

func get_default_banner() -> SummonBannerDefinition:
	return banners.values()[0] if not banners.is_empty() else null

## Stages triés par numéro.
func get_stages_sorted() -> Array:
	var arr := stages.values()
	arr.sort_custom(func(a, b): return a.numero < b.numero)
	return arr

func hero_skills(def: HeroDefinition) -> Array:
	var arr: Array = []
	for sid in def.skill_ids:
		arr.append(get_skill(sid))
	return arr
