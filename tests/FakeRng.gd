class_name FakeRng
extends RefCounted
## RNG déterministe pour les tests. `value` ∈ [0,1] pilote tous les tirages.
##  value = 0.0  -> tirages "bas" (premier item, pas de critique, variance min)
##  value = 0.5  -> milieu (variance neutre = 1.0)

var value := 0.5

func with_value(v: float) -> FakeRng:
	value = v
	return self

func randf() -> float:
	return value

func randf_range(a: float, b: float) -> float:
	return lerpf(a, b, value)

func randi_range(a: int, b: int) -> int:
	return a + int(round((b - a) * value))

func chance(p: float) -> bool:
	return value < p

func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[clampi(int(value * arr.size()), 0, arr.size() - 1)]

func weighted_pick(items: Array, weights: Array):
	if items.is_empty():
		return null
	var total := 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return pick(items)
	var roll := value * total
	var acc := 0.0
	for i in items.size():
		acc += float(weights[i])
		if roll < acc:
			return items[i]
	return items[items.size() - 1]
