class_name TestData
extends RefCounted
## Validation des définitions data-driven.

static func run(t: Tester) -> void:
	t.section("Données")
	var R = DataRegistry
	R.load_all()

	t.eq(R.heroes.size(), 6, "6 héros chargés")
	t.ge(R.stages.size(), 3, "au moins 3 stages")
	t.ge(R.enemies.size(), 5, "ennemis chargés")
	t.ok(R.get_default_banner() != null, "bannière présente")

	# Identifiants uniques (taille liste == taille dict indexé)
	t.eq(HeroesData.build().size(), R.heroes.size(), "identifiants de héros uniques")
	t.eq(SkillsData.build().size(), R.skills.size(), "identifiants de compétences uniques")
	t.eq(StatusEffectsData.build().size(), R.status_effects.size(), "identifiants de statuts uniques")

	# Chaque héros : 3 compétences valides avec cible valide
	for h in R.heroes.values():
		t.eq(h.skill_ids.size(), 3, "%s possède 3 compétences" % h.id)
		for sid in h.skill_ids:
			var s: SkillDefinition = R.get_skill(sid)
			t.ok(s != null, "compétence %s existe" % sid)
			if s != null:
				t.ok(s.target >= 0 and s.target <= GameEnums.Target.SELF, "cible valide pour %s" % sid)

	# Statuts référencés par les compétences existent
	for s in R.skills.values():
		for e in s.effects:
			if e.get("kind", "") == "status":
				t.ok(R.get_status(e.get("status", "")) != null,
					"statut %s référencé par %s existe" % [e.get("status", ""), s.id])

	# Ennemis : compétences valides
	for en in R.enemies.values():
		t.ge(en.skill_ids.size(), 1, "%s a au moins une compétence" % en.id)
		for sid in en.skill_ids:
			t.ok(R.get_skill(sid) != null, "compétence ennemie %s existe" % sid)

	# Stages : ennemis présents
	for st in R.stages.values():
		t.ge(st.enemy_ids.size(), 1, "%s contient des ennemis" % st.id)

	# Taux d'invocation = 100 %
	var b: SummonBannerDefinition = R.get_default_banner()
	t.approx(b.rates_sum(), 1.0, 0.0001, "taux d'invocation = 100 %")
	t.eq(b.rates.get(3, 0.0), 0.75, "taux 3★ = 75 %")
	t.eq(b.rates.get(4, 0.0), 0.22, "taux 4★ = 22 %")
	t.eq(b.rates.get(5, 0.0), 0.03, "taux 5★ = 3 %")
