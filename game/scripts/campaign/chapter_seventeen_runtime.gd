class_name ChapterSeventeenRuntime
extends ChapterRuntime
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_seventeen_transactions.gd")
const PUZZLE_SCRIPT="res://scripts/puzzles/chapter_seventeen_puzzle_resolver.gd"
const ENGINE_SCRIPT="res://scripts/combat/chapter_seventeen_engine.gd"
const BATTLE_SCRIPT="res://scripts/combat/chapter_seventeen_encounter.gd"
func _init(campaign:RefCounted,id:int=17)->void:
 var previous:Dictionary=campaign.current_chapter_runtime().state.duplicate(true)
 super(campaign,id)
 for key in ["memories","inventory","knowledge","assists","currency_ledger"]:state[key]=previous[key].duplicate(true)
 for key in ["coins","liang_age","xiaoshuang_age"]:state[key]=previous[key]
 state.optional={"ch17_r07":{"status":"undiscovered","disposition":"open"}}
 state.merge({"leader_id":Party.HERO,"r07_windows":{},"r07_active_window":"","frozen_contexts":{},"objective_snapshot":{},"semantic_commits":[],"verified_puzzles":{},"puzzle_hints":{},"puzzle_attempts":{},"inherited_choices":previous.choices.duplicate(true),"inherited_ch16_optional":previous.optional.duplicate(true)})
 for node in content.scenes:
  node.choices=[]
  for e in runtime.scenes[node.id]:
   if e.op=="choice":node.choices.append_array(content.choice_groups[e.group].options.duplicate(true))
static func can_enter(c:RefCounted)->bool:
 return c.active_chapter==16 and c.state.finished and int(c.actors.get(Party.HERO,{}).get("xp",0))>=43225 and int(c.actors[Party.HERO].get("hp",0))>0 and c.world_objects.get("ch16_journey",{}).get("stage")=="eastbound" and c.actors.get("char_axue",{}).get("status")=="dead"
func _choice_key(event:Dictionary)->String:return str(event.get("choice_key",event.get("group","")))
func available_choices()->Array:
 return content.choice_groups[current_event().group].options.duplicate(true) if current_event().get("op")=="choice" else []
func selected_choice()->Dictionary:
 var group:Dictionary=content.choice_groups.get(current_event().get("group",""),{})
 for choice in group.get("options",[]):
  if choice.id==state.choices.get(group.get("choice_key",""),""):return choice
 return {}
func presentation()->Array:
 var e:=current_event()
 if e.get("op")=="branch_feedback":return [{"speaker":"旁白","kind":"stage","text":selected_choice().get("feedback","")}]
 if e.get("op")=="dialogue":
  var lines:Array=[]
  for id in e.refs:lines.append(content.dialogue_registry[id].duplicate(true))
  if e.id=="ch17_reunion_echo" and "MEM_MQ13_CHAOYUN_WILLOW_HAT" in state.memories:lines.append({"speaker":"旁白","kind":"stage","text":"旧笠还在往日记事里。柳莺莺没有拿十年前的离别责问来客。"})
  return _format(lines)
 return super.presentation()
func _award(id:String,amount:int)->void:
 if Party.award(owner().actors,owner().reward_ledger,id,amount):state.xp=int(owner().actors[Party.HERO].xp)
func _transactions_valid(event:Dictionary,candidate:Dictionary)->bool:
 var actors:Dictionary=owner().actors.duplicate(true);var items:Dictionary=owner().items.duplicate(true);var world:Dictionary=owner().world_objects.duplicate(true);var staged:Dictionary=candidate.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_seventeen_event" and not Transactions.apply(effect.id,actors,items,staged,world):return false
 return true
func _effect(effect:Dictionary)->void:
 if effect.op=="chapter_seventeen_event":
  if not Transactions.apply(effect.id,owner().actors,owner().items,state,owner().world_objects):push_error("MQ17 transaction rejected: "+str(effect.id))
 elif effect.op=="chapter_seventeen_reward":_award(effect.id,int(effect.xp))
 else:super._effect(effect)
func _finish_scene()->void:
 var current:=scene()
 for receipt in current.completion_gate.all_of:
  if receipt not in state.receipts.get(current.id,[]):push_error("MQ17 incomplete scene: "+str(receipt));return
 if state.scope!="main":
  state.optional[state.scope]={"status":"archived","disposition":"completed"}
  _memory(current.completion_memory);_award(current.reward_transaction,int(current.xp))
  state.scope="main";state.side_step=0;state.position=state.return_position.duplicate();puzzle_session=null
  return
 state.completed.append(current.id)
 if state.scene_index==content.scenes.size()-1:
  state.finished=true;state.quest_phase="ARCHIVED_ECHO";_memory(content.completion_memory)
  state.position=maps[current.map_id].spawn.duplicate();state.path_progress={};state.objective_snapshot={};state.puzzle_attempts={}
 else:
  state.scene_index+=1;state.step=0;state.path_progress={}
  if scene().map_id!=current.map_id:state.position=[-1.0,-1.0]
func actor_panel(id:String)->Dictionary:return owner().actors[id].duplicate(true)
func control_actor_id()->String:return str(scene().get("controller",Party.HERO))
func battle_actor_ids()->Array:
 return [Party.HERO,Transactions.F] if current_event().get("id")=="ch17_road_wolves" else [Party.HERO,Transactions.L,Transactions.F]
func combat_party()->Array:
 var party:Array=[]
 for id in battle_actor_ids():
  var actor:Dictionary=actor_panel(id)
  actor.id=id;actor.name={Party.HERO:"梁萧",Transactions.L:"柳莺莺",Transactions.F:"风怜"}[id];actor.team="party";actor.controllable=true;actor.fixed_level=int(actor.level)
  actor.internal_stats_applied=true;actor.panel_internal_skill=actor.get("internal_skill","")
  actor.passives=actor.get("equipped_passives",actor.get("passives",[])).duplicate()
  actor.learned_passives=actor.get("learned_passives",actor.passives).duplicate()
  actor.skills=["normal_attack","self_guard","guard_ally"]
  for skill in actor.equipped_active_skills:actor.skills.append({"LX_A01":"observe","LX_A02":"sancai_counter"}.get(skill,skill))
  party.append(actor)
 return party
func puzzle_context()->Dictionary:
 if state.frozen_contexts.has(current_token()):return state.frozen_contexts[current_token()].duplicate(true)
 var evidence:Array=[]
 for key in Transactions.EVIDENCE:
  if owner().world_objects.get("ch17_evidence",{}).get(key,false):evidence.append(key)
 return {"chapter":17,"current_token":current_token(),"scene_id":scene().id,"map_id":scene().map_id,"control_actor_id":control_actor_id(),"attempt_generation":int(state.puzzle_attempts.get(current_token(),0)),"evidence":evidence,"roof_method":state.choices.get("r07_method",""),"amo_exposed":owner().world_objects.get("ch17_amo",{}).get("exposed",false),"b13_boundary":owner().world_objects.get("ch17_b13_boundary",{}).duplicate(true)}
func puzzle_definition()->Dictionary:return {"id":current_event().get("puzzle_id",""),"attempt":current_token(),"guided":false,"world":false}
func make_puzzle()->RefCounted:
 if current_event().get("op")!="puzzle":return null
 if puzzle_session!=null:return puzzle_session
 var session:RefCounted=load(PUZZLE_SCRIPT).new();var definition:=puzzle_definition()
 if not session.begin(definition.id,definition.attempt,puzzle_context()):return null
 if state.puzzle_records.has(current_token()) and not session.restore(state.puzzle_records[current_token()],puzzle_context()):return null
 puzzle_session=session;return session
func puzzle_input(token:String,action:Dictionary)->Dictionary:
 if token!=current_token():return {"ok":false,"message":"操作已过期"}
 var session:=make_puzzle()
 if session==null:return {"ok":false,"message":"机关尚未就绪"}
 # Restart is a replayable campaign command, not a mutable success flag. A new
 # context/revision epoch bounds each attempt and prevents the 512-input cap
 # from trapping the player. Hints persist; already committed events never reset.
 if action.get("type")=="reset":
  if action.size()>2 or not action.has("type") or (action.size()==2 and not action.has("revision")):return {"ok":false,"message":"无效重置"}
  if action.has("revision") and (not load(PUZZLE_SCRIPT).whole(action.revision,1,11000000) or int(action.revision)!=int(session.state.revision)):return {"ok":false,"message":"操作已过期"}
  var hint_level:int=session.state.hint_level
  state.puzzle_attempts[token]=int(state.puzzle_attempts.get(token,0))+1
  state.frozen_contexts.erase(token);state.puzzle_records.erase(token);state.puzzle_snapshot={};puzzle_session=null
  session=make_puzzle()
  for i in range(hint_level):session.apply_input({"type":"hint"})
  state.frozen_contexts[token]=session.context.duplicate(true)
  state.puzzle_records[token]=session.snapshot();state.puzzle_snapshot=session.snapshot()
  _record("puzzle_input",{"action":action})
  return {"ok":true,"accepted":true,"message":"机关已重置，提示记录保留。"}
 var before:Dictionary=session.snapshot();var result:Dictionary=session.apply_input(action)
 if not Canonical.equivalent(before,session.snapshot()):
  if not state.frozen_contexts.has(token):state.frozen_contexts[token]=session.context.duplicate(true)
  _record("puzzle_input",{"action":action});state.puzzle_records[token]=session.snapshot();state.puzzle_snapshot=session.snapshot()
 if session.get_view().state.complete:complete(token,{"receipts":session.get_receipts()})
 return result
func _puzzle_effects(_e:Dictionary,_proof:Dictionary)->void:pass
func _new_objective_encounter()->RefCounted:
 var id:String=current_event().get("id","")
 if current_event().get("op")!="objective_battle":return null
 if id=="ch17_road_wolves" and owner().items.get("item_ch17_tianfa",{}).get("owner")!=Transactions.F:return null
 if id=="ch17_wolf_double" and not owner().world_objects.get("ch17_prepared",{}).get("ready",false):return null
 if id=="ch17_amo" and not owner().world_objects.get("ch17_amo",{}).get("exposed",false):return null
 var config:Dictionary=load(ENGINE_SCRIPT).encounter_config(id)
 if config.is_empty():return null
 config.context=puzzle_context()
 var session:RefCounted=load(BATTLE_SCRIPT).new(owner().rules,owner().combat,config,combat_party(),current_token())
 return null if session.engine.entry_error!="" else session
func make_objective_encounter()->RefCounted:
 var session:=_new_objective_encounter()
 if session==null or (not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot)):return null
 return session
func save_objective_checkpoint(session:RefCounted)->bool:
 if current_event().get("op")!="objective_battle" or session==null:return false
 var verifier:=_new_objective_encounter()
 if verifier==null or not verifier.restore(session.snapshot()):return false
 state.objective_snapshot=session.snapshot();return true
func accept_objective(token:String,proof:Dictionary)->bool:return complete(token,proof) if current_event().get("op")=="objective_battle" else false
func navigation_valid(value:Variant,map_id:String)->bool:
 if not CampaignState._position_valid(value):return false
 if float(value[0])==-1.0 and float(value[1])==-1.0:return true
 var map:Dictionary=maps.get(map_id,{})
 if map.is_empty():return false
 var b:Array=map.walk_bounds;var p:=Vector2(value[0],value[1])
 if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]:return false
 for r in map.solids:
  if Rect2(r[0],r[1],r[2],r[3]).grow_individual(8,4,8,4).has_point(p):return false
 return true
func complete(token:String,proof:Dictionary)->bool:
 if token.is_empty() or token!=current_token() or state.finished:return false
 var e:=current_event().duplicate(true);var candidate:Dictionary=state.duplicate(true);var final_actors:Array=[]
 match e.op:
  "dialogue","stage","branch_feedback":
   if not proof.is_empty():return false
  "choice":
   if proof.size()!=1 or not proof.get("choice_id") is String:return false
   var permitted:=false
   for option in available_choices():
    if option.id==proof.choice_id:permitted=true
   if not permitted:return false
  "action":
   if proof.size()!=2 or not proof.has_all(["map_id","position"]) or proof.map_id!=scene().map_id or not navigation_valid(proof.position,scene().map_id):return false
   var geometry:Dictionary=maps[scene().map_id].actions.get(e.id,{})
   if geometry.is_empty() or Vector2(proof.position[0],proof.position[1]).distance_to(Vector2(geometry.position[0],geometry.position[1]))>float(geometry.radius):return false
   candidate.position=proof.position.duplicate()
  "quest_window":
   if proof.size()!=1 or not proof.get("closure_acknowledged") is bool or not proof.closure_acknowledged:return false
  "puzzle":
   var live:=make_puzzle()
   if live==null or not live.get_view().state.complete or not Canonical.equivalent(proof,{"receipts":live.get_receipts()}):return false
   var verifier:RefCounted=load(PUZZLE_SCRIPT).new()
   if not verifier.restore(live.snapshot(),puzzle_context()):return false
   candidate.verified_puzzles[e.puzzle_id]=true;candidate.puzzle_hints[e.puzzle_id]=int(live.state.hint_level)
  "objective_battle":
   var verifier:=_new_objective_encounter()
   if verifier==null or proof.get("attempt_id")!=token:return false
   var verified:Dictionary=verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party())
   if verified.is_empty():return false
   var staged:Dictionary=owner().actors.duplicate(true)
   if not Party.accept_resources(staged,verified.final_actors,battle_actor_ids()) or staged[Party.HERO].hp<=0:return false
   final_actors=verified.final_actors.duplicate(true);candidate.verified_puzzles[e.id]=true;candidate.objective_snapshot={}
  _:return false
 if not _transactions_valid(e,candidate):return false
 state=candidate
 if not final_actors.is_empty():Party.accept_resources(owner().actors,final_actors,battle_actor_ids())
 var was_side:bool=state.scope!="main"
 var ok:bool=super.complete(token,proof)
 if ok and was_side:_record_side_progress()
 return ok
func commit_archived_result(proof:Dictionary)->bool:
 if not owner()._restoring_summary:return false
 var e:=current_event();var candidate:Dictionary=state.duplicate(true)
 if e.op in ["puzzle","objective_battle"]:candidate.verified_puzzles[e.get("puzzle_id",e.id)]=true
 if not _transactions_valid(e,candidate):return false
 state.verified_puzzles=candidate.verified_puzzles
 var was_side:bool=state.scope!="main"
 var ok:bool=super.commit_archived_result(proof)
 if ok and was_side:_record_side_progress()
 return ok
func restore_navigation(saved:Dictionary)->bool:
 if not saved.get("objective_snapshot") is Dictionary:return false
 if not saved.objective_snapshot.is_empty():
  var session:=_new_objective_encounter()
  if session==null or not session.restore(saved.objective_snapshot):return false
 if not super.restore_navigation(saved):return false
 state.objective_snapshot=saved.objective_snapshot.duplicate(true);return true
func world_context()->Dictionary:
 var ctx:Dictionary=super.world_context();ctx.chapter=17;ctx.controller_id=control_actor_id()
 for id in [Party.HERO,Transactions.L,Transactions.F]:ctx.actor_appearances[id]="adult"
 ctx.follower_actor_ids=[]
 for id in owner().actors:
  if owner().actors[id].get("status")=="dead":
   if id not in ctx.dead_actor_ids:ctx.dead_actor_ids.append(id)
   ctx.present_actor_ids.erase(id)
  elif id not in _scene_actor_ids():
   if id not in ctx.departed_actor_ids:ctx.departed_actor_ids.append(id)
   ctx.present_actor_ids.erase(id)
 for id in ["npc_ch17_taboluo","npc_ch17_zhuque"]:
  if (id=="npc_ch17_taboluo" and owner().world_objects.get("ch17_merchants",{}).get("status")=="dead") or (id=="npc_ch17_zhuque" and owner().world_objects.get("ch17_zhuque",{}).get("status")=="dead"):
   ctx.dead_actor_ids.append(id);ctx.present_actor_ids.erase(id)
 if owner().world_objects.get("ch17_amo",{}).get("status")=="dead":ctx.dead_actor_ids.append("npc_ch17_amo");ctx.present_actor_ids.erase("npc_ch17_amo")
 ctx.world_objects=owner().world_objects.duplicate(true);ctx.items=owner().items.duplicate(true)
 return ctx
func _scene_actor_ids()->Array:
 var ids:Array=[]
 for actor in content.actor_registry:
  if actor.name in scene().cast:ids.append(actor.id)
 return ids
func party_journal_text()->String:
 return "柳莺莺是小禽村主人；村务与建屋由她作主。风怜使用固定限定面板，不领取核心角色经验。\n天罚剑匣有独立托管记录；本章未授予第19章终极剑法。"
func open_sidequest(id:String)->bool:
 var window:String=current_token()
 if not super.open_sidequest(id):return false
 state.r07_active_window=window;_record_side_progress();return true
func _record_side_progress()->void:
 state.r07_windows[state.r07_active_window]=runtime.side_quests.ch17_r07.size() if state.scope=="main" else int(state.side_step)
func optional_window_view()->Dictionary:
 var last:bool=current_event().get("id")=="ch17_roof_last_window"
 return {"title":"离山前的新屋" if last else "小禽村的约定","body":"柳莺莺主持建屋，梁萧与风怜协作。完成后留下村民的谢意与记事。","continue":"处理完约定，准备离山…" if last else "先去查清狼哨…","confirmation":"离山后，未完成的新屋约定将记为错过，不发奖励。" if last else "先去调查狼哨。离山前还可回到这里完成新屋。"}
func available_leaders()->Array:return []
func switch_leader(_id:String)->bool:return false
