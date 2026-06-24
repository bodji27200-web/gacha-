class_name ScreenHeader
extends HBoxContainer
## En-tête commun des écrans : bouton retour + titre + ressources.

func setup(title_text: String, back_target: String = "") -> void:
	add_theme_constant_override("separation", 16)
	var back := Style.button("←  Retour")
	back.pressed.connect(func():
		AudioManager.play_sfx("click")
		if back_target != "":
			SceneRouter.goto(back_target)
		else:
			SceneRouter.goto(SceneRouter.MENU))
	add_child(back)
	var t := Style.title(title_text, 28)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(t)
	add_child(Style.spacer())
	var cb := CurrencyBar.new()
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(cb)
