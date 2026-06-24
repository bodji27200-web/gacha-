extends Node
## Smoke test d'interface : instancie chaque écran en headless pour vérifier
## qu'aucune erreur runtime ne survient à la construction.
## Lancement : godot --headless res://tests/UISmoke.tscn

func _ready() -> void:
	DataRegistry.load_all()
	GameState.new_game()
	GameState.tutorial_done = true
	SceneRouter.pending_stage_id = "1-2"

	for p in ["res://scenes/MainMenu.tscn", "res://scenes/StageSelect.tscn",
			"res://scenes/TeamBuilder.tscn", "res://scenes/Collection.tscn",
			"res://scenes/Summon.tscn"]:
		var inst: Node = load(p).instantiate()
		add_child(inst)
		print("[UISMOKE] ouvert ", p)
		await get_tree().process_frame
		await get_tree().process_frame
		inst.queue_free()
		await get_tree().process_frame

	# Battle : on le laisse démarrer puis on quitte proprement (timers en cours)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	print("[UISMOKE] ouvert res://scenes/Battle.tscn")
	await get_tree().create_timer(0.6).timeout
	print("[UISMOKE] terminé sans erreur")
	get_tree().quit(0)
