class_name ChapterSixRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_six_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_six_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_six_world_actions.gd"
const RECONSIDER_EVENTS=["ch06_departure_window","entrust","entrust_feedback","dlg_ch06_goodbye","chapter_six_exit"]
const BATTLE_SCRIPT="res://scripts/combat/chapter_six_encounter.gd"
func _init(campaign:RefCounted,id:int=6) -> void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={"R03":{"status":"undiscovered","disposition":"open"},"L02":{"status":"undiscovered","disposition":"open"}}
 state.merge({"leader_id":Party.HERO,"story_restriction":"","frozen_contexts":{},"last_battle_panels":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"exploration_unlocks":previous.get("exploration_unlocks",[]).duplicate(),"inherited_optional":previous.get("inherited_optional",{}).duplicate(true),"inherited_ch04_optional":previous.get("inherited_ch04_optional",{}).duplicate(true),"inherited_choices":previous.choices.duplicate(true)})
 for node in content.scenes:
  node.choices=[]
  for event in runtime.scenes[node.id]:
   if event.op=="choice":node.choices.append_array(content.choice_groups[event.group].options.duplicate(true))
static func can_enter(campaign:RefCounted) -> bool:
 return campaign.active_chapter==5 and campaign.state.finished and campaign.actors.has(Transactions.A) and campaign.actors[Transactions.A].get("status")=="active" and campaign.items.get(Transactions.SWORD,{}).get("owner")==Party.HERO
func available_choices() -> Array:
 if current_event().get("op")!="choice":return []
 var result:Array=content.choice_groups[current_event().group].options.duplicate(true)
 for choice in result:choice.text=choice.label;choice.effects=[]
 return result
func selected_choice() -> Dictionary:
 var group:String=current_event().get("group","")
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
 Party.award(owner().actors,owner().reward_ledger,id,amount)
 state.xp=int(owner().actors[Party.HERO].xp)
func _transactions_valid(event:Dictionary) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true)
 var items:Dictionary=owner().items.duplicate(true)
 var target:Dictionary=state.duplicate(true)
 var world:Dictionary=owner().world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_six_event":
   if effect.id in RECONSIDER_EVENTS and effect.id in target.semantic_commits:continue
   if not Transactions.apply(effect.id,actors,items,target,world):return false
 return true
func _effect(effect:Dictionary) -> void:
 if effect.op!="chapter_six_event":super._effect(effect);return
 if effect.id in RECONSIDER_EVENTS and effect.id in state.semantic_commits:return
 if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):
  push_error("Chapter six transaction rejected: "+str(effect.id));return
 state.semantic_commits.append(effect.id)
 if effect.id=="enc_ch06_white_plum":_award("reward_mq06_white_plum_once",400)
 if effect.id=="departure_confirmed":super._effect({"op":"close_optional"})
 if effect.id=="departure_confirmed":
  var endpoint:Array=maps[scene().map_id].actions.chapter_six_exit.position.duplicate()
  owner().world_objects.ch06_spatial_state={"map_id":scene().map_id,"control_actor_id":Party.HERO,"player_position":endpoint,"actor_positions":{Party.HERO:endpoint.duplicate()},"carrying_pair":{}}
  state.position=endpoint.duplicate();state.path_progress={};state.last_battle_panels={};state.objective_snapshot={}

func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.all_of:
  if required not in state.receipts.get(current.id,[]):push_error("Missing chapter six milestone");return
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
func _puzzle_effects(_event:Dictionary,_proof:Dictionary) -> void:pass
func actor_panel(id:String) -> Dictionary:return owner().actors[id].duplicate(true)
func combat_party() -> Array:
 var result:Array=[]
 var ids:Array=[Party.HERO,Transactions.A] if current_event().get("id")=="enc_ch06_basket_guard" else [Party.HERO]
 for id in ids:
  if not owner().actors.has(id) or owner().actors[id].get("status","present") not in ["active","present"]:continue
  var actor:Dictionary=actor_panel(id)
  var skills:Array=["normal_attack","self_guard","guard_ally","observe"]
  for skill in actor.skills:
   if skill=="LX_A03" and skill not in skills:skills.append(skill)
  if id==Party.HERO:skills.append("sancai_counter")
  var ranks:Dictionary=actor.skill_ranks.duplicate(true)
  if id==Party.HERO:ranks.observe=int(actor.skill_ranks.get("LX_A01",1))
  result.append({"id":id,"name":actor.get("name","梁萧"),"team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":skills,"skill_ranks":ranks,"passives":actor.get("passives",[]).duplicate(),"internal_skill":actor.get("internal_skill","")})
 return result
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 var method:String=""
 if state.scope=="R03":method="bird" if state.choices.get("r03_method")=="ch06_r03_method_bird" else "box"
 if state.scope=="L02":method="waterwheel" if state.choices.get("l02_method")=="ch06_l02_method_waterwheel" else "cart"
 return {"chapter":6,"scene_id":scene().id,"map_id":scene().map_id,"objective_id":current_event().get("id",""),"actors":owner().actors.duplicate(true),"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"completed_receipts":state.receipts.duplicate(true),"leader_id":state.leader_id,"control_actor_id":current_event().get("controller_id",state.leader_id),"method":method,"authorizations":state.semantic_commits.duplicate()}
func make_objective_encounter() -> RefCounted:
 var config:Dictionary=Registry.read_json("chapter_six_encounters").get("encounters",{}).get(current_event().get("id",""),{}).duplicate(true)
 if config.is_empty() or not ResourceLoader.exists(BATTLE_SCRIPT):return null
 config["context"]={"completed_receipts":state.receipts.duplicate(true),"items":owner().items.duplicate(true)}
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 if not session.engine.entry_error.is_empty():return null
 if not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot):return null
 return session
func commit_archived_result(proof:Dictionary) -> bool:
 if not owner()._restoring_summary or not _transactions_valid(current_event()):return false
 return super.commit_archived_result(proof)
func puzzle_definition() -> Dictionary:
 return {"id":current_event().get("id",""),"attempt":current_token(),"guided":false,"world":current_event().get("op")=="world_puzzle"}
func make_puzzle() -> RefCounted:
 if current_event().get("op") not in ["puzzle","world_puzzle"]:return null
 var controller:String=current_event().get("controller_id",state.leader_id)
 if controller not in [Party.HERO,Transactions.A] or not owner().actors.has(controller):return null
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
 return result
func accept_objective(token:String,proof:Dictionary) -> bool:
 if token!=current_token() or current_event().get("op")!="objective_battle" or not proof.get("attempt_id") is String:return false
 return complete(token,proof)
func save_objective_checkpoint(session: RefCounted) -> bool:
 if current_event().get("op")!="objective_battle" or session==null:return false
 state.objective_snapshot=session.snapshot();return true
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
   if event.id=="departure_confirmed" and not _at_departure_endpoint():return false
   if proof.size()!=1 or not proof.get("closure_acknowledged") is bool or not proof.closure_acknowledged:return false
  "puzzle","world_puzzle":
   var live:=make_puzzle()
   if live==null or not live.get_view().get("state",{}).get("complete",false) or not Canonical.equivalent(proof,{"receipts":live.get_receipts()}):return false
   var verifier:RefCounted=load(WORLD_SCRIPT if event.op=="world_puzzle" else PUZZLE_SCRIPT).new()
   if not verifier.restore(live.snapshot(),puzzle_context()) or not Canonical.equivalent(verifier.get_receipts(),live.get_receipts()):return false
  "objective_battle":
   var verifier:=make_objective_encounter()
   if verifier==null or not proof.get("attempt_id") is String or proof.get("attempt_id")!=token:return false
   var validated:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party())
   if validated.is_empty():return false
   for actor in combat_party():state.last_battle_panels[actor.id]={"max_hp":actor.max_hp,"max_mp":actor.max_mp}
   var party_results:Array=[]
   for actor in validated.final_actors:
    if actor.get("team")=="party":party_results.append(actor)
   var expected_ids:Array=[]
   for actor in combat_party():expected_ids.append(actor.id)
   if not Party.accept_resources(owner().actors,party_results,expected_ids):return false
   state.objective_snapshot={}
  _:return false
 if event.op=="world_puzzle":
  var receipt:Dictionary=make_puzzle().receipt()
  state.world_receipts[event.id]=receipt.duplicate(true)
  owner().world_objects.ch06_spatial_state=receipt.world_state.duplicate(true)
  owner().world_objects.ch06_spatial_state.map_id=scene().map_id
  state.position=receipt.world_state.player_position.duplicate()
 if event.op in ["action","puzzle"]:
  if event.op=="action":state.position=proof.position.duplicate()
  var previous:Dictionary=owner().world_objects.get("ch06_spatial_state",{})
  var spatial:Dictionary=previous.duplicate(true) if previous.get("map_id")==scene().map_id else {}
  # Free movement may finish anywhere inside the verified interaction radius.
  # Controlled scenes begin at that action's authored grid anchor, never a fractional free-walk offset.
  var entry_position:Array=maps[scene().map_id].actions[event.get("entry_id",event.id)].position.duplicate()
  spatial["player_position"]=entry_position;spatial["map_id"]=scene().map_id
  spatial["control_actor_id"]=event.get("controller_id",state.leader_id)
  if not spatial.has("actor_positions"):spatial.actor_positions={}
  spatial.actor_positions[spatial.control_actor_id]=entry_position.duplicate()
  owner().world_objects.ch06_spatial_state=spatial
 var accepted:bool=super.complete(token,proof)
 if accepted:_resume_completed_exit_route()
 return accepted
func _at_departure_endpoint() -> bool:
 if not navigation_valid(state.position,scene().map_id):return false
 var geometry:Dictionary=maps[scene().map_id].actions.get("chapter_six_exit",{})
 if geometry.is_empty():return false
 return Vector2(state.position[0],state.position[1]).distance_to(Vector2(geometry.position[0],geometry.position[1]))<=float(geometry.get("radius",24))
func _resume_completed_exit_route() -> void:
 if current_event().get("id")=="chapter_six_exit" and "chapter_six_exit" in state.semantic_commits:
  state.path_progress["chapter_six_exit"]=maps[scene().map_id].paths.chapter_six_exit.size()
func available_leaders() -> Array:
 if current_event().get("op")!="action":return []
 var result:Array=[]
 for id in [Party.HERO,Party.LIU,Transactions.A]:
  if owner().actors.has(id) and owner().actors[id].get("status","present") in ["active","present"]:result.append(id)
 return result
func switch_leader(id:String) -> bool:
 if id not in available_leaders() or id==state.leader_id:return false
 _record("leader",{"id":id});state.leader_id=id;return true
func restore_navigation(saved:Dictionary) -> bool:
 if not saved.get("objective_snapshot") is Dictionary:return false
 if not super.restore_navigation(saved):return false
 if not saved.objective_snapshot.is_empty():
  if current_event().get("op")!="objective_battle":return false
  var session:=make_objective_encounter()
  if session==null or not session.restore(saved.objective_snapshot):return false
  state.objective_snapshot=saved.objective_snapshot.duplicate(true)
 return true
func can_reconsider_departure() -> bool:return state.scope=="main" and current_event().get("id")=="departure_confirmed" and not state.finished
func reconsider_departure(position:Variant) -> bool:
 if not can_reconsider_departure() or not navigation_valid(position,scene().map_id):return false
 _record("reconsider_departure",{"position":position.duplicate()})
 state.step=1;state.position=position.duplicate();state.path_progress={}
 return true
func replay(record:Dictionary) -> bool:
 if not record.get("kind") is String or not record.get("token") is String:return false
 if record.get("kind")=="reconsider_departure":return record.get("token")==current_token() and record.get("proof") is Dictionary and record.proof.size()==1 and reconsider_departure(record.proof.get("position"))
 if record.get("kind")=="leader":return record.get("token")==current_token() and record.get("proof") is Dictionary and record.proof.size()==1 and record.proof.get("id") is String and switch_leader(record.proof.id)
 return super.replay(record)
func world_context() -> Dictionary:
 var context:Dictionary=super.world_context()
 context.path_progress=state.path_progress.duplicate()
 if current_event().get("id")=="chapter_six_exit" and "chapter_six_exit" in state.semantic_commits:
  context.path_progress["chapter_six_exit"]=maps[scene().map_id].paths.chapter_six_exit.size()
 context.chapter=6;context.controller_id=current_event().get("controller_id",state.leader_id)
 context.actor_appearances[Party.HERO]="youth_age_18"
 context.items=owner().items.duplicate(true);context.world_objects=owner().world_objects.duplicate(true)
 context.exploration_unlocks=state.exploration_unlocks.duplicate()
 context.present_actor_ids=[context.controller_id];context.follower_actor_ids=[]
 for actor in content.actor_registry:
  if actor.name in scene().cast and actor.id not in context.present_actor_ids:context.present_actor_ids.append(actor.id)
 if owner().actors[Transactions.A].status=="active":
  var other:String=Transactions.A if context.controller_id==Party.HERO else Party.HERO
  context.follower_actor_ids.append(other)
 if current_event().get("op")=="world_puzzle":context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 return context
func party_journal_text() -> String:
 var axue:Dictionary=owner().actors[Transactions.A]
 var body:String="柳莺莺暂离，仍保留核心成长；不在当前队伍。\n阿雪：固定23级，气血%d/480，真气%d/75。\n"%[axue.hp,axue.mp]
 if axue.status=="staying_huashan":body+="阿雪留在华山，由四婶照看。\n"
 if state.currency_ledger.has("reward_mq06_coins_once"):body+="本章行旅结算450铜已领取一次。\n"
 if owner().items.has("item_ch06_entrusted_coins"):body+="托阿雪照看的盘缠：%d铜。\n"%int(owner().items.item_ch06_entrusted_coins.quantity)
 return body
func sequence() -> Array:
 var result:Array=[]
 for event in super.sequence():
  if not event.has("when_choice") or event.when_choice in state.choices.values():result.append(event)
 return result
func optional_window_view() -> Dictionary:
 var complete:bool=state.optional.R03.status=="archived" and state.optional.L02.status=="archived"
 var deadline:bool=current_event().get("deadline",false)
 if can_reconsider_departure():
  var transfer:String="把当前%d铜全部托阿雪照看，自己不留盘缠"%int(state.coins) if state.choices.get("entrust")=="ch06_entrust_coins" else "将同一父批本托阿雪照看，保留%d铜盘缠"%int(state.coins)
  return {"title":"最后确认离村","body":transfer+"。现在仍可返回村中或改选托付。","continue":"准备正式辞行…","confirmation":transfer+"。确认后阿雪留村，未完约定记为未竟，梁萧赴蔡州；不能再返回本章生活窗口。"}

 return {"title":"从军之前" if deadline else "家居日常","body":"竹器与三户修造都已完成。" if complete else "溪边与院中还有未完的约定，可以返回继续。","continue":"确认收拢家事…" if deadline else ("继续商量托付" if scene().id=="ch06_departure" else "先去见六友"),"confirmation":"两项约定均已归档，准备托付家事吗？" if complete else "尚未完成的约定会留下未竟记事，不发完成奖励。仍要准备离村吗？"}
func pause_sidequest() -> bool:
 if current_event().get("op")=="objective_battle":return false
 return super.pause_sidequest()
