class_name BannersData
extends RefCounted
## Bannière permanente du prototype.

static func build() -> Array:
	var b := SummonBannerDefinition.new()
	b.id = "proto_banner"
	b.nom = "Portail des Origines"
	b.description = "Bannière permanente du prototype. Tous les héros y sont disponibles."
	b.pool = {
		3: ["kaelen", "neria", "elyra"],
		4: ["brask", "selka"],
		5: ["vaeron"],
	}
	b.rates = {3: 0.75, 4: 0.22, 5: 0.03}
	b.cost_single = 100
	b.cost_multi = 1000
	b.multi_count = 10
	b.currency = "cristaux"
	b.multi_min_rarity = 4
	b.pity_threshold = 40
	b.pity_rarity = 5
	return [b]

## Valeurs de conversion des doublons en fragments (par rareté).
const DUP_FRAGMENTS := {3: 10, 4: 20, 5: 40}
