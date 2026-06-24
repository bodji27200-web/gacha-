class_name HeroInstance
extends Resource
## Exemplaire d'un héros possédé par le joueur (données propres au joueur).
## Ne contient JAMAIS les définitions : seulement un identifiant + l'état joueur.

@export var uid: String = ""                ## identifiant unique de l'exemplaire
@export var def_id: String = ""             ## référence vers HeroDefinition
@export var niveau: int = 1
@export var exp: int = 0
@export var fragments: int = 0              ## fragments de CE héros (issus des doublons)
@export var favori: bool = false            ## verrouillage favori
@export var ordre: int = 0                  ## ordre d'obtention

static func create(p_uid: String, p_def_id: String, p_ordre: int) -> HeroInstance:
	var h := HeroInstance.new()
	h.uid = p_uid
	h.def_id = p_def_id
	h.ordre = p_ordre
	h.niveau = 1
	h.exp = 0
	return h

func to_dict() -> Dictionary:
	return {
		"uid": uid,
		"def_id": def_id,
		"niveau": niveau,
		"exp": exp,
		"fragments": fragments,
		"favori": favori,
		"ordre": ordre,
	}

static func from_dict(d: Dictionary) -> HeroInstance:
	var h := HeroInstance.new()
	h.uid = String(d.get("uid", ""))
	h.def_id = String(d.get("def_id", ""))
	h.niveau = int(d.get("niveau", 1))
	h.exp = int(d.get("exp", 0))
	h.fragments = int(d.get("fragments", 0))
	h.favori = bool(d.get("favori", false))
	h.ordre = int(d.get("ordre", 0))
	return h
