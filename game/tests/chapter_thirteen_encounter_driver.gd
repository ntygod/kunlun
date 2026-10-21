extends RefCounted
const HERO="char_liang_xiao"
static func commands(s:RefCounted)->Array:
 var v:Dictionary=s.get_view();var target:String="npc_yun_shu" if v.objective.phase==1 else "npc_hetuoluo"
 var fire:=false
 for i in v.intents:
  if i.kind=="fire" and not i.cancelled:fire=true;target=i.actor_id
 for skill in (["LX_A05","LX_A03","sancai_counter","self_guard"] if fire else ["sancai_counter","self_guard","normal_attack"]):
  var t:String=HERO if skill=="self_guard" else target
  if s.engine.validate_command(HERO,skill,t)=="":return [[HERO,skill,t]]
 return []
static func run(s:RefCounted)->bool:
 for i in range(40):
  if s.get_view().outcome!="":return s.get_view().outcome=="victory"
  var cmds:=commands(s)
  if cmds.is_empty():return false
  for c in cmds:
   if s.set_command(c[0],c[1],c[2])!="":return false
  if not s.resolve_round():return false
 return false
