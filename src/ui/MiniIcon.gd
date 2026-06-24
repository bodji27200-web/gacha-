class_name MiniIcon
extends Control
## Petite icône vectorielle (or, cristal, fragment).

var kind := "gold"

func setup(k: String) -> void:
	kind = k
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var c := size * 0.5
	var r: float = minf(size.x, size.y) * 0.42
	match kind:
		"gold":
			draw_circle(c, r, Style.GOLD)
			draw_circle(c, r, Style.GOLD.darkened(0.3), false, 2.0)
			draw_circle(c, r * 0.45, Style.GOLD.lightened(0.3))
		"crystal":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.75, 0),
				c + Vector2(0, r), c + Vector2(-r * 0.75, 0)]), Style.CRYSTAL)
			draw_line(c + Vector2(0, -r), c + Vector2(0, r), Color(1, 1, 1, 0.6), 1.0)
		"fragment":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r, -r * 0.4), c + Vector2(r * 0.5, -r),
				c + Vector2(r, r * 0.5), c + Vector2(-r * 0.3, r)]), Color("c89bf0"))
