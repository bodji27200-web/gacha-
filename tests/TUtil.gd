class_name TUtil
extends RefCounted
## Utilitaires partagés par les tests.

static func mkc(name: String, element: int, stats: Stats, cid: int, side: String, skills: Array = []) -> Combatant:
	var c := Combatant.new()
	c.cid = cid
	c.side = side
	c.is_enemy = side == "enemy"
	c.slot = cid
	c.display_name = name
	c.element = element
	c.base_stats = stats
	c.max_hp = stats.pv
	c.hp = stats.pv
	c.skills = skills
	return c

static func mkengine(rng) -> CombatEngine:
	return CombatEngine.new(DataRegistry, rng)

## Combat complet auto-piloté (IA des deux côtés). Retourne le moteur terminé.
static func auto_battle(team_instances: Array, enemy_ids: Array, rng) -> CombatEngine:
	var eng := mkengine(rng)
	eng.setup(team_instances, enemy_ids)
	var guard := 0
	while not eng.finished and guard < 5000:
		guard += 1
		var actor: Combatant = eng.next_actor()
		if actor == null:
			break
		eng.ai_execute(actor)
		eng.drain()
	return eng
