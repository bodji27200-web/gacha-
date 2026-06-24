extends Control
## Invocation : bannière permanente, taux affichés, pitié, animations.

var _banner: SummonBannerDefinition
var _content: VBoxContainer
var _hint: Label
var _played_once := false

func _ready() -> void:
	Style.apply(self)
	add_child(Style.bg_rect())
	_banner = DataRegistry.get_default_banner()
	_played_once = GameState.total_summons > 0

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var header := ScreenHeader.new()
	header.setup("Invocation")
	root.add_child(header)

	_hint = Style.label("", 14, Style.DANGER)
	root.add_child(_hint)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	if not GameState.currency_changed.is_connected(_refresh):
		GameState.currency_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()

	# Bannière
	var panel := Style.panel(Style.PANEL)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 20)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(Style.title(_banner.nom, 28, Style.ACCENT))
	v.add_child(Style.label(_banner.description, 14, Style.DIM))

	# Taux
	var rates := HBoxContainer.new()
	rates.add_theme_constant_override("separation", 12)
	rates.add_child(_rate_chip(5, _banner.rates.get(5, 0.0)))
	rates.add_child(_rate_chip(4, _banner.rates.get(4, 0.0)))
	rates.add_child(_rate_chip(3, _banner.rates.get(3, 0.0)))
	v.add_child(rates)

	# Pool
	for rar in [5, 4, 3]:
		var names: Array = []
		for did in _banner.pool.get(rar, []):
			names.append(DataRegistry.get_hero(did).nom)
		v.add_child(Style.label("%d★ : %s" % [rar, ", ".join(names)], 13, VisualKit.rarity_color(rar)))

	# Pitié
	var remaining: int = maxi(0, _banner.pity_threshold - GameState.pity_counter)
	v.add_child(Style.label("Pitié : 5★ garanti dans %d invocation(s). Tirages effectués : %d."
		% [remaining, GameState.total_summons], 14, Style.ACCENT2.lightened(0.2)))
	_content.add_child(panel)

	# Boutons d'invocation
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER

	if not GameState.first_summon_done:
		var free := _summon_button("Invocation gratuite", "Offerte · héros garanti", Style.OK)
		free.pressed.connect(func(): _do_single(true))
		actions.add_child(free)

	var single := _summon_button("Invocation ×1", "%d cristaux" % _banner.cost_single, Style.ACCENT2)
	single.disabled = GameState.cristaux < _banner.cost_single
	single.pressed.connect(func(): _do_single(false))
	actions.add_child(single)

	var sub := "%d cristaux · 4★ garanti" % _banner.cost_multi
	var multi := _summon_button("Invocation ×10", sub, Style.ACCENT)
	multi.disabled = GameState.cristaux < _banner.cost_multi
	multi.pressed.connect(_do_multi)
	actions.add_child(multi)

	_content.add_child(actions)
	_content.add_child(Style.label(
		"Les doublons sont convertis en fragments (3★ : 10, 4★ : 20, 5★ : 40), utilisables en phase 2.",
		13, Style.DIM))

func _summon_button(title: String, subtitle: String, col: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(240, 84)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", Style._sb(col.darkened(0.35), 10, col, 2))
	b.add_theme_stylebox_override("hover", Style._sb(col.darkened(0.2), 10, col.lightened(0.2), 3))
	b.add_theme_stylebox_override("pressed", Style._sb(col.darkened(0.1), 10))
	b.add_theme_stylebox_override("disabled", Style._sb(Style.PANEL.darkened(0.2), 10))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tl := Style.label(title, 20, Color.WHITE)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sl := Style.label(subtitle, 13, Color(1, 1, 1, 0.8))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	v.add_child(sl)
	b.add_child(v)
	return b

func _do_single(free: bool) -> void:
	if not free and not GameState.spend_cristaux(_banner.cost_single):
		_flash("Pas assez de cristaux.")
		return
	AudioManager.play_sfx("click")
	var res := GameState.summon_single(free)
	SaveManager.autosave()
	_play([res])

func _do_multi() -> void:
	if not GameState.spend_cristaux(_banner.cost_multi):
		_flash("Pas assez de cristaux.")
		return
	AudioManager.play_sfx("click")
	var res := GameState.summon_multi()
	SaveManager.autosave()
	_play(res)

func _play(results: Array) -> void:
	var ov := SummonOverlay.new()
	ov.setup(results, _played_once)
	ov.closed.connect(_refresh)
	add_child(ov)
	_played_once = true

func _rate_chip(rarity: int, rate: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Style._sb(VisualKit.rarity_color(rarity).darkened(0.2), 8))
	var l := Style.label("%d★  %.0f %%" % [rarity, rate * 100.0], 16, Color.WHITE)
	p.add_child(l)
	return p

func _flash(text: String) -> void:
	_hint.text = text
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(_hint):
		_hint.text = ""
