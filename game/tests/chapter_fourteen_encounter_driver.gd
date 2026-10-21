extends RefCounted
const Core=preload("res://scripts/combat/chapter_fourteen_engine.gd")
static func commands(s:RefCounted)->Array:
 var v:Dictionary=s.get_view();var h:String=Core.HERO;var hs:String=Core.HS
 var target:String=""
 for a in v.actors:
  if a.team=="enemy" and not a.defeated and a.id!=Core.ARRAY:target=a.id;break
 if v.objective.phase==2:
  if v.objective.wheels_collapsed:target=Core.ARRAY
  else:
   for id in Core.WHEELS:
    if id not in v.objective.nodes:target=id;break
  if v.objective.nodes.size()>=2 and not v.objective.wheels_collapsed and s.engine.validate_command(h,"CO_05",target)=="":return [[h,"CO_05",target]]
 var commands:Array=[]
 for who in [h,hs]:
  var choices:Array=["LX_A05","LX_A03","LX_A04","normal_attack"] if who==h else ["HS_A05","HS_A02","HS_A03","normal_attack"]
  if v.objective.phase==2 and not v.objective.wheels_collapsed and who==h:choices=["LX_A04","self_guard"]
  if s.engine._status_value(s.engine.actor_by_id(h),"root")>0 and who==hs:choices=["HS_A04","HS_A05","normal_attack"]
  for skill in choices:
   var t:String=who if skill=="self_guard" else (h if skill=="HS_A04" else target)
   if s.engine.validate_command(who,skill,t)=="":commands.append([who,skill,t]);break
  if commands.size()==0 or commands[-1][0]!=who:
   if s.engine.validate_command(who,"self_guard",who)=="":commands.append([who,"self_guard",who])
 return commands
static func run(s:RefCounted)->bool:
 for i in range(100):
  if s.get_view().outcome!="":return s.get_view().outcome=="victory"
  for c in commands(s):
   if s.set_command(c[0],c[1],c[2])!="":return false
  if not s.resolve_round():return false
 return false
