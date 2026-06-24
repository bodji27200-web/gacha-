class_name DamageFormula
extends RefCounted
## Formule de dégâts centralisée et documentée.
##
## dégâts = ATQ_eff × multiplicateur_compétence × bonus_conditionnel
##          × (1 − DEF_eff / (DEF_eff + K))      ← réduction par la défense (K = 300)
##          × modificateur_élémentaire           ← 1.30 avantage / 0.75 désavantage / 1.0 neutre
##          × critique                           ← × dégâts_critiques si coup critique
##          × variation                          ← aléatoire léger 0.97..1.03
## Le résultat est arrondi et vaut au minimum 1.

const DEF_K := 300.0
const ELEM_ADVANTAGE := 1.30
const ELEM_DISADVANTAGE := 0.75
const VARIANCE_MIN := 0.97
const VARIANCE_MAX := 1.03
const ELEM_PRECISION_BONUS := 0.10   ## bonus d'application des debuffs en avantage élémentaire

## Retourne {amount:int, crit:bool, elem:"adv"/"dis"/"neutral"}.
static func compute(attacker: Combatant, defender: Combatant, skill: SkillDefinition,
		rng, mult_extra: float = 1.0) -> Dictionary:
	var atk := attacker.eff_stat("attaque")
	var dmg := atk * skill.power * mult_extra

	var dfn := defender.eff_stat("defense")
	dmg *= (1.0 - dfn / (dfn + DEF_K))

	var elem: int = skill.element if skill.element >= 0 else attacker.element
	var tag := "neutral"
	if GameEnums.has_element_advantage(elem, defender.element):
		dmg *= ELEM_ADVANTAGE
		tag = "adv"
	elif GameEnums.has_element_disadvantage(elem, defender.element):
		dmg *= ELEM_DISADVANTAGE
		tag = "dis"

	var crit: bool = rng.chance(clampf(attacker.eff_stat("crit_taux"), 0.0, 1.0))
	if crit:
		dmg *= maxf(1.0, attacker.eff_stat("crit_degats"))

	dmg *= rng.randf_range(VARIANCE_MIN, VARIANCE_MAX)
	return {"amount": int(maxf(1.0, round(dmg))), "crit": crit, "elem": tag}

## Probabilité finale d'appliquer un debuff (bornée pour éviter 0 %/100 % permanents).
static func debuff_chance(base: float, attacker: Combatant, defender: Combatant, advantage: bool) -> float:
	if base >= 1.0:
		return 1.0   # explicitement garanti
	var c := base + attacker.eff_stat("precision") - defender.eff_stat("resistance")
	if advantage:
		c += ELEM_PRECISION_BONUS
	return clampf(c, 0.05, 0.95)
