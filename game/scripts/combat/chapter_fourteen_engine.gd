class_name ChapterFourteenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
const Same=preload("res://scripts/campaign/encounter_session.gd")
const HERO="char_liang_xiao"
const HS="char_huasheng"
const MASTER="ch14_temple_master"
const MONKS=[MASTER,"ch14_monk_east","ch14_monk_west"]
const ARRAY="ch14_wheel_array"
const WHEELS=["ch14_wheel_north","ch14_wheel_east","ch14_wheel_south","ch14_wheel_west"]
const ID="enc_ch14_datianwang_temple"
const ALLOWED=["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03","LX_A04","LX_A05","HS_A01","HS_A02","HS_A03","HS_A04","HS_A05"]
var entry_error=""
static func enemy(id:String,label:String,hp:int,atk:int,defense:int,speed:int)->Dictionary:
 return {"id":id,"name":label,"team":"enemy","max_hp":hp,"max_mp":220,"atk":atk,"def":defense,"spd":speed,"boss":true,"protection_rounds":1,"tags":["formation","armor"],"rotation":[{"name":"守阵","hits":[],"tags":[],"target_id":HERO}]}
static func encounter_config(id:String=ID)->Dictionary:
 if id!=ID:return {}
 return {"id":ID,"kind":"b11","name":"大天王寺","level":64,"xp":0,"battle_id":"B11","result":"ch14_temple_cleared","nonlethal":true,"enemies":[enemy(MASTER,"护法上师",4400,255,175,44),enemy(MONKS[1],"东护寺僧",2000,180,175,40),enemy(MONKS[2],"西护寺僧",2000,180,175,40)]}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 content.skills.LX_A03={"name":"飞星九宫剑","source_id":"LX_A03","kind":"skill","target":"enemy","hits":[.55,.55,.55],"speed":8,"break_tag":"interrupt","martial":true}
 content.skills.LX_A04={"name":"滴水穿石劲","source_id":"LX_A04","kind":"skill","target":"enemy","speed":12,"martial":true}
 content.skills.LX_A05={"name":"碧海惊涛掌","source_id":"LX_A05","kind":"skill","target":"enemy","speed":0,"martial":true}
 for row in [["HS_A01","金刚护持",0,"friend"],["HS_A02","金刚破器掌",-2,"enemy"],["HS_A03","巨力推山撼",-5,"enemy"],["HS_A04","罗汉解脱身",15,"friend"],["HS_A05","伏魔大金刚震",-6,"enemy"]]:
  content.skills[row[0]]={"name":row[1],"source_id":row[0],"kind":"skill","speed":row[2],"target":row[3]}
 content.skills.HS_A01.merge({"prepare":true,"kind":"guard"})
 content.skills.HS_A04.merge({"prepare":true,"kind":"release"})
 content.skills.CO_05={"name":"九宫巨灵·翻江倒海震","kind":"combo","target":"enemy","speed":5}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config()
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),14,14) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
 var ids:Array=[]
 for a in party:
  if not a is Dictionary:entry_error="invalid_actor";continue
  if a.get("id") not in [HERO,HS] or a.get("id") in ids or a.get("team")!="party" or a.get("status","") in ["dead","departed_chaoyun","captured"]:entry_error="invalid_actor"
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
   var source:String={"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill)
   active.append(source)
   if not source.begins_with("LX_" if a.id==HERO else "HS_") or not a.skill_ranks.has(source):entry_error="unlearned_skill"
  if active.size()>4:entry_error="active_slot_limit"
  if a.has("equipped_active_skills") and not Same.equivalent(active,a.equipped_active_skills):entry_error="loadout_mismatch"
  for rank in a.skill_ranks.values():
   if not _whole(rank,1,3):entry_error="invalid_rank"
  seen=[]
  for passive in a.passives:
   if passive not in (["LX_P01","LX_P02","LX_P03"] if a.id==HERO else ["HS_P01","HS_P02"]) or passive not in a.learned_passives or passive in seen:entry_error="invalid_passive"
   seen.append(passive)
  if seen.size()>2:entry_error="passive_slot_limit"
  if a.get("internal_skill","") not in (["LX_N02"] if a.id==HERO else ["HS_N01"]):entry_error="invalid_internal"
  if a.get("internal_stats_applied")!=true or a.get("panel_internal_skill")!=a.get("internal_skill"):entry_error="invalid_internal_panel"
  if a.id==HS and not a.skill_ranks.has("HS_A05"):entry_error="hs05_not_granted"
 if ids.size()!=2:entry_error="brothers_required"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 var clean:Array=party.duplicate(true)
 for a in clean:
  if a.id==HERO:a.skill_ranks.observe=a.skill_ranks.get("LX_A01",1)
 content.skills.LX_A03.hits=[.6,.6,.6]
 super.start(config,clean);checkpoint=snapshot()
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective={"phase":1,"nodes":[],"wheels_collapsed":false,"combo_trial":false,"synergy":0,"reserved":0,"synergy_round":0,"failure":"","innocents_safe":true,"whale_procs":0,"whale_action":"","whale_loss":0,"whale_guard":false,"p03_stacks":0,"p03_events":[],"postheal":false}
 super.begin_round()
 state.objective.synergy_round=0
 for who in [HERO,HS]:
  var a:=actor_by_id(who);a.passive_healed=0
  if a.get("shield_until",-1)<state.round:a.shield=0
  if who==HERO:_passive_heal(a,.02,"whale_breath");gain_mana(a,4,"whale_breath")
 state.intents=[]
 if state.objective.phase==1:
  for id in MONKS:
   if not alive(actor_by_id(id)):continue
   var lead:bool=id==MASTER
   var heavy:bool=lead and state.round%3==1
   _intent(id,"strike","八部金刚杵 · 破器可解" if heavy else "护阵掌 · 留意护持",[2.10 if heavy else .55],["disarm","induce"],HERO if lead else HS)
 else:
  if alive(actor_by_id(ARRAY)):_intent(ARRAY,"roar","降魔狮子吼 · 罗汉解控护体",[1.1],["sever","interrupt"],HERO)
  for id in WHEELS:
   if alive(actor_by_id(id)):_intent(id,"node","铜轮阵眼 · 先拆两处节点",[],["disarm"],HERO)
func _intent(id:String,kind:String,label:String,hits:Array,tags:Array,target:String)->void:
 state.intents.append({"actor_id":id,"intent_id":"b11:%s:%d"%[id,state.round],"kind":kind,"name":label,"target_id":target,"hits":hits,"tags":tags,"speed":0,"executed":false,"cancelled":false})
func validate_command(id:String,skill:String,target:String)->String:
 if actor_by_id(id).is_empty():return "actor_unavailable"
 if skill=="CO_05":
  if state.mode!="commands" or id not in [HERO,HS] or not state.objective.combo_trial or state.objective.synergy+state.objective.reserved<2:return "combo_unavailable"
  for who in [HERO,HS]:
   if not alive(actor_by_id(who)) or _status_value(actor_by_id(who),"root")>0:return "combo_unavailable"
  return "" if alive(actor_by_id(target)) and actor_by_id(target).team=="enemy" else "invalid_target"
 if skill in ["HS_A01","HS_A04"] and actor_by_id(target).get("team")!="party":return "invalid_target"
 if target==ARRAY and not state.objective.wheels_collapsed:return "wheel_shield_locked"
 if _status_value(actor_by_id(id),"root")>0 and skill not in ["HS_A04","self_guard"]:return "actor_rooted"
 return super.validate_command(id,skill,target)
func set_command(a:Variant,s:Variant,t:Variant,revision:Variant=-1)->String:
 if not a is String or not s is String or not t is String or not revision is int or revision < -1:return "invalid_command_type"
 if revision!=-1 and revision!=state.revision:return "stale_revision"
 var error:=validate_command(a,s,t)
 if error!="":return error
 if state.objective.reserved>0:_refund()
 if s=="CO_05":
  state.objective.synergy-=2;state.objective.reserved=2
  for who in [HERO,HS]:state.commands[who]={"actor_id":who,"skill_id":s,"target_id":t}
 else:state.commands[a]={"actor_id":a,"skill_id":s,"target_id":t}
 state.revision+=1;return ""
func _refund()->void:
 if state.objective.reserved==0:return
 state.objective.synergy=mini(3,state.objective.synergy+state.objective.reserved);state.objective.reserved=0
 state.commands.clear();_event("combo_refund",HERO,HS,2)
func apply_input(a:Variant)->Dictionary:
 if not a is Dictionary or not a.has_all(["actor_id","action_id"]):return {"accepted":false,"error":"invalid_input"}
 for key in a:
  if key not in ["actor_id","action_id","revision"]:return {"accepted":false,"error":"unexpected_field"}
 if a.actor_id not in [HERO,HS] or not a.action_id is String:return {"accepted":false,"error":"invalid_actor"}
 if a.has("revision") and (not a.revision is int or a.revision!=state.revision):return {"accepted":false,"error":"invalid_revision"}
 if state.mode!="commands" or state.outcome!="":return {"accepted":false,"error":"not_accepting_input"}
 if a.action_id=="cancel":_refund();state.commands.clear();state.revision+=1
 elif a.action_id=="retreat":_refund();state.outcome="defeat";state.mode="finished";state.objective.failure="retreated";state.revision+=1
 else:return {"accepted":false,"error":"invalid_action"}
 return {"accepted":true}
func _synergy()->void:
 if state.objective.synergy_round>=1:return
 state.objective.synergy_round+=1;state.objective.synergy=mini(3,state.objective.synergy+1)
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 if not super._break(a,t,i):return false
 _synergy()
 if t.id in WHEELS and t.id not in state.objective.nodes:state.objective.nodes.append(t.id);_event("node_broken",a.id,t.id)
 if "LX_P03" in a.get("passives",[]) and i.intent_id not in state.objective.p03_events:
  state.objective.p03_events.append(i.intent_id);state.objective.p03_stacks=mini(3,int(state.objective.p03_stacks)+1)
 return true
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 super._execute_intent(a,i)
 var hs:=actor_by_id(HS)
 if alive(hs) and hs.get("inner_mana_round",-1)!=state.round:
  hs.inner_mana_round=state.round;gain_mana(hs,3,"shaoshi_breath")
 if i.kind=="roar" and not i.cancelled:
  var target:=actor_by_id(i.target_id)
  if alive(target) and int(target.get("shield",0))==0:_apply_status(target,"root",1,2)
func _after_preparation(a:Dictionary,skill:Dictionary)->void:
 if skill.get("source_id")=="HS_A04":
  for who in [a.id,a.stance.target_id]:
   var t:=actor_by_id(who)
   t.statuses=t.statuses.filter(func(e):return e.kind not in ["root","sealed","bound","disarmed"])
   t.shield=maxi(int(t.get("shield",0)),mini(int(a.max_hp*.12),int(t.max_hp*.2)));t.shield_until=state.round+1
  a.stance={}
 if skill.get("source_id")=="HS_A01":
  a.guard_reduction=.35
  if a.stance.target_id==a.id:a.stance.kind="self_guard"
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 var id:String=cmd.skill_id
 if id=="CO_05":
  if state.objective.reserved==0:return
  if not alive(actor_by_id(HERO)) or not alive(actor_by_id(HS)) or _status_value(actor_by_id(HERO),"root")>0 or _status_value(actor_by_id(HS),"root")>0:
   _refund()
   for who in [HERO,HS]:
    if alive(actor_by_id(who)):actor_by_id(who).stance={"kind":"self_guard","target_id":who,"tokens":1,"skill_id":"self_guard"}
   return
  state.objective.reserved=0
  var h:=actor_by_id(HERO);var hs:=actor_by_id(HS);var attack:Variant=h.atk;h.atk=(float(h.atk)+float(hs.atk))/2
  for t in state.actors:
   if t.team!="enemy" or not alive(t):continue
   if t.id==ARRAY and not state.objective.wheels_collapsed:continue
   _damage_action(h,t,2.65,true,"combo",id)
   t.statuses.append({"kind":"flat_speed_down","value":25,"starts":state.round+1,"expires":state.round+1})
  h.atk=attack
  if state.objective.nodes.size()>=2 and not state.objective.wheels_collapsed:
   state.objective.wheels_collapsed=true
   for who in WHEELS:
    var wheel:=actor_by_id(who);_lose_hp(h,wheel,int(wheel.hp))
   state.objective.wheels_collapsed=true;_event("wheels_collapsed",HERO,HS,4)
  hs.stance={"kind":"guard","target_id":HERO,"tokens":1,"skill_id":"CO_05"};hs.guard_reduction=.35
  _event("combo_executed",HERO,HS);return
 if _status_value(a,"root")>0:_event("controlled_skip",a.id);return
 if id in ["HS_A02","HS_A03","HS_A05"]:
  _pay(a,id,content.skills[id]);_event("action",a.id,cmd.target_id,0,{"skill_id":id})
  var count:=0
  for t in state.actors:
   if t.team!="enemy" or not alive(t) or (t.id==ARRAY and not state.objective.wheels_collapsed) or (id=="HS_A02" and t.id!=cmd.target_id):continue
   var old:Variant=a.atk
   if id=="HS_A02":a.atk=float(a.atk)+float(a.def)*.4/1.55
   var multiplier:float={"HS_A02":1.55,"HS_A03":1.45,"HS_A05":1.50}[id]
   if id=="HS_A02" and int(a.skill_ranks.get(id,1))>=2:multiplier*=1.5
   _damage_action(a,t,multiplier,id!="HS_A02","normal",id);a.atk=old
   _apply_status(t,"attack_down",.25 if id=="HS_A05" else .20,2)
   if id=="HS_A02":_apply_status(t,"defense_down",.25,3)
   for i in state.intents:
    if i.actor_id==t.id and not i.executed and not i.cancelled and ((id!="HS_A03" and "disarm" in i.tags) or (id!="HS_A02" and "interrupt" in i.tags)):
     if _break(a,t,i):i.cancelled=true
   count+=1
  if id=="HS_A05" and int(a.skill_ranks.get(id,1))>=2:_apply_status(a,"defense_up",minf(.15,count*.05),1)
  return
 var marked_before:bool=_status_value(a,"mingxin")>0
 a.observe_strike=marked_before and a.get("observe_bonus",false) and id in ["normal_attack","LX_A03","LX_A04","LX_A05"]
 var breaks_before:int=state.break_count
 if id in ["LX_A04","LX_A05"]:
  var skill:Dictionary=content.skills[id];_pay(a,id,skill);_event("action",a.id,cmd.target_id,0,{"skill_id":id})
  var marked:bool=_status_value(a,"mingxin")>0;var critical:=1.5 if marked else 1.0
  if marked:a.statuses=a.statuses.filter(func(e):return e.kind!="mingxin")
  var triggered_extra:=false
  for t in state.actors:
   if t.team!="enemy" or not alive(t) or (id=="LX_A04" and t.id!=cmd.target_id):continue
   var defense:Variant=t.def
   if id=="LX_A04":
    for i in state.intents:
     if i.actor_id==t.id and not i.executed and not i.cancelled and "disarm" in i.tags:
      if _break(a,t,i):i.cancelled=true
    t.def=float(defense)*(.60 if int(a.skill_ranks.get(id,1))>=3 else .75)
    if int(a.skill_ranks.get(id,1))>=2 and (_status_value(t,"posuan")>0 or _status_value(t,"diagnosed")>0):critical=1.5
   for hit in ([.75,.60] if id=="LX_A05" else [1.55]):_damage_action(a,t,hit*critical,false,"normal",id)
   t.def=defense
   if id=="LX_A05" and int(a.skill_ranks.get(id,1))>=2 and not triggered_extra and (_status_value(t,"inner_wound")>0 or _status_value(t,"bleed")>0):
    triggered_extra=true;var loss:=_lose_hp(a,t,int(floor(a.atk*.30)));_event("tide_true_damage",a.id,t.id,loss)
   _apply_status(t,"speed_down" if id=="LX_A05" else "attack_down",.20 if id=="LX_A05" else .15,2)
   if id=="LX_A05":
    for i in state.intents:
     if i.actor_id==t.id and not i.executed and not i.cancelled and "interrupt" in i.tags:
      if _break(a,t,i):i.cancelled=true
  if id=="LX_A05" and int(a.skill_ranks.get(id,1))>=3:
   a.shield=maxi(int(a.get("shield",0)),mini(int(floor(a.atk*.40)),int(floor(a.max_hp*.20))));a.tide_shield_until=int(state.round)+1
  a.observe_strike=false
  if marked_before:a.observe_bonus=false
  return
 super._execute_command(a,cmd)
 if id=="observe" and int(a.skill_ranks.get("LX_A01",1))>=3:
  if not a.get("observe_bonus_granted",false):a.observe_bonus=true;a.observe_bonus_granted=true
  for e in actor_by_id(cmd.target_id).get("statuses",[]):
   if e.kind=="posuan":e.expires=int(state.round)+2
 elif marked_before and _status_value(a,"mingxin")==0:a.observe_bonus=false
 a.observe_strike=false
 if id=="LX_A03":
  a.jiugong_through=state.round;a.jiugong_speed_round=int(state.round)+1
  if state.break_count>breaks_before and int(a.skill_ranks.get(id,1))>=3:gain_mana(a,4,"jiugong_break");a.ready[id]=maxi(int(state.round)+1,int(a.ready[id])-1)
func _speed(a:Dictionary,modifier:int,skill:Dictionary={})->int:
 return (mini(int(actor_by_id(HERO).spd),int(actor_by_id(HS).spd))+5) if skill.get("kind")=="combo" else super._speed(a,modifier,skill)+(10 if a.get("jiugong_speed_round",-1)==state.round else 0)-int(_status_value(a,"flat_speed_down"))
func _passive_heal(a:Dictionary,ratio:float,reason:String)->void:
 var heal:=mini(int(a.max_hp)-int(a.hp),mini(int(floor(a.max_hp*ratio)),maxi(0,int(floor(a.max_hp*.03))-int(a.get("passive_healed",0)))))
 a.hp+=heal;a.passive_healed=int(a.get("passive_healed",0))+heal;_event(reason,a.id,a.id,heal)
func _counter(a:Dictionary,t:Dictionary,induced:bool)->void:
 var before:int=a.counter_count;super._counter(a,t,induced)
 if a.counter_count==before:return
 if induced and int(a.skill_ranks.get("LX_A02",1))>=2:
  _passive_heal(a,.02,"sancai_heal")
 if int(a.skill_ranks.get("LX_A02",1))>=3:_apply_status(t,"attack_down",.15,2);_apply_status(t,"inner_wound",1.0,2)
func _damage_action(a:Dictionary,t:Dictionary,m:float,aoe:bool,channel:String,id:String,guard:Dictionary={})->void:
 if guard.get("id")==HS and guard.stance.get("skill_id") in ["HS_A01","CO_05"]:
  var attack:float=floor(float(a.atk)*(1+maxf(_status_value(a,"attack_up"),_status_value(a,"friend_rage"))))*(1-minf(_status_value(a,"attack_down"),float(rules.limits.attack_debuff)))
  var raw:float=maxf(1,attack)*m
  if int(t.vulnerable_through)>=state.round:raw*=1+minf(.2+_status_value(t,"posuan"),float(rules.limits.vulnerability))
  var share:=.9 if int(guard.skill_ranks.get("HS_A01",1))>=3 else .75
  _branch(a,t,raw*(1-share),channel,id);var loss:=_branch(a,guard,raw*share,"guard",id)
  if loss>0 and not guard.guard_rewarded:
   guard.guard_rewarded=true;gain_mana(guard,int(rules.mana.successful_guard_gain),"successful_guard");_synergy()
   _damage_action(guard,a,.5,false,"reflection","HS_A01")
  return
 var previous_statuses:Array=a.statuses.duplicate(true)
 if a.id==HERO:
  var bonus:=float(state.objective.p03_stacks)*.05
  if bonus>_status_value(a,"attack_up"):_apply_status(a,"attack_up",bonus,1)
  if a.get("observe_strike",false):m*=1.1
  if "LX_P03" in a.get("passives",[]) and t.get("tags",[]).has("formation"):m*=1.25
 super._damage_action(a,t,m,aoe,channel,id,guard)
 a.statuses=previous_statuses
func _branch(a:Dictionary,t:Dictionary,raw:float,channel:String,id:String)->int:
 var old_def:Variant=t.def;var old_reduction:float=t.get("reduction",0.0)
 if t.id==HERO:
  t.def=int(floor(float(old_def)*(1.0+maxf(float(state.objective.p03_stacks)*.05,_status_value(t,"defense_up")))))
  if t.get("jiugong_through",-1)==state.round:t.reduction=maxf(old_reduction,.2)
  if channel=="enemy" and t.get("internal_skill","")=="LX_N02":
   if state.objective.whale_action!=id:state.objective.whale_action=id;state.objective.whale_loss=0;state.objective.whale_guard=false
   if state.objective.whale_guard:t.reduction=maxf(float(t.get("reduction",0)),.30)
 t.def=float(t.def)*(1-minf(_status_value(t,"defense_down"),float(rules.limits.defense_debuff)))
 if t.id==HS:t.def=float(t.def)*(1+_status_value(t,"defense_up"))
 var before:int=t.hp;var result:=super._branch(a,t,raw,channel,id)
 if t.id==HERO and channel=="enemy" and t.get("internal_skill","")=="LX_N02":
  state.objective.whale_loss+=before-int(t.hp)
  if not state.objective.whale_guard and state.objective.whale_loss>int(t.max_hp)*.25 and state.objective.whale_procs<2:
   state.objective.whale_guard=true;state.objective.whale_procs+=1;_event("whale_guard",HERO,HERO,1,{"subsequent_segments_only":true})
 t.def=old_def;t.reduction=old_reduction
 if raw>0 and t.get("jiugong_through",-1)==state.round:t.jiugong_through=-1
 return result
func _reduction(a:Dictionary)->float:
 var result:=super._reduction(a)
 if a.id==HS:result=maxf(result,.15)
 if a.stance.get("skill_id") in ["HS_A01","CO_05"]:result=maxf(result,.35)
 return minf(result,float(rules.limits.extra_damage_reduction))
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if t.get("innocent",false):
  state.objective.innocents_safe=false;state.objective.failure="innocent_harmed";state.outcome="defeat";return 0
 if not alive(t) or amount<=0:return 0
 if t.id==ARRAY and not state.objective.wheels_collapsed:return 0
 if t.id in WHEELS and not state.objective.wheels_collapsed:
  var capped:=mini(maxi(0,int(t.hp)-1),amount);t.hp-=capped;return capped
 var loss:=mini(int(t.hp),amount)
 if t.team=="enemy" and loss>=int(t.hp):
  loss=maxi(0,int(t.hp)-1);t.defeated=true;_event("nonlethal_defeat",a.id,t.id)
 t.hp-=loss
 if t.hp<=0:t.defeated=true
 return loss
func _check_outcome()->void:
 if state.outcome!="" or not state.has("objective"):return
 if not alive(actor_by_id(HERO)) and not alive(actor_by_id(HS)):state.outcome="defeat";state.objective.failure="brother_exhausted";return
 if state.mode!="round_end":return
 if state.objective.phase==1:
  for who in MONKS:
   if alive(actor_by_id(who)):return
  state.objective.phase=2;state.objective.combo_trial=true;state.objective.synergy=maxi(2,state.objective.synergy)
  for who in [HERO,HS]:actor_by_id(who).skills.append("CO_05")
  for row in [[ARRAY,"降魔转轮大阵",5200,280,190,48],[WHEELS[0],"北铜轮阵眼",1000,0,190,0],[WHEELS[1],"东铜轮阵眼",1000,0,190,0],[WHEELS[2],"南铜轮阵眼",1000,0,190,0],[WHEELS[3],"西铜轮阵眼",1000,0,190,0]]:
   var t:=enemy(row[0],row[1],row[2],row[3],row[4],row[5]);t.merge({"hp":t.max_hp,"mp":t.max_mp,"ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":false},true);state.actors.append(t)
  _event("combo_trial_granted",HERO,HS,2,{"skill_id":"CO_05","resources_preserved":true});return
 if state.objective.wheels_collapsed and not alive(actor_by_id(ARRAY)):
  state.outcome="victory"
  for who in [HERO,HS]:
   var t:=actor_by_id(who)
   if not alive(t):t.hp=maxi(1,int(t.max_hp*.2));t.defeated=false;_event("postbattle_revive",who,who,int(t.hp))
  state.objective.postheal=true
func get_view()->Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={};v.legal_commands={}
 for who in [HERO,HS]:
  v.skill_costs[who]={};v.legal_commands[who]=[]
  for skill in actor_by_id(who).skills:
   v.skill_costs[who][skill]=skill_cost(actor_by_id(who),content.skills[skill])
   for a in state.actors:
    if validate_command(who,skill,a.id)=="":v.legal_commands[who].append({"skill_id":skill,"target_id":a.id})
 v.objective.summary="全场戒杀 · 阵眼%d/2 · 铜轮%s · 协力%d/3。先破两节点，再以兄弟合招震塌四轮。"%[mini(2,v.objective.nodes.size()),"已塌" if v.objective.wheels_collapsed else "仍在",v.objective.synergy]
 v.objective.available_actions=[]
 var visible:Array=[HERO,HS];var positions:Dictionary={HERO:[112,224],HS:[160,224]}
 for a in state.actors:
  if a.team=="enemy" and alive(a):visible.append(a.id);positions[a.id]=[240+(visible.size()%3)*24,112+(visible.size()%2)*32]
 v.world_state={"map_id":state.encounter.context.get("map_id","map_ch14_temple_hall"),"objective_id":ID,"control_actor_id":HERO,"player_position":[112,224],"actor_positions":positions,"visible_actor_ids":visible,"battle_phase":state.objective.phase,"complete":state.outcome=="victory"}
 return v
