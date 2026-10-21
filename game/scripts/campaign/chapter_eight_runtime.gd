class_name ChapterEightRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_eight_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_eight_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_eight_world_actions.gd"
const RECONSIDER_EVENTS=[]
const BATTLE_SCRIPT="res://scripts/combat/chapter_eight_encounter.gd"
var paused_session:RefCounted
func _init(campaign:RefCounted,id:int=8) -> void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={"L04":{"status":"undiscovered","disposition":"open"}}
 state["inherited_ch07_optional"]=previous.optional.duplicate(true)
 state.merge({"leader_id":Party.HERO,"story_restriction":"","frozen_contexts":{},"last_battle_panels":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"exploration_unlocks":previous.get("exploration_unlocks",[]).duplicate(),"inherited_optional":previous.get("inherited_optional",{}).duplicate(true),"inherited_ch04_optional":previous.get("inherited_ch04_optional",{}).duplicate(true),"inherited_choices":previous.choices.duplicate(true)})
 state.merge({"campaign_battle_snapshot":{},"rest_receipts":[],"fire_confirmation":{},"loadout_records":[]})
 var hero:Dictionary=owner().actors[Party.HERO]
 hero["learned_passives"]=hero.get("passives",[]).duplicate()
 hero["equipped_passives"]=hero.get("passives",[]).slice(0,2)
 for node in content.scenes:
  node.choices=[]
  for event in runtime.scenes[node.id]:
   if event.op=="choice":node.choices.append_array(content.choice_groups[event.group].options.duplicate(true))
static func can_enter(campaign:RefCounted) -> bool:
 if campaign.active_chapter!=7 or not campaign.state.finished:return false
 for who in [Party.HERO,Party.LIU,Transactions.A]:
  if not campaign.actors.get(who) is Dictionary:return false
 return int(campaign.actors[Party.HERO].xp)>=11220 and int(campaign.actors[Party.HERO].hp)>0 and campaign.actors[Transactions.A].get("status")=="recovering_in_camp"
func _choice_key(event:Dictionary) -> String:return event.get("choice_key",event.get("group",scene().id))
func available_choices() -> Array:
 if current_event().get("op")!="choice":return []
 var result:Array=content.choice_groups[current_event().group].options.duplicate(true)
 for choice in result:choice.text=choice.label;choice.effects=[]
 return result
func selected_choice() -> Dictionary:
 var group:String=current_event().get("group","")
 if group.is_empty() and current_event().get("op")=="branch_feedback":group=str(current_event().id).trim_suffix("_feedback")
 var chosen:String=state.choices.get(group,"")
 for choice in content.choice_groups.get(group,{}).get("options",[]):
  if choice.id==chosen:return choice
 return {}
func presentation() -> Array:
 var event:=current_event()
 if event.get("op")=="branch_feedback":return [{"speaker":"旁白","kind":"stage","text":selected_choice().get("feedback","")}]
 if event.get("op")=="dialogue":
  var lines:Array=[]
  for id in event.get("refs",[]):lines.append(content.dialogue_registry[id].duplicate(true))
  return _format(lines)
 return super.presentation()
func _award(id:String,amount:int) -> void:
 if not Party.award(owner().actors,owner().reward_ledger,id,amount):return
 state.xp=int(owner().actors[Party.HERO].xp)
 _sync_intermission()
func _paused_session() -> RefCounted:
 if paused_session!=null and Canonical.equivalent(paused_session.snapshot(),state.campaign_battle_snapshot):return paused_session
 paused_session=load(BATTLE_SCRIPT).from_snapshot(state.campaign_battle_snapshot,owner().rules,owner().combat)
 return paused_session
func _sync_intermission() -> bool:
 if state.campaign_battle_snapshot.is_empty() or owner()._restoring_summary:return true
 var session:RefCounted=_paused_session()
 if session==null:return false
 if session.snapshot().get("state",{}).get("objective",{}).get("phase","")!="intermission":return true
 if not session.sync_campaign_actor(owner().actors[Party.HERO]):return false
 state.campaign_battle_snapshot=session.snapshot()
 return true
func _sync_campaign_context() -> bool:
 if state.campaign_battle_snapshot.is_empty() or owner()._restoring_summary:return true
 var session:RefCounted=_paused_session()
 if session==null:return false
 if session.snapshot().state.objective.phase!="intermission":return true
 var side:Dictionary=state.optional.L04.duplicate(true)
 var progress:Dictionary=state.puzzle_records.get("L04:00",{}).get("state",{})
 side["progress"]={}
 for key in ["method","observed","rescued","supporting","retreating","carrying","sand","fire_out","stone_open","pad_ready","sheltered","talked","looters","position","control_actor_id"]:
  if progress.has(key):side.progress[key]=progress[key]
 if not session.sync_campaign_context({"l04":side,"fire_confirmation":state.fire_confirmation.duplicate(true)}):return false
 state.campaign_battle_snapshot=session.snapshot()
 return true
func _transactions_valid(event:Dictionary) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true)
 var items:Dictionary=owner().items.duplicate(true)
 var target:Dictionary=state.duplicate(true)
 var world:Dictionary=owner().world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_eight_event":
   if effect.id in RECONSIDER_EVENTS and effect.id in target.semantic_commits:continue
   if not Transactions.apply(effect.id,actors,items,target,world):return false
 return true
func _effect(effect:Dictionary) -> void:
 if effect.op!="chapter_eight_event":super._effect(effect);return
 if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):
  push_error("Chapter eight transaction rejected: "+str(effect.id));return
 state.semantic_commits.append(effect.id)
 if effect.id=="ch08_fire_confirmed":_sync_campaign_context()
 if effect.id=="dam_ch08_submerged":_award("reward_mq08_dam_once",800)
 if effect.id=="cannon_ch08_calibration":_award("reward_mq08_cannon_once",800)
 if effect.id=="enc_ch08_civilian_escort":_award("reward_mq08_escort_once",500)
 if effect.id=="dlg_ch08_archive":
  state.objective_snapshot={};state.campaign_battle_snapshot={};state.last_battle_panels={}
  var endpoint:Array=maps[scene().map_id].spawn.duplicate()
  state.position=endpoint;state.path_progress={}
  owner().world_objects.ch08_spatial_state={"map_id":scene().map_id,"control_actor_id":Party.HERO,"player_position":endpoint,"actor_positions":{Party.HERO:endpoint.duplicate()},"carrying_pair":{}}
func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.all_of:
  if required not in state.receipts.get(current.id,[]):push_error("Missing chapter eight milestone");return
 if state.scope!="main":
  var side:String=state.scope
  if not Transactions.apply(side+"_archived",owner().actors,owner().items,state,owner().world_objects):push_error("Invalid side archive");return
  state.semantic_commits.append(side+"_archived");state.optional[side]={"status":"archived","disposition":"completed"}
  _memory(current.completion_memory);_award(current.reward_transaction,int(current.xp))
  state.scope="main";state.side_step=0;state.position=state.return_position.duplicate();state.path_progress={};state.leader_id=Party.HERO
  return
 state.completed.append(current.id)
 for reward in content.reward_transactions:
  if reward.get("after_scene")==current.id:_award(reward.id,int(reward.xp))
 if int(state.scene_index)==content.scenes.size()-1:
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
 else:
  var old_map:String=current.map_id
  state.scene_index+=1;state.step=0;state.path_progress={}
  if scene().map_id!=old_map:state.position=[-1.0,-1.0]
  if current.id=="ch08_fire_assault" and not owner()._restoring_summary:
   var resumed:RefCounted=load(BATTLE_SCRIPT).from_snapshot(state.campaign_battle_snapshot,owner().rules,owner().combat)
   if resumed==null or not resumed.resume_phase_two(puzzle_context(),current_token()):
    push_error("Chapter eight phase two checkpoint rejected");return
   state.campaign_battle_snapshot=resumed.snapshot()
func _puzzle_effects(_event:Dictionary,_proof:Dictionary) -> void:pass
func actor_panel(id:String) -> Dictionary:return owner().actors[id].duplicate(true)
func combat_party() -> Array:
 var actor:Dictionary=actor_panel(Party.HERO)
 var skills:Array=["normal_attack","self_guard","guard_ally","observe","sancai_counter"]
 for skill in actor.skills:
  if skill=="LX_A03" and skill not in skills:skills.append(skill)
 var ranks:Dictionary=actor.skill_ranks.duplicate(true);ranks.observe=int(actor.skill_ranks.get("LX_A01",1))
 return [{"id":Party.HERO,"name":"梁萧","team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":skills,"skill_ranks":ranks,"passives":actor.equipped_passives.duplicate(),"learned_passives":actor.learned_passives.duplicate(),"equipped_passives":actor.equipped_passives.duplicate(),"acquired_passives":actor.learned_passives.duplicate(),"internal_skill":actor.get("internal_skill",""),"controllable":true,"fixed_level":int(actor.level)}]
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 var actors:Dictionary=owner().actors.duplicate(true)
 for id in ["npc_ranya","npc_guo_shoujing"]:actors[id]={"id":id,"status":"present","kind":"scene_support"}
 return {"chapter":8,"current_token":current_token(),"revision":1,"phase":scene().id,"scope":scene().id,"scene_id":scene().id,"map_id":scene().map_id,"objective_id":current_event().get("id",""),"actors":actors,"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"inherited_choices":state.inherited_choices.duplicate(true),"knowledge":state.knowledge.duplicate(),"fixed_level":38,"completed_receipts":state.receipts.duplicate(true),"leader_id":Party.HERO,"control_actor_id":Party.HERO,"authorizations":state.semantic_commits.duplicate(),"rest_receipts":state.rest_receipts.duplicate(),"fire_confirmation":state.fire_confirmation.duplicate(true),"fire_confirmed":state.fire_confirmation.get("confirmed",false),"preparation_receipts":state.rest_receipts.duplicate(),"l04":state.optional.L04.duplicate(true)}
func make_objective_encounter() -> RefCounted:
 var session:RefCounted=_new_objective_encounter()
 if session==null:return null
 if not state.objective_snapshot.is_empty() and (not _battle_history_valid(state.objective_snapshot) or not session.restore(state.objective_snapshot)):return null
 return session
func _new_objective_encounter() -> RefCounted:
 if not ResourceLoader.exists(BATTLE_SCRIPT):return null
 if current_event().get("id")=="enc_ch08_civilian_escort":
  if state.campaign_battle_snapshot.is_empty() or not state.fire_confirmation.get("confirmed",false):return null
  var continued:RefCounted=load(BATTLE_SCRIPT).from_snapshot(state.campaign_battle_snapshot,owner().rules,owner().combat)
  if continued==null or continued.snapshot().state.objective.phase!="phase_two":return null
  return continued
 var config:Dictionary=Registry.read_json("chapter_eight_encounters").get("encounters",{}).get(current_event().get("id",""),{}).duplicate(true)
 if config.is_empty():return null
 config["context"]=puzzle_context()
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 if not session.engine.entry_error.is_empty():return null
 return session
func commit_archived_result(proof:Dictionary) -> bool:
 if not owner()._restoring_summary or not _transactions_valid(current_event()):return false
 return super.commit_archived_result(proof)
func puzzle_definition() -> Dictionary:
 return {"id":current_event().get("id",""),"attempt":current_token(),"guided":false,"world":current_event().get("op")=="world_puzzle"}
func make_puzzle() -> RefCounted:
 if current_event().get("op") not in ["puzzle","world_puzzle"]:return null
 var controller:String=current_event().get("controller_id",state.leader_id)
 if controller!=Party.HERO or not owner().actors.has(controller):return null
 if owner().actors[controller].get("status","present") not in ["active","present"] or int(owner().actors[controller].hp)<=0:return null
 if puzzle_session!=null:return puzzle_session
 var definition:=puzzle_definition()
 var path:String=WORLD_SCRIPT if definition.world else PUZZLE_SCRIPT
 if not ResourceLoader.exists(path):return null
 puzzle_session=load(path).new()
 if not puzzle_session.begin(definition.id,definition.attempt,puzzle_context()):puzzle_session=null;return null
 if state.puzzle_records.has(definition.attempt) and not puzzle_session.restore(state.puzzle_records[definition.attempt],puzzle_context()):puzzle_session=null
 return puzzle_session
func puzzle_input(token: String,action: Dictionary) -> Dictionary:
 if token!=current_token():return {"ok":false,"message":"操作已过期"}
 var session:=make_puzzle()
 if session==null:return {"ok":false,"message":"机关尚未登记"}
 var before:Dictionary=session.snapshot()
 var result:Dictionary=session.apply_input(action)
 if not Canonical.equivalent(before,session.snapshot()):
  if not state.frozen_contexts.has(token):state.frozen_contexts[token]=session.context.duplicate(true)
  _record("puzzle_input",{"action":action})
  state.puzzle_records[token]=session.snapshot();state.puzzle_snapshot=session.snapshot()
 if bool(session.get_view().get("state",{}).get("complete",false)):
  complete(token,{"receipts":session.get_receipts()})
 _sync_campaign_context()
 return result
func accept_objective(token:String,proof:Dictionary) -> bool:
 if token!=current_token() or current_event().get("op")!="objective_battle" or not proof.get("attempt_id") is String:return false
 return complete(token,proof)
func save_objective_checkpoint(session: RefCounted) -> bool:
 if current_event().get("op")!="objective_battle" or session==null:return false
 var candidate:Dictionary=session.snapshot()
 var verifier:RefCounted=_new_objective_encounter()
 if verifier==null or not _battle_history_valid(candidate) or not verifier.restore(candidate):return false
 state.objective_snapshot=candidate;return true
func _battle_history_valid(snapshot:Dictionary) -> bool:
 if not snapshot.get("history") is Array:return false
 var prefix:int=0
 if current_event().get("id")=="enc_ch08_civilian_escort":
  var trusted:Array=state.campaign_battle_snapshot.get("history",[])
  prefix=trusted.size()
  if snapshot.history.size()<prefix or not Canonical.equivalent(snapshot.history.slice(0,prefix),trusted):return false
 for record in snapshot.history.slice(prefix):
  if not record is Dictionary or record.get("op") not in ["input","command","resolve"]:return false
 return true
func _valid_action(event: Dictionary,proof: Dictionary) -> bool:
 if event.has("requires_leader") and state.leader_id!=event.requires_leader:return false
 var geometry:Dictionary=maps.get(scene().map_id,{}).get("actions",{}).get(event.id,{})
 if geometry.is_empty() or not proof.get("map_id") is String or proof.get("map_id")!=scene().map_id or not navigation_valid(proof.get("position"),scene().map_id):return false
 if Vector2(proof.position[0],proof.position[1]).distance_to(Vector2(geometry.position[0],geometry.position[1]))>float(geometry.get("radius",24)):return false
 if event.kind=="route":
  var total:int=maps[scene().map_id].paths.get(event.id,[]).size()
  return proof.size()==5 and proof.get("complete") is bool and proof.complete and _integer(proof.get("index")) and _integer(proof.get("total")) and int(proof.index)==total and int(proof.total)==total and total>0
 return proof.size()==2
func complete(token: String,proof: Dictionary) -> bool:
 if token=="" or token!=current_token() or state.finished:return false
 var event:=current_event().duplicate(true)
 if not _transactions_valid(event):return false
 match event.op:
  "action":
   if not _valid_action(event,proof):return false
  "choice":
   if proof.size()!=1 or not proof.get("choice_id") is String:return false
   var permitted:=false
   for choice in available_choices():
    if choice.id==proof.choice_id:permitted=true
   if not permitted:return false
  "stage","dialogue","branch_feedback":
   if not proof.is_empty():return false
  "quest_window":
   if proof.size()!=1 or not proof.get("closure_acknowledged") is bool or not proof.closure_acknowledged:return false
  "puzzle","world_puzzle":
   var live:=make_puzzle()
   if live==null or not live.get_view().get("state",{}).get("complete",false) or not Canonical.equivalent(proof,{"receipts":live.get_receipts()}):return false
   var verifier:RefCounted=load(WORLD_SCRIPT if event.op=="world_puzzle" else PUZZLE_SCRIPT).new()
   if not verifier.restore(live.snapshot(),puzzle_context()) or not Canonical.equivalent(verifier.get_receipts(),live.get_receipts()):return false
  "objective_battle":
   var verifier:=make_objective_encounter()
   if verifier==null or not proof.get("attempt_id") is String:return false
   var configuration:Dictionary=verifier.encounter.duplicate(true)
   if event.id=="enc_ch08_civilian_escort":
    if proof.get("phase_attempt_id")!=token:return false
    configuration=Registry.read_json("chapter_eight_encounters").encounters.enc_ch08_civilian_escort.duplicate(true)
    configuration.context={"campaign_checkpoint":state.campaign_battle_snapshot.duplicate(true)}
   elif proof.attempt_id!=token:return false
   var validated:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,configuration,combat_party())
   if validated.is_empty():return false
   for actor in combat_party():state.last_battle_panels[actor.id]={"max_hp":actor.max_hp,"max_mp":actor.max_mp}
   var party_results:Array=[]
   for actor in validated.final_actors:
    if actor.get("id")==Party.HERO:party_results.append(actor)
   var expected_ids:Array=[]
   for actor in combat_party():expected_ids.append(actor.id)
   if not Party.accept_resources(owner().actors,party_results,expected_ids):return false
   if event.id=="enc_ch08_ballista_objective":state.campaign_battle_snapshot=validated.get("campaign_snapshot",{}).duplicate(true)
   if event.id=="enc_ch08_civilian_escort":state.campaign_battle_snapshot={}
   state.objective_snapshot={}
  _:return false
 if event.op=="world_puzzle":
  var receipt:Dictionary=make_puzzle().receipt()
  state.world_receipts[event.id]=receipt.duplicate(true)
  if event.id=="rescue_ch08_l04":state.choices.l04_method=receipt.world_state.method
  owner().world_objects.ch08_spatial_state=receipt.world_state.duplicate(true)
  owner().world_objects.ch08_spatial_state.map_id=scene().map_id
  state.position=receipt.world_state.player_position.duplicate()
 if event.op in ["action","puzzle"]:
  if event.op=="action":state.position=proof.position.duplicate()
  var previous:Dictionary=owner().world_objects.get("ch08_spatial_state",{})
  var spatial:Dictionary=previous.duplicate(true) if previous.get("map_id")==scene().map_id else {}
  # Free movement may finish anywhere inside the verified interaction radius.
  # Controlled scenes begin at that action's authored grid anchor, never a fractional free-walk offset.
  var entry_position:Array=maps[scene().map_id].actions[event.get("entry_id",event.id)].position.duplicate()
  spatial["player_position"]=entry_position;spatial["map_id"]=scene().map_id
  spatial["control_actor_id"]=event.get("controller_id",state.leader_id)
  if not spatial.has("actor_positions"):spatial.actor_positions={}
  spatial.actor_positions[spatial.control_actor_id]=entry_position.duplicate()
  owner().world_objects.ch08_spatial_state=spatial
 var accepted:bool=super.complete(token,proof)
 return accepted
func available_leaders() -> Array:return []
func switch_leader(_id:String) -> bool:return false
func restore_navigation(saved:Dictionary) -> bool:
 if not saved.get("objective_snapshot") is Dictionary:return false
 if not super.restore_navigation(saved):return false
 if not saved.objective_snapshot.is_empty():
  if current_event().get("op")!="objective_battle":return false
  var session:=make_objective_encounter()
  if session==null or not _battle_history_valid(saved.objective_snapshot) or not session.restore(saved.objective_snapshot):return false
  state.objective_snapshot=saved.objective_snapshot.duplicate(true)
 return true
func replay(record:Dictionary) -> bool:
 if not record.get("kind") is String or not record.get("token") is String or not record.get("proof") is Dictionary:return false
 if record.token!=current_token():return false
 if record.kind=="passive_loadout":return record.proof.get("ids") is Array and set_passive_loadout(record.proof.ids)
 return super.replay(record)
func world_context() -> Dictionary:
 var context:Dictionary=super.world_context()
 context.path_progress=state.path_progress.duplicate();context.chapter=8;context.controller_id=Party.HERO
 context.actor_appearances[Party.HERO]="youth_age_18"
 context.items=owner().items.duplicate(true);context.world_objects=owner().world_objects.duplicate(true)
 context.exploration_unlocks=state.exploration_unlocks.duplicate();context.follower_actor_ids=[]
 for id in owner().world_objects.get("ch07_six_friends",{}):
  if owner().world_objects.ch07_six_friends[id]=="dead":context.dead_actor_ids.append(id);context.present_actor_ids.erase(id)
 if current_event().get("op")=="world_puzzle":context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 return context
func party_journal_text() -> String:
 var a:Dictionary=owner().actors[Transactions.A]
 return "梁萧独自参战。柳莺莺暂离但保留共同成长；阿雪在营休养（气血%d/%d、真气%d/%d），场景协作不受整备治疗。\n已学被动：%s\n装配两槽：%s\n战役中场不能换装、补满真气或重置用药。"%[a.hp,a.max_hp,a.mp,a.max_mp,str(owner().actors[Party.HERO].learned_passives),str(owner().actors[Party.HERO].equipped_passives)]
func optional_window_view() -> Dictionary:
 var done:bool=state.optional.L04.status=="archived"
 var deadline:bool=current_event().get("deadline",false)
 return {"title":"总攻前的最后确认" if deadline else "炮后的巷道","body":"祖孙已到枯井窝棚，平安符已经收妥。" if done else "可以先去查看祖孙呼救，未完的救援可以暂停再返回。","continue":"确认火攻…" if deadline else "继续传令","confirmation":"确认总攻后，未完的祖孙救援将关闭，不能补领奖励。"}
func pause_sidequest() -> bool:
 var accepted:bool=super.pause_sidequest()
 if accepted:_sync_campaign_context()
 return accepted
func open_sidequest(id:String) -> bool:
 var accepted:bool=super.open_sidequest(id)
 if accepted:_sync_campaign_context()
 return accepted
func disposition(id:String,value:String) -> bool:
 var accepted:bool=super.disposition(id,value)
 if accepted:_sync_campaign_context()
 return accepted
func set_passive_loadout(ids:Array) -> bool:
 if current_event().get("id")!="ch08_passive_loadout" or ids.size()>2 or state.loadout_records.size()>=128 or not state.campaign_battle_snapshot.is_empty():return false
 var actor:Dictionary=owner().actors[Party.HERO];var seen:Array=[]
 for id in ids:
  if not id is String or id in seen or id not in actor.learned_passives:return false
  seen.append(id)
 _record("passive_loadout",{"ids":ids.duplicate()})
 actor.equipped_passives=ids.duplicate();state.loadout_records.append(ids.duplicate())
 return true

func battle_presentation(view:Dictionary) -> Dictionary:
 var spatial:Dictionary=view.get("world_state",{})
 var map_id:String=spatial.get("map_id","")
 if map_id.is_empty() or not maps.has(map_id):return {}
 var out:Dictionary=scene().duplicate(true)
 out.id=scene().id+"__battle_phase_"+str(view.get("objective",{}).get("phase",1))
 out.map_id=map_id
 return out
