extends SceneTree
const Session = preload("res://scripts/combat/objective_encounter.gd")
const Core = preload("res://scripts/combat/combat_engine.gd")
const ObjectiveView = preload("res://scripts/ui/objective_battle_panel.gd")
var rules: Dictionary
var runtime: Dictionary
var data: Dictionary
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CH02 COMBAT: " + text)
func party() -> Array:
	return [{"id":"char_liang_xiao","name":"梁萧","team":"party","max_hp":240,"max_mp":65,"atk":48,"def":28,"spd":22,"skills":["normal_attack","self_guard","sancai_counter","observe"],"skill_ranks":{"observe":1},"passives":[]}]
func session(id: String) -> ObjectiveEncounter:
	return Session.new(rules,runtime,data.encounters[id],party(),"step:02:test")
func take(s: ObjectiveEncounter, input: Dictionary) -> void:
	check(s.apply_input(input).accepted,"accept " + str(input))
	check(s.resolve_round(),"resolve accepted objective action")
func win_antidote(s: ObjectiveEncounter, detour: bool = false) -> void:
	take(s,{"action_id":"listen"})
	if detour:
		take(s,{"action_id":"feign_surrender","lane":"west"})
	take(s,{"action_id":"feign_surrender","lane":"east"})
	take(s,{"action_id":"restrain","target":"char_toghon"})
	take(s,{"action_id":"inspect_antidote"})
	take(s,{"action_id":"exchange","item":"blue_antidote"})
	take(s,{"action_id":"administer","target":"char_hua_qingyuan"})
	take(s,{"action_id":"delay_pursuit","lane":"bridge"})
	if detour: take(s,{"action_id":"escort_move","destination":"side"})
	take(s,{"action_id":"escort_move","destination":"bridge"})
	take(s,{"action_id":"escort_move","destination":"exit"})
func basic_core(rank: int = 1, passive: bool = false) -> CombatEngine:
	var p := party()
	p[0].max_hp = 10000
	p[0].atk = 100
	p[0].skill_ranks.observe = rank
	if passive: p[0].passives = ["LX_P01"]
	var enemy := {"id":"e","team":"enemy","max_hp":10000,"max_mp":0,"atk":100,"def":0,"spd":10,"protection_rounds":1,"rotation":[{"target_id":"char_liang_xiao","hits":[1.0],"tags":["induce"]}]}
	var e := Core.new(rules,runtime)
	e.start({"id":"skill_test","level":1,"enemies":[enemy]},p)
	return e
func cast(e: CombatEngine, skill: String) -> void:
	check(e.set_command("char_liang_xiao",skill,"char_liang_xiao" if skill == "self_guard" else "e") == "","core cast " + skill)
	check(e.resolve_round(),"core resolves")
func run() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	runtime = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_two_encounters.json"))
	var s := session("enc_ch02_protect_qin")
	check(s.get_view().actors.size() == 3,"Qin is protected actor, Jiuru not free command")
	check(s.set_command("char_qin_bofu","self_guard","char_qin_bofu",int(s.engine.state.revision)) == "actor_unavailable","wounded Qin cannot take normal command")
	var before := s.snapshot()
	check(not s.apply_input({"action_id":"move_qin","lane":"fake"}).accepted and s.snapshot() == before,"invalid lane atomic")
	check(not s.apply_input({"action_id":"move_qin","lane":"right","won":true}).accepted,"UI won flag rejected")
	check(s.victory_receipt().is_empty(),"no early receipt")
	take(s,{"action_id":"move_qin","lane":"right"})
	check(s.engine.state.objective.chain_count == 1 and s.victory_receipt().is_empty(),"one real chain not victory")
	var mid: Dictionary = JSON.parse_string(JSON.stringify(s.snapshot()))
	check(s.restore(mid),"mid-fight JSON checkpoint replay restore")
	take(s,{"action_id":"move_qin","lane":"left"})
	check(s.engine.state.outcome == "victory","two genuinely avoided chain actions win")
	check(s.engine.actor_by_id("char_he_songyang").hp == 5000,"victory does not require damage to master")
	var receipt := s.victory_receipt()
	check(not Session.replay_receipt(receipt,rules,runtime,data.encounters.enc_ch02_protect_qin,party()).is_empty(),"protection receipt replay")
	var forged := receipt.duplicate(true)
	forged.commands[0].input.lane = "left"
	check(Session.replay_receipt(forged,rules,runtime,data.encounters.enc_ch02_protect_qin,party()).is_empty(),"forged success input rejected")
	check(not s.resolve_round(),"victory cannot resolve twice")
	s.retry()
	check(s.history.is_empty() and s.victory_receipt().is_empty(),"retry clears receipt and history")
	take(s,{"action_id":"decoy_chain","lane":"left"})
	take(s,{"action_id":"decoy_chain","lane":"right"})
	check(s.engine.state.outcome == "victory" and s.engine.actor_by_id("char_liang_xiao").hp < 240,"alternate decoy route uses actual damage yet wins")
	s.retry()
	take(s,{"action_id":"wait"})
	check(s.engine.state.outcome == "defeat" and s.receipt().is_empty(),"unprotected chain fails no receipt")
	var failed_state := s.snapshot()
	check(not s.apply_input({"action_id":"move_qin","lane":"right"}).accepted and s.snapshot() == failed_state,"cannot repair failed battle by extra input")
	s.retry()
	check(s.engine.actor_by_id("char_qin_bofu").hp == 90,"failure retry restores wounded target")

	s = session("enc_ch02_antidote_escape")
	check(s.get_view().actors.filter(func(a: Dictionary) -> bool: return a.id == "char_hua_xiaoshuang").is_empty(),"girl is not combat/killable slot")
	check(not s.apply_input({"action_id":"exchange","item":"blue_antidote"}).accepted,"cannot exchange before restraint and identification")
	win_antidote(s)
	check(s.engine.state.outcome == "victory","full hostage exchange and escape succeeds")
	check(s.engine.actor_by_id("char_toghon").hp == 1000 and s.engine.actor_by_id("char_huo_zhenren").hp == 5000,"exchange route does not require human injury")
	check(s.engine.state.objective.treated and s.engine.state.objective.exchanged and s.engine.state.objective.delay_resolved,"all real objective evidence present")
	receipt = s.receipt()
	check(not Session.replay_receipt(JSON.parse_string(JSON.stringify(receipt)),rules,runtime,data.encounters.enc_ch02_antidote_escape,party()).is_empty(),"antidote receipt JSON replay")
	forged = receipt.duplicate(true)
	forged.objective_evidence.treated = false
	check(Session.replay_receipt(forged,rules,runtime,data.encounters.enc_ch02_antidote_escape,party()).is_empty(),"tampered evidence rejected")
	forged = receipt.duplicate(true)
	forged.commands.remove_at(4)
	check(Session.replay_receipt(forged,rules,runtime,data.encounters.enc_ch02_antidote_escape,party()).is_empty(),"skipping exchange cannot forge receipt")
	s.retry()
	win_antidote(s,true)
	check(s.engine.state.outcome == "victory" and s.engine.state.objective.alarm == 1,"recoverable wrong approach plus side path still wins")
	s.retry()
	take(s,{"action_id":"listen"})
	take(s,{"action_id":"feign_surrender","lane":"east"})
	take(s,{"action_id":"wait"})
	check(s.engine.state.objective.stage == "approach","missed restraint window closes after actual guard action")
	check(not s.apply_input({"action_id":"restrain","target":"char_toghon"}).accepted,"cannot restrain outside window")
	take(s,{"action_id":"feign_surrender","lane":"east"})
	take(s,{"action_id":"restrain","target":"char_toghon"})
	take(s,{"action_id":"inspect_antidote"})
	take(s,{"action_id":"exchange","item":"red_bottle"})
	check(s.engine.state.outcome == "defeat" and s.receipt().is_empty(),"incorrect medicine fails without reward")
	s.retry()
	before = s.snapshot()
	check(not s.restore({"version":1}),"malformed session snapshot rejected")
	check(s.snapshot() == before,"bad session snapshot cannot mutate live state")
	var input := {"action_id":"listen","revision":int(s.engine.state.revision)}
	check(s.apply_input(input).accepted,"queue listen")
	var queued := s.snapshot()
	check(not s.apply_input(input).accepted and s.snapshot() == queued,"stale repeated UI callback has no effect")
	input.revision = int(s.engine.state.revision)
	check(s.apply_input(input).accepted and s.snapshot() == queued,"current identical input idempotent")
	check(s.restore(JSON.parse_string(JSON.stringify(queued))),"queued input snapshot restores by replay")
	var corrupted := queued.duplicate(true)
	corrupted.state.objective.treated = true
	check(not s.restore(corrupted),"invented objective snapshot cannot bypass input")

	# Exact LX_A01 Lv1/Lv2 and LX_P01 contracts.
	var e := basic_core()
	e.actor_by_id("char_liang_xiao").mp = 20
	cast(e,"observe")
	check(e.actor_by_id("e").hp == 10000 and e.state.break_count == 0,"observe does zero damage and no break")
	check(e.actor_by_id("char_liang_xiao").mp == 24,"observe restores4 MP")
	check(e._status_value(e.actor_by_id("e"),"posuan") == 0.1,"observe two-round posuan survives next round")
	cast(e,"normal_attack")
	check(e.actor_by_id("e").hp == 9850,"next normal attack has1.5 guaranteed critical without independent posuan boost")
	check(e._status_value(e.actor_by_id("e"),"posuan") == 0.0,"posuan expires after T+1")
	cast(e,"normal_attack")
	check(e.actor_by_id("e").hp == 9750,"critical marker consumed once")
	e = basic_core()
	cast(e,"observe")
	cast(e,"sancai_counter")
	check(e._status_value(e.actor_by_id("char_liang_xiao"),"mingxin") == 1.0,"prepared counter does not consume mingxin")
	e = basic_core(2)
	var hp := int(e.actor_by_id("char_liang_xiao").hp)
	cast(e,"observe")
	check(e.actor_by_id("char_liang_xiao").hp == hp - 62,"Lv2 DR20 applies this round with own DEF28")
	cast(e,"normal_attack")
	check(e.actor_by_id("char_liang_xiao").hp == hp - 62 - 78,"Lv2 DR expires not an extra round")
	e = basic_core(1,true)
	check(e._status_value(e.actor_by_id("e"),"posuan") == 0.1 and e.state.break_count == 0,"P01 automatic posuan not automatic break")
	var hero := e.actor_by_id("char_liang_xiao")
	check(e._speed(hero,15,runtime.skills.observe) == int(hero.spd)+21,"P01 normal skill speed+6 above half MP")
	hero.mp = 32
	check(e._speed(hero,15,runtime.skills.observe) == int(hero.spd)+15,"P01 no speed at half or less MP")
	hero.mp = 65
	check(e._speed(hero,0,runtime.skills.normal_attack) == int(hero.spd),"P01 not applied to ordinary attack")
	check(e._speed(hero,-8,runtime.skills.sancai_counter) == int(hero.spd)-8,"P01 not applied to preparation")

	# Highest threat is public raw action damage, with stable order on ties and missing damage.
	e = basic_core(1,true)
	var enemy2: Dictionary = e.state.encounter.enemies[0].duplicate(true)
	enemy2.id = "e2"
	enemy2.atk = 200
	var encounter2: Dictionary = e.state.encounter.duplicate(true)
	encounter2.enemies.append(enemy2)
	var passive_party := party()
	passive_party[0].passives = ["LX_P01"]
	e.start(encounter2,passive_party)
	check(e._status_value(e.actor_by_id("e2"),"posuan") == 0.1 and e._status_value(e.actor_by_id("e"),"posuan") == 0,"P01 marks highest public damage enemy")
	encounter2.enemies[1].atk = 100
	e.start(encounter2,passive_party)
	check(e._status_value(e.actor_by_id("e"),"posuan") == 0.1 and e._status_value(e.actor_by_id("e2"),"posuan") == 0,"P01 equal threat stable enemy slot")
	for opponent in encounter2.enemies: opponent.rotation[0].erase("hits")
	e.start(encounter2,passive_party)
	check(e._status_value(e.actor_by_id("e"),"posuan") == 0.1,"P01 missing public damage deterministically ties at zero")
	check(e.state.events.filter(func(ev: Dictionary) -> bool: return ev.type == "passive_posuan").size() == 1,"P01 opening only once")
	var saved := JSON.parse_string(JSON.stringify(e.snapshot())) as Dictionary
	check(e.restore(saved),"new status/passive fields survive core JSON restore")
	e.actor_by_id("char_liang_xiao").max_mp = 64
	e.actor_by_id("char_liang_xiao").mp = 32
	check(e._speed(e.actor_by_id("char_liang_xiao"),15,runtime.skills.observe) == 37,"P01 strict above-half excludes exact half")

	e = basic_core()
	e.actor_by_id("char_liang_xiao").skills.append("test_interrupt")
	cast(e,"observe")
	cast(e,"test_interrupt")
	var hit_values: Array = []
	for event in e.state.events:
		if int(event.round) == 2 and event.type == "damage" and event.target == "e": hit_values.append(int(event.amount))
	check(hit_values == [82,82,82],"mingxin multiplies whole multi-hit action once")
	check(e._status_value(e.actor_by_id("char_liang_xiao"),"mingxin") == 0,"multi-hit consumes one marker")
	e = basic_core()
	cast(e,"observe")
	e.actor_by_id("e").vulnerable_through = 2
	cast(e,"normal_attack")
	check(e.actor_by_id("e").hp == 9805,"posuan adds10 points to break vulnerability:100*1.5*1.3=195")

	# Killing/KO the negotiator cannot stand in for a hostage exchange.
	s = session("enc_ch02_antidote_escape")
	s.engine.actor_by_id("char_liang_xiao").atk = 99999
	check(s.set_command("char_liang_xiao","normal_attack","char_toghon",int(s.engine.state.revision)) == "","test nonlethal route")
	check(s.resolve_round(),"attack resolves through shared damage core")
	check(s.engine.actor_by_id("char_toghon").hp == 1 and s.engine.actor_by_id("char_toghon").defeated,"nonlethal leaves1 and incapacitates")
	check(s.engine.state.outcome == "defeat" and s.receipt().is_empty(),"incapacitating negotiator is failed objective, not clear-enemy win")
	s = session("enc_ch02_antidote_escape")
	win_antidote(s)
	check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"completed objective snapshot replays exact terminal state")
	check(s.receipt().objective_evidence.no_human_deaths,"success receipt explicitly proves no human deaths")
	var panel := ObjectiveView.new()
	root.add_child(panel)
	s = session("enc_ch02_protect_qin")
	var view := s.get_view()
	panel.render(view,runtime.skills,false)
	var callbacks: Array = []
	panel.input_submitted.connect(func(action: Dictionary): callbacks.append(action))
	panel._submit_input({"action_id":"move_qin","lane":"right","revision":1})
	check(callbacks.size() == 1 and s.history.is_empty(),"objective panel emits intent only")
	check(s.get_view() == view,"panel leaves engine untouched")
	panel.queue_free()
	await process_frame
	print("Chapter two combat: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
