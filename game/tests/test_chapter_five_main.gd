extends "res://tests/test_chapter_five.gd"
var app
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app)
 await process_frame
 app.saves=SaveStore.new("user://chapter_five_main_test")
 var c:=Campaign.new(base)
 var fixture:="res://../output/cache/chapter_four_gui_v2/manual_natural_final.json"
 if FileAccess.file_exists(fixture):check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","natural GUI source load")
 else:
  check(false,"required natural source absent");quit(2);return

 app.story=c;app._enter_registered_chapter(5)
 var guard:=0
 while not c.state.finished and guard<150:
  guard+=1
  var token:String=c.current_token();var e:Dictionary=c.current_event()
  print("main5 ",token)
  match e.op:
   "dialogue","stage","branch_feedback":
    check(app.mode=="chapter_dialogue","actual dialogue "+token)
    while c.current_token()==token:
     if app.line_index==app.lines.size()-1:
      var press:=InputEventKey.new();press.keycode=KEY_E;press.physical_keycode=KEY_E;press.pressed=true
      Input.parse_input_event(press);await process_frame
      press.pressed=false;Input.parse_input_event(press);await process_frame
     else:app._next_line()
    if c.current_event().get("op")=="world_puzzle":check(c.current_chapter_runtime().make_puzzle().input_log.is_empty(),"closing dialogue E does not consume new controlled input")
   "choice":app._commit_chapter_choice(token,c.available_choices()[0].id)
   "action":
    if e.id=="safe_cabin_rest":
     app._switch_leader(Party.LIU)
     check(c.state.leader_id==Party.LIU,"actual core leader switch")
     app._save();app._load("manual")
     check(c.state.leader_id==Party.LIU,"leader chronology restores")
     app._switch_leader(Party.HERO)
    if e.id=="chapter_five_exit":
     app._switch_leader("char_axue")
     app._save();app._load("manual")
     check(c.state.leader_id=="char_axue","limited ally can lead after real recruitment")
    if e.has("requires_leader") and c.state.leader_id!=e.requires_leader:app._switch_leader(e.requires_leader)
    var geo:Dictionary=app.world.get_objective_geometry(e.id)
    check(not geo.is_empty(),"main geometry "+e.id)
    if geo.is_empty():break
    if e.kind=="route":
     for point in geo.waypoints:app.world.player.position=point;app.world._update_paths()
    else:app.world.player.position=geo.position
    if e.id=="ride_route":app.world.player.position=geo.position+Vector2(-6.25,6.42)
    app._interact()
    if e.id=="ride_route":
     check(Proof.equivalent(c.world_objects.ch04_spatial_state.horse_position,[geo.position.x,geo.position.y]),"mounted horse uses verified endpoint grid")
     check(Proof.equivalent(c.world_objects.ch04_spatial_state.player_position,[geo.position.x,geo.position.y]),"fractional free walk cannot offset controlled grid")
   "puzzle","world_puzzle":
    if e.op=="puzzle":
     var geo:Dictionary=app.world.get_objective_geometry(e.get("entry_id",e.id))
     check(not geo.is_empty(),"main puzzle entry "+e.id)
     if geo.is_empty():break
     app.world.player.position=geo.position;app._interact()
    else:
     check(app.mode=="world_puzzle" and not app.world.player.enabled,"controlled step opens without free-walk precondition")
     var start:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
     var rewards:Dictionary=c.reward_ledger.duplicate(true)
     var actors:Dictionary=c.actors.duplicate(true)
     app._advance_chapter()
     check(Proof.equivalent(start,c.current_chapter_runtime().make_puzzle().snapshot()),"repeated activation keeps exact controlled state")
     app._show_menu();app._cancel_choice()
     check(Proof.equivalent(start,c.current_chapter_runtime().make_puzzle().snapshot()),"menu reopening keeps exact controlled state")
     app._save();app._load("manual")
     check(Proof.equivalent(start,c.current_chapter_runtime().make_puzzle().snapshot()),"manual restore keeps exact controlled state")
     check(Proof.equivalent(rewards,c.reward_ledger) and Proof.equivalent(actors,c.actors),"activation/menu/load cannot mint rewards or refill resources")
    check(app.mode==("world_puzzle" if e.op=="world_puzzle" else "chapter_puzzle"),"actual panel "+e.id)
    var rt:=c.current_chapter_runtime();var session:=rt.make_puzzle()
    var partial_checked:=false
    for i in range(500):
     if c.current_token()!=token:break
     if e.op=="world_puzzle":
      var live:=c.current_chapter_runtime().make_puzzle()
      var action:Dictionary=FiveWorld.next_input(live.get_view())
      if action.type=="interact":
       var before:int=live.input_log.size()
       var press:=InputEventKey.new();press.keycode=KEY_E;press.physical_keycode=KEY_E;press.pressed=true
       Input.parse_input_event(press);await process_frame
       press.pressed=false;Input.parse_input_event(press);await process_frame
       check(live.input_log.size()==before+1,"E consumed exactly once")
      else:app._world_puzzle_input(action)
      if not partial_checked and c.current_token()==token:
       var partial:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
       app._show_menu();app._cancel_choice();app._save();app._load("manual")
       check(Proof.equivalent(partial,c.current_chapter_runtime().make_puzzle().snapshot()),"partial inputs survive menu and manual restore")
       partial_checked=true
      if c.current_token()!=token and app.world.scene_data.id==c.scene().id and not c.state.position==[-1.0,-1.0]:
       var final_view:Dictionary=live.get_view()
       check(Proof.equivalent(c.state.position,final_view.world_state.player_position),"verified terminal position survives handoff/save")
     else:app._registered_puzzle_input(session.next_demo_action())
   "objective_battle":
    check(app.mode=="chapter_battle","dual battle actual panel")
    if e.id=="enc_ch05_leigong_escape":
     check(app.world.scene_data.map_id=="map_ch05_fire_corridor","B03 phase1 fire background")
     var before:Dictionary=app.encounter_session.snapshot()
     app._save();app._load("manual")
     check(Proof.equivalent(before,app.encounter_session.snapshot()),"phase1 background reload preserves battle")
     check(app.world.scene_data.map_id=="map_ch05_fire_corridor","phase1 background restored")
    var driver:=FiveDriver.new()
    if e.id=="enc_ch05_mechanism_yun_shu":driver.b02(app.encounter_session)
    else:driver.b03(app.encounter_session)
    check(driver.errors.is_empty(),"dual battle model inputs")
    if e.id=="enc_ch05_leigong_escape":
     var before:Dictionary=app.encounter_session.snapshot()
     var position:Vector2=app.world.player.position
     app._show_chapter_battle()
     check(app.world.scene_data.map_id=="map_ch05_eight_gates","B03 phase2 outside gates background")
     check(Proof.equivalent(before,app.encounter_session.snapshot()) and app.world.player.position==position,"background never mutates encounter or position")
     app._persist_objective_checkpoint();app._save();app._load("manual")
     check(app.world.scene_data.map_id=="map_ch05_eight_gates","phase2 background restored")
    app._chapter_battle_finish()
    if e.id=="enc_ch05_leigong_escape":check(app.world.scene_data.map_id==c.scene().map_id,"battle exit restores canonical background")
   "quest_window":app._chapter_completed(c.current_chapter_runtime().close_window(token))
  if c.current_token()==token and not c.state.finished:check(false,"main advance "+token);break
 check(c.state.finished,"actual main terminal")
 check(app.mode=="ending","registered ending")
 app._show_journal();check(app.mode=="journal","dual journal")
 app.queue_free();await process_frame;await process_frame
 print("Chapter five main: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
