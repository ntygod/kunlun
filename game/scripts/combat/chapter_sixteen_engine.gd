class_name ChapterSixteenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## MQ16 ordinary development encounter, not B13. Existing LX01-05 handlers follow chapter13.
const Same=preload("res://scripts/campaign/encounter_session.gd")
const HERO="char_liang_xiao"
const ARUTAI="npc_ch16_arutai"
const ID="ch16_night_raid"
const ALLOWED=["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03","LX_A04","LX_A05","LX_A06"]
var entry_error=""
static func encounter_config(id:String=ID)->Dictionary:
 if id!=ID:return {}
 return {"id":ID,"kind":"ordinary","name":"精绝夜袭","description":"妇孺已入石屋。梁萧独自断后，观察连环鞭势，选择接引、拆招或进攻。","level":69,"xp":0,"result":"ch16_refuge_secured","enemies":[
  {"id":ARUTAI,"name":"阿鲁台·花斑豹","team":"enemy","max_hp":1500,"max_mp":0,"atk":175,"def":140,"spd":48,"boss":false,"protection_rounds":1,"rotation":[
   {"name":"连环鞭：三段散劲，汇涓可接引；伤害不会回滚","target_id":HERO,"hits":[.65,.65,.65],"tags":["interrupt","induce"],"speed":0},
   {"name":"横刀迫近：单段重击，可引偏","target_id":HERO,"hits":[1.5],"tags":["induce"],"speed":0}]}]}
func _init(r:Dictionary,c:Dictionary)->void:
 super(r,c)
 content.skills.LX_A03={"name":"飞星九宫剑","source_id":"LX_A03","kind":"skill","target":"enemy","hits":[.55,.55,.55],"speed":8,"break_tag":"interrupt","martial":true}
 content.skills.LX_A04={"name":"滴水穿石劲","source_id":"LX_A04","kind":"skill","target":"enemy","speed":12,"martial":true}
 content.skills.LX_A05={"name":"碧海惊涛掌","source_id":"LX_A05","kind":"skill","target":"enemy","speed":0,"martial":true}

 # Self-targeting preparation consumes the normal action; retaliation is capped once per round.
 content.skills.LX_A06={"name":"汇涓成河","source_id":"LX_A06","kind":"river_stance","target":"self","prepare":true,"speed":25,"martial":true}
func start(config:Dictionary,party:Array)->void:
 entry_error=""
 var canonical:=encounter_config()
 for k in canonical:
  if not Same.equivalent(config.get(k),canonical[k]):entry_error="invalid_encounter"
 for k in config:
  if k not in canonical and k!="context":entry_error="invalid_encounter"
 var ctx:Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),16,16) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
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
   if a.skill_ranks.has("LX_A06") and a.skill_ranks.LX_A06!=1:entry_error="river_rank_not_yet_authorized"
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
 if not state.has("objective"):
  state.objective={"failure":"","whale_procs":0,"whale_action":"","whale_loss":0,"whale_guard":false,"p03_stacks":0,"p03_events":[],"river_actions":[],"civilians_safe":true,"pending":{}}
 super.begin_round()
 var a:=actor_by_id(HERO)
 a.passive_healed=0
 if a.get("internal_skill","")=="LX_N02":
  _passive_heal(a,.02,"whale_breath");gain_mana(a,4,"whale_breath")
 elif a.get("internal_skill","")=="LX_N01":gain_mana(a,3,"mirror_breath")
 if a.get("tide_shield_until",-1)<state.round:a.shield=0
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
 if "LX_P03" in a.get("passives",[]) and i.intent_id not in state.objective.p03_events:
  state.objective.p03_events.append(i.intent_id);state.objective.p03_stacks=mini(3,int(state.objective.p03_stacks)+1)
 return true
func _execute_intent(a:Dictionary,i:Dictionary)->void:
 var target:=actor_by_id(str(i.get("target_id","")))
 var ready:bool=not target.is_empty() and target.stance.get("kind","")=="river_stance" and not i.get("cancelled",false)
 if not ready:
  super._execute_intent(a,i);return
 # Run every original segment, including guard/shield/passive routing. Only then retaliate.
 var previous:Array=target.statuses.duplicate(true)
 _apply_status(target,"damage_reduction",.50,1)
 var hp_before:int=target.hp
 super._execute_intent(a,i)
 target.statuses=previous
 var layers:int=mini(3,i.get("hits",[]).size())
 if layers<=0 or not alive(target) or not alive(a):return
 if int(target.counter_count)>=int(rules.limits.counter_per_actor_round) or int(target.stance.get("tokens",0))<=0:return
 target.stance.tokens=0;target.counter_count+=1
 var matched:bool=i.get("hits",[]).size()>1 and ("interrupt" in i.get("tags",[]) or "induce" in i.get("tags",[]))
 var unloaded:bool=matched and _break(target,a,i)
 _event("river_counter",target.id,a.id,layers,{"multiplier":1.30+.30*layers,"action_id":i.intent_id,"hp_loss_before_counter":hp_before-int(target.hp),"unloaded":unloaded})
 state.objective.river_actions.append(i.intent_id)
 _damage_action(target,a,1.30+.30*layers,false,"counter","LX_A06:"+str(i.intent_id))
func _reduction(a:Dictionary)->float:
 var base:float=super._reduction(a)
 if a.stance.get("kind","")=="river_stance":base=maxf(base,.50)
 return minf(base,float(rules.limits.extra_damage_reduction))
func _check_outcome()->void:
 super._check_outcome()
 if state.outcome=="defeat":state.objective.failure="hero_exhausted"
func get_view()->Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={HERO:{}};v.legal_commands={HERO:[]}
 for skill in actor_by_id(HERO).skills:
  v.skill_costs[HERO][skill]=skill_cost(actor_by_id(HERO),content.skills[skill])
  for a in state.actors:
   if validate_command(HERO,skill,a.id)=="":v.legal_commands[HERO].append({"skill_id":skill,"target_id":a.id})
 v.objective.summary="妇孺已安置在石屋；阻止追击并战胜阿鲁台。汇涓为自身架势，本轮减伤50%，按一个敌方动作积流后只反震一次。"
 v.objective.available_actions=[]
 return v
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
