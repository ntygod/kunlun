class_name ChapterSevenCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## Chapter-seven approved, public sparse schedules; rewards belong to campaign only.
const HERO := "char_liang_xiao"
const AXUE := "char_axue"
const BOSS := "jin_fei"
const DATA_PATH := "res://data/chapter_seven_encounters.json"
const CENTERS := [Vector2i(160,240),Vector2i(320,240),Vector2i(480,240)]
const SAFE := [-1,1,-1]
const SUPPORTS := {"A":934,"B":933,"C":933}
const MARKS := {"A":"left_beam","B":"crossbeam","C":"right_winch"}
var entry_error := ""
var snow_source: Dictionary = {}

func _init(rule_data: Dictionary,runtime_data: Dictionary) -> void:
 super(rule_data,runtime_data)
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
 content.skills.merge(data.skills,true)

func start(encounter: Dictionary,party: Array) -> void:
 entry_error=""
 var ids: Array=[]
 for a in party:
  if not a is Dictionary or not a.get("id") is String or a.id not in [HERO,AXUE] or a.id in ids:entry_error="invalid_party";break
  ids.append(a.id)
  if not a.get("team") is String or a.team!="party":entry_error="invalid_team";break
  for key in ["hp","mp","max_hp","max_mp","atk","def","spd"]:
   if not _whole(a.get(key),1 if key in ["hp","max_hp"] else 0):entry_error="invalid_actor_number";break
  if entry_error!="":break
  if a.hp>a.max_hp or a.mp>a.max_mp or not a.get("skills") is Array or not a.get("passives",[]) is Array:entry_error="invalid_actor_resources";break
  for skill in a.skills:
   if not skill is String:entry_error="invalid_skill"
  for passive in a.get("passives",[]):
   if not passive is String:entry_error="invalid_passive"
  if not a.get("skill_ranks",{}) is Dictionary or not a.get("internal_skill","") is String:entry_error="invalid_actor_metadata"
  elif a.has("skill_ranks"):
   for rank in a.skill_ranks.values():
    if not _whole(rank,1,3):entry_error="invalid_rank"
  if a.has("controllable") and not a.controllable is bool:entry_error="invalid_controllable"
 if HERO not in ids or AXUE not in ids:entry_error="required_party_missing"
 if not encounter.get("kind") is String or encounter.kind not in ["fire_ox","b04"] or not _whole(encounter.get("level")) or encounter.level!=31:entry_error="invalid_encounter"
 if entry_error!="":
  state={"outcome":"invalid","mode":"finished","actors":[],"commands":{},"revision":0,"round":1,"intents":[],"events":[],"encounter":encounter.duplicate(true),"objective":{"failure":entry_error,"phase":1,"pending":{}}};return
 var clean: Array=[]
 for a in party:
  var actor: Dictionary=a.duplicate(true)
  if actor.id==AXUE:snow_source=actor;continue
  actor.controllable=true
  if actor.get("internal_skill","")=="LX_N01":actor.atk=int(floor(float(actor.atk)*1.08));actor.spd+=5
  if "ch07_action" not in actor.skills:actor.skills.append("ch07_action")
  clean.append(actor)
 super.start(encounter,clean)
 if encounter.kind=="fire_ox":
  # This is a controlled hazard, not a new combat: preserve actual MP.
  actor_by_id(HERO).mp=int(party[ids.find(HERO)].mp)
 checkpoint=snapshot()

func _initial_objective() -> Dictionary:
 return {"phase":1,"phase_round":1,"phase_start":1,"completed_rounds":0,"pending":{},"failure":"","jin_repelled":false,"snow_freed":false,"haiya_handed":false,"supports":{"A":934,"B":933,"C":933},"calibrated":"","bolts":3,"evacuation":0,"haiya_safe":false,"shifutong_safe":false,"suppressed":{},"passive_turn":0,"hazard_index":0,"position":[160,240],"mistakes":[],"covered":[],"path":[],"phase_entry":{},"withdraw_path":[],"escort_position":[416,240]}

func begin_round() -> void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective=_initial_objective()
 var o: Dictionary=state.objective
 o.phase_round=int(state.round)-int(o.phase_start)+1
 super.begin_round()
 o.pending={}
 if state.encounter.kind=="fire_ox":state.intents=[];return
 for actor in state.actors:
  if actor.team=="party" and alive(actor) and actor.get("internal_skill","")=="LX_N01":gain_mana(actor,3,"mirror_breath")
 state.intents=[]
 if int(o.phase)==1:_phase_one_intents()
 else:_phase_two_intents()
 _axue_passive()
 for actor in state.actors:
  if actor.team=="party" and alive(actor) and int(actor.get("ax_regen_until",-1))>=int(state.round) and int(actor.get("ax_regen_start",999999))<=int(state.round):gain_mana(actor,4,"ax_s02_regen")
 _check_friend_rage()

func _intent(id: String,name: String,hits: Array,tags: Array,aoe: bool=false) -> void:
 state.intents.append({"actor_id":id,"intent_id":"%s:%d"%[id,state.round],"name":name,"target_id":HERO,"hits":hits,"tags":tags,"aoe":aoe,"executed":false,"cancelled":false})

func _phase_one_intents() -> void:
 var n: int=(int(state.objective.phase_round)-1)%6+1
 var active: String={1:"archer_left",2:"archer_left",3:"archer_right",4:"archer_right",5:BOSS,6:BOSS}[n]
 for id in [BOSS,"archer_left","archer_right"]:
  if not alive(actor_by_id(id)) or (id==BOSS and state.objective.jin_repelled):continue
  if id!=active:_intent(id,"换位/装填（无伤害）",[],[]);continue
  if n%2==1:_intent(id,"蓄箭（可飞星打断下一轮释放）" if n<5 else "重斩蓄势",[],["interrupt","induce"])
  elif state.objective.suppressed.get(id,-1)==int(state.round):_intent(id,"蓄势已破，本轮释放取消",[],[])
  else:_intent(id,"箭雨 1.40×130" if n<5 else "重斩 1.85×130",[1.4 if n<5 else 1.85],["induce","arrow_rain"] if n<5 else ["induce"])

func _phase_two_intents() -> void:
 var n: int=(int(state.objective.phase_round)-1)%6+1
 _intent("bridge_threat",{1:"落石阴影预告（环境陷阱）",2:"落石 1.00×145（环境陷阱）",3:"箭雨预告",4:"箭雨 1.40×130",5:"落石阴影预告（环境陷阱）",6:"落石 1.00×145（环境陷阱）"}[n],[1.4] if n==4 else ([1.0] if n in [2,6] else []),["arrow_rain"] if n in [3,4] else ["environment_trap"],true)
 actor_by_id("bridge_threat").atk=130 if n==4 else 145

func _axue_passive() -> void:
 var a:=actor_by_id(AXUE);var h:=actor_by_id(HERO)
 if int(state.round)%2!=0 or int(state.objective.passive_turn)==int(state.round) or not alive(a) or not alive(h) or not a.get("controllable",false) or "AX_P01" not in a.get("passives",[]):return
 state.objective.passive_turn=state.round
 var target: Dictionary=h
 var chosen: Dictionary={}
 for member in [h,a]:
  for effect in member.statuses:
   if effect.kind in ["bleed","cold_poison","luo_pain","stun","sleep","freeze","sealed","attack_down","speed_down"] and int(effect.starts)<=int(state.round) and int(effect.expires)>int(state.round):
    if chosen.is_empty() or int(effect.starts)<int(chosen.starts):chosen=effect
  if not chosen.is_empty():target=member;break
 if not chosen.is_empty():chosen.expires-=1;_event("ax_p01_shortened",AXUE,target.id,1,{"kind":chosen.kind})
 gain_mana(target,3,"ax_p01")

func input_error(action: Dictionary) -> String:
 if state.mode!="commands" or state.outcome!="":return "not_accepting_input"
 for key in action:
  if key not in ["actor_id","action_id","value","mark","revision"]:return "unexpected_field"
 for key in ["actor_id","action_id"]:
  if not action.get(key) is String:return "invalid_input_type"
 if action.has("revision") and (not _whole(action.revision) or int(action.revision)!=int(state.revision)):return "stale_revision"
 if action.actor_id!=HERO or not alive(actor_by_id(HERO)):return "actor_unavailable"
 if action.action_id=="retreat" and not action.has("value") and not action.has("mark"):return ""
 if action.action_id=="cancel":return "" if action.size()==2 or (action.size()==3 and action.has("revision")) else "unexpected_field"
 if state.encounter.kind=="fire_ox":
  if action.action_id=="move" and action.get("value") is String and action.value in ["left","right","up","down"] and not action.has("mark"):return "" if _move_destination(action.value)!=Vector2i(-1,-1) else "blocked"
  if action.action_id=="cover" and not action.has("value") and not action.has("mark"):return ""
  return "invalid_hazard_action"
 if int(state.objective.phase)==1:
  if action.has("value") or action.has("mark"):return "unexpected_value"
  if action.action_id=="free_axue" and state.objective.jin_repelled and not state.objective.snow_freed:return ""
  if action.action_id=="handoff_haiya" and state.objective.snow_freed and not state.objective.haiya_handed:return ""
 else:
  if not action.get("value") is String or action.value not in SUPPORTS:return "invalid_support"
  if action.action_id=="calibrate" and action.get("mark") is String and action.mark in MARKS.values() and int(state.objective.supports[action.value])>0:return ""
  if action.action_id=="fire" and not action.has("mark"):return ""
 return "invalid_action"

func _move_destination(direction: String) -> Vector2i:
 var p:=Vector2i(state.objective.position[0],state.objective.position[1])
 var q: Vector2i=p+{"left":Vector2i(-16,0),"right":Vector2i(16,0),"up":Vector2i(0,-16),"down":Vector2i(0,16)}[direction]
 var index:=mini(2,int(state.objective.hazard_index))
 if q.x<128 or q.x>512 or q.y<208 or q.y>256:return Vector2i(-1,-1)
 # Each un-cleared ox blocks onward progress, but walking to the next checkpoint is real.
 if q.x>CENTERS[index].x+32:return Vector2i(-1,-1)
 return q

func apply_input(action: Dictionary) -> Dictionary:
 var error:=input_error(action)
 if error!="":return {"accepted":false,"error":error}
 var o: Dictionary=state.objective
 if action.action_id=="retreat":o.failure="retreated";state.outcome="defeat";state.mode="finished";_event("retreated",HERO)
 elif action.action_id=="cancel":state.commands.erase(HERO);o.pending={}
 elif action.action_id=="move":
  var q:=_move_destination(action.value);o.path.append({"from":o.position.duplicate(),"to":[q.x,q.y]});o.position=[q.x,q.y]
 else:
  var clean:=action.duplicate(true);clean.erase("revision")
  o.pending=clean;state.commands[HERO]={"actor_id":HERO,"skill_id":"ch07_action","target_id":HERO}
 state.revision+=1
 return {"accepted":true}

func validate_command(actor_id: String,skill_id: String,target_id: String) -> String:
 if skill_id=="ch07_action":return "use_scene_input"
 if state.encounter.kind=="fire_ox":return "use_hazard_inputs"
 var error:=super.validate_command(actor_id,skill_id,target_id)
 if error!="":return error
 var actor:=actor_by_id(actor_id);var target:=actor_by_id(target_id)
 if _status_value(actor,"stun")>0 or _status_value(actor,"sleep")>0 or _status_value(actor,"freeze")>0:return "actor_controlled"
 if skill_id=="AX_S02" and target.team!="party":return "invalid_target"
 if target.get("withdrawn",false):return "target_withdrawn"
 if actor_id==AXUE and skill_id not in ["normal_attack","self_guard","guard_ally","AX_S01","AX_S02"]:return "limited_support"
 if int(state.objective.phase)==1 and target_id==BOSS and state.objective.jin_repelled:return "jin_fei_withdrawn"
 if int(state.objective.phase)==2 and content.skills[skill_id].get("target")=="enemy" and skill_id!="normal_attack":return "target_out_of_reach"
 return ""

func set_command(actor_id: String,skill_id: String,target_id: String,revision: int=-1) -> String:
 var error:=super.set_command(actor_id,skill_id,target_id,revision)
 if error=="" and actor_id==HERO:state.objective.pending={}
 return error

func _execute_command(actor: Dictionary,command: Dictionary) -> void:
 if command.skill_id=="ch07_action":_scene_action();return
 if command.skill_id=="AX_S02":
  _pay(actor,command.skill_id,content.skills[command.skill_id])
  var target:=actor_by_id(command.target_id)
  var heal:=mini(104,int(target.max_hp)-int(target.hp));target.hp+=heal
  for effect in target.statuses:
   if effect.kind in ["bleed","cold_poison","luo_pain"] and int(effect.starts)<=int(state.round) and int(effect.expires)>=int(state.round):target.statuses.erase(effect);break
  target.ax_regen_start=int(state.round)+1;target.ax_regen_until=int(state.round)+2
  _event("ax_heal",actor.id,target.id,heal);return
 if int(state.objective.phase)==2 and command.skill_id=="normal_attack":
  _event("structure_out_of_reach",actor.id,"bridge_threat",0,{"hint":"手中兵刃无法够到承重点，需用机关弩"});return
 super._execute_command(actor,command)
 if command.skill_id=="LX_A03":actor.jiugong_through=state.round;actor.jiugong_speed_round=int(state.round)+1

func _scene_action() -> void:
 var o: Dictionary=state.objective;var action: Dictionary=o.pending
 if action.is_empty():return
 if state.encounter.kind=="fire_ox":
  var i:=int(o.hazard_index);var correct: Vector2i=CENTERS[i]+Vector2i(32*SAFE[i],0)
  if o.position==[correct.x,correct.y]:o.covered.append(i);o.hazard_index+=1;_event("convoy_covered",HERO,"convoy",i+1)
  else:
   if i not in o.mistakes:o.mistakes.append(i);_lose_hp(actor_by_id(HERO),actor_by_id(HERO),30)
   _event("hazard_wrong_position",HERO,"convoy",0,{"hint":"火牛冲过粮车，须到标示避险侧掩护"})
  return
 match action.action_id:
  "free_axue":o.snow_freed=true;_event("snow_unbound",HERO,AXUE)
  "handoff_haiya":o.haiya_handed=true;_event("haiya_handed_over",HERO,"haiya")
  "calibrate":
   if action.mark==MARKS[action.value]:o.calibrated=action.value;_event("crossbow_calibrated",HERO,action.value)
   else:o.calibrated="";_event("wrong_mark",HERO,action.value,0,{"hint":"A左斜梁 / B中横木 / C右绞盘"})
  "fire":
   if o.calibrated==action.value and int(o.supports[action.value])>0 and int(o.bolts)>0:
    var loss:=int(o.supports[action.value]);o.supports[action.value]=0;o.bolts-=1;o.calibrated=""
    actor_by_id("bridge_threat").hp-=loss
    _event("support_broken",HERO,action.value,loss,{"tag":"破器卸甲","mana_reward":0})
   else:_event("wrong_shot",HERO,action.value,0,{"hint":"先对准尚未断开的对应承重点；误射不耗弩矢"})

func _execute_intent(actor: Dictionary,intent: Dictionary) -> void:
 if actor.id==BOSS and state.objective.jin_repelled:intent.cancelled=true
 if intent.hits.is_empty() or intent.cancelled:intent.executed=true;return
 var evaded: Array=[]
 for member in state.actors:
  if member.team=="party" and member.get("ax_evade",false) and ("arrow_rain" in intent.tags or "environment_trap" in intent.tags):
   member.ax_evade_active=true;evaded.append(member)
 super._execute_intent(actor,intent)
 for member in evaded:member.ax_evade=false;member.ax_evade_active=false

func _break(source: Dictionary,target: Dictionary,intent: Dictionary) -> bool:
 if not super._break(source,target,intent):return false
 if int(state.objective.phase)==1 and int(state.objective.phase_round)%2==1 and "interrupt" in intent.tags:state.objective.suppressed[target.id]=int(state.round)+1
 return true

func _lose_hp(source: Dictionary,target: Dictionary,amount: int) -> int:
 if target.id==BOSS:
  var loss:=mini(maxi(0,int(target.hp)-1),amount);target.hp-=loss
  if int(target.hp)<=1400 and not state.objective.jin_repelled:
   state.objective.jin_repelled=true
   for intent in state.intents:
    if intent.actor_id==BOSS:intent.cancelled=true
   _event("jin_fei_repelled",source.id,BOSS,int(target.hp),{"alive":true})
  return loss
 return super._lose_hp(source,target,amount)

func _reduction(actor: Dictionary) -> float:
 return maxf(super._reduction(actor),maxf(.35 if actor.get("ax_evade_active",false) else 0.0,.2 if int(actor.get("jiugong_through",-1))>=int(state.round) else 0.0))

func _speed(actor: Dictionary,modifier: int,skill: Dictionary={}) -> int:
 return super._speed(actor,modifier,skill)+(12 if int(actor.get("ax_speed_round",-1))==int(state.round) else 0)+(10 if int(actor.get("jiugong_speed_round",-1))==int(state.round) else 0)

func _after_preparation(actor: Dictionary,skill: Dictionary) -> void:
 if skill.kind=="ax_evade":
  for member in state.actors:
   if member.team=="party" and alive(member):member.ax_evade=true;member.ax_speed_round=int(state.round)+1

func _check_outcome() -> void:
 if state.outcome!="":return
 var o: Dictionary=state.objective
 if not alive(actor_by_id(HERO)) or (int(o.phase)==2 and not alive(actor_by_id(AXUE))):o.failure="participant_exhausted";state.outcome="defeat";return
 if state.mode!="round_end":return
 if state.encounter.kind=="fire_ox":
  if o.covered.size()==3:state.outcome="victory"
  return
 if int(o.phase)==1:
  if o.jin_repelled and o.snow_freed and o.haiya_handed:_transition()
 else:
  o.completed_rounds+=1;o.evacuation=mini(5,int(o.completed_rounds))
  o.escort_position=[[384,352,320,288,240][int(o.evacuation)-1],240]
  o.haiya_safe=int(o.evacuation)>=5;o.shifutong_safe=o.haiya_safe
  if int(o.completed_rounds)>=5 and o.haiya_safe and o.shifutong_safe and o.supports.A==0 and o.supports.B==0 and o.supports.C==0:
   o.withdraw_path=[]
   for x in range(416,223,-16):o.withdraw_path.append([x,240])
   _event("controlled_last_rope_withdrawal",HERO,AXUE,0,{"path":o.withdraw_path.duplicate(true),"before_bridge_collapse":true})
   state.outcome="victory";_event("bridge_escape_complete")

func _transition() -> void:
 var o: Dictionary=state.objective
 o.phase=2;o.phase_start=int(state.round)+1;o.phase_round=0;o.completed_rounds=0
 var a:=snow_source.duplicate(true)
 a.merge({"team":"party","controllable":true,"ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":false},true)
 a.skills=["normal_attack","self_guard","guard_ally","AX_S01","AX_S02"]
 state.actors.append(a)
 for enemy in state.actors:
  if enemy.team=="enemy":enemy["withdrawn"]=true
 # Structure is an untargetable environmental source, never a living/healable party member.
 state.actors.append({"id":"bridge_threat","name":"横木与三承重点","team":"enemy","hp":2800,"max_hp":2800,"mp":0,"max_mp":0,"atk":145,"def":80,"spd":35,"rotation":[{"name":"预告","target_id":HERO,"hits":[],"tags":[]}],"ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":true})
 o.phase_entry={"hero_hp":actor_by_id(HERO).hp,"hero_mp":actor_by_id(HERO).mp,"snow_hp":a.hp,"snow_mp":a.mp}
 _event("phase_changed",HERO,AXUE,2,o.phase_entry)

func get_view() -> Dictionary:
 var v:=snapshot();v.skill_data=content.skills.duplicate(true);v.skill_costs={};v.legal_commands={}
 v.objective.available_actions=[]
 v.objective.summary="新开交锋真气依规则补满；转阶段不补，阿雪沿用实际真气。靳飞压退而非杀死，随后两次解救。断索每处校准、射击各一行动，三处全断且海牙/史富通至少五完整轮到岸才能脱困。"
 if state.encounter.kind=="fire_ox":v.objective.summary="火牛依次向右、左、右冲来；沿路行走至避险侧（左、右、左），掩护同袍撤出。每处首次失误扣30血，总最多90；必须实际纠正。赵山剑伤为固定剧情。"
 for actor in state.actors:
  if actor.team!="party":continue
  v.skill_costs[actor.id]={};v.legal_commands[actor.id]=[]
  for skill in actor.skills:
   if not content.skills.has(skill):continue
   v.skill_costs[actor.id][skill]=skill_cost(actor,content.skills[skill])
   for target in state.actors:
    if validate_command(actor.id,skill,target.id)=="":v.legal_commands[actor.id].append({"skill_id":skill,"target_id":target.id})
 for id in ["cancel","free_axue","handoff_haiya","cover","retreat"]:_choice(v,{"actor_id":HERO,"action_id":id},{"cancel":"取消编排","free_axue":"解开阿雪拘束","handoff_haiya":"开锁并把海牙交史富通","cover":"掩护友军撤出","retreat":"退战（可从本阶段重试）"}[id])
 for d in ["left","right","up","down"]:_choice(v,{"actor_id":HERO,"action_id":"move","value":d},"移步"+{"left":"左","right":"右","up":"上","down":"下"}[d])
 for support in SUPPORTS:
  for mark in MARKS.values():_choice(v,{"actor_id":HERO,"action_id":"calibrate","value":support,"mark":mark},"校准%s · %s"%[support,{"left_beam":"左斜梁","crossbeam":"中横木","right_winch":"右绞盘"}[mark]])
  _choice(v,{"actor_id":HERO,"action_id":"fire","value":support},"扳机射断 "+support)
 var p: Array=state.objective.position if state.encounter.kind=="fire_ox" else ([224,240] if state.outcome=="victory" else [416,240])
 v.world_state={"map_id":"map_ch07_funiu_convoy_pass" if state.encounter.kind=="fire_ox" else ("map_ch07_yunxing_prison" if int(state.objective.phase)==1 else "map_ch07_yunxing_chain_bridge"),"control_actor_id":HERO,"objective_id":state.encounter.id,"convoy_burning":state.encounter.kind=="fire_ox","player_position":p,"actor_positions":{HERO:p},"visible_actor_ids":[HERO],"target_position":p}
 if state.encounter.kind=="b04":
  if int(state.objective.phase)==1:
   v.world_state.actor_positions.merge({AXUE:[304,192],"npc_haiya":[448,192],"npc_jin_fei":[480,224],"npc_shi_futong":[400,256],"npc_ch07_archer_left":[384,192],"npc_ch07_archer_right":[512,192]})
  else:
   v.world_state.actor_positions.merge({AXUE:[p[0],256],"npc_haiya":state.objective.escort_position.duplicate(),"npc_shi_futong":state.objective.escort_position.duplicate(),"npc_jin_fei":[480,240],"char_yun_shu":[512,224]})
  v.world_state["actor_postures"]={AXUE:"standing" if state.objective.snow_freed else "bound","npc_haiya":"wounded" if state.objective.haiya_handed else "bound"}
  v.world_state["support_states"]={"A":state.objective.supports.A==0,"B":state.objective.supports.B==0,"C":state.objective.supports.C==0}
  v.world_state.visible_actor_ids=v.world_state.actor_positions.keys()
  v.world_state["bridge_severed"]=state.outcome=="victory"
  v.world_state["controlled_withdrawal"]=state.objective.withdraw_path.duplicate(true)
 if state.encounter.kind=="fire_ox" and int(state.objective.hazard_index)<3:
  var q: Vector2i=CENTERS[int(state.objective.hazard_index)]+Vector2i(32*SAFE[int(state.objective.hazard_index)],0);v.world_state.target_position=[q.x,q.y]
 return v

func _choice(view: Dictionary,action: Dictionary,label: String) -> void:
 if input_error(action)!="":return
 action.revision=state.revision;view.objective.available_actions.append({"label":label,"input":action})

func alive(actor: Dictionary) -> bool:
 if not actor.is_empty() and actor.get("id")=="bridge_threat":return true
 return super.alive(actor)

func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
 var result:=super._branch(source,target,raw,channel,action_id)
 if raw>0 and int(target.get("jiugong_through",-1))>=int(state.round):target.jiugong_through=-1
 return result

func _counter(actor: Dictionary,target: Dictionary,induced: bool) -> void:
 var before:=int(actor.counter_count)
 super._counter(actor,target,induced)
 if int(actor.counter_count)==before:return
 var rank:=int(actor.get("skill_ranks",{}).get("LX_A02",actor.get("skill_ranks",{}).get("sancai_counter",1)))
 if actor.id==HERO and rank>=2 and induced:
  var gain:=mini(int(actor.max_hp)-int(actor.hp),int(floor(float(actor.max_hp)*0.02)))
  actor.hp+=gain;_event("sancai_heal",actor.id,actor.id,gain)
 if actor.id==HERO and rank>=3 and alive(target):_apply_status(target,"attack_down",0.15,2)
