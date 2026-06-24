class_name PortraitView
extends Control
## Affiche un portrait procédural + bordure de rareté + icône d'élément + étoiles.

var visual: Dictionary = {}
var element: int = GameEnums.Element.FEU
var rarity: int = 3
var show_stars: bool = true
var show_element: bool = true

func setup(p_visual: Dictionary, p_element: int, p_rarity: int) -> void:
	visual = p_visual
	element = p_element
	rarity = p_rarity
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	VisualKit.draw_portrait(self, rect, visual)
	var rc := VisualKit.rarity_color(rarity)
	draw_rect(rect, rc, false, 3.0)
	if show_element:
		var es: float = clampf(size.x * 0.22, 18.0, 30.0)
		VisualKit.draw_element_icon(self, Rect2(Vector2(size.x - es - 4, 4), Vector2(es, es)), element)
	if show_stars:
		var ss: float = clampf(size.x * 0.11, 9.0, 16.0)
		VisualKit.draw_stars(self, Vector2(6, size.y - ss - 5), rarity, ss, rc)
