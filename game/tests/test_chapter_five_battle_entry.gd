extends "res://tests/test_chapter_four.gd"
## Integration evidence: actual campaign/progression/runtime, not hand-edited panels.
const FiveSession=preload("res://scripts/combat/chapter_five_encounter.gd")
const FiveDriver=preload("res://tests/chapter_five_battle_driver.gd")
const FiveWorld=preload("res://tests/chapter_five_world_driver.gd")
func advance_five(c:CampaignState) -> bool:
 var rt=c.current_chapter_runtime();var event=c.current_event();var token=c.current_token()
 match event.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[0].id)
  "action":return c.complete_action(token,event.id,{"map_id":c.scene().map_id,"position":rt.maps[c.scene().map_id].actions[event.id].position})
  "world_puzzle","puzzle":
   var session=rt.make_puzzle()
   if session==null:return false
   for index in range(1000):
    if c.current_token()!=token:return true
    var input:Dictionary=FiveWorld.next_input(session.get_view()) if event.op=="world_puzzle" else session.next_demo_action()
    if input.is_empty():return false
    var result:Dictionary=rt.puzzle_input(token,input)
    if not result.get("ok",result.get("accepted",false)):print(result);return false
   return false
 return false
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var natural:=OS.get_environment("CH05_ENTRY")=="natural"
 var c:CampaignState
 if natural:
  c=Campaign.new(base)
  var fixture:="res://../output/cache/chapter_four_gui_v2/manual_natural_final.json"
  if not FileAccess.file_exists(fixture):print("BLOCKED natural fixture absent");quit(2);return
  check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","actual chapter4 natural fixture")
 else:
  c=chapter_two_ending(false)
  check(c.enter_chapter_three(),"generated minimum chapter3 entry")
  while not c.state.finished:
   if not act_three(c,16):check(false,"generated chapter3 progression");quit(1);return
  check(c.enter_registered_chapter(4),"generated minimum chapter4 entry")
  while not c.state.finished:
   if c.current_event().op=="objective_battle":
    var old=c.current_chapter_runtime().make_objective_encounter();var driver=BattleDriver.new(check)
    driver.low_route(old)
    if old.receipt().is_empty() or not c.current_chapter_runtime().complete(c.current_token(),old.receipt()):check(false,"chapter4 minimum battle");quit(1);return
   elif not intro(c):check(false,"generated chapter4 progression "+c.current_token());quit(1);return
  check(c.state.xp==4465,"no side minimum chapter4 XP")
 print("CH05 actual entry ","natural" if natural else "minimum"," XP",c.state.xp," HP",c.actors[Party.HERO].hp,"/",c.actors[Party.LIU].hp)
 check(c.enter_registered_chapter(5),"actual chapter5 entry")
 var battles:=0
 for index in range(200):
  if c.current_event().op=="objective_battle":
   var rt=c.current_chapter_runtime();var s=rt.make_objective_encounter()
   if s==null:check(false,"actual battle session creation");quit(1);return
   var p:Array=rt.combat_party()
   print("ACTUAL PARTY ",JSON.stringify(p))
   if p.size()!=2:check(false,"runtime party must contain exactly Liang and Liu");quit(1);return
   var driver=FiveDriver.new(check)
   if battles==0:driver.b02(s)
   else:driver.b03(s)
   check(s.engine.state.outcome=="victory","actual battle victory "+s.encounter.id)
   print("ACTUAL RESULT ",s.encounter.id," rounds",s.engine.state.round-1," HP",s.engine.actor_by_id(Party.HERO).hp,"/",s.engine.actor_by_id(Party.LIU).hp," startHP",p[0].hp,"/",p[1].hp," maxHP",p[0].max_hp,"/",p[1].max_hp," permanentMaxHP",c.actors[Party.HERO].max_hp)
   check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"actual whole battle JSON replay")
   # Pressure boundary only: derive real runtime stats, then subtract explicit
   # hypothetical entry damage. These are not claimed campaign-history paths.
   var threshold:int=int(p[0].hp)-int(s.engine.actor_by_id(Party.HERO).hp)+1
   for start_hp in [threshold,threshold-1]:
    var pressure_party:Array=p.duplicate(true);pressure_party[0].hp=start_hp
    var pressure=FiveSession.new(c.rules,c.combat,s.encounter,pressure_party,"pressure-only")
    var pressure_driver=FiveDriver.new()
    if battles==0:pressure_driver.b02(pressure)
    else:pressure_driver.b03(pressure)
    check((pressure.engine.state.outcome=="victory")== (start_hp==threshold),"derived-panel injury pressure exact boundary")
    check(pressure.restore(JSON.parse_string(JSON.stringify(pressure.snapshot()))),"pressure replay exact injury")
   print("PRESSURE ONLY route threshold H",threshold," with L",p[1].hp,"; lower1 defeats, no stat/MP changes")
   if s.receipt().is_empty():quit(1);return
   check(rt.complete(c.current_token(),s.receipt()),"actual battle receipt committed")
   battles+=1
   if battles==2:break
  elif not advance_five(c):check(false,"chapter5 advances "+c.current_token());quit(1);return
 check(battles==2,"both actual runtime encounters completed")
 print("CH05 battle entry ",checks," checks ",failures," failures")
 quit(1 if failures else 0)
