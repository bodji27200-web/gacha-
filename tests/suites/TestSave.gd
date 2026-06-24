class_name TestSave
extends RefCounted
## Sauvegarde / chargement, persistance de l'équipe et des fragments, migration.

static func run(t: Tester) -> void:
	t.section("Sauvegarde")
	GameState.registry = DataRegistry
	GameState.rng = RNG

	GameState.new_game()
	GameState.add_currency(500, 50)
	var k: HeroInstance = GameState.get_instance_by_def("kaelen")
	GameState.add_xp(k, 500)
	k.fragments = 15
	k.favori = true
	GameState.set_team_slot(0, GameState.get_instance_by_def("neria").uid)

	var saved_cristaux := GameState.cristaux
	var saved_count := GameState.heroes.size()
	var saved_team := GameState.team.duplicate()
	var saved_level := k.niveau
	t.ok(SaveManager.save_game(), "écriture de la sauvegarde")

	# Réinitialise puis recharge
	GameState.new_game()
	t.ok(SaveManager.load_game(), "chargement de la sauvegarde")
	t.eq(GameState.cristaux, saved_cristaux, "cristaux restaurés")
	t.eq(GameState.heroes.size(), saved_count, "nombre de héros restauré")
	t.eq(GameState.team, saved_team, "équipe restaurée")
	var k2: HeroInstance = GameState.get_instance_by_def("kaelen")
	t.eq(k2.niveau, saved_level, "niveau restauré")
	t.eq(k2.fragments, 15, "fragments restaurés")
	t.ok(k2.favori, "favori restauré")

	# Migration d'une ancienne sauvegarde (sans version)
	t.section("Migration")
	var old := {
		"or": 10, "cristaux": 20,
		"heroes": [{"uid": "x", "def_id": "kaelen", "niveau": 3}],
		"team": ["x", "", "", ""],
	}
	var migrated := SaveManager._migrate(old.duplicate(true))
	t.eq(migrated.get("version", 0), 1, "la migration ajoute la version 1")
	GameState.from_dict(migrated)
	t.eq(GameState.cristaux, 20, "ancienne sauvegarde chargée")
	t.eq(GameState.get_instance_by_def("kaelen").niveau, 3, "héros d'ancienne sauvegarde restauré")

	SaveManager.delete_save()
