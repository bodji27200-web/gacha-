extends Node
## Point d'entrée : charge la sauvegarde (ou crée une nouvelle partie) puis ouvre le menu.

func _ready() -> void:
	DataRegistry.load_all()
	if SaveManager.has_save():
		if not SaveManager.load_game():
			GameState.new_game()
			SaveManager.save_game()
	else:
		GameState.new_game()
		SaveManager.save_game()

	print("[BOOT] Données chargées — héros:%d ennemis:%d stages:%d compétences:%d statuts:%d" % [
		DataRegistry.heroes.size(), DataRegistry.enemies.size(), DataRegistry.stages.size(),
		DataRegistry.skills.size(), DataRegistry.status_effects.size()])
	print("[BOOT] Joueur — or:%d cristaux:%d héros possédés:%d" % [
		GameState.or_montant, GameState.cristaux, GameState.heroes.size()])

	# En mode validation (--quit-after), on n'enchaîne pas sur l'UI.
	if "--check-only" in OS.get_cmdline_user_args():
		return
	SceneRouter.goto(SceneRouter.MENU)
