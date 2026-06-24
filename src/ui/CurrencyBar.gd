class_name CurrencyBar
extends PanelContainer
## Barre compacte : or, cristaux, niveau de compte. Se met à jour automatiquement.

var _gold: Label
var _cry: Label
var _acc: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", Style._sb(Style.PANEL2, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	add_child(h)

	_gold = Label.new()
	h.add_child(_make_pill("gold", _gold))
	_cry = Label.new()
	h.add_child(_make_pill("crystal", _cry))

	var accbox := HBoxContainer.new()
	accbox.add_theme_constant_override("separation", 6)
	var dot := Label.new()
	dot.text = "✦"
	dot.add_theme_color_override("font_color", Style.ACCENT2.lightened(0.2))
	_acc = Label.new()
	accbox.add_child(dot)
	accbox.add_child(_acc)
	h.add_child(accbox)

	if not GameState.currency_changed.is_connected(refresh):
		GameState.currency_changed.connect(refresh)
	refresh()

func _make_pill(kind: String, lbl: Label) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var icon := MiniIcon.new()
	icon.setup(kind)
	icon.custom_minimum_size = Vector2(22, 22)
	box.add_child(icon)
	lbl.add_theme_font_size_override("font_size", 18)
	box.add_child(lbl)
	return box

func refresh() -> void:
	if _gold:
		_gold.text = _fmt(GameState.or_montant)
	if _cry:
		_cry.text = _fmt(GameState.cristaux)
	if _acc:
		_acc.text = "Compte Nv %d" % GameState.account_level()

static func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = " " + out
	return out
