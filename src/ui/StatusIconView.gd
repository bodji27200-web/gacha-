class_name StatusIconView
extends Control
## Petite icône de statut avec infobulle (nom, durée, cumuls).

var inst: StatusEffectInstance

func setup(p_inst: StatusEffectInstance) -> void:
	inst = p_inst
	custom_minimum_size = Vector2(22, 22)
	var stack_txt := (" ×%d" % inst.stacks) if inst.stacks > 1 else ""
	var kind := "Buff" if not inst.def.is_debuff() else "Debuff"
	tooltip_text = "%s — %s%s\n%s\n%d tour(s) restant(s)" % [
		inst.def.nom, kind, stack_txt, inst.def.description, inst.remaining]
	queue_redraw()

func _draw() -> void:
	VisualKit.draw_status_icon(self, Rect2(Vector2.ZERO, size),
		inst.def.icon_key, inst.def.color, not inst.def.is_debuff())
	if inst.stacks > 1:
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(size.x - 8, size.y - 1), str(inst.stacks),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
