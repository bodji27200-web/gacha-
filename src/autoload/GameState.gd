extends Node
## État du joueur : héros possédés, économie, équipe, progression, invocation.
## Utilise self.registry / self.rng (injectables) afin de rester testable.

signal currency_changed
signal collection_changed
signal team_changed

const SAVE_VERSION := 1
const MAX_LEVEL := 20
const STARTERS := ["kaelen", "neria", "elyra", "brask"]

# Dépendances (injectées en _ready, ou manuellement dans les tests)
var registry
var rng

# --- État joueur ---
var or_montant: int = 0
var cristaux: int = 0
var heroes: Array[HeroInstance] = []
var team: Array[String] = ["", "", "", ""]   # 4 uid (vides autorisés)
var stages_cleared: Dictionary = {}           # stage_id -> true
var first_clear_claimed: Dictionary = {}       # stage_id -> true
var pity_counter: int = 0
var total_summons: int = 0
var first_summon_done: bool = false
var first_multi_done: bool = false
var tutorial_done: bool = false
var settings: Dictionary = {"combat_speed": 1, "sfx": true, "music": true}
var _next_uid: int = 1
var _next_ordre: int = 0

func _ready() -> void:
	registry = DataRegistry
	rng = RNG

# =====================================================================
#  NOUVELLE PARTIE
# =====================================================================
func new_game() -> void:
	or_montant = 1000
	cristaux = 120
	heroes.clear()
	team = ["", "", "", ""]
	stages_cleared = {}
	first_clear_claimed = {}
	pity_counter = 0
	total_summons = 0
	first_summon_done = false
	first_multi_done = false
	tutorial_done = false
	settings = {"combat_speed": 1, "sfx": true, "music": true}
	_next_uid = 1
	_next_ordre = 0
	for def_id in STARTERS:
		var inst := _create_instance(def_id)
		heroes.append(inst)
	# Équipe de départ = les 4 héros offerts
	for i in mini(4, heroes.size()):
		team[i] = heroes[i].uid
	currency_changed.emit()
	collection_changed.emit()
	team_changed.emit()

func _new_uid() -> String:
	var u := "h%d" % _next_uid
	_next_uid += 1
	return u

func _create_instance(def_id: String) -> HeroInstance:
	var inst := HeroInstance.create(_new_uid(), def_id, _next_ordre)
	_next_ordre += 1
	return inst

# =====================================================================
#  COLLECTION
# =====================================================================
func owns_def(def_id: String) -> bool:
	return get_instance_by_def(def_id) != null

func get_instance_by_def(def_id: String) -> HeroInstance:
	for h in heroes:
		if h.def_id == def_id:
			return h
	return null

func get_instance_by_uid(uid: String) -> HeroInstance:
	for h in heroes:
		if h.uid == uid:
			return h
	return null

func hero_def(inst: HeroInstance) -> HeroDefinition:
	return registry.get_hero(inst.def_id)

func instance_stats(inst: HeroInstance) -> Stats:
	return registry.get_hero(inst.def_id).stats_at_level(inst.niveau)

## Puissance approximative (tri / affichage).
func power(inst: HeroInstance) -> int:
	var s := instance_stats(inst)
	return int(round(s.pv * 0.25 + s.attaque * 3.5 + s.defense * 2.0
		+ s.vitesse * 2.5 + s.crit_taux * 300.0 + (s.crit_degats - 1.0) * 120.0))

func account_level() -> int:
	var lv := 1 + stages_cleared.size()
	var total := 0
	for h in heroes:
		total += h.niveau
	return lv + int(total / 12.0)

# =====================================================================
#  ÉCONOMIE & RÉCOMPENSES
# =====================================================================
func add_currency(p_or: int, p_cristaux: int) -> void:
	or_montant = maxi(0, or_montant + p_or)
	cristaux = maxi(0, cristaux + p_cristaux)
	currency_changed.emit()

func spend_cristaux(amount: int) -> bool:
	if cristaux < amount:
		return false
	cristaux -= amount
	currency_changed.emit()
	return true

## Octroie les récompenses d'un stage. Retourne un résumé (incl. montées de niveau).
func grant_stage_rewards(stage: StageDefinition, team_uids: Array) -> Dictionary:
	var first := not first_clear_claimed.has(stage.id)
	var gold := stage.reward_or + (stage.first_or if first else 0)
	var crys := stage.reward_cristaux + (stage.first_cristaux if first else 0)
	var xp := stage.reward_xp + (stage.first_xp if first else 0)
	add_currency(gold, crys)
	var level_ups: Array = []
	for uid in team_uids:
		var inst := get_instance_by_uid(uid)
		if inst:
			var r := add_xp(inst, xp)
			if r.get("leveled", false):
				level_ups.append(r)
	stages_cleared[stage.id] = true
	if first:
		first_clear_claimed[stage.id] = true
	collection_changed.emit()
	return {
		"first": first, "or": gold, "cristaux": crys, "xp": xp, "level_ups": level_ups,
	}

# =====================================================================
#  EXPÉRIENCE & NIVEAUX
# =====================================================================
func exp_to_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return -1
	return 80 + (level - 1) * 55

## Ajoute de l'XP à un héros. Retourne {leveled, from, to, gains:Stats}.
func add_xp(inst: HeroInstance, amount: int) -> Dictionary:
	if inst.niveau >= MAX_LEVEL:
		inst.exp = 0
		return {"leveled": false, "from": inst.niveau, "to": inst.niveau}
	var from_level := inst.niveau
	inst.exp += amount
	while inst.niveau < MAX_LEVEL:
		var need := exp_to_next(inst.niveau)
		if inst.exp < need:
			break
		inst.exp -= need
		inst.niveau += 1
	if inst.niveau >= MAX_LEVEL:
		inst.exp = 0
	var leveled := inst.niveau > from_level
	var gains := Stats.new()
	if leveled:
		var def: HeroDefinition = registry.get_hero(inst.def_id)
		var n := float(inst.niveau - from_level)
		gains = Stats.make(def.growth.pv * n, def.growth.attaque * n,
			def.growth.defense * n, def.growth.vitesse * n)
	return {"leveled": leveled, "from": from_level, "to": inst.niveau, "gains": gains, "name": registry.get_hero(inst.def_id).nom}

# =====================================================================
#  ÉQUIPE
# =====================================================================
func set_team_slot(slot: int, uid: String) -> bool:
	if slot < 0 or slot >= 4:
		return false
	# Pas de doublon exact (même exemplaire) dans l'équipe
	if uid != "":
		for i in 4:
			if i != slot and team[i] == uid:
				return false
	team[slot] = uid
	team_changed.emit()
	return true

func clear_team_slot(slot: int) -> void:
	if slot >= 0 and slot < 4:
		team[slot] = ""
		team_changed.emit()

func team_instances() -> Array:
	var arr: Array = []
	for uid in team:
		if uid != "":
			var inst := get_instance_by_uid(uid)
			if inst:
				arr.append(inst)
	return arr

func team_is_valid() -> bool:
	return not team_instances().is_empty()

# =====================================================================
#  INVOCATION
# =====================================================================
## Tire la rareté selon les taux de la bannière, en respectant la pitié.
func _roll_rarity(banner: SummonBannerDefinition) -> int:
	var rarities: Array = []
	var weights: Array = []
	for r in banner.rates.keys():
		rarities.append(r)
		weights.append(banner.rates[r])
	var rarity := int(rng.weighted_pick(rarities, weights))
	# Pitié dure : forcer 5★ au seuil
	if rarity != banner.pity_rarity and pity_counter + 1 >= banner.pity_threshold:
		rarity = banner.pity_rarity
	return rarity

func _pick_def_of_rarity(banner: SummonBannerDefinition, rarity: int, exclude_owned: bool = false) -> String:
	var pool: Array = banner.pool.get(rarity, []).duplicate()
	if exclude_owned:
		var filtered: Array = []
		for did in pool:
			if not owns_def(did):
				filtered.append(did)
		if not filtered.is_empty():
			pool = filtered
	if pool.is_empty():
		return ""
	return String(rng.pick(pool))

## Résultat d'un tirage : {def_id, rarity, is_new, fragments, name}
func _resolve_pull(banner: SummonBannerDefinition, rarity: int, force_new: bool) -> Dictionary:
	var def_id := _pick_def_of_rarity(banner, rarity, force_new)
	if def_id == "":
		def_id = _pick_def_of_rarity(banner, rarity, false)
	# Mise à jour de la pitié
	if rarity == banner.pity_rarity:
		pity_counter = 0
	else:
		pity_counter += 1
	total_summons += 1
	var def: HeroDefinition = registry.get_hero(def_id)
	var result := {"def_id": def_id, "rarity": rarity, "name": def.nom, "is_new": false, "fragments": 0}
	if owns_def(def_id):
		var frags := int(BannersData.DUP_FRAGMENTS.get(def.rarete, 10))
		var inst := get_instance_by_def(def_id)
		inst.fragments += frags
		result["fragments"] = frags
	else:
		heroes.append(_create_instance(def_id))
		result["is_new"] = true
	return result

## Invocation simple. `free` = première invocation gratuite (héros nouveau garanti).
func summon_single(free: bool = false) -> Dictionary:
	var banner: SummonBannerDefinition = registry.get_default_banner()
	var is_free := free and not first_summon_done
	var rarity := _roll_rarity(banner)
	var res := _resolve_pull(banner, rarity, is_free)
	first_summon_done = true
	collection_changed.emit()
	currency_changed.emit()
	return res

## Invocation x10 avec garantie d'au moins un 4★+.
func summon_multi() -> Array:
	var banner: SummonBannerDefinition = registry.get_default_banner()
	var results: Array = []
	var got_high := false
	for i in banner.multi_count:
		var rarity := _roll_rarity(banner)
		# Garantie sur le dernier tirage si rien de >= multi_min_rarity
		if i == banner.multi_count - 1 and not got_high and rarity < banner.multi_min_rarity:
			rarity = banner.multi_min_rarity
		if rarity >= banner.multi_min_rarity:
			got_high = true
		results.append(_resolve_pull(banner, rarity, false))
	first_summon_done = true
	first_multi_done = true
	collection_changed.emit()
	currency_changed.emit()
	return results

# =====================================================================
#  SÉRIALISATION
# =====================================================================
func to_dict() -> Dictionary:
	var hero_dicts: Array = []
	for h in heroes:
		hero_dicts.append(h.to_dict())
	return {
		"version": SAVE_VERSION,
		"or": or_montant,
		"cristaux": cristaux,
		"heroes": hero_dicts,
		"team": team.duplicate(),
		"stages_cleared": stages_cleared.duplicate(),
		"first_clear_claimed": first_clear_claimed.duplicate(),
		"pity_counter": pity_counter,
		"total_summons": total_summons,
		"first_summon_done": first_summon_done,
		"first_multi_done": first_multi_done,
		"tutorial_done": tutorial_done,
		"settings": settings.duplicate(),
		"next_uid": _next_uid,
		"next_ordre": _next_ordre,
	}

func from_dict(d: Dictionary) -> void:
	or_montant = int(d.get("or", 0))
	cristaux = int(d.get("cristaux", 0))
	heroes.clear()
	for hd in d.get("heroes", []):
		var inst := HeroInstance.from_dict(hd)
		# Validation : ignorer un héros dont la définition n'existe plus
		if registry.get_hero(inst.def_id) != null:
			heroes.append(inst)
	var t: Array = d.get("team", ["", "", "", ""])
	team = ["", "", "", ""]
	for i in mini(4, t.size()):
		team[i] = String(t[i])
	stages_cleared = d.get("stages_cleared", {})
	first_clear_claimed = d.get("first_clear_claimed", {})
	pity_counter = int(d.get("pity_counter", 0))
	total_summons = int(d.get("total_summons", 0))
	first_summon_done = bool(d.get("first_summon_done", false))
	first_multi_done = bool(d.get("first_multi_done", false))
	tutorial_done = bool(d.get("tutorial_done", false))
	settings = d.get("settings", {"combat_speed": 1, "sfx": true, "music": true})
	_next_uid = int(d.get("next_uid", heroes.size() + 1))
	_next_ordre = int(d.get("next_ordre", heroes.size()))
	currency_changed.emit()
	collection_changed.emit()
	team_changed.emit()
