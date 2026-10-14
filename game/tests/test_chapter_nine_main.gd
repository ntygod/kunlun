extends SceneTree
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const R=preload("res://scripts/puzzles/chapter_nine_puzzle_resolver.gd")
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func settle()->void:
	await process_frame;await process_frame;await process_frame
func key(main:Node,code:int)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;main._input(event)
func run()->void:
	for dimensions in [Vector2i(640,360),Vector2i(1280,720)]:
		root.size=dimensions
		var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await settle();main._layout()
		main.saves.directory="user://ch09_main_test_"+str(OS.get_process_id())+"_"+str(dimensions.x)
		check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","real frozen chapter8 entry")
		check(main.story.enter_registered_chapter(9),"admit chapter9")
		var visited:Array=[]
		for i in range(100):
			var event:Dictionary=main.story.current_event()
			if event.get("id")=="evt_ch09_wood_bird_assembled":
				main._load_chapter_scene();await settle()
				var presentation=load("res://scripts/chapter_nine_world_presentation.gd")
				var prepared_view:Dictionary=presentation.spatial(main.world)
				check(prepared_view.get("wood_bird",{}).get("stage")=="prepared","dialogue draws prepared bird")
				var expected:Array=prepared_view.actor_positions.char_axue
				check(main.world.cast_actors.char_axue.position==Vector2(expected[0],expected[1]),"dialogue retains snow workstation")
				var snapshot:Dictionary={"checkpoint":main.story.state.wood_bird_checkpoint.duplicate(true),"rewards":main.story.reward_ledger.duplicate(true),"actors":main.story.actors.duplicate(true),"events":main.story.prepare_persisted_save().payload.current.events.duplicate(true)}
				main._show_menu();key(main,KEY_F5);await settle();key(main,KEY_F9);await settle()
				check(presentation.spatial(main.world).get("wood_bird",{}).get("stage")=="prepared","F9 prepared bird restored")
				check(main.world.cast_actors.char_axue.position==Vector2(expected[0],expected[1]),"F9 snow same workstation")
				main._show_menu();main._cancel_choice();await settle()
				check(main.story.current_event().id=="evt_ch09_wood_bird_assembled","menu/cancel/F5/F9 does not advance")
				check(load("res://scripts/campaign/encounter_session.gd").equivalent({"checkpoint":main.story.state.wood_bird_checkpoint,"rewards":main.story.reward_ledger,"actors":main.story.actors,"events":main.story.prepare_persisted_save().payload.current.events},snapshot),"render and menu do not mutate proof or award")
				main.modal.hide()
			if event.get("op")=="puzzle":
				main._load_chapter_scene();main._show_registered_puzzle();await settle()
				var session:RefCounted=main.story.current_chapter_runtime().make_puzzle()
				var panel:Control=main.registered_puzzle_panel
				var scroll:ScrollContainer=main.modal_content.get_parent();var area:Rect2=scroll.get_global_rect()
				check(main.mode=="chapter_puzzle","real main modal route")
				check(area.encloses(panel.get_global_rect()),"panel fits "+str(dimensions)+" "+event.id+" body "+str(panel.get_global_rect())+" area "+str(area))
				for control in [panel._board,panel._buttons.close,panel._buttons.hint,panel._labels.rules,panel._labels.formula]:check(area.encloses(control.get_global_rect()),"critical board/rules/footer fit "+event.id)
				check(panel._labels.details.text==session.instruction(),"complete formal rules available")
				check(panel.input_submitted.get_connections().size()==1,"one authoritative input connection")
				check(panel.close_requested.is_connected(main._return_from_puzzle),"close routed")
				if event.id=="evt_ch09_wood_bird_resume":
					for step in range(3):panel.input_submitted.emit(session.next_demo_action())
					check(session.state.stage=="rail_moving" and session.state.rail_index==1,"actual main flight partial rail")
					var spatial:Dictionary=session.get_view().world_state
					check(load("res://scripts/chapter_nine_world_presentation.gd").spatial(main.world).wood_bird.stage=="rail_moving","current flight overrides prepared fallback")
					check(main.world.player.position==Vector2(spatial.player_position[0],spatial.player_position[1]),"main hero physically follows bird")
				var old_hint:int=session.state.hint
				panel._buttons.hint.pressed.emit();check(session.state.hint==mini(3,old_hint+1),"real UI command accepted")
				# F5 uses the actual input route and resulting bytes are independently loaded.
				key(main,KEY_F5);await settle()
				var path:String=main.saves.directory.path_join("manual.json")
				check(FileAccess.file_exists(path),"F5 wrote actual file: "+main.notice.text)
				if not FileAccess.file_exists(path):quit(1);return
				var raw:String=FileAccess.get_file_as_string(path);var saved:Variant=JSON.parse_string(raw)
				check(saved is Dictionary and raw.sha256_text().length()==64,"actual save bytes parsed and hashed")
				var copy:=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
				check(copy.restore_persisted(saved)=="","independent campaign restores F5 content")
				check(copy.current_token()==main.story.current_token(),"saved actual token matches")
				var saved_state:Dictionary=copy.current_chapter_runtime().make_puzzle().state.duplicate(true)
				check(saved_state==session.state,"saved actual puzzle state matches")
				# F5 may adopt a replayed campaign object; refresh references from authority.
				session=main.story.current_chapter_runtime().make_puzzle()
				main._show_registered_puzzle();await settle();panel=main.registered_puzzle_panel
				for j in range(2):panel._buttons.hint.pressed.emit()
				panel._buttons.demo.pressed.emit();check(panel._demo_running,"live demo starts")
				key(main,KEY_F9)
				check(not panel._demo_running,"F9 stops old timer immediately")
				panel._tick();await settle()
				check(main.story.current_chapter_runtime().make_puzzle().state==saved_state,"F9 restores exact phase without old callback")
				main._show_registered_puzzle();await settle();panel=main.registered_puzzle_panel
				for j in range(2):panel._buttons.hint.pressed.emit()
				panel._buttons.demo.pressed.emit();check(panel._demo_running,"demo starts before menu")
				var before:Dictionary=main.story.current_chapter_runtime().make_puzzle().snapshot()
				main._show_menu();check(not panel._demo_running,"menu stops demo")
				panel.input_submitted.emit({"type":"wait"});panel._tick()
				check(main.story.current_chapter_runtime().make_puzzle().snapshot()==before,"old hidden panel signal blocked")
				await settle();main.modal.hide();visited.append(event.id)
			if visited.size()==3:break
			if not Flow.advance(main.story,false):check(false,"flow blocked "+str(event));break
		check(visited==["pz_ch09_pine_needle","pz_ch09_wood_bird_begin","evt_ch09_wood_bird_resume"],"all three actual nodes routed "+str(dimensions))
		for step in range(30):
			if main.story.current_chapter_runtime().scene().map_id!="map_ch09_tiandu_peak":break
			check(Flow.advance(main.story,false),"leave peak after flight")
		main._load_chapter_scene();await settle()
		check(not main.story.current_chapter_runtime().world_context().has("wood_bird_presentation"),"next map has no prepared fallback")
		check(not load("res://scripts/chapter_nine_world_presentation.gd").spatial(main.world).has("wood_bird"),"next map has no lingering bird")
		main.queue_free();await settle()
	print("Chapter nine actual main: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
