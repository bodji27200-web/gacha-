class_name TestCombat
extends RefCounted
## Tests du moteur de combat (formule, éléments, statuts, jauge, boss, fin de combat).

const FEU := GameEnums.Element.FEU
const EAU := GameEnums.Element.EAU
const NATURE := GameEnums.Element.NATURE

static func _basic_skill() -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = "_test_hit"
	s.power = 1.0
	s.hits = 1
	s.element = -1
	s.target = GameEnums.Target.ENEMY_ONE
	return s

static func run(t: Tester) -> void:
	_test_formula(t)
	_test_status(t)
	_test_gauge_cooldown(t)
	_test_dot_heal_shield(t)
	_test_boss_and_outcome(t)

# --------------------------------------------------------------------
static func _test_formula(t: Tester) -> void:
	t.section("Combat — formule & éléments")
	var fr := FakeRng.new().with_value(0.5)   # variance = 1.0, pas de critique si crit_taux bas
	var sk := _basic_skill()
	var atk := Stats.make(1000, 200, 100, 100, 0.0, 1.5, 0.0, 0.0)
	var A := TUtil.mkc("A", FEU, atk, 0, "ally")
	var dfn := Stats.make(5000, 100, 100, 100, 0.0, 1.5, 0.0, 0.0)
	var Bn := TUtil.mkc("Bn", NATURE, dfn, 100, "enemy")   # avantage Feu>Nature
	var Bf := TUtil.mkc("Bf", FEU, dfn, 101, "enemy")      # neutre
	var Be := TUtil.mkc("Be", EAU, dfn, 102, "enemy")      # désavantage

	var r_adv := DamageFormula.compute(A, Bn, sk, fr)
	var r_neu := DamageFormula.compute(A, Bf, sk, fr)
	var r_dis := DamageFormula.compute(A, Be, sk, fr)
	t.gt(r_adv.amount, r_neu.amount, "avantage élémentaire > neutre")
	t.lt(r_dis.amount, r_neu.amount, "désavantage élémentaire < neutre")
	t.eq(r_adv.elem, "adv", "tag avantage correct")
	t.eq(r_dis.elem, "dis", "tag désavantage correct")

	# Défense
	var dlow := TUtil.mkc("L", FEU, Stats.make(5000, 100, 50, 100, 0, 1.5, 0, 0), 103, "enemy")
	var dhigh := TUtil.mkc("H", FEU, Stats.make(5000, 100, 400, 100, 0, 1.5, 0, 0), 104, "enemy")
	t.gt(DamageFormula.compute(A, dlow, sk, fr).amount, DamageFormula.compute(A, dhigh, sk, fr).amount,
		"plus de défense réduit les dégâts")

	# Critique
	var critAtk := Stats.make(1000, 200, 100, 100, 1.0, 2.0, 0, 0)
	var Ac := TUtil.mkc("Ac", FEU, critAtk, 5, "ally")
	var rc := DamageFormula.compute(Ac, Bf, sk, fr)
	var rn := DamageFormula.compute(A, Bf, sk, fr)
	t.ok(rc.crit, "critique déclenché (crit_taux 100 %)")
	t.gt(rc.amount, rn.amount, "le critique inflige davantage")

	# Probabilité de debuff (fonction pure, bornée)
	t.approx(DamageFormula.debuff_chance(1.0, A, Bf, false), 1.0, 0.001, "chance garantie reste 100 %")
	t.approx(DamageFormula.debuff_chance(0.5, A, Bf, false), 0.5, 0.001, "chance de base 50 %")
	var Bres := TUtil.mkc("R", FEU, Stats.make(5000, 100, 100, 100, 0, 1.5, 0, 0.5), 106, "enemy")
	t.approx(DamageFormula.debuff_chance(0.5, A, Bres, false), 0.05, 0.001, "résistance plafonne à 5 %")
	var Aprec := TUtil.mkc("P", FEU, Stats.make(1000, 200, 100, 100, 0, 1.5, 0.6, 0), 6, "ally")
	t.approx(DamageFormula.debuff_chance(0.5, Aprec, Bf, false), 0.95, 0.001, "précision plafonne à 95 %")
	t.approx(DamageFormula.debuff_chance(0.5, A, Bf, true), 0.6, 0.001, "avantage élémentaire ajoute 0.10")

# --------------------------------------------------------------------
static func _test_status(t: Tester) -> void:
	t.section("Combat — buffs & debuffs")
	var caster := TUtil.mkc("C", FEU, Stats.make(1000, 200, 100, 100, 0, 1.5, 0.0, 0), 0, "ally")

	# Application réussie (value 0 -> chance(p) vraie)
	var eng := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var victim := TUtil.mkc("V", NATURE, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 100, "enemy")
	eng.allies = [caster]; eng.enemies = [victim]; eng.all = [caster, victim]; eng.turn_count = 1
	eng._apply_status(caster, victim, "def_down", 0.5, 2)
	t.ok(victim.has_status("def_down"), "debuff appliqué quand la chance passe")

	# Résistance bloque (chance plafonnée à 5 %, roll 0.5)
	var eng2 := TUtil.mkengine(FakeRng.new().with_value(0.5))
	var v2 := TUtil.mkc("V2", NATURE, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 1.0), 100, "enemy")
	eng2.allies = [caster]; eng2.enemies = [v2]; eng2.all = [caster, v2]; eng2.turn_count = 1
	eng2._apply_status(caster, v2, "def_down", 0.5, 2)
	t.bad(v2.has_status("def_down"), "résistance bloque le debuff")

	# Buff modifie la stat puis expire proprement (avec délai de grâce)
	var eng3 := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var u := TUtil.mkc("U", FEU, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	eng3.allies = [u]; eng3.enemies = []; eng3.all = [u]; eng3.turn_count = 5
	eng3._apply_status(u, u, "atk_up", 1.0, 2)
	t.approx(u.eff_stat("attaque"), 150.0, 0.5, "atk_up applique +50 %")
	eng3._end_turn(u, "")
	t.ok(u.has_status("atk_up"), "pas de décrément le tour d'application (grâce)")
	eng3.turn_count = 6; eng3._end_turn(u, "")
	t.ok(u.has_status("atk_up"), "buff encore actif (durée 2)")
	eng3.turn_count = 7; eng3._end_turn(u, "")
	t.bad(u.has_status("atk_up"), "buff expiré après sa durée")

	# Étourdissement / gel empêchent l'action et expirent
	var engs := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var sv := TUtil.mkc("SV", NATURE, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 100, "enemy")
	engs.allies = [caster]; engs.enemies = [sv]; engs.all = [caster, sv]; engs.turn_count = 1
	engs._apply_status(caster, sv, "etourdissement", 1.0, 1)
	t.ok(sv.is_prevented(), "étourdissement empêche d'agir")
	engs.turn_count = 2; engs._end_turn(sv, "")
	t.bad(sv.has_status("etourdissement"), "étourdissement expire après 1 tour")
	engs._apply_status(caster, sv, "gel", 1.0, 1)
	t.ok(sv.is_prevented(), "gel empêche d'agir")

	# Provocation : cible forcée
	var engt := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var brask := TUtil.mkc("B", FEU, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	var foe := TUtil.mkc("F", NATURE, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 100, "enemy")
	engt.allies = [brask]; engt.enemies = [foe]; engt.all = [brask, foe]; engt.turn_count = 1
	engt._apply_status(brask, foe, "provocation", 1.0, 1)
	t.eq(foe.taunt_source_cid(), 0, "provocation enregistre la source")

# --------------------------------------------------------------------
static func _test_gauge_cooldown(t: Tester) -> void:
	t.section("Combat — jauge & recharge")
	var engg := TUtil.mkengine(FakeRng.new())
	var g := TUtil.mkc("G", FEU, Stats.make(1000, 100, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	engg.allies = [g]; engg.enemies = []; engg.all = [g]
	g.gauge = 0.0; engg._apply_gauge(g, 30.0)
	t.approx(g.gauge, 30.0, 0.01, "jauge +30")
	engg._apply_gauge(g, -50.0)
	t.approx(g.gauge, 0.0, 0.01, "jauge bornée à 0")
	g.gauge = 110.0; engg.turn_count = 1; engg._end_turn(g, "")
	t.approx(g.gauge, 10.0, 0.01, "report du surplus de jauge (110 → 10)")

	# Recharge des compétences
	var engc := TUtil.mkengine(FakeRng.new().with_value(0.5))
	var kdef: HeroDefinition = DataRegistry.get_hero("kaelen")
	var ka := TUtil.mkc("K", FEU, kdef.stats_at_level(5), 0, "ally", DataRegistry.hero_skills(kdef))
	var tank := TUtil.mkc("T", NATURE, Stats.make(100000, 10, 10, 60, 0, 1.5, 0, 0), 100, "enemy")
	engc.allies = [ka]; engc.enemies = [tank]; engc.all = [ka, tank]; engc.turn_count = 1
	var sk2: SkillDefinition = DataRegistry.get_skill("kaelen_2")   # recharge 3
	engc.execute(ka, sk2, tank)
	t.eq(int(ka.cooldowns.get("kaelen_2", 0)), 3, "recharge posée à 3")
	t.bad(sk2 in engc.available_skills(ka), "compétence en recharge indisponible")
	engc.turn_count = 2; engc._end_turn(ka, "")
	engc.turn_count = 3; engc._end_turn(ka, "")
	engc.turn_count = 4; engc._end_turn(ka, "")
	t.ok(sk2 in engc.available_skills(ka), "compétence disponible après 3 tours")

# --------------------------------------------------------------------
static func _test_dot_heal_shield(t: Tester) -> void:
	t.section("Combat — poison/brûlure, soin, bouclier")
	var engp := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var pc := TUtil.mkc("PC", NATURE, Stats.make(1000, 200, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	var pv := TUtil.mkc("PV", FEU, Stats.make(3000, 100, 100, 100, 0, 1.5, 0, 0), 100, "enemy")
	engp.allies = [pc]; engp.enemies = [pv]; engp.all = [pc, pv]; engp.turn_count = 1
	engp._apply_status(pc, pv, "poison", 1.0, 3)
	var hp0 := pv.hp
	engp._process_turn_start(pv)
	t.lt(pv.hp, hp0, "le poison inflige des dégâts au début du tour")
	engp._apply_status(pc, pv, "brulure", 1.0, 2)
	var hp1 := pv.hp
	engp._process_turn_start(pv)
	t.lt(pv.hp, hp1, "la brûlure inflige des dégâts au début du tour")

	# Soin
	var engh := TUtil.mkengine(FakeRng.new().with_value(0.0))
	var hc := TUtil.mkc("HC", EAU, Stats.make(2000, 150, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	hc.hp = 1000.0
	engh.allies = [hc]; engh.enemies = []; engh.all = [hc]
	engh._heal_unit(hc, hc, 300, false)
	t.approx(hc.hp, 1300.0, 0.5, "le soin restaure 300 PV")
	hc.hp = 1990.0; engh._heal_unit(hc, hc, 300, false)
	t.approx(hc.hp, 2000.0, 0.5, "le soin ne dépasse pas les PV max")

	# Bouclier
	var sh := TUtil.mkc("SH", EAU, Stats.make(2000, 100, 100, 100, 0, 1.5, 0, 0), 0, "ally")
	var at := TUtil.mkc("AT", FEU, Stats.make(1000, 300, 100, 100, 0, 1.5, 0, 0), 100, "enemy")
	engh.allies = [sh]; engh.enemies = [at]; engh.all = [sh, at]; engh.turn_count = 1
	engh._apply_status(sh, sh, "bouclier", 1.0, 2)   # 2000 * 0.18 = 360
	t.gt(sh.total_shield(), 0.0, "bouclier présent")
	var shp0 := sh.hp
	engh._apply_damage(at, sh, 200, false, "neutral")
	t.approx(sh.hp, shp0, 0.5, "le bouclier absorbe les dégâts (PV inchangés)")
	t.lt(sh.total_shield(), 360.0, "le bouclier diminue après absorption")

# --------------------------------------------------------------------
static func _test_boss_and_outcome(t: Tester) -> void:
	t.section("Combat — boss & issue")
	var engb := TUtil.mkengine(FakeRng.new().with_value(0.5))
	engb.setup([HeroInstance.create("h1", "kaelen", 0)], ["gardien_cendres"])
	var boss: Combatant = engb.enemies[0]
	t.ok(boss.is_boss, "le boss est marqué comme boss")
	boss.hp = boss.max_hp * 0.49
	engb._check_enrage(boss)
	t.ok(boss.enraged, "le boss s'enrage sous 50 % de PV")
	t.ok(boss.has_status("atk_up") and boss.has_status("spd_up"), "l'enrage augmente attaque et vitesse")
	engb._check_enrage(boss)
	t.eq(boss.statuses.filter(func(s): return s.def.id == "atk_up").size(), 1, "l'enrage ne se déclenche qu'une fois")

	# Victoire : équipe de départ contre le stage 1-1
	var team := [
		HeroInstance.create("a", "kaelen", 0), HeroInstance.create("b", "neria", 1),
		HeroInstance.create("c", "elyra", 2), HeroInstance.create("d", "brask", 3),
	]
	var engv := TUtil.auto_battle(team, ["ember_grunt", "ember_grunt", "ember_acolyte"], FakeRng.new().with_value(0.5))
	t.ok(engv.finished, "le combat se termine")
	t.lt(engv.turn_count, engv.max_turns, "aucune boucle infinie")
	t.eq(engv.result, "victory", "victoire de l'équipe de départ au stage 1-1")

	# Défaite : un seul attaquant niveau 1 contre le boss
	var engd := TUtil.auto_battle([HeroInstance.create("s", "kaelen", 0)],
		["gardien_cendres", "cinder_servant"], FakeRng.new().with_value(0.5))
	t.ok(engd.finished, "le combat (défaite) se termine")
	t.eq(engd.result, "defeat", "Kaelen seul niveau 1 perd contre le boss")
