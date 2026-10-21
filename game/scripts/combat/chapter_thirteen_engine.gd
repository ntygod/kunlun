class_name ChapterThirteenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
const Same=preload("res://scripts/campaign/encounter_session.gd")
const HERO="char_liang_xiao"
const YUN="npc_yun_shu"
const HE="npc_hetuoluo"
const ID="enc_ch13_island_departure"
const ALLOWED=["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03","LX_A04","LX_A05"]
var entry_error=""
static func enemy(id:String,hp:int,atk:int,defense:int,speed:int)->Dictionary:
 return {"id":id,"name":"云殊" if id==YUN else "贺陀罗","team":"enemy","max_hp":hp,"max_mp":200 if id==YUN else 250,"atk":atk,"def":defense,"spd":speed,"boss":true,"protection_rounds":1,"rotation":[{"name":"临礁迫近","hits":[],"tags":[],"target_id":HERO}]}
static func encounter_config(id:String=ID)->Dictionary:
 if id!=ID:return {}
 return {"id":ID,"kind":"b10","name":"海岛离脱","level":62,"xp":0,"battle_id":"B10","result":"ch13_ship_departed","enemies":[enemy(YUN,4000,245,145,46),enemy(HE,4500,270,155,50)]}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 content.skills.LX_A03={"name":"飞星九宫剑","source_id":"LX_A03","kind":"skill","target":"enemy","hits":[.55,.55,.55],"speed":8,"break_tag":"interrupt","martial":true}
 content.skills.LX_A04={"name":"滴水穿石劲","source_id":"LX_A04","kind":"skill","target":"enemy","speed":12,"martial":true}
 content.skills.LX_A05={"name":"碧海惊涛掌","source_id":"LX_A05","kind":"skill","target":"enemy","speed":0,"martial":true}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config()
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),13,13) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
 if party.size()!=1 or not party[0] is Dictionary or party[0].get("id")!=HERO:entry_error="solo_hero_required"
 else:
  var a:Dictionary=party[0]
  if a.get("team")!="party" or a.get("status","") in ["dead","permanently_departed"]:entry_error="invalid_actor"
  for k in ["hp","mp","max_hp","max_mp","atk","def","spd","fixed_level"]:
   if not _whole(a.get(k),1 if k in ["hp","max_hp","fixed_level"] else 0):entry_error="invalid_actor_number"
  if not a.get("skills") is Array or not a.get("skill_ranks") is Dictionary or not a.get("passives") is Array or not a.get("learned_passives") is Array:entry_error="invalid_metadata"
  if entry_error=="":
   if a.hp>a.max_hp or a.mp>a.max_mp or a.fixed_level>80:entry_error="invalid_resources"
   var seen:Array=[];var active:Array=[]
   for skill in a.skills:
    if not skill is String or skill not in ALLOWED or skill in seen:entry_error="invalid_skill"
    seen.append(skill)
    if skill not in ["normal_attack","self_guard","guard_ally"]:
     var source:String={"observe":"LX_A01","sancai_counter":"LX_A02"}.get(skill,skill)
     active.append(source)
     if not a.skill_ranks.has(source):entry_error="unlearned_skill"
   if active.size()>4:entry_error="active_slot_limit"
   if a.has("equipped_active_skills") and not Same.equivalent(active,a.equipped_active_skills):entry_error="loadout_mismatch"
   for rank in a.skill_ranks.values():
    if not _whole(rank,1,3):entry_error="invalid_rank"
   seen=[]
   for passive in a.passives:
    if passive not in ["LX_P01","LX_P02","LX_P03"] or passive not in a.learned_passives or passive in seen:entry_error="invalid_passive"
    seen.append(passive)
   if seen.size()>2:entry_error="passive_slot_limit"
   if a.get("internal_skill","") not in ["","LX_N01","LX_N02"]:entry_error="invalid_internal"
   if a.get("internal_skill")=="LX_N02" and (a.get("internal_stats_applied")!=true or a.get("panel_internal_skill")!="LX_N02" or not a.skill_ranks.has("LX_N02")):entry_error="invalid_internal_panel"
 if entry_error!="":
  state={"mode":"finished","outcome":"invalid","actors":[],"commands":{},"revision":0,"events":[],"round":1,"intents":[],"objective":{"failure":entry_error}};return
 var clean:Array=party.duplicate(true);var a:Dictionary=clean[0]
 a.skill_ranks.observe=a.skill_ranks.get("LX_A01",1)
 if a.get("internal_skill","")=="LX_N01":a.atk=int(floor(a.atk*1.08));a.spd+=5
 content.skills.LX_A03.hits=[.6,.6,.6] if int(a.skill_ranks.get("LX_A03",1))>=2 else [.55,.55,.55]
 super.start(config,clean);checkpoint=snapshot()
func begin_round()->void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective={"phase":1,"anchor":0,"survived_rounds":0,"failure":"","whale_procs":0,"whale_action":"","whale_loss":0,"whale_guard":false,"p03_stacks":0,"p03_events":[],"postheal":false}
 if state.objective.anchor>=50 and state.objective.phase==1:
  state.objective.phase=2;_event("phase_changed",HE,HERO,2,{"resources_preserved":true})
 super.begin_round()
 var a:=actor_by_id(HERO)
 a.passive_healed=0
 if a.get("internal_skill","")=="LX_N02":
  _passive_heal(a,.02,"whale_breath");gain_mana(a,4,"whale_breath")
 elif a.get("internal_skill","")=="LX_N01":gain_mana(a,3,"mirror_breath")
 if a.get("tide_shield_until",-1)<state.round:a.shield=0
 state.intents=[]
 var lead:String=YUN if state.objective.phase==1 else HE
 if int(state.round)%3==1:_intent(lead,"fire","毁帆火攻：若未打断，起锚倒退30；本轮惊涛/飞星可阻",[],["interrupt"],-15)
 _intent(lead,"thrust","临礁重击：2.00倍攻击；三才可引偏，自守减伤",[2.0],["induce"],0)
 if state.objective.phase==2:_intent(YUN,"pressure","云殊逼索：0.45倍攻击；保护船沿",[.45],[],0)
func _intent(id:String,kind:String,label:String,hits:Array,tags:Array,speed:int)->void:
 state.intents.append({"actor_id":id,"intent_id":"b10:%s:%d"%[kind,state.round],"kind":kind,"name":label,"target_id":HERO,"hits":hits,"tags":tags,"speed":speed,"executed":false,"cancelled":false})
func set_command(a:Variant,s:Variant,t:Variant,revision:Variant=-1)->String:
 if not a is String or not s is String or not t is String:return "invalid_command_type"
 if not revision is int or revision < -1:return "invalid_revision_type"
 return super.set_command(a,s,t,revision)
func apply_input(a:Variant)->Dictionary:
 if not a is Dictionary or not a.has_all(["actor_id","action_id"]):return {"accepted":false,"error":"invalid_input"}
 for key in a:
  if key not in ["actor_id","action_id","revision"]:return {"accepted":false,"error":"unexpected_field"}
 if a.actor_id!=HERO or not a.action_id is String:return {"accepted":false,"error":"invalid_actor"}
 if a.has("revision") and (not a.revision is int or a.revision!=state.revision):return {"accepted":false,"error":"invalid_revision"}
 if state.mode!="commands" or state.outcome!="":return {"accepted":false,"error":"not_accepting_input"}
 if a.action_id=="cancel":state.commands.clear();state.revision+=1
 elif a.action_id=="retreat":state.outcome="defeat";state.mode="finished";state.objective.failure="retreated";state.revision+=1
 else:return {"accepted":false,"error":"invalid_action"}
 return {"accepted":true}
func _break(a:Dictionary,t:Dictionary,i:Dictionary)->bool:
 if not super._break(a,t,i):return false
 if i.get("kind")=="fire":i.cancelled=true;_event("fire_cancelled",a.id,t.id)
 if "LX_P03" in a.get("passives",[]) and i.intent_id not in state.objective.p03_events:
  state.objective.p03_events.append(i.intent_id);state.objective.p03_stacks=mini(3,int(state.objective.p03_stacks)+1)
 return true
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 if i.kind=="fire":
  i.executed=true
  if not i.cancelled:state.objective.anchor=maxi(0,int(state.objective.anchor)-30);_event("sail_burned",a.id,"ship",30)
  return
 super._execute_intent(a,i)
func _execute_command(a:Dictionary,cmd:Dictionary)->void:
 var id:String=cmd.skill_id
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
 return super._speed(a,modifier,skill)+(10 if a.get("jiugong_speed_round",-1)==state.round else 0)
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
 var previous_statuses:Array=a.statuses.duplicate(true)
 if a.id==HERO:
  var bonus:=float(state.objective.p03_stacks)*.05
  if bonus>_status_value(a,"attack_up"):_apply_status(a,"attack_up",bonus,1)
  if a.get("observe_strike",false):m*=1.1
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
 var before:int=t.hp;var result:=super._branch(a,t,raw,channel,id)
 if t.id==HERO and channel=="enemy" and t.get("internal_skill","")=="LX_N02":
  state.objective.whale_loss+=before-int(t.hp)
  if not state.objective.whale_guard and state.objective.whale_loss>int(t.max_hp)*.25 and state.objective.whale_procs<2:
   state.objective.whale_guard=true;state.objective.whale_procs+=1;_event("whale_guard",HERO,HERO,1,{"subsequent_segments_only":true})
 t.def=old_def;t.reduction=old_reduction
 if raw>0 and t.get("jiugong_through",-1)==state.round:t.jiugong_through=-1
 return result
func _lose_hp(a:Dictionary,t:Dictionary,amount:int)->int:
 if t.team=="enemy":
  var loss:=mini(maxi(0,int(t.hp)-1),maxi(0,amount));t.hp-=loss;return loss
 return super._lose_hp(a,t,amount)
func _check_outcome()->void:
 if state.outcome!="":return
 if not alive(actor_by_id(HERO)):state.outcome="defeat";state.objective.failure="hero_exhausted";return
 if state.mode!="round_end":return
 state.objective.survived_rounds=state.round;state.objective.anchor=mini(100,int(state.objective.anchor)+20)
 _event("anchor_progress",HERO,"ship",state.objective.anchor)
 if state.round>=5 and state.objective.anchor>=100:
  state.outcome="victory"
  # Solo B10 has no HXS_P01 bearer; survival victory grants no HP reward.
func get_view()->Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={HERO:{}};v.legal_commands={HERO:[]}
 for skill in actor_by_id(HERO).skills:
  v.skill_costs[HERO][skill]=skill_cost(actor_by_id(HERO),content.skills[skill])
  for a in state.actors:
   if validate_command(HERO,skill,a.id)=="":v.legal_commands[HERO].append({"skill_id":skill,"target_id":a.id})
 v.objective.summary="起锚%d/100；已守%d轮，至少5轮。50起锚后贺陀罗逼近；毁帆倒退30。"%[state.objective.anchor,state.objective.survived_rounds]
 v.objective.available_actions=[]
 v.world_state={"map_id":state.encounter.context.get("map_id","map_ch13_island_shore"),"objective_id":ID,"control_actor_id":HERO,"player_position":[160,224],"actor_positions":{HERO:[160,224],YUN:[256,192],HE:[304,224]},"visible_actor_ids":[HERO,YUN,HE],"battle_phase":state.objective.phase,"complete":state.outcome=="victory"}
 return v
