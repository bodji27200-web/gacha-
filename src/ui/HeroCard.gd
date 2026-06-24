class_name HeroCard
extends Button
## Carte de héros cliquable (collection, équipe, menu).
## Affiche portrait, nom, élément, rôle, rareté, niveau, et statut favori.

var inst: HeroInstance
var portrait: PortraitView

func setup(p_inst: HeroInstance, card_w: float = 118.0) -> void:
	inst = p_inst
	text = ""
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(card_w, card_w + 50.0)
	add_theme_stylebox_override("normal", Style._sb(Style.PANEL2, 10))
	add_theme_stylebox_override("hover", Style._sb(Style.PANEL3, 10, Style.ACCENT, 2))
	add_theme_stylebox_override("pressed", Style._sb(Style.PANEL3, 10))
	add_theme_stylebox_override("focus", Style._sb(Color(0, 0, 0, 0), 10, Style.ACCENT, 2))

	var def: HeroDefinition = DataRegistry.get_hero(inst.def_id)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6; v.offset_top = 6; v.offset_right = -6; v.offset_bottom = -6
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	add_child(v)

	portrait = PortraitView.new()
	portrait.setup(_visual(def), def.element, def.rarete)
	portrait.custom_minimum_size = Vector2(card_w - 12, card_w - 12)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(portrait)

	var name_l := Style.label(def.nom, 16, Style.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	v.add_child(name_l)

	var info := Label.new()
	info.text = "%s · Nv %d" % [GameEnums.role_name(def.role), inst.niveau]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Style.DIM)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)

	if inst.favori:
		var fav := Label.new()
		fav.text = "★"
		fav.add_theme_color_override("font_color", Style.ACCENT)
		fav.position = Vector2(8, 4)
		fav.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fav)

static func _visual(def: HeroDefinition) -> Dictionary:
	return {
		"primary": def.primary_color, "secondary": def.secondary_color,
		"body": def.body_type, "weapon": def.weapon,
	}
