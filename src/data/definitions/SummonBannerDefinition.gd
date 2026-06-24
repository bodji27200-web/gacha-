class_name SummonBannerDefinition
extends Resource
## Définition d'une bannière d'invocation.

@export var id: String = ""
@export var nom: String = ""
@export_multiline var description: String = ""
## Pool de héros par rareté : { 3: [ids], 4: [ids], 5: [ids] }
@export var pool: Dictionary = {}
## Probabilités par rareté : { 3: 0.75, 4: 0.22, 5: 0.03 } (somme = 1.0)
@export var rates: Dictionary = {}
@export var cost_single: int = 100
@export var cost_multi: int = 1000
@export var multi_count: int = 10
@export var currency: String = "cristaux"
@export var multi_min_rarity: int = 4       ## garantie du multi
@export var pity_threshold: int = 40        ## garantie 5★ après N tirages
@export var pity_rarity: int = 5

func rates_sum() -> float:
	var total := 0.0
	for r in rates.keys():
		total += float(rates[r])
	return total
