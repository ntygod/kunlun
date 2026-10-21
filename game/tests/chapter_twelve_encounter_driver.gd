extends RefCounted
const Core=preload("res://scripts/combat/chapter_twelve_engine.gd")
static func legal(s:Variant,a:String,skill:String,t:String)->bool:return s.engine.validate_command(a,skill,t)==""
static func choose(s:Variant,a:String,candidates:Array)->Array:
 for c in candidates:
  if legal(s,a,c[0],c[1]):return [a,c[0],c[1]]
 return [a,"self_guard",a]
static func commands(s:Variant)->Array:
 var e:Variant=s.engine;var o:Dictionary=e.state.objective;var kind:String=e.state.encounter.kind
 var round:int=e.state.round;var cycle:int=(round-1)%3
 if kind=="han":
  var x:Dictionary=e.actor_by_id(Core.X);var t:="han_ningzi"
  var candidates:Array=[]
  if x.hp<x.max_hp*.65:candidates.append(["HXS_A02",Core.X])
  if cycle==1:candidates.append(["HXS_A06",t])
  if e._status_value(e.actor_by_id(t),"diagnosed")==0:candidates.append(["HXS_A01",t])
  candidates.append_array([["normal_attack",t]])
  return [choose(s,Core.X,candidates)]
 if kind=="lei":
  var skill:String=["HS_A01","HS_A02","HS_A03"][cycle]
  if (cycle==1 and o.disarm_seen) or (cycle==2 and o.push_seen):skill="HS_A01"
  return [choose(s,Core.HS,[[skill,Core.HS if skill=="HS_A01" else "lei_xingkong"]])]
 if kind=="chu":
  var candidates:Array=[]
  if o.poems.size()<3:candidates.append([Core.POEMS[o.poems.size()],"chu_xianliu"])
  candidates.append_array([["sancai_counter","chu_xianliu"],["LX_A03","chu_xianliu"]])
  return [choose(s,Core.HERO,candidates)]
 var result:Array=[];var h:Dictionary=e.actor_by_id(Core.HERO);var x:Dictionary=e.actor_by_id(Core.X);var liu:Dictionary=e.actor_by_id(Core.LIU)
 var target:=""
 for id in ["luo_mingqi","puppet_east","puppet_west","chiyou_cauldron"]:
  if e.alive(e.actor_by_id(id)) and legal(s,Core.HERO,"normal_attack",id):target=id;break
 var combo:bool=target!="" and cycle==1 and legal(s,Core.HERO,"CO_02",target) and e.alive(h)
 if combo:result.append([Core.HERO,"CO_02",target])
 else:
  if e.alive(h):
   var candidates:Array=[]
   var threatened:=false
   for intent in e.state.intents:
    if intent.kind=="strike" and intent.target_id==Core.X and not intent.cancelled:threatened=true
   if threatened and x.hp<x.max_hp*.75:candidates.append(["guard_ally",Core.X])
   if target!="":candidates.append_array([["LX_A04",target],["LX_A03",target],["normal_attack",target]])
   result.append(choose(s,Core.HERO,candidates))
  var candidates:Array=[]
  if int(o.unlock_round)>0 and round>=o.unlock_round and o.herbs.size()<3:candidates.append([Core.HERBS[o.herbs.size()],"chiyou_cauldron"])
  for a in [h,liu]:
   if not e.alive(a):candidates.append(["HXS_A05",a.id])
  if e.alive(h) and cycle==0 and e.alive(e.actor_by_id("luo_mingqi")):candidates.append(["HXS_A02",Core.HERO]);candidates.append(["HXS_A05",Core.HERO])
  var low:Dictionary=x
  for a in [h,liu]:
   if e.alive(a) and float(a.hp)/a.max_hp<float(low.hp)/low.max_hp:low=a
  if low.hp<low.max_hp*.65:candidates.append(["HXS_A02",low.id]);candidates.append(["HXS_A03",Core.X])
  if target!="" and e._status_value(e.actor_by_id(target),"diagnosed")==0:candidates.append(["HXS_A01",target])
  if target!="":candidates.append(["HXS_A04",target])
  result.append(choose(s,Core.X,candidates))
 if e.alive(liu):
  var candidates:Array=[]
  for intent in e.state.intents:
   if "disarm" in intent.tags:candidates.append(["LYY_A03",intent.actor_id])
  if target!="":candidates.append_array([["LYY_A04",target],["LYY_A02",target],["normal_attack",target]])
  result.append(choose(s,Core.LIU,candidates))
 return result
static func run(s:Variant,limit:int=160)->bool:
 if s.engine.entry_error!="":print("CH12_ENTRY_ERROR ",s.engine.entry_error);return false
 for i in range(limit):
  if s.engine.state.outcome!="":return s.engine.state.outcome=="victory"
  for c in commands(s):
   var error:String=s.set_command(c[0],c[1],c[2])
   if error!="":print("CH12_COMMAND_ERROR ",error," ",c);return false
  if not s.resolve_round():return false
 return false
