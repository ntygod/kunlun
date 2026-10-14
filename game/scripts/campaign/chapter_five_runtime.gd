class_name ChapterFiveRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_five_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_five_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_five_world_actions.gd"
const BATTLE_SCRIPT="res://scripts/combat/chapter_five_encounter.gd"
func _init(campaign:RefCounted,id:int=5) -> void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={}
 state.merge({"leader_id":Party.HERO,"injury":{},"combo_unlocked":false,"axue_thorn":false,"liu_wounded":false,"seven_swords_vow":false,"frozen_contexts":{},"last_battle_panels":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"exploration_unlocks":previous.get("exploration_unlocks",[]).duplicate(),"inherited_optional":previous.get("inherited_optional",{}).duplicate(true),"inherited_ch04_optional":previous.optional.duplicate(true),"inherited_choices":previous.choices.duplicate(true)})
 for node in content.scenes:
  for event in runtime.scenes[node.id]:
   if event.op=="choice":node.choices=content.choice_groups[event.group].options.duplicate(true)
static func can_enter(campaign:RefCounted) -> bool:
 return campaign.active_chapter==4 and campaign.state.finished and campaign.actors.has(Party.LIU) and campaign.items.get(Transactions.HAT,{}).get("owner")==Party.HERO and campaign.items.get(Transactions.SWORD,{}).get("owner")==Party.HERO
func available_choices() -> Array:
 if current_event().get("op")!="choice":return []
 var result:Array=content.choice_groups[current_event().group].options.duplicate(true)
 for choice in result:choice.text=choice.label;choice.effects=[]
 return result
func selected_choice() -> Dictionary:
 var chosen:String=state.choices.get(_choice_key(current_event()),"")
 for choice in scene().choices:
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
 Party.award(owner().actors,owner().reward_ledger,id,amount)
 Transactions.clamp_resources(owner().actors,state)
 state.xp=int(owner().actors[Party.HERO].xp)
func _transactions_valid(event:Dictionary) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true)
 var items:Dictionary=owner().items.duplicate(true)
 var target:Dictionary=state.duplicate(true)
 var world:Dictionary=owner().world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_five_event" and not Transactions.apply(effect.id,actors,items,target,world):return false
 return true
func _effect(effect:Dictionary) -> void:
 if effect.op!="chapter_five_event":super._effect(effect);return
 if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):
  push_error("Chapter five transaction rejected: "+str(effect.id));return
 state.semantic_commits.append(effect.id)
 if effect.id=="chapter_five_exit":
  var endpoint:Array=maps[scene().map_id].actions.chapter_five_exit.position.duplicate()
  owner().world_objects.ch05_spatial_state={"map_id":scene().map_id,"control_actor_id":Party.HERO,"player_position":endpoint,"actor_positions":{Party.HERO:endpoint.duplicate(),Transactions.A:endpoint.duplicate()},"carrying_pair":{}}
  state.position=endpoint.duplicate();state.path_progress={}
  state.injury={"stage":"recovered"};state.last_battle_panels={};state.objective_snapshot={}
func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.all_of:
  if required not in state.receipts.get(current.id,[]):push_error("Missing chapter five milestone");return
 state.completed.append(current.id)
 for reward in content.reward_transactions:
  if reward.get("after_scene")==current.id:_award(reward.id,int(reward.xp))
 if int(state.scene_index)==content.scenes.size()-1:
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
 else:
  var old_map:String=current.map_id
  state.scene_index+=1;state.step=0;state.path_progress={}
  if scene().map_id!=old_map:state.position=[-1.0,-1.0]
func _puzzle_effects(_event:Dictionary,_proof:Dictionary) -> void:pass
func actor_panel(id:String) -> Dictionary:
 return Transactions.effective(owner().actors[id],state.injury if id==Party.HERO else {})
func combat_party() -> Array:
 var result:Array=[]
 for id in [Party.HERO,Party.LIU,Transactions.A]:
  if not owner().actors.has(id) or owner().actors[id].get("status","present") not in ["active","present"]:continue
  var actor:Dictionary=actor_panel(id)
  var skills:Array=["normal_attack","self_guard","guard_ally","sancai_counter","observe"] if id==Party.HERO else ["normal_attack","self_guard","guard_ally"]
  if id==Party.HERO and state.injury.get("stage")=="depleted":skills=["observe","self_guard"]
  if id!=Party.HERO:
   for skill in actor.skills:
    if (str(skill).begins_with("LYY_A") or str(skill).begins_with("AX_S")) and skill not in skills:skills.append(skill)
  var ranks:Dictionary=actor.skill_ranks.duplicate(true)
  if id==Party.HERO:ranks.observe=int(actor.skill_ranks.get("LX_A01",1))
  result.append({"id":id,"name":actor.get("name","梁萧"),"team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":skills,"skill_ranks":ranks,"passives":actor.passives.duplicate(),"internal_skill":"" if id==Party.HERO and state.injury.get("stage")=="depleted" else actor.get("internal_skill","")})
 return result
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 return {"chapter":5,"scene_id":scene().id,"map_id":scene().map_id,"objective_id":current_event().get("id",""),"actors":owner().actors.duplicate(true),"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"completed_receipts":state.receipts.duplicate(true),"leader_id":state.leader_id,"control_actor_id":current_event().get("controller_id",state.leader_id),"carrying_pair":{},"box_instance":Transactions.BOX}
func make_objective_encounter() -> RefCounted:
 var config:Dictionary=Registry.read_json("chapter_five_encounters").get("encounters",{}).get(current_event().get("id",""),{}).duplicate(true)
 if config.is_empty() or not ResourceLoader.exists(BATTLE_SCRIPT):return null
 config["context"]={"combo_unlocked":state.combo_unlocked,"combo_trial_eligible":true,"liang_restricted":state.injury.get("stage")=="depleted","completed_receipts":state.receipts.duplicate(true),"items":owner().items.duplicate(true)}
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 if not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot):return null
 return session
func commit_archived_result(proof:Dictionary) -> bool:
 if not owner()._restoring_summary or not _transactions_valid(current_event()):return false
 return super.commit_archived_result(proof)
func puzzle_definition() -> Dictionary:
 return {"id":current_event().get("id",""),"attempt":current_token(),"guided":false,"world":current_event().get("op")=="world_puzzle"}
func make_puzzle() -> RefCounted:
 if current_event().get("op") not in ["puzzle","world_puzzle"]:return null
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
 return result
func save_objective_checkpoint(session: RefCounted) -> bool:
 if current_event().get("op")!="objective_battle" or session==null:return false
 state.objective_snapshot=session.snapshot();return true
func _valid_action(event: Dictionary,proof: Dictionary) -> bool:
 if event.has("requires_leader") and state.leader_id!=event.requires_leader:return false
 var geometry:Dictionary=maps.get(scene().map_id,{}).get("actions",{}).get(event.id,{})
 if geometry.is_empty() or proof.get("map_id")!=scene().map_id or not navigation_valid(proof.get("position"),scene().map_id):return false
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
   if proof.size()!=1 or proof.get("closure_acknowledged")!=true:return false
  "puzzle","world_puzzle":
   var live:=make_puzzle()
   if live==null or not live.get_view().get("state",{}).get("complete",false) or not Canonical.equivalent(proof,{"receipts":live.get_receipts()}):return false
   var verifier:RefCounted=load(WORLD_SCRIPT if event.op=="world_puzzle" else PUZZLE_SCRIPT).new()
   if not verifier.restore(live.snapshot(),puzzle_context()) or not Canonical.equivalent(verifier.get_receipts(),live.get_receipts()):return false
  "objective_battle":
   var verifier:=make_objective_encounter()
   if verifier==null or proof.get("attempt_id")!=token:return false
   var validated:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party())
   if validated.is_empty():return false
   for actor in combat_party():state.last_battle_panels[actor.id]={"max_hp":actor.max_hp,"max_mp":actor.max_mp}
   var party_results:Array=[]
   for actor in validated.final_actors:
    if actor.get("team")=="party":party_results.append(actor)
   if not Party.accept_resources(owner().actors,party_results,[Party.HERO,Party.LIU]):return false
   state.objective_snapshot={}
  _:return false
 if event.op=="world_puzzle":
  var receipt:Dictionary=make_puzzle().receipt()
  state.world_receipts[event.id]=receipt.duplicate(true)
  owner().world_objects.ch05_spatial_state=receipt.world_state.duplicate(true)
  owner().world_objects.ch05_spatial_state.map_id=scene().map_id
  state.position=receipt.world_state.player_position.duplicate()
 if event.op=="action":
  state.position=proof.position.duplicate()
  var spatial:Dictionary=owner().world_objects.get("ch05_spatial_state",{})
  # Free movement may finish anywhere inside the verified interaction radius.
  # Controlled scenes begin at that action's authored grid anchor, never a fractional free-walk offset.
  var entry_position:Array=maps[scene().map_id].actions[event.id].position.duplicate()
  spatial["player_position"]=entry_position;spatial["map_id"]=scene().map_id
  owner().world_objects.ch05_spatial_state=spatial
 return super.complete(token,proof)
func available_leaders() -> Array:
 if current_event().get("op")!="action":return []
 var result:Array=[]
 for id in [Party.HERO,Party.LIU,Transactions.A]:
  if owner().actors.has(id) and owner().actors[id].get("status","present") in ["active","present"]:result.append(id)
 return result
func switch_leader(id:String) -> bool:
 if id not in available_leaders() or id==state.leader_id:return false
 _record("leader",{"id":id});state.leader_id=id;return true
func world_context() -> Dictionary:
 var context:Dictionary=super.world_context()
 context.chapter=5;context.controller_id=current_event().get("controller_id",state.leader_id)
 context.actor_appearances[Party.HERO]="youth_age_17";context.actor_appearances[Party.LIU]="youth_age_16"
 context.items=owner().items.duplicate(true);context.world_objects=owner().world_objects.duplicate(true)
 context.exploration_unlocks=state.exploration_unlocks.duplicate()
 context.present_actor_ids=[context.controller_id];context.follower_actor_ids=[]
 if owner().actors[Party.LIU].status=="active" and context.controller_id==Party.HERO:
  context.present_actor_ids.append(Party.LIU);context.follower_actor_ids.append(Party.LIU)
 if owner().actors.has(Transactions.A) and context.controller_id==Party.HERO:
  context.present_actor_ids.append(Transactions.A);context.follower_actor_ids.append(Transactions.A)
 if current_event().get("op")=="world_puzzle":context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 return context

func party_journal_text() -> String:
 var body:String="柳莺莺："+("暂离寻人；保留成长，不可切领队或上场。" if owner().actors[Party.LIU].status=="temporarily_absent" else "同行核心队员。")+"\n"
 if state.currency_ledger.has("reward_mq05_coins_once"):body+="本章行旅结算：400铜（已入账一次）。\n"
 var injury_stage:String=state.injury.get("stage","none")
 if injury_stage in ["depleted","recovering"]:
  var base:Dictionary=owner().actors[Party.HERO]
  body+="梁萧内力耗损：当前有效面板为原面板%d%%；原气血上限%d、攻击%d、防御%d、身法%d保持。\n"%[50 if injury_stage=="depleted" else 75,base.max_hp,base.atk,base.def,base.spd]
 if owner().actors.has(Transactions.A):
  var axue:Dictionary=owner().actors[Transactions.A]
  body+="阿雪：限定同行，固定23级；气血%d/480，真气%d/75，不领取全局核心成长。\n"%[axue.hp,axue.mp]
 return body
