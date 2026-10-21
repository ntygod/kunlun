extends RefCounted
const BATTLE_DRIVER="res://tests/chapter_thirteen_encounter_driver.gd"
## Drives actual commands only. Timed world commands model duration; this is not GUI evidence.
static func advance(c:RefCounted,branch:int=0,do_side:bool=true) -> bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":
   var options:Array=c.available_choices()
   if e.get("choice_key","")=="departure_loadout":
    for option in options:
     if option.id=="ch13_departure_loadout_recommended":return c.choose(token,option.id)
   return c.choose(token,options[mini(branch,options.size()-1)].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions.get(e.id,{})
   if geometry.is_empty():return false
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle","world_puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:print("NO CH13 SESSION ",e.id," ",rt.puzzle_context());return false
   for i in range(4096):
    if c.current_token()!=token:return true
    var action:Dictionary=session.next_demo_action()
    if action.is_empty():print("EMPTY CH13 INPUT ",session.get_view());return false
    var result:Dictionary=rt.puzzle_input(token,action)
    if not result.get("ok",result.get("accepted",false)):print("CH13 INPUT REJECT ",action," ",result);return false
   return false
  "quest_window":
   return rt.close_window(token)
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:
    var cfg:Dictionary=load(rt.ENGINE_SCRIPT).encounter_config(e.id);cfg.context=rt.puzzle_context()
    var debug:RefCounted=load(rt.ENGINE_SCRIPT).new(c.rules,c.combat);debug.start(cfg,rt.combat_party())
    print("NO CH13 BATTLE ",token," ",debug.entry_error," ",JSON.stringify(rt.combat_party()));return false
   if not ResourceLoader.exists(BATTLE_DRIVER):print("CH13 BATTLE DRIVER NOT YET AVAILABLE");return false
   if not load(BATTLE_DRIVER).run(session):return false
   return rt.accept_objective(token,session.receipt())
 return false
