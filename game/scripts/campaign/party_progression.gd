class_name PartyProgression
extends RefCounted
## Shared core transactions. Limited allies are deliberately excluded. Call only after the chapter validates its event.
## Battle passives are NOT baked into these permanent panels.
const Growth=preload("res://scripts/campaign/progression.gd")
const HERO:="char_liang_xiao"
const LIU:="char_liu_yingying"
const CH04_GEAR:={HERO:{"max_hp":60,"max_mp":10,"atk":16,"def":10,"spd":2},LIU:{"max_hp":50,"max_mp":10,"atk":15,"def":8,"spd":4}}
static func recruit_liu(actors: Dictionary) -> bool:
 if actors.has(LIU) or not actors.has(HERO):return false
 var xp:int=actors[HERO].xp
 var actor:=Growth.actor_panel(LIU,xp,{"max_hp":10,"max_mp":0,"atk":3,"def":1,"spd":1})
 actor.merge({"name":"柳莺莺","age":16,"status":"active","kind":"core","hp":actor.max_hp,"mp":actor.max_mp,"skills":["LYY_A01","LYY_A02","LYY_N01","LYY_P01"],"skill_ranks":{"LYY_A01":1,"LYY_A02":1,"LYY_N01":1,"LYY_P01":1},"passives":["LYY_P01"],"internal_skill":"LYY_N01","joined_at_xp":xp,"earned_rewards":{},"equipment_stage":"initial"})
 actors[LIU]=actor
 return true
static func refit(actors: Dictionary, actor_id: String) -> bool:
 if not CH04_GEAR.has(actor_id) or not actors.has(actor_id):return false
 var actor:Dictionary=actors[actor_id]
 if actor.get("equipment_stage","")=="chapter_four":return false
 var hp:int=actor.hp;var mp:int=actor.mp
 actor.merge(Growth.actor_panel(actor_id,int(actor.xp),CH04_GEAR[actor_id]),true)
 actor.hp=mini(hp,int(actor.max_hp));actor.mp=mini(mp,int(actor.max_mp))
 actor.equipment_stage="chapter_four"
 return true
static func award(actors: Dictionary, ledger: Dictionary, id: String, amount: int) -> bool:
 if id.is_empty() or amount<0 or ledger.has(id) or not actors.has(HERO):return false
 # All recruited cores remain XP recipients while asleep or temporarily absent. Leadership and
 # presentation status never recruit or mint a second campaign reward.
 for actor_id in [HERO,LIU]:
  if not actors.has(actor_id):continue
  var actor:Dictionary=actors[actor_id]
  var hp:int=actor.hp;var mp:int=actor.mp;var old_max:int=actor.max_hp
  actor.merge(Growth.actor_panel(actor_id,int(actor.xp)+amount,actor.equipment),true)
  actor.hp=mini(int(actor.max_hp),hp+int(actor.max_hp)-old_max)
  actor.mp=mini(mp,int(actor.max_mp))
  if not actor.has("earned_rewards"):actor.earned_rewards={}
  actor.earned_rewards[id]=amount
 ledger[id]=amount
 return true
static func accept_resources(actors: Dictionary, final_actors: Array, expected_ids: Array) -> bool:
 # Validate the complete result before mutating either actor. The session must
 # already be replayed; this additionally rejects duplicates/missing participants.
 var updates:Dictionary={}
 if final_actors.size()!=expected_ids.size():return false
 for value in final_actors:
  if not value is Dictionary or not value.get("id") is String:return false
  var id:String=value.id
  if id not in expected_ids or updates.has(id) or not actors.has(id):return false
  for field in ["hp","mp"]:
   var n:Variant=value.get(field)
   if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floor(float(n)) or int(n)<0 or int(n)>int(actors[id]["max_"+field]):return false
  updates[id]={"hp":int(value.hp),"mp":int(value.mp)}
 for id in updates:
  actors[id].hp=updates[id].hp;actors[id].mp=updates[id].mp
 return true
