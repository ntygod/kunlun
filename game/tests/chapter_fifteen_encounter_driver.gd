extends RefCounted
const Core=preload("res://scripts/combat/chapter_fifteen_engine.gd")
static func commands(s:RefCounted)->Array:
 var v:Dictionary=s.get_view();var x:String=Core.X;var hs:String=Core.HS;var he:String=Core.HE
 if v.objective.curve_phase==v.objective.phase and s.engine.validate_command(x,"CO_04",he)=="":return [[x,"CO_04",he]]
 var local:int=v.round-int(v.objective.phase_start)
 if local%3==0:return [[x,"HXS_A01",he],[hs,"HS_A01",x]]
 if local%3==1 and s.engine.validate_command(x,"HXS_A07",he)=="" and s.engine.validate_command(hs,"HS_A06",he)=="":return [[x,"HXS_A07",he],[hs,"HS_A06",he]]
 var heal:String=x if s.engine.actor_by_id(x).hp<s.engine.actor_by_id(hs).hp else hs
 return [[x,"HXS_A02",heal],[hs,"HS_A01",x]] if s.engine.validate_command(x,"HXS_A02",heal)=="" else [[x,"self_guard",x],[hs,"HS_A01",x]]
static func run(s:RefCounted)->bool:
 for i in range(100):
  if s.get_view().outcome!="":return s.get_view().outcome=="victory"
  for c in commands(s):
   if s.set_command(c[0],c[1],c[2])!="":return false
  if not s.resolve_round():return false
 return false
