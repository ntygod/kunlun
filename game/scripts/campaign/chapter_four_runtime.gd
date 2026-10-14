class_name ChapterFourRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_four_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_four_puzzle_resolver.gd"
const WORLD_SCRIPT="res://scripts/world_actions/chapter_four_world_actions.gd"
const BATTLE_SCRIPT="res://scripts/combat/chapter_four_encounter.gd"
var dialogue_by_id:Dictionary={}
func _init(campaign: RefCounted,id: int=4) -> void:
 super(campaign,id)
 var previous:Dictionary=campaign.chapter_three.state
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 state.coins=int(previous.coins);state.liang_age=int(previous.liang_age);state.xiaoshuang_age=int(previous.xiaoshuang_age)
 state.optional={"R02":{"status":"undiscovered","disposition":"open"},"L01":{"status":"undiscovered","disposition":"open"}}
 state.merge({"leader_id":Party.HERO,"frozen_contexts":{},"last_battle_panels":{},"objective_snapshot":{},"world_receipts":{},"semantic_commits":[],"inherited_choices":previous.choices.duplicate(true),"inherited_optional":previous.inherited_optional.duplicate(true),"exploration_unlocks":[],"return_map_id":"","timeline_days":0})
 dialogue_by_id=content.dialogue_registry.duplicate(true)
 for node in content.scenes:
  node["dialogue"]=[];node["choices"]=[]
  for group in node.choice_groups:
   for option in content.choice_groups[group].options:node.choices.append(_choice(option))
 for side in content.side_quests:
  side["map_id"]="map_ch04_rain_gallery" if side.id=="R02" else "map_ch04_gusu_street"
  side["cast"]=["梁萧","柳莺莺","老周"] if side.id=="L01" else ["梁萧","柳莺莺"]
  side["completion_gate"]={"all_of":["r02_weave","r02_rain_test","r02_reclaim_drawing"] if side.id=="R02" else ["l01_repair","l01_leak_test","l01_priority_cargo"]}
  var choices:Array=[]
  for option in side.choices:choices.append(_choice(option))
  side.choices=choices
 for item in content.item_registry:
  if not item.has("name"):item.name={Transactions.INK:"清心砚",Transactions.POUCH:"随身零钱袋","item_ch04_liu_willow_hat":"莺莺的师门柳笠","item_ch04_small_willow_hat":"新编小柳笠","item_ch04_tung_oil_bag":"防水桐油袋"}.get(item.id,item.id)
func _choice(option: Dictionary) -> Dictionary:
 var result:=option.duplicate(true)
 result["effects"]=[]
 result["text"]=result.get("label","")
 return result
func sequence() -> Array:
 var result:Array=[]
 for event in super.sequence():
  if not event.has("when_choice") or event.when_choice in state.choices.values():result.append(event)
 return result
func available_choices() -> Array:
 if current_event().get("op")!="choice":return []
 var group:String=current_event().group
 if state.scope!="main":
  var side_choices:Array=scene().choices.duplicate(true)
  for option in side_choices:
   var feedback:String=_line(option.feedback_dialogue_ref).get("text","")
   option["feedback"]=feedback.split(" / ")[0] if state.scope=="L01" else feedback
  return side_choices
 var result:Array=[]
 for option in content.choice_groups[group].options:result.append(_choice(option))
 return result
func selected_choice() -> Dictionary:
 var chosen:String=state.choices.get(_choice_key(current_event()),"")
 for choice in scene().choices:
  if choice.id==chosen:return choice
 return {}
func _line(id: String) -> Dictionary:
 var line:Dictionary=dialogue_by_id.get(id,{}).duplicate(true)
 for override in content.effective_dialogue_overrides:
  if override.source_dialogue_id!=id:continue
  var condition:String=override.get("condition","always")
  if condition.begins_with("choice ") and condition.substr(7) not in state.choices.values():continue
  if override.has("replacement_dialogue_id"):line=dialogue_by_id[override.replacement_dialogue_id].duplicate(true)
  if override.has("replacement_stage_direction"):line.stage_direction=override.replacement_stage_direction
 var purse:Dictionary=owner().items.get(Transactions.POUCH,{})
 var empty_variant:Dictionary={"dlg_ch04_source_841":"dlg_ch04_zero_copper_841","dlg_ch04_source_842":"dlg_ch04_zero_copper_842","dlg_ch04_source_843":"dlg_ch04_zero_copper_843"}
 if purse.get("custody")=="liu" and int(purse.get("escrow",-1))==0 and empty_variant.has(id):line=dialogue_by_id[empty_variant[id]].duplicate(true)
 line.kind="stage" if line.get("kind") in ["stage","narration"] else "speech"
 return line
func presentation() -> Array:
 var event:=current_event()
 if event.get("op")=="stage" and state.scope=="L01":
  var afterglow:String="老周连声道谢。" if "ch04_l01_rice" in state.choices.values() else "渔家送来一份莼菜鲈鱼，只作本场饭食。"
  return [{"speaker":"旁白","kind":"stage","text":"船身重新浮稳。老周核对押租已归还，这笔钱不进梁萧的行囊。"+afterglow}]
 if event.get("op")=="branch_feedback":
  var choice:=selected_choice()
  return _format([_line(choice.feedback_dialogue_ref)]) if choice.has("feedback_dialogue_ref") else [{"speaker":"旁白","text":choice.get("label","这一念留在行旅中。"),"kind":"stage"}]
 if event.get("op")=="dialogue":
  var lines:Array=[]
  for id in event.get("refs",[]):lines.append(_line(id))
  if lines.is_empty():lines.append({"speaker":"旁白","kind":"stage","text":event.get("text",event.get("name","行旅继续。"))})
  return _format(lines)
 return super.presentation()
func _award(id: String, amount: int) -> void:
 Party.award(owner().actors,owner().reward_ledger,id,amount)
 state.xp=int(owner().actors[Party.HERO].xp)
func _transaction(id: String, actors: Dictionary, items: Dictionary, target: Dictionary) -> bool:
 match id:
  "pouch_escrow_prepared":return Transactions.reserve_pouch(target,items)
  "pouch_theft_seen":return Transactions.steal_pouch(items)
  "pouch_and_keepsake_returned":return Transactions.return_pouch(target,items)
  "liu_joined":return Party.recruit_liu(actors)
  "gear_refitted":
   if not actors.has(Party.HERO) or not actors.has(Party.LIU) or actors[Party.HERO].get("equipment_stage")=="chapter_four" or actors[Party.LIU].get("equipment_stage")=="chapter_four":return false
   var hero_ok:bool=Party.refit(actors,Party.HERO)
   var liu_ok:bool=Party.refit(actors,Party.LIU)
   return hero_ok and liu_ok
  "keepsake_custody_verified":return Transactions.transfer_keepsake(items,"ch04_pact_inkstone" in target.choices.values())
 return true
func _transactions_valid(event: Dictionary) -> bool:
 var actors:Dictionary=owner().actors.duplicate(true)
 var items:Dictionary=owner().items.duplicate(true)
 var target:Dictionary=state.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_four_event" and not _transaction(effect.id,actors,items,target):return false
 return true
func _effect(effect: Dictionary) -> void:
 if effect.op!="chapter_four_event":super._effect(effect);return
 var id:String=effect.id
 if not _transaction(id,owner().actors,owner().items,state):
  push_error("Chapter four transaction rejected: "+id)
  return
 state.semantic_commits.append(id)
 match id:
  "timeline_next_spring":
   state.liang_age=17;state.xiaoshuang_age=16;owner().actors[Party.HERO].age=17;owner().actors.char_hua_xiaoshuang.age=16
  "liu_joined":
   owner().items.item_ch04_liu_willow_hat={"owner":Party.LIU,"state":"carried","form":"intact"}
   owner().actors["animal_yanzhi"]={"status":"nearby","kind":"noncombat_horse","owner":Party.LIU,"coat":"white_red_spots"}
  "ride_choice":owner().items.item_ch04_liu_willow_hat.form="torn_rim"
  "liu_carried_not_combat":owner().actors[Party.LIU].status="asleep";state.leader_id=Party.HERO
  "liu_awake":owner().actors[Party.LIU].status="active"
  "liu_denial_heard":_knowledge("liu_denies_murder_and_arson")
  "real_box_lead_heard":_knowledge("ch04_real_box_lead")
  "teacher_truth_heard":_knowledge("liu_teacher_loss_account")
  "three_days_elapsed":state.timeline_days=3
  "small_hat_received":owner().items.item_ch04_small_willow_hat={"owner":Party.HERO,"state":"carried","form":"newly_woven"}
  "r02_reclaim":owner().items.item_ch04_waterworks_drawing={"owner":Party.LIU,"state":"carried","form":"reclaimed"}
  "r02_reclaim_drawing":owner().items.item_ch04_waterworks_drawing.owner="npc_widow";owner().items.item_ch04_waterworks_drawing.state="returned"
  "r02_repaired":owner().items.item_ch04_liu_willow_hat.form="repaired_by_r02"
  "l01_priority_cargo":owner().world_objects.ch04_cargo={"priority":"fish" if "ch04_l01_fish" in state.choices.values() else "rice","unloaded":false}
  "l01_repaired":
   owner().world_objects.ch04_repaired_boat={"state":"repaired","leak_test_ticks":3}
   owner().world_objects.ch04_cargo.unloaded=true
  "export_verified":
   owner().world_objects.ch04_spatial_state={"map_id":scene().map_id,"player_position":maps[scene().map_id].actions.export_verified.position.duplicate(),"horse_id":"animal_yanzhi","carrying":false,"horse_released":true,"chu_wan_held":false}
  "departure_confirmed":
   if current_event().get("deadline",false):_effect({"op":"close_optional"})
func _knowledge(id: String) -> void:
 if id not in state.knowledge:state.knowledge.append(id)
func _finish_scene() -> void:
 var current:=scene()
 for required in current.completion_gate.get("all_of",[]):assert(required in state.receipts.get(current.id,[]),"Unmet chapter4 gate "+required)
 if state.scope!="main":
  var side:String=state.scope
  state.optional[side]={"status":"archived","disposition":"completed"}
  _memory(current.completion_memory);_award(current.reward_transaction,int(current.xp))
  if side=="R02":
   var liu:Dictionary=owner().actors[Party.LIU]
   if "LYY_A03" not in liu.skills:liu.skills.append("LYY_A03")
   liu.skill_ranks.LYY_A03=1
  else:
   _item("item_ch04_tung_oil_bag")
   state.exploration_unlocks.append("l01_water_movement_no_slow")
   owner().world_objects.l01_water_movement_no_slow=true
  state.semantic_commits.append(side+"_archived")
  state.scope="main";state.side_step=0;state.position=state.return_position.duplicate();state.path_progress={}
  return
 state.completed.append(current.id)
 for reward in content.reward_transactions:
  if reward.get("after_scene")==current.id:_award(reward.id,int(reward.xp))
 if int(state.scene_index)==content.scenes.size()-1:
  assert(Transactions.purse_closed(owner().items))
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
 else:
  var old_map:String=current.map_id
  state.scene_index+=1;state.step=0;state.path_progress={}
  if scene().map_id!=old_map:state.position=[-1.0,-1.0]
func _puzzle_effects(_event: Dictionary,_proof: Dictionary) -> void:pass
func combat_party() -> Array:
 var result:Array=[]
 for id in [Party.HERO,Party.LIU]:
  if not owner().actors.has(id):continue
  var actor:Dictionary=owner().actors[id]
  if actor.get("status")=="asleep":continue
  var skills:Array=["normal_attack","self_guard","guard_ally","sancai_counter","observe"] if id==Party.HERO else ["normal_attack","self_guard","guard_ally","LYY_A01","LYY_A02"]
  if id==Party.LIU and "LYY_A03" in actor.skills:skills.append("LYY_A03")
  result.append({"id":id,"name":"梁萧" if id==Party.HERO else "柳莺莺","team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"mp":actor.mp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":skills,"skill_ranks":{"observe":actor.skill_ranks.LX_A01} if id==Party.HERO else actor.skill_ranks.duplicate(true),"passives":actor.passives.duplicate(),"internal_skill":actor.get("internal_skill","")})
 return result
func puzzle_definition() -> Dictionary:
 return {"id":current_event().get("id",""),"attempt":current_token(),"guided":false,"world":current_event().get("op")=="world_puzzle"}
func puzzle_context() -> Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 return {"chapter":4,"scene_id":scene().id,"map_id":scene().map_id,"actors":owner().actors.duplicate(true),"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"choices":state.choices.duplicate(true),"completed_receipts":state.receipts.duplicate(true),"leader_id":state.leader_id,"party_ids":[Party.HERO,Party.LIU] if owner().actors.has(Party.LIU) else [Party.HERO],"shelter_method":"boat" if "ch04_care_boat" in state.choices.values() else "spring","bell_method":"inscription" if "ch04_bell_inscription" in state.choices.values() else "protect","priority":"fish" if "ch04_l01_fish" in state.choices.values() else "rice"}
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
func make_objective_encounter() -> RefCounted:
 var config:Dictionary=Registry.read_json("chapter_four_encounters").get("encounters",{}).get(current_event().get("id",""),{}).duplicate(true)
 if config.is_empty() or not ResourceLoader.exists(BATTLE_SCRIPT):return null
 config["context"]={"environment_method":"oil" if "ch04_oil" in state.choices.values() else "lamp","initial_mingxin_on_liu":"ch04_r02_stand" in state.choices.values()}
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 if not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot):return null
 return session
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
  owner().world_objects.ch04_spatial_state=receipt.world_state.duplicate(true)
  owner().world_objects.ch04_spatial_state.map_id=scene().map_id
  state.position=receipt.world_state.player_position.duplicate()
 if event.op=="action":
  state.position=proof.position.duplicate()
  var spatial:Dictionary=owner().world_objects.get("ch04_spatial_state",{})
  # Free movement may finish anywhere inside the verified interaction radius.
  # Controlled scenes begin at that action's authored grid anchor, never a fractional free-walk offset.
  var entry_position:Array=maps[scene().map_id].actions[event.id].position.duplicate()
  spatial["player_position"]=entry_position;spatial["map_id"]=scene().map_id
  if event.id=="ride_route":
   spatial["horse_position"]=entry_position.duplicate();spatial["horse_id"]="animal_yanzhi"
  owner().world_objects.ch04_spatial_state=spatial
 return super.complete(token,proof)
func available_leaders() -> Array:
 if current_event().get("op")!="action" or not owner().actors.has(Party.LIU) or owner().actors[Party.LIU].status=="asleep":return []
 return [Party.HERO,Party.LIU]
func switch_leader(id: String) -> bool:
 if id not in available_leaders() or id==state.leader_id:return false
 _record("leader",{"id":id});state.leader_id=id;return true
func open_sidequest(id: String) -> bool:
 var origin:String=scene().map_id
 var ok:=super.open_sidequest(id)
 if ok:state.return_map_id=origin;state.path_progress={}
 return ok
func restore_navigation(saved: Dictionary) -> bool:
 if not saved.get("objective_snapshot") is Dictionary:return false
 if not super.restore_navigation(saved):return false
 if not saved.objective_snapshot.is_empty():
  if current_event().get("op")!="objective_battle":return false
  var session:=make_objective_encounter()
  if session==null or not session.restore(saved.objective_snapshot):return false
  state.objective_snapshot=saved.objective_snapshot.duplicate(true)
 return true
func replay(record: Dictionary) -> bool:
 if record.get("kind")=="leader":return record.token==current_token() and record.proof.size()==1 and record.proof.get("id") is String and switch_leader(record.proof.id)
 return super.replay(record)
func world_context() -> Dictionary:
 var context:=super.world_context()
 context["chapter"]=4;context.controller_id=state.leader_id
 context["exploration_unlocks"]=state.exploration_unlocks.duplicate()
 context.actor_appearances[Party.LIU]="youth_age_16"
 if int(state.liang_age)>=17:context.actor_appearances[Party.HERO]="youth_age_17"
 context["items"]=owner().items.duplicate(true)
 context.present_actor_ids.erase("char_hua_xiaoshuang")
 if scene().map_id=="map_ch04_bell_interior":context.present_actor_ids=[Party.HERO,Party.LIU]
 if current_event().get("op")=="world_puzzle":
  context.active_objectives.append({"id":current_event().id,"name":current_event().name,"type":"interact","enabled":true})
 context.follower_actor_ids=[]
 if owner().actors.has(Party.LIU):
  if Party.LIU not in context.present_actor_ids:context.present_actor_ids.append(Party.LIU)
  if owner().actors[Party.LIU].status=="asleep":context["carried_pair"]={"carrier_id":Party.HERO,"passenger_id":Party.LIU}
  elif state.leader_id==Party.HERO:context.follower_actor_ids=[Party.LIU]
  else:context.follower_actor_ids=[Party.HERO]
 if "horse_call_and_arrival" in state.semantic_commits and "liu_carried_not_combat" not in state.semantic_commits:context["mounted_on"]="animal_yanzhi"
 return context
func optional_window_view() -> Dictionary:
 var deadline:bool=current_event().get("deadline",false)
 var all_archived:bool=true
 for side in ["R02","L01"]:
  if state.optional.get(side,{}).get("status","")!="archived":all_archived=false
 if all_archived:
  return {"title":"西行之前" if deadline else "三日姑苏","body":"修笠与修舟都已完成，约定与记事已经留下。","continue":"确认西行…" if deadline else "先继续江南行旅","confirmation":"两项约定均已归档。准备踏上西行水道吗？" if deadline else "两项约定均已归档。先去枫桥走走吧。"}
 return {"title":"西行之前" if deadline else "三日姑苏","body":"修笠与修舟尚可回头继续。确认西行后，未完成的约定才会记为错过。" if deadline else "雨廊与码头都可慢慢走。暂离这里仍能在西行前返回，不因关闭此页错过支线。","continue":"确认西行…" if deadline else "先继续江南行旅","confirmation":"尚未完成的约定不会发奖。准备踏上西行水道吗？" if deadline else "先去枫桥走走。西行之前仍可回来继续修笠、修舟。"}

func pause_sidequest() -> bool:
 # Leaving the application/menu can save every battle command, but travelling
 # to a different side quest while a battle remains unresolved is not legal.
 if current_event().get("op")=="objective_battle":return false
 state.objective_snapshot={}
 return super.pause_sidequest()

func commit_archived_result(proof: Dictionary) -> bool:
 if not owner()._restoring_summary:return false
 if current_event().get("op")=="objective_battle":
  for actor in combat_party():state.last_battle_panels[actor.id]={"max_hp":actor.max_hp,"max_mp":actor.max_mp}
 return super.commit_archived_result(proof)
