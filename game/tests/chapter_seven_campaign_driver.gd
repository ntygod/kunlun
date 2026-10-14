extends RefCounted
const WorldDriver=preload("res://tests/chapter_seven_world_driver.gd")
static func advance(c:RefCounted,do_side:bool=true,branch:int=0) -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[branch].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO SESSION ",e.id);return false
   for i in range(6000):
    if c.current_token()!=token:return true
    var action:Dictionary=WorldDriver.next_input(session.get_view()) if e.op=="world_puzzle" else session.next_demo_action()
    if action.is_empty():print("EMPTY INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("INPUT REJECT ",action," ",result);return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:return false
   var driver:RefCounted=load("res://tests/chapter_seven_battle_driver.gd").new()
   driver.run(session)
   return rt.complete(token,session.receipt())
  "quest_window":
   if do_side and rt.state.optional.L03.status!="archived":return rt.open_sidequest("L03")
   return rt.close_window(token)
 return false
