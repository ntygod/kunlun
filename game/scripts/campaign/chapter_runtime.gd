class_name ChapterRuntime
extends RefCounted
## Registered typed steps plus a single chronological log for main and optional play.
const Registry = preload("res://scripts/campaign/chapter_registry.gd")
const Canonical = preload("res://scripts/campaign/encounter_session.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
var owner_ref: WeakRef
var content: Dictionary
var runtime: Dictionary
var maps: Dictionary
var state: Dictionary
var puzzle_session: RefCounted
func _init(owner: RefCounted, id: int = 2) -> void:
	owner_ref = weakref(owner)
	var registered := Registry.definition(id)
	content = registered.content
	runtime = registered.runtime
	maps = registered.maps
	state = {"chapter":id,"quest_id":content.quest_id,"quest_phase":"INVESTIGATING","scene_index":0,"step":0,
		"scope":"main","side_step":0,"return_position":[-1.0,-1.0],"completed":[],"choices":{},"receipts":{},
		"position":[-1.0,-1.0],"path_progress":{},"xp":owner.actors.char_liang_xiao.xp,"finished":false,
		"memories":owner.progress.memories.duplicate(),"inventory":owner.progress.inventory.duplicate(),"chronology":[],
		"optional":{"ch02_r01":{"status":"undiscovered","disposition":"open"},"ch02_k01":{"status":"undiscovered","disposition":"open"}},
		"measurements":[],"assists":[],"knowledge":[],"currency_ledger":{},"coins":0,"season":"spring",
		"puzzle_snapshot":{},"puzzle_records":{},"controller_override":"","liang_age":10,"xiaoshuang_age":10}
	owner.actors.char_liang_xiao["skill_ranks"] = {"LX_A01":1,"LX_A02":1}
	owner.actors.char_liang_xiao["passives"] = []
	owner.actors["char_hua_xiaoshuang"] = {"status":"story_support","kind":"exploration_only","age":10}
	owner.actors["follower_jinlinger"] = {"status":"not_adopted","kind":"noncombat_golden_monkey"}
func owner() -> RefCounted: return owner_ref.get_ref()
func scene() -> Dictionary:
	var result: Dictionary
	if state.scope == "main": result = content.scenes[int(state.scene_index)].duplicate(true)
	else:
		for quest in content.side_quests:
			if quest.id == state.scope: result = quest.duplicate(true); break
	result["objective"] = result.get("objective",result.title)
	result["map_tiles"] = result.get("map_tiles",[16,10])
	result["style"] = result.get("style","study")
	return result
func sequence() -> Array:
	return runtime.scenes[scene().id] if state.scope == "main" else runtime.side_quests[state.scope]
func current_event() -> Dictionary:
	if state.finished: return {}
	return sequence()[int(state.step if state.scope == "main" else state.side_step)]
func current_token() -> String: return current_event().get("step_id","")
func _record(kind: String, proof: Dictionary) -> void:
	state.chronology.append({"kind":kind,"token":current_token(),"proof":proof.duplicate(true)})
func _memory(id: String) -> void:
	if id != "" and not id in state.memories: state.memories.append(id)
func _item(id: String, who: String = "char_liang_xiao", status: String = "carried") -> void:
	owner().items[id] = {"owner":who,"state":status}
func _inventory() -> void:
	state.inventory = []
	for id in owner().items:
		if owner().items[id].state == "carried": state.inventory.append(id)
func _award(id: String, amount: int) -> void:
	if owner().reward_ledger.has(id): return
	owner().reward_ledger[id] = amount
	var total := 0
	for value in owner().reward_ledger.values(): total += int(value)
	var actor: Dictionary = owner().actors.char_liang_xiao
	var old_hp := int(actor.max_hp)
	actor.merge(Growth.liang_panel(total,actor.equipment),true)
	actor.hp = mini(int(actor.max_hp),int(actor.hp)+int(actor.max_hp)-old_hp)
	state.xp = total
func available_choices() -> Array:
	return scene().get(current_event().get("group","choices"),[]).duplicate(true)
func selected_choice() -> Dictionary:
	var id: String = state.choices.get(scene().id,"")
	for choice in scene().get("choices",[]):
		if choice.id == id: return choice
	return {}
func presentation() -> Array:
	var event := current_event()
	var result: Array = []
	match event.op:
		"stage": return [{"speaker":"旁白","text":event.text,"kind":"stage"}]
		"branch_feedback": return _format(selected_choice().get("feedback_events",[]))
		"conditional_echoes":
			for conditional in scene().get("conditional_events",[]):
				if conditional.requires_memory in state.memories: result.append_array(_format(conditional.events))
			if result.is_empty(): result.append({"speaker":"旁白","text":"窗外风声渐紧。灯下只剩梁萧一人。","kind":"stage"})
			return result
		"dialogue":
			var last: int = scene().dialogue.size()-1 if int(event.end)<0 else int(event.end)
			for i in range(int(event.start),last+1):
				var line: Dictionary = scene().dialogue[i].duplicate(true)
				for override in scene().get("effective_dialogue_overrides",[]):
					var at := int(override.get("source_unit_index",override.get("dialogue_index",-1)))
					if at != i: continue
					if override.has("when_choice") and not override.when_choice in state.choices.values(): continue
					line[override.get("field","text")] = override.get("replacement",override.get("text",""))
				result.append_array(_format([line]))
	return result
func _format(lines: Array) -> Array:
	var result: Array = []
	for line in lines:
		var kind: String = line.get("kind","speech")
		result.append({"speaker":"旁白" if kind == "stage" else line.get("speaker","旁白"),"text":line.get("text",line.get("direction","")),"kind":kind,"stage_direction":line.get("stage_direction","")})
	return result
func finish_dialogue(token: String) -> bool:
	if token != current_token() or current_event().get("op","") not in ["dialogue","stage","branch_feedback","conditional_echoes"]: return false
	return complete(token,{})
func choose(token: String, id: String) -> bool:
	if token != current_token() or current_event().get("op","") != "choice": return false
	for choice in available_choices():
		if choice.id == id: return complete(token,{"choice_id":id})
	return false
func complete_action(token: String, id: String, proof: Dictionary) -> bool:
	var event := current_event()
	if token != current_token() or event.get("op","") != "action" or event.id != id: return false
	var geometry: Dictionary = maps.get(scene().map_id,{}).get("actions",{}).get(id,{})
	if geometry.is_empty() or not proof.get("map_id") is String or proof.map_id != scene().map_id or not CampaignState._position_valid(proof.get("position")): return false
	var at := Vector2(proof.position[0],proof.position[1])
	var target := Vector2(geometry.position[0],geometry.position[1])
	if at.distance_to(target)>float(geometry.get("radius",24)): return false
	if event.kind == "route":
		if not proof.get("complete") is bool or not proof.complete or not _integer(proof.get("index")) or not _integer(proof.get("total")): return false
		var total: int = maps.get(scene().map_id,{}).get("paths",{}).get(id,[]).size()
		if total == 0 or int(proof.index) != total or int(proof.total) != total: return false
	return complete(token,proof)
func complete(token: String, proof: Dictionary) -> bool:
	if state.finished or token == "" or token != current_token(): return false
	var event := current_event()
	_record("complete",proof)
	var receipts: Array = state.receipts.get(scene().id,[])
	for id in event.get("receipts",[]):
		if not id in receipts: receipts.append(id)
	if event.op in ["branch_practice","branch_feedback"]:
		var selected := selected_choice()
		if selected.has("required_receipt") and not selected.required_receipt in receipts: receipts.append(selected.required_receipt)
	state.receipts[scene().id] = receipts
	if event.op == "choice":
		for choice in available_choices():
			if choice.id != proof.choice_id: continue
			state.choices[scene().id+":responsibility" if event.get("group","") == "additional_choices" else scene().id] = choice.id
			_memory(choice.get("memory_tag",choice.get("flag",choice.id+"_memory")))
			for effect in choice.get("effects",[]): _effect(effect)
	if event.op == "action" and event.has("measurement") and not event.measurement in state.measurements: state.measurements.append(event.measurement)
	if event.op == "conditional_echoes":
		for conditional in scene().get("conditional_events",[]):
			if conditional.requires_memory in state.memories:
				for effect in conditional.effects: _effect(effect)
	if event.op == "objective_battle":
		for actor in proof.get("final_actors",[]):
			if actor.id == "char_liang_xiao":
				owner().actors.char_liang_xiao.hp = int(actor.hp)
				owner().actors.char_liang_xiao.mp = int(actor.mp)
		var id := "reward_mq02_protect_qin_once" if event.id == "enc_ch02_protect_qin" else "reward_mq02_antidote_once"
		_award(id,60)
		if event.id == "enc_ch02_antidote_escape": _item("item_ch02_antidote","char_hua_qingyuan","consumed")
	if event.op == "puzzle": _puzzle_effects(event,proof)
	if event.has("season"): state.season = event.season
	if state.scope != "main":
		if event.op == "action": state.optional[state.scope].status = "investigating"
		elif event.op == "puzzle": state.optional[state.scope].status = "aftermath"
	for effect in event.get("effects",[]): _effect(effect)
	state.puzzle_snapshot = {}
	puzzle_session = null
	if state.scope == "main": state.step += 1
	else: state.side_step += 1
	if int(state.step if state.scope == "main" else state.side_step) >= sequence().size(): _finish_scene()
	_inventory()
	return true
func _effect(effect: Dictionary) -> void:
	match effect.op:
		"add_memory": _memory(effect.id)
		"grant", "grant_item": _item(effect.id,effect.get("owner","char_liang_xiao"))
		"restore_liang": state.controller_override = "char_liang_xiao"
		"adopt_monkey": owner().actors.follower_jinlinger.status = "follower"
		"xiaoshuang_absent": owner().actors.char_hua_xiaoshuang.status = "absent_safe"
		"isolate": owner().actors.char_hua_xiaoshuang.status = "visits_restricted"
		"close_optional":
			for quest in state.optional:
				if state.optional[quest].status != "archived": state.optional[quest] = {"status":"missed","disposition":"declined" if state.optional[quest].disposition == "declined" else "missed"}
		"age":
			state.liang_age = effect.liang
			state.xiaoshuang_age = effect.xiaoshuang
			owner().actors.char_liang_xiao.age = effect.liang
			owner().actors.char_hua_xiaoshuang.age = effect.xiaoshuang
		"equip_chapter_two":
			var actor: Dictionary = owner().actors.char_liang_xiao
			actor.merge(Growth.liang_panel(int(state.xp),{"max_hp":30,"max_mp":5,"atk":8,"def":5,"spd":1}),true)
			actor.hp = actor.max_hp
			actor.mp = actor.max_mp
			_item("item_ch02_standard_gear")
func _finish_scene() -> void:
	var current := scene()
	for required in current.completion_gate.get("all_of",[]): assert(required in state.receipts.get(current.id,[]),"Unmet chapter gate "+required)
	if state.scope != "main":
		var id: String = state.scope
		state.optional[id] = {"status":"archived","disposition":"completed"}
		_memory(current.completion_memory)
		_award(current.reward_transaction,int(current.xp))
		if id == "ch02_r01":
			_item("item_ch02_unclosed_workbook")
			state.assists.append("assist_ch02_trial_reflection")
		else:
			_item("item_ch02_shadow_measurement_notes")
			state.assists.append("assist_ch02_geometry_guides")
			state.knowledge.append("LX_A04_future_upgrade_eligible")
		state.scope = "main"
		state.side_step = 0
		state.position = state.return_position.duplicate()
		return
	state.completed.append(current.id)
	for transaction in content.reward_transactions:
		if transaction.get("trigger","") == current.transaction_id: _award(transaction.id,int(transaction.xp))
	if current.id == "ch02_statue_shadows": state.knowledge.append_array(["daxian_heart_primer","phantom_dust_movement"])
	if current.id == "ch02_nine_sums": owner().actors.char_liang_xiao.skill_ranks.LX_A01 = 2
	if current.id == "ch02_tenth_sum_crisis":
		_award("reward_mq02_pz01_once",500)
		state.knowledge.append_array(["nine_nine_return_theory","self_reliance"])
		owner().actors.char_liang_xiao.passives.append("LX_P01")
		if not "LX_P01" in owner().actors.char_liang_xiao.skills: owner().actors.char_liang_xiao.skills.append("LX_P01")
	if int(state.scene_index) == content.scenes.size()-1:
		state.currency_ledger["reward_mq02_coins_once"] = 250
		state.coins = 250
		state.finished = true
		state.quest_phase = "ARCHIVED_ECHO"
		_memory(content.completion_memory)
	else:
		state.scene_index += 1
		state.step = 0
		state.position = [-1.0,-1.0]
		state.path_progress = {}
		state.controller_override = ""
		if scene().id == "ch02_west_lake_visit": _effect({"op":"age","liang":11,"xiaoshuang":10})
func open_sidequest(id: String) -> bool:
	if current_event().get("op","") != "quest_window" or not state.optional.has(id) or state.optional[id].status in ["archived","missed"]: return false
	if not navigation_valid(state.position,scene().map_id): return false
	_record("open_side",{"id":id,"position":state.position.duplicate()})
	state.return_position = state.position.duplicate()
	state.scope = id
	state.side_step = int(state.optional[id].get("resume_step",0))
	state.position = state.optional[id].get("resume_position",[-1.0,-1.0]).duplicate()
	if state.optional[id].status == "undiscovered": state.optional[id].status = "accepted"
	state.optional[id].disposition = "active"
	return true
func disposition(id: String, value: String) -> bool:
	if current_event().get("op","") != "quest_window" or not state.optional.has(id) or value not in ["deferred","declined"] or state.optional[id].status == "archived": return false
	_record("disposition",{"id":id,"value":value})
	state.optional[id].disposition = value
	return true
func close_window(token: String) -> bool:
	if token != current_token() or current_event().get("op","") != "quest_window": return false
	return complete(token,{"closure_acknowledged":true})
func _puzzle_effects(event: Dictionary, proof: Dictionary) -> void:
	if event.id == "r01":
		if proof.get("choice_id","") == "ch02_r01_keep_later":
			_item("item_ch02_first_wrong_page","char_hua_xiaoshuang")
			state.choices.ch02_r01 = "ch02_r01_keep_later"
		else: state.choices.ch02_r01 = "ch02_r01_keep_all"
	if event.id == "k01": state.choices.ch02_k01 = proof.get("choice_id","")
	if event.id == "pz01_problem_06": state.knowledge.append("paper_river_volume")
static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == int(value)
func world_context() -> Dictionary:
	var current := scene()
	var controller: String = state.controller_override if state.controller_override != "" else current.get("controller","char_liang_xiao")
	if current.id in ["ch02_west_lake_visit","ch02_pavilion_scout"] and state.controller_override == "": controller = "char_hua_xiaoshuang"
	var context := {"controller_id":controller,"actor_appearances":{},"present_actor_ids":[],"dead_actor_ids":["char_liang_wenjing"],"departed_actor_ids":["char_xiao_yuling"],"active_objectives":[],"completed_actions":[],"world_objects":owner().world_objects.duplicate(true),"story_age":int(state.liang_age),"season":current_event().get("season",state.season),"follower_actor_ids":[]}
	context.actor_appearances.char_liang_xiao = "youth_age_16" if int(state.liang_age)>=16 else ("child_age_12" if int(state.liang_age)>=12 else "child_age_10")
	context.actor_appearances.char_hua_xiaoshuang = "youth_age_15" if int(state.xiaoshuang_age)>=15 else "child_age_11"
	for actor in content.actor_registry:
		if actor.name in current.get("cast",[]): context.present_actor_ids.append(actor.id)
	for id in ["follower_baichier","follower_jinlinger"]:
		if owner().actors.get(id,{}).get("status","") == "follower":
			context.present_actor_ids.append(id)
			context.follower_actor_ids.append(id)
	for receipts in state.receipts.values(): context.completed_actions.append_array(receipts)
	var event := current_event()
	if event.get("op","") == "branch_practice" and puzzle_definition().id == "shadow_practice":
		context.active_objectives.append({"id":"shadow_practice_verified","name":"踩亮起的石影，E演练","type":"puzzle","enabled":true})
	if event.get("op","") in ["action","puzzle"]:
		var id: String = event.get("entry_id",event.get("id",""))
		context.active_objectives.append({"id":id,"name":event.name,"type":"route" if event.get("kind","") == "route" else "interact","enabled":true})
		if event.has("carrying"): context["carried_pair"] = {"carrier_id":"char_liang_xiao","passenger_id":event.carrying}
	return context
func replay(record: Dictionary) -> bool:
	if state.finished or record.token == "" or record.token != current_token(): return false
	match record.kind:
		"open_side":
			if not navigation_valid(record.proof.get("position"),scene().map_id): return false
			state.position = record.proof.position.duplicate()
			return open_sidequest(str(record.proof.get("id","")))
		"pause_side":
			if not navigation_valid(record.proof.get("position"),scene().map_id): return false
			state.position = record.proof.position.duplicate()
			return pause_sidequest()
		"puzzle_input":
			if not record.proof.get("action") is Dictionary: return false
			var size_before: int = state.chronology.size()
			puzzle_input(record.token,record.proof.action)
			return state.chronology.size() > size_before
		"disposition": return disposition(str(record.proof.get("id","")),str(record.proof.get("value","")))
		"complete":
			var event := current_event()
			match event.op:
				"dialogue","stage","branch_feedback","conditional_echoes": return finish_dialogue(record.token)
				"choice": return choose(record.token,str(record.proof.get("choice_id","")))
				"action": return complete_action(record.token,event.id,record.proof)
				"objective_battle": return accept_objective(record.token,record.proof)
				"quest_window": return close_window(record.token) if record.proof.get("closure_acknowledged") is bool and record.proof.closure_acknowledged else false
	return false
func restore_navigation(saved: Dictionary) -> bool:
	if not navigation_valid(saved.get("position"),scene().map_id) or not navigation_valid(saved.get("return_position"),"map_ch02_study") or not saved.get("path_progress") is Dictionary: return false
	var allowed := {}
	var events := sequence()
	for i in range(mini(int(state.step if state.scope == "main" else state.side_step)+1,events.size())):
		var event: Dictionary = events[i]
		if event.get("kind","") == "route": allowed[event.id] = maps.get(scene().map_id,{}).get("paths",{}).get(event.id,[]).size()
	for id in saved.path_progress:
		if not id is String or not allowed.has(id) or not _integer(saved.path_progress[id]) or int(saved.path_progress[id]) < 0 or int(saved.path_progress[id]) > int(allowed[id]): return false
	state.position = saved.position.duplicate()
	state.return_position = saved.return_position.duplicate()
	state.path_progress = saved.path_progress.duplicate()
	return true
func puzzle_definition() -> Dictionary:
	var event := current_event()
	var id: String = event.get("id","")
	if event.op == "branch_practice":
		var choice := selected_choice()
		if scene().id == "ch02_statue_shadows": id = "shadow_practice" if choice.id.ends_with("_a") else "breath_practice"
		elif scene().id == "ch02_lamp_lesson": id = "name_practice" if choice.id.ends_with("_a") else "pz01_problem_01"
		else: id = "burn_practice" if choice.id.ends_with("_a") else "step_practice"
	if id.begins_with("pz01_tenth_"): id = "pz01_tenth"
	return {"id":id,"attempt":"ch02_tenth_sum_crisis:pz01_tenth" if id == "pz01_tenth" else current_token(),"guided":id in ["jing_writing","name_practice","shadow_practice","breath_practice","burn_practice","step_practice"]}
func puzzle_context() -> Dictionary:
	var geometry: Dictionary = maps.get(scene().map_id,{}).get("actions",{}).get("shadow_practice_verified",{}).duplicate(true)
	# The authoring map also exposes this geometry via world.get_objective_geometry.
	geometry["waypoints"] = maps.get(scene().map_id,{}).get("paths",{}).get("shadow_practice_verified",[]).duplicate(true)
	geometry["observed_measurements"] = state.measurements.duplicate()
	geometry["assist_flags"] = state.assists.duplicate()
	geometry["authorize_acceptance"] = current_event().get("id","") == "pz01_tenth_acceptance"
	return geometry
func make_puzzle() -> RefCounted:
	if current_event().get("op","") not in ["puzzle","branch_practice"]: return null
	if puzzle_session != null: return puzzle_session
	var definition := puzzle_definition()
	var path := "res://scripts/campaign/guided_exercise.gd" if definition.guided else "res://scripts/puzzles/chapter_puzzle_resolver.gd"
	puzzle_session = load(path).new()
	puzzle_session.begin(definition.id,definition.attempt,puzzle_context())
	if state.puzzle_records.has(definition.attempt):
		if not puzzle_session.restore(state.puzzle_records[definition.attempt],puzzle_context()): puzzle_session = null; return null
	if definition.id == "k01" and puzzle_session.input_log.is_empty():
		for key in state.measurements: puzzle_session.apply_input({"type":"observe","key":key})
	return puzzle_session
func puzzle_input(token: String, action: Dictionary) -> Dictionary:
	if token != current_token(): return {"ok":false,"message":"操作已过期"}
	var session := make_puzzle()
	if session == null: return {"ok":false,"message":"机关尚未登记"}
	var before: Dictionary = session.snapshot()
	var result: Dictionary = session.apply_input(action)
	if not Canonical.equivalent(before,session.snapshot()):
		_record("puzzle_input",{"action":action})
		state.puzzle_records[puzzle_definition().attempt] = session.snapshot()
		state.puzzle_snapshot = session.snapshot()
	var proof: Dictionary = session.receipt()
	if current_event().get("id","") == "pz01_tenth_overload":
		for intermediate in session.get_receipts():
			if intermediate.objective_id == "pz01_tenth_overload_seen": proof = intermediate
	if state.scope != "main":
		var snapshot_state: Dictionary = session.get_view().state
		state.optional[state.scope].status = ("choice_recorded" if action.get("type","") == "method" else "executing") if snapshot_state.get("method","") != "" else "investigating"
	if not proof.is_empty():
		# Completion is recorded separately; both records replay the same resolver.
		complete(token,proof)
	return result
func make_objective_encounter() -> RefCounted:
	var data := Registry.read_json("chapter_two_encounters")
	var encounters: Variant = data.get("encounters",{})
	var id: String = current_event().get("id","")
	var config: Dictionary = {}
	if encounters is Dictionary: config = encounters.get(id,{})
	else:
		for entry in encounters:
			if entry.id == id: config = entry
	if config.is_empty(): return null
	var path := "res://scripts/combat/objective_encounter.gd"
	return load(path).new(owner().rules,owner().combat,config,combat_party(),current_token())
func combat_party() -> Array:
	var actor: Dictionary = owner().actors.char_liang_xiao
	return [{"id":"char_liang_xiao","name":"梁萧","team":"party","max_hp":actor.max_hp,"max_mp":actor.max_mp,"hp":actor.hp,"atk":actor.atk,"def":actor.def,"spd":actor.spd,"skills":["normal_attack","self_guard","sancai_counter","observe"],"skill_ranks":{"observe":actor.skill_ranks.get("LX_A01",1)},"passives":actor.passives.duplicate()}]
func accept_objective(token: String, proof: Dictionary) -> bool:
	if token != current_token() or current_event().get("op","") != "objective_battle": return false
	var session := make_objective_encounter()
	if session == null or proof.get("attempt_id","") != token: return false
	var validated: Dictionary = session.replay_receipt(proof,owner().rules,owner().combat,session.encounter,combat_party())
	return complete(token,validated) if not validated.is_empty() else false
func pause_sidequest() -> bool:
	if state.scope == "main": return false
	if not navigation_valid(state.position,scene().map_id): return false
	_record("pause_side",{"position":state.position.duplicate()})
	state.optional[state.scope]["resume_step"] = state.side_step
	state.optional[state.scope]["resume_position"] = state.position.duplicate()
	state.optional[state.scope].disposition = "deferred"
	state.scope = "main"
	state.side_step = 0
	state.position = state.return_position.duplicate()
	puzzle_session = null
	return true

func navigation_valid(value: Variant, map_id: String) -> bool:
	if not CampaignState._position_valid(value): return false
	if float(value[0]) < 0 or float(value[1]) < 0: return float(value[0]) == -1 and float(value[1]) == -1
	var extent: Array = maps.get(map_id,{}).get("size",[4096,4096])
	return float(value[0]) <= float(extent[0]) and float(value[1]) <= float(extent[1])
