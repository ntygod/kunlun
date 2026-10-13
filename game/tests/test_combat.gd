extends SceneTree
const Combat = preload("res://scripts/combat/combat_engine.gd")
var checks := 0
var failures := 0
var rules: Dictionary
var runtime: Dictionary

func _initialize() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	runtime = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	run()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT FAIL: " + label)

func fixture(aoe: bool = false, hits: Array = [1.0]) -> CombatEngine:
	var engine := Combat.new(rules, runtime)
	var party: Array = []
	for id in ["a", "b", "c"]:
		party.append({"id": id, "team": "party", "max_hp": 10000, "max_mp": 100, "atk": 100, "def": 0, "spd": 20, "skills": runtime.skills.keys()})
	var enemy := {"id": "e", "team": "enemy", "max_hp": 100000, "max_mp": 0, "atk": 1000, "def": 0, "spd": 100, "protection_rounds": 1,
		"rotation": [{"target_id": "a", "hits": hits, "aoe": aoe, "tags": ["interrupt", "induce"]}]}
	engine.start({"id": "test", "level": 1, "enemies": [enemy]}, party)
	return engine

func fill(engine: CombatEngine, except_ids: Array = []) -> void:
	for id in ["a", "b", "c"]:
		if id not in except_ids and engine.alive(engine.actor_by_id(id)):
			check(engine.set_command(id, "normal_attack", "e") == "", "fill command " + id)

func events(engine: CombatEngine, kind: String, round_id: int = 1) -> Array:
	return engine.state.events.filter(func(event: Dictionary) -> bool: return event.type == kind and int(event.round) == round_id)

func run() -> void:
	var e := fixture()
	var original := e.snapshot()
	check(e.set_command("a", "normal_attack", "b") == "invalid_target", "reject friendly offensive target")
	check(e.snapshot() == original, "rejected target is mutation free")
	check(e.set_command("missing", "normal_attack", "e") == "actor_unavailable", "unknown actor")
	check(e.set_command("a", "missing", "e") == "skill_unavailable", "unknown skill")
	check(e.set_command("a", "normal_attack", "e", 99) == "stale_revision", "stale revision")
	check(not e.resolve_round(), "incomplete three-person plan cannot execute")
	e.actor_by_id("a").mp = 0
	check(e.set_command("a", "mirror_counter", "e") == "insufficient_mp", "MP validation")
	e.actor_by_id("a").mp = 100
	e.actor_by_id("a")["martial_disabled"] = true
	check(e.set_command("a", "mirror_counter", "e") == "martial_disabled", "story martial lock")
	e.actor_by_id("a").martial_disabled = false
	fill(e)
	check(e.resolve_round(), "complete three commands resolve")
	check(events(e, "action").size() == 3 and events(e, "enemy_action").size() == 1, "each actor acts once")
	check(events(e, "action")[0].source == "a" and events(e, "action")[2].source == "c", "stable slot tie order")

	# Slow preparation, original raw split, no second DEF; zero-cap MP not relevant.
	e = fixture()
	e.state.k = 200.0
	e.actor_by_id("a").def = 100
	e.actor_by_id("a")["reduction"] = 0.1
	e.actor_by_id("b").def = 300
	e.actor_by_id("b").spd = 1
	e.actor_by_id("b").mp = 50
	check(e.set_command("b", "guard_ally", "a") == "", "select slow guard")
	check(e.set_command("c", "guard_ally", "a") == "guard_conflict", "reject duplicate guard")
	fill(e, ["b"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 9700 and e.actor_by_id("b").hp == 9850, "raw split 300/150 exact")
	check(e.actor_by_id("b").mp == 62, "guard 8 plus first actual share 4")
	check(events(e, "prepared")[0].id < events(e, "enemy_action")[0].id, "prepare before fast enemy")
	check(events(e, "action").size() == 2, "guard consumes normal action")

	e = fixture(false, [0.5, 0.5, 0.5])
	e.actor_by_id("b").mp = 0
	e.set_command("b", "guard_ally", "a")
	fill(e, ["b"])
	e.resolve_round()
	check(events(e, "damage").filter(func(ev: Dictionary) -> bool: return ev.target == "b").size() == 3, "guard token covers every hit of one action")
	check(events(e, "mana").filter(func(ev: Dictionary) -> bool: return ev.detail.reason == "successful_guard").size() == 1, "actual guard reward once, not per hit")

	e = fixture(true)
	e.set_command("b", "guard_ally", "a")
	fill(e, ["b"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 9000 and e.actor_by_id("b").hp == 9250 and e.actor_by_id("c").hp == 9000, "AOE has own packets and no single-target sharing")

	e = fixture()
	e.actor_by_id("a").mp = 50
	e.set_command("a", "mirror_counter", "e")
	fill(e, ["a"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 10000, "induced miss zero")
	check(e.actor_by_id("a").mp == 46, "mirror floor10 then break gain6")
	check(events(e, "counter").size() == 1 and events(e, "action").size() == 2, "counter is prepared action, no extra action")
	check(e.set_command("a", "mirror_counter", "e") == "cooldown", "CD1 unavailable T2")
	check(int(e.actor_by_id("e").protected_through) == 2 and int(e.actor_by_id("e").vulnerable_through) == 2, "break timestamps T and T+1")
	fill(e)
	e.resolve_round()
	check(e.set_command("a", "mirror_counter", "e") == "", "CD1 ready T3")
	fill(e, ["a"])
	e.resolve_round()
	check(e.state.break_count == 2, "protection permits new T3 break")

	e = fixture()
	e.actor_by_id("a").spd = 200
	e.actor_by_id("b").spd = 180
	e.set_command("a", "test_interrupt", "e")
	e.set_command("b", "test_interrupt", "e")
	fill(e, ["a", "b"])
	e.resolve_round()
	check(events(e, "break").size() == 1, "two attacks cannot break twice same round")
	check(e.actor_by_id("a").hp == 9650, "interrupt replaces attack with 35 percent damage")
	e.actor_by_id("c").spd = 200
	e.set_command("c", "test_interrupt", "e")
	fill(e, ["c"])
	e.resolve_round()
	check(events(e, "break", 2).is_empty(), "protected next round cannot break")
	check(e.actor_by_id("a").hp == 8650, "protected enemy still performs full action")

	e = fixture()
	e.actor_by_id("e").protection_rounds = 2
	e.actor_by_id("a").spd = 200
	e.set_command("a", "test_interrupt", "e")
	fill(e, ["a"])
	e.resolve_round()
	check(int(e.actor_by_id("e").protected_through) == 3, "p2 covers T2 T3")
	check(e._protected(e.actor_by_id("e")), "p2 protected T2")
	e.state.round = 4
	check(not e._protected(e.actor_by_id("e")), "p2 expires T4")

	e = fixture()
	e.actor_by_id("a").mp = 0
	e.gain_mana(e.actor_by_id("a"), 8, "test_guard")
	e.gain_mana(e.actor_by_id("a"), 6, "test_break")
	e.gain_mana(e.actor_by_id("a"), 100, "test_other")
	check(e.actor_by_id("a").mp == 12, "all mana sources share budget")
	e.actor_by_id("a").max_mp = 279
	check(e.skill_cost(e.actor_by_id("a"), {"source_id": "LX_A07"}) == 62, "cost ceilings after percent")
	e.actor_by_id("a")["discount"] = 0.8
	check(e.skill_cost(e.actor_by_id("a"), {"source_id": "LX_A07"}) == 31, "discount capped once at50")
	check(e.skill_cost(e.actor_by_id("a"), runtime.skills.self_guard) == 0, "zero cost stays zero")

	e = fixture()
	e.actor_by_id("a")["reduction"] = 0.9
	check(e._reduction(e.actor_by_id("a")) == 0.6, "reduction cap")
	e.actor_by_id("a").reduction = 0.2
	e.set_command("a", "self_guard", "a")
	fill(e, ["a"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 9350, "guard highest DR35 not multiplicative")

	e = fixture()
	var checkpoint_copy := e.snapshot()
	fill(e)
	e.resolve_round()
	var expected := e.snapshot()
	check(e.retry_checkpoint(), "retry restores entry checkpoint")
	check(e.snapshot() == checkpoint_copy, "retry restores resources and complete event log")
	fill(e)
	e.resolve_round()
	check(e.snapshot() == expected, "replayed commands produce same full state and events")
	var wire: Dictionary = JSON.parse_string(JSON.stringify(e.snapshot()))
	check(e.restore(wire), "JSON snapshot accepted")
	fill(e)
	e.resolve_round()
	check(int(e.state.round) == 3, "restored JSON state actually executes")
	var good := e.snapshot()
	var bad := good.duplicate(true)
	bad.version = 900
	check(not e.restore(bad) and e.snapshot() == good, "future version rejected atomically")
	bad = good.duplicate(true)
	bad.actors[0].hp = -1
	check(not e.restore(bad) and e.snapshot() == good, "invalid actor bounds rejected")
	bad = good.duplicate(true)
	bad.content_version = "other"
	check(not e.restore(bad), "content mismatch rejected")

	e = fixture()
	e.actor_by_id("a").hp = 1
	e.actor_by_id("b").hp = 1
	e.actor_by_id("c").hp = 1
	e.state.intents[0].aoe = true
	fill(e)
	e.resolve_round()
	check(e.state.outcome == "defeat" and e.state.mode == "finished", "defeat terminal")
	check(not e.resolve_round(), "terminal state cannot act")
	check(e.retry_checkpoint() and e.state.outcome == "", "defeat retry clears terminal state")
	# Lock-axis timing: a speed effect applied by the first action changes next round only.
	e = fixture()
	e.actor_by_id("a").spd = 200
	e.actor_by_id("b").spd = 80
	e.content.skills.test_interrupt["speed_down"] = 0.5
	e.set_command("a", "test_interrupt", "e")
	fill(e, ["a"])
	e.resolve_round()
	var actions: Array = e.state.events.filter(func(ev: Dictionary) -> bool: return int(ev.round) == 1 and ev.type in ["action", "enemy_action"])
	check(actions[0].source == "a" and actions[1].source == "e" and actions[2].source == "b", "current axis fixed before speed debuff")
	fill(e)
	e.resolve_round()
	actions = e.state.events.filter(func(ev: Dictionary) -> bool: return int(ev.round) == 2 and ev.type in ["action", "enemy_action"])
	check(actions[1].source == "b" and actions[2].source == "e", "speed reduction effective next round")

	# Actual protection fallback and expired vulnerability are numerical, not labels.
	e = fixture()
	e.actor_by_id("e").protected_through = 1
	e.set_command("a", "mirror_counter", "e")
	fill(e, ["a"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 9350 and events(e, "break").is_empty(), "protected counter gives35 DR without induced miss")
	check(events(e, "counter").size() == 1, "protected stance still resolves single palm")
	e = fixture()
	e.actor_by_id("e").vulnerable_through = 1
	fill(e)
	e.resolve_round()
	check(events(e, "damage").filter(func(ev: Dictionary) -> bool: return ev.target == "e")[0].amount == 120, "break vulnerability multiplies by1.2")
	fill(e)
	e.resolve_round()
	check(events(e, "damage", 2).filter(func(ev: Dictionary) -> bool: return ev.target == "e")[0].amount == 100, "vulnerability expiry stops damage bonus")

	# A second enemy action cannot reuse an exhausted multi-hit guard token.
	e = fixture(false, [0.5, 0.5])
	var extra: Dictionary = e.actor_by_id("e").duplicate(true)
	extra.id = "e2"
	e.state.actors.append(extra)
	var extra_intent: Dictionary = e.state.intents[0].duplicate(true)
	extra_intent.actor_id = "e2"
	extra_intent.intent_id = "e2:1"
	e.state.intents.append(extra_intent)
	e.set_command("b", "guard_ally", "a")
	e.set_command("c", "guard_ally", "b")
	fill(e, ["b", "c"])
	e.resolve_round()
	check(e.actor_by_id("a").hp == 8500, "second enemy action not shared")
	check(e.actor_by_id("b").hp == 9626 and e.actor_by_id("c").hp == 10000, "shared damage cannot chain to third guardian; per-hit floor")

	e = fixture()
	var before_invalid := e.snapshot()
	for field in ["revision", "k", "event_sequence", "intents"]:
		var malformed := before_invalid.duplicate(true)
		malformed.erase(field)
		check(not e.restore(malformed) and e.snapshot() == before_invalid, "missing checkpoint field rejected: " + field)
	var malformed := before_invalid.duplicate(true)
	malformed.actors[0].ready = {"unknown_skill": 5}
	check(not e.restore(malformed), "unknown cooldown skill rejected")
	malformed = before_invalid.duplicate(true)
	malformed.actors[0].statuses = [{"kind": "attack_down", "value": "oops", "starts": 1, "expires": 2}]
	check(not e.restore(malformed), "malformed nested status rejected")
	malformed = before_invalid.duplicate(true)
	malformed.actors[1].id = "a"
	check(not e.restore(malformed), "duplicate actor checkpoint rejected")
	var view := e.get_view()
	view.actors[0].hp = 0
	check(e.actor_by_id("a").hp == 10000, "view cannot mutate combat state")
	e = fixture()
	e.set_command("a", "normal_attack", "e")
	var identical := e.snapshot()
	check(e.set_command("a", "normal_attack", "e") == "" and e.snapshot() == identical, "identical command idempotent")
	var corrupt := e.snapshot()
	corrupt.actors[0].mp = 0
	corrupt.commands.a.skill_id = "mirror_counter"
	check(not e.restore(corrupt) and e.snapshot() == identical, "restore rejects unaffordable command")
	corrupt = e.snapshot()
	corrupt.commands.a.target_id = "a"
	check(not e.restore(corrupt) and e.snapshot() == identical, "restore rejects self-attack")
	corrupt = e.snapshot()
	corrupt.actors[0]["shield"] = -100
	check(not e.restore(corrupt) and e.snapshot() == identical, "restore rejects negative shield")
	e = fixture()
	e.actor_by_id("a").hp = 1
	fill(e)
	e.resolve_round()
	check(e.state.intents[0].target_id == "b", "new round publicly locks surviving target")
	fill(e, ["a"])
	e.resolve_round()
	check(e.actor_by_id("b").hp == 9000, "dead original target cannot neutralize enemy forever")
	e = fixture()
	var valid_state := e.snapshot()
	var bad_intents := valid_state.duplicate(true)
	bad_intents.intents.append(bad_intents.intents[0].duplicate(true))
	check(not e.restore(bad_intents) and e.snapshot() == valid_state, "duplicate intent cannot give enemy extra action")
	bad_intents = valid_state.duplicate(true)
	bad_intents.intents.clear()
	check(not e.restore(bad_intents), "missing live enemy intent rejected")
	bad_intents = valid_state.duplicate(true)
	bad_intents.intents[0].executed = true
	check(not e.restore(bad_intents), "commands boundary cannot contain executed intent")
	for field in ["speed", "aoe", "tags"]:
		bad_intents = valid_state.duplicate(true)
		bad_intents.intents[0][field] = {"bad": "type"}
		check(not e.restore(bad_intents), "bad nested intent rejected: " + field)
	var bad_goal := e.snapshot()
	bad_goal.encounter["required_breaks"] = {"bad": "type"}
	check(not e.restore(bad_goal), "bad encounter goal rejected before execution")
	print("Combat checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
