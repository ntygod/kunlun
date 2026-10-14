extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eight_campaign_driver.gd")
const WorldDriver=preload("res://tests/chapter_eight_world_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const H="char_liang_xiao"
var failures:=0
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var mode:String=OS.get_environment("CH08_STATE_MODE")
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 if mode=="read":
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://ch08_state_cases.json"))
  for key in data:
   var sample:Dictionary=data[key]
   var err:String=c.restore_persisted(sample.payload);check(err=="","independent "+key+" "+err)
   if err!="":continue
   check(Same.equivalent(c.actors,sample.actors),"actors "+key)
   check(Same.equivalent(c.state.campaign_battle_snapshot,sample.campaign),"one battle context "+key)
   check(Same.equivalent(c.world_objects,sample.world),"world "+key)
   var rt:RefCounted=c.current_chapter_runtime()
   if c.current_event().op=="objective_battle":
    var session:RefCounted=rt.make_objective_encounter()
    check(session!=null,"battle restored "+key)
    if session==null:continue
    check(Flow.battle(session),"battle remainder "+key)
    check(rt.complete(c.current_token(),session.receipt()),"accept remainder "+key)
   for i in range(100):
    if c.state.finished:break
    if not Flow.advance(c,true,0,"body"):check(false,"resume "+key+" "+c.current_token());break
   check(c.state.finished and c.state.xp==17665 and c.state.coins==2450,"remainder exact ledger "+key)
  print("CH08 STATE READ ",data.size()," checkpoints, ",failures," failures");quit(1 if failures else 0);return
 var err:String=c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json")))
 check(err=="","source");check(c.enter_registered_chapter(8),"entry")
 var samples:Dictionary={}
 for i in range(100):
  var rt:RefCounted=c.current_chapter_runtime();var id:String=c.current_event().get("id","")
  if id=="enc_ch08_ballista_objective":
   var session:RefCounted=rt.make_objective_encounter()
   check(session.apply_input({"actor_id":H,"action_id":"inspect_hub","value":"left_gear"}).accepted,"inspect")
   check(session.resolve_round(),"round");check(rt.save_objective_checkpoint(session),"checkpoint")
   capture(c,samples,"phase_one_mid")
   check(Flow.battle(session),"phase1 remainder");check(rt.complete(c.current_token(),session.receipt()),"phase1 accept")
   capture(c,samples,"intermission_entry");continue
  if id=="rescue_ch08_l04":
   var session:RefCounted=rt.make_puzzle()
   for k in range(34):
    if c.current_event().get("id")!=id:break
    var result:Dictionary=rt.puzzle_input(c.current_token(),WorldDriver.next_input(session,"body"))
    check(result.ok,"partial rescue")
   capture(c,samples,"l04_partial")
   check(rt.pause_sidequest(),"pause actual rescue");capture(c,samples,"l04_paused")
   check(rt.open_sidequest("L04"),"resume rescue")
  if id=="ch08_fire_confirmed":capture(c,samples,"fire_unconfirmed")
  if id=="enc_ch08_civilian_escort":
   var initial:Dictionary=rt.state.campaign_battle_snapshot.duplicate(true)
   for k in range(3):rt.make_objective_encounter()
   check(Same.equivalent(initial,rt.state.campaign_battle_snapshot),"make never refreshes phase2 checkpoint")
   var session:RefCounted=rt.make_objective_encounter()
   check(session.apply_input({"actor_id":H,"action_id":"lead_batch"}).accepted,"lead")
   check(session.resolve_round(),"lead round")
   check(session.apply_input({"actor_id":H,"action_id":"escort_intercept"}).accepted,"intercept")
   check(session.resolve_round(),"intercept round")
   check(session.set_command(H,"sancai_counter","routed_pressure")=="","sancai")
   check(session.resolve_round(),"sancai round")
   check(rt.save_objective_checkpoint(session),"phase2 save")
   capture(c,samples,"phase_two_batch_one")
   var before:Dictionary=c.export_save();var forged:Dictionary=before.duplicate(true)
   forged.current.navigation.objective_snapshot.state.actors[0].mp+=1
   check(c.restore_persisted(forged)!="","reject forged MP snapshot")
   check(Same.equivalent(before,c.export_save()),"forgery does not mutate live")
   break
  if not Flow.advance(c,true,0,"body"):check(false,"flow "+c.current_token());break
 var f:=FileAccess.open("user://ch08_state_cases.json",FileAccess.WRITE);f.store_string(JSON.stringify(samples));f.close()
 print("CH08 STATE WRITE ",samples.size()," checkpoints, ",failures," failures");quit(1 if failures else 0)
func capture(c:RefCounted,samples:Dictionary,key:String) -> void:
 print("CAPTURE ",key)
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","capture "+key+" "+str(saved.error))
 if saved.error!="":return
 samples[key]={"payload":saved.payload,"actors":c.actors.duplicate(true),"campaign":c.state.campaign_battle_snapshot.duplicate(true),"world":c.world_objects.duplicate(true)}
