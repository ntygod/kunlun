extends "res://tests/test_chapter_two.gd"
var app
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.get_window().title=="昆仑（开发版）","neutral title persists on root Window")
	app.saves=Saves.new("user://chapter_two_main_test")
	complete_prologue(app.story)
	app.story.enter_chapter_one()
	while not app.story.state.finished: act(app.story,0)
	app._enter_chapter_two()
	var count := 0
	while not app.story.state.finished and count<160:
		var token: String = app.story.current_token()
		var event: Dictionary = app.story.current_event()
		match event.op:
			"dialogue","stage","branch_feedback","conditional_echoes":
				check(app.mode=="chapter_dialogue","typed presentation routed")
				while app.story.current_token()==token: app._next_line()
			"action":
				var geometry: Dictionary=app.world.get_objective_geometry(event.id)
				check(not geometry.is_empty(),"chapter2 world action registered "+event.id)
				if geometry.is_empty(): break
				if event.kind=="route":
					for point in geometry.waypoints:
						app.world.player.position=point
						app.world._update_paths()
				app.world.player.position=geometry.position
				app._interact()
			"choice":
				var choice: Dictionary=app.story.available_choices()[0]
				app._chapter_choose(choice.id,token)
				app._commit_chapter_choice(token,choice.id)
			"quest_window":
				var pending := ""
				for id in ["ch02_r01","ch02_k01"]:
					if app.story.state.optional[id].status!="archived": pending=id;break
				app._show_optional_window()
				check(app.modal_content.get_child(1).text.contains("未尽的约定" if pending!="" else "都已完成"),"optional window introduction respects completed quests")
				app._confirm_window_closure()
				var closure_button: Button = app.modal_content.get_child(app.modal_content.get_child_count()-1)
				check(closure_button.text == ("记下遗憾，继续行旅" if pending!="" else "继续下一段岁月"),"closure wording respects completed optional quests")
				if pending!="": app._open_optional(pending)
				else: closure_button.pressed.emit()
			"objective_battle":
				var commands: Array = [{"action_id":"move_qin","lane":"right"},{"action_id":"move_qin","lane":"left"}] if event.id == "enc_ch02_protect_qin" else [{"action_id":"listen"},{"action_id":"feign_surrender","lane":"east"},{"action_id":"restrain","target":"char_toghon"},{"action_id":"inspect_antidote"},{"action_id":"exchange","item":"blue_antidote"},{"action_id":"administer","target":"char_hua_qingyuan"},{"action_id":"delay_pursuit","lane":"bridge"},{"action_id":"escort_move","destination":"bridge"},{"action_id":"escort_move","destination":"exit"}]
				for command in commands:
					app._objective_input(command)
					app._chapter_resolve()
				check(app.encounter_session.get_view().outcome=="victory","controller objective victory")
				app._chapter_battle_finish()
			"puzzle","branch_practice":
				if event.op=="puzzle":
					var geometry: Dictionary=app.world.get_objective_geometry(event.entry_id)
					check(not geometry.is_empty(),"puzzle has world entry "+event.entry_id)
					app.world.player.position=geometry.position
					app._interact()
				var turns := 0
				while app.story.current_token()==token and turns<100:
					var definition: Dictionary=app.story.chapter_two.puzzle_definition()
					var session: RefCounted=app.story.chapter_two.make_puzzle()
					var view: Dictionary=session.get_view()
					if definition.guided:
						if definition.id in ["jing_writing","name_practice"]:
							var board: GlyphBoard
							for child in app.modal_content.get_children():
								if child is GlyphBoard: board=child
							check(board!=null,"real glyph widget exists")
							await process_frame
							while not board.done:
								board.tap(board.current_start());board.tap(board.current_end())
						else:
							var values: Array=["抬肘","旋腕","弓步"] if definition.id in ["shadow_practice","step_practice"] else (["吸气","静息","呼气"] if definition.id=="breath_practice" else ["选取本题散页","投入火盆","饮下参汤"])
							app.world.player.position=Vector2([[144,144],[176,144],[176,176]][int(view.state.index)][0],[[144,144],[176,144],[176,176]][int(view.state.index)][1])
							app._registered_puzzle_input({"type":"observe"})
							if definition.id == "shadow_practice":
								app._return_to_shadow()
								app._interact()
								check(app.mode=="chapter_puzzle","shadow practice resumes after real movement mode")
							app._guided_perform(values[int(view.state.index)])
					else:
						var existing_panel = app.registered_puzzle_panel
						existing_panel._selection = 7
						app._registered_puzzle_input(next_input(definition.id,view.state,event.get("id","")))
						if app.story.current_token() == token:
							check(app.registered_puzzle_panel == existing_panel and existing_panel._selection == 7,"same puzzle reuses panel and selected cell")
					turns+=1
		check(app.story.current_token()!=token or app.story.state.finished,"main advances "+token)
		if app.story.current_token()==token and not app.story.state.finished: break
		await process_frame
		count+=1
	check(app.story.state.finished and app.story.state.xp==2090,"main all-side ending reaches2090")
	app._show_journal()
	app._cancel_choice()
	check(app.mode=="ending" and not app.world.player.enabled,"chapter2 ending/journal restores input lock")
	app.queue_free()
	await process_frame
	print("Chapter two main: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
func next_input(id: String,s: Dictionary,event_id: String) -> Dictionary:
	if id=="pz01_tenth": return {"type":"extend" if event_id=="pz01_tenth_overload" else "stop"}
	if id=="r01":
		for i in range(9):
			if int(s.values[i])!=i: return {"type":"place_piece","slot":i,"piece":i}
		if not s.matched: return {"type":"submit"}
		if s.segment=="": return {"type":"select_segment","segment":"borrow_yin_to_balance_yang"}
		if s.method=="": return {"type":"method","value":"keep_all"}
		return {"type":"bind","step":["paste_cover","thread","title"][s.binding.size()]}
	if id=="k01":
		if s.method=="": return {"type":"method","value":"double_difference"}
		var values: Array=[600,8,8,12,18,4,404,10,808,8]
		for i in range(values.size()):
			if s.values[i]!=values[i]: return {"type":"set","index":i,"value":values[i]}
		if s.formula=="": return {"type":"formula","value":"rod_plus_baseline_over_difference"}
		return {"type":"submit"}
	return {"type":"hint" if int(s.hint)<3 else "demo_next"}
