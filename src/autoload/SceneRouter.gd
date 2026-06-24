extends Node
## Navigation entre écrans avec un court fondu.

const MENU := "res://scenes/MainMenu.tscn"
const COLLECTION := "res://scenes/Collection.tscn"
const TEAM := "res://scenes/TeamBuilder.tscn"
const SUMMON := "res://scenes/Summon.tscn"
const STAGES := "res://scenes/StageSelect.tscn"
const BATTLE := "res://scenes/Battle.tscn"

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false

## Contexte transmis au combat (stage sélectionné).
var pending_stage_id: String = ""

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)

func goto(path: String) -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.18)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.18)
	await tw2.finished
	_busy = false

func goto_battle(stage_id: String) -> void:
	pending_stage_id = stage_id
	goto(BATTLE)
