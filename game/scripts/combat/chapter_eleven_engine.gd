class_name ChapterElevenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
const Same=preload("res://scripts/campaign/encounter_session.gd")
const HERO="char_liang_xiao"
const X="char_hua_xiaoshuang"
const ID="enc_ch11_laoshan_rescue"
const CHANG="changning"
const HE="hetuoluo"
const INNER_ACTIONS=["LX_A04","HXS_A04","HXS_A07","CO_02"]
const BAD=["poison","bleed","cold","stun","sleep","freeze","sealed","attack_down","speed_down"]
const H_SKILLS=["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03","LX_A04"]
const X_SKILLS=["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A03","HXS_A04","HXS_A07"]
var entry_error=""
var combo_executing=false
static func enemy(id:String,hp:int,atk:int,defense:int,speed:int,mp:int,boss:bool)->Dictionary:
 return {"id":id,"name":{CHANG:"常宁",HE:"贺陀罗","guard_east":"东侧禁卫","guard_west":"西侧禁卫"}[id],"team":"enemy","max_hp":hp,"max_mp":mp,"atk":atk,"def":defense,"spd":speed,"boss":boss,"tags":["heavy_armor"] if id in ["guard_east","guard_west"] else [],"protection_rounds":1,"rotation":[{"name":"审势","hits":[],"tags":[],"target_id":HERO}]}
static func encounter_config()->Dictionary:
 return {"id":ID,"kind":"b07","name":"崂山营救","level":50,"xp":0,"battle_id":"B07","result":"ch11_rescue_won","enemies":[enemy(CHANG,2800,175,110,36,180,true),enemy("guard_east",1200,175,110,36,180,false),enemy("guard_west",1200,175,110,36,180,false)]}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 for row in [["LX_A03","飞星九宫剑",8,"enemy"],["LX_A04","滴水穿石劲",12,"enemy"],["HXS_A01","望诊切脉",16,"enemy"],["HXS_A02","捻针推宫",8,"friend"],["HXS_A03","杏林悬壶",0,"self"],["HXS_A04","神仙倒·迷香",10,"enemy"],["HXS_A07","龙须取气",12,"enemy"]]:
  content.skills[row[0]]={"name":row[1],"source_id":row[0],"kind":"skill","speed":row[2],"target":row[3],"martial":row[0].begins_with("LX")}
 content.skills.LX_A03.merge({"hits":[.6,.6,.6],"break_tag":"interrupt"})
 content.skills.controlled_wait={"name":"受控等待","kind":"wait","target":"self","hits":[],"speed":0}
 content.skills.CO_02={"name":"九宫推宫·两仪天行息","kind":"combo","target":"enemy","speed":10,"mp_floor":0}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config()
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),11,11) or not ctx.get("current_token") is String or ctx.current_token.is_empty() or ctx.get("combo_unlocked")!=true:entry_error="invalid_context"
 if party.size()!=2:entry_error="two_heroes_required"
 var ids:Array=[]
 for v in party:
  if not v is Dictionary:entry_error="invalid_actor";continue
  if v.get("id") not in [HERO,X] or v.get("id") in ids or v.get("team")!="party":entry_error="invalid_actor"
  ids.append(v.get("id"))
  for k in ["hp","mp","max_hp","max_mp","atk","def","spd","fixed_level"]:
   if not _whole(v.get(k),1 if k in ["hp","max_hp","fixed_level"] else 0):entry_error="invalid_actor_number"
  if not v.get("skills") is Array or not v.get("skill_ranks") is Dictionary or not v.get("passives") is Array or not v.get("learned_passives") is Array:entry_error="invalid_actor_metadata";continue
  if entry_error!="":continue
  if v.hp>v.max_hp or v.mp>v.max_mp or v.fixed_level>80:entry_error="invalid_actor_resources"
  var allowed:Array=H_SKILLS if v.id==HERO else X_SKILLS
  var seen:Array=[]
  var active_count:=0
  for skill in v.skills:
   if not skill is String or skill not in allowed or skill in seen:entry_error="invalid_skill"
   seen.append(skill)
   var source:String={"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill)
   if source not in ["normal_attack","self_guard","guard_ally"]:
    active_count+=1
    if not v.skill_ranks.has(source):entry_error="unlearned_skill"
  if active_count>4 or (v.id==X and active_count!=4):entry_error="active_slot_limit"
  if v.has("equipped_active_skills"):
   var actual:Array=[]
   for skill in v.skills:
    if skill not in ["normal_attack","self_guard","guard_ally"]:actual.append({"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill))
   if not v.equipped_active_skills is Array or not Same.equivalent(actual,v.equipped_active_skills):entry_error="loadout_mismatch"
  for rank in v.skill_ranks.values():
   if not _whole(rank,1,3):entry_error="invalid_rank"
  seen=[]
  for passive in v.passives:
   if passive not in v.learned_passives or passive in seen or passive not in (["LX_P01","LX_P02","LX_P03"] if v.id==HERO else ["HXS_P01"]):entry_error="invalid_passive"
   seen.append(passive)
  if seen.size()>2:entry_error="too_many_passives"
  if v.id==X and (v.get("internal_skill") not in ["HXS_N01","HXS_N02"] or v.get("internal_stats_applied")!=true or v.get("panel_internal_skill")!=v.get("internal_skill")):entry_error="invalid_internal_panel"
  if v.id==HERO and v.get("internal_skill","") not in ["","LX_N01"]:entry_error="invalid_internal_skill"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 var clean:Array=party.duplicate(true)
 for a in clean:
  a.skills.append("CO_02")
  if a.id==HERO:
   a.skill_ranks.observe=a.skill_ranks.get("LX_A01",1)
   if a.get("internal_skill","")=="LX_N01":a.atk=int(floor(a.atk*1.08));a.spd+=5
   content.skills.LX_A03.hits=[.6,.6,.6] if int(a.skill_ranks.get("LX_A03",1))>=2 else [.55,.55,.55]
 super.start(config,clean)
 checkpoint=snapshot()
func _o()->Dictionary:return state.objective
func _rank(a:Dictionary,id:String)->int:return int(a.get("skill_ranks",{}).get(id,1))
func _controlled(a:Dictionary)->bool:
 if a.is_empty():return false
 for kind in ["stun","sleep","freeze","sealed"]:
  if _status_value(a,kind)>0:return true
 return false
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective={"phase":1,"phase_start":1,"synergy":0,"reserved":0,"synergy_round":0,"combo_round":0,"combo_refunded":false,"failure":"","postheal":false,"phase_two_pending":false,"p03_stacks":0,"p03_events":[],"phase_history":[]}
 # Shared begin resets counters and expires statuses; ticks below precede the
 # published replacement intentions, with no retroactive regeneration on cast.
 super.begin_round()
 for a in state.actors:
  a.passive_healed=0;a.mark_heal_round=0
  for e in a.statuses.duplicate(true):
   if e.kind=="poison" and int(e.starts)<=state.round and alive(a):
    if a.get("internal_skill","")=="HXS_N02":continue
    var loss:=super._lose_hp(actor_by_id(e.source),a,int(e.value));_event("poison_tick",e.source,a.id,loss)
  if not alive(a):continue
  if _status_value(a,"regeneration")>0:_heal(a,a,int(floor(float(a.max_hp)*.02)),true,"regeneration")
  if _status_value(a,"regeneration_mana")>0:gain_mana(a,2,"regeneration")
  if a.get("internal_skill","")=="LX_N01":gain_mana(a,3,"mirror_breath")
 _check_outcome()
 if state.outcome!="":state.mode="finished";state.intents=[];return
 state.intents=[]
 if int(_o().phase)==1:
  var cycle:int=(int(state.round)-1)%3
  if alive(actor_by_id(CHANG)):
   if cycle==0:_intent(CHANG,"poison_charge","毒烟蓄势：下轮施毒；望诊后滴水可破药囊",[],["sever","needle"],HERO)
   elif cycle==1:_intent(CHANG,"poison","五行毒烟：每次157毒伤，后续三轮轮初；可净化",[],["sever","needle"],HERO)
   else:_intent(CHANG,"strike","毒医掌击：0.80倍攻击",[.8],[],HERO)
  for id in ["guard_east","guard_west"]:
   if not alive(actor_by_id(id)):continue
   var guard:bool=(int(state.round)+(0 if id=="guard_east" else 1))%2==0
   if guard:_apply_status(actor_by_id(id),"damage_reduction",.35,1)
   _intent(id,"guard" if guard else "strike","禁卫自守：本轮35%护体" if guard else "禁卫进击：0.80倍攻击锁定"+("梁萧" if id=="guard_east" else "晓霜"),[] if guard else [.8],[],HERO if id=="guard_east" else X)
 else:
  var cycle:int=(int(state.round)-int(_o().phase_start))%4
  var boss:=actor_by_id(HE)
  boss.shell=cycle in [0,1] and int(boss.get("shell_broken_until",-1))<int(state.round)
  if cycle==0:_intent(HE,"shell","逆血罡罩蓄势：正面物伤免疫且反震8气/动作；龙须可破，望诊后滴水可揭罩",[],["sever"],X)
  elif cycle==1:_intent(HE,"pounce","罡罩·恶僧扑杀：锁定晓霜1.95倍；可援护/三才诱偏；龙须破罩后改0.60倍",[1.95],["sever","induce"],X)
  elif cycle==2:_intent(HE,"poison","洞内毒雾：每次193毒伤，后续三轮轮初；晓霜N02免持续毒",[],["sever","needle"],HERO)
  else:_intent(HE,"pounce","恶僧扑杀：锁定梁萧1.95倍；可诱偏/援护",[1.95],["induce"],HERO)
func _intent(id:String,kind:String,label:String,hits:Array,tags:Array,target:String)->void:
 state.intents.append({"actor_id":id,"intent_id":"%s:%d"%[id,state.round],"kind":kind,"name":label,"hits":hits,"tags":tags,"target_id":target,"executed":false,"cancelled":false})
 if kind=="poison" and actor_by_id(id).get("poison_cancel_round",-1)==state.round:state.intents[-1].cancelled=true
func _eligible()->bool:
 for id in [HERO,X]:
  var a:=actor_by_id(id)
  if not alive(a) or _controlled(a):return false
 return true
func validate_command(id:String,skill:String,target:String)->String:
 if skill=="CO_02":
  if state.mode!="commands" or id not in [HERO,X] or not _eligible():return "combo_unavailable"
  if int(_o().synergy)+int(_o().reserved)<2:return "insufficient_synergy"
  var t:=actor_by_id(target)
  return "" if alive(t) and t.team=="enemy" else "invalid_target"
 if _controlled(actor_by_id(id)):return "actor_controlled"
 var err:=super.validate_command(id,skill,target)
 if err!="":return err
 if content.skills[skill].target=="friend" and actor_by_id(target).team!="party":return "invalid_target"
 return ""
func set_command(id:Variant,skill:Variant,target:Variant,revision:Variant=-1)->String:
 if not id is String or not skill is String or not target is String or not revision is int:return "invalid_command_type"
 if revision !=-1 and revision!=state.revision:return "stale_revision"
 var error:=validate_command(id,skill,target)
 if error!="":return error
 if skill=="CO_02":
  if int(_o().reserved)==0:_o().synergy-=2;_o().reserved=2
  _o().combo_refunded=false
  for who in [HERO,X]:state.commands[who]={"actor_id":who,"skill_id":skill,"target_id":target}
  state.revision+=1;return ""
 if int(_o().reserved)>0:
  _refund(false);state.commands.clear()
 return super.set_command(id,skill,target,revision)
func apply_input(a:Variant)->Dictionary:
 if not a is Dictionary or a.size()!=2 or not a.has_all(["action_id","revision"]) or not a.action_id is String or not a.revision is int:return {"accepted":false,"error":"invalid_input"}
 if state.mode!="commands" or a.revision!=state.revision:return {"accepted":false,"error":"stale_input"}
 if a.action_id!="cancel":return {"accepted":false,"error":"invalid_action"}
 _refund(false);state.commands.clear();state.revision+=1;return {"accepted":true}
func can_resolve()->bool:
 if state.mode!="commands":return false
 for a in state.actors:
  if a.team=="party" and alive(a) and not _controlled(a) and not state.commands.has(a.id):return false
 return true
func resolve_round()->bool:
 if not can_resolve():return false
 for a in state.actors:
  if a.team=="party" and alive(a) and _controlled(a) and not state.commands.has(a.id):state.commands[a.id]={"actor_id":a.id,"skill_id":"controlled_wait","target_id":a.id}
 return super.resolve_round()
func _refund(fallback:bool)->void:
 if int(_o().reserved)==0 or _o().combo_refunded:return
 _o().synergy+=_o().reserved;_o().reserved=0;_o().combo_refunded=true;_event("combo_refund","","",2)
 if fallback:
  for id in [HERO,X]:
   var a:=actor_by_id(id)
   if alive(a) and not _controlled(a):a.stance={"kind":"self_guard","target_id":id,"tokens":1,"skill_id":"self_guard"}
func _gain_synergy(reason:String)->void:
 if combo_executing or _o().synergy_round==state.round or int(_o().synergy)+int(_o().reserved)>=3:return
 _o().synergy+=1;_o().synergy_round=state.round;_event("synergy","","",1,{"reason":reason})
func gain_mana(a:Dictionary,amount:int,reason:String)->void:
 super.gain_mana(a,amount,reason)
 if reason=="successful_guard":_gain_synergy("guard")
func _speed(a:Dictionary,modifier:int,skill:Dictionary={})->int:
 if skill.get("kind")=="combo":return mini(super._speed(actor_by_id(HERO),0),super._speed(actor_by_id(X),0))+10
 return super._speed(a,modifier,skill)+(10 if a.get("jiugong_speed_round",-1)==state.round else 0)
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 if not super._break(a,t,i):return false
 _gain_synergy("break")
 if a.id==HERO and "LX_P03" in a.get("passives",[]) and "interrupt" in i.tags and i.intent_id not in _o().p03_events:
  _o().p03_events.append(i.intent_id);_o().p03_stacks=mini(3,int(_o().p03_stacks)+1)
 return true
func _normal_target(command:Dictionary)->Dictionary:return _legal_target(str(command.target_id),"enemy")
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 var id:String=cmd.skill_id
 if id=="CO_02":
  if int(_o().reserved)>0:_combo()
  return
 if _controlled(a):_event("controlled_skip",a.id);return
 if id in ["HXS_A01","HXS_A02","HXS_A03","HXS_A04","HXS_A07","LX_A04"]:
  var target:Dictionary=actor_by_id(cmd.target_id) if id in ["HXS_A02","HXS_A03"] else _normal_target(cmd)
  if id=="HXS_A02" and not alive(target):target=_lowest()
  if not alive(target):return
  var skill:Dictionary=content.skills[id];_pay(a,id,skill);_event("action",a.id,target.id,0,{"skill_id":id})
  match id:
   "HXS_A01":
    _apply_status(target,"diagnosed",.15,3 if _rank(a,id)>=3 else 2)
    if _rank(a,id)>=2:target.diagnose_bonus=true
    gain_mana(a,4,"diagnose");_event("diagnosed",a.id,target.id)
   "HXS_A02":
    _heal(a,target,_fixed_heal(a,.7,6),false,id)
    var removed:=_cleanse(target,2 if _rank(a,id)>=2 else 1)
    if removed>0 and _rank(a,id)>=2:gain_mana(a,4,"cleanse")
    if _rank(a,id)>=3:_apply_status(target,"damage_reduction",.15,2)
   "HXS_A03":
    for t in state.actors:
     if t.team!="party" or not alive(t):continue
     var amount:float=_fixed_heal(a,.55 if _rank(a,id)>=3 else .45,5 if _rank(a,id)>=3 else 4)
     if _rank(a,id)>=3 and t.hp*10<t.max_hp*3:amount*=1.5
     _heal(a,t,amount,false,id);_apply_status(t,"regeneration",.02,3)
     if _rank(a,id)>=2:_apply_status(t,"regeneration_mana",2,3)
   "HXS_A04":
    _attack(a,target,.4,id,0.0)
    if target.get("boss",false):_apply_status(target,"attack_down",.4 if _rank(a,id)>=2 else .3,2)
    elif not _protected(target):_apply_status(target,"sleep",1,1)
    _try_break(a,target,["needle"],false)
   "HXS_A07":
    _attack(a,target,1.15,id,1.0)
    if target.get("boss",false):
     var broken:=_try_break(a,target,["sever"],true)
     if not broken and _protected(target):_apply_status(target,"attack_down",.3,2)
    else:target.mp=maxi(0,int(target.mp)-(25 if _rank(a,id)>=2 else 15));_try_break(a,target,["sever"],true)
   "LX_A04":
    _attack(a,target,1.55,id,.25)
    _apply_status(target,"attack_down",.15,2)
    if _status_value(target,"diagnosed")>0:_try_break(a,target,["sever"],false)
  return
 var marked:bool=_status_value(a,"mingxin")>0
 a.observe_strike=marked and a.get("observe_bonus",false) and id in ["normal_attack","LX_A03"]
 var breaks:int=state.break_count
 super._execute_command(a,cmd)
 if id=="observe" and _rank(a,"LX_A01")>=3:
  if not a.get("observe_bonus_granted",false):a.observe_bonus=true;a.observe_bonus_granted=true
  for e in _normal_target(cmd).get("statuses",[]):
   if e.kind=="posuan":e.expires=int(state.round)+2
 elif marked and _status_value(a,"mingxin")==0:a.observe_bonus=false
 a.observe_strike=false
 if id=="LX_A03":
  a.jiugong_round=state.round;a.jiugong_speed_round=int(state.round)+1
  if state.break_count>breaks and _rank(a,id)>=3:gain_mana(a,4,"jiugong_break");a.ready[id]=maxi(int(state.round)+1,int(a.ready[id])-1)
func _try_break(a:Dictionary,t:Dictionary,tags:Array,low_threat:bool)->bool:
 for i in state.intents:
  if i.actor_id!=t.id or i.executed or i.cancelled:continue
  var matches:=false
  for tag in tags:
   if tag in i.tags:matches=true
  if not matches or not _break(a,t,i):continue
  if i.kind=="poison_charge":t.poison_cancel_round=int(state.round)+1
  if i.kind in ["shell","pounce"] and t.get("shell",false):
   t.shell=false;t.shell_open_round=state.round;t.shell_broken_until=int(state.round)+1
   # A second hit can exploit the opening without claiming a second protected break.
   i.tags.append("interrupt")
  if low_threat:i.hits=[.6];i.kind="strike";i.tags=[];i.name="透穴后低威胁掌：0.60倍攻击"
  else:i.cancelled=true
  _event("countered",a.id,t.id,0,{"low_threat":low_threat});return true
 return false
func _attack(a:Dictionary,t:Dictionary,multiplier:float,id:String,ignore:float)->void:
 var defense:Variant=t.def;t.def=float(t.def)*(1.0-ignore)
 var had:=_status_value(a,"mingxin")>0
 if a.id==HERO and had:multiplier*=1.5;a.statuses=a.statuses.filter(func(e):return e.kind!="mingxin")
 _damage_action(a,t,multiplier,false,"normal",id)
 t.def=defense
func _fixed_heal(a:Dictionary,scale:float,constant:float)->float:return float(a.atk)*scale+constant*(1.0+39.0*(float(a.fixed_level)-1.0)/79.0)
func _lowest()->Dictionary:
 var best:Dictionary={}
 for a in state.actors:
  if a.team=="party" and alive(a) and (best.is_empty() or int(a.hp)<int(best.hp)):best=a
 return best
func _heal(source:Dictionary,target:Dictionary,base:float,passive:bool,reason:String)->void:
 if not alive(target):return
 var amount:int=int(floor(base))
 if passive:amount=mini(amount,maxi(0,int(floor(target.max_hp*.03))-int(target.get("passive_healed",0))))
 else:
  var bonus:float=(.15 if source.get("internal_skill","")=="HXS_N01" else 0.0)+(.15 if target.get("internal_skill","")=="HXS_N01" else 0.0)
  amount=int(floor(base*(1.0+minf(.4,bonus))))
 amount=mini(amount,int(target.max_hp)-int(target.hp));target.hp+=amount
 if passive:target.passive_healed=int(target.get("passive_healed",0))+amount
 _event("heal",source.id,target.id,amount,{"reason":reason,"passive":passive})
func _cleanse(t:Dictionary,count:int,kinds:Array=BAD)->int:
 var removed:=0
 for e in t.statuses.duplicate(true):
  if e.kind in kinds and int(e.expires)>=state.round and removed<count:t.statuses.erase(e);removed+=1;_event("cleanse",X,t.id,1,{"kind":e.kind})
 return removed
func _combo()->void:
 if not _eligible():_refund(true);return
 _o().reserved=0;_o().combo_round=state.round;combo_executing=true
 var h:=actor_by_id(HERO);var x:=actor_by_id(X)
 _event("combo_executed",HERO,X,2)
 for t in state.actors:
  if t.team!="enemy" or not alive(t):continue
  _damage_action(h,t,2.2,true,"combo","CO_02");_apply_status(t,"attack_down",.25,2)
  _try_break(h,t,["sever","needle"],false)
 for t in [h,x]:
  _heal(x,t,_fixed_heal(x,.55,5),false,"CO_02");_cleanse(t,1);gain_mana(t,8,"CO_02")
 combo_executing=false
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 if _controlled(a):i.executed=true;_event("controlled_skip",a.id);return
 if i.cancelled:i.executed=true;return
 if i.kind=="poison":
  i.executed=true
  for t in state.actors:
   if t.team!="party" or not alive(t):continue
   if t.get("internal_skill","")=="HXS_N02":_event("poison_immune",t.id);continue
   var value:int=int(floor(a.atk*.90));var previous:float=0.0
   for e in t.statuses:
    if e.kind=="poison" and int(e.expires)>=state.round:previous=maxf(previous,float(e.value))
   t.statuses=t.statuses.filter(func(e):return e.kind!="poison")
   t.statuses.append({"kind":"poison","source":a.id,"value":maxi(value,int(previous)),"starts":int(state.round)+1,"expires":int(state.round)+3})
   _event("poison_applied",a.id,t.id,value)
  return
 super._execute_intent(a,i)
func _counter(a:Dictionary,t:Dictionary,induced:bool)->void:
 var before:int=a.counter_count;super._counter(a,t,induced)
 if a.counter_count==before:return
 if induced and _rank(a,"LX_A02")>=2:_heal(a,a,int(floor(a.max_hp*.02)),true,"sancai")
 if _rank(a,"LX_A02")>=3:_apply_status(t,"attack_down",.15,2)
func _damage_action(a:Dictionary,t:Dictionary,m:float,aoe:bool,channel:String,id:String,guard:Dictionary={})->void:
 if not alive(t):return
 if t.get("shell",false) and a.team=="party" and id not in INNER_ACTIONS:
  if a.get("shell_drain_round",-1)!=state.round or a.get("shell_drain_action","")!=id:
   var spent:=mini(8,int(a.mp));a.mp-=spent;a.shell_drain_round=state.round;a.shell_drain_action=id;_event("shell_mana_drain",t.id,a.id,spent)
  _event("shell_immune",t.id,a.id);return
 var original_statuses:Array=a.statuses.duplicate(true)
 if a.id==HERO and float(_o().p03_stacks)*.05>_status_value(a,"attack_up"):_apply_status(a,"attack_up",float(_o().p03_stacks)*.05,1)
 if a.get("observe_strike",false):m*=1.1
 if a.id==HERO and "LX_P03" in a.get("passives",[]) and "heavy_armor" in t.get("tags",[]):m*=1.25
 var marked:=_status_value(t,"diagnosed")>0
 if marked:
  var broken:float=1.0+(minf(.2+_status_value(t,"posuan"),.5) if int(t.vulnerable_through)>=state.round else 0.0)
  m*=minf(1.5,broken*1.15)/broken
 if t.get("diagnose_bonus",false) and a.team=="party":m*=1.1;t.diagnose_bonus=false
 var old_hp:int=t.hp
 super._damage_action(a,t,m,aoe,channel,id,guard);a.statuses=original_statuses
 if channel=="normal" and marked and t.hp<old_hp and t.get("mark_heal_round",0)!=state.round and _rank(actor_by_id(X),"HXS_A01")>=3:
  t.mark_heal_round=state.round;var low:=_lowest()
  if not low.is_empty():_heal(actor_by_id(X),low,int(floor(actor_by_id(X).atk*.1)),true,"diagnosis")
 if t.hp<old_hp:t.statuses=t.statuses.filter(func(e):return e.kind!="sleep")
func _branch(a:Dictionary,t:Dictionary,raw:float,channel:String,id:String)->int:
 var defense:Variant=t.def;var reduction:float=t.get("reduction",0.0)
 if t.id==HERO:
  t.def=int(floor(float(t.def)*(1.0+float(_o().p03_stacks)*.05)))
  if t.get("jiugong_round",-1)==state.round:t.reduction=maxf(.2,reduction)
 var loss:=super._branch(a,t,raw,channel,id)
 t.def=defense;t.reduction=reduction
 if raw>0 and t.id==HERO:t.jiugong_round=-1
 return loss
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if a.get("id")==X and t.team=="enemy" and "HXS_P01" in a.get("passives",[]) and amount>=t.hp:
  var loss:=maxi(0,int(t.hp)-1);t.hp=1;t.defeated=true;_event("nonlethal_defeat",X,t.id);return loss
 return super._lose_hp(a,t,amount)
func _check_outcome()->void:
 if state.outcome!="" or not state.has("objective"):return
 if not alive(actor_by_id(HERO)) or not alive(actor_by_id(X)):
  _refund(true);state.outcome="defeat";_o().failure="rescuer_exhausted";return
 if state.mode!="round_end":return
 if actor_by_id(X).get("internal_skill","")=="HXS_N01" and int(state.round)%2==1:
  var low:=_lowest();gain_mana(low,4,"suwen");_cleanse(low,1,["bleed","poison","speed_down"])
 var enemy_alive:=false
 for a in state.actors:
  if a.team=="enemy" and alive(a):enemy_alive=true
 if enemy_alive:return
 if int(_o().phase)==1:
  _o().phase=2;_o().phase_start=int(state.round)+1;_o().phase_history.append({"round":state.round,"actors":state.actors.duplicate(true),"synergy":_o().synergy})
  var boss:=enemy(HE,3500,215,130,40,220,true)
  boss.merge({"hp":3500,"mp":220,"ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":false})
  state.actors.append(boss);_event("phase_changed",HE,"",2)
 else:
  state.outcome="victory"
  if not _o().postheal and "HXS_P01" in actor_by_id(X).passives:
   _o().postheal=true
   for a in [actor_by_id(HERO),actor_by_id(X)]:
    var amount:=mini(int(a.max_hp)-int(a.hp),int(floor(a.max_hp*.2)));a.hp+=amount;_event("postbattle_heal",X,a.id,amount)
func get_view()->Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={};v.legal_commands={}
 for a in state.actors:
  if a.team!="party":continue
  v.skill_costs[a.id]={};v.legal_commands[a.id]=[]
  for skill in a.skills:
   v.skill_costs[a.id][skill]=skill_cost(a,content.skills[skill])
   for t in state.actors:
    if validate_command(a.id,skill,t.id)=="":v.legal_commands[a.id].append({"skill_id":skill,"target_id":t.id})
 v.objective.summary="两人存活击退敌阵；阶段%d；协力%d/3（预留%d）。望诊不直接破招；保护期不取消行动。"%[int(_o().phase),int(_o().synergy),int(_o().reserved)]
 v.objective.available_actions=[]
 v.objective.forecast=[]
 for a in state.actors:
  if a.team=="enemy" and alive(a) and _status_value(a,"diagnosed")>0:
   var next:String="禁卫交替攻守"
   if a.id==CHANG:next=["毒烟蓄势","五行毒烟","毒医掌击"][int(state.round)%3]
   elif a.id==HE:next=["逆血罡罩蓄势","罡罩扑杀锁定晓霜","洞内毒雾","扑杀锁定梁萧"][(int(state.round)+1-int(_o().phase_start))%4]
   v.objective.forecast.append(a.name+"下轮："+next)
 v.world_state={"map_id":state.encounter.context.get("map_id","map_ch11_rescue_cave"),"objective_id":ID,"control_actor_id":HERO,"player_position":[112,136],"actor_positions":{HERO:[112,136],X:[96,136]},"visible_actor_ids":[HERO,X],"battle_phase":_o().phase,"complete":state.outcome=="victory"}
 return v
