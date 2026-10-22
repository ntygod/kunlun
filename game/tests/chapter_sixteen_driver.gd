extends RefCounted
## Test-only legal-command driver. Not reachable from the game and not natural-GUI evidence.
static func puzzle_action(session:RefCounted)->Dictionary:
 var s:Dictionary=session.get_view().state
 match session.puzzle_id:
  "pz_ch16_river":
   if not s.surveyed:return {"type":"survey"}
   for i in range(3):
    if s.gates[i]!=[4,4,1][i]:return {"type":"gate","channel":i,"value":[4,4,1][i]}
   if not s.overflow:return {"type":"dig","site":"old_channel"}
   return {"type":"test"}
  "pz_ch16_scale":
   if not s.objects.is_empty():return {"type":"clear"}
   if not s.understood:return {"type":"talk"}
   if s.left=="":return {"type":"stand","actor":"char_liang_xiao","side":"left"}
   return {"type":"stand","actor":"npc_ranya","side":"right"}
  "pz_ch16_study":
   if not s.page_read:return {"type":"read"}
   if s.instrument!=[2,3,2,1][int(s.season_index)%4]:return {"type":"align","value":[2,3,2,1][int(s.season_index)%4]}
   return {"type":"record"}
 return {}
static func command(session:RefCounted)->Dictionary:
 var v:Dictionary=session.get_view();var h:Dictionary=session.engine.actor_by_id("char_liang_xiao")
 var enemy:String=""
 for a in v.actors:
  if a.team=="enemy" and not a.defeated and a.hp>0:
   enemy=a.id
   if a.id=="npc_ch16_raiders":break
 if enemy=="":return {}
 var order:Array=["LX_A06","LX_A05","LX_A03","LX_A04","sancai_counter","normal_attack"]
 if int(v.round)%2==0:order=["LX_A05","LX_A03","LX_A04","observe","normal_attack"]
 for id in order:
  var target:String=h.id if id in ["LX_A06","self_guard"] else enemy
  if session.engine.validate_command(h.id,id,target)=="":return {"actor":h.id,"skill":id,"target":target}
 return {}
static func advance(c:RefCounted,branch:int=0)->bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var token:String=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":
   var options:Array=c.available_choices()
   return c.choose(token,options[mini(branch,options.size()-1)].id)
  "action":
   var geometry:Dictionary=rt.maps[c.scene().map_id].actions[e.id]
   return c.complete_action(token,e.id,{"map_id":c.scene().map_id,"position":geometry.position})
  "puzzle":
   var session:RefCounted=rt.make_puzzle()
   if session==null:return false
   for i in range(80):
    if c.current_token()!=token:return true
    if not rt.puzzle_input(token,puzzle_action(session)).get("ok",false):return false
   return false
  "objective_battle":
   var session:RefCounted=rt.make_objective_encounter()
   if session==null:return false
   for round_index in range(80):
    if session.engine.state.outcome!="":break
    var cmd:=command(session)
    if OS.get_environment("CH16_TRACE")=="1":print("ROUND ",session.engine.state.round," ",session.engine.actor_by_id("char_liang_xiao").hp,"/",session.engine.actor_by_id("char_liang_xiao").max_hp," ",cmd," ",session.engine.actor_by_id("npc_ch16_arutai").hp)
    if cmd.is_empty() or session.set_command(cmd.actor,cmd.skill,cmd.target)!="" or not session.resolve_round():return false
   if session.engine.state.outcome!="victory":
    print("MQ16 failed battle ",session.engine.state.round," ",session.engine.actor_by_id("char_liang_xiao").hp);return false
   return rt.accept_objective(token,session.receipt())
 return false
