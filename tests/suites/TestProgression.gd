class_name TestProgression
extends RefCounted
## Expérience, montée de niveau, plafond, et récompenses de stage.

static func run(t: Tester) -> void:
	t.section("Progression")
	GameState.registry = DataRegistry
	GameState.rng = RNG

	GameState.new_game()
	var k: HeroInstance = GameState.get_instance_by_def("kaelen")
	var lv0 := k.niveau
	var r := GameState.add_xp(k, 1000)
	t.gt(k.niveau, lv0, "le héros monte de niveau avec de l'XP")
	t.ok(r.leveled, "le résultat indique une montée de niveau")
	t.gt(r.gains.pv, 0.0, "des PV sont gagnés à la montée de niveau")

	# Plafond niveau 20
	k.niveau = GameState.MAX_LEVEL
	k.exp = 0
	GameState.add_xp(k, 999999)
	t.eq(k.niveau, GameState.MAX_LEVEL, "niveau plafonné à 20")

	# Récompenses de stage + première victoire unique
	t.section("Récompenses")
	GameState.new_game()
	var team_uids := GameState.team.duplicate()
	var cr0 := GameState.cristaux
	var st: StageDefinition = DataRegistry.get_stage("1-1")
	var rr := GameState.grant_stage_rewards(st, team_uids)
	t.ok(rr.first, "première victoire détectée")
	t.eq(GameState.cristaux, cr0 + st.reward_cristaux + st.first_cristaux, "bonus de première victoire ajouté")
	t.ok(GameState.stages_cleared.has("1-1"), "stage marqué comme terminé")
	var cr1 := GameState.cristaux
	var rr2 := GameState.grant_stage_rewards(st, team_uids)
	t.bad(rr2.first, "plus de bonus de première victoire la 2e fois")
	t.eq(GameState.cristaux, cr1 + st.reward_cristaux, "récompense normale uniquement ensuite")
