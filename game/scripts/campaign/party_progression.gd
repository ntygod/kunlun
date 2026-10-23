class_name PartyProgression
extends RefCounted
## Shared core transactions. Limited allies are deliberately excluded. Call only after the chapter validates its event.
## Battle passives are NOT baked into these permanent panels.
const Growth=preload("res://scripts/campaign/progression.gd")
const HERO:="char_liang_xiao"
const LIU:="char_liu_yingying"
const XIAOSHUANG:="char_hua_xiaoshuang"
const HUASHENG:="char_huasheng"
const CORE_IDS:=[HERO,LIU,XIAOSHUANG,HUASHENG]
const CH11_GEAR:={HERO:{"max_hp":230,"max_mp":25,"atk":50,"def":32,"spd":5},XIAOSHUANG:{"max_hp":190,"max_mp":35,"atk":38,"def":28,"spd":4},HUASHENG:{"max_hp":320,"max_mp":20,"atk":48,"def":45,"spd":2}}
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
 for actor_id in CORE_IDS:
  if not actors.has(actor_id) or actors[actor_id].get("status")=="dead":continue
  if actor_id in [XIAOSHUANG,HUASHENG] and actors[actor_id].get("kind")!="core":continue
  var actor:Dictionary=actors[actor_id]
  var hp:int=actor.hp;var mp:int=actor.mp;var old_max:int=actor.max_hp
  actor.merge(newcore_panel(actor_id,int(actor.xp)+amount,actor.equipment,actor.internal_skill) if actor_id in [XIAOSHUANG,HUASHENG] or (actor_id==HERO and actor.get("internal_skill")=="LX_N02") or (actor_id==LIU and actor.get("internal_skill") in ["LYY_N02","LYY_N03"]) else Growth.actor_panel(actor_id,int(actor.xp)+amount,actor.equipment),true)
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

## Derived permanent panels only for the newly migrated cores. Old chapter panels stay unchanged.
static func newcore_panel(actor_id:String,xp:int,equipment:Dictionary,internal:String) -> Dictionary:
 var panel:Dictionary=Growth.actor_panel(actor_id,xp,equipment)
 if actor_id==XIAOSHUANG:
  if internal=="HXS_N01":panel.max_mp=int(floor(float(panel.max_mp)*1.20))
  elif internal=="HXS_N02":
   panel.max_hp=int(floor(float(panel.max_hp)*1.20));panel.def=int(floor(float(panel.def)*1.15))
  elif internal=="HXS_N03":
   panel.max_mp=int(floor(float(panel.max_mp)*1.35));panel.spd+=8
 elif actor_id==HUASHENG and internal=="HS_N01":
  panel.max_hp=int(floor(float(panel.max_hp)*1.25));panel.def=int(floor(float(panel.def)*1.20))
 elif actor_id==HUASHENG and internal=="HS_N02":
  panel.max_hp=int(floor(float(panel.max_hp)*1.30));panel.atk=int(floor(float(panel.atk)*1.18));panel.spd+=6
 if actor_id==HERO and internal=="LX_N02":
  panel.max_hp=int(floor(float(panel.max_hp)*1.18));panel.max_mp=int(floor(float(panel.max_mp)*1.25));panel.def=int(floor(float(panel.def)*1.12))
 elif actor_id==LIU and internal=="LYY_N02":
  panel.atk=int(floor(float(panel.atk)*1.15));panel.max_mp=int(floor(float(panel.max_mp)*1.20))
 elif actor_id==LIU and internal=="LYY_N03":
  for key in ["max_hp","max_mp","atk","def","spd"]:panel[key]=int(floor(float(panel[key])*1.12))
  panel.spd+=15
 panel.panel_internal_skill=internal
 return panel
static func refit_ch11(actors:Dictionary,id:String) -> bool:
 if not CH11_GEAR.has(id) or not actors.has(id) or (id!=HERO and actors[id].get("kind")!="core") or actors[id].get("equipment_stage")=="chapter_eleven":return false
 var actor:Dictionary=actors[id];var hp:int=actor.hp;var mp:int=actor.mp
 actor.merge(newcore_panel(id,int(actor.xp),CH11_GEAR[id],actor.internal_skill) if id in [XIAOSHUANG,HUASHENG] else Growth.actor_panel(id,int(actor.xp),CH11_GEAR[id]),true)
 actor.hp=mini(hp,int(actor.max_hp));actor.mp=mini(mp,int(actor.max_mp));actor.equipment_stage="chapter_eleven"
 return true
static func migrate_ch11_core(actors:Dictionary,id:String) -> bool:
 if id not in [XIAOSHUANG,HUASHENG] or not actors.has(HERO) or actors.get(id,{}).get("kind")=="core" or actors.get(id,{}).get("status")=="dead":return false
 var actor:Dictionary=actors.get(id,{}).duplicate(true)
 var inherited:Dictionary=actor.duplicate(true)
 var old_hp:Variant=actor.get("hp");var old_mp:Variant=actor.get("mp")
 for value in [old_hp,old_mp]:
  if value!=null and (not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floor(float(value)) or value<0):return false
 var internal:String="HXS_N01" if id==XIAOSHUANG else "HS_N01"
 var gear:Dictionary=actor.get("equipment",CH11_GEAR[id] if id==HUASHENG else {"max_hp":25,"max_mp":10,"atk":6,"def":5,"spd":1}).duplicate(true)
 actor.merge(newcore_panel(id,int(actors[HERO].xp),gear,internal),true)
 actor.id=id;actor.name="花晓霜" if id==XIAOSHUANG else "花生";actor.kind="core";actor.status="active"
 actor.hp=actor.max_hp if old_hp==null else mini(int(old_hp),int(actor.max_hp));actor.mp=actor.max_mp if old_mp==null else mini(int(old_mp),int(actor.max_mp))
 actor.initial_numeric_panel={"chapter":11,"hp_initialized":old_hp==null,"mp_initialized":old_mp==null,"equipment_initialized":not inherited.has("equipment"),"equipment_source":"preserved_existing" if inherited.has("equipment") else ("chapter_eleven_standard" if id==HUASHENG else "initial_medical_baseline")}
 actor.internal_skill=internal;actor.learned_internals=[internal];actor.joined_at_xp=int(actors[HERO].xp);actor.earned_rewards={}
 actor.skills=["HXS_A01","HXS_A02","HXS_A03","HXS_N01","HXS_P01"] if id==XIAOSHUANG else ["HS_A01","HS_A02","HS_N01","HS_P01","HS_P02"]
 actor.skill_ranks={"HXS_A01":3,"HXS_A02":3,"HXS_A03":1,"HXS_N01":1,"HXS_P01":1} if id==XIAOSHUANG else {"HS_A01":1,"HS_A02":1,"HS_N01":1,"HS_P01":1,"HS_P02":1}
 actor.learned_passives=["HXS_P01"] if id==XIAOSHUANG else ["HS_P01","HS_P02"]
 actor.equipped_passives=actor.learned_passives.duplicate();actor.passives=actor.equipped_passives.duplicate();actor.nonlethal=true
 actor.equipped_active_skills=["HXS_A01","HXS_A02","HXS_A03"] if id==XIAOSHUANG else ["HS_A01","HS_A02"]
 for skill in inherited.get("skills",[]):
  if skill not in actor.skills:actor.skills.append(skill)
 for skill in inherited.get("skill_ranks",{}):actor.skill_ranks[skill]=maxi(int(actor.skill_ranks.get(skill,0)),int(inherited.skill_ranks[skill]))
 actor.earned_rewards=inherited.get("earned_rewards",{}).duplicate(true)
 actor.equipment_stage=inherited.get("equipment_stage","chapter_two" if id==XIAOSHUANG else "chapter_eleven")
 actors[id]=actor
 return true
static func equip_xiaoshuang_n02(actors:Dictionary) -> bool:
 if not actors.has(XIAOSHUANG) or actors[XIAOSHUANG].get("kind")!="core" or actors[XIAOSHUANG].get("internal_skill")=="HXS_N02":return false
 var actor:Dictionary=actors[XIAOSHUANG];var hp:int=actor.hp;var mp:int=actor.mp
 if "HXS_N02" not in actor.skills:actor.skills.append("HXS_N02")
 if "HXS_N02" not in actor.learned_internals:actor.learned_internals.append("HXS_N02")
 actor.skill_ranks.HXS_N02=1;actor.internal_skill="HXS_N02"
 actor.merge(newcore_panel(XIAOSHUANG,int(actor.xp),actor.equipment,"HXS_N02"),true)
 actor.hp=mini(hp,int(actor.max_hp));actor.mp=mini(mp,int(actor.max_mp))
 return true

## Authored core upgrades only; preserve prior injuries and never grant a free refill.
static func equip_core_internal(actors:Dictionary,id:String,internal:String) -> bool:
 if not ((id==HERO and internal=="LX_N02") or (id==LIU and internal=="LYY_N02") or (id==HUASHENG and internal=="HS_N02") or (id==XIAOSHUANG and internal=="HXS_N03")) or not actors.has(id):return false
 var actor:Dictionary=actors[id]
 if actor.get("status")=="dead" or actor.get("internal_skill")==internal:return false
 var hp:int=actor.hp;var mp:int=actor.mp
 if internal not in actor.skills:actor.skills.append(internal)
 if not actor.has("learned_internals"):actor.learned_internals=[actor.get("internal_skill","")]
 if internal not in actor.learned_internals:actor.learned_internals.append(internal)
 actor.skill_ranks[internal]=1;actor.internal_skill=internal
 actor.merge(newcore_panel(id,int(actor.xp),actor.equipment,internal),true)
 actor.hp=mini(hp,int(actor.max_hp));actor.mp=mini(mp,int(actor.max_mp))
 return true
