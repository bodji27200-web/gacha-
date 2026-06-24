class_name DevMenu
extends CanvasLayer
## Outils de développement — disponibles uniquement en build de debug.
## Ne pas afficher dans le build joueur (le menu vérifie OS.is_debug_build()).

func _init() -> void:
	layer = 70

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)

	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 20)
	panel.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	v.add_child(Style.title("Outils de développement", 24, Style.ACCENT2.lightened(0.3)))
	v.add_child(Style.label("Build de debug uniquement.", 12, Style.DIM))

	v.add_child(_btn("+1000 or", func(): GameState.add_currency(1000, 0)))
	v.add_child(_btn("+1000 cristaux", func(): GameState.add_currency(0, 1000)))
	v.add_child(_btn("Donner tous les héros manquants", _give_all))
	v.add_child(_btn("Équipe +5 niveaux", _level_team))
	v.add_child(_btn("Réinitialiser la sauvegarde de test", func():
		SaveManager.delete_save(); GameState.new_game(); SaveManager.save_game()
		SceneRouter.goto(SceneRouter.MENU)))

	# Seed RNG
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 8)
	var seed_edit := LineEdit.new()
	seed_edit.placeholder_text = "seed (entier)"
	seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(seed_edit)
	var seed_btn := Style.button("Fixer seed")
	seed_btn.pressed.connect(func():
		if seed_edit.text.is_valid_int():
			RNG.seed_with(seed_edit.text.to_int()))
	seed_row.add_child(seed_btn)
	v.add_child(seed_row)

	var close := Style.button("Fermer")
	close.pressed.connect(queue_free)
	v.add_child(close)

func _btn(text: String, cb: Callable) -> Button:
	var b := Style.button(text)
	b.pressed.connect(func():
		cb.call()
		AudioManager.play_sfx("click"))
	return b

func _give_all() -> void:
	for def in DataRegistry.heroes.values():
		if not GameState.owns_def(def.id):
			GameState.heroes.append(GameState._create_instance(def.id))
	GameState.collection_changed.emit()
	SaveManager.autosave()

func _level_team() -> void:
	for inst in GameState.team_instances():
		inst.niveau = mini(GameState.MAX_LEVEL, inst.niveau + 5)
	GameState.collection_changed.emit()
	SaveManager.autosave()
