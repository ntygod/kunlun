extends RefCounted
const BattleDriver=preload("res://tests/chapter_ten_encounter_driver.gd")
## Drives actual commands only. Timed world commands model duration; this is not GUI evidence.
static func advance(c:RefCounted,branch:int=0) -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[branch].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions.get(e.id,{})
   if geometry.is_empty():return false
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO CH10 SESSION ",e.id," ",rt.puzzle_context());return false
   for i in range(4096):
    if c.current_token()!=token:return true
    var action:Dictionary=session.next_demo_action()
    if action.is_empty():print("EMPTY CH10 INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("CH10 INPUT REJECT ",action," ",result);return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:print("NO CH10 BATTLE ",token);return false
   if not BattleDriver.run(session,branch==0):return false
   return rt.accept_objective(token,session.receipt())
 return false
