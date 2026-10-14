extends SceneTree
const Session = preload("res://scripts/combat/chapter_four_encounter.gd")
const Driver = preload("res://tests/chapter_four_battle_driver.gd")
const BattleUI = preload("res://scripts/ui/chapter_four_battle_panel.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
const H := "char_liang_xiao"
const L := "char_liu_yingying"
const F := "char_huo_zhenren"
var rules: Dictionary
var runtime: Dictionary
var data: Dictionary
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CH04 combat: "+message)
func party(hp: int = 284, xp: int = 3420) -> Array:
	var h := Growth.liang_panel(xp,{"max_hp":60,"max_mp":10,"atk":16,"def":10,"spd":2})
	h.merge({"id":H,"name":"梁萧","team":"party","hp":hp,"skills":["normal_attack","self_guard","guard_ally","observe","sancai_counter"],"passives":["LX_P01"],"skill_ranks":{"observe":2}},true)
	var l := Growth.actor_panel(L,xp,{"max_hp":50,"max_mp":10,"atk":15,"def":8,"spd":4})
	l.merge({"id":L,"name":"柳莺莺","team":"party","hp":int(l.max_hp)-40,"skills":["normal_attack","self_guard","guard_ally","LYY_A01","LYY_A02"],"passives":["LYY_P01"],"internal_skill":"LYY_N01","skill_ranks":{"LYY_A01":1,"LYY_A02":1}},true)
	return [h,l]
func session(method: String = "lamp",hp: int = 284,id: String = "enc_ch04_tavern_escape",xp: int = 3420) -> ChapterFourEncounter:
	var e: Dictionary = data.encounters[id].duplicate(true)
	e.context = {"environment_method":method}
	return Session.new(rules,runtime,e,party(hp,xp),"ch04:test")
func inp(s: ChapterFourEncounter,actor: String,action: String,destination: String = "") -> void:
	var input := {"actor_id":actor,"action_id":action}
	if destination != "": input["destination" if action == "move" else "target"] = destination
	var result := s.apply_input(input)
	check(result.accepted,"input %s %s: %s" % [actor,action,result])
func cmd(s: ChapterFourEncounter,actor: String,skill: String,target: String) -> void: check(s.set_command(actor,skill,target)=="","command "+skill)
func resolve(s: ChapterFourEncounter) -> void:
	check(s.resolve_round(),"resolve")
	print("round ",s.engine.state.round-1," H ",s.engine.actor_by_id(H).hp," L ",s.engine.actor_by_id(L).hp," outcome ",s.engine.state.outcome)
func lamp(s: ChapterFourEncounter) -> void:
	Driver.new(check).lamp(s)

func oil(s: ChapterFourEncounter) -> void:
	Driver.new(check).oil(s)

func low_route(s: ChapterFourEncounter) -> void:
	Driver.new(check).low_route(s)

func has_event(s: ChapterFourEncounter,type: String) -> bool:
	for event in s.engine.state.events:
		if event.type == type: return true
	return false
func json(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value))
func r02(s: ChapterFourEncounter) -> void:
	Driver.new(check).r02(s)

func edge_tests() -> void:
	var s := session()
	check(s.set_command(H,"LYY_A02",F)=="skill_unavailable","Liang cannot borrow Liu martial")
	check(s.set_command(L,"LYY_A03",F)=="skill_unavailable","no R02 skill before earned")
	check(s.set_command(L,"LYY_A01",H)=="invalid_target","induce cannot target ally")
	check(s.set_command(L,"guard_ally",L)=="invalid_target","ally guard excludes self")
	check(s.set_command(L,"normal_attack",F,0)=="stale_revision","stale command rejected")
	check(not s.apply_input({"actor_id":H,"action_id":"move","destination":"window"}).accepted,"nonadjacent movement blocked")
	check(not s.apply_input({"actor_id":H,"action_id":"drop_lamp"}).accepted,"lamp cannot be remotely pressed")
	check(not s.apply_input({"actor_id":L,"action_id":"secure_anchor"}).accepted,"no win button")
	check(s.receipt().is_empty(),"unfinished receipt empty")
	cmd(s,H,"self_guard",H)
	check(not s.can_resolve(),"both actor commands required")
	for i in range(3): cmd(s,H,"self_guard",H)
	check(s.set_command(H,"self_guard",H)=="round_edit_limit_resolve_available","own slot edit budget enforced")
	cmd(s,L,"self_guard",L)
	check(s.can_resolve(),"other actor slot reserved despite edit spam")
	resolve(s)
	check(s.restore(json(s.snapshot())),"midbattle JSON restore")
	var forged: Dictionary = json(s.snapshot());forged.state.actors[0].hp += 1
	check(not s.restore(forged),"raw healed snapshot rejected")
	s.retry();check(int(s.engine.actor_by_id(H).hp)==284,"retry preserves entry injury")
	check(s.history.is_empty() and s.receipt().is_empty(),"retry clears proof without rewards")
	# Induction redirects actual point-name, respects protection, and has normal CD.
	s = session()
	s.engine.state.objective.positions["ch04_guard"] = "jar"
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A01","ch04_guard");resolve(s)
	check(has_event(s,"redirected") and has_event(s,"induced_miss"),"A01 redirects and induces once")
	check(s.set_command(L,"LYY_A01","ch04_guard")=="cooldown","A01 cooldown real")
	check(has_event(s,"mana"),"induce grants bounded mana")
	s = session()
	s.engine.actor_by_id("ch04_guard").protected_through = 1
	s.engine.state.objective.positions["ch04_guard"] = "jar"
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A01","ch04_guard");resolve(s)
	check(has_event(s,"redirected") and not has_event(s,"induced_miss"),"protected enemy redirects without cancellation")
	# N01 first hit shield and preparation cannot be repeatedly refreshed.
	check(not s.engine.actor_by_id(L).n01_shield,"N01 next-hit shield consumed on real hit")
	# A02 costs half only for first normal action; its DOT starts next round, lasts two.
	s = session()
	check(s.engine.skill_cost(s.engine.actor_by_id(L),s.engine.content.skills.LYY_A02)==6,"P01 half-cost first action")
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A02",F);resolve(s)
	check(s.engine.skill_cost(s.engine.actor_by_id(L),s.engine.content.skills.LYY_A02)==12,"P01 not refreshed next round")
	check(has_event(s,"pain_tick"),"A02 DOT next-round tick")
	check(s.engine._status_value(s.engine.actor_by_id(F),"speed_down")>=0.15,"A02 speed slow source15percent")
	# Exact smoke ray and lifetime, never a random all-screen miss switch.
	s = session()
	inp(s,H,"move","lamp");inp(s,L,"move","side");resolve(s)
	inp(s,H,"drop_lamp");inp(s,L,"clear_civilians");resolve(s)
	check(s.engine._ray_smoked("fire","window") and not s.engine._ray_smoked("fire","lamp"),"smoke blocks intersecting ray only, exposed lamp remains targetable")
	inp(s,H,"move","window");cmd(s,L,"self_guard",L);resolve(s)
	check(has_event(s,"smoke_blocked_ray"),"ranged enemy performs actual reposition behind smoke")
	check(not s.engine._ray_smoked("fire","window"),"smoke expires after cast round and following round")
	# Oil is a genuine paid two-action edge, side corridor costs one.
	s = session("oil")
	inp(s,H,"move","side");inp(s,L,"move","jar");resolve(s)
	cmd(s,H,"self_guard",H);inp(s,L,"spill_oil");resolve(s)
	inp(s,H,"move","jar");cmd(s,L,"self_guard",L);resolve(s)
	check(s.engine.state.objective.positions[H]=="side","oil first movement remains in place")
	inp(s,H,"move","jar");cmd(s,L,"self_guard",L);resolve(s)
	check(s.engine.state.objective.positions[H]=="jar","oil second movement arrives")
	# Unconscious Liu cannot issue either channel; downed ally ends objective without XP.
	s = session();s.engine.actor_by_id(L).controllable = false
	check(s.set_command(L,"self_guard",L)=="actor_unavailable","sleeping Liu martial rejected")
	check(not s.apply_input({"actor_id":L,"action_id":"move","destination":"jar"}).accepted,"sleeping Liu world command rejected")
	s = session();s.engine.actor_by_id(L).hp = 1
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A01",F);resolve(s)
	cmd(s,H,"self_guard",H);cmd(s,L,"normal_attack",F);resolve(s)
	check(s.engine.state.outcome=="defeat" and s.receipt().is_empty(),"ally down cannot produce victory")
	s.retry();check(int(s.engine.actor_by_id(L).hp)==429,"defeat retry trusted initial party, not injected HP")
	# Earned A03 front-row strike, ordinary cooldown, not an extra command.
	var p := party();p[1].skills.append("LYY_A03")
	s = Session.new(rules,runtime,data.encounters.enc_ch04_r02_reclaim,p,"a03:test")
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A03","r02_guard_east");resolve(s)
	check(s.set_command(L,"LYY_A03","r02_guard_east")=="cooldown","A03 real CD2")
	check(s.engine._status_value(s.engine.actor_by_id("r02_guard_west"),"imbalance")>0,"A03 affects front row")
	# Defeated nonlethal units are ineligible for attacks, DOT and reward farming.
	s = session("lamp",16,"enc_ch04_r02_reclaim",3020);r02(s)
	check(s.engine.state.outcome=="victory" and int(s.encounter.xp)==0,"R02 minimum16HP, zero encounter XP")
	for actor in s.engine.state.actors:
		if actor.team=="enemy": check(int(actor.hp)==1 and actor.defeated,"R02 nonlethal floor all channels")
	check(not Session.replay_receipt(json(s.receipt()),rules,runtime,s.encounter,party(16,3020)).is_empty(),"R02 proof JSON replay")
	var receipt: Dictionary = json(s.receipt());receipt.objective_evidence.documents_taken = false
	check(Session.replay_receipt(receipt,rules,runtime,s.encounter,party(16,3020)).is_empty(),"forged document proof refused")

	s = session("lamp",16,"enc_ch04_r02_reclaim",3020)
	Driver.new(check).r02_disarm(s)
	check(s.engine.state.outcome=="victory" and int(s.engine.actor_by_id(H).hp)==16,"R02 non-damage five-round weapon objective")
	for actor in s.engine.state.actors:
		if actor.team=="enemy": check(int(actor.hp)==int(actor.max_hp) and not actor.defeated and not actor.weapon,"living full-HP disarmed guards permit documents")
	check(not Session.replay_receipt(json(s.receipt()),rules,runtime,s.encounter,party(16,3020)).is_empty(),"R02 non-damage original document receipt replay")

	s = session("lamp",284,"enc_ch04_r02_reclaim")
	cmd(s,H,"self_guard",H);inp(s,L,"disarm","r02_guard_west");resolve(s)
	var unarmed_damage := false
	for event in s.engine.state.events:
		if event.type=="damage" and event.source=="r02_guard_west": unarmed_damage = is_equal_approx(float(event.detail.raw),47.0*0.4) and int(event.amount)>0
	check(unarmed_damage and has_event(s,"unarmed_attack"),"same-round disarm converts queued attack to real unarmed damage, not cancelled")
	check("徒手" in str(s.engine.state.intents[1].name),"disarmed next-round intent explicitly says unarmed")

func pain_rounds(s: ChapterFourEncounter) -> Array:
	var result: Array = []
	for event in s.engine.state.events:
		if event.type == "pain_tick": result.append(int(event.round))
	return result
func dot_tests() -> void:
	var s := session()
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A02",F);resolve(s)
	check(pain_rounds(s)==[2],"delayed DOT first tick T+1 only")
	check(s.restore(json(s.snapshot())),"restore at pending second DOT tick")
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	check(pain_rounds(s)==[2,3],"delayed DOT exactly next two round starts")
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	check(pain_rounds(s)==[2,3],"DOT expires without third tick")
	s = session()
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A02",F);resolve(s)
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A02",F);resolve(s)
	var pain_count := 0
	for effect in s.engine.actor_by_id(F).statuses:
		if effect.kind == "luo_pain": pain_count += 1
	check(pain_count==1 and pain_rounds(s)==[2,3],"refresh one layer, no immediate extra tick")
	check(s.restore(json(s.snapshot())),"refreshed DOT JSON restore")
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	check(pain_rounds(s)==[2,3,4],"refresh replaces remainder with T+1/T+2")
	s = session();s.engine.actor_by_id(F)["boss"] = true
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A02",F);resolve(s)
	for event in s.engine.state.events:
		if event.type == "pain_tick": check(int(event.amount)==5,"boss DOT capped floor1percent maxHP")
	s.engine.actor_by_id(F).hp=1
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	check(int(s.engine.actor_by_id(F).hp)==1 and s.engine.actor_by_id(F).defeated,"DOT routes through nonlethal floor")
	var count := pain_rounds(s).size()
	cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	check(pain_rounds(s).size()==count,"defeated target cannot yield repeated DOT effects")

func panel_tests() -> void:
	for window_size in [Vector2i(640,360),Vector2i(1178,814),Vector2i(1280,720)]:
		root.size = window_size
		await process_frame
		var host := PanelContainer.new()
		host.position = Vector2(20,20);host.size = Vector2(mini(850,window_size.x-40),mini(510,window_size.y-40))
		var theme_data := Theme.new();theme_data.default_font = load("res://assets/fonts/kunlun_ui.ttf");theme_data.default_font_size = 20
		var style := StyleBoxFlat.new();style.content_margin_left=24;style.content_margin_right=24;style.content_margin_top=16;style.content_margin_bottom=16
		theme_data.set_stylebox("panel","PanelContainer",style);host.theme=theme_data
		root.add_child(host)
		var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;host.add_child(scroll)
		var column := VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(column)
		var panel := BattleUI.new();column.add_child(panel)
		var s := session();check(s.set_command(H,"normal_attack",F)=="","arranged command exists before UI selector changes");panel.render(s.get_view(),runtime.skills,s.can_resolve())
		for i in range(4): await process_frame
		var names := panel.slots.keys()
		var bounds := {}
		for id in names:
			bounds[id] = panel.slots[id].get_global_rect()
			check(scroll.get_global_rect().encloses(bounds[id]),"all controls fit actual Chinese theme %s %s" % [window_size,id])
		for label in panel.labels: check(scroll.get_global_rect().encloses(label.get_global_rect()),"status text visible with all controls")
		check(panel.slots.has(H+"_skills") and panel.slots.has(L+"_skills"),"two permanent actor controls")
		check(panel.intent_text.max_lines_visible==-1 and panel.intent_text.autowrap_mode!=TextServer.AUTOWRAP_OFF,"full intent content wraps without line limit")
		for intent in s.engine.state.intents: check(str(intent.name) in panel.intent_text.text,"each enemy intent retained in full")
		check(panel.intent_scroll.get_v_scroll_bar().max_value>panel.intent_scroll.size.y,"long public intents expose vertical scrolling")
		panel.intent_scroll.grab_focus()
		var end_key := InputEventKey.new();end_key.keycode=KEY_END;end_key.pressed=true
		root.push_input(end_key,true);await process_frame
		check(panel.intent_scroll.scroll_vertical>0,"keyboard reaches second complete enemy intent")
		check(scroll.get_global_rect().encloses(panel.slots.resolve.get_global_rect()),"intent scrolling never hides resolve controls")
		var emissions: Array = []
		panel.command_requested.connect(func(actor,skill,target,revision): emissions.append([actor,skill,target,revision]))
		var untouched := s.snapshot()
		var skills: OptionButton = panel.slots[H+"_skills"]
		var targets: OptionButton = panel.slots[H+"_targets"]
		# Enemy target initially selected; self-guard explicitly shows Liang immediately.
		skills.select(1);skills.item_selected.emit(1)
		check(targets.get_item_metadata(targets.selected)==H and not panel.slots[H+"_command"].disabled,"self-guard auto-selects visible self without extra target action")
		for index in range(targets.item_count): check(targets.is_item_disabled(index)==(targets.get_item_metadata(index)!=H),"self skill disables every non-self target")
		check(emissions.is_empty() and s.snapshot()==untouched,"changing skill/target never submits or changes an arranged command")
		panel.slots[H+"_command"].pressed.emit()
		check(emissions.size()==1 and emissions[0]==[H,"self_guard",H,int(s.engine.state.revision)],"explicit button emits correct self-target revisioned signal")
		skills.select(0);skills.item_selected.emit(0)
		check(targets.get_item_metadata(targets.selected)==F,"enemy skill selects first legal enemy after self")
		targets.select(3);targets.item_selected.emit(3)
		skills.select(3);skills.item_selected.emit(3)
		check(targets.get_item_metadata(targets.selected)=="ch04_guard","enemy skill preserves valid player-chosen enemy")
		skills.select(2);skills.item_selected.emit(2)
		check(targets.get_item_metadata(targets.selected)==L,"guard selects its sole legal teammate visibly")
		check(s.snapshot()==untouched and emissions.size()==1,"later selector changes still do not mutate battle")
		# A future larger roster must not silently choose among multiple allies.
		var multiple: Dictionary = s.get_view()
		var guest: Dictionary = multiple.actors[1].duplicate(true);guest.id="test_guest";guest.name="客人";multiple.actors.append(guest)
		multiple.legal_commands[H].append({"skill_id":"guard_ally","target_id":"test_guest"})
		panel.render(multiple,runtime.skills,false)
		for i in range(4): await process_frame
		skills = panel.slots[H+"_skills"];targets = panel.slots[H+"_targets"]
		check(targets.get_item_metadata(targets.selected)==L,"existing legal teammate choice survives larger ally list")
		skills.select(0);skills.item_selected.emit(0)
		skills.select(2);skills.item_selected.emit(2)
		check(targets.selected==-1 and panel.slots[H+"_command"].disabled,"ambiguous ally choice requires player selection")
		check(s.snapshot()==untouched,"view-only target changes preserve previously compiled normal attack")
		panel.render(s.get_view(),runtime.skills,false)
		for i in range(4): await process_frame
		panel.show_details();await process_frame
		var popup_style: StyleBoxFlat = panel.details.get_theme_stylebox("panel")
		check(popup_style.bg_color.a==1.0,"rules log opaque popup")
		panel.details.hide()
		panel.slots[L+"_actions"].grab_focus()
		s.engine.actor_by_id(L).defeated = true
		panel.render(s.get_view(),runtime.skills,false)
		for i in range(4): await process_frame
		check(panel.slots.keys()==names,"downed actor controls never add/remove slots")
		for id in names: check(panel.slots[id].get_global_rect()==bounds[id],"fixed control position after downed actor "+id)
		check(root.gui_get_focus_owner()==panel.slots[L+"_actions"],"keyboard focus survives redraw")
		var weak: WeakRef = weakref(panel.details);host.queue_free();await process_frame;await process_frame
		check(weak.get_ref()==null,"popup freed with panel")

func run() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	runtime = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_four_encounters.json"))
	print("Actual test panels ",party())
	for method in ["lamp","oil"]:
		var s := session(method)
		if method == "lamp": lamp(s)
		else: oil(s)
		check(s.engine.state.outcome == "victory",method+" natural284 win")
		var proof: Dictionary = JSON.parse_string(JSON.stringify(s.receipt()))
		check(not Session.replay_receipt(proof,rules,runtime,s.encounter,party()).is_empty(),method+" JSON replay")
		check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),method+" snapshot")
	for method in ["lamp","oil"]:
		var low := session(method,66,"enc_ch04_tavern_escape",3020)
		low_route(low)
		check(low.engine.state.outcome == "victory",method+" lowest66 route")
		print("LOW ",method," ",low.engine.state.outcome," hp ",low.engine.actor_by_id(H).hp)
	for sample in [[2770,87],[3170,88],[3420,89]]:
		for method in ["lamp","oil"]:
			var low := session(method,sample[1],"enc_ch04_tavern_escape",sample[0]);low_route(low)
			check(low.engine.state.outcome=="victory","minimum legal matrix %s %s" % [sample,method])
			check(not Session.replay_receipt(json(low.receipt()),rules,runtime,low.encounter,party(sample[1],sample[0])).is_empty(),"minimum matrix JSON replay")
	edge_tests()
	dot_tests()
	await panel_tests()
	print("Chapter04 combat checks %d failures %d" % [checks,failures])
	quit(1 if failures else 0)
