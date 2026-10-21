class_name ChapterTenRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_ten_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_ten_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_ten_world_actions.gd"
const BATTLE_SCRIPT="res://scripts/combat/chapter_ten_encounter.gd"
const ENGINE_SCRIPT="res://scripts/combat/chapter_ten_engine.gd"
func _init(campaign:RefCounted,id:int=10) -> void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={}
 state.merge({"leader_id":Party.HERO,"frozen_contexts":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"rest_receipts":[],"exploration_unlocks":previous.get("exploration_unlocks",[]).duplicate(),"inherited_optional":previous.get("inherited_optional",{}).duplicate(true),"inherited_ch04_optional":previous.get("inherited_ch04_optional",{}).duplicate(true),"inherited_ch07_optional":previous.get("inherited_ch07_optional",{}).duplicate(true),"inherited_ch08_optional":previous.get("inherited_ch08_optional",{}).duplicate(true),"inherited_ch09_optional":previous.optional.duplicate(true),"inherited_choices":previous.choices.duplicate(true),"verified_puzzles":{},"allowed_transactions":[]})
 for node in content.scenes:
  node.choices=[]
  for event in runtime.scenes[node.id]:
   for effect in event.get("effects",[]):
    if effect.op=="chapter_ten_event":state.allowed_transactions.append(effect.id)
   if event.op=="choice":node.choices.append_array(content.choice_groups[event.group].options.duplicate(true))
static func can_enter(campaign:RefCounted) -> bool:
 if campaign.active_chapter!=9 or not campaign.state.finished:return false
 for who in [Party.HERO,Party.LIU,Transactions.A]:
  if not campaign.actors.get(who) is Dictionary:return false
 return int(campaign.actors[Party.HERO].xp)>=17845 and int(campaign.actors[Party.HERO].hp)>0 and campaign.actors[Transactions.A].get("status")=="travelling_with_liang"
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
 if Party.award(owner().actors,owner().reward_ledger,id,amount):state.xp=int(owner().actors[Party.HERO].xp)
func _transactions_valid(event:Dictionary,candidate:Dictionary={}) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true);var items:Dictionary=owner().items.duplicate(true);var target:Dictionary=(state if candidate.is_empty() else candidate).duplicate(true);var world:Dictionary=owner().world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_ten_event":
   if not Transactions.apply(effect.id,actors,items,target,world):return false
   target.semantic_commits.append(effect.id)
 return true
func _effect(effect:Dictionary) -> void:
 if effect.op!="chapter_ten_event":super._effect(effect);return
 if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):push_error("Chapter ten transaction rejected: "+str(effect.id));return
 state.semantic_commits.append(effect.id)
 if effect.id=="evt_ch10_bayan_survived":_award("reward_mq10_bayan_once",300)
func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.all_of:
  if required not in state.receipts.get(current.id,[]):push_error("Missing chapter ten milestone");return
 state.completed.append(current.id)
 for reward in content.reward_transactions:
  if reward.get("after_scene")==current.id:_award(reward.id,int(reward.xp))
 if int(state.scene_index)==content.scenes.size()-1:
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
  state.objective_snapshot={};state.position=maps[current.map_id].spawn.duplicate();state.path_progress={};state.controller_override=""
  owner().world_objects.ch10_spatial_state={"map_id":current.map_id,"control_actor_id":Party.HERO,"player_position":state.position.duplicate(),"actor_positions":{Party.HERO:state.position.duplicate()},"carrying_pair":{}}
 else:
  var old_map:String=current.map_id
  state.scene_index+=1;state.step=0;state.path_progress={};state.controller_override=""
  if scene().map_id!=old_map:state.position=[-1.0,-1.0]
func _puzzle_effects(_event:Dictionary,_proof:Dictionary) -> void:pass
func actor_panel(id:String) -> Dictionary:return owner().actors[id].duplicate(true)
func combat_party() -> Array:
 var actor:Dictionary=actor_panel(Party.HERO);var skills:Array=["normal_attack","self_guard"]
 for pair in [["LX_A01","observe"],["LX_A02","sancai_counter"],["LX_A03","LX_A03"]]:
  if pair[0] in actor.skills:skills.append(pair[1])
 var ranks:Dictionary=actor.skill_ranks.duplicate(true);ranks.observe=int(actor.skill_ranks.get("LX_A01",1))
 return [{"id":Party.HERO,"name":"梁萧","team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":skills,"skill_ranks":ranks,"passives":actor.get("equipped_passives",[]).duplicate(),"learned_passives":actor.get("learned_passives",[]).duplicate(),"equipped_passives":actor.get("equipped_passives",[]).duplicate(),"acquired_passives":actor.get("learned_passives",[]).duplicate(),"internal_skill":actor.get("internal_skill",""),"controllable":true,"fixed_level":int(actor.level)}]
func control_actor_id() -> String:return Transactions.A if scene().id=="ch10_axue_return" else Party.HERO
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 return {"chapter":10,"current_token":current_token(),"revision":1,"phase":scene().id,"scope":scene().id,"scene_id":scene().id,"map_id":scene().map_id,"objective_id":current_event().get("id",""),"actors":owner().actors.duplicate(true),"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"inherited_choices":state.inherited_choices.duplicate(true),"knowledge":state.knowledge.duplicate(),"fixed_level":int(owner().actors[Party.HERO].level),"completed_receipts":state.receipts.duplicate(true),"leader_id":control_actor_id(),"control_actor_id":control_actor_id(),"authorizations":state.semantic_commits.duplicate(),"rest_receipts":state.rest_receipts.duplicate()}
func puzzle_definition() -> Dictionary:return {"id":current_event().get("puzzle_id",current_event().get("id","")),"attempt":current_token(),"guided":false,"world":current_event().get("op")=="world_puzzle"}
func make_puzzle() -> RefCounted:
 if current_event().get("op") not in ["puzzle","world_puzzle"]:return null
 if int(owner().actors[Party.HERO].hp)<=0:return null
 if puzzle_session!=null:return puzzle_session
 var definition:=puzzle_definition();var path:String=WORLD_SCRIPT if definition.world else PUZZLE_SCRIPT
 if not ResourceLoader.exists(path):return null
 var candidate:RefCounted=load(path).new()
 if not candidate.begin(definition.id,definition.attempt,puzzle_context()):return null
 if state.puzzle_records.has(definition.attempt) and not candidate.restore(state.puzzle_records[definition.attempt],puzzle_context()):return null
 puzzle_session=candidate;return puzzle_session
func puzzle_input(token:String,action:Dictionary) -> Dictionary:
 if token!=current_token():return {"ok":false,"message":"操作已过期"}
 var session:=make_puzzle()
 if session==null:return {"ok":false,"message":"机关尚未登记"}
 var before:Dictionary=session.snapshot();var result:Dictionary=session.apply_input(action)
 if not Canonical.equivalent(before,session.snapshot()):
  if not state.frozen_contexts.has(token):state.frozen_contexts[token]=session.context.duplicate(true)
  _record("puzzle_input",{"action":action});state.puzzle_records[token]=session.snapshot();state.puzzle_snapshot=session.snapshot()
 if session.get_view().get("state",{}).get("complete",false):complete(token,{"receipts":session.get_receipts()})
 return result
func _new_objective_encounter() -> RefCounted:
 if current_event().get("id")!="enc_ch10_bayan_tide" or int(owner().actors[Party.HERO].xp)<19350 or owner().actors[Transactions.A].get("status")!="dead":return null
 var config:Dictionary=load(ENGINE_SCRIPT).encounter_config();config.context=puzzle_context()
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 return null if not session.engine.entry_error.is_empty() else session
func make_objective_encounter() -> RefCounted:
 var session:=_new_objective_encounter()
 if session==null:return null
 if not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot):return null
 return session
func save_objective_checkpoint(session:RefCounted) -> bool:
 if current_event().get("op")!="objective_battle" or session==null:return false
 var candidate:Dictionary=session.snapshot();var verifier:=_new_objective_encounter()
 if verifier==null or not verifier.restore(candidate):return false
 state.objective_snapshot=candidate;return true
func accept_objective(token:String,proof:Dictionary) -> bool:return complete(token,proof) if token==current_token() and current_event().get("op")=="objective_battle" else false
func _valid_action(event:Dictionary,proof:Dictionary) -> bool:
 var geometry:Dictionary=maps.get(scene().map_id,{}).get("actions",{}).get(event.id,{})
 if geometry.is_empty() or not proof.get("map_id") is String or proof.map_id!=scene().map_id or not navigation_valid(proof.get("position"),scene().map_id):return false
 if not proof.has_all(["map_id","position"]) or proof.size()!=2:return false
 return Vector2(proof.position[0],proof.position[1]).distance_to(Vector2(geometry.position[0],geometry.position[1]))<=float(geometry.get("radius",24))
func complete(token:String,proof:Dictionary) -> bool:
 if token.is_empty() or token!=current_token() or state.finished:return false
 var event:=current_event().duplicate(true);var next_state:Dictionary=state.duplicate(true);var spatial:Dictionary={};var final_actors:Array=[]
 match event.op:
  "action":
   if not _valid_action(event,proof):return false
   next_state.position=proof.position.duplicate()
  "choice":
   if proof.size()!=1 or not proof.get("choice_id") is String:return false
   var permitted:=false
   for choice in available_choices():
    if choice.id==proof.choice_id:permitted=true
   if not permitted:return false
  "stage","dialogue","branch_feedback":
   if not proof.is_empty():return false
  "puzzle","world_puzzle":
   var live:=make_puzzle()
   if live==null or not live.get_view().get("state",{}).get("complete",false) or not Canonical.equivalent(proof,{"receipts":live.get_receipts()}):return false
   var verifier:RefCounted=load(WORLD_SCRIPT if event.op=="world_puzzle" else PUZZLE_SCRIPT).new()
   if not verifier.restore(live.snapshot(),puzzle_context()) or not Canonical.equivalent(verifier.get_receipts(),live.get_receipts()):return false
   next_state.verified_puzzles[puzzle_definition().id]=true
   if event.op=="world_puzzle":
    var receipt:Dictionary=live.receipt();next_state.world_receipts[event.id]=receipt.duplicate(true)
    spatial=receipt.get("world_state",{}).duplicate(true)
    if spatial.is_empty() or not navigation_valid(spatial.get("player_position"),scene().map_id):return false
    spatial.map_id=scene().map_id;next_state.position=spatial.player_position.duplicate()
  "objective_battle":
   var verifier:=_new_objective_encounter()
   if verifier==null or not proof.get("attempt_id") is String or proof.attempt_id!=token:return false
   var validated:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party())
   if validated.is_empty():return false
   var actors:Dictionary=owner().actors.duplicate(true)
   if not Party.accept_resources(actors,validated.final_actors,[Party.HERO]) or int(actors[Party.HERO].hp)<=0:return false
   final_actors=validated.final_actors.duplicate(true);next_state.verified_puzzles[event.id]=true;next_state.objective_snapshot={}
  _:return false
 if not _transactions_valid(event,next_state):return false
 state.clear();state.merge(next_state)
 if not spatial.is_empty():owner().world_objects.ch10_spatial_state=spatial
 if not final_actors.is_empty():Party.accept_resources(owner().actors,final_actors,[Party.HERO])
 return super.complete(token,proof)
func commit_archived_result(proof:Dictionary) -> bool:
 if not owner()._restoring_summary:return false
 var event:=current_event();var staged:Dictionary=state.duplicate(true)
 if event.op in ["puzzle","world_puzzle","objective_battle"]:staged.verified_puzzles[event.get("puzzle_id",event.id)]=true
 if not _transactions_valid(event,staged):return false
 state.verified_puzzles=staged.verified_puzzles
 return super.commit_archived_result(proof)
func restore_navigation(saved:Dictionary) -> bool:
 if not saved.get("objective_snapshot") is Dictionary:return false
 if not saved.objective_snapshot.is_empty():
  var session:=_new_objective_encounter()
  if session==null or not session.restore(saved.objective_snapshot):return false
 if not super.restore_navigation(saved):return false
 state.objective_snapshot=saved.objective_snapshot.duplicate(true)
 return true
func replay(record:Dictionary) -> bool:
 if not record.get("kind") is String or not record.get("token") is String or not record.get("proof") is Dictionary or record.token!=current_token():return false
 return super.replay(record)
func available_leaders() -> Array:return []
func switch_leader(_id:String) -> bool:return false
func world_context() -> Dictionary:
 var context:Dictionary=super.world_context()
 context.path_progress=state.path_progress.duplicate();context.chapter=10;context.controller_id=control_actor_id();context.actor_appearances[Party.HERO]="youth_age_18"
 context.items=owner().items.duplicate(true);context.world_objects=owner().world_objects.duplicate(true);context.exploration_unlocks=state.exploration_unlocks.duplicate();context.follower_actor_ids=[]
 if owner().actors[Transactions.A].get("status")=="dead":
  context.dead_actor_ids.append(Transactions.A);context.present_actor_ids.erase(Transactions.A)
 for id in owner().world_objects.get("ch07_six_friends",{}):
  if owner().world_objects.ch07_six_friends[id]=="dead":context.dead_actor_ids.append(id);context.present_actor_ids.erase(id)
 if current_event().get("op")=="world_puzzle":context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 return context
func party_journal_text() -> String:
 return "阿雪 · 斯人已随江水去。旧针线包与真实信物留存，昔日面板仅作行旅记录，不能再出战。柳莺莺暂离仍共同成长。" if owner().actors[Transactions.A].get("status")=="dead" else "阿雪随行，寻径照拂；当前固定面板与旧伤照实继承。柳莺莺暂离仍共同成长。"
func battle_presentation(_view:Dictionary) -> Dictionary:return scene()
