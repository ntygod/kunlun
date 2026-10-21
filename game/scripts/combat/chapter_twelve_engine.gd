class_name ChapterTwelveCombatEngine
extends "res://scripts/combat/chapter_eleven_engine.gd"
const HS="char_huasheng"
const LIU="char_liu_yingying"
const IDS=["enc_ch12_han_duel","enc_ch12_lei_duel","enc_ch12_chu_duel","enc_ch12_chiyou_medicine"]
const HERBS=["ch12_herb_qing","ch12_herb_bai","ch12_herb_chi"]
const POEMS=["ch12_poem_du","ch12_poem_hua","ch12_poem_qiu"]
static func foe(id:String,label:String,hp:int,mp:int,atk:int,defense:int,speed:int,boss:bool=true)->Dictionary:
 return {"id":id,"name":label,"team":"enemy","max_hp":hp,"max_mp":mp,"atk":atk,"def":defense,"spd":speed,"boss":boss,"protection_rounds":1,"rotation":[{"name":"候招","hits":[],"tags":[],"target_id":X}]}
static func encounter_config(id:String=IDS[0])->Dictionary:
 var index:int=IDS.find(id)
 if index<0:return {}
 var foes:Array=[]
 match index:
  0:foes=[foe("han_ningzi","韩凝紫",2200,0,165,100,42)]
  1:foes=[foe("lei_xingkong","雷行空·雷鼓",3200,0,220,160,30)]
  2:foes=[foe("chu_xianliu","楚仙流",3800,0,255,145,48)]
  3:foes=[foe("luo_mingqi","骆明绮·赤炼毒师",3600,200,210,125,44),foe("puppet_east","东药偶",1500,200,210,125,44,false),foe("puppet_west","西药偶",1500,200,210,125,44,false)]
 return {"id":id,"kind":["han","lei","chu","medicine"][index],"name":["医理问心","雷鼓角力","诗剑会友","蚩尤辨药"][index],"level":58 if index==3 else 54,"xp":0,"battle_id":"B09" if index==3 else "B08","result":["ch12_han_won","ch12_lei_draw","ch12_chu_draw","ch12_poison_resolved"][index],"nonlethal":true,"enemies":foes}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 for row in [["HXS_A05","金针渡穴·生生不息",18,"friend"],["HXS_A06","暗香疏影拳",4,"enemy"],["HS_A01","金刚护持",0,"self"],["HS_A02","金刚破器掌",-2,"enemy"],["HS_A03","巨力推山撼",-5,"enemy"],["LYY_A01","虚实步·惊鸿诱",22,"enemy"],["LYY_A02","梭罗散手·截脉",14,"enemy"],["LYY_A03","软索飞钩·绊马",10,"enemy"],["LYY_A04","冰河玄指",8,"enemy"],["LYY_A05","飞燕掠波",25,"friend"]]:
  content.skills[row[0]]={"name":row[1],"source_id":row[0],"kind":"skill","speed":row[2],"target":row[3]}
 content.skills.HS_A01.merge({"prepare":true,"kind":"self_guard"})
 content.skills.LYY_A01.merge({"prepare":true,"kind":"feint"})
 for n in range(3):
  content.skills[HERBS[n]]={"name":["投青叶·清风","投白花·澄露","投赤萼·暖阳"][n],"kind":"herb","target":"enemy","speed":20}
  content.skills[POEMS[n]]={"name":["落花独立·守中","名花倾国·化繁","求之不得·退让"][n],"kind":"poem","target":"enemy","speed":20}
 content.skills.CO_01={"name":"纯阳飞燕·九宫连环引","kind":"combo","target":"enemy","speed":15}
 content.skills.ch12_wait={"name":"调息等待","kind":"wait","target":"self","speed":0}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config(str(config.get("id","")))
 if canonical.is_empty():entry_error="invalid_encounter"
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),12,12) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
 var ids:Array=[]
 var expected:Array={"han":[X],"lei":[HS],"chu":[HERO],"medicine":[HERO,X,LIU]}.get(str(config.get("kind","")),[])
 for v in party:
  if not v is Dictionary:entry_error="invalid_actor";continue
  if v.get("id") not in expected or v.get("id") in ids or v.get("team")!="party" or v.get("status","") in ["dead","permanently_departed"]:entry_error="invalid_actor"
  ids.append(v.get("id"))
  for key in ["hp","mp","max_hp","max_mp","atk","def","spd","fixed_level"]:
   if not _whole(v.get(key),1 if key in ["hp","max_hp","fixed_level"] else 0):entry_error="invalid_actor_number"
  if not v.get("skills") is Array or not v.get("skill_ranks") is Dictionary or not v.get("passives") is Array or not v.get("learned_passives") is Array:entry_error="invalid_metadata";continue
  if entry_error!="":continue
  if v.hp>v.max_hp or v.mp>v.max_mp or v.fixed_level>80:entry_error="invalid_resources"
  var active:Array=[];var seen:Array=[]
  var prefix:String={HERO:"LX_",X:"HXS_",HS:"HS_",LIU:"LYY_"}.get(v.id,"")
  for skill in v.skills:
   if not skill is String or skill in seen or not content.skills.has(skill):entry_error="invalid_skill";continue
   seen.append(skill)
   if skill in ["normal_attack","self_guard","guard_ally"]:continue
   var source:String={"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill)
   if not source.begins_with(prefix+"A") or not v.skill_ranks.has(source):entry_error="unlearned_skill"
   active.append(source)
  if active.size()>4:entry_error="active_slot_limit"
  if v.has("equipped_active_skills") and not Same.equivalent(active,v.equipped_active_skills):entry_error="loadout_mismatch"
  for rank in v.skill_ranks.values():
   if not _whole(rank,1,3):entry_error="invalid_rank"
  seen=[]
  for passive in v.passives:
   if not passive is String or passive not in {HERO:["LX_P01","LX_P02","LX_P03"],X:["HXS_P01","HXS_P03"],HS:["HS_P01","HS_P02"],LIU:["LYY_P01","LYY_P02"]}.get(v.id,[]) or passive not in v.learned_passives or passive in seen:entry_error="invalid_passive"
   seen.append(passive)
  if seen.size()>2:entry_error="passive_slot_limit"
  if v.get("internal_skill","") not in {HERO:["","LX_N01"],X:["HXS_N01","HXS_N02"],HS:["HS_N01"],LIU:["","LYY_N01"]}.get(v.id,[]):entry_error="invalid_internal"
  if v.id in [X,HS] and (v.get("internal_stats_applied")!=true or v.get("panel_internal_skill")!=v.get("internal_skill")):entry_error="invalid_internal_panel"
 if ids.size()!=expected.size():entry_error="wrong_party"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 state={"version":SNAPSHOT_VERSION,"rules_version":rules.version,"content_version":content.version,"encounter":config.duplicate(true),"round":1,"mode":"new","revision":0,"actors":[],"commands":{},"intents":[],"events":[],"event_sequence":0,"break_count":0,"outcome":"","k":float(rules.defense.k_base)+float(rules.defense.k_per_power_level)*(float(config.level)-1)*39/79}
 state.objective={"phase":1,"phase_start":1,"synergy":0,"reserved":0,"synergy_round":0,"combo_round":0,"combo_refunded":false,"failure":"","postheal":false,"p03_stacks":0,"p03_events":[],"guard_seen":false,"disarm_seen":false,"push_seen":false,"poems":[],"dismantled":false,"herbs":[],"unlock_round":0,"herb_deadline":0,"suppressed_round":0}
 for source in party+config.enemies:
  var a:Dictionary=source.duplicate(true)
  _normalize(a)
  if a.team=="party":
   a.skills.append("ch12_wait")
   if a.id==HERO:
    a.skill_ranks.observe=a.skill_ranks.get("LX_A01",1)
    if a.get("internal_skill","")=="LX_N01":a.atk=int(floor(a.atk*1.08));a.spd+=5
    content.skills.LX_A03.hits=[.6,.6,.6] if _rank(a,"LX_A03")>=2 else [.55,.55,.55]
   if a.id==LIU and a.get("internal_skill","")=="LYY_N01":a.spd=int(floor(a.spd*1.1));a.internal_guard=true
   if config.kind=="medicine":
    if a.id in [X,HERO] and ("CO_02" in ctx.get("combo_unlocks",[]) or ctx.get("combo_unlocked",false)):a.skills.append("CO_02")
    if a.id in [LIU,HERO] and "CO_01" in ctx.get("combo_unlocks",[]):a.skills.append("CO_01")
   if config.kind=="medicine" and a.id==X:a.skills.append_array(HERBS)
   if config.kind=="chu":a.skills.append_array(POEMS)
  state.actors.append(a)
 begin_round();checkpoint=snapshot()
func _normalize(a:Dictionary)->void:
 a.merge({"hp":int(a.get("hp",a.max_hp)),"mp":int(a.max_mp),"ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":false},true)
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 state.commands={};state.intents=[];state.mode="round_start"
 for a in state.actors:
  a.mana_gained=0;a.counter_count=0;a.guard_rewarded=false;a.break_rewarded=false;a.stance={};a.passive_healed=0
  a.statuses=a.statuses.filter(func(e):return int(e.expires)>=int(state.round))
 for a in state.actors:
  for e in a.statuses.duplicate(true):
   if e.kind in ["poison","cold","pain"] and int(e.starts)<=state.round and alive(a):
    if a.get("internal_skill","")=="HXS_N02" and e.kind in ["poison","cold"]:continue
    _event("dot",e.source,a.id,_lose_hp(actor_by_id(e.source),a,int(e.value)))
  if not alive(a):continue
  if state.encounter.kind=="medicine" and a.id==HERO:_event("scenario_poison",X,a.id,_lose_hp(actor_by_id("luo_mingqi"),a,int(floor(a.max_hp*.03))))
  if not alive(a):continue
  if _status_value(a,"regeneration")>0:_heal(a,a,a.max_hp*.02,true,"regeneration")
  if _status_value(a,"regeneration_mana")>0:gain_mana(a,2,"regeneration")
  if a.get("internal_skill","")=="LX_N01":gain_mana(a,3,"mirror_breath")
  if "LX_P01" in a.get("passives",[]) and not a.passive_started:
   a.passive_started=true;var t:=_highest_threat()
   if not t.is_empty():_apply_status(t,"posuan",.1,2)
 _check_outcome()
 if state.outcome!="":state.mode="finished";return
 state.mode="commands";state.revision+=1
 var cycle:int=(int(state.round)-1)%3
 match state.encounter.kind:
  "han":
   if cycle==0:_intent("han_ningzi","cold","阴寒探脉：普通寒毒；N02免持续寒伤",[],["needle"],X)
   elif cycle==1:_intent("han_ningzi","strike","冰刺进击：0.90倍，转阴易阳可诱偏",[.9],["induce"],X)
   else:_intent("han_ningzi","guard","收针审势：本轮不攻",[],[],X)
  "lei":
   if cycle==0:_intent("lei_xingkong","strike","鼓槌重击：1.40倍；金刚护持实际承接",[1.4],[],HS)
   elif cycle==1:_intent("lei_xingkong","strike","鼓架横击：1.20倍；后手架鼓，破器匹配卸械",[1.2],["disarm"],HS);state.intents[-1].speed=-20
   else:_intent("lei_xingkong","strike","雷鼓蓄力：1.80倍；推山匹配打断（后手蓄势）",[1.8],["interrupt"],HS);state.intents[-1].speed=-35
  "chu":
   var n:int=mini(2,_o().poems.size())
   _intent("chu_xianliu","strike",["落花独立：守中回应；剑路可诱偏","名花倾国：化繁回应；剑路可打断","求之不得：退让回应；剑路可诱偏"][n],[.8],["induce","interrupt"],HERO)
  "medicine":
   for id in ["luo_mingqi","puppet_east","puppet_west"]:
    if not alive(actor_by_id(id)):continue
    if id=="luo_mingqi":
     if cycle==0:_intent(id,"catalyze","催毒锁梁：600真伤；晓霜单疗/复苏可压制本轮",[],[],HERO);state.intents[-1].speed=-20
     elif cycle==1:_intent(id,"poison","毒雾：0.90攻击持续三轮；N02免毒",[],["needle","sever"],HERO)
     else:_intent(id,"guard","调息操偶：本轮不攻",[],[],HERO)
    elif (int(state.round)+(0 if id=="puppet_east" else 1))%3==0:_intent(id,"strike","药偶扑袭：1.80倍锁晓霜，可诱偏/卸械",[1.8],["induce","disarm"],X)
    else:_intent(id,"guard","药偶调整丝线：本轮不攻",[],[],X)
   var pot:=actor_by_id("chiyou_cauldron")
   if alive(pot):
    if int(_o().unlock_round)==0 or int(state.round)<int(_o().unlock_round):_intent(pot.id,"guard","鼎封锁：先令毒师与药偶失战；不可攻击或投药",[],[],X)
    else:_intent(pot.id,"strike","毒鼎余波：0.60倍锁晓霜；辨药后仍须正常击破4200血",[.6],[],X)
 _check_friend_rage();_event("round_started")
func validate_command(id:String,skill:String,target:String)->String:
 if skill in ["CO_01","CO_02"]:
  var members:Array=[HERO,LIU] if skill=="CO_01" else [HERO,X]
  if state.mode!="commands" or id not in members or int(_o().synergy)+int(_o().reserved)<2:return "combo_unavailable"
  for who in members:
   var a:=actor_by_id(who)
   if not alive(a) or _controlled(a) or a.get("revived_round",-1)==state.round or skill not in a.get("skills",[]):return "combo_unavailable"
  var t:=actor_by_id(target)
  if t.get("id")=="chiyou_cauldron" and (int(_o().unlock_round)==0 or state.round<int(_o().unlock_round)):return "cauldron_locked"
  return "" if alive(t) and t.team=="enemy" else "invalid_target"
 if skill in HERBS:
  if id!=X or state.encounter.kind!="medicine" or int(_o().unlock_round)==0 or state.round<int(_o().unlock_round) or _o().herbs.size()>=3:return "herbs_locked"
 if target=="chiyou_cauldron" and (int(_o().unlock_round)==0 or state.round<int(_o().unlock_round)):return "cauldron_locked"
 if skill=="HXS_A05":
  var a:=actor_by_id(id);var t:=actor_by_id(target)
  if state.mode!="commands" or not alive(a) or _controlled(a) or skill not in a.get("skills",[]):return "actor_unavailable"
  if t.is_empty() or t.team!="party":return "invalid_target"
  if t.get("revive_used",false) and not alive(t):return "revive_used"
  if alive(t) and t.get("deathsave_used",false):return "deathsave_used"
  if state.round<int(a.ready.get(skill,1)):return "cooldown"
  if a.mp<skill_cost(a,content.skills[skill]):return "insufficient_mp"
  return ""
 return super.validate_command(id,skill,target)
func set_command(id:Variant,skill:Variant,target:Variant,revision:Variant=-1)->String:
 if not id is String or not skill is String or not target is String or not revision is int:return "invalid_command_type"
 if revision!=-1 and revision!=state.revision:return "stale_revision"
 var error:=validate_command(id,skill,target)
 if error!="":return error
 if skill in ["CO_01","CO_02"]:
  if int(_o().reserved)>0:_refund(false)
  _o().combo_members=[HERO,LIU] if skill=="CO_01" else [HERO,X]
  _o().combo_skill=skill;_o().combo_target=target;_o().synergy-=2;_o().reserved=2;_o().combo_refunded=false
  for who in _o().combo_members:state.commands[who]={"actor_id":who,"skill_id":skill,"target_id":target}
 else:
  if int(_o().reserved)>0 and id in _o().get("combo_members",[]):_refund(false)
  state.commands[id]={"actor_id":id,"skill_id":skill,"target_id":target}
 state.revision+=1;return ""
func _refund(fallback:bool)->void:
 if int(_o().reserved)==0 or _o().combo_refunded:return
 _o().synergy+=_o().reserved;_o().reserved=0;_o().combo_refunded=true
 for id in _o().get("combo_members",[]):
  state.commands.erase(id)
  var a:=actor_by_id(id)
  if fallback and alive(a) and not _controlled(a):a.stance={"kind":"self_guard","target_id":id,"tokens":1,"skill_id":"self_guard"}
 _event("combo_refund","","",2)
func _eligible()->bool:
 for id in _o().get("combo_members",[HERO,X]):
  var a:=actor_by_id(id)
  if not alive(a) or _controlled(a) or a.get("revived_round",-1)==state.round:return false
 return true
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 var id:String=cmd.skill_id
 if id=="CO_01":
  if int(_o().reserved)>0:_combo()
  return
 if a.get("revived_round",-1)==state.round:return
 if _controlled(a):_event("controlled_skip",a.id);return
 if id=="ch12_wait":_event("wait",a.id);return
 if id in HERBS:
  _event("herb_poured",a.id,cmd.target_id,0,{"herb":id})
  if _o().herbs.size()<3 and id==HERBS[_o().herbs.size()]:_o().herbs.append(id)
  else:_event("wrong_herb",a.id)
  return
 if id in POEMS:
  if _o().poems.size()<3 and id==POEMS[_o().poems.size()]:_o().poems.append(id);_apply_status(a,"damage_reduction",.2,1)
  _event("poem_response",a.id,cmd.target_id,0,{"poem":id});return
 if id=="HXS_A05":
  var t:=actor_by_id(cmd.target_id);_pay(a,id,content.skills[id])
  if alive(t):_apply_status(t,"deathsave",1,2)
  elif not t.get("revive_used",false):t.hp=maxi(1,int(floor(t.max_hp*.3)));t.defeated=false;t.revive_used=true;t.revived_round=state.round;_event("revived",a.id,t.id,t.hp)
  if _rank(a,id)>=2:_apply_status(a,"damage_reduction",.35,1)
  if t.id==HERO:_o().suppressed_round=state.round
  return
 if id=="HXS_A02" and cmd.target_id==HERO:_o().suppressed_round=state.round
 if id in ["HXS_A06","HS_A02","HS_A03","LYY_A02","LYY_A03","LYY_A04","LYY_A05"]:
  var t:=actor_by_id(cmd.target_id)
  if not alive(t):return
  _pay(a,id,content.skills[id]);_event("action",a.id,t.id,0,{"skill_id":id})
  match id:
   "HXS_A06":_attack(a,t,.95,id,0);_apply_status(t,"attack_down",.2,2);_try_break(a,t,["induce"],false)
   "HS_A02":
    var old:Variant=a.atk;a.atk=float(a.atk)+float(a.def)*.4/1.55;_attack(a,t,1.55,id,0);a.atk=old
    _apply_status(t,"defense_down",.25,3);_apply_status(t,"attack_down",.2,2)
    if _try_break(a,t,["disarm"],false):_o().disarm_seen=true
   "HS_A03":
    _attack(a,t,1.45,id,0)
    if _try_break(a,t,["interrupt"],false):_o().push_seen=true
    t.statuses.append({"kind":"flat_speed_down","value":20,"starts":state.round+1,"expires":state.round+1})
   "LYY_A02":
    var critical:bool=_rank(a,id)>=2 and (_status_value(t,"pain")>0 or int(t.vulnerable_through)>=state.round)
    _attack(a,t,(1.65 if _rank(a,id)>=3 else 1.45)*(1.5 if critical else 1.0),id,0);_apply_status(t,"speed_down",.15,2);_try_break(a,t,["sever"],false)
    t.statuses=t.statuses.filter(func(e):return e.kind!="pain")
    t.statuses.append({"kind":"pain","source":a.id,"value":mini(int(a.atk*.3),int(t.max_hp*.01)) if t.get("boss",false) else int(a.atk*.3),"starts":state.round+1,"expires":state.round+2})
   "LYY_A03":
    for e in state.actors:
     if e.team=="enemy" and alive(e) and (e.id!="chiyou_cauldron" or int(_o().unlock_round)>0 and state.round>=_o().unlock_round):
      _attack(a,e,1.25,id,0);_apply_status(e,"defense_down",.2,2);_apply_status(e,"flat_speed_down",15,2);_try_break(a,e,["disarm","interrupt"],false)
   "LYY_A04":
    _attack(a,t,1.6,id,0)
    if _rank(a,id)>=2 and _status_value(t,"pain")>0 and alive(t):_damage_action(a,t,.5,false,"followup",id)
    _apply_status(t,"speed_down",.25,2)
    if t.get("boss",false) and _rank(a,id)>=3:_apply_status(t,"attack_down",.3,2);_apply_status(t,"defense_down",.3,2)
    elif _rank(a,id)>=3 and not _protected(t):_apply_status(t,"sealed",1,1)
    _try_break(a,t,["needle","sever"],false)
   "LYY_A05":
    var friends:Array=[a] if t.id==a.id else [a,t]
    for f in friends:
     var amount:=mini(int(f.max_hp)-int(f.hp),int(f.max_hp*.05));f.hp+=amount;_event("heal",a.id,f.id,amount,{"reason":id,"passive":false})
     f.statuses.append({"kind":"flat_speed_up","value":20,"starts":state.round+1,"expires":state.round+2});f.next_guard=.2
     if _rank(a,id)>=2:_cleanse(f,1,["speed_down","root"])
    _apply_status(a,"mingxin",1,99999)
    if _rank(a,id)>=3:
     var enemy_target:=_legal_target("","enemy")
     if alive(enemy_target):_damage_action(a,enemy_target,.4,false,"followup",id)
  return
 super._execute_command(a,cmd)
func _try_break(a:Dictionary,t:Dictionary,tags:Array,low_threat:bool)->bool:
 for i in state.intents:
  if i.actor_id!=t.id or i.executed or i.cancelled:continue
  var matching:=false
  for tag in tags:
   if tag in i.tags:matching=true
  if matching and _break(a,t,i):
   if low_threat:i.hits=[.6];i.kind="strike";i.tags=[]
   else:i.cancelled=true
   _o().dismantled=true;return true
 return false
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 var done:=super._break(a,t,i)
 if done:_o().dismantled=true
 return done
func _after_preparation(a:Dictionary,skill:Dictionary)->void:
 if skill.get("source_id")=="LYY_A01":
  for i in state.intents:
   if i.actor_id!=a.stance.target_id or i.get("aoe",false) or i.kind!="strike":continue
   i.target_id=a.id;a.feint_guard_round=state.round
   if "induce" in i.tags and not i.executed and not i.cancelled and _break(a,actor_by_id(i.actor_id),i):
    i.cancelled=true
    if _rank(a,"LYY_A01")>=2:_damage_action(a,actor_by_id(i.actor_id),1.1,false,"counter","LYY_A01")
    if _rank(a,"LYY_A01")>=3:_apply_status(a,"mingxin",1,99999);gain_mana(a,4,"feint")
    if a.get("internal_skill","")=="LYY_N01":gain_mana(a,4,"cold_river")
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 if i.cancelled or _controlled(a):i.executed=true;return
 if i.kind=="catalyze":
  i.executed=true
  if _o().suppressed_round!=state.round and alive(actor_by_id(HERO)):_event("catalyze",a.id,HERO,_lose_hp(a,actor_by_id(HERO),600))
  else:_event("catalyze_suppressed",X,HERO)
  return
 if i.kind=="cold":
  i.executed=true;var t:=actor_by_id(X)
  if t.get("internal_skill","")!="HXS_N02":t.statuses.append({"kind":"cold","source":a.id,"value":int(a.atk*.9),"starts":state.round+1,"expires":state.round+3})
  return
 var hs:=actor_by_id(HS);var before:int=int(hs.get("hp",0))
 super._execute_intent(a,i)
 if not hs.is_empty() and hs.hp<before and hs.stance.get("skill_id")=="HS_A01" and hs.counter_count==0:
  hs.counter_count+=1;_o().guard_seen=true
  if alive(hs) and alive(a):_damage_action(hs,a,.5,false,"counter","HS_A01")
 if not hs.is_empty() and hs.get("internal_skill","")=="HS_N01" and alive(hs):gain_mana(hs,3,"vajra_breath")
func skill_cost(a:Dictionary,skill:Dictionary)->int:
 var value:int=super.skill_cost(a,skill)
 if a.id==LIU and state.get("round",0)==1 and "LYY_P01" in a.get("passives",[]) and skill.get("kind")!="combo" and not skill.get("prepare",false):value=int(ceil(value*.5))
 return value
func _speed(a:Dictionary,modifier:int,skill:Dictionary={})->int:
 if skill.get("kind")=="combo":
  var members:Array=_o().get("combo_members",[HERO,X])
  return mini(_speed(actor_by_id(members[0]),0),_speed(actor_by_id(members[1]),0))+(15 if _o().get("combo_skill")=="CO_01" else 10)
 return super._speed(a,modifier,skill)-int(_status_value(a,"flat_speed_down"))+int(_status_value(a,"flat_speed_up"))+(10000 if state.round==1 and a.id==LIU and "LYY_P01" in a.get("passives",[]) and skill.get("kind")!="combo" and not skill.get("prepare",false) else 0)
func _damage_action(a:Dictionary,t:Dictionary,m:float,aoe:bool,channel:String,id:String,guard:Dictionary={})->void:
 if t.id=="chiyou_cauldron" and (int(_o().unlock_round)==0 or state.round<int(_o().unlock_round)):_event("cauldron_locked",a.id,t.id);return
 var emergency:Dictionary={};var emergency_reduction:=0.0;var emergency_rewarded:=false
 var medic:=actor_by_id(X)
 if guard.is_empty() and not aoe and channel=="enemy" and m>=1.5 and t.team=="party" and t.id!=X and t.hp*10<t.max_hp*3 and alive(medic) and "HXS_P03" in medic.get("passives",[]) and not medic.get("emergency_used",false):
  emergency=medic;emergency_reduction=float(medic.get("reduction",0));emergency_rewarded=medic.guard_rewarded
  medic.emergency_used=true;medic.reduction=maxf(.5,emergency_reduction);medic.guard_rewarded=true;guard=medic;_event("emergency_guard",X,t.id)
 var old_atk:Variant=a.atk
 if a.id==LIU and "LYY_P02" in a.get("passives",[]) and a.hp*2<a.max_hp:a.atk=int(floor(a.atk*1.15))
 if a.id==LIU and channel=="normal" and _status_value(a,"mingxin")>0 and not (id=="LYY_A02" and (_status_value(t,"pain")>0 or t.vulnerable_through>=state.round)):m*=1.5;a.statuses=a.statuses.filter(func(e):return e.kind!="mingxin")
 var old:int=t.hp
 super._damage_action(a,t,m,aoe,channel,id,guard)
 a.atk=old_atk
 if not emergency.is_empty():emergency.reduction=emergency_reduction;emergency.guard_rewarded=emergency_rewarded
 if a.id==LIU and channel=="normal" and a.get("internal_skill","")=="LYY_N01" and a.get("frost_round",0)!=state.round:
  a.frost_round=state.round;t.statuses.append({"kind":"speed_down","value":.1,"starts":state.round+1,"expires":state.round+1})
 if t.id==LIU and t.hp<old and channel=="enemy" and "LYY_P02" in t.get("passives",[]) and t.get("rose_round",0)!=state.round and alive(t):t.rose_round=state.round;_damage_action(t,a,.6,false,"counter","LYY_P02")
 if t.hp<old and t.get("internal_guard",false):t.internal_guard=false
 if t.hp<old:t.next_guard=0.0
func _branch(a:Dictionary,t:Dictionary,raw:float,channel:String,id:String)->int:
 var defense:Variant=t.def;t.def=float(t.def)*(1-minf(.5,_status_value(t,"defense_down")))
 var old_reduction:float=t.get("reduction",0.0)
 if t.get("internal_skill","")=="HS_N01" and channel in ["enemy","guard"]:t.reduction=maxf(old_reduction,.15)
 if t.get("internal_guard",false):t.reduction=maxf(float(t.get("reduction",0.0)),.1)
 t.reduction=maxf(float(t.get("reduction",0.0)),float(t.get("next_guard",0)))
 if a.id=="han_ningzi" and channel=="enemy" and t.get("internal_skill","")=="HXS_N02":
  t.reduction=maxf(float(t.get("reduction",0)),.15)
  if t.get("cold_mana_round",0)!=state.round:t.cold_mana_round=state.round;gain_mana(t,4,"transform_cold")
 if t.get("feint_guard_round",0)==state.round:t.reduction=maxf(float(t.get("reduction",0.0)),.35)
 var result:=super._branch(a,t,raw,channel,id);t.def=defense;t.reduction=old_reduction;return result
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if not alive(t):return 0
 if t.id=="chiyou_cauldron" and (_o().herbs.size()<3 or int(_o().unlock_round)==0):amount=mini(amount,maxi(0,int(t.hp)-1))
 if t.id in ["lei_xingkong","chu_xianliu"]:amount=mini(amount,maxi(0,int(t.hp)-1))
 if t.team=="party" and amount>=t.hp and _status_value(t,"deathsave")>0 and not t.get("deathsave_used",false):
  var before:int=t.hp;t.hp=mini(int(t.max_hp),1+int(floor(t.max_hp*.2)));t.deathsave_used=true;t.statuses=t.statuses.filter(func(e):return e.kind!="deathsave");_event("deathsave",t.id,t.id);return maxi(0,before-1)
 return super._lose_hp(a,t,amount)
func _combo()->void:
 if not _eligible():_refund(true);return
 _o().reserved=0;combo_executing=true
 var h:=actor_by_id(HERO);var x:=actor_by_id(X)
 if _o().get("combo_skill")=="CO_01":
  var liu:=actor_by_id(LIU);var original:Variant=h.atk;h.atk=(float(h.atk)+float(liu.atk))/2
  for t in state.actors:
   if t.team!="enemy" or not alive(t) or (t.id=="chiyou_cauldron" and (int(_o().unlock_round)==0 or state.round<_o().unlock_round)):continue
   var defense:Variant=t.def;t.def=float(t.def)*.65
   _damage_action(h,t,2.85*(1.35 if t.id==_o().combo_target else 1.0),true,"combo","CO_01");t.def=defense;_apply_status(t,"defense_down",.35,2);_try_break(h,t,["disarm","induce"],false)
  h.atk=original
  for a in [h,liu]:_apply_status(a,"damage_reduction",.2,1)
  combo_executing=false;_event("combo_executed",HERO,LIU);return
 for t in state.actors:
  if t.team=="enemy" and alive(t) and (t.id!="chiyou_cauldron" or int(_o().unlock_round)>0 and state.round>=_o().unlock_round):_damage_action(h,t,2.2,true,"combo","CO_02");_apply_status(t,"attack_down",.25,2);_try_break(h,t,["sever","needle"],false)
 for t in state.actors:
  if t.team=="party" and alive(t):_heal(x,t,_fixed_heal(x,.55,5),false,"CO_02");_cleanse(t,1);gain_mana(t,8,"CO_02")
 combo_executing=false;_event("combo_executed",HERO,X)
func _check_outcome()->void:
 if state.outcome!="" or not state.has("objective"):return
 var required:String={"han":X,"lei":HS,"chu":HERO,"medicine":X}[state.encounter.kind]
 if not alive(actor_by_id(required)):state.outcome="defeat";_o().failure="required_actor_exhausted";return
 if state.mode!="round_end":return
 var healer:=actor_by_id(X)
 if alive(healer) and healer.get("internal_skill","")=="HXS_N01" and state.round%2==1:
  var low:=_lowest();gain_mana(low,4,"suwen");_cleanse(low,1,["bleed","poison","speed_down"])
 var won:=false
 match state.encounter.kind:
  "han":won=actor_by_id("han_ningzi").hp<=660
  "lei":won=state.round>=6 and _o().guard_seen and _o().disarm_seen and _o().push_seen
  "chu":won=state.round>=6 and _o().poems.size()==3 and _o().dismantled
  "medicine":
   if _o().phase==1 and actor_by_id("luo_mingqi").hp<=1800:
    _o().phase=2;var pot:=foe("chiyou_cauldron","蚩尤毒鼎",4200,240,235,140,48);_normalize(pot);state.actors.append(pot);_event("cauldron_summoned")
   if _o().phase==2 and _o().unlock_round==0:
    var cleared:=true
    for id in ["luo_mingqi","puppet_east","puppet_west"]:
     if alive(actor_by_id(id)):cleared=false
    if cleared:_o().unlock_round=state.round+1;_o().herb_deadline=state.round+3;_event("herb_window_open")
   if int(_o().herb_deadline)>0 and state.round>=int(_o().herb_deadline) and _o().herbs.size()<3:state.outcome="defeat";_o().failure="herb_deadline";return
   won=_o().phase==2 and not alive(actor_by_id("chiyou_cauldron")) and _o().herbs.size()==3 and alive(actor_by_id(HERO)) and alive(actor_by_id(LIU))
 if won:
  state.outcome="victory"
  var x:=actor_by_id(X)
  if alive(x) and "HXS_P01" in x.get("passives",[]) and not _o().postheal:
   _o().postheal=true
   for a in state.actors:
    if a.team=="party" and alive(a):var n:=mini(int(a.max_hp)-int(a.hp),int(a.max_hp*.2));a.hp+=n;_event("postbattle_heal",X,a.id,n)
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
 var summaries:Dictionary={"han":"医理问心：韩凝紫至30%血认输。N02免普通寒毒；望诊、转阴易阳、治疗与自守可配合。","lei":"雷鼓角力：实际护持、匹配破器、匹配推山各一次，存活至少六轮即平。","chu":"诗剑会友：依公开卦意回应三首诗，并实际拆招；至少六轮存活即平。","medicine":"晓霜气竭失败；梁萧/莺莺可复苏。毒师半血唤鼎，旧敌清场后下轮三轮投药，正确后正常击破鼎并三人生还。"}
 v.objective.summary=summaries[state.encounter.kind]
 v.objective.forecast=[];v.objective.available_actions=[]
 v.objective.herb_clues=["第一征象：青纹·风声——青叶·清风","第二征象：白纹·凝露——白花·澄露","第三征象：赤纹·暖光——赤萼·暖阳"]
 if state.encounter.kind=="medicine":v.objective.summary+=" 已投%d/3，截止第%d轮；梁萧轮初3%%毒伤，单疗/复苏压制当轮600催毒。"%[_o().herbs.size(),_o().herb_deadline]
 v.world_state={"map_id":state.encounter.context.get("map_id",""),"objective_id":state.encounter.id,"control_actor_id":X if state.encounter.kind in ["han","medicine"] else HS if state.encounter.kind=="lei" else HERO,"complete":state.outcome=="victory"}
 return v
