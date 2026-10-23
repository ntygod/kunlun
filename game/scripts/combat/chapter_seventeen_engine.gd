class_name ChapterSeventeenCombatEngine
extends "res://scripts/combat/chapter_sixteen_engine.gd"
## B13 is split around the evidence investigation. Phase two preserves HP/MP.
## Enemy base panels follow V3; objectives never grant victory through a UI flag.
const LIU="char_liu_yingying"
const FENG="char_feng_lian"
const DOUBLE="npc_ch17_double"
const AMO="npc_ch17_amo"
const COMMON=["normal_attack","self_guard","guard_ally"]
const HERO_SKILLS=["observe","sancai_counter","LX_A03","LX_A04","LX_A05","LX_A06"]
const LIU_SKILLS=["LYY_A01","LYY_A03","LYY_A05","LYY_A08"]
const FENG_SKILLS=["FL_S01","FL_S02"]
var _sword_action=false
static func _enemy(id:String,name:String,hp:int,mp:int,atk:int,defense:int,speed:int,rotation:Array,boss:bool=true)->Dictionary:
 return {"id":id,"name":name,"team":"enemy","max_hp":hp,"max_mp":mp,"atk":atk,"def":defense,"spd":speed,"boss":boss,"protection_rounds":1,"rotation":rotation,"row":"front"}
static func encounter_config(id:String="ch17_road_wolves")->Dictionary:
 var enemies:Array=[];var title:="";var description:=""
 match id:
  "ch17_road_wolves":
   title="草原狼群 · 护住归路";description="梁萧与风怜协作护商。破煞可打断扑袭，汇涓接引连续撕咬。"
   for n in range(2):enemies.append(_enemy("npc_ch17_road_wolf_"+str(n),"荒原狼"+str(n+1),650,0,155,110,49,[{"name":"扑咬 · 可打断或引偏","target_id":FENG if n==0 else HERO,"hits":[.6,.6],"tags":["interrupt","induce","disarm"]}],false))
  "ch17_wolf_double":
   title="天山双狼 · 狼皮替身";description="回风斩扰乱狼群，软索钩住替身。两招实际命中后，群狼会反噬持哨者；不能凭空跳过交锋。"
   enemies.append(_enemy(DOUBLE,"披狼皮的替身",4600,200,290,170,65,[{"name":"双狼啸月杀 · 破器、诱导","target_id":HERO,"hits":[.75,.75],"tags":["disarm","induce","interrupt"]},{"name":"挥爪横扫 · 全体","target_id":HERO,"hits":[.85],"tags":["interrupt"],"aoe":true}]))
   for n in range(3):enemies.append(_enemy("npc_ch17_b13_wolf_"+str(n),"凶狼"+str(n+1),1800,200,290,170,65,[{"name":"凶狼扑袭 · 可引偏","target_id":[FENG,LIU,HERO][n],"hits":[.85],"tags":["induce","interrupt","disarm"]}],false))
  "ch17_amo":
   title="天山双狼 · 救风怜";description="梁萧观势与风怜望气共同锁定真身；莺莺以虚实步或飞钩解围，再由飞星九宫剑完成斩落。此段不补满真气。"
   enemies.append(_enemy(AMO,"天狼子·阿莫",6800,280,335,195,72,[{"name":"嗜血狼牙锁 · 点名风怜，可诱导/夺刃","target_id":FENG,"hits":[1.5],"tags":["induce","disarm"]},{"name":"声东击西 · 梁萧观势与风怜望气辨真身","target_id":HERO,"hits":[.6,.6,.6],"tags":["interrupt","induce"]}]))
  _:return {}
 return {"id":id,"name":title,"description":description,"kind":"ordinary" if id=="ch17_road_wolves" else "boss","level":71,"xp":0,"result":id+"_resolved","enemies":enemies}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 for row in [["LYY_A01","虚实步·惊鸿诱","feint","enemy",22],["LYY_A03","软索飞钩·绊马","skill","enemy",10],["LYY_A05","双飞燕回翔","skill","friend",25],["LYY_A08","天山掠海·回风斩","skill","enemy",18],["FL_S01","天罚负剑·破煞","skill","enemy",10],["FL_S02","沙海勘水·望气","skill","enemy",16]]:
  content.skills[row[0]]={"name":row[1],"source_id":row[0],"kind":row[2],"target":row[3],"speed":row[4],"martial":true}
 content.skills.LYY_A01.prepare=true
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config(str(config.get("id","")))
 if canonical.is_empty():entry_error="invalid_encounter"
 for key in canonical:
  if not Same.equivalent(config.get(key),canonical[key]):entry_error="invalid_encounter"
 for key in config:
  if key not in canonical and key!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),17,17) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
 var expected:Array=[HERO,FENG] if config.get("id")=="ch17_road_wolves" else [HERO,LIU,FENG]
 if party.size()!=expected.size():entry_error="wrong_party"
 var seen:Array=[]
 for value in party:
  if not value is Dictionary or not value.get("id") is String or value.id not in expected or value.id in seen:entry_error="invalid_member";continue
  var a:Dictionary=value;seen.append(a.id)
  if a.get("team")!="party" or a.get("status") in ["dead","permanently_departed"]:entry_error="unavailable_member"
  for key in ["hp","mp","max_hp","max_mp","atk","def","spd","fixed_level"]:
   if not _whole(a.get(key),1 if key in ["hp","max_hp","fixed_level"] else 0):entry_error="invalid_number"
  if not a.get("skills") is Array or not a.get("skill_ranks") is Dictionary or not a.get("equipped_active_skills") is Array or not a.get("passives") is Array or not a.get("learned_passives") is Array:entry_error="invalid_metadata";continue
  if entry_error!="":continue
  if a.hp>a.max_hp or a.mp>a.max_mp or a.fixed_level>80:entry_error="invalid_resources"
  var allowed:Array=HERO_SKILLS if a.id==HERO else (LIU_SKILLS if a.id==LIU else FENG_SKILLS)
  var active:Array=[];var unique:Array=[]
  for skill in a.skills:
   if not skill is String or skill in unique or (skill not in COMMON and skill not in allowed):entry_error="invalid_skill";continue
   unique.append(skill)
   if skill not in COMMON:
    var source:String={"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill);active.append(source)
    if not _whole(a.skill_ranks.get(source),1,3):entry_error="unlearned_skill"
  if active.size()>4 or not Same.equivalent(active,a.equipped_active_skills):entry_error="loadout_mismatch"
  if a.id==HERO and int(a.skill_ranks.get("LX_A06",1))!=1:entry_error="future_river_rank"
  if a.id==LIU and int(a.skill_ranks.get("LYY_A08",1))!=1:entry_error="future_liuying_rank"
  if a.id==FENG:
   var fixed:Dictionary={"fixed_level":70,"max_hp":1816,"max_mp":162,"atk":262,"def":158,"spd":56}
   for key in fixed:
    if a.get(key)!=fixed[key]:entry_error="limited_panel_changed"
   if a.get("kind")!="limited":entry_error="limited_actor_required"
  elif a.get("internal_stats_applied")!=true or a.get("panel_internal_skill")!=a.get("internal_skill"):entry_error="invalid_internal_panel"
  unique=[]
  var passives:Array=["LX_P01","LX_P02","LX_P03"] if a.id==HERO else (["LYY_P01","LYY_P03"] if a.id==LIU else ["FL_P01"])
  for passive in a.passives:
   if passive not in passives or passive not in a.learned_passives or passive in unique:entry_error="invalid_passive"
   unique.append(passive)
  if unique.size()>2:entry_error="passive_slot_limit"
 if entry_error=="" and config.id=="ch17_amo":
  if not ctx.get("amo_exposed",false) or not ctx.get("b13_boundary") is Dictionary or ctx.b13_boundary.size()!=3:entry_error="phase_boundary_missing"
  else:
   for a in party:
    var old:Variant=ctx.b13_boundary.get(a.id)
    if not old is Dictionary or not _whole(old.get("mp"),0,int(a.max_mp)) or int(a.mp)!=int(old.mp):entry_error="phase_mana_changed"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 var clean:Array=party.duplicate(true)
 for a in clean:
  if a.id==HERO:
   a.skill_ranks.observe=a.skill_ranks.get("LX_A01",1)
   content.skills.LX_A03.hits=[.6,.6,.6] if int(a.skill_ranks.get("LX_A03",1))>=2 else [.55,.55,.55]
 _initialize_state(config,clean,config.id!="ch17_amo")
 begin_round();checkpoint=snapshot()
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 super.begin_round()
 if not state.objective.has("revolt"):
  state.objective.merge({"revolt":false,"wind_hit":false,"hook_hit":false,"observed":false,"sensed":false,"exposed":false,"rescued":false,"sword_finish":false,"synergy":0,"synergy_round":-1,"sense_bonus":false,"advice_used":false,"shelter_ready":1,"shelter_action":"","shelter_target":"","aura_round":-1,"ambush_actions":[]})
 var l:=actor_by_id(LIU)
 if alive(l) and l.get("internal_skill")=="LYY_N03":
  for a in state.actors:
   if a.team=="party":a.statuses.append({"kind":"speed_up","value":.12,"starts":int(state.round)+1,"expires":int(state.round)+1})
func skill_cost(a:Dictionary,skill:Dictionary)->int:
 var id:String=skill.get("source_id","");var spec:Dictionary=rules.skills.get(id,skill)
 var floor_cost:float=spec.get("mp_floor",0)
 if id=="LYY_A05" and int(a.get("skill_ranks",{}).get(id,1))>=2:floor_cost=6
 var cost:float=maxf(floor_cost,float(a.max_mp)*float(spec.get("mp_percent",0)))
 var discount:float=float(a.get("discount",0))+(0.25 if _status_value(a,"friend_rage")>0 else 0.0)
 var first:bool=a.id==LIU and "LYY_P01" in a.get("passives",[]) and state.get("round",1)==1 and not skill.get("prepare",false) and skill.kind!="combo"
 if first or a.get("advice_discount",false):discount=maxf(discount,.50)
 return int(ceil(cost*(1.0-minf(discount,float(rules.mana.maximum_discount)))))
func _pay(a:Dictionary,id:String,skill:Dictionary)->void:
 var paid:=skill_cost(a,skill);super._pay(a,id,skill)
 if paid>0 and a.get("advice_discount",false):a.advice_discount=false
func _speed(a:Dictionary,modifier:int,skill:Dictionary={})->int:
 var speed:int=super._speed(a,modifier,skill)-int(_status_value(a,"speed_flat_down"))
 if int(a.get("fly_speed_start",999999))<=int(state.round) and int(a.get("fly_speed_end",-1))>=int(state.round):speed+=20
 if a.id==LIU and "LYY_P01" in a.get("passives",[]) and state.round==1 and not skill.is_empty() and not skill.get("prepare",false) and skill.kind!="combo":speed+=100000
 return speed
func validate_command(a:String,s:String,t:String)->String:
 var error:=super.validate_command(a,s,t)
 if error!="":return error
 if content.skills[s].target=="friend" and actor_by_id(a).team!=actor_by_id(t).team:return "invalid_target"
 return ""
func _after_preparation(a:Dictionary,skill:Dictionary)->void:
 super._after_preparation(a,skill)
 if a.id==LIU and skill.kind=="feint":_event("yanzhi_feint",LIU,a.stance.target_id,0,{"horse":"animal_yanzhi","noncombat":true})
func _exposure()->void:
 state.objective.exposed=state.objective.observed and state.objective.sensed
func _aura()->void:
 if state.objective.aura_round==state.round:return
 var l:=actor_by_id(LIU)
 if not alive(l) or l.get("internal_skill")!="LYY_N03":return
 state.objective.aura_round=state.round
 for a in state.actors:
  if a.team=="party" and alive(a):a.statuses.append({"kind":"technique_bonus","value":.20,"starts":int(state.round),"expires":int(state.round)+1})
 _event("tianqin_aura",LIU,"",1)
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 if not super._break(a,t,i):return false
 if a.id==LIU:_aura()
 _gain_synergy("break")
 return true
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 if state.objective.revolt and str(a.id).begins_with("npc_ch17_b13_wolf_"):
  i.executed=true
  if i.cancelled:return
  var target:=actor_by_id(DOUBLE)
  if alive(target):
   _event("wolves_revolt",a.id,DOUBLE)
   for hit in i.hits:_damage_action(a,target,float(hit),false,"enemy_revolt",i.intent_id)
  return
 var l:=actor_by_id(LIU)
 if alive(l) and l.stance.get("kind")=="feint" and l.stance.get("target_id")==a.id and int(l.stance.get("tokens",0))>0 and not i.cancelled and not i.get("aoe",false):
  l.stance.tokens=0;i.target_id=LIU
  if "induce" in i.tags and _break(l,a,i):
   i.executed=true;_event("feint_miss",LIU,a.id)
   if a.id==AMO and state.objective.exposed:state.objective.rescued=true;_event("feng_rescued",LIU,FENG)
   if int(l.skill_ranks.get("LYY_A01",1))>=2 and l.counter_count<int(rules.limits.counter_per_actor_round):
    l.counter_count+=1;_damage_action(l,a,1.1,false,"counter",i.intent_id+":feint")
   if int(l.skill_ranks.get("LYY_A01",1))>=3:_apply_status(l,"mingxin",1,99999999);gain_mana(l,4,"feint")
   return
  # During resilience the attack is only redirected, never cancelled.
  l.feint_reduction_action=i.intent_id
 var shelter:Dictionary={}
 if i.get("aoe",false) and not i.cancelled and alive(l) and "LYY_P03" in l.get("passives",[]) and state.round>=state.objective.shelter_ready:
  for member in state.actors:
   if member.team=="party" and member.id!=LIU and alive(member) and (shelter.is_empty() or float(member.hp)/member.max_hp<float(shelter.hp)/shelter.max_hp):shelter=member
  if not shelter.is_empty():state.objective.shelter_action=i.intent_id;state.objective.shelter_target=shelter.id;state.objective.shelter_ready=state.round+2;_event("shelter",LIU,shelter.id)
 super._execute_intent(a,i)
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 a.technique_action_bonus=_status_value(a,"technique_bonus");a.technique_action_used=false
 _execute_chapter_command(a,cmd)
 if a.technique_action_used:a.statuses=a.statuses.filter(func(e):return e.kind!="technique_bonus")
 a.erase("technique_action_bonus");a.erase("technique_action_used")
func _gain_synergy(reason:String)->bool:
 if state.objective.synergy_round==state.round or state.objective.synergy>=int(rules.synergy.capacity):return false
 state.objective.synergy_round=state.round;state.objective.synergy+=1;_event("synergy","","",1,{"reason":reason});return true
func _execute_chapter_command(a:Dictionary,cmd:Dictionary)->void:
 var skill_id:String=cmd.skill_id
 if a.id==HERO:
  _sword_action=skill_id=="LX_A03" and state.objective.rescued
  super._execute_command(a,cmd);_sword_action=false
  if skill_id=="observe" and cmd.target_id==AMO:state.objective.observed=true;_exposure()
  return
 if skill_id in COMMON:
  super._execute_command(a,cmd)
  if a.id==FENG:_advice(a)
  return
 var target:=actor_by_id(cmd.target_id)
 if not alive(target):
  _event("command_invalidated",a.id,cmd.target_id);return
 var skill:Dictionary=content.skills[skill_id];_pay(a,skill_id,skill);_event("action",a.id,target.id,0,{"skill_id":skill_id})
 var marked:bool=_status_value(a,"mingxin")>0
 var critical:float=2.0 if marked and skill_id=="LYY_A08" else (1.5 if marked else 1.0)
 if marked and skill_id in ["LYY_A03","LYY_A08","FL_S01"]:a.statuses=a.statuses.filter(func(e):return e.kind!="mingxin")
 match skill_id:
  "LYY_A03":
   for t in state.actors:
    if t.team!="enemy" or not alive(t) or t.get("row","front")!="front":continue
    _damage_action(a,t,1.25*critical,false,"normal",skill_id)
    if t.id==DOUBLE:state.objective.hook_hit=true
    _apply_status(t,"speed_flat_down",15,2);_apply_status(t,"defense_down",.20,2)
    for intent in state.intents:
     if intent.actor_id==t.id and not intent.executed and not intent.cancelled and ("disarm" in intent.tags or "interrupt" in intent.tags) and _break(a,t,intent):
      intent.cancelled=true
      if t.id==AMO and state.objective.exposed:state.objective.rescued=true;_event("feng_rescued",LIU,FENG)
  "LYY_A08":
   for t in state.actors:
    if t.team!="enemy" or not alive(t):continue
    _damage_action(a,t,(2.35 if t.id==target.id else 1.2)*critical,true,"normal",skill_id)
    if t.id==DOUBLE:state.objective.wind_hit=true
  "LYY_A05":
   var ids:Array=[a.id] if target.id==a.id else [a.id,target.id]
   for id in ids:
    var member:=actor_by_id(id);var amount:=mini(int(floor(member.max_hp*.05)),int(member.max_hp)-int(member.hp));member.hp+=amount;_event("fly_heal",a.id,id,amount)
    member.statuses.append({"kind":"speed_up","value":0.0,"starts":int(state.round)+1,"expires":int(state.round)+2})
    member.fly_speed_start=int(state.round)+1;member.fly_speed_end=int(state.round)+2;member.fly_guard=true
    if int(a.skill_ranks.get(skill_id,1))>=2:member.statuses=member.statuses.filter(func(e):return e.kind not in ["speed_down","root"])
    if int(a.skill_ranks.get(skill_id,1))>=3:member.fly_follow=true
   _apply_status(a,"mingxin",1,99999999)
  "FL_S01":
   _damage_action(a,target,1.65*critical,false,"normal",skill_id);_apply_status(target,"defense_down",.25,2)
   for intent in state.intents:
    if intent.actor_id==target.id and not intent.executed and not intent.cancelled and ("disarm" in intent.tags or "interrupt" in intent.tags) and _break(a,target,intent):intent.cancelled=true
  "FL_S02":
   for t in state.actors:
    if t.team=="enemy" and alive(t):_apply_status(t,"exposed",.15,2)
   if not state.objective.sense_bonus and _gain_synergy("sand_sense"):state.objective.sense_bonus=true
   if target.id==AMO:state.objective.sensed=true;_exposure()
 if state.objective.wind_hit and state.objective.hook_hit and not state.objective.revolt:
  state.objective.revolt=true;_event("wolf_control_broken",LIU,DOUBLE)
 if a.id==FENG:_advice(a)
func _advice(f:Dictionary)->void:
 var h:=actor_by_id(HERO)
 if state.objective.advice_used or "FL_P01" not in f.get("passives",[]) or not alive(h):return
 var mental:=false
 for effect in h.statuses:
  if effect.kind in ["confusion","fear","charm"]:mental=true
 if float(h.mp)>=float(h.max_mp)*.30 and not mental:return
 state.objective.advice_used=true;h.advice_discount=true
 for n in range(h.statuses.size()):
  if h.statuses[n].kind in ["confusion","fear","charm"]:h.statuses.remove_at(n);break
 _passive_heal(h,.02,"feng_advice");_event("advice",FENG,HERO)
func _damage_action(a:Dictionary,t:Dictionary,m:float,aoe:bool,channel:String,id:String,guard:Dictionary={})->void:
 var bonus:float=a.get("technique_action_bonus",0.0) if channel=="normal" else 0.0
 if bonus>0:a.technique_action_used=true;m*=1.0+minf(bonus,float(rules.limits.technique_damage))
 var previous_def:Variant=t.def
 t.def=float(previous_def)*(1.0-minf(_status_value(t,"defense_down"),float(rules.limits.defense_debuff)))
 var vulnerable:float=.20+_status_value(t,"posuan") if t.vulnerable_through>=state.round else 0.0
 var exposure:=_status_value(t,"exposed")
 m*=(1.0+minf(vulnerable+exposure,float(rules.limits.vulnerability)))/(1.0+minf(vulnerable,float(rules.limits.vulnerability)))
 super._damage_action(a,t,m,aoe,channel,id,guard);t.def=previous_def
 if channel=="normal" and t.id==AMO and not state.objective.exposed and alive(t) and alive(a):
  var action_key:String="%s:%d:%s"%[a.id,state.round,id]
  if action_key not in state.objective.ambush_actions and t.counter_count<int(rules.limits.counter_per_actor_round):
   t.counter_count+=1;state.objective.ambush_actions.append(action_key);_event("blind_strike_ambush",AMO,a.id)
   super._damage_action(t,a,1.8,false,"counter",action_key+":ambush")
 # A same-action follow-up is consumed once, not one extra turn or one per segment.
 if channel=="normal" and a.get("fly_follow",false) and alive(a) and alive(t):
  a.fly_follow=false;super._damage_action(a,t,.40,false,"follow",id+":fly")
func _branch(a:Dictionary,t:Dictionary,raw:float,channel:String,id:String)->int:
 var old:float=t.get("reduction",0)
 if channel=="enemy":
  if t.get("feint_reduction_action","")==id:t.reduction=maxf(old,.35)
  if state.objective.shelter_action==id and state.objective.shelter_target==t.id:t.reduction=maxf(float(t.get("reduction",0)),.35)
  if t.get("fly_guard",false):t.fly_guard_action=id;t.fly_guard=false
  if t.get("fly_guard_action","")==id:t.reduction=maxf(float(t.get("reduction",0)),.20)
 var damage:=super._branch(a,t,raw,channel,id);t.reduction=old
 return damage
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if t.id==DOUBLE and not (state.objective.wind_hit and state.objective.hook_hit):amount=mini(amount,maxi(0,int(t.hp)-1))
 if t.id==AMO:
  if not (state.objective.exposed and state.objective.rescued and _sword_action):amount=mini(amount,maxi(0,int(t.hp)-1))
  elif amount>=int(t.hp):state.objective.sword_finish=true
 return super._lose_hp(a,t,amount)
func _check_outcome()->void:
 if state.outcome!="":return
 for a in state.actors:
  if a.team=="party" and not alive(a):state.outcome="defeat";state.objective.failure="companion_exhausted";_event("outcome","","",0,{"result":"defeat"});return
 if state.encounter.id=="ch17_wolf_double" and not alive(actor_by_id(DOUBLE)):
  state.outcome="victory";_event("wolves_scatter","",DOUBLE);_event("outcome","","",0,{"result":"victory"});return
 if state.encounter.id=="ch17_amo" and not alive(actor_by_id(AMO)):
  if state.objective.sword_finish:state.outcome="victory";_event("outcome","","",0,{"result":"victory"})
  return
 super._check_outcome()
func get_view()->Dictionary:
 var view:Dictionary=snapshot()
 if entry_error!="":return view
 view.skill_data=content.skills.duplicate(true);view.skill_costs={};view.legal_commands={}
 for a in state.actors:
  if a.team!="party":continue
  view.skill_costs[a.id]={};view.legal_commands[a.id]=[]
  for skill in a.skills:
   view.skill_costs[a.id][skill]=skill_cost(a,content.skills[skill])
   for target in state.actors:
    if validate_command(a.id,skill,target.id)=="":view.legal_commands[a.id].append({"skill_id":skill,"target_id":target.id})
 view.objective.available_actions=[]
 if state.encounter.id=="ch17_wolf_double":view.objective.summary="回风斩 %s · 飞钩 %s · 群狼%s"%["已命中" if state.objective.wind_hit else "待出招","已命中" if state.objective.hook_hit else "待出招","反噬持哨者" if state.objective.revolt else "仍受控制"]
 elif state.encounter.id=="ch17_amo":view.objective.summary="观势 %s · 望气 %s · 风怜%s · 未辨先攻会遭背刺；最后以飞星斩落"%["已辨" if state.objective.observed else "待辨","已辨" if state.objective.sensed else "待辨","已脱险" if state.objective.rescued else "待救"]
 else:view.objective.summary="护住商旅，击退两头荒原狼；同伴气竭可从战前重试。"
 return view
