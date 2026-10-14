class_name ChapterNineRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_nine_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_nine_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_nine_world_actions.gd"
const BATTLE_SCRIPT="res://scripts/combat/chapter_nine_encounter.gd"
const FLIGHT_EVENTS=["evt_ch09_dual_crank_ready","evt_ch09_release_mooring","evt_ch09_launch_rail_traversed","evt_ch09_fixed_stall","evt_ch09_he_palm_lift","evt_ch09_cloud_exit_reached","evt_ch09_water_landing","evt_ch09_wood_bird_drifted"]
func _init(campaign:RefCounted,id:int=9) -> void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={"L05":{"status":"undiscovered","disposition":"open"}}
 state.merge({"leader_id":Party.HERO,"frozen_contexts":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"rest_receipts":[],"exploration_unlocks":previous.get("exploration_unlocks",[]).duplicate(),"inherited_optional":previous.get("inherited_optional",{}).duplicate(true),"inherited_ch04_optional":previous.get("inherited_ch04_optional",{}).duplicate(true),"inherited_ch07_optional":previous.get("inherited_ch07_optional",{}).duplicate(true),"inherited_ch08_optional":previous.optional.duplicate(true),"inherited_choices":previous.choices.duplicate(true),"verified_puzzles":{},"wood_bird_checkpoint":{},"wood_bird_context":{},"wood_stage_receipts":[],"l05_closed":false,"l05_archive_window":"","allowed_transactions":["L05_archived"]})
 for node in content.scenes:
  node.choices=[]
  for event in runtime.scenes[node.id]:
   for effect in event.get("effects",[]):
    if effect.op=="chapter_nine_event":state.allowed_transactions.append(effect.id)
   if event.op=="choice":node.choices.append_array(content.choice_groups[event.group].options.duplicate(true))
static func can_enter(campaign:RefCounted) -> bool:
 if campaign.active_chapter!=8 or not campaign.state.finished:return false
 for who in [Party.HERO,Party.LIU,Transactions.A]:
  if not campaign.actors.get(who) is Dictionary:return false
 return int(campaign.actors[Party.HERO].xp)>=15015 and int(campaign.actors[Party.HERO].hp)>0 and campaign.actors[Transactions.A].get("status")=="recovering_in_camp"
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
 if event.get("id")=="evt_ch09_l03_stone_echo":
  var text:String="空帐里留着磨刀石。梁萧只听见雨声，没有凭空补出一段从未经历的磨刀往事。"
  if state.inherited_ch07_optional.get("L03",{}).get("status")=="archived":text="梁萧想起与王可同营时写信、相助的旧事。如今磨刀石留在空帐，那只曾握住它的手再也不会回来。"
  return [{"speaker":"旁白","kind":"stage","text":text}]
 if event.get("id")=="evt_ch09_west_temple_window_complete" and state.optional.L05.status=="archived":
  return [{"speaker":"旁白","kind":"stage","text":"张郎中已由梁萧扶回破庙，主持分药。药箱归医者，铜钥匙与辨药记事留在行囊。" if state.choices.l05_method=="A" else "阿雪依药签分药，梁萧设疑阵引开巡骑，小喜子代师发药。张郎中仍未寻得；不能将这条方法说成救出了郎中。"}]
 if event.get("op")=="dialogue":
  var lines:Array=[]
  for id in event.get("refs",[]):lines.append(content.dialogue_registry[id].duplicate(true))
  return _format(lines)
 return super.presentation()
func _award(id:String,amount:int) -> void:
 if Party.award(owner().actors,owner().reward_ledger,id,amount):state.xp=int(owner().actors[Party.HERO].xp)
func _transactions_valid(event:Dictionary) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true);var items:Dictionary=owner().items.duplicate(true);var target:Dictionary=state.duplicate(true);var world:Dictionary=owner().world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_nine_event" and not Transactions.apply(effect.id,actors,items,target,world):return false
 return true
func _effect(effect:Dictionary) -> void:
 if effect.op!="chapter_nine_event":super._effect(effect);return
 if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):push_error("Chapter nine transaction rejected: "+str(effect.id));return
 state.semantic_commits.append(effect.id)
 var awards={"evt_ch09_pine_proof_complete":["reward_mq09_pine_once",500],"evt_ch09_wood_bird_proof_complete":["reward_mq09_wood_bird_once",500],"evt_ch09_well_disarm_complete":["reward_mq09_well_encounter_once",300]}
 if awards.has(effect.id):_award(awards[effect.id][0],awards[effect.id][1])
func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.all_of:
  if required not in state.receipts.get(current.id,[]):push_error("Missing chapter nine milestone");return
 if state.scope!="main":
  if not Transactions.apply("L05_archived",owner().actors,owner().items,state,owner().world_objects):push_error("Invalid L05 archive");return
  state.semantic_commits.append("L05_archived");state.optional.L05={"status":"archived","disposition":"completed"}
  _memory(current.completion_memory);_award(current.reward_transaction,int(current.xp))
  state.scope="main";state.side_step=0;state.position=state.return_position.duplicate();state.path_progress={};state.leader_id=Party.HERO
  state.l05_archive_window=current_token();return
 state.completed.append(current.id)
 for reward in content.reward_transactions:
  if reward.get("after_scene")==current.id:_award(reward.id,int(reward.xp))
 if int(state.scene_index)==content.scenes.size()-1:
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
  state.objective_snapshot={};state.wood_bird_checkpoint={};state.wood_bird_context={}
  state.position=maps[current.map_id].spawn.duplicate();state.path_progress={}
  owner().world_objects.ch09_spatial_state={"map_id":current.map_id,"control_actor_id":Party.HERO,"player_position":state.position.duplicate(),"actor_positions":{Party.HERO:state.position.duplicate()},"carrying_pair":{}}
 else:
  var old_map:String=current.map_id
  state.scene_index+=1;state.step=0;state.path_progress={}
  if scene().map_id!=old_map:state.position=[-1.0,-1.0]
func _puzzle_effects(_event:Dictionary,_proof:Dictionary) -> void:pass
func actor_panel(id:String) -> Dictionary:return owner().actors[id].duplicate(true)
func combat_party() -> Array:
 var actor:Dictionary=actor_panel(Party.HERO)
 return [{"id":Party.HERO,"name":"梁萧","team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":[],"skill_ranks":actor.skill_ranks.duplicate(true),"passives":actor.get("equipped_passives",[]).duplicate(),"learned_passives":actor.get("learned_passives",[]).duplicate(),"equipped_passives":actor.get("equipped_passives",[]).duplicate(),"internal_skill":actor.get("internal_skill",""),"controllable":true,"fixed_level":int(actor.level)}]
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 var context:Dictionary={"chapter":9,"current_token":current_token(),"revision":1,"phase":scene().id,"scope":scene().id,"scene_id":scene().id,"map_id":scene().map_id,"objective_id":current_event().get("id",""),"actors":owner().actors.duplicate(true),"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"inherited_choices":state.inherited_choices.duplicate(true),"knowledge":state.knowledge.duplicate(),"fixed_level":40,"completed_receipts":state.receipts.duplicate(true),"leader_id":Party.HERO,"control_actor_id":Party.HERO,"authorizations":state.semantic_commits.duplicate(),"rest_receipts":state.rest_receipts.duplicate(),"l05":state.optional.L05.duplicate(true)}
 if owner().world_objects.has("ch09_pine_materials"):context.material_receipt=owner().world_objects.ch09_pine_materials.duplicate(true)
 if scene().id=="ch09_cloud_escape":
  context.wood_bird_checkpoint=state.wood_bird_checkpoint.duplicate(true);context.wood_bird_context=state.wood_bird_context.duplicate(true)
 return context
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
 if current_event().get("id")!="enc_ch09_well_disarm":return null
 var config:Dictionary=Registry.read_json("chapter_nine_encounters").get("encounters",{}).get(current_event().id,{}).duplicate(true)
 if config.is_empty():return null
 config.context=puzzle_context()
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
   if event.id=="pz_ch09_pine_needle":state.verified_puzzles.pine=true
   if event.id=="pz_ch09_wood_bird_begin":
    if live.state.get("stage")!="prepared":return false
    state.wood_bird_checkpoint=live.snapshot();state.wood_bird_context=live.context.duplicate(true);state.verified_puzzles.wood_prepared=true
   if event.id=="evt_ch09_wood_bird_resume":
    if live.state.get("stage")!="drifted":return false
    var stages:Array=[]
    for receipt in live.get_receipts():
     if receipt.has("event_id"):stages.append(receipt.event_id)
    for required in FLIGHT_EVENTS:
     if required not in stages:return false
    state.verified_puzzles.wood_drifted=true;state.wood_stage_receipts=stages
   if event.op=="world_puzzle":
    var receipt:Dictionary=live.receipt();state.world_receipts[event.id]=receipt.duplicate(true)
    if event.id=="rescue_ch09_l05":
     state.choices.l05_method=receipt.world_state.method;state.verified_puzzles.l05=true
    owner().world_objects.ch09_spatial_state=receipt.world_state.duplicate(true)
    owner().world_objects.ch09_spatial_state.map_id=scene().map_id
    state.position=receipt.world_state.player_position.duplicate()
  "objective_battle":
   var verifier:=_new_objective_encounter()
   if verifier==null or not proof.get("attempt_id") is String or proof.attempt_id!=token:return false
   var validated:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party())
   if validated.is_empty() or not Party.accept_resources(owner().actors,validated.final_actors,[Party.HERO]):return false
   state.verified_puzzles.well_disarmed=true;state.objective_snapshot={}
  _:return false
 if event.op=="action":state.position=proof.position.duplicate()
 return super.complete(token,proof)
func commit_archived_result(proof:Dictionary) -> bool:
 if not owner()._restoring_summary:return false
 var event:=current_event()
 if event.id=="pz_ch09_pine_needle":state.verified_puzzles.pine=true
 if event.id=="pz_ch09_wood_bird_begin":state.verified_puzzles.wood_prepared=true
 if event.id=="evt_ch09_wood_bird_resume":state.verified_puzzles.wood_drifted=true;state.wood_stage_receipts=["evt_ch09_wood_bird_assembled"]+FLIGHT_EVENTS
 if event.id=="enc_ch09_well_disarm":state.verified_puzzles.well_disarmed=true
 if event.id=="rescue_ch09_l05":state.verified_puzzles.l05=true
 if not _transactions_valid(event):return false
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
 context.path_progress=state.path_progress.duplicate();context.chapter=9;context.controller_id=Party.HERO;context.actor_appearances[Party.HERO]="youth_age_18"
 context.items=owner().items.duplicate(true);context.world_objects=owner().world_objects.duplicate(true);context.exploration_unlocks=state.exploration_unlocks.duplicate();context.follower_actor_ids=[]
 # Read-only projection from the latest verified wood-bird record. Never advance it here.
 if scene().map_id=="map_ch09_tiandu_peak":
  for token in ["ch09_cloud_escape:00","ch09_wood_bird_assembly:00"]:
   if not state.puzzle_records.has(token) or not state.frozen_contexts.has(token):continue
   var bird:RefCounted=load(PUZZLE_SCRIPT).new()
   if bird.restore(state.puzzle_records[token],state.frozen_contexts[token]):
    context.wood_bird_presentation=bird.get_view().get("world_state",{}).duplicate(true);break
 for id in owner().world_objects.get("ch07_six_friends",{}):
  if owner().world_objects.ch07_six_friends[id]=="dead":context.dead_actor_ids.append(id);context.present_actor_ids.erase(id)
 if current_event().get("op")=="world_puzzle":context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 return context
func party_journal_text() -> String:
 var a:Dictionary=owner().actors[Transactions.A]
 return "梁萧独自应对兵刃。柳莺莺暂离仍共同成长；阿雪只场景同行，气血%d/%d、真气%d/%d保持真实继承。\n标准装备与共用铜钱不属弃官赏赐。无新增战技、编号首领或已实装药品系统。"%[a.hp,a.max_hp,a.mp,a.max_mp]
func optional_window_view() -> Dictionary:
 var done:bool=state.optional.L05.status=="archived";var deadline:bool=current_event().get("deadline",false)
 return {"title":"帅帐之前的路口" if deadline else "西郊破庙救治","body":"破庙救治已经归档，铜钥匙与记事留存。" if done else ("血井的悲剧已经发生，不会重播。现在仍可回破庙，或确认闯帐。" if deadline else "青杏医箱与伤员在破庙，可查看、暂停、再回来。"),"continue":"确认闯帐…" if deadline else "先去断街","confirmation":"确认进入伯颜帅帐后，未完成的L05将关闭；没有经验、钥匙或完成记事。"}
func battle_presentation(_view:Dictionary) -> Dictionary:return scene()
