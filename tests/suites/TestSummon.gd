class_name TestSummon
extends RefCounted
## Invocation : première gratuite, garantie x10, pitié, doublons → fragments.

static func run(t: Tester) -> void:
	t.section("Invocation")
	GameState.registry = DataRegistry

	# Première invocation gratuite : héros nouveau, différent des héros de départ
	GameState.rng = FakeRng.new().with_value(0.0)
	GameState.new_game()
	var res := GameState.summon_single(true)
	t.ok(res.is_new, "première invocation = nouveau héros")
	t.bad(res.def_id in GameState.STARTERS, "héros différent des héros de départ")

	# Pitié : 39 tirages sans 5★, 40e garanti 5★, puis remise à zéro
	GameState.new_game()
	GameState.rng = FakeRng.new().with_value(0.0)   # toujours la rareté la plus basse
	var got5 := false
	for i in range(39):
		if GameState.summon_single(false).rarity == 5:
			got5 = true
	t.bad(got5, "aucun 5★ sur 39 tirages (value 0)")
	t.eq(GameState.pity_counter, 39, "compteur de pitié = 39")
	var p40 := GameState.summon_single(false)
	t.eq(p40.rarity, 5, "40e tirage garanti 5★ (pitié)")
	t.eq(GameState.pity_counter, 0, "pitié remise à zéro après un 5★")

	# Garantie du x10 : au moins un 4★ ou plus
	GameState.new_game()
	GameState.rng = FakeRng.new().with_value(0.0)
	var multi := GameState.summon_multi()
	t.eq(multi.size(), 10, "x10 produit 10 résultats")
	var has4 := false
	for m in multi:
		if m.rarity >= 4:
			has4 = true
	t.ok(has4, "le x10 garantit au moins un 4★")

	# Doublon → fragments, stockés sur l'exemplaire
	GameState.new_game()
	GameState.rng = FakeRng.new().with_value(0.0)   # rareté 3 -> premier 3★ = kaelen (possédé)
	var dup := GameState.summon_single(false)
	t.bad(dup.is_new, "héros déjà possédé n'est pas nouveau")
	t.eq(dup.fragments, 10, "doublon 3★ = 10 fragments")
	t.eq(GameState.get_instance_by_def(dup.def_id).fragments, 10, "fragments stockés sur l'exemplaire")

	# Restaure un RNG normal pour la suite
	GameState.rng = RNG
