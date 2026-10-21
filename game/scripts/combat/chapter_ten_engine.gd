class_name ChapterTenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## B06 is six rounds of survival. Enemy vitality is not a victory meter.
const HERO := "char_liang_xiao"
const BOSS := "bayan"
const ID := "enc_ch10_bayan_tide"
const ALLOWED := ["normal_attack","self_guard","observe","sancai_counter","LX_A03"]
var entry_error := ""

static func encounter_config() -> Dictionary:
 return {"id":ID,"kind":"b06","name":"钱塘伯颜","level":46,"result":"ch10_tide_survived","xp":0,"battle_id":"B06","enemies":[{"id":BOSS,"name":"伯颜","team":"enemy","max_hp":3600,"max_mp":200,"atk":205,"def":120,"spd":38,"protection_rounds":1,"rotation":[{"name":"引弓蓄势","target_id":HERO,"hits":[],"tags":["interrupt"]}]}]}

func _init(r: Dictionary,c: Dictionary) -> void:
 super(r,c)
 content.skills["LX_A03"]={"name":"飞星九宫剑","source_id":"LX_A03","kind":"skill","target":"enemy","hits":[.55,.55,.55],"speed":8,"break_tag":"interrupt","martial":true}
 content.skills["ch10_borrow_tide"]={"name":"借潮引势","kind":"tide_cover","target":"self","prepare":true,"mp_floor":0}

func start(config: Dictionary,party: Array) -> void:
 entry_error=""
 var canonical:=encounter_config()
 for key in canonical:
  if not preload("res://scripts/campaign/encounter_session.gd").equivalent(config.get(key),canonical[key]):entry_error="invalid_encounter"
 for key in config:
  if key not in canonical and key!="context":entry_error="invalid_encounter"
 var ctx: Variant=config.get("context")
 if not ctx is Dictionary or not _whole(ctx.get("chapter"),10,10) or not ctx.get("current_token") is String or ctx.current_token.is_empty():entry_error="invalid_context"
 if party.size()!=1 or not party[0] is Dictionary or party[0].get("id")!=HERO:entry_error="solo_hero_required"
 else:
  var h: Dictionary=party[0]
  if h.get("team")!="party":entry_error="solo_hero_required"
  for k in ["hp","mp","max_hp","max_mp","atk","def","spd"]:
   if not _whole(h.get(k),1 if k in ["hp","max_hp"] else 0):entry_error="invalid_actor_number"
  if not h.get("skills") is Array or not h.get("skill_ranks") is Dictionary or not h.get("passives",[]) is Array or not h.get("internal_skill","") is String:entry_error="invalid_actor_metadata"
  if entry_error=="":
   if h.hp>h.max_hp or h.mp>h.max_mp:entry_error="invalid_resources"
   if h.get("internal_skill","") not in ["","LX_N01"]:entry_error="invalid_internal_skill"
   if h.get("internal_skill","")=="LX_N01" and not h.skill_ranks.has("LX_N01"):entry_error="unlearned_internal_skill"
   if not h.get("learned_passives",[]) is Array:entry_error="invalid_passive_metadata"
   var seen: Array=[]
   for skill in h.skills:
    if not skill is String or skill not in ALLOWED or skill in seen:entry_error="invalid_skill"
    seen.append(skill)
   for rank in h.skill_ranks.values():
    if not _whole(rank,1,3):entry_error="invalid_skill_rank"
   for pair in [["observe","LX_A01"],["sancai_counter","LX_A02"],["LX_A03","LX_A03"]]:
    if pair[0] in h.skills and not h.skill_ranks.has(pair[1]):entry_error="unlearned_skill"
   seen=[]
   for passive in h.get("passives",[]):
    if not passive is String or passive not in ["LX_P01","LX_P02","LX_P03"] or passive in seen:entry_error="invalid_passive"
    seen.append(passive)
   if seen.size()>2:entry_error="invalid_passive_slots"
   if h.get("learned_passives",[]) is Array:
    for passive in h.get("passives",[]):
     if passive not in h.get("learned_passives",[]):entry_error="unlearned_passive"
 if entry_error!="":
  state={"outcome":"invalid","mode":"finished","actors":[],"commands":{},"revision":0,"round":1,"intents":[],"events":[],"encounter":config.duplicate(true),"objective":{"failure":entry_error}};return
 var clean:=party.duplicate(true)
 clean[0].skills.append("ch10_borrow_tide")
 # Alias the shared observation rule to the actual learned source rank.
 clean[0].skill_ranks.observe=clean[0].skill_ranks.get("LX_A01",1)
 if clean[0].get("internal_skill","")=="LX_N01":clean[0].atk=int(floor(float(clean[0].atk)*1.08));clean[0].spd+=5
 if int(clean[0].skill_ranks.get("LX_A03",1))>=2:content.skills.LX_A03.hits=[.6,.6,.6]
 super.start(config,clean)
 checkpoint=snapshot()

func begin_round() -> void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective={"phase":"phase_one","survived_rounds":0,"bow_cancelled_round":0,"tide_used_round":0,"p03_stacks":0,"p03_events":[],"failure":"","grief_through":2,"grief_logged":false}
 if int(state.round)==4:
  var boss:=actor_by_id(BOSS);var lost:int=boss.max_hp-boss.hp
  boss.max_hp=4200;boss.hp=maxi(1,4200-lost);boss.max_mp=240
  boss.atk=230;boss.def=135;boss.spd=42
  state.objective.phase="phase_two";_event("tide_phase",BOSS,"",4,{"hero_resources_preserved":true})
 super.begin_round()
 var hero:=actor_by_id(HERO)
 if not state.objective.grief_logged:
  _apply_status(hero,"friend_rage",.2,2);state.objective.grief_logged=true
  _event("grief_modifier",HERO,"",2,{"attack_up":.2,"mp_discount":.25,"equips_passive":false})
 if hero.get("internal_skill","")=="LX_N01":gain_mana(hero,3,"mirror_breath")
 state.intents=[]
 match int(state.round):
  1: _intent("bow","引弓蓄势：下一回合金雕裂石箭2.20×攻击；本轮飞星可断弦",[],["interrupt"])
  2: _intent("release","金雕裂石箭：2.20×攻击；未断弦则自守减伤",[] if state.objective.bow_cancelled_round==2 else [2.2],[])
  3: _intent("palm","撼山重掌：1.60×攻击；三才可引偏",[1.6],["induce"])
  4: _intent("tide","帅令合围：潮骑冲踏1.30×攻击；借潮避开",[1.3],[],true)
  5:
   _intent("bow","引弓蓄势：下回合2.20×攻击；本轮飞星可断弦",[],["interrupt"])
   _intent("tide","持续潮压：0.50×攻击；借潮可避，自守可减伤",[.5],[],true)
  6:
   _intent("release","金雕裂石箭：2.20×攻击；自守保住最后一轮",[] if state.objective.bow_cancelled_round==6 else [2.2],[])
   _intent("tide","最后潮压：0.50×攻击；存活至轮末过关",[.5],[],true)

func _intent(kind: String,label: String,hits: Array,tags: Array,aoe: bool=false) -> void:
 state.intents.append({"actor_id":BOSS,"intent_id":"b06:%s:%d"%[kind,state.round],"kind":kind,"name":label,"target_id":HERO,"hits":hits,"tags":tags,"aoe":aoe,"executed":false,"cancelled":false})

func validate_command(actor: String,skill: String,target: String) -> String:
 if skill=="ch10_borrow_tide" and int(state.round)<4:return "tide_not_risen"
 return super.validate_command(actor,skill,target)
func set_command(actor: Variant,skill: Variant,target: Variant,revision: Variant=-1) -> String:
 if not actor is String or not skill is String or not target is String:return "invalid_command_type"
 if not revision is int or revision < -1:return "invalid_revision_type"
 return super.set_command(actor,skill,target,revision)
func apply_input(a: Variant) -> Dictionary:
 if not a is Dictionary or not a.has_all(["actor_id","action_id"]):return {"accepted":false,"error":"invalid_input"}
 for key in a:
  if key not in ["actor_id","action_id","revision"]:return {"accepted":false,"error":"unexpected_field"}
 if not a.actor_id is String or a.actor_id!=HERO or not a.action_id is String:return {"accepted":false,"error":"invalid_actor"}
 if a.has("revision") and (not a.revision is int or a.revision!=state.revision):return {"accepted":false,"error":"invalid_revision"}
 if state.mode!="commands" or state.outcome!="":return {"accepted":false,"error":"not_accepting_input"}
 match a.action_id:
  "borrow_tide":
   var error:=set_command(HERO,"ch10_borrow_tide",HERO,a.get("revision",-1))
   if error!="":return {"accepted":false,"error":error}
  "cancel":state.commands.clear();state.revision+=1
  "retreat":state.outcome="defeat";state.mode="finished";state.objective.failure="retreated";state.revision+=1
  _:return {"accepted":false,"error":"invalid_action"}
 return {"accepted":true}

func _after_preparation(actor: Dictionary,skill: Dictionary) -> void:
 if skill.kind=="tide_cover":state.objective.tide_used_round=state.round;_event("borrow_tide",HERO,"",state.round)
func _execute_intent(actor: Dictionary,intent: Dictionary) -> void:
 if intent.get("kind")=="tide" and state.objective.tide_used_round==state.round:
  intent.executed=true;_event("tide_avoided",HERO,BOSS);return
 super._execute_intent(actor,intent)
func _break(source: Dictionary,target: Dictionary,intent: Dictionary) -> bool:
 if not super._break(source,target,intent):return false
 if intent.get("kind")=="bow":state.objective.bow_cancelled_round=int(state.round)+1;intent.cancelled=true;_event("bow_interrupted",HERO,BOSS)
 if intent.get("kind")=="bow" and "LX_P03" in source.get("passives",[]) and intent.intent_id not in state.objective.p03_events:
  state.objective.p03_events.append(intent.intent_id);state.objective.p03_stacks=mini(3,int(state.objective.p03_stacks)+1)
 return true
func _execute_command(actor: Dictionary,command: Dictionary) -> void:
 var had_mingxin:=_status_value(actor,"mingxin")>0
 var breaks:int=state.break_count
 actor["observe_strike"]=had_mingxin and actor.get("observe_bonus",false) and command.skill_id in ["normal_attack","LX_A03"]
 super._execute_command(actor,command)
 if command.skill_id=="observe" and int(actor.skill_ranks.get("LX_A01",1))>=3:
  for effect in actor.statuses:
   if effect.kind=="mingxin" and not actor.get("observe_bonus_granted",false):actor["observe_bonus"]=true;actor["observe_bonus_granted"]=true
  for effect in actor_by_id(BOSS).statuses:
   if effect.kind=="posuan":effect.expires=int(state.round)+2
 elif had_mingxin and _status_value(actor,"mingxin")==0:actor["observe_bonus"]=false
 actor["observe_strike"]=false
 if command.skill_id=="LX_A03":
  actor["jiugong_through"]=state.round;actor["jiugong_speed_round"]=int(state.round)+1
  if state.break_count>breaks and int(actor.skill_ranks.get("LX_A03",1))>=3:
   gain_mana(actor,4,"jiugong_interrupt");actor.ready.LX_A03=maxi(int(state.round)+1,int(actor.ready.LX_A03)-1)
func _speed(actor: Dictionary,modifier: int,skill: Dictionary={}) -> int:
 return super._speed(actor,modifier,skill)+(10 if actor.get("jiugong_speed_round",-1)==state.round else 0)
func _counter(actor: Dictionary,target: Dictionary,induced: bool) -> void:
 var before:int=actor.counter_count;super._counter(actor,target,induced)
 if actor.counter_count==before:return
 if induced and int(actor.skill_ranks.get("LX_A02",1))>=2:
  var heal:=mini(int(actor.max_hp)-int(actor.hp),int(floor(float(actor.max_hp)*.02)));actor.hp+=heal;_event("sancai_heal",HERO,HERO,heal)
 if int(actor.skill_ranks.get("LX_A02",1))>=3:_apply_status(target,"attack_down",.15,2)
func _damage_action(source: Dictionary,target: Dictionary,multiplier: float,aoe: bool,channel: String,action_id: String,guard: Dictionary={}) -> void:
 var saved: Array=source.statuses.duplicate(true)
 if source.id==HERO:
  var bonus:=float(state.objective.p03_stacks)*.05
  if bonus>_status_value(source,"attack_up"):_apply_status(source,"attack_up",bonus,1)
  if source.get("observe_strike",false):multiplier*=1.1
 super._damage_action(source,target,multiplier,aoe,channel,action_id,guard)
 source.statuses=saved
func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
 var old_def:int=target.def;var old_reduction:float=target.get("reduction",0.0)
 if target.id==HERO:
  target.def=int(floor(float(old_def)*(1.0+maxf(float(state.objective.p03_stacks)*.05,_status_value(target,"defense_up")))))
  if target.get("jiugong_through",-1)==state.round:target.reduction=maxf(old_reduction,.2)
 var result:=super._branch(source,target,raw,channel,action_id)
 target.def=old_def;target.reduction=old_reduction
 if raw>0 and target.get("jiugong_through",-1)==state.round:target.jiugong_through=-1
 return result
func _lose_hp(source: Dictionary,target: Dictionary,amount: int) -> int:
 if target.id==BOSS:
  var loss:=mini(maxi(0,int(target.hp)-1),maxi(0,amount));target.hp-=loss;return loss
 return super._lose_hp(source,target,amount)
func _check_outcome() -> void:
 if state.outcome!="":return
 if not alive(actor_by_id(HERO)):state.outcome="defeat";state.objective.failure="hero_exhausted";return
 if state.mode!="round_end":return
 state.objective.survived_rounds=state.round
 if int(state.round)==6:
  state.outcome="victory";state.objective.phase="completed";_event("survived_six_rounds",HERO,BOSS,6)
func get_view() -> Dictionary:
 var v:=snapshot()
 if entry_error!="":return v
 v.skill_data=content.skills.duplicate(true);v.skill_costs={HERO:{}};v.legal_commands={HERO:[]}
 for skill in actor_by_id(HERO).skills:
  v.skill_costs[HERO][skill]=skill_cost(actor_by_id(HERO),content.skills[skill])
  for actor in state.actors:
   if validate_command(HERO,skill,actor.id)=="":v.legal_commands[HERO].append({"skill_id":skill,"target_id":actor.id})
 v.objective.summary="坚守%d/6轮；第4轮潮起。伯颜气血不决定胜负。"%state.objective.survived_rounds
 v.objective.available_actions=[]
 if state.mode=="commands":
  if state.round>=4:v.objective.available_actions.append({"id":"borrow_tide","name":"借潮引势（只避潮压，不挡箭）","input":{"actor_id":HERO,"action_id":"borrow_tide"}})
 v.world_state={"map_id":state.encounter.context.get("map_id","map_ch10_qiantang_bank"),"objective_id":ID,"control_actor_id":HERO,"player_position":[240,224],"actor_positions":{HERO:[240,224],"char_bayan":[304,192]},"visible_actor_ids":[HERO,"char_bayan"],"battle_phase":state.objective.phase,"complete":state.outcome=="victory"}
 return v
