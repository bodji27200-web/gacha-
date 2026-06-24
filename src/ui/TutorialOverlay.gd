class_name TutorialOverlay
extends CanvasLayer
## Tutoriel court affiché une seule fois (premier stage). Explique les bases.

signal closed

var _index := 0
var _title: Label
var _body: Label
var _next: Button

const PAGES := [
	["Jauge de tour", "Chaque unité remplit une jauge selon sa Vitesse. Lorsqu'elle atteint 100, l'unité agit. La barre en haut montre l'ordre des prochains tours."],
	["Choisir une compétence", "À votre tour, choisissez l'une des trois compétences en bas de l'écran. Une compétence en recharge est grisée avec le nombre de tours restants."],
	["Choisir une cible", "Les cibles valides sont mises en surbrillance. Cliquez la cible souhaitée. Vous pouvez annuler avant de valider."],
	["Avantage élémentaire", "Feu > Nature > Eau > Feu. Attaquer en avantage inflige plus de dégâts ; en désavantage, moins. L'icône d'élément est affichée sur chaque unité."],
	["Buffs, debuffs et recharges", "Les icônes au-dessus des unités indiquent buffs et debuffs (survolez-les). Brûlure et poison infligent des dégâts dans le temps ; gel et étourdissement empêchent d'agir."],
]

func _init() -> void:
	layer = 55

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel(Style.PANEL)
	panel.theme = Style.theme()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 24)
	panel.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	v.add_child(Style.label("Tutoriel", 13, Style.DIM))
	_title = Style.title("", 26)
	v.add_child(_title)
	_body = Style.label("", 16, Style.TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(512, 90)
	v.add_child(_body)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var skip := Style.button("Passer le tutoriel")
	skip.pressed.connect(_finish)
	row.add_child(skip)
	row.add_child(Style.spacer())
	_next = Style.button("Suivant  →", Vector2(150, 0))
	_next.pressed.connect(_advance)
	row.add_child(_next)
	v.add_child(row)

	_show_page()

func _show_page() -> void:
	_title.text = PAGES[_index][0]
	_body.text = PAGES[_index][1]
	_next.text = "Compris  ✓" if _index == PAGES.size() - 1 else "Suivant  →"

func _advance() -> void:
	AudioManager.play_sfx("click")
	_index += 1
	if _index >= PAGES.size():
		_finish()
	else:
		_show_page()

func _finish() -> void:
	closed.emit()
	queue_free()
