extends Node
## Sauvegarde locale versionnée (JSON dans user://, persistée en IndexedDB sur le Web).
## Sauvegarde principale + sauvegarde de secours, validation et migration.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.bak.json"
const TMP_PATH := "user://save.tmp.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var data := GameState.to_dict()
	var json := JSON.stringify(data, "  ")
	# Conserver l'ancienne sauvegarde en secours
	if FileAccess.file_exists(SAVE_PATH):
		var prev := FileAccess.get_file_as_string(SAVE_PATH)
		if prev != "":
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak:
				bak.store_string(prev)
				bak.close()
	# Écriture via fichier temporaire puis renommage (anti-corruption)
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Impossible d'écrire la sauvegarde.")
		return false
	f.store_string(json)
	f.close()
	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists("save.json"):
			dir.remove("save.json")
		dir.rename("save.tmp.json", "save.json")
	return true

func load_game() -> bool:
	var data := _read_json(SAVE_PATH)
	if data.is_empty():
		data = _read_json(BACKUP_PATH)
	if data.is_empty():
		return false
	data = _migrate(data)
	GameState.from_dict(data)
	return true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	if txt == "":
		return {}
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Sauvegarde illisible : %s" % path)
		return {}
	return parsed

## Migration des anciennes versions de sauvegarde.
func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	# v0 -> v1 : ajout des compteurs uid/ordre si absents (tolérance)
	if v < 1:
		if not data.has("next_uid"):
			data["next_uid"] = data.get("heroes", []).size() + 1
		if not data.has("next_ordre"):
			data["next_ordre"] = data.get("heroes", []).size()
		data["version"] = 1
	return data

func delete_save() -> void:
	for p in [SAVE_PATH, BACKUP_PATH, TMP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func autosave() -> void:
	save_game()
