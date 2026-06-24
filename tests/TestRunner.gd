extends Node
## Lanceur de tests headless. Exécution :
##   godot --headless res://tests/TestRunner.tscn
## Sort avec le code 0 si tout passe, 1 sinon.

func _ready() -> void:
	DataRegistry.load_all()
	var t := Tester.new()

	TestData.run(t)
	TestCombat.run(t)
	TestSummon.run(t)
	TestProgression.run(t)
	TestSave.run(t)
	TestSmoke.run(t)

	print("\n========== RÉSULTATS DES TESTS ==========")
	if t.messages.is_empty():
		print("  (aucun échec)")
	else:
		for m in t.messages:
			print(m)
	print("-----------------------------------------")
	print("Total : %d   Réussis : %d   Échecs : %d" % [t.total, t.passed(), t.failed])
	print("=========================================")

	var code := 0 if t.failed == 0 else 1
	print("EXIT_CODE=%d" % code)
	await get_tree().process_frame
	get_tree().quit(code)
