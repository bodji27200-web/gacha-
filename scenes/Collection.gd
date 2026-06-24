extends Control
## Collection : tous les héros possédés, avec filtres, tri et fiche détaillée.

var _grid: GridContainer
var _count_label: Label
var _filter_element := -1
var _filter_role := -1
var _filter_rarity := 0
var _favoris_only := false
var _sort := 0

func _ready() -> void:
	Style.apply(self)
	add_child(Style.bg_rect())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := ScreenHeader.new()
	header.setup("Collection")
	root.add_child(header)

	root.add_child(_filter_bar())

	_count_label = Style.label("", 13, Style.DIM)
	root.add_child(_count_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	if not GameState.collection_changed.is_connected(_refresh):
		GameState.collection_changed.connect(_refresh)
	_refresh()

func _filter_bar() -> PanelContainer:
	var panel := Style.panel(Style.PANEL)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 12)
	panel.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)

	var el := _option("Élément", ["Tous", "Feu", "Eau", "Nature"], func(i): _filter_element = i - 1; _refresh())
	h.add_child(el)
	var ro := _option("Rôle", ["Tous", "Défenseur", "Attaquant", "Soutien", "Soigneur"], func(i): _filter_role = i - 1; _refresh())
	h.add_child(ro)
	var ra := _option("Rareté", ["Toutes", "3★", "4★", "5★"], func(i): _filter_rarity = (i + 2) if i > 0 else 0; _refresh())
	h.add_child(ra)
	var so := _option("Tri", ["Puissance", "Niveau", "Rareté", "Nom", "Plus récent"], func(i): _sort = i; _refresh())
	h.add_child(so)

	h.add_child(Style.spacer())
	var fav := CheckButton.new()
	fav.text = "Favoris"
	fav.toggled.connect(func(on): _favoris_only = on; _refresh())
	h.add_child(fav)
	return panel

func _option(title: String, items: Array, cb: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(Style.label(title, 12, Style.DIM))
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_ALL
	for it in items:
		opt.add_item(it)
	opt.item_selected.connect(cb)
	v.add_child(opt)
	return v

func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var list: Array = []
	for inst in GameState.heroes:
		var def: HeroDefinition = DataRegistry.get_hero(inst.def_id)
		if _filter_element >= 0 and def.element != _filter_element:
			continue
		if _filter_role >= 0 and def.role != _filter_role:
			continue
		if _filter_rarity > 0 and def.rarete != _filter_rarity:
			continue
		if _favoris_only and not inst.favori:
			continue
		list.append(inst)

	list.sort_custom(_comparator)
	for inst in list:
		var card := HeroCard.new()
		card.setup(inst, 118)
		card.pressed.connect(func():
			AudioManager.play_sfx("click")
			var pop := HeroDetailPopup.new()
			pop.setup(inst)
			add_child(pop))
		_grid.add_child(card)

	_count_label.text = "%d héros affichés sur %d possédés" % [list.size(), GameState.heroes.size()]

func _comparator(a: HeroInstance, b: HeroInstance) -> bool:
	var da: HeroDefinition = DataRegistry.get_hero(a.def_id)
	var db: HeroDefinition = DataRegistry.get_hero(b.def_id)
	match _sort:
		0: return GameState.power(a) > GameState.power(b)
		1: return a.niveau > b.niveau
		2:
			if da.rarete != db.rarete:
				return da.rarete > db.rarete
			return GameState.power(a) > GameState.power(b)
		3: return da.nom.naturalnocasecmp_to(db.nom) < 0
		4: return a.ordre > b.ordre
	return GameState.power(a) > GameState.power(b)
