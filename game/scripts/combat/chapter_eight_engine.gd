class_name ChapterEightCombatEngine
extends "res://scripts/combat/combat_engine.gd"
const HERO := "char_liang_xiao"
const HUBS := {"left_gear":1067,"center_pin":1067,"right_string":1066}
const DATA_PATH := "res://data/chapter_eight_encounters.json"
var entry_error := ""

func _init(r: Dictionary,c: Dictionary) -> void:
 super(r,c)
 content.skills.merge(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)).skills,true)

func start(encounter: Dictionary,party: Array) -> void:
 entry_error=""
 var canonical: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)).encounters.get(encounter.get("id",""),{})
 if canonical.is_empty() or (encounter.has("context") and not encounter.context is Dictionary):entry_error="invalid_encounter"
 else:
  for key in canonical:
   if encounter.get(key)!=canonical[key]:entry_error="invalid_encounter"
  for key in encounter:
   if key not in canonical and key!="context":entry_error="invalid_encounter"
 if party.size()!=1 or not party[0] is Dictionary or party[0].get("id")!=HERO:entry_error="solo_hero_required"
 if entry_error=="":
  var a: Dictionary=party[0]
  for key in ["hp","mp","max_hp","max_mp","atk","def","spd"]:
   if not _whole(a.get(key),1 if key in ["hp","max_hp"] else 0):entry_error="invalid_actor_number"
  if not a.get("skills") is Array or not a.get("passives",[]) is Array or a.get("passives",[]).size()>2:entry_error="invalid_slots"
  else:
   var seen: Array=[]
   for p in a.get("passives",[]):
    if not p is String or p not in ["LX_P01","LX_P02","LX_P03"] or p in seen or (not a.get("acquired_passives",a.get("passives",[])) is Array or p not in a.get("acquired_passives",a.get("passives",[]))):entry_error="invalid_slots"
    seen.append(p)
  if a.get("team")!="party" or not a.get("internal_skill","") is String or not a.get("skill_ranks",{}) is Dictionary or not a.get("acquired_passives",[]) is Array:entry_error="invalid_metadata"
  if a.get("skills") is Array:
   for skill in a.skills:
    if not skill is String or not content.skills.has(skill):entry_error="invalid_skill"
  if a.get("skill_ranks",{}) is Dictionary:
   for rank in a.get("skill_ranks",{}).values():
    if not _whole(rank,1,3):entry_error="invalid_rank"
  if a.has("controllable") and not a.controllable is bool:entry_error="invalid_control"
  if entry_error=="" and (a.hp>a.max_hp or a.mp>a.max_mp):entry_error="invalid_resources"
 if not _whole(encounter.get("level")) or encounter.get("level")!=(34 if encounter.get("kind")=="river_duel" else 38):entry_error="invalid_calibration"
 if encounter.get("kind") not in ["river_duel","b05"] or encounter.get("id")=="enc_ch08_civilian_escort":entry_error="requires_campaign_resume"
 if entry_error!="":
  state={"outcome":"invalid","mode":"finished","actors":[],"commands":{},"revision":0,"round":1,"intents":[],"events":[],"encounter":encounter,"objective":{"failure":entry_error}};return
 var clean: Array=party.duplicate(true)
 for skill in ["ch08_action","ch08_escort"]:
  if skill not in clean[0].skills:clean[0].skills.append(skill)
 if clean[0].get("internal_skill","")=="LX_N01":clean[0].atk=int(floor(float(clean[0].atk)*1.08));clean[0].spd+=5
 super.start(encounter,clean)
 checkpoint=snapshot()

func _initial_objective() -> Dictionary:
 var batches: Array=[]
 for i in range(3):batches.append({"id":"batch_%d"%(i+1),"position":[0,i],"path":[[0,i]],"route":[[0,i],[1,i],[2,i],[3,i]],"protected":false,"disarmed":false,"safe":false})
 return {"phase":"river_duel" if state.encounter.kind=="river_duel" else "phase_one","phase_start":1,"phase_round":1,"pending":{},"failure":"","hubs":HUBS.duplicate(),"calibrated":"","bolts":3,"suppressed_round":-1,"river_gaps":0,"river_pending_gap":false,"river_cover":false,"river_position":[0,0],"river_path":[[0,0]],"pressure":3800,"batch_index":0,"batches":batches,"p03_stacks":0,"p03_events":[],"medicine_uses":0,"fire_confirmation":{},"l04":{},"preparation_receipts":state.encounter.get("context",{}).get("preparation_receipts",[]),"battle_id":state.encounter.battle_id}

func begin_round() -> void:
 if state.mode not in ["new","round_end"] or state.outcome!="":return
 if not state.has("objective"):state.objective=_initial_objective()
 super.begin_round()
 var o: Dictionary=state.objective
 o.phase_round=int(state.round)-int(o.phase_start)+1;o.pending={}
 var h:=actor_by_id(HERO)
 if h.get("internal_skill","")=="LX_N01":gain_mana(h,3,"mirror_breath")
 state.intents=[]
 var n:=beat()
 if o.phase=="river_duel":
  _intent("river_yunshu","长篙蓄势：本轮借矢石/飞星，或下轮三才" if n==1 else "迫台点刺 1.60×135（可三才诱偏）",[] if n==1 else [1.6],["interrupt"] if n==1 else ["induce"])
 elif o.phase=="phase_one":
  _intent("ballista",["装填（无伤害）","拉满弦蓄势（本轮破器可取消下轮）","巨箭 3.00×165"][n-1],[] if n<3 or o.suppressed_round==state.round else [3.0],[])
 elif o.phase=="phase_two":
  _intent("routed_pressure",["乱兵逼近：引当前批过街（无伤害）","溃军乱斩 1.50×180：须全拦截护民","凶徒追击梁 1.50×180：三才引偏卸刃"][n-1],[] if n==1 else [1.5],["induce"] if n==3 and o.batches[o.batch_index].protected else [])

func beat() -> int:return (int(state.objective.phase_round)-1)%(2 if state.objective.phase=="river_duel" else 3)+1
func _intent(id: String,label: String,hits: Array,tags: Array) -> void:
 state.intents.append({"actor_id":id,"intent_id":"%s:%d"%[id,state.round],"name":label,"target_id":HERO,"hits":hits,"tags":tags,"executed":false,"cancelled":false})

func input_error(a: Dictionary) -> String:
 if state.mode!="commands" or state.outcome!="":return "not_accepting_input"
 for k in a:
  if k not in ["actor_id","action_id","value","revision"]:return "unexpected_field"
 if not a.get("actor_id") is String or not a.get("action_id") is String or a.actor_id!=HERO:return "invalid_input"
 if a.has("revision") and (not a.revision is int or a.revision!=state.revision):return "invalid_revision"
 var o: Dictionary=state.objective
 if a.action_id in ["cancel","retreat"]:return "" if not a.has("value") else "unexpected_value"
 if o.phase=="phase_one":
  if not a.get("value") is String or a.value not in HUBS or o.hubs[a.value]==0:return "invalid_hub"
  if a.action_id=="inspect_hub":return ""
  if a.action_id=="release_calibrated_shot":
   if o.calibrated!=a.value:return "calibrate_first"
   if _protected(actor_by_id("ballista")):return "protection_wait"
   return ""
 elif not a.has("value"):
  if o.phase=="river_duel" and a.action_id=="borrow_cover" and beat()==1:return ""
  if o.phase=="phase_two":
   var b: Dictionary=o.batches[o.batch_index]
   if a.action_id=="lead_batch" and beat()==1 and not b.safe:return ""
   if a.action_id=="escort_intercept" and beat()==2 and b.position[0]==2:return ""
 return "invalid_action"

func apply_input(a: Variant) -> Dictionary:
 if not a is Dictionary:return {"accepted":false,"error":"invalid_input_type"}
 var error:=input_error(a)
 if error!="":return {"accepted":false,"error":error}
 if a.action_id=="cancel":state.commands.erase(HERO);state.objective.pending={}
 elif a.action_id=="retreat":state.outcome="defeat";state.mode="finished";state.objective.failure="retreated"
 else:
  state.objective.pending=a.duplicate(true);state.objective.pending.erase("revision")
  state.commands[HERO]={"actor_id":HERO,"skill_id":"ch08_escort" if a.action_id=="escort_intercept" else "ch08_action","target_id":HERO}
 state.revision+=1
 return {"accepted":true}

func validate_command(actor_id: String,skill_id: String,target_id: String) -> String:
 if skill_id in ["ch08_action","ch08_escort"]:return "use_scene_input"
 if state.objective.phase=="phase_one" and skill_id not in ["self_guard","observe"]:return "structure_out_of_reach"
 if state.objective.phase=="phase_two" and skill_id not in ["normal_attack","self_guard","observe","sancai_counter"]:return "scene_target_incompatible"
 return super.validate_command(actor_id,skill_id,target_id)

func set_command(actor_id: Variant,skill_id: Variant,target_id: Variant,revision: Variant=-1) -> String:
 if not actor_id is String or not skill_id is String or not target_id is String:return "invalid_command_type"
 if not revision is int or revision < -1:return "invalid_revision_type"
 var error:=super.set_command(actor_id,skill_id,target_id,revision)
 if error=="":state.objective.pending={}
 return error

func _execute_command(actor: Dictionary,command: Dictionary) -> void:
 if command.skill_id=="ch08_action":_scene_action();return
 if state.objective.phase=="phase_two" and command.skill_id=="normal_attack":_event("narrative_feint",HERO,"routed_pressure");return
 super._execute_command(actor,command)
 if command.skill_id=="LX_A03":actor.jiugong_through=state.round;actor.jiugong_speed_round=int(state.round)+1

func _scene_action() -> void:
 var o: Dictionary=state.objective;var a: Dictionary=o.pending;var h:=actor_by_id(HERO)
 match a.action_id:
  "borrow_cover":o.river_cover=true;_event("cover_reached",HERO)
  "inspect_hub":o.calibrated=a.value;_event("hub_inspected",HERO,a.value)
  "release_calibrated_shot":
   var loss:=int(o.hubs[a.value]);o.hubs[a.value]=0;o.bolts-=1;o.calibrated=""
   var target:=actor_by_id("ballista");target.hp-=loss;target.last_break=state.round;target.protected_through=int(state.round)+1
   if beat() in [2,3]:
    o.suppressed_round=int(state.round)+(1 if beat()==2 else 0)
    for intent in state.intents:intent.cancelled=true
   _event("break_disarm",HERO,a.value,loss,{"mana_reward":0});_p03("hub:"+a.value)
  "lead_batch":
   var b: Dictionary=o.batches[o.batch_index]
   while int(b.position[0])<2:
    b.position=[int(b.position[0])+1,int(o.batch_index)];b.path.append(b.position.duplicate())
   _event("batch_led",HERO,b.id)
  "escort_intercept":
   h.stance={"kind":"escort_intercept","target_id":HERO,"tokens":1};gain_mana(h,int(rules.mana.guard_gain),"guard")
   o.batches[o.batch_index].protected=true;_event("escort_prepared",HERO,o.batches[o.batch_index].id)

func _execute_intent(actor: Dictionary,intent: Dictionary) -> void:
 var o: Dictionary=state.objective
 if intent.cancelled or intent.hits.is_empty():intent.executed=true;return
 if o.phase=="river_duel" and beat()==2 and (o.river_cover or o.river_pending_gap):
  o.river_pending_gap=true;intent.executed=true;_event("river_missed",actor.id,HERO);return
 if o.phase=="phase_two" and beat()==2:
  var b: Dictionary=o.batches[o.batch_index]
  if b.position[0]==2 and o.pending.get("action_id")!="escort_intercept":o.failure="escort_retry";state.outcome="defeat";return
  super._execute_intent(actor,intent)
  if b.position[0]==2 and alive(actor_by_id(HERO)):gain_mana(actor_by_id(HERO),int(rules.mana.successful_guard_gain),"successful_guard")
  return
 super._execute_intent(actor,intent)

func _break(source: Dictionary,target: Dictionary,intent: Dictionary) -> bool:
 if not super._break(source,target,intent):return false
 if state.objective.phase=="river_duel":state.objective.river_pending_gap=true
 if "interrupt" in intent.tags:_p03("interrupt:"+str(intent.intent_id))
 return true

func _p03(id: String) -> void:
 var o: Dictionary=state.objective
 if "LX_P03" not in actor_by_id(HERO).get("passives",[]) or id in o.p03_events:return
 o.p03_events.append(id);o.p03_stacks=mini(3,int(o.p03_stacks)+1)
 _event("p03_stack",HERO,"",o.p03_stacks,{"break_id":id})

func _counter(actor: Dictionary,target: Dictionary,induced: bool) -> void:
 var count:=int(actor.counter_count)
 super._counter(actor,target,induced)
 if int(actor.counter_count)==count:return
 if induced and int(actor.get("skill_ranks",{}).get("LX_A02",1))>=2:
  var heal:=mini(int(actor.max_hp)-int(actor.hp),int(floor(float(actor.max_hp)*.02)));actor.hp+=heal;_event("sancai_heal",HERO,HERO,heal)
 if int(actor.get("skill_ranks",{}).get("LX_A02",1))>=3:_apply_status(target,"attack_down",.15,2)
 if induced and state.objective.phase=="phase_two" and beat()==3:
  var o: Dictionary=state.objective;var b: Dictionary=o.batches[o.batch_index]
  if b.protected and not b.disarmed:
   b.disarmed=true;b.safe=true;b.position=[3,int(o.batch_index)];b.path.append(b.position.duplicate())
   var loss: int=[1267,1267,1266][o.batch_index];o.pressure-=loss;o.batch_index+=1
   _event("pressure_disarmed",HERO,b.id,loss,{"tag":"induce","entity_damage":false})

func _damage_action(source: Dictionary,target: Dictionary,multiplier: float,aoe: bool,channel: String,action_id: String,guard: Dictionary={}) -> void:
 if target.id=="routed_pressure":return
 var old_statuses: Array=source.statuses.duplicate(true)
 var bonus: float=float(state.objective.p03_stacks)*.05 if source.id==HERO else 0.0
 if bonus>_status_value(source,"attack_up"):_apply_status(source,"attack_up",bonus,1)
 var category:=0.0
 if source.id==HERO and "LX_P03" in source.get("passives",[]):
  for tag in target.get("tags",[]):
   if tag in ["mechanism","formation","heavy_armor","机关","阵法","重甲"]:category=.25
 # Same category takes the maximum, never repeated for multiple tags.
 if source.id==HERO and action_id=="LX_A03" and int(source.get("skill_ranks",{}).get("LX_A03",1))>=2:
  for tag in target.get("tags",[]):
   if tag in ["mechanism","formation","机关","阵法"]:category=maxf(category,.25)
 super._damage_action(source,target,multiplier*(1.0+minf(.5,category)),aoe,channel,action_id,guard)
 source.statuses=old_statuses

func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
 var original: int=target.def
 if target.id==HERO:target.def=int(floor(float(original)*(1.0+maxf(float(state.objective.p03_stacks)*.05,_status_value(target,"defense_up")))))
 var loss:=super._branch(source,target,raw,channel,action_id);target.def=original
 if raw>0 and int(target.get("jiugong_through",-1))>=int(state.round):target.jiugong_through=-1
 return loss

func _lose_hp(source: Dictionary,target: Dictionary,amount: int) -> int:
 if target.id=="river_yunshu":
  var loss:=mini(maxi(0,int(target.hp)-1),amount);target.hp-=loss;return loss
 if target.id=="routed_pressure":return 0
 return super._lose_hp(source,target,amount)
func alive(actor: Dictionary) -> bool:
 if actor.get("id")=="routed_pressure":return true
 return super.alive(actor)

func _check_outcome() -> void:
 if state.outcome!="":return
 if not alive(actor_by_id(HERO)):state.outcome="defeat";state.objective.failure="hero_exhausted";return
 if state.mode!="round_end":return
 var o: Dictionary=state.objective
 if o.phase=="river_duel" and beat()==2:
  if o.river_pending_gap:
   o.river_gaps+=1;o.river_position=[int(o.river_gaps),0];o.river_path.append(o.river_position.duplicate());_event("river_gap",HERO,"river_yunshu",o.river_gaps)
  o.river_pending_gap=false;o.river_cover=false
  if o.river_gaps==3:state.outcome="victory";_event("river_withdraw_to_ballista",HERO)
 elif o.phase=="phase_one" and o.bolts==0:o.phase="intermission";state.outcome="victory";_event("campaign_paused")
 elif o.phase=="phase_two":
  if o.batch_index==3 and o.pressure==0:o.phase="completed";state.outcome="victory";o.p03_stacks=0;_event("escort_complete")
  elif beat()==3:o.batches[o.batch_index].protected=false

func sync_campaign_actor(actor: Dictionary) -> bool:
 if state.objective.phase!="intermission" or actor.get("id",HERO)!=HERO:return false
 for k in ["hp","mp","max_hp","max_mp","atk","def","spd"]:
  if not _whole(actor.get(k)):return false
 if actor.hp>actor.max_hp or actor.mp>actor.max_mp:return false
 var h:=actor_by_id(HERO)
 for k in ["hp","mp","max_hp","max_mp","atk","def","spd","level","xp"]:
  if actor.has(k):h[k]=actor[k]
 if h.get("internal_skill","")=="LX_N01":h.atk=int(floor(float(h.atk)*1.08));h.spd+=5
 state.revision+=1;return true

func resume_phase_two(context: Dictionary) -> bool:
 if state.objective.phase!="intermission" or (not context.get("fire_confirmed") is bool or not context.fire_confirmed):return false
 var o: Dictionary=state.objective
 o.phase="phase_two";o.phase_start=state.round;o.phase_round=1;o.fire_confirmation=context.duplicate(true)
 o.l04=context.get("l04",{}).duplicate(true)
 var threat:=actor_by_id("ballista").duplicate(true)
 threat.id="routed_pressure";threat.name="乱兵阵势（场景压力，非生命）";threat.erase("hp");threat.erase("max_hp")
 threat.atk=180;threat.def=105;threat.spd=36;threat.mp=160;threat.max_mp=160;threat.last_break=-1;threat.protected_through=-1;threat.vulnerable_through=-1;threat.statuses=[]
 state.actors=[actor_by_id(HERO),threat];state.outcome="";state.mode="round_end"
 state.encounter.id="enc_ch08_civilian_escort";state.encounter.result="escort_verified";state.encounter.name="乱军护民"
 begin_round();checkpoint=snapshot();return true

func get_view() -> Dictionary:
 var v:=snapshot();v.skill_data=content.skills.duplicate(true);v.skill_costs={HERO:{}};v.legal_commands={HERO:[]};v.objective.available_actions=[]
 for skill in actor_by_id(HERO).get("skills",[]):
  if not content.skills.has(skill):continue
  v.skill_costs[HERO][skill]=skill_cost(actor_by_id(HERO),content.skills[skill])
  for a in state.actors:
   if validate_command(HERO,skill,a.id)=="":v.legal_commands[HERO].append({"skill_id":skill,"target_id":a.id})
 for id in ["borrow_cover","lead_batch","escort_intercept","cancel","retreat"]:_choice(v,{"actor_id":HERO,"action_id":id},id)
 for hub in HUBS:
  for action in ["inspect_hub","release_calibrated_shot"]:_choice(v,{"actor_id":HERO,"action_id":action,"value":hub},action+":"+hub)
 var o: Dictionary=state.objective
 var positions: Dictionary={};var map_id: String;var player: Array
 if o.phase=="river_duel":
  map_id="map_ch08_island_platform";player=[288+16*int(o.river_position[0]),224]
  positions={HERO:player,"char_yun_shu":[368,224]}
 elif o.phase in ["phase_one","intermission"]:
  map_id="map_ch08_xiangyang_north_battery";player=[96,240];positions={HERO:player}
 else:
  map_id="map_ch08_xiangyang_fire_street";player=[144,240];positions={HERO:player}
  for b in o.batches:positions[b.id]=[160+16*int(b.position[0]),224+16*int(b.position[1])]
 v.world_state={"map_id":map_id,"control_actor_id":HERO,"objective_id":state.encounter.id,"player_position":player,"actor_positions":positions,"visible_actor_ids":positions.keys(),"battle_phase":o.phase,"hubs":o.hubs.duplicate(),"hub_positions":{"left_gear":[296,144],"center_pin":[320,144],"right_string":[344,144]},"pressure":o.pressure,"batches":[]}
 for b in o.batches:
  var projected: Dictionary=b.duplicate(true)
  projected.position=[160+16*int(b.position[0]),224+16*int(b.position[1])]
  projected.route=[];projected.path=[]
  for point in b.route:projected.route.append([160+16*int(point[0]),224+16*int(point[1])])
  for point in b.path:projected.path.append([160+16*int(point[0]),224+16*int(point[1])])
  v.world_state.batches.append(projected)
 v.objective.summary="护送三批、三才引偏卸刃；普通攻击不能消除混乱度，也不回气。" if state.objective.phase in ["phase_two","completed"] else "同一战役：中场不补真气、不重置技能、药品或格物层。"
 return v
func _choice(v: Dictionary,a: Dictionary,label: String) -> void:
 if input_error(a)=="":a.revision=state.revision;v.objective.available_actions.append({"label":label,"input":a})

func _reduction(actor: Dictionary) -> float:
 return maxf(super._reduction(actor),maxf(.25 if actor.stance.get("kind")=="escort_intercept" else 0.0,.2 if int(actor.get("jiugong_through",-1))>=int(state.round) else 0.0))
func _speed(actor: Dictionary,modifier: int,skill: Dictionary={}) -> int:
 return super._speed(actor,modifier,skill)+(10 if int(actor.get("jiugong_speed_round",-1))==int(state.round) else 0)

func _after_preparation(_actor: Dictionary,skill: Dictionary) -> void:
 if skill.kind=="escort_intercept":_scene_action()

func sync_campaign_context(context: Dictionary) -> bool:
 if state.objective.phase!="intermission" or context.keys().any(func(k):return k not in ["l04","fire_confirmation"]):return false
 if JSON.stringify(context).length()>8192:return false
 for key in context:
  if not context[key] is Dictionary:return false
 if context.has("l04"):state.objective.l04=context.l04.duplicate(true)
 if context.has("fire_confirmation"):state.objective.fire_confirmation=context.fire_confirmation.duplicate(true)
 return true
