extends Node
## Générateur aléatoire centralisé. Permet de fixer une seed pour les tests.
## Utilisé en injection par le combat et l'invocation (pas d'appel direct à randf() ailleurs).

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

## Fixe une seed déterministe (tests, mode dev).
func seed_with(s: int) -> void:
	rng.seed = s
	rng.state = s

func randomize_seed() -> void:
	rng.randomize()

func randf() -> float:
	return rng.randf()

func randf_range(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func randi_range(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func chance(p: float) -> bool:
	return rng.randf() < p

func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[rng.randi_range(0, arr.size() - 1)]

## Tirage pondéré. `items` et `weights` de même taille. Retourne un item.
func weighted_pick(items: Array, weights: Array):
	if items.is_empty():
		return null
	var total := 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return pick(items)
	var roll := rng.randf() * total
	var acc := 0.0
	for i in items.size():
		acc += float(weights[i])
		if roll < acc:
			return items[i]
	return items[items.size() - 1]
