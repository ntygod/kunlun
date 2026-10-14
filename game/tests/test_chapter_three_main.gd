extends "res://tests/test_chapter_three.gd"
var app
class TrackingStore extends SaveStore:
	var writes := 0
	var fail_auto := false
	var fail_manual := false
	func save_game(story: RefCounted, slot: String = "manual") -> String:
		writes += 1
		if (fail_auto and slot=="auto") or (fail_manual and slot=="manual"): return "模拟磁盘不可写"
		return super.save_game(story,slot)
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.saves=TrackingStore.new("user://chapter_three_main_test")
	app.story=chapter_two_ending(true)
	app._enter_chapter_three()
	check(app.story.active_chapter==3,"chapter2 ending enters actual main3")
	var guard:=0
	while not app.story.state.finished and guard<120:
		var token: String=app.story.current_token()
		var event: Dictionary=app.story.current_event()
		match event.op:
			"dialogue","stage","branch_feedback","chapter_echo":
				check(app.mode=="chapter_dialogue","chapter3 dialogue routed "+token)
				while app.story.current_token()==token: app._next_line()
			"action":
				var geometry: Dictionary=app.world.get_objective_geometry(event.id)
				check(not geometry.is_empty(),"chapter3 world geometry "+event.id)
				if geometry.is_empty():break
				if event.kind!="route":
					app._process(0)
					check("目标在" in app.objective.text or "按E交互" in app.objective.text,"interaction target direction is visible "+event.id)
				if event.kind=="route":
					for point in geometry.waypoints:
						app.world.player.position=point;app.world._update_paths()
					check(app.world.player.position.distance_to(geometry.position)<=float(geometry.radius),"route ends at actual interaction "+event.id)
				else: app.world.player.position=geometry.position
				app._interact()
			"choice":
				var choice: Dictionary=app.story.available_choices()[-1]
				app._chapter_choose(choice.id,token)
				app._commit_chapter_choice(token,choice.id)
			"puzzle":
				var geometry: Dictionary=app.world.get_objective_geometry(event.entry_id)
				app.world.player.position=geometry.position
				app._interact()
				check(app.mode=="chapter_puzzle","chapter3 puzzle actual panel")
				app.saves.fail_auto=true;app._return_from_puzzle()
				check(app.mode=="chapter_puzzle","failed checkpoint retains live puzzle panel")
				app.saves.fail_auto=false
				for action in puzzle_actions(event.id):
					var panel=app.registered_puzzle_panel
					var disk_writes: int=app.saves.writes
					app._registered_puzzle_input(action)
					if app.story.current_token()==token:
						check(panel==app.registered_puzzle_panel,"chapter3 puzzle retains controls")
						check(app.saves.writes==disk_writes,"intermediate puzzle input avoids full disk replay")
			"world_puzzle":
				var geometry: Dictionary=app.world.get_objective_geometry(event.entry_id)
				app.world.player.position=geometry.position
				app._interact()
				check(app.mode=="world_puzzle" and not app.world.player.enabled,"world puzzle disables free physics")
				var rt: ChapterRuntime=app.story.current_chapter_runtime()
				var paused := false
				var keyboard_moved := false
				for action in escape_actions(event.id,rt.state.padding,rt.puzzle_context()):
					if action.get("type", "") == "move" and not keyboard_moved:
						var writes_before: int=app.saves.writes
						var marker: Dictionary=app._world_milestone()
						app.actions.get_child(1).grab_focus()
						var key := InputEventKey.new()
						key.keycode = KEY_RIGHT if int(action.dx)>0 else (KEY_LEFT if int(action.dx)<0 else (KEY_DOWN if int(action.dy)>0 else KEY_UP))
						key.physical_keycode=key.keycode
						key.pressed = true
						var before: Array = app.story.current_chapter_runtime().make_puzzle().get_view().world_state.player_position.duplicate()
						Input.parse_input_event(key)
						await process_frame
						key.pressed = false;Input.parse_input_event(key)
						check(app.story.current_chapter_runtime().make_puzzle().get_view().world_state.player_position!=before,"focused button does not swallow world arrow")
						if marker==app._world_milestone(): check(app.saves.writes==writes_before,"ordinary controlled step avoids strict disk replay")
						keyboard_moved=true
					else: app._world_puzzle_input(action)
					if not paused and app.story.current_token()==token:
						var saved_world: Dictionary=app.story.current_chapter_runtime().make_puzzle().snapshot()
						app.saves.fail_auto=true;app._show_menu()
						check(app.mode=="world_puzzle","failed checkpoint retains controlled world")
						app.saves.fail_auto=false
						var save_key := InputEventKey.new()
						save_key.keycode=KEY_F5;save_key.physical_keycode=KEY_F5;save_key.pressed=true
						app._input(save_key)
						check(app.notice.text.contains("已保存"),"world F5 saves without opening menu")
						app._show_menu();app._load("manual")
						check(app.mode=="world_puzzle" and not app.world.player.enabled,"world menu/load resumes controlled grid without free-movement leak")
						check(EncounterSession.equivalent(saved_world,app.story.current_chapter_runtime().make_puzzle().snapshot()),"partial world session survives UI reload")
						paused=true
			"objective_battle":
				check(app.mode=="chapter_battle","B01 actual panel")
				await drive_boss_ui()
				check(app.encounter_session.get_view().outcome=="victory","B01 through main wins")
				app._chapter_battle_finish()
		check(app.story.current_token()!=token or app.story.state.finished,"main3 advances "+token)
		if app.story.current_token()==token and not app.story.state.finished:break
		await process_frame
		guard+=1
	check(app.story.state.finished and app.story.state.xp==3120,"main3 both-side ending3120")
	check(app.story.items.item_ch02_qingxin_inkstone.form=="intact","abacus choice retains intact inkstone")
	check(app.story.items.item_ch03_copper_abacus.form=="destroyed","actual abacus consumed")
	app._show_journal()
	check(app.mode=="journal","chapter3 ending journal opens")
	app._save()
	app._load("manual")
	check(app.story.state.finished and app.story.state.xp==3120,"main3 terminal manual load")
	check(app.mode=="ending","loaded terminal shows archive")
	var ending_key:=InputEventKey.new()
	ending_key.keycode=KEY_F5;ending_key.physical_keycode=KEY_F5;ending_key.pressed=true
	app.modal_content.get_child(2).grab_focus()
	var writes_before:int=app.saves.writes
	Input.parse_input_event(ending_key);await process_frame
	check(app.saves.writes==writes_before+1 and app.notice.text.contains("已保存"),"focused archive F5 uses save entry")
	var terminal_bytes:=FileAccess.get_file_as_string(app.saves.directory+"/manual.json")
	var terminal_state:Dictionary=app.story.export_save()
	app.saves.fail_manual=true
	Input.parse_input_event(ending_key);await process_frame
	check(app.notice.text.contains("不可写"),"archive F5 reports save failure")
	check(FileAccess.get_file_as_string(app.saves.directory+"/manual.json")==terminal_bytes,"failed archive F5 preserves disk")
	check(EncounterSession.equivalent(app.story.export_save(),terminal_state),"failed archive F5 preserves state")
	app.saves.fail_manual=false
	ending_key.echo=true;writes_before=app.saves.writes
	app._input(ending_key)
	check(app.saves.writes==writes_before,"archive F5 echo ignored")

	app.queue_free();await process_frame
	print("Chapter three main: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
func drive_boss_ui() -> void:
	for round_index in range(60):
		if app.encounter_session.get_view().outcome!="":break
		var session: RefCounted=app.encounter_session
		var writes_before: int=app.saves.writes
		var beat: String=session.engine.state.intents[0].beat
		if beat=="release":
			var o: Dictionary=session.engine.state.objective
			while o.position!=o.required_handle:
				var index: int=session.engine.POSITIONS.find(o.position)
				var desired: int=session.engine.POSITIONS.find(o.required_handle)
				app._objective_input({"action_id":"move_handle","destination":session.engine.POSITIONS[index+(1 if desired>index else -1)]})
			while int(o.pointer)!=int(o.required_pointer):app._objective_input({"action_id":"rotate_ring","direction":"right"})
			app._objective_input({"action_id":"armillary_release","intent_id":session.engine.state.intents[0].intent_id})
		else:
			var skill: String="observe" if beat=="charge" else "self_guard"
			app._chapter_command("char_liang_xiao",skill,"char_ming_sanqiu" if skill=="observe" else "char_liang_xiao",session.engine.state.revision)
		check(app.saves.writes==writes_before,"battle editing retains memory snapshot without disk replay")
		app._chapter_resolve()
		check(app.saves.writes==writes_before+1,"battle round settlement creates strict checkpoint")
		if round_index==0:
			var saved_battle: Dictionary=app.encounter_session.snapshot()
			app.saves.fail_auto=true;app._show_menu()
			check(app.mode=="chapter_battle","failed checkpoint retains battle commands")
			app.saves.fail_auto=false
			var save_key := InputEventKey.new()
			save_key.physical_keycode=KEY_F5;save_key.pressed=true
			app._input(save_key)
			check(app.notice.text.contains("已保存"),"B01 F5 saves live compiled commands")
			app._show_menu();app._load("manual")
			check(app.mode=="chapter_battle","battle menu/manual reload resumes battle")
			check(EncounterSession.equivalent(saved_battle,app.encounter_session.snapshot()),"partial battle through actual main save/load")
		await process_frame
