extends "res://tests/test_chapter_one.gd"
func act_two(campaign: CampaignState, with_optional: bool, branch: int = 0) -> bool:
	var runtime := campaign.chapter_two
	var event := campaign.current_event()
	var token := campaign.current_token()
	match event.op:
		"dialogue","stage","branch_feedback","conditional_echoes": return campaign.finish_dialogue(token)
		"action":
			var geometry: Dictionary = runtime.maps[runtime.scene().map_id].actions[event.id]
			var proof := {"map_id":runtime.scene().map_id,"position":geometry.position.duplicate()}
			if event.kind == "route":
				var count: int = runtime.maps[runtime.scene().map_id].paths[event.id].size()
				proof.merge({"index":count,"total":count,"complete":true})
			return campaign.complete_action(token,event.id,proof)
		"choice": return campaign.choose(token,campaign.available_choices()[mini(branch,campaign.available_choices().size()-1)].id)
		"quest_window":
			if with_optional:
				for id in ["ch02_r01","ch02_k01"]:
					if campaign.state.optional[id].status != "archived": return runtime.open_sidequest(id)
			return runtime.close_window(token)
		"puzzle","branch_practice":
			var definition := runtime.puzzle_definition()
			var session := runtime.make_puzzle()
			check(session != null,"registered resolver: "+definition.id)
			if session == null: return false
			if definition.guided:
				if definition.id in ["jing_writing","name_practice"]:
					while campaign.current_token() == token:
						var glyph: String = session.get_view().glyph
						var board := GlyphBoard.new()
						board.setup(glyph)
						var points: Array=[]
						for stroke in board.strokes: points.append(stroke[0]);points.append(stroke[-1])
						runtime.puzzle_input(token,{"type":"glyph","glyph":glyph,"strokes":board.strokes.size(),"points":points})
						board.free()
				else:
					var values: Array = ["抬肘","旋腕","弓步"] if definition.id in ["shadow_practice","step_practice"] else (["吸气","静息","呼气"] if definition.id == "breath_practice" else ["选取本题散页","投入火盆","饮下参汤"])
					for i in range(3):
						runtime.puzzle_input(token,{"type":"observe"})
						runtime.puzzle_input(token,{"type":"perform","value":values[i],"position":[[144,144],[176,144],[176,176]][i]})
			elif definition.id == "r01":
				for i in range(9): runtime.puzzle_input(token,{"type":"place_piece","slot":i,"piece":i})
				runtime.puzzle_input(token,{"type":"submit"})
				runtime.puzzle_input(token,{"type":"select_segment","segment":"borrow_yin_to_balance_yang"})
				runtime.puzzle_input(token,{"type":"method","value":"keep_all" if branch == 0 else "keep_later"})
				for step in ["paste_cover","thread","title"]: runtime.puzzle_input(token,{"type":"bind","step":step})
			elif definition.id == "k01":
				runtime.puzzle_input(token,{"type":"method","value":"double_difference" if branch == 0 else "similar_triangles"})
				var values := [600,8,8,12,18,4,404,10,808,8]
				for i in range(values.size()): runtime.puzzle_input(token,{"type":"set","index":i,"value":values[i]})
				runtime.puzzle_input(token,{"type":"formula","value":"rod_plus_baseline_over_difference" if branch == 0 else "shadow_ratio"})
				runtime.puzzle_input(token,{"type":"submit"})
			elif definition.id == "pz01_tenth": runtime.puzzle_input(token,{"type":"extend" if event.id == "pz01_tenth_overload" else "stop"})
			else:
				for i in range(3): runtime.puzzle_input(token,{"type":"hint"})
				var tries := 0
				while campaign.current_token() == token and tries<60:
					runtime.puzzle_input(token,{"type":"demo_next"})
					tries += 1
			return campaign.current_token()!=token
		"objective_battle":
			var session: RefCounted = runtime.make_objective_encounter()
			var commands: Array = [{"action_id":"move_qin","lane":"right"},{"action_id":"move_qin","lane":"left"}] if event.id == "enc_ch02_protect_qin" else [{"action_id":"listen"},{"action_id":"feign_surrender","lane":"east"},{"action_id":"restrain","target":"char_toghon"},{"action_id":"inspect_antidote"},{"action_id":"exchange","item":"blue_antidote"},{"action_id":"administer","target":"char_hua_qingyuan"},{"action_id":"delay_pursuit","lane":"bridge"},{"action_id":"escort_move","destination":"bridge"},{"action_id":"escort_move","destination":"exit"}]
			for command in commands:
				check(session.apply_input(command).accepted,"actual objective input")
				check(session.resolve_round(),"actual enemy objective round")
			check(session.get_view().outcome == "victory","objective win, no HP kill")
			return runtime.accept_objective(token,session.receipt())
	return false
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var previous := Campaign.new(base)
	complete_prologue(previous)
	previous.enter_chapter_one()
	while not previous.state.finished: act(previous,0)
	var old_save := previous.export_save()
	for branch in [0,1,2]:
		var campaign := Campaign.new(base)
		check(campaign.restore(old_save)=="","v2 old chapter remains valid")
		check(campaign.enter_chapter_two(),"explicit chapter2 transition")
		check(campaign.state.xp==345,"entry carries prior XP")
		var count := 0
		while not campaign.state.finished and count<160:
			var token := campaign.current_token()
			check(act_two(campaign,branch>0,branch%2),"chapter event "+token)
			if campaign.current_token()==token and campaign.state.scope=="main": break
			var saved := campaign.export_save()
			var restored := Campaign.new(base)
			var error := restored.restore(JSON.parse_string(JSON.stringify(saved)))
			check(error=="","v3 roundtrip "+token+" "+error)
			if error!="": break
			count+=1
		check(campaign.state.finished,"chapter2 full route completes")
		check(campaign.state.xp==(1440 if branch==0 else 2090),"main/all-side exact XP")
		check(campaign.actors.char_liang_xiao.level==(10 if branch==0 else 12),"chapter2 correct level")
		check(campaign.world_objects.item_ch01_tomb_marker.text=="梁文","paper Jing never changes old tomb")
		check(campaign.items.has("item_ch02_qingxin_inkstone"),"mandatory next chapter inkstone")
		check(campaign.state.coins==250,"chapter coins once")
	print("Chapter two: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
