class_name ChapterThreeRuntime
extends ChapterRuntime
## Chapter-specific effects and adapters; chronology and transactional sequencing
## remain in ChapterRuntime. The original chapter-two save variant stays frozen.
func _init(campaign: RefCounted, id: int = 3) -> void:
	super(campaign,id)
	var previous: Dictionary = campaign.chapter_two.state
	for key in ["memories","inventory","knowledge","assists","currency_ledger"]:
		state[key] = previous[key].duplicate(true)
	state.coins = int(previous.coins)
	state.liang_age = int(previous.liang_age)
	state.xiaoshuang_age = int(previous.xiaoshuang_age)
	state.optional = {}
	state["inherited_choices"] = previous.choices.duplicate(true)
	state["inherited_optional"] = previous.optional.duplicate(true)
	state["padding"] = ""
	state["objective_snapshot"] = {}
	state["escape_receipts"] = {}
	campaign.items.item_ch02_qingxin_inkstone["form"] = "intact"
	campaign.actors.char_hua_xiaoshuang.status = "story_support"
	var dialogue_by_id := {}
	for line in content.dialogue_registry: dialogue_by_id[line.id] = line
	for node in content.scenes:
		node["dialogue"] = []
		for reference in node.dialogue_refs: node.dialogue.append(dialogue_by_id[reference].duplicate(true))
		node["objective"] = node.title

func available_choices() -> Array:
	var event := current_event()
	var permitted: Array = []
	var group: String = event.get("group","choices")
	for entry in scene().get("choice_groups",[]):
		if entry.id == group: permitted = entry.required_one_of
	var result: Array = []
	for choice in scene().get("choices",[]):
		if not permitted.is_empty() and not choice.id in permitted: continue
		var requirements: Dictionary = choice.get("requires",{})
		if requirements.has("owned_item"):
			var item: Dictionary = owner().items.get(requirements.owned_item,{})
			if item.get("owner","") != "char_liang_xiao" or item.get("state","") != "carried" or item.get("form","") != requirements.get("state","intact"): continue
		if requirements.has("follower_exists") and not owner().actors.has(requirements.follower_exists): continue
		if requirements.has("owned_story_supply"):
			var supply: Dictionary = owner().items.get(requirements.owned_story_supply,{})
			if supply.get("owner","") != "char_hua_xiaoshuang" or int(supply.get("quantity",0)) < 1: continue
		result.append(choice.duplicate(true))
	return result

func presentation() -> Array:
	var event := current_event()
	if event.op == "chapter_echo":
		if event.id == "r01_workbook":
			var workbook: Dictionary = owner().items.get("item_ch02_unclosed_workbook",{})
			var text := "梁萧在空白纸上重新列出旧日思路。没有旧册，仍可从头逐式验算。"
			if workbook.get("state","") == "carried" and workbook.get("owner","") == "char_liang_xiao" and "MEM_R01_KEEP_DRAFT" in state.memories:
				text = "梁萧翻到未合算册的有效中段，错稿里的借阴补阳变式仍在。"
				text += " 初学第一页仍由晓霜代存，没有回到行囊。" if state.inherited_choices.get("ch02_r01","") == "ch02_r01_keep_later" else " 前后错页都留在册中，沿途的改算仍清楚可见。"
			return [{"speaker":"旁白","kind":"stage","text":text}]
		return [{"speaker":"年轻弟子","kind":"speech","text":"梁兄方才讲解以字代元，我们都听明白了。仁厚护人，才配掌宫！"}] if "mem_ch03_explain_symbols" in state.memories else [{"speaker":"旁白","kind":"stage","text":"台下的年轻弟子望向花清渊，众人的支持并不以一番算理讲解为门槛。"}]
	if event.op == "branch_feedback":
		return [{"speaker":"旁白","kind":"stage","text":selected_choice().get("feedback","这一念留在行旅中。") }]
	if event.op != "dialogue": return super.presentation()
	var result: Array = []
	var last: int = scene().dialogue.size()-1 if int(event.end)<0 else int(event.end)
	for index in range(int(event.start),last+1):
		var line: Dictionary = scene().dialogue[index].duplicate(true)
		for override in content.effective_dialogue_overrides:
			if override.dialogue_id != line.id: continue
			var condition: String = override.get("when","always")
			if condition.begins_with("choice_") and not condition in state.choices.values(): continue
			if condition == "after_receipt_ch03_shadow_escape" and not state.escape_receipts.has("interaction_ch03_shadow_escape"): continue
			if override.has("text"): line.text = override.text
			if override.has("kind"):
				line.kind = override.kind
				if override.kind == "stage" and not override.has("replace_stage_direction"): line.stage_direction = ""
			if override.has("replace_stage_direction"): line.stage_direction = override.replace_stage_direction
		if line.get("kind","") == "narration": line.kind = "stage"
		result.append_array(_format([line]))
	return result

func finish_dialogue(token: String) -> bool:
	if current_event().get("op","") == "chapter_echo": return complete(token,{}) if token == current_token() else false
	return super.finish_dialogue(token)

func complete(token: String, proof: Dictionary) -> bool:
	if token != current_token() or token == "" or state.finished: return false
	var event := current_event().duplicate(true)
	if event.op == "action" and not _valid_action_proof(event,proof): return false
	if event.op == "choice":
		if proof.size() != 1 or not proof.get("choice_id") is String: return false
		var allowed := false
		for choice in available_choices():
			if choice.id == proof.choice_id: allowed = true
		if not allowed: return false
	if event.op in ["dialogue","stage","branch_feedback","chapter_echo"] and not proof.is_empty(): return false
	if event.op in ["puzzle","world_puzzle"]:
		var live := make_puzzle()
		if live == null or live.receipt().is_empty() or not Canonical.equivalent(live.receipt(),proof): return false
		var path := "res://scripts/world_actions/shadow_escape.gd" if event.op == "world_puzzle" else "res://scripts/puzzles/chapter_three_puzzle_resolver.gd"
		var verifier: RefCounted = load(path).new()
		if not verifier.restore(live.snapshot(),puzzle_context()) or not Canonical.equivalent(verifier.receipt(),proof): return false
	if event.op == "objective_battle":
		var verifier := make_objective_encounter()
		if verifier == null or proof.get("attempt_id","") != token: return false
		if verifier.replay_receipt(proof,owner().rules,owner().combat,verifier.encounter,combat_party()).is_empty(): return false
		for actor in proof.get("final_actors",[]):
			if actor.id == "char_liang_xiao":
				owner().actors.char_liang_xiao.hp = int(actor.hp)
				owner().actors.char_liang_xiao.mp = int(actor.mp)
		state.objective_snapshot = {}
	if event.op == "world_puzzle":
		state.escape_receipts[event.id] = proof.duplicate(true)
		state.position = make_puzzle().get_view().world_state.player_position.duplicate()
	if event.op == "action" and proof.get("position") is Array: state.position = proof.position.duplicate()
	var ok := super.complete(token,proof)
	if ok and event.op == "choice" and event.get("receipts",[]).has("padding_reserved"):
		state.padding = "inkstone" if proof.choice_id == "choice_ch03_padding_inkstone" else "abacus"
	return ok

func _valid_action_proof(event: Dictionary, proof: Dictionary) -> bool:
	var geometry: Dictionary = maps.get(scene().map_id,{}).get("actions",{}).get(event.id,{})
	if geometry.is_empty() or proof.get("map_id","") != scene().map_id or not navigation_valid(proof.get("position"),scene().map_id): return false
	var at := Vector2(proof.position[0],proof.position[1])
	if at.distance_to(Vector2(geometry.position[0],geometry.position[1])) > float(geometry.get("radius",24)): return false
	if event.kind == "route":
		var total: int = maps[scene().map_id].paths.get(event.id,[]).size()
		return proof.size() == 5 and proof.get("complete") is bool and proof.complete and _integer(proof.get("index")) and _integer(proof.get("total")) and int(proof.index) == total and int(proof.total) == total and total > 0
	return proof.size() == 2

func _effect(effect: Dictionary) -> void:
	match effect.op:
		"knowledge":
			if not effect.id in state.knowledge: state.knowledge.append(effect.id)
		"control": state.controller_override = effect.id
		"borrow_abacus":
			if not owner().items.has("item_ch03_copper_abacus"):
				owner().items.item_ch03_copper_abacus = {"owner":"char_liang_xiao","state":"carried","form":"intact","loan_from":"天机宫论算案","returned":false}
				owner().world_objects.lingtai_math_desk_abacus = {"state":"borrowed","item_id":"item_ch03_copper_abacus"}
		"story_medicine":
			owner().items.item_ch02_xiaoshuang_medicine = {"owner":"char_hua_xiaoshuang","state":"carried","quantity":1,"story_supply":true}
		"transform_padding":
			var id: String = "item_ch02_qingxin_inkstone" if state.padding == "inkstone" else "item_ch03_copper_abacus"
			var item: Dictionary = owner().items.get(id,{})
			assert(item.get("owner","") == "char_liang_xiao" and item.get("form","") == "intact","Padding requires the actually reserved intact item")
			item.form = "broken_fragment" if state.padding == "inkstone" else "destroyed"
			if state.padding == "abacus": item.state = "destroyed"
		"story_injuries":
			owner().actors.char_liang_xiao["story_injury"] = "narrative_internal_injury"
			owner().actors.char_hua_xiaoshuang["story_injury"] = "leg_injury"
		"secure_keepsake": owner().items.item_ch02_qingxin_inkstone["secured"] = true
		"shelter_xiaoshuang":
			owner().actors.char_hua_xiaoshuang.status = "sheltered"
			owner().world_objects.ch03_hidden_hollow = {"state":"concealed","occupants":["char_hua_xiaoshuang"]}
		"leave_medicine": owner().items.item_ch02_xiaoshuang_medicine["location"] = "ch03_hidden_hollow"
		"shelter_followers":
			for id in ["follower_baichier","follower_jinlinger"]:
				owner().actors[id].status = "sheltered_with_xiaoshuang"
				owner().world_objects.ch03_hidden_hollow.occupants.append(id)
		"place_cloak":
			owner().items.item_ch03_xiaoshuang_outer_cloak = {"owner":"char_hua_xiaoshuang","state":"placed","location":"ch03_decoy_branch"}
			owner().world_objects.ch03_decoy_branch = {"state":"cloak_placed","item_id":"item_ch03_xiaoshuang_outer_cloak","ming_diverted":true}
		"departure": owner().actors.char_hua_xiaoshuang.status = "separated_not_dead"
		_: super._effect(effect)

func _finish_scene() -> void:
	var previous_map: String = scene().map_id
	var previous_position: Array = state.position.duplicate()
	super._finish_scene()
	if not state.finished and scene().map_id == previous_map: state.position = previous_position
	if state.finished and not state.currency_ledger.has("reward_mq03_coins_once"):
		state.currency_ledger.reward_mq03_coins_once = 300
		state.coins += 300

func puzzle_definition() -> Dictionary:
	return {"id":current_event().get("id",""),"attempt":current_token(),"guided":false,"world":current_event().get("op","") == "world_puzzle"}
func puzzle_context() -> Dictionary:
	return {"chapter":3,"scene":scene().id,"map_id":scene().map_id,"padding":state.padding,"required_rest_count":2 if state.padding == "abacus" else 0,"items":owner().items.duplicate(true),"world_objects":owner().world_objects.duplicate(true),"completed_receipts":state.receipts.duplicate(true),"map":maps.get(scene().map_id,{}).duplicate(true)}
func make_puzzle() -> RefCounted:
	if current_event().get("op","") not in ["puzzle","world_puzzle"]: return null
	if puzzle_session != null: return puzzle_session
	var definition := puzzle_definition()
	var path := "res://scripts/world_actions/shadow_escape.gd" if definition.world else "res://scripts/puzzles/chapter_three_puzzle_resolver.gd"
	if not ResourceLoader.exists(path): return null
	puzzle_session = load(path).new()
	puzzle_session.begin(definition.id,definition.attempt,puzzle_context())
	if state.puzzle_records.has(definition.attempt):
		if not puzzle_session.restore(state.puzzle_records[definition.attempt],puzzle_context()): puzzle_session = null
	return puzzle_session

func make_objective_encounter() -> RefCounted:
	var config: Dictionary = Registry.read_json("chapter_three_encounters").get("encounters",{}).get(current_event().get("id",""),{})
	if config.is_empty() or not ResourceLoader.exists("res://scripts/combat/chapter_three_encounter.gd"): return null
	var session: RefCounted = load("res://scripts/combat/chapter_three_encounter.gd").new(owner().rules,owner().combat,config,combat_party(),current_token())
	if not state.objective_snapshot.is_empty() and not session.restore(state.objective_snapshot): return null
	return session
func save_objective_checkpoint(session: RefCounted) -> bool:
	if current_event().get("op","") != "objective_battle" or session == null: return false
	state.objective_snapshot = session.snapshot()
	return true
func restore_navigation(saved: Dictionary) -> bool:
	if not super.restore_navigation(saved) or not saved.get("objective_snapshot") is Dictionary: return false
	if not saved.objective_snapshot.is_empty():
		if current_event().get("op","") != "objective_battle": return false
		var session := make_objective_encounter()
		if session == null or not session.restore(saved.objective_snapshot): return false
		state.objective_snapshot = saved.objective_snapshot.duplicate(true)
	return true
func replay(record: Dictionary) -> bool:
	if record.kind == "complete" and current_event().get("op","") == "chapter_echo": return finish_dialogue(record.token)
	return super.replay(record)
func world_context() -> Dictionary:
	var context := super.world_context()
	if state.controller_override != "": context.controller_id = state.controller_override
	if owner().actors.char_hua_xiaoshuang.status in ["sheltered","separated_not_dead"]:
		context.present_actor_ids.erase("char_hua_xiaoshuang")
	context["chapter"] = 3
	context["padding"] = state.padding
	return context
