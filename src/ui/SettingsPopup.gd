class_name SettingsPopup
extends CanvasLayer
## Fenêtre modale des paramètres (vitesse de combat, sons, musique, réinitialisation).

var _confirm_reset := false
var _reset_btn: Button

func _init() -> void:
	layer = 60

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			pass)  # clic dans le vide : ne ferme pas par sécurité
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 22)
	panel.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	v.add_child(Style.title("Paramètres", 28))

	# Vitesse de combat
	var speed_btn := Style.button("")
	_refresh_speed(speed_btn)
	speed_btn.pressed.connect(func():
		GameState.settings["combat_speed"] = 2 if int(GameState.settings.get("combat_speed", 1)) == 1 else 1
		_refresh_speed(speed_btn)
		SaveManager.autosave())
	v.add_child(_row("Vitesse de combat", speed_btn))

	# Effets sonores
	var sfx := CheckButton.new()
	sfx.button_pressed = GameState.settings.get("sfx", true)
	sfx.toggled.connect(func(on):
		GameState.settings["sfx"] = on
		if on: AudioManager.play_sfx("click")
		SaveManager.autosave())
	v.add_child(_row("Effets sonores", sfx))

	# Musique
	var mus := CheckButton.new()
	mus.button_pressed = GameState.settings.get("music", true)
	mus.toggled.connect(func(on):
		GameState.settings["music"] = on
		AudioManager.refresh_music_setting()
		SaveManager.autosave())
	v.add_child(_row("Musique d'ambiance", mus))

	v.add_child(_sep())

	# Réinitialisation de la sauvegarde
	_reset_btn = Style.button("Réinitialiser la sauvegarde")
	_reset_btn.add_theme_color_override("font_color", Style.DANGER)
	_reset_btn.pressed.connect(_on_reset)
	v.add_child(_reset_btn)

	v.add_child(Style.label("Toute la progression sera perdue.", 12, Style.DIM))
	v.add_child(_sep())

	var close := Style.button("Fermer")
	close.pressed.connect(func():
		AudioManager.play_sfx("click")
		queue_free())
	v.add_child(close)

func _refresh_speed(b: Button) -> void:
	b.text = "×%d" % int(GameState.settings.get("combat_speed", 1))

func _row(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := Style.label(text, 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(control)
	return h

func _sep() -> Control:
	var r := ColorRect.new()
	r.color = Style.PANEL3
	r.custom_minimum_size.y = 1
	return r

func _on_reset() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		_reset_btn.text = "Confirmer la réinitialisation ?"
		return
	SaveManager.delete_save()
	GameState.new_game()
	SaveManager.save_game()
	queue_free()
	SceneRouter.goto(SceneRouter.MENU)
