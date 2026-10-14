extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const BattleDriver=preload("res://tests/chapter_six_battle_driver.gd")
const WorldDriver=preload("res://tests/chapter_six_world_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func advance(c:RefCounted) -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[0].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   var proof:Dictionary={"map_id":c.scene().map_id,"position":geometry.position}
   if e.kind=="route":
    var total:int=rt.maps[c.scene().map_id].paths[e.id].size();proof.merge({"complete":true,"index":total,"total":total})
   return c.complete_action(token,e.id,proof)
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO SESSION ",e.id," ",rt.puzzle_context());return false
   for i in range(1000):
    if c.current_token()!=token:return true
    var action:Dictionary=WorldDriver.next_input(session.get_view()) if e.op=="world_puzzle" else session.next_demo_action()
    if action.is_empty():print("EMPTY INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("INPUT REJECT ",action," ",result);return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:return false
   var driver=BattleDriver.new()
   driver.run(session)
   return rt.complete(token,session.receipt())
  "quest_window":
   for side in ["R03","L02"]:
    if rt.state.optional[side].status!="archived":return rt.open_sidequest(side)
   return rt.close_window(token)
 return false
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json")))=="","natural chapter5")
 var prior_actors:Dictionary=c.actors.duplicate(true);var prior_items:Dictionary=c.items.duplicate(true)
 check(c.enter_registered_chapter(6),"registered chapter6 entry")
 check(Proof.equivalent(prior_actors,c.actors) and Proof.equivalent(prior_items,c.items),"entry doesn't mutate actual prior resources/objects")
 for i in range(200):
  if c.state.finished:break
  print("CH6 ",c.current_token()," ",c.current_event().id)
  var before:Dictionary=c.export_save()
  check(not c.current_chapter_runtime().complete(c.current_token(),{"success":true}),"fake success rejected")
  check(Proof.equivalent(before,c.export_save()),"fake proof atomic")
  var live_event:Dictionary=c.current_event()
  if live_event.op in ["action","objective_battle"]:
   for bad_value in [true,false,null,1,[],{}]:
    var bad_proof:Dictionary={"map_id":bad_value,"position":[80,240]} if live_event.op=="action" else {"attempt_id":bad_value}
    check(not c.current_chapter_runtime().complete(c.current_token(),bad_proof),"bad external enum rejected without comparison crash")
    if live_event.op=="objective_battle":check(not c.current_chapter_runtime().accept_objective(c.current_token(),bad_proof),"inherited objective entry guarded")
    check(Proof.equivalent(before,c.export_save()),"bad external enum leaves same state")

  if not advance(c):check(false,"actual advance "+c.current_token());break
  var other=Campaign.new(base);var err:String=other.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
  check(err=="","event replay "+c.current_token()+" "+err)
  if not err.is_empty():break
 check(c.state.finished,"chapter6 full completion")
 if c.state.finished:
  check(c.state.xp==11575,"2525 plus700 source budget")
  check(c.state.coins==0 and c.items.item_ch06_entrusted_coins.quantity==1400,"actual950 plus450 entirely entrusted")
  var candidate:Dictionary=c.prepare_persisted_save()
  check(candidate.get("error","")=="","compact chapter6 "+str(candidate.get("error","")))
 print("Chapter six integration: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
