extends RefCounted
const WorldDriver=preload("res://tests/chapter_eight_world_driver.gd")
const H="char_liang_xiao"
static func battle(session:RefCounted) -> bool:
 for i in range(150):
  var v:Dictionary=session.get_view()
  if v.outcome!="":return v.outcome=="victory"
  var phase:String=v.objective.phase
  var beat:int=session.engine.beat()
  var ok:bool=false
  if phase=="river_duel":
   if beat==1:ok=session.apply_input({"actor_id":H,"action_id":"borrow_cover"}).accepted
   else:ok=session.set_command(H,"self_guard",H)==""
  elif phase=="phase_one":
   var hub:String=""
   for id in ["left_gear","center_pin","right_string"]:
    if v.objective.hubs[id]>0:hub=id;break
   ok=session.apply_input({"actor_id":H,"action_id":"release_calibrated_shot" if v.objective.calibrated==hub else "inspect_hub","value":hub}).accepted
  elif phase=="phase_two":
   if beat==1:ok=session.apply_input({"actor_id":H,"action_id":"lead_batch"}).accepted
   elif beat==2:ok=session.apply_input({"actor_id":H,"action_id":"escort_intercept"}).accepted
   else:ok=session.set_command(H,"sancai_counter","routed_pressure")==""
  if not ok or not session.resolve_round():print("BATTLE BLOCK ",v);return false
 return false
static func advance(c:RefCounted,do_side:bool=true,branch:int=0,method:String="body") -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[branch].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   if e.id=="ch08_passive_loadout" and do_side:
    if not rt.set_passive_loadout(["LX_P01","LX_P03"]):return false
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO SESSION ",e.id," ",rt.puzzle_context());return false
   for i in range(3000):
    if c.current_token()!=token:return true
    var action:Dictionary=WorldDriver.next_input(session,method) if e.op=="world_puzzle" else session.next_demo_action()
    if action.is_empty():print("EMPTY INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("INPUT REJECT ",action," ",result);return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:print("NO BATTLE ",token);return false
   if not battle(session):return false
   return rt.complete(token,session.receipt())
  "quest_window":
   if do_side and rt.state.optional.L04.status!="archived":
    if not rt.navigation_valid(rt.state.position,c.scene().map_id):rt.state.position=rt.maps[c.scene().map_id].spawn.duplicate()
    return rt.open_sidequest("L04")
   return rt.close_window(token)
 return false
