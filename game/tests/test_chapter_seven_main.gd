extends "res://tests/test_chapter_seven.gd"
const SaveStore=preload("res://scripts/save_store.gd")
var app
const WorldDriver=preload("res://tests/chapter_seven_world_driver.gd")
const BattleDriver=preload("res://tests/chapter_seven_battle_driver.gd")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 app.saves=SaveStore.new("user://chapter_seven_main_test")
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_six_gui/manual_natural_final.json")))=="","real source")
 app.story=c;app._enter_registered_chapter(7)
 for i in range(200):
  if c.state.finished:break
  var e:Dictionary=c.current_event();var token:String=c.current_token()
  print("MAIN7 ",token)
  match e.op:
   "dialogue","stage","branch_feedback":
    check(app.mode=="chapter_dialogue","actual dialogue")
    while c.current_token()==token:app._next_line()
   "choice":app._commit_chapter_choice(token,c.available_choices()[0].id)
   "action":
    var geo:Dictionary=app.world.get_objective_geometry(e.id)
    check(not geo.is_empty(),"real world geometry")
    if geo.is_empty():break
    app.world.player.position=geo.position;app._interact()
   "puzzle","world_puzzle":
    if e.op=="puzzle":
     var geo:Dictionary=app.world.get_objective_geometry(e.id);app.world.player.position=geo.position;app._interact()
    check(app.mode==("world_puzzle" if e.op=="world_puzzle" else "chapter_puzzle"),"actual puzzle panel")
    var partial:=false
    for n in range(6000):
     if c.current_token()!=token:break
     var session:RefCounted=c.current_chapter_runtime().make_puzzle()
     var action:Dictionary=WorldDriver.next_input(session.get_view()) if e.op=="world_puzzle" else session.next_demo_action()
     if e.op=="world_puzzle":app._world_puzzle_input(action)
     else:app._registered_puzzle_input(action)
     if not partial and c.current_token()==token:
      var before:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
      app._save();app._load("manual")
      check(Proof.equivalent(before,c.current_chapter_runtime().make_puzzle().snapshot()),"partial F5/F9 exact")
      partial=true
   "objective_battle":
    check(app.mode=="chapter_battle","actual battle panel")
    var driver=BattleDriver.new(check);driver.run(app.encounter_session)
    check(driver.errors.is_empty(),"actual public battle inputs")
    c.current_chapter_runtime().save_objective_checkpoint(app.encounter_session)
    var before:Dictionary=app.encounter_session.snapshot();app._save();app._load("manual")
    check(Proof.equivalent(before,app.encounter_session.snapshot()),"victory pending disk snapshot")
    app._chapter_battle_finish()
   "quest_window":
    if c.state.optional.L03.status!="archived":app._open_optional("L03")
    else:app._chapter_completed(c.current_chapter_runtime().close_window(token))
  await process_frame
  if c.current_token()==token:check(false,"main stalled "+token);break
 check(c.state.finished,"main reaches archive")
 app.queue_free();await process_frame;await process_frame
 print("Chapter seven main: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
