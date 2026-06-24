class_name FigureView
extends Control
## Affiche un sprite de combat procédural complet (fiche héros, résultat d'invocation).

var visual: Dictionary = {}
var facing: int = 1
var swing: float = 0.0
var _bg := true

func setup(p_visual: Dictionary, p_facing: int = 1, bg: bool = true) -> void:
	visual = p_visual
	facing = p_facing
	_bg = bg
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if _bg:
		var rc := Rect2(Vector2.ZERO, size)
		draw_rect(rc, Style.PANEL.darkened(0.2))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.55)),
			visual.get("primary", Style.PANEL).darkened(0.5))
	var inset := Rect2(size.x * 0.18, size.y * 0.08, size.x * 0.64, size.y * 0.88)
	VisualKit.draw_figure(self, inset, visual, facing, swing)
