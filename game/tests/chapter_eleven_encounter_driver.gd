extends RefCounted
const Core=preload("res://scripts/combat/chapter_eleven_engine.gd")
static func commands(s:RefCounted)->Array:
 var v:Dictionary=s.get_view();var h:Dictionary=s.engine.actor_by_id(Core.HERO);var x:Dictionary=s.engine.actor_by_id(Core.X)
 var target:Dictionary={}
 for id in [Core.CHANG,"guard_east","guard_west",Core.HE]:
  var a:Dictionary=s.engine.actor_by_id(id)
  if s.engine.alive(a):target=a;break
 if target.is_empty():return []
 if s.set_command(Core.HERO,"CO_02",target.id)=="":return []
 var hs:String="normal_attack";var xs:String="normal_attack";var xt:String=target.id
 var poison_pending:=false
 for i in v.intents:
  if i.actor_id==target.id and i.kind in ["poison","poison_charge"] and not i.cancelled:poison_pending=true
 if target.get("shell",false):
  hs="guard_ally";xs="HXS_A07"
 elif poison_pending and s.engine._status_value(target,"diagnosed")>0 and s.engine.validate_command(Core.HERO,"LX_A04",target.id)=="":hs="LX_A04"
 elif s.engine.validate_command(Core.HERO,"LX_A03",target.id)=="":hs="LX_A03"
 if not target.get("shell",false):
  if float(h.hp)/h.max_hp<.7 or float(x.hp)/x.max_hp<.7:
   xt=Core.HERO if float(h.hp)/h.max_hp<float(x.hp)/x.max_hp else Core.X;xs="HXS_A02"
   if h.max_hp-h.hp>180 and x.max_hp-x.hp>150 and s.engine.validate_command(Core.X,"HXS_A03",Core.X)=="":xs="HXS_A03";xt=Core.X
  elif s.engine._status_value(target,"diagnosed")==0:xs="HXS_A01"
  if poison_pending and s.engine._status_value(target,"diagnosed")==0 and h.hp>200 and "HXS_A01" in x.skills:xs="HXS_A01";xt=target.id
 # R04 can replace any one medical slot; choose only actually equipped actions.
 if "HXS_A04" in x.skills and poison_pending and "HXS_A01" not in x.skills and h.hp>350 and s.engine.validate_command(Core.X,"HXS_A04",target.id)=="":xs="HXS_A04";xt=target.id
 if s.engine.validate_command(Core.X,xs,xt)!="":
  if (h.max_hp-h.hp>150 or x.max_hp-x.hp>150) and s.engine.validate_command(Core.X,"HXS_A03",Core.X)=="":xs="HXS_A03";xt=Core.X
  elif (h.max_hp-h.hp>150 or x.max_hp-x.hp>150) and s.engine.validate_command(Core.X,"HXS_A02",Core.HERO)=="":xs="HXS_A02";xt=Core.HERO if float(h.hp)/h.max_hp<float(x.hp)/x.max_hp else Core.X
  elif s.engine.validate_command(Core.X,"HXS_A04",target.id)=="":xs="HXS_A04";xt=target.id
  else:xs="self_guard";xt=Core.X
 # Respond to the actual telegraphed victim: a healer's turn is not a substitute
 # for Liang's guard/counter. This avoids wasting MP on damage into a lethal hit.
 for intent in v.intents:
  if intent.kind!="pounce" or intent.cancelled:continue
  if intent.target_id==Core.X:hs="guard_ally"
  elif intent.target_id==Core.HERO:hs="sancai_counter" if s.engine.validate_command(Core.HERO,"sancai_counter",intent.actor_id)=="" else "self_guard"
 var ht:String=Core.X if hs=="guard_ally" else (Core.HERO if hs=="self_guard" else target.id)
 if s.engine.validate_command(Core.HERO,hs,ht)!="":hs="normal_attack";ht=target.id
 return [[Core.HERO,hs,ht],[Core.X,xs,xt]]
static func run(s:RefCounted,verbose:bool=false)->bool:
 for n in range(120):
  var v:Dictionary=s.get_view()
  if v.outcome!="":return v.outcome=="victory"
  for cmd in commands(s):
   if s.set_command(cmd[0],cmd[1],cmd[2])!="":return false
  if verbose:print("B07 ",v.round," ",s.engine.state.commands," hp ",s.engine.actor_by_id(Core.HERO).hp,"/",s.engine.actor_by_id(Core.X).hp," mp ",s.engine.actor_by_id(Core.HERO).mp,"/",s.engine.actor_by_id(Core.X).mp)
  if not s.resolve_round():return false
 return false
