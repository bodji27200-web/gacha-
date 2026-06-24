class_name CreatureKit3D
extends RefCounted
## Associe chaque définition (héros / ennemi) à une espèce de créature 3D + couleurs.
## Permet de remplacer l'apparence sans toucher à la logique (id internes conservés).

const KITS := {
	# --- Héros (noms affichés : Cendrak, Ferrum, Nyméa, Cryalis, Sylvara, Nocteris) ---
	"kaelen": {"species": "drakelin", "primary": Color("c0392b"), "secondary": Color("2c1410"), "glow": Color("ff9a3c"), "name": "Cendrak"},
	"brask": {"species": "armor", "primary": Color("a86b3a"), "secondary": Color("2a2a32"), "glow": Color("ff8a3c"), "name": "Ferrum"},
	"neria": {"species": "imp", "primary": Color("3a8ed6"), "secondary": Color("123048"), "glow": Color("bfe8ff"), "name": "Nyméa"},
	"selka": {"species": "armor", "primary": Color("2f9fb0"), "secondary": Color("13343a"), "glow": Color("bff0ff"), "name": "Cryalis"},
	"elyra": {"species": "drakelin", "primary": Color("57b34a"), "secondary": Color("1c2e16"), "glow": Color("d8f0a0"), "name": "Sylvara"},
	"vaeron": {"species": "imp", "primary": Color("4a2f6a"), "secondary": Color("0e0a16"), "glow": Color("b07aff"), "name": "Nocteris"},
	# --- Ennemis ---
	"ember_grunt": {"species": "imp", "primary": Color("8a2d22"), "secondary": Color("1a0e0a"), "glow": Color("ff7a3c")},
	"ember_acolyte": {"species": "imp", "primary": Color("9a5a2a"), "secondary": Color("241408"), "glow": Color("ffb45a")},
	"cinder_servant": {"species": "drakelin", "primary": Color("5a2d2a"), "secondary": Color("160a0a"), "glow": Color("ff6a3c")},
	"ash_attacker": {"species": "imp", "primary": Color("c75a2d"), "secondary": Color("2a1812"), "glow": Color("ff8a3c")},
	"ash_defender": {"species": "armor", "primary": Color("8a5a3a"), "secondary": Color("2a2a30"), "glow": Color("ffae6a")},
	"thorn_stalker": {"species": "drakelin", "primary": Color("4f8a3a"), "secondary": Color("16240f"), "glow": Color("baf07a")},
	"gardien_cendres": {"species": "armor", "primary": Color("8a3a22"), "secondary": Color("1a0c08"), "glow": Color("ff7a30")},
}

static func for_def(def_id: String, element: int) -> Dictionary:
	if KITS.has(def_id):
		return KITS[def_id]
	# repli par élément
	var col: Color = GameEnums.element_color(element)
	var species := "drakelin" if element == GameEnums.Element.FEU else "imp"
	return {"species": species, "primary": col, "secondary": col.darkened(0.6), "glow": col.lightened(0.3)}

static func display_name(def_id: String, fallback: String) -> String:
	if KITS.has(def_id) and KITS[def_id].has("name"):
		return KITS[def_id]["name"]
	return fallback
