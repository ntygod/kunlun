extends SceneTree
const Session = preload("res://scripts/combat/chapter_three_encounter.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
const BattleView = preload("res://scripts/ui/chapter_three_battle_panel.gd")
const H := "char_liang_xiao"
const B := "char_ming_sanqiu"
var rules: Dictionary
var runtime: Dictionary
var encounter: Dictionary
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B01: " + message)
func party(xp: int = 1675, missing_hp: int = 72) -> Array:
	var p := Growth.liang_panel(xp,{"max_hp":30,"max_mp":5,"atk":8,"def":5,"spd":1})
	p["hp"] = int(p.max_hp) - missing_hp # Actual GUI chapter-two route carries72 missing HP through growth.
	p.merge({"id":H,"name":"梁萧","team":"party","skills":["normal_attack","self_guard","sancai_counter","observe"],"skill_ranks":{"observe":2},"passives":["LX_P01"]})
	return [p]
func session(xp: int = 1675, missing_hp: int = 72) -> ChapterThreeEncounter:
	return Session.new(rules,runtime,encounter,party(xp,missing_hp),"ch03:b01:test")
func command(s: ChapterThreeEncounter, skill: String) -> void:
	check(s.set_command(H,skill,H if skill == "self_guard" else B,int(s.engine.state.revision)) == "", "command " + skill)
	check(s.resolve_round(),"resolve " + skill)
func input(s: ChapterThreeEncounter, action: Dictionary) -> void:
	check(s.apply_input(action).accepted,"input " + str(action))
func align(s: ChapterThreeEncounter) -> void:
	var o: Dictionary = s.engine.state.objective
	while o.position != o.required_handle:
		var current := s.engine.POSITIONS.find(o.position)
		var desired := s.engine.POSITIONS.find(o.required_handle)
		input(s,{"action_id":"move_handle","destination":s.engine.POSITIONS[current + (1 if desired > current else -1)]})
	while int(o.pointer) != int(o.required_pointer): input(s,{"action_id":"rotate_ring","direction":"right"})
func interrupt(s: ChapterThreeEncounter) -> void:
	align(s)
	input(s,{"action_id":"armillary_release","intent_id":s.engine.state.intents[0].intent_id})
	check(s.resolve_round(),"resolve mechanism")
func win_interrupts(s: ChapterThreeEncounter) -> void:
	for round_index in range(40):
		if s.engine.state.outcome != "": break
		match s.engine.state.intents[0].beat:
			"charge": command(s,"observe")
			"release": interrupt(s)
			"thrust": command(s,"self_guard")
			"shield", "recovery": command(s,"self_guard")
func run() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	runtime = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	encounter = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three_encounters.json")).encounters.enc_ch03_lingtai_ming_sanqiu
	for xp in [1675,2325]:
		var s := session(xp)
		print("B01 real panel ",party(xp))
		win_interrupts(s)
		check(s.engine.state.outcome == "victory","three distinct instrument windows win at XP%d" % xp)
		print("B01 mechanism route XP%d rounds%d HP%d MP%d" % [xp,s.engine.state.round-1,s.engine.actor_by_id(H).hp,s.engine.actor_by_id(H).mp])
		check(s.engine.state.objective.interrupt_ids.size() == 3,"exactly three distinct windows")
		var proof: Dictionary = JSON.parse_string(JSON.stringify(s.victory_receipt()))
		check(not Session.replay_receipt(proof,rules,runtime,encounter,party(xp)).is_empty(),"JSON replay victory")
		check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"terminal snapshot restores")
		proof.objective_evidence.interrupt_count = 99
		check(Session.replay_receipt(proof,rules,runtime,encounter,party(xp)).is_empty(),"forged count rejected")
	for xp in [1675,2325]:
		for uses in [0,2]:
			var s := session(xp)
			win_hp(s, uses, true)
			check(s.engine.state.outcome == "victory" and s.engine.state.objective.victory_route == "phase_two_hp_depleted","actual HP route XP%d instruments%d" % [xp,uses])
			check(s.engine.state.objective.interrupt_count == uses,"HP route does not smuggle three-interrupt win")
			print("B01 HP route XP%d instruments%d rounds%d HP%d MP%d" % [xp,uses,s.engine.state.round-1,s.engine.actor_by_id(H).hp,s.engine.actor_by_id(H).mp])
			check(not Session.replay_receipt(json(s.victory_receipt()),rules,runtime,encounter,party(xp)).is_empty(),"HP route receipt fully replays")
	# Model chapter-two protect/antidote route avoids damage and naturally enters full.
	for uses in [0,2,3]:
		var s := session(1675,0)
		if uses == 3: win_interrupts(s)
		else: win_hp(s,uses,true)
		check(s.engine.state.outcome == "victory","natural model minimum fullHP route wins: %d instruments" % uses)
		check(not Session.replay_receipt(json(s.receipt()),rules,runtime,encounter,party(1675,0)).is_empty(),"model minimum route proof replays")
		print("B01 minimum model route instruments%d rounds%d HP%d" % [uses,s.engine.state.round-1,s.engine.actor_by_id(H).hp])
	test_history_budget()
	test_input_replay()
	test_boundaries()
	test_phase_checkpoint()
	test_damage_and_counter()
	test_panel()
	print("CHAPTER THREE COMBAT %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func win_hp(s: ChapterThreeEncounter, mechanism_uses: int = 0, roundtrip: bool = false, stop_phase_two: bool = false) -> void:
	for i in range(120):
		if s.engine.state.outcome != "" or (stop_phase_two and int(s.engine.state.objective.phase) == 2): return
		var beat: String = s.engine.state.intents[0].beat
		var use_mechanism: bool = int(s.engine.state.objective.interrupt_count) < mechanism_uses
		if use_mechanism and beat == "charge": command(s,"observe")
		elif use_mechanism and beat == "release": interrupt(s)
		else:
			var skill := "normal_attack"
			if beat == "release": skill = "self_guard"
			if beat == "thrust": skill = "sancai_counter"
			command(s,skill)
		if roundtrip: check(s.restore(json(s.snapshot())),"every real HP-route round restores by input replay")

func test_boundaries() -> void:
	var s := session()
	var before := s.snapshot()
	check(not s.apply_input({"action_id":"move_handle","destination":"far"}).accepted,"nonexistent handle denied")
	check(not s.apply_input({"action_id":"rotate_ring","direction":"right","won":true}).accepted,"success flag denied")
	check(not s.apply_input({"action_id":"armillary_release","intent_id":9}).accepted,"intent must be string")
	check(s.snapshot() == before,"malformed inputs atomic")
	input(s,{"action_id":"move_handle","destination":"left"})
	check(not s.apply_input({"action_id":"move_handle","destination":"right"}).accepted,"cannot teleport over center")
	var revision := int(s.engine.state.revision)
	input(s,{"action_id":"rotate_ring","direction":"right","revision":revision})
	check(not s.apply_input({"action_id":"rotate_ring","direction":"right","revision":revision}).accepted,"stale spatial callback denied")
	check(s.restore(json(s.snapshot())),"partially aligned spatial inputs survive JSON save")
	check(s.engine.state.round == 1 and s.engine.state.objective.interrupt_count == 0,"three arbitrary buttons never victory")
	var corrupt := s.snapshot()
	corrupt.state.objective.pointer = 0
	before = s.snapshot()
	check(not s.restore(corrupt) and s.snapshot() == before,"fabricated alignment rejected atomically")
	command(s,"observe")
	var current_id: String = s.engine.state.intents[0].intent_id
	input(s,{"action_id":"armillary_release","intent_id":current_id})
	check(s.resolve_round(),"wrong ring still consumes round")
	check(s.engine.state.objective.interrupt_count == 0 and s.engine.state.objective.last_feedback == "ring_not_aligned","incorrect ring never counts")
	check(s.engine.actor_by_id(H).hp < party()[0].max_hp,"failed mechanism takes real charged attack")
	s = session()
	command(s,"observe")
	input(s,{"action_id":"armillary_release","intent_id":s.engine.state.intents[0].intent_id})
	s.resolve_round()
	check(s.engine.state.objective.last_feedback == "wrong_handle" and s.engine.state.objective.interrupt_count == 0,"wrong handle fails")
	s = session()
	command(s,"self_guard")
	interrupt(s)
	check(s.engine.state.objective.last_feedback == "current_charge_not_observed" and s.engine.state.objective.interrupt_count == 0,"no observe cannot borrow force")
	s = session()
	command(s,"observe")
	align(s)
	input(s,{"action_id":"armillary_release","intent_id":"b01:p1:r999"})
	s.resolve_round()
	check(s.engine.state.objective.interrupt_count == 0,"wrong intent ID cannot borrow force")
	s = session()
	command(s,"observe")
	var old_id: String = s.engine.state.intents[0].intent_id
	interrupt(s)
	check(s.engine.state.objective.interrupt_count == 1,"first authentic charge counts once")
	input(s,{"action_id":"armillary_release","intent_id":old_id})
	s.resolve_round()
	check(s.engine.state.objective.interrupt_count == 1,"old intent cannot count in thrust round")
	while s.engine.state.intents[0].beat != "charge": command(s,"self_guard")
	check(s.engine.state.objective.observed_intent == "","new charge expires prior observation")
	command(s,"self_guard")
	interrupt(s)
	check(s.engine.state.objective.interrupt_count == 1,"prior charge observation cannot authorize new window")
	var slow_config := encounter.duplicate(true)
	slow_config.mechanism_speed = -30 # Boundary fixture, not a production change.
	s = Session.new(rules,runtime,slow_config,party(),"slow:fixture")
	command(s,"observe")
	interrupt(s)
	check(s.engine.state.objective.last_feedback == "release_window_closed" and s.engine.state.objective.interrupt_count == 0,"same inputs after enemy release fail")
	s = session()
	command(s,"observe")
	s.engine.actor_by_id(B).protected_through = 2 # Isolated resilience boundary.
	interrupt(s)
	check(s.engine.state.objective.last_feedback == "tenacity_protection" and s.engine.state.objective.interrupt_count == 0,"protected charge cannot count")

func test_phase_checkpoint() -> void:
	var s := session()
	win_hp(s,1,true,true)
	check(s.engine.state.objective.phase == 2 and s.engine.state.outcome == "","real damage crosses P1 threshold into P2")
	check(s.engine.actor_by_id(B).hp == 850 and s.engine.actor_by_id(B).max_hp == 850,"P2 starts full850")
	check(s.engine.state.intents[0].beat == "charge" and not s.engine.state.intents[0].executed,"fresh P2 intent announced before acting")
	check(s.engine.state.objective.observed_intent == "","old phase observation invalidated")
	check(s.engine.state.objective.interrupt_count == 1,"phase preserves instrument count")
	var checkpoint := s.snapshot()
	check(s.checkpoint_history_size == s.history.size() and s.checkpoint_history_size > 0,"phase checkpoint is derived history prefix")
	var hp: int = s.engine.actor_by_id(H).hp
	var mp: int = s.engine.actor_by_id(H).mp
	check(hp < party()[0].max_hp,"phase transition did not heal Liang")
	var ready: Dictionary = s.engine.actor_by_id(H).ready.duplicate(true)
	for i in range(120):
		if s.engine.state.outcome != "": break
		input(s,{"action_id":"wait"})
		s.resolve_round()
	check(s.engine.state.outcome == "defeat" and s.receipt().is_empty(),"P2 can fail honestly without reward")
	check(s.restore(json(s.snapshot())),"failed P2 snapshot replays")
	s.retry()
	check(s.snapshot() == checkpoint,"retry restores exact trusted P2 checkpoint including prefix and cooldown")
	check(s.engine.actor_by_id(H).hp == hp and s.engine.actor_by_id(H).mp == mp and s.engine.actor_by_id(H).ready == ready,"retry preserves phase entry HPMP/CD")
	var forged := checkpoint.duplicate(true)
	forged.checkpoint_history_size = 0
	check(not s.restore(forged),"cannot spoof retry checkpoint")
	forged = checkpoint.duplicate(true)
	forged.state.actors[0].hp = forged.state.actors[0].max_hp
	check(not s.restore(forged),"cannot heal by forged phase snapshot")
	win_hp(s,1,true)
	check(s.engine.state.outcome == "victory","P2 retry can really win")
	check(not Session.replay_receipt(json(s.receipt()),rules,runtime,encounter,party()).is_empty(),"postretry victory includes verified P1 prefix")
	s = session()
	var original := s.snapshot()
	for i in range(120):
		if s.engine.state.outcome != "": break
		input(s,{"action_id":"wait"})
		s.resolve_round()
	check(s.engine.state.outcome == "defeat","P1 failure by inaction")
	s.retry()
	check(s.snapshot() == original and s.receipt().is_empty(),"P1 retry no reward and exact entry restored")

func test_damage_and_counter() -> void:
	var s := session()
	command(s,"observe")
	var before_hp: int = s.engine.actor_by_id(H).hp
	command(s,"sancai_counter")
	check(s.engine.actor_by_id(H).hp < before_hp and s.engine.state.objective.interrupt_count == 0 and s.engine.state.break_count == 0,"LX_A02 charge has guard and ordinary counter, not interrupt")
	command(s,"self_guard")
	while s.engine.state.intents[0].beat != "thrust": command(s,"self_guard")
	before_hp = s.engine.actor_by_id(H).hp
	command(s,"sancai_counter")
	check(s.engine.state.events.any(func(e: Dictionary) -> bool: return e.type == "induced_miss") and s.engine.state.break_count == 1 and s.engine.state.objective.interrupt_count == 0,"LX_A02 induction is true missed thrust, not instrument count")
	check(s.engine.actor_by_id(B).protected_through == int(s.engine.state.round) and s.engine.actor_by_id(B).vulnerable_through == int(s.engine.state.round),"current resilience and vulnerability last through next round")
	s = session()
	command(s,"observe")
	interrupt(s)
	check(s.engine.actor_by_id(B).hp == 626,"P1 backlash exactly floor680x8%=54 bypasses armor")
	while s.engine.state.intents[0].beat != "shield": command(s,"self_guard")
	command(s,"self_guard")
	check(s.engine.actor_by_id(B).shield == 136,"P1 shield floor680x20%=136")
	var old_shield: int = s.engine.actor_by_id(B).shield
	before_hp = s.engine.actor_by_id(H).hp
	command(s,"normal_attack")
	var absorbed: int = old_shield-int(s.engine.actor_by_id(B).shield)
	check(before_hp-int(s.engine.actor_by_id(H).hp) == int(floor(absorbed*0.2)),"shield reflects20% actual damage incl absorption with no double-defense")
	s = session()
	win_hp(s,0,false,true)
	while s.engine.state.intents[0].beat != "shield": command(s,"self_guard")
	command(s,"self_guard")
	check(s.engine.actor_by_id(B).shield == 170,"P2 shield floor850x20%=170")
	s = session()
	win_hp(s,0,false,true)
	command(s,"observe")
	interrupt(s)
	check(s.engine.actor_by_id(B).hp == 782,"P2 backlash exactly floor850x8%=68")
	check(s.engine.state.objective.interrupt_count == 1,"P2 first real instrument uses the same persistent counter")
	# Induction protection fallback is not an automatic miss.
	s = session()
	command(s,"self_guard")
	command(s,"self_guard")
	s.engine.actor_by_id(B).protected_through = int(s.engine.state.round)
	before_hp = s.engine.actor_by_id(H).hp
	command(s,"sancai_counter")
	check(s.engine.actor_by_id(H).hp < before_hp and s.engine.state.break_count == 0,"protected quick thrust still damages35% self-guard")
	check(not s.engine.state.events.any(func(e: Dictionary) -> bool: return e.type == "induced_miss"),"protected LX_A02 cannot claim an induced miss")
	# Unit boundary fixture: preserve source damage math, give a test-only multi-hit skill.
	var test_runtime := runtime.duplicate(true)
	test_runtime.skills.boundary_multihit = {"kind":"skill","target":"enemy","hits":[10.0,10.0,10.0],"speed":50}
	var test_party := party()
	test_party[0].skills.append("boundary_multihit")
	s = Session.new(rules,test_runtime,encounter,test_party,"multi:fixture")
	s.engine.actor_by_id(B).last_break = 1
	s.engine.actor_by_id(B).protected_through = 2
	s.engine.actor_by_id(B).vulnerable_through = 2
	command(s,"boundary_multihit")
	check(s.engine.actor_by_id(B).hp == 850 and s.engine.state.objective.phase == 2,"multi-hit threshold clamps; no remaining hits touch P2")
	check(s.engine.actor_by_id(B).last_break == 1 and s.engine.actor_by_id(B).protected_through == 2 and s.engine.actor_by_id(B).vulnerable_through == 2,"phase preserves enemy protection and vulnerability")
	check(s.engine.actor_by_id(H).hp == party()[0].hp,"cancelled old intent never sneaks a P2 attack into transition round")
	var boss_damage := 0
	for event in s.engine.state.events:
		if event.type == "damage" and event.target == B: boss_damage += int(event.amount)
	check(boss_damage == 340,"damage log records340 actual loss, not discarded overkill")
	for channel in ["normal","dot","reflection"]:
		var boss: Dictionary = s.engine.actor_by_id(B)
		boss.hp = 20
		boss.defeated = false
		s.engine._branch(s.engine.actor_by_id(H),boss,100000.0,channel,"unit_nonlethal")
		check(boss.hp == 1 and boss.defeated,"all damage channels remain nonlethal: "+channel)

func test_panel() -> void:
	var s := session()
	var panel := BattleView.new()
	root.add_child(panel)
	var before := s.snapshot()
	panel.render(s.get_view(),runtime.skills,s.can_resolve())
	check(s.snapshot() == before,"UI render has no mutable engine authority")
	check(panel.slots.size() == 15,"fixed keyboard-focusable spatial/skill/resolve slots exist")
	panel.free()

func test_input_replay() -> void:
	var s := session()
	var inputs := [{"action_id":"move_handle","destination":"left"},{"action_id":"rotate_ring","direction":"right"},{"action_id":"rotate_ring","direction":"left"}]
	for action in inputs:
		input(s,action)
		check(s.restore(json(s.snapshot())),"every partial setup input survives JSON replay")
	check(s.set_command(H,"observe",B,int(s.engine.state.revision)) == "","pending observe command")
	check(s.restore(json(s.snapshot())),"pending command restores without resolve")
	s.resolve_round()
	input(s,{"action_id":"armillary_release","intent_id":s.engine.state.intents[0].intent_id})
	check(s.restore(json(s.snapshot())),"pending release restores before consumption")
	var before_mp: int = s.engine.actor_by_id(H).mp
	s.resolve_round()
	check(s.engine.state.objective.interrupt_count == 1,"restored input produces one real interrupt")
	check(int(s.engine.actor_by_id(H).mp) >= before_mp and int(s.engine.actor_by_id(H).ready.objective_action) == int(s.engine.state.round),"mechanism zero cost and CD0 uses regular action")
	check(s.engine.state.commands.is_empty(),"mechanism action cannot leave extra queued attack")
	var record := s.snapshot()
	record.history.append({"op":"resolve","won":true})
	check(not s.restore(record),"extra resolve fields denied")
	record = s.snapshot()
	record.history[0].input.destination = "right"
	check(not s.restore(record),"tampered actual spatial input cannot restore observed state")

func test_history_budget() -> void:
	var s := session()
	for i in range(4100):
		var result := s.apply_input({"action_id":"rotate_ring","direction":"right"})
		check(bool(result.accepted) == (i < Session.MAX_SPATIAL_EDITS_PER_ROUND),"bounded accepted spatial history")
	check(s.history.size() == Session.MAX_SPATIAL_EDITS_PER_ROUND,"overflow attempts do not enlarge history")
	check(s.restore(json(s.snapshot())),"over4096 attempted inputs preserve self-restorable snapshot")
	check(not s.can_resolve(),"space budget alone did not fabricate action")
	for i in range(Session.MAX_COMMAND_EDITS_PER_ROUND):
		check(s.set_command(H,"observe",B,int(s.engine.state.revision)) == "","separate command budget remains after spatial cap")
	check(s.set_command(H,"self_guard",H,int(s.engine.state.revision)) != "","command edit bound enforced")
	check(s.can_resolve() and s.restore(json(s.snapshot())),"full edit budgets leave queued action and replay valid")
	check(s.resolve_round(),"resolve always available after command budget exhausted")
	check(int(s.get_view().objective.input_budget.spatial_remaining) == Session.MAX_SPATIAL_EDITS_PER_ROUND,"next round restores spatial budget")
	check(int(s.get_view().objective.input_budget.command_remaining) == Session.MAX_COMMAND_EDITS_PER_ROUND,"next round restores command budget")
	interrupt(s)
	win_interrupts(s)
	check(s.engine.state.outcome == "victory","can finish after hitting edit budgets")
	check(not Session.replay_receipt(json(s.receipt()),rules,runtime,encounter,party()).is_empty(),"budget-boundary victory proof fully replayable")
	# Saturate every round under the actual120-round content bound; no unbounded log.
	var endurance_fixture := party()
	endurance_fixture[0].max_hp = 1000000 # History-limit unit fixture only; never balance evidence.
	endurance_fixture[0].hp = 1000000
	s = Session.new(rules,runtime,encounter,endurance_fixture,"history:120rounds")
	for round_index in range(int(encounter.max_rounds)):
		if s.engine.state.outcome != "": break
		for i in range(Session.MAX_SPATIAL_EDITS_PER_ROUND):
			s.apply_input({"action_id":"rotate_ring","direction":"right"})
		for i in range(Session.MAX_COMMAND_EDITS_PER_ROUND): s.set_command(H,"self_guard",H,int(s.engine.state.revision))
		s.resolve_round()
	check(s.history.size() == 3960 and s.engine.state.objective.failure == "time_expired" and s.restore(json(s.snapshot())),"full120-round saturated history reaches3960 and restores defeat")
	s.retry()
	check(s.history.is_empty() and s.restore(json(s.snapshot())),"retry after history saturation restores trusted phase start")
