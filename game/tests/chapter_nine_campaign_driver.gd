extends RefCounted
const WorldDriver=preload("res://tests/chapter_nine_world_driver.gd")
const BattleDriver=preload("res://tests/chapter_nine_encounter_driver.gd")
static func advance(c:RefCounted,do_side:bool=true,branch:int=0,method:String="A",late_side:bool=false) -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[branch].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO SESSION ",e.id," ",rt.puzzle_context());return false
   for i in range(4096):
    if c.current_token()!=token:return true
    var action:Dictionary=WorldDriver.next_input(session,method) if e.op=="world_puzzle" else session.next_demo_action()
    if action.is_empty():print("EMPTY INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("INPUT REJECT ",action," ",result);return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:print("NO BATTLE ",token);return false
   if not BattleDriver.run(session):return false
   return rt.complete(token,session.receipt())
  "quest_window":
   if do_side and rt.state.optional.L05.status!="archived" and (not late_side or e.get("deadline",false)):
    if not rt.navigation_valid(rt.state.position,c.scene().map_id):rt.state.position=rt.maps[c.scene().map_id].spawn.duplicate()
    return rt.open_sidequest("L05")
   return rt.close_window(token)
 return false
