extends "res://tests/test_chapter_two.gd"
const ThirdPuzzle = preload("res://scripts/puzzles/chapter_three_puzzle_resolver.gd")
const Escape = preload("res://scripts/world_actions/shadow_escape.gd")
func chapter_two_ending(optional: bool, branch: int = 0) -> CampaignState:
	var campaign := Campaign.new(base)
	complete_prologue(campaign)
	campaign.enter_chapter_one()
	while not campaign.state.finished: act(campaign,0)
	campaign.enter_chapter_two()
	while not campaign.state.finished:
		if not act_two(campaign,optional,branch): break
	return campaign
func puzzle_actions(id: String) -> Array:
	var result: Array = []
	if id == "interaction_ch03_tea":
		for i in range(3): result.append({"type":"tea_transfer","cup":i,"amount":1})
		result.append({"type":"submit"})
	elif id == "trial_ch03_qingyuan":
		for step in ThirdPuzzle.TRIAL: result.append({"type":step})
	else:
		var n: int = ThirdPuzzle.SIZES[id]
		for i in range(n): result.append({"type":"assign_symbol_to_column","symbol":i,"column":i})
		for i in range(n-2,-1,-1): result.append({"type":"subtract_known_row","row":i,"source":i+1,"numerator":1,"denominator":1})
		for i in range(n): result.append({"type":"enter_value","symbol":i,"numerator":i+1,"denominator":1})
		for i in range(n): result.append({"type":"substitute_back","row":i})
		result.append({"type":"submit"})
	return result
func win_boss(session: RefCounted) -> void:
	for round_index in range(50):
		if session.get_view().outcome != "": break
		var beat: String = session.engine.state.intents[0].beat
		if beat == "release":
			var o: Dictionary = session.engine.state.objective
			while o.position != o.required_handle:
				var index: int = session.engine.POSITIONS.find(o.position)
				var desired: int = session.engine.POSITIONS.find(o.required_handle)
				check(session.apply_input({"action_id":"move_handle","destination":session.engine.POSITIONS[index+(1 if desired>index else -1)]}).accepted,"B01 real handle walk")
			while int(o.pointer) != int(o.required_pointer): check(session.apply_input({"action_id":"rotate_ring","direction":"right"}).accepted,"B01 real ring turn")
			check(session.apply_input({"action_id":"armillary_release","intent_id":session.engine.state.intents[0].intent_id}).accepted,"B01 armed current intent")
		else:
			var skill := "observe" if beat == "charge" else "self_guard"
			check(session.set_command("char_liang_xiao",skill,"char_ming_sanqiu" if skill == "observe" else "char_liang_xiao") == "","B01 lawful command")
		check(session.resolve_round(),"B01 actual round")
	check(session.get_view().outcome == "victory","B01 inherited party wins")
func escape_go(session: RefCounted, x: int, y: int) -> void:
	var guard := 0
	while session.state.position != [x,y] and guard < 100:
		guard += 1
		var dx := signi(x-int(session.state.position[0]))
		var dy := signi(y-int(session.state.position[1])) if dx == 0 else 0
		var result: Dictionary = session.apply_input({"type":"move","dx":dx,"dy":dy})
		check(result.ok,"escape real step")
		if not result.ok: break
func escape_feint(session: RefCounted, target: String) -> void:
	while session.state.phase != 1: session.apply_input({"type":"wait"})
	check(session.apply_input({"type":"feint","target":target}).ok,"escape phase alignment")
func escape_actions(id: String, padding: String, context: Dictionary) -> Array:
	var s := Escape.new()
	s.begin(id,"plan",context)
	if not s.state.sheltered: escape_go(s,144,208)
	if id == "interaction_ch03_shadow_escape":
		s.apply_input({"type":"inspect","target":"yurang"})
		for i in range(2): s.apply_input({"type":"correct_step","index":i})
		escape_go(s,224,208); escape_feint(s,"zhuhai")
		escape_go(s,272,208); s.apply_input({"type":"carry"})
		if padding == "abacus":
			escape_go(s,352,208);escape_go(s,352,112);escape_go(s,304,112)
			for i in range(8): s.apply_input({"type":"rest"})
			escape_go(s,352,112);escape_go(s,352,208)
		escape_go(s,368,208);escape_feint(s,"wuyang");escape_go(s,416,208)
		if padding == "abacus":
			escape_go(s,496,208);escape_go(s,496,112);escape_go(s,448,112)
			for i in range(8): s.apply_input({"type":"rest"})
			escape_go(s,496,112);escape_go(s,496,208);escape_go(s,416,208)
		escape_go(s,496,208);escape_go(s,560,208)
	else:
		if not s.state.sheltered:
			s.apply_input({"type":"inspect","target":"blood_trail"})
			escape_go(s,304,208);escape_go(s,304,112);escape_go(s,224,112)
			s.apply_input({"type":"shelter"})
		s.apply_input({"type":"take_cloak"})
		escape_go(s,256,112);s.apply_input({"type":"guard_animals"})
		escape_go(s,304,112);escape_go(s,304,208);escape_go(s,352,208)
		s.apply_input({"type":"place_cloak"})
		escape_go(s,448,208);escape_go(s,560,208)
		for i in range(80):
			if not s.receipt().is_empty(): break
			s.apply_input({"type":"wait"})
	check(not s.receipt().is_empty(),"planned escape has real receipt")
	return s.input_log.duplicate(true)
func act_three(campaign: CampaignState, branch: int = 0, pattern: int = -1) -> bool:
	var runtime := campaign.chapter_three
	var event := campaign.current_event()
	var token := campaign.current_token()
	match event.op:
		"dialogue","stage","branch_feedback","chapter_echo": return campaign.finish_dialogue(token)
		"action":
			var geometry: Dictionary = runtime.maps[runtime.scene().map_id].actions[event.id]
			var proof := {"map_id":runtime.scene().map_id,"position":geometry.position.duplicate()}
			if event.kind == "route":
				var count: int = runtime.maps[runtime.scene().map_id].paths[event.id].size()
				proof.merge({"index":count,"total":count,"complete":true})
			return campaign.complete_action(token,event.id,proof)
		"choice":
			var selected: int = branch if pattern < 0 else ((pattern >> campaign.state.choices.size()) & 1)
			return campaign.choose(token,campaign.available_choices()[mini(selected,campaign.available_choices().size()-1)].id)
		"puzzle":
			for action in puzzle_actions(event.id): runtime.puzzle_input(token,action)
			return campaign.current_token() != token
		"world_puzzle":
			for action in escape_actions(event.id,runtime.state.padding,runtime.puzzle_context()): runtime.puzzle_input(token,action)
			return campaign.current_token() != token
		"objective_battle":
			print("B01 integrated party: ",runtime.combat_party())
			var session := runtime.make_objective_encounter()
			win_boss(session)
			return runtime.accept_objective(token,session.receipt())
	return false
func chapter_two_subset(mask: int, branch: int = 0) -> CampaignState:
	var campaign := Campaign.new(base)
	complete_prologue(campaign);campaign.enter_chapter_one()
	while not campaign.state.finished: act(campaign,0)
	campaign.enter_chapter_two()
	while not campaign.state.finished:
		if campaign.current_event().op == "quest_window":
			var pending := ""
			for i in range(2):
				var id: String = ["ch02_r01","ch02_k01"][i]
				if mask & (1<<i) and campaign.state.optional[id].status != "archived": pending=id;break
			if pending!="":campaign.chapter_two.open_sidequest(pending)
			else:campaign.chapter_two.close_window(campaign.current_token())
		else:
			if not act_two(campaign,false,branch):break
	return campaign
func run_route(campaign: CampaignState, pattern: int, every_step: bool) -> void:
	var inherited_xp: int=campaign.state.xp
	var inherited_items: Dictionary=campaign.items.duplicate(true)
	check(campaign.enter_chapter_three(),"legitimate ch2 enters ch3")
	check(campaign.state.liang_age==16 and campaign.state.xiaoshuang_age==15,"no extra sixth-year age")
	var steps := 0
	while not campaign.state.finished and steps < 120:
		var token: String = campaign.current_token()
		var old_scene: String = campaign.scene().id
		var event: Dictionary=campaign.current_event()
		if event.op in ["puzzle","world_puzzle","objective_battle"]:
			var before: Dictionary=campaign.export_save()
			check(not campaign.chapter_three.complete(token,{"won":true}),"bare result cannot commit gameplay")
			check(Campaign._normalize_numbers(before)==Campaign._normalize_numbers(campaign.export_save()),"forged completion atomic")
		if event.op=="objective_battle":check(campaign.state.xp==inherited_xp+235,"B01 pre-entry235 actual award")
		if old_scene=="ch03_hostage_exchange" and event.op=="dialogue":
			var rendered: String=JSON.stringify(campaign.dialogue_lines())
			if int(event.start)==0:check(not rendered.contains("扔掉手中") and rendered.contains("挂回腰间"),"wrapped sword retained before hostage performance")
			if int(event.start)==3:
				check(rendered.contains("算盘损毁") if campaign.state.padding=="abacus" else rendered.contains("清心砚裂开"),"offscreen performance follows actual padding")
				check(campaign.items.item_ch02_qingxin_inkstone.form=="intact" and campaign.items.item_ch03_copper_abacus.form=="intact","reservation has not consumed either item before performance")
		if event.op=="chapter_echo" and event.id=="r01_workbook":
			var echo: String=JSON.stringify(campaign.dialogue_lines())
			check(echo.contains("未合算册") if inherited_items.has("item_ch02_unclosed_workbook") else echo.contains("空白纸"),"R01 echo only from owned workbook")
		if old_scene=="ch03_assassin_shadows" and event.op=="dialogue":
			check(not JSON.stringify(campaign.dialogue_lines()).contains("刺穿明归"),"post-shadow no required lethal shoulder attack")
		check(act_three(campaign,0,pattern),"chapter3 advances "+token)
		if campaign.current_token() == token: break
		if every_step or old_scene!=campaign.scene().id or campaign.state.finished:
			var fresh := Campaign.new(base)
			var error: String = fresh.restore(JSON.parse_string(JSON.stringify(campaign.export_save())))
			check(error == "","chapter3 roundtrip "+token+" "+error)
		steps += 1
	check(campaign.state.finished and campaign.state.xp==inherited_xp+1030,"ending exact inherited+1030")
	check(campaign.state.coins==550 and campaign.state.currency_ledger.reward_mq03_coins_once==300,"money inherits250 plus300 once")
	check(campaign.actors.char_hua_xiaoshuang.status=="separated_not_dead","Xiaoshuang separated not dead")
	for id in ["follower_baichier","follower_jinlinger"]:check(campaign.actors[id].status=="sheltered_with_xiaoshuang","animals safe at shelter")
	check(campaign.items.item_ch02_xiaoshuang_medicine.owner=="char_hua_xiaoshuang" and campaign.items.item_ch02_xiaoshuang_medicine.quantity==1,"one real story supply remains with Xiaoshuang")
	var abacus: bool=(pattern & 16)!=0
	check(campaign.items.item_ch02_qingxin_inkstone.form==("intact" if abacus else "broken_fragment"),"unique keepsake actual selected form")
	check(campaign.items.item_ch03_copper_abacus.form==("destroyed" if abacus else "intact"),"abacus exact consumption or outstanding loan")
	check(campaign.state.choices.has("ch03_throne_refusal:reason") and campaign.state.choices.has("ch03_throne_refusal:after"),"two refusal groups independently preserved")
	var rests: Array=[]
	for record in campaign.state.escape_receipts.interaction_ch03_shadow_escape.engine_event_log:
		if record.type=="distinct_cover_rest":rests.append(record.details.pocket)
	check(rests.size()==(2 if abacus else 0),"extra rests only required for actual abacus choice")
	for id in ["item_ch02_unclosed_workbook","item_ch02_first_wrong_page","item_ch02_shadow_measurement_notes","item_ch01_xuanyuan_sword"]:
		check(campaign.items.get(id,{})==inherited_items.get(id,{}),"prior unique item unchanged "+id)
	check(not "tenth_sum_solved" in campaign.state.knowledge and not campaign.items.has("item_taie_sword"),"no fictitious tenth answer or throne sword")
	check(campaign.actors.char_liang_xiao.skill_ranks.LX_A01==2 and campaign.actors.char_liang_xiao.passives==["LX_P01"],"skill inheritance no new permanent grant")
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	for scenario in [[0,0,0],[0,1,16],[1,0,32],[2,1,63],[3,0,16],[3,1,63]]:
		var campaign:=chapter_two_subset(scenario[0],scenario[1])
		run_route(campaign,scenario[2],scenario[0] in [0,3])
	print("Chapter three integrated: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
