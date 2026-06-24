class_name TestSmoke
extends RefCounted
## Smoke test : menu → équipe → stage 1-1 → victoire → récompense →
## invocation → collection → sauvegarde → rechargement.

static func run(t: Tester) -> void:
	t.section("Smoke (boucle complète)")
	GameState.registry = DataRegistry
	GameState.rng = RNG

	GameState.new_game()
	t.eq(GameState.heroes.size(), 4, "4 héros de départ offerts")
	t.ok(GameState.team_is_valid(), "équipe de départ valide")

	# Combat du stage 1-1 (auto-piloté)
	var eng := TUtil.auto_battle(GameState.team_instances(),
		DataRegistry.get_stage("1-1").enemy_ids, FakeRng.new().with_value(0.5))
	t.ok(eng.finished, "le combat 1-1 se termine")
	t.eq(eng.result, "victory", "victoire au stage 1-1")

	# Récompense
	var before := GameState.cristaux
	GameState.grant_stage_rewards(DataRegistry.get_stage("1-1"), GameState.team)
	t.gt(GameState.cristaux, before, "des cristaux sont gagnés")

	# Invocation + collection
	GameState.rng = FakeRng.new().with_value(0.0)
	var count0 := GameState.heroes.size()
	var pull := GameState.summon_single(true)
	t.ok(pull.is_new or pull.fragments > 0, "l'invocation donne un héros ou des fragments")
	if pull.is_new:
		t.eq(GameState.heroes.size(), count0 + 1, "la collection augmente d'un héros")

	# Sauvegarde puis rechargement
	GameState.rng = RNG
	t.ok(SaveManager.save_game(), "sauvegarde de la partie")
	var crystals := GameState.cristaux
	var heroes := GameState.heroes.size()
	GameState.new_game()
	t.ok(SaveManager.load_game(), "rechargement de la partie")
	t.eq(GameState.cristaux, crystals, "cristaux persistés après rechargement")
	t.eq(GameState.heroes.size(), heroes, "héros persistés après rechargement")

	SaveManager.delete_save()
