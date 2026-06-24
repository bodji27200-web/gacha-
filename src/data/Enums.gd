class_name GameEnums
extends RefCounted
## Énumérations globales du jeu.
## Accessibles partout via GameEnums.Element.FEU, etc.

enum Element { FEU, EAU, NATURE }

enum Role { DEFENSEUR, ATTAQUANT, SOUTIEN, SOIGNEUR }

## Type de ciblage d'une compétence.
enum Target {
	ENEMY_ONE,      ## un ennemi
	ENEMY_ALL,      ## tous les ennemis
	ALLY_ONE,       ## un allié (peut être soi)
	ALLY_OTHER,     ## un allié différent de soi
	ALLY_ALL,       ## toute l'équipe (alliés vivants)
	ALLY_LOWEST,    ## allié au PV % le plus bas
	SELF,           ## soi-même
}

enum EffectType { BUFF, DEBUFF }

const ELEMENT_NAMES := {
	Element.FEU: "Feu",
	Element.EAU: "Eau",
	Element.NATURE: "Nature",
}

const ROLE_NAMES := {
	Role.DEFENSEUR: "Défenseur",
	Role.ATTAQUANT: "Attaquant",
	Role.SOUTIEN: "Soutien",
	Role.SOIGNEUR: "Soigneur",
}

## Couleurs associées aux éléments (UI). L'icône reste la source de vérité,
## la couleur n'est qu'un renfort visuel.
const ELEMENT_COLORS := {
	Element.FEU: Color("e8552d"),
	Element.EAU: Color("3a8ed6"),
	Element.NATURE: Color("57b34a"),
}

const ROLE_COLORS := {
	Role.DEFENSEUR: Color("c8a23a"),
	Role.ATTAQUANT: Color("d23f4a"),
	Role.SOUTIEN: Color("9b59b6"),
	Role.SOIGNEUR: Color("3fb98a"),
}

static func element_name(e: int) -> String:
	return ELEMENT_NAMES.get(e, "?")

static func role_name(r: int) -> String:
	return ROLE_NAMES.get(r, "?")

static func element_color(e: int) -> Color:
	return ELEMENT_COLORS.get(e, Color.WHITE)

static func role_color(r: int) -> Color:
	return ROLE_COLORS.get(r, Color.WHITE)

## Cycle élémentaire : retourne true si "attaquant" a l'avantage sur "cible".
## Feu > Nature > Eau > Feu.
static func has_element_advantage(attacker: int, defender: int) -> bool:
	match attacker:
		Element.FEU: return defender == Element.NATURE
		Element.NATURE: return defender == Element.EAU
		Element.EAU: return defender == Element.FEU
	return false

static func has_element_disadvantage(attacker: int, defender: int) -> bool:
	return has_element_advantage(defender, attacker)
