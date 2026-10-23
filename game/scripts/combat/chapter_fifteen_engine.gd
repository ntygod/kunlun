class_name ChapterFifteenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
const Same=preload("res://scripts/campaign/encounter_session.gd")
const X="char_hua_xiaoshuang"
const HS="char_huasheng"
const HE="npc_hetuoluo"
const ID="enc_ch15_medical_disarm"
const ALLOWED=["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A03","HXS_A04","HXS_A05","HXS_A06","HXS_A07","HS_A01","HS_A02","HS_A03","HS_A04","HS_A05","HS_A06"]
const BAD=["poison","cold","bleed","root","sealed","bound","disarmed","speed_down","attack_down","defense_down"]
var entry_error=""
static func encounter_config(id:String=ID)->Dictionary:
 if id!=ID:return {}
 return {"id":ID,"kind":"b12","name":"医理破贺陀罗","level":68,"xp":0,"battle_id":"B12","result":"ch15_he_disabled","nonlethal":true,"enemies":[{"id":HE,"name":"贺陀罗","team":"enemy","max_hp":5500,"max_mp":260,"atk":310,"def":240,"spd":50,"boss":true,"protection_rounds":1,"tags":["armor"],"rotation":[{"name":"黑煞碎心爪","hits":[2.2],"tags":["guard"],"target_id":X}]}]}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 for row in [["HXS_A01","望诊切脉",16,"enemy"],["HXS_A02","捻针推宫",8,"friend"],["HXS_A03","杏林悬壶",0,"self"],["HXS_A04","神仙倒·迷香",10,"enemy"],["HXS_A05","金针渡穴·生生不息",18,"friend"],["HXS_A06","暗香疏影拳",4,"enemy"],["HXS_A07","龙须取气·截脉断劲",12,"enemy"],["HS_A01","金刚护持",0,"friend"],["HS_A02","金刚破器掌",-2,"enemy"],["HS_A03","巨力推山撼",-5,"enemy"],["HS_A04","罗汉解脱身",15,"friend"],["HS_A05","伏魔大金刚震",-6,"enemy"],["HS_A06","曲直弹指劲",12,"enemy"]]:
  content.skills[row[0]]={"name":row[1],"source_id":row[0],"kind":"skill","speed":row[2],"target":row[3]}
 content.skills.HS_A01.merge({"prepare":true,"kind":"guard"},true)
 content.skills.HS_A04.merge({"prepare":true,"kind":"release"},true)
 content.skills.CO_04={"name":"菩提点穴·低眉破煞劲","kind":"combo","target":"enemy","speed":12}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config()
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 if not config.get("context") is Dictionary or not _whole(config.context.get("chapter"),15,15) or not config.context.get("current_token") is String or config.context.current_token.is_empty():entry_error="invalid_context"
 var ids:Array=[]
 for a in party:
  if not a is Dictionary:entry_error="invalid_actor";continue
  if a.get("id") not in [X,HS] or a.get("id") in ids or a.get("team")!="party" or a.get("status","") in ["dead","captured","departed_chaoyun"]:entry_error="invalid_actor"
  ids.append(a.get("id"))
  for k in ["hp","mp","max_hp","max_mp","atk","def","spd","fixed_level"]:
   if not _whole(a.get(k),1 if k in ["hp","max_hp","fixed_level"] else 0):entry_error="invalid_actor_number"
  if not a.get("skills") is Array or not a.get("skill_ranks") is Dictionary or not a.get("passives") is Array or not a.get("learned_passives") is Array:entry_error="invalid_metadata"
  if entry_error!="":continue
  if a.hp>a.max_hp or a.mp>a.max_mp or a.fixed_level>80:entry_error="invalid_resources"
  var seen:Array=[];var active:Array=[]
  for skill in a.skills:
   if not skill is String or skill not in ALLOWED or skill in seen:entry_error="invalid_skill"
   seen.append(skill)
   if skill in ["normal_attack","self_guard","guard_ally"]:continue
   active.append(skill)
   if not skill.begins_with("HXS_" if a.id==X else "HS_") or not a.skill_ranks.has(skill):entry_error="unlearned_skill"
  if active.size()>4:entry_error="active_slot_limit"
  if a.has("equipped_active_skills") and not Same.equivalent(active,a.equipped_active_skills):entry_error="loadout_mismatch"
  for rank in a.skill_ranks.values():
   if not _whole(rank,1,3):entry_error="invalid_rank"
  seen=[]
  for passive in a.passives:
   if passive not in (["HXS_P01","HXS_P02","HXS_P03"] if a.id==X else ["HS_P01","HS_P02","HS_P03"]) or passive not in a.learned_passives or passive in seen:entry_error="invalid_passive"
   seen.append(passive)
  if seen.size()>2:entry_error="passive_slot_limit"
  if a.get("internal_skill","") not in (["HXS_N02"] if a.id==X else ["HS_N01","HS_N02"]):entry_error="invalid_internal"
  if a.get("internal_stats_applied")!=true or a.get("panel_internal_skill")!=a.get("internal_skill"):entry_error="invalid_internal_panel"
  if a.id==HS and not a.skill_ranks.has("HS_A06"):entry_error="hs06_not_granted"
 if ids.size()!=2:entry_error="healer_and_huasheng_required"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 super.start(config,party);checkpoint=snapshot()
func _o()->Dictionary:return state.objective
func _rank(a:Dictionary,id:String)->int:return int(a.get("skill_ranks",{}).get(id,1))
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective={"phase":1,"phase_start":1,"seals":0,"sealed_phases":[],"combo_trial":false,"synergy":0,"reserved":0,"synergy_round":0,"failure":"","postheal":false,"diagnosed_phase":0,"curve_phase":0,"needle_round":0,"curve_round":0,"bell":true}
 super.begin_round();_o().synergy_round=0
 for who in [X,HS]:
  var a:=actor_by_id(who);a.passive_healed=0
  if a.get("shield_until",-1)<state.round:a.shield=0
  if _status_value(a,"regeneration")>0:_heal(a,a,a.max_hp*.02,true,"regeneration")
  if _status_value(a,"regeneration_mana")>0:gain_mana(a,2,"regeneration")
 if state.round>=3 and not _o().combo_trial:
  _o().combo_trial=true;_o().synergy=maxi(2,int(_o().synergy))
  for who in [X,HS]:actor_by_id(who).skills.append("CO_04")
  _event("combo_trial_granted",X,HS,2,{"skill_id":"CO_04"})
 var local:int=state.round-int(_o().phase_start)
 state.intents=[]
 var kind:String=["claw","charge","blast"][local%3]
 state.intents.append({"actor_id":HE,"intent_id":"b12:%d"%state.round,"kind":kind,"name":{"claw":"黑煞碎心爪 · 锁定晓霜，金刚护持＋望诊","charge":"大威德裂地轰·蓄势 · 龙须标穴、曲直收劲","blast":"大威德裂地轰 · 留意韧性保护，合招封功不免伤"}[kind],"target_id":X,"hits":[2.2] if kind=="claw" else ([] if kind=="charge" else [2.4]),"aoe":kind=="blast","tags":["guard","diagnose"] if kind=="claw" else ["needle","sever","interrupt"],"speed":0,"executed":false,"cancelled":false})
 if kind=="blast" and actor_by_id(HE).get("charge_broken_round",-2)==state.round-1:
  state.intents[0].hits=[.6];state.intents[0].aoe=false;state.intents[0].name="蓄势已散 · 低威胁掌（保护期合招不取消）"
func validate_command(id:String,skill:String,target:String)->String:
 var a:=actor_by_id(id);var t:=actor_by_id(target)
 if skill=="CO_04":
  if state.mode!="commands" or id not in [X,HS] or not _o().combo_trial or _o().synergy+_o().reserved<2:return "combo_unavailable"
  for who in [X,HS]:
   if not alive(actor_by_id(who)) or actor_by_id(who).get("revived_round",-1)==state.round or _status_value(actor_by_id(who),"root")>0:return "combo_unavailable"
  return "" if target==HE and alive(t) else "invalid_target"
 if a.is_empty() or a.get("revived_round",-1)==state.round:return "actor_unavailable"
 if skill in ["HS_A01","HS_A04","HXS_A02"] and t.get("team")!="party":return "invalid_target"
 if skill=="HXS_A05":
  if state.mode!="commands" or not alive(a) or skill not in a.skills:return "actor_unavailable"
  if t.get("team")!="party":return "invalid_target"
  if not alive(t) and t.get("revive_used",false):return "revive_used"
  if alive(t) and t.get("deathsave_used",false):return "deathsave_used"
  if state.round<int(a.ready.get(skill,1)):return "cooldown"
  return "" if a.mp>=skill_cost(a,content.skills[skill]) else "insufficient_mp"
 return super.validate_command(id,skill,target)
func set_command(a:Variant,s:Variant,t:Variant,revision:Variant=-1)->String:
 if not a is String or not s is String or not t is String or not revision is int or revision < -1:return "invalid_command_type"
 if revision!=-1 and revision!=state.revision:return "stale_revision"
 var error:=validate_command(a,s,t)
 if error!="":return error
 if _o().reserved>0:_refund()
 if s=="CO_04":
  _o().synergy-=2;_o().reserved=2
  for who in [X,HS]:state.commands[who]={"actor_id":who,"skill_id":s,"target_id":t}
 else:state.commands[a]={"actor_id":a,"skill_id":s,"target_id":t}
 state.revision+=1;return ""
func _refund()->void:
 if _o().reserved==0:return
 _o().synergy=mini(3,int(_o().synergy)+int(_o().reserved));_o().reserved=0;state.commands.clear();_event("combo_refund",X,HS,2)
func apply_input(a:Variant)->Dictionary:
 if not a is Dictionary or not a.has_all(["actor_id","action_id"]):return {"accepted":false,"error":"invalid_input"}
 for k in a:
  if k not in ["actor_id","action_id","revision"]:return {"accepted":false,"error":"unexpected_field"}
 if a.actor_id not in [X,HS] or not a.action_id is String:return {"accepted":false,"error":"invalid_actor"}
 if a.has("revision") and (not a.revision is int or a.revision!=state.revision):return {"accepted":false,"error":"invalid_revision"}
 if state.mode!="commands" or state.outcome!="":return {"accepted":false,"error":"not_accepting_input"}
 if a.action_id=="cancel":_refund();state.commands.clear();state.revision+=1
 elif a.action_id=="retreat":_refund();state.outcome="defeat";state.mode="finished";_o().failure="retreated";state.revision+=1
 else:return {"accepted":false,"error":"invalid_action"}
 return {"accepted":true}
func _synergy(reason:String)->void:
 if _o().synergy_round>=1:return
 _o().synergy_round+=1;_o().synergy=mini(3,int(_o().synergy)+1);_event("synergy",X,HS,1,{"reason":reason})
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 if not super._break(a,t,i):return false
 _synergy("effective_break");return true
func _try_break(a:Dictionary,t:Dictionary,tags:Array,soft:bool=false)->bool:
 for i in state.intents:
  if i.actor_id!=t.id or i.executed or i.cancelled:continue
  for tag in tags:
   if tag not in i.tags:continue
   if not _break(a,t,i):return false
   if i.kind=="charge":t.charge_broken_round=state.round
   if soft:i.hits=[.6];i.aoe=false;i.kind="soft";i.name="龙须透穴 · 低威胁掌"
   else:i.cancelled=true
   return true
 return false
func _after_preparation(a:Dictionary,skill:Dictionary)->void:
 if skill.get("source_id")=="HS_A01":
  if a.stance.target_id==a.id:a.stance.kind="self_guard"
  if a.get("internal_skill")=="HS_N02":a.next_speed=true
 if skill.get("source_id")=="HS_A04":
  for who in [a.id,a.stance.target_id]:
   var t:=actor_by_id(who);_cleanse(t,99,["root","sealed","bound","disarmed"])
   t.shield=maxi(int(t.get("shield",0)),mini(int(a.max_hp*.12),int(t.max_hp*.2)));t.shield_until=state.round+1;t.shield_rohan=_rank(a,"HS_A04")>=3
  a.stance={}
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 var id:String=cmd.skill_id
 if id=="CO_04":
  if _o().reserved>0:_combo()
  return
 if a.get("revived_round",-1)==state.round:return
 var t:=actor_by_id(cmd.target_id)
 if id in ["normal_attack","self_guard","guard_ally"]:
  super._execute_command(a,cmd)
  if id=="normal_attack" and a.id==HS:a.next_speed=false
  return
 _pay(a,id,content.skills[id]);_event("action",a.id,t.id,0,{"skill_id":id})
 if a.id==HS:a.next_speed=false
 match id:
  "HXS_A01":
   _apply_status(t,"diagnosed",.15,3 if _rank(a,id)>=3 else 2);t.diagnose_bonus=_rank(a,id)>=2;_o().diagnosed_phase=_o().phase;gain_mana(a,4,"diagnose")
  "HXS_A02":
   _heal(a,t,_fixed(a,.7,6),false,id)
   if _cleanse(t,2 if _rank(a,id)>=2 else 1)>0 and _rank(a,id)>=2:gain_mana(a,4,"cleanse")
   if _rank(a,id)>=3:_apply_status(t,"damage_reduction",.15,2)
  "HXS_A03":
   for who in [X,HS]:
    var friend:=actor_by_id(who);var amount:=_fixed(a,.55 if _rank(a,id)>=3 else .45,5 if _rank(a,id)>=3 else 4)
    if _rank(a,id)>=3 and friend.hp*10<friend.max_hp*3:amount*=1.5
    _heal(a,friend,amount,false,id);_apply_status(friend,"regeneration",.02,3)
    if _rank(a,id)>=2:_apply_status(friend,"regeneration_mana",2,3)
  "HXS_A04":
   _attack(a,t,.4,id,0);_apply_status(t,"attack_down",.4 if _rank(a,id)>=2 else .3,2);_try_break(a,t,["needle"])
   if _rank(a,id)>=3:t.statuses.append({"kind":"speed_down","value":.3,"starts":state.round+1,"expires":state.round+1})
  "HXS_A05":
   if alive(t):_apply_status(t,"deathsave",1,2)
   elif not t.get("revive_used",false):t.hp=maxi(1,int(t.max_hp*.3));t.defeated=false;t.revive_used=true;t.revived_round=state.round
   if _rank(a,id)>=2:_apply_status(a,"damage_reduction",.35,1)
   if _rank(a,id)>=3:gain_mana(t,12,"revive")
  "HXS_A06":
   _attack(a,t,.95,id,0);_apply_status(t,"attack_down",.2,2)
   if _try_break(a,t,["induce"]) and _rank(a,id)>=2:
    for i in state.intents:
     if i.actor_id==t.id:
      for hit in i.hits:_damage_action(t,t,float(hit)*.2,false,"backlash",id)
   if _rank(a,id)>=3:a.next_guard=.2
  "HXS_A07":
   _attack(a,t,1.15,id,1);_o().needle_round=state.round
   if _status_value(t,"diagnosed")>0 and _o().curve_round==state.round:_o().curve_phase=_o().phase;_event("curve_gate",HS,HE)
   if not _try_break(a,t,["sever"],true) and _protected(t):_apply_status(t,"attack_down",.3,2)
   if _rank(a,id)>=3:_o().bell=false
  "HS_A06":
   _o().curve_round=state.round
   _attack(a,t,2.25 if _status_value(t,"diagnosed")>0 else 1.7,id,.3)
   if _status_value(t,"diagnosed")>0 and _o().needle_round==state.round:_o().curve_phase=_o().phase;_event("curve_gate",HS,HE)
   if _try_break(a,t,["needle","sever"]) and _rank(a,id)>=3:
    gain_mana(a,6,"curve_break");gain_mana(actor_by_id(X),6,"curve_break")
  "HS_A02","HS_A03","HS_A05":
   var old:Variant=a.atk
   if id=="HS_A02":a.atk=float(a.atk)+float(a.def)*.4/1.55
   var m:float={"HS_A02":1.55,"HS_A03":1.45,"HS_A05":1.5}[id]
   if id=="HS_A02" and _rank(a,id)>=2:m*=1.5
   _attack(a,t,m,id,0);a.atk=old
   _apply_status(t,"attack_down",.25 if id=="HS_A05" else .2,2)
   if id=="HS_A02":_apply_status(t,"defense_down",.25,3)
   var broke:=_try_break(a,t,["disarm"] if id=="HS_A02" else ["interrupt"])
   if id=="HS_A02" and broke and _rank(a,id)>=3:
    for who in [X,HS]:
     var friend:=actor_by_id(who);friend.shield=maxi(int(friend.get("shield",0)),int(friend.max_hp*.1));friend.shield_until=state.round
   if id=="HS_A03":
    t.statuses.append({"kind":"flat_speed_down","value":20,"starts":state.round+1,"expires":state.round+1})
    if _rank(a,id)>=2 and _status_value(t,"diagnosed")>0:t.statuses.append({"kind":"speed_down","value":.15,"starts":state.round+1,"expires":state.round+1})
   if id=="HS_A05" and _rank(a,id)>=2:_apply_status(a,"defense_up",.05,1)
   if a.get("internal_skill")=="HS_N02" and id in ["HS_A02","HS_A05"]:a.next_speed=true
func _combo()->void:
 for who in [X,HS]:
  if not alive(actor_by_id(who)):_refund();return
 _o().reserved=0
 actor_by_id(HS).next_speed=false
 var hs:=actor_by_id(HS);var t:=actor_by_id(HE)
 _attack(hs,t,3.1,"CO_04",.5);_o().bell=false
 _apply_status(t,"attack_down",.4,2);_apply_status(t,"gate_vulnerability",.25,2)
 # Sealing is objective progress, never a protected-window break reward.
 if _o().phase not in _o().sealed_phases and _o().diagnosed_phase==_o().phase and _o().curve_phase==_o().phase:
  _o().sealed_phases.append(_o().phase);_o().seals+=1;_event("medical_seal",X,HE,1,{"protected":_protected(t)})
 else:_event("medical_sequence_missing",X,HE)
 if not _protected(t):
  for i in state.intents:
   if i.actor_id==HE and not i.executed and not i.cancelled:i.cancelled=true;t.last_break=state.round;t.protected_through=state.round+1;_event("combo_control",HS,HE)
 _event("combo_executed",X,HS)
func _fixed(a:Dictionary,scale:float,constant:float)->float:return a.atk*scale+constant*(1+39*(float(a.fixed_level)-1)/79)
func _heal(a:Dictionary,t:Dictionary,amount:float,passive:bool,reason:String)->void:
 if not alive(t):return
 var n:int=int(floor(amount))
 if passive:n=mini(n,maxi(0,int(t.max_hp*.03)-int(t.get("passive_healed",0))))
 n=mini(n,int(t.max_hp)-int(t.hp));t.hp+=n
 if passive:t.passive_healed=int(t.get("passive_healed",0))+n
 _event("heal",a.id,t.id,n,{"reason":reason,"passive":passive})
func _cleanse(t:Dictionary,count:int,kinds:Array=BAD)->int:
 var removed:=0
 for e in t.statuses.duplicate(true):
  if e.kind in kinds and removed<count:t.statuses.erase(e);removed+=1
 return removed
func _attack(a:Dictionary,t:Dictionary,m:float,id:String,ignore:float)->void:
 var defense:Variant=t.def;t.def=float(t.def)*(1-ignore);_damage_action(a,t,m,false,"normal",id);t.def=defense
func _speed(a:Dictionary,modifier:int,skill:Dictionary={})->int:
 if skill.get("kind")=="combo":return mini(int(actor_by_id(X).spd),int(actor_by_id(HS).spd))+12
 return super._speed(a,modifier,skill)-int(_status_value(a,"flat_speed_down"))+(15 if a.id==HS and a.get("next_speed",false) and not skill.get("prepare",false) else 0)
func _damage_action(a:Dictionary,t:Dictionary,m:float,aoe:bool,channel:String,id:String,guard:Dictionary={})->void:
 if not aoe and channel=="enemy" and t.team=="party":
  var hs:=actor_by_id(HS);var x:=actor_by_id(X)
  var raw:float=floor(float(a.atk)*(1-minf(_status_value(a,"attack_down"),float(rules.limits.attack_debuff))))*m
  var guarded_share:float=(.9 if _rank(hs,"HS_A01")>=3 else .75) if guard.get("id")==HS and guard.stance.get("skill_id")=="HS_A01" else (float(rules.guard.share) if not guard.is_empty() else 0.0)
  if t.id==X and alive(hs) and "HS_P03" in hs.passives and not hs.get("sacrifice_used",false) and _predict_loss(t,raw*(1-guarded_share))>=t.hp:
   hs.sacrifice_used=true
   if not hs.get("deathsave_used",false):hs.deathsave_used=true;hs.sacrifice_lock=true
   _event("sacrifice_guard",HS,X)
   _branch(a,hs,raw,"sacrifice",id);hs.sacrifice_lock=false;return
  if guard.is_empty() and t.id==HS and t.hp*10<t.max_hp*3 and m>=1.5 and alive(x) and "HXS_P03" in x.passives and not x.get("emergency_used",false):
   x.emergency_used=true;var reduction:float=x.get("reduction",0);x.reduction=maxf(reduction,.5)
   _event("emergency_guard",X,HS);_branch(a,t,raw*.5,"enemy",id);_branch(a,x,raw*.5,"emergency",id);x.reduction=reduction;return
 if guard.get("id")==HS and guard.stance.get("skill_id")=="HS_A01":
  var raw:float=floor(float(a.atk)*(1-minf(_status_value(a,"attack_down"),float(rules.limits.attack_debuff))))*m
  var share:=.9 if _rank(guard,"HS_A01")>=3 else .75
  _branch(a,t,raw*(1-share),channel,id);var loss:=_branch(a,guard,raw*share,"guard",id)
  if loss>0 and not guard.guard_rewarded:
   guard.guard_rewarded=true;gain_mana(guard,int(rules.mana.successful_guard_gain),"successful_guard");_synergy("actual_guard")
   if _rank(guard,"HS_A01")>=3:_heal(guard,t,t.max_hp*.02,true,"guard_recovery")
   _damage_action(guard,a,.5,false,"reflection","HS_A01")
  return
 var old_atk:Variant=a.atk
 if a.id==HS and a.get("internal_skill")=="HS_N02":a.atk=float(a.atk)+float(a.def)*.2
 var marked:bool=_status_value(t,"diagnosed")>0
 var old:int=t.hp
 if t.team=="enemy":
  var ordinary:float=minf(.2+_status_value(t,"posuan"),float(rules.limits.vulnerability)) if t.vulnerable_through>=state.round else 0.0
  var medical:float=maxf(_status_value(t,"diagnosed"),_status_value(t,"gate_vulnerability"))
  m*=(1+minf(float(rules.limits.vulnerability),ordinary+medical))/(1+ordinary)
  if t.get("diagnose_bonus",false) and channel=="normal":m*=1.1;t.diagnose_bonus=false
 super._damage_action(a,t,m,aoe,channel,id,guard)
 a.atk=old_atk
 if marked and channel=="normal" and t.hp<old and t.get("mark_heal_round",-1)!=state.round and _rank(actor_by_id(X),"HXS_A01")>=3:
  t.mark_heal_round=state.round;var low:=actor_by_id(X) if actor_by_id(X).hp<actor_by_id(HS).hp else actor_by_id(HS);_heal(actor_by_id(X),low,actor_by_id(X).atk*.1,true,"diagnosed_recovery")
func _predict_loss(t:Dictionary,raw:float)->int:
 var defense:float=float(t.def)*(1-minf(.5,_status_value(t,"defense_down")))
 return maxi(0,maxi(1,int(floor(raw*float(state.k)/(float(state.k)+maxf(0,defense))*(1-_reduction(t)))))-int(t.get("shield",0)))
func _branch(a:Dictionary,t:Dictionary,raw:float,channel:String,id:String)->int:
 var defense:Variant=t.def;t.def=float(t.def)*(1+_status_value(t,"defense_up"))*(1-minf(.5,_status_value(t,"defense_down")))
 var prior_shield:int=t.get("shield",0)
 var result:=super._branch(a,t,raw,channel,id);t.def=defense
 if raw>0:t.next_guard=0.0
 if prior_shield>0 and t.get("shield",0)==0 and t.get("shield_rohan",false):
  t.shield_rohan=false
  for who in [X,HS]:_heal(actor_by_id(HS),actor_by_id(who),actor_by_id(who).max_hp*.02,true,"rohan_shield_break")
 return result
func _reduction(a:Dictionary)->float:
 var result:=maxf(super._reduction(a),float(a.get("next_guard",0)))
 if a.id==HE and _o().bell:result=maxf(result,.6)
 if a.get("internal_skill")=="HS_N01":result=maxf(result,.15)
 if a.stance.get("skill_id")=="HS_A01":result=maxf(result,.35)
 return minf(result,float(rules.limits.extra_damage_reduction))
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 super._execute_intent(a,i)
 var hs:=actor_by_id(HS)
 if alive(hs) and hs.get("internal_skill")=="HS_N01" and hs.get("inner_mana_round",-1)!=state.round:hs.inner_mana_round=state.round;gain_mana(hs,3,"shaoshi_breath")
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if not alive(t) or amount<=0:return 0
 if t.id==HE:
  var loss:=mini(amount,maxi(0,int(t.hp)-1));t.hp-=loss;return loss
 if t.get("sacrifice_lock",false) and amount>=t.hp:
  var loss:=maxi(0,int(t.hp)-1);t.hp-=loss;return loss
 if amount>=t.hp and _status_value(t,"deathsave")>0 and not t.get("deathsave_used",false):
  var before:int=t.hp;t.hp=mini(int(t.max_hp),1+int(t.max_hp*.2));t.deathsave_used=true;t.statuses=t.statuses.filter(func(e):return e.kind!="deathsave");_event("deathsave",t.id,t.id);return maxi(0,before-1)
 return super._lose_hp(a,t,amount)
func _check_outcome()->void:
 if state.outcome!="" or not state.has("objective"):return
 if not alive(actor_by_id(X)) or (not alive(actor_by_id(HS)) and ("HXS_A05" not in actor_by_id(X).skills or actor_by_id(HS).get("revive_used",false))):state.outcome="defeat";_o().failure="medical_pair_exhausted";return
 if state.mode!="round_end":return
 if _o().phase==1 and _o().seals==1:
  _o().phase=2;_o().phase_start=state.round+1;_o().bell=true
  var t:=actor_by_id(HE);t.max_hp=4800;t.hp=4800;t.max_mp=300;t.mp=300;t.atk=345;t.def=200;t.spd=55
  t.statuses=[];t.last_break=-1;t.protected_through=-1;t.vulnerable_through=-1
  _event("phase_changed",HE,HE,2,{"party_resources_preserved":true});return
 if _o().seals==2 and alive(actor_by_id(X)) and alive(actor_by_id(HS)):
  actor_by_id(HE).defeated=true;state.outcome="victory";_event("nonlethal_defeat",HS,HE)
  if "HXS_P01" in actor_by_id(X).passives:
   for who in [X,HS]:
    var a:=actor_by_id(who);var heal:=mini(int(a.max_hp)-int(a.hp),int(a.max_hp*.2));a.hp+=heal;_event("postbattle_heal",X,who,heal)
   _o().postheal=true
func get_view()->Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={};v.legal_commands={}
 for who in [X,HS]:
  v.skill_costs[who]={};v.legal_commands[who]=[]
  for skill in actor_by_id(who).skills:
   v.skill_costs[who][skill]=skill_cost(actor_by_id(who),content.skills[skill])
   for a in state.actors:
    if validate_command(who,skill,a.id)=="":v.legal_commands[who].append({"skill_id":skill,"target_id":a.id})
 v.objective.summary="封功%d/2 · 协力%d/3 · 魔功护体%s。望诊护持→龙须曲直→合招封功；保护期敌人仍行动。"%[v.objective.seals,v.objective.synergy,"60%" if v.objective.bell else "已散"]
 v.objective.available_actions=[]
 if "HXS_P02" in actor_by_id(X).passives and state.round==1:v.objective.forecast=["洞若观火：抓击可护持，魔功蓄势可截脉；望诊本身不发协力。"]
 v.world_state={"map_id":state.encounter.context.get("map_id","map_ch15_duel"),"objective_id":ID,"control_actor_id":X,"player_position":[112,224],"actor_positions":{X:[112,224],HS:[160,224],HE:[256,144]},"visible_actor_ids":[X,HS,HE],"battle_phase":_o().phase,"complete":state.outcome=="victory"}
 return v
