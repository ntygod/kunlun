extends RefCounted
## Test-only policy using public commands. No HP setters, success flags or runtime mutation.
const H="char_liang_xiao"
const L="char_liu_yingying"
const F="char_feng_lian"
static func puzzle_action(p:RefCounted)->Dictionary:
 var s:Dictionary=p.state
 if p.puzzle_id=="pz_ch17_roof":
  var step:Dictionary=p.roof_steps()[int(s.stage)]
  return {"type":"place","actor":step.actor,"part":step.part}
 var wanted:Array=["howls","disguise"] if s.claim=="double" else ["wounds","callus","zhuque"]
 for clue in s.selected:
  if clue not in wanted:return {"type":"toggle","clue":clue}
 for clue in wanted:
  if clue not in s.selected:return {"type":"toggle","clue":clue}
 return {"type":"connect","claim":s.claim}
static func commands(session:RefCounted)->Array:
 var engine:RefCounted=session.engine;var view:Dictionary=session.get_view();var enemy:String=""
 for a in view.actors:
  if a.team=="enemy" and engine.alive(a):
   if enemy=="" or a.get("boss",false):enemy=a.id
 if enemy=="":return []
 var lowest:=H
 for a in view.actors:
  if a.team=="party" and engine.alive(a) and float(a.hp)/a.max_hp<float(engine.actor_by_id(lowest).hp)/engine.actor_by_id(lowest).max_hp:lowest=a.id
 var result:Array=[]
 for a in view.actors:
  if a.team!="party" or not engine.alive(a):continue
  var order:Array=[]
  if a.id==H:
   if view.encounter.id=="ch17_amo" and not view.objective.observed:order.append(["observe",enemy])
   if view.encounter.id=="ch17_amo" and view.objective.rescued:order.append(["LX_A03",enemy])
   if float(a.hp)/a.max_hp<.45:order.append(["LX_A06",H]);order.append(["sancai_counter",enemy])
   order.append_array([["LX_A05",enemy],["LX_A03",enemy],["LX_A04",enemy],["observe",enemy],["normal_attack",enemy]])
  elif a.id==L:
   if view.encounter.id=="ch17_wolf_double":
    if not view.objective.wind_hit:order.append(["LYY_A08",enemy])
    if not view.objective.hook_hit:order.append(["LYY_A03",enemy])
   if view.encounter.id=="ch17_amo" and not view.objective.rescued:order.append(["LYY_A01",enemy]);order.append(["LYY_A03",enemy])
   if float(engine.actor_by_id(lowest).hp)/engine.actor_by_id(lowest).max_hp<.65:order.append(["LYY_A05",lowest])
   order.append_array([["LYY_A08",enemy],["LYY_A03",enemy],["LYY_A01",enemy],["normal_attack",enemy]])
  else:
   if view.encounter.id=="ch17_amo" and not view.objective.sensed:order.append(["FL_S02",enemy])
   order.append_array([["FL_S01",enemy],["FL_S02",enemy],["normal_attack",enemy]])
  order.append(["self_guard",a.id])
  var chosen:Dictionary={}
  for row in order:
   if engine.validate_command(a.id,row[0],row[1])=="":chosen={"actor":a.id,"skill":row[0],"target":row[1]};break
  if chosen.is_empty():return []
  result.append(chosen)
 return result
static func advance(c:RefCounted,branch:int=0,roof:bool=true)->bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":
   var choices:Array=c.available_choices();return c.choose(token,choices[mini(branch,choices.size()-1)].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "quest_window":
   if roof and rt.state.optional.ch17_r07.status!="archived":return rt.open_sidequest("ch17_r07")
   return rt.close_window(token)
  "puzzle":
   var p:RefCounted=rt.make_puzzle()
   if p==null:return false
   for n in range(32):
    if c.current_token()!=token:return true
    if not rt.puzzle_input(token,puzzle_action(p)).get("ok",false):return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:return false
   for n in range(100):
    if session.engine.state.outcome!="":break
    var inputs:=commands(session)
    if OS.get_environment("CH17_TRACE")=="1":
     var vitals:Array=[]
     for a in session.engine.state.actors:vitals.append([a.id,a.hp,a.mp])
     print(e.id," ROUND ",session.engine.state.round," ",vitals," ",inputs)
    if inputs.is_empty():return false
    for cmd in inputs:
     if session.set_command(cmd.actor,cmd.skill,cmd.target)!="":return false
    if not session.resolve_round():return false
   if session.engine.state.outcome!="victory":print("BATTLE FAILED ",e.id," ",session.engine.state.round," ",session.engine.state.objective);return false
   return rt.accept_objective(token,session.receipt())
 return false
