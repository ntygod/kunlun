class_name CompletedChapterSummary
extends RefCounted
## Bounded, declarative completed outcomes. These are not historical input proofs.
## apply() mutates only a disposable restore candidate; the caller owns atomic commit.
const VERSION := 1
const BASE_KEYS := ["chapter", "summary_version", "choices", "milestones", "boundary_vitals"]
const SIDE_IDS := ["ch02_r01", "ch02_k01"]
const SIDE_CHOICES := {
	"ch02_r01":["ch02_r01_keep_all", "ch02_r01_keep_later"],
	"ch02_k01":["ch02_k01_double_difference", "ch02_k01_similar_triangles"]}

static func pack(campaign: RefCounted, chapter: int) -> Dictionary:
	if chapter not in [0,1,2,3] or campaign.active_chapter != chapter or not campaign.state.get("finished",false): return {}
	var markers := _milestones(campaign,chapter)
	if markers.is_empty(): return {}
	var entry := {"chapter":chapter,"summary_version":VERSION,"choices":campaign.state.choices.duplicate(true),
		"milestones":markers,"boundary_vitals":{}}
	if chapter == 0: entry.observed = campaign.state.observed.duplicate(true)
	if chapter > 0:
		entry.boundary_vitals = {"hp":campaign.actors.char_liang_xiao.hp,"mp":campaign.actors.char_liang_xiao.mp}
	if chapter == 2:
		entry.optional_commits = _optional_commits(campaign.chapter_two)
		entry.optional_dispositions = {}
		for id in SIDE_IDS: entry.optional_dispositions[id] = campaign.state.optional[id].disposition
	# Dot-assigned dictionary keys can be StringName in live state; the wire schema is JSON.
	return JSON.parse_string(JSON.stringify(entry))

static func apply(campaign: RefCounted, entry: Dictionary) -> String:
	var error := _shape(entry)
	if error != "": return error
	var chapter := int(entry.chapter)
	if chapter == 0:
		if campaign.active_chapter != 0 or campaign.state.finished or not campaign.state.choices.is_empty(): return "序章摘要必须从新行旅开始"
	elif campaign.active_chapter != chapter-1 or not campaign.state.finished:
		return "归档章节必须连续且前章已完成"
	var previous: bool = campaign._restoring_summary
	campaign._restoring_summary = true
	error = _apply(campaign,entry)
	campaign._restoring_summary = previous
	return error

static func _apply(campaign: RefCounted, entry: Dictionary) -> String:
	var chapter := int(entry.chapter)
	if chapter == 0:
		# The original prologue is already a finite scene-result model, not an input log.
		var observed_error := _observed_definitions(campaign,entry.observed)
		if observed_error != "": return observed_error
		while not campaign.state.finished:
			var scene: Dictionary = campaign.scene()
			if not entry.choices.has(scene.id): return "序章摘要缺少选择"
			var selected: Variant = entry.choices[scene.id]
			if not _whole(selected) or int(selected) < 0 or int(selected) >= scene.choices.size(): return "序章摘要选择无效"
			if entry.observed.has(scene.id):
				# An explicitly empty registered observation list is also accepted by v1.
				campaign.state.observed[scene.id] = []
				for id in entry.observed[scene.id]:
					if not campaign.observe(id): return "序章摘要勘查定义无效"
			if scene.get("mode","dialogue") != "dialogue" and not campaign.solve_puzzle(scene.mode): return "序章摘要机关定义无效"
			if not campaign.commit_choice(scene.id,int(selected)): return "序章摘要事务失败"
	else:
		var entered: bool = campaign.call(["", "enter_chapter_one", "enter_chapter_two", "enter_chapter_three"][chapter])
		if not entered: return "归档章节前置不满足"
		var iterations := 0
		while not campaign.state.finished:
			iterations += 1
			if iterations > 256: return "归档章节步骤超出登记边界"
			var event: Dictionary = campaign.current_event()
			var proof: Dictionary = {}
			if event.get("op","") == "choice":
				var key: String = campaign.scene().id if chapter == 1 else campaign.current_chapter_runtime()._choice_key(event)
				if not entry.choices.has(key): return "归档摘要缺少选择"
				var id: String = entry.choices[key]
				var allowed := false
				for choice in campaign.available_choices():
					if choice.id == id: allowed = true
				if not allowed: return "归档选择或物品前置无效"
				proof = {"choice_id":id}
			elif event.get("op","") in ["battle","objective_battle"]:
				proof = {"final_actors":[]}
			elif event.get("op","") == "quest_window":
				var optional_error := _apply_optional(campaign.chapter_two,entry)
				if optional_error != "": return optional_error
				proof = {"closure_acknowledged":true}
			var ok: bool = campaign.commit_archived_result(proof) if chapter == 1 else campaign.current_chapter_runtime().commit_archived_result(proof)
			if not ok: return "归档语义事务失败"
			if chapter == 3 and event.get("receipts",[]).has("padding_reserved"):
				campaign.state.padding = "inkstone" if proof.choice_id == "choice_ch03_padding_inkstone" else "abacus"
		var error := _vitals(campaign,entry.boundary_vitals,chapter)
		if error != "": return error
		campaign.actors.char_liang_xiao.hp = int(entry.boundary_vitals.hp)
		campaign.actors.char_liang_xiao.mp = int(entry.boundary_vitals.mp)
	var rebuilt := pack(campaign,chapter)
	if not _same(rebuilt,entry): return "归档里程碑、选择或终态不一致"
	return ""

static func _apply_optional(runtime: RefCounted, entry: Dictionary) -> String:
	var main_step: int = runtime.state.step
	var resumes := {}
	for record in entry.optional_commits:
		var id: String = "ch02_r01" if record.kind.begins_with("r01_") else "ch02_k01"
		var solving: bool = record.kind.ends_with("_puzzle_solved")
		runtime.state.scope = id
		runtime.state.side_step = 0 if solving else int(resumes[id])
		runtime.state.optional[id] = {"status":"accepted" if solving else "aftermath","disposition":"active"}
		var iterations := 0
		while runtime.state.scope != "main":
			iterations += 1
			if iterations > 32: return "支线归档步骤超界"
			var event: Dictionary = runtime.current_event()
			var proof: Dictionary = {"choice_id":record.choice_id} if event.op == "puzzle" else {}
			if not runtime.commit_archived_result(proof): return "支线归档事务失败"
			if solving and event.op == "puzzle":
				resumes[id] = runtime.state.side_step
				runtime.state.scope = "main"
				runtime.state.side_step = 0
				break
		if runtime.state.step != main_step: return "支线归档越过主线窗口"
	for id in SIDE_IDS:
		if entry.optional_dispositions[id] != "completed":
			runtime.state.optional[id].disposition = "declined" if entry.optional_dispositions[id] == "declined" else "deferred"
	runtime.set_meta("completed_optional_commits",entry.optional_commits.duplicate(true))
	return ""

static func _optional_commits(runtime: RefCounted) -> Array:
	if runtime.has_meta("completed_optional_commits"): return runtime.get_meta("completed_optional_commits").duplicate(true)
	var result: Array = []
	for record in runtime.state.chronology:
		if record.get("kind","") != "complete": continue
		for id in SIDE_IDS:
			var sequence: Array = runtime.runtime.side_quests[id]
			for event in sequence:
				if event.step_id != record.token: continue
				var prefix: String = "r01" if id == "ch02_r01" else "k01"
				if event.op == "puzzle": result.append({"kind":prefix+"_puzzle_solved","choice_id":record.proof.get("choice_id","")})
				elif event.step_id == sequence[-1].step_id: result.append({"kind":prefix+"_archived"})
	return result

static func _milestones(campaign: RefCounted, chapter: int) -> Array:
	var result: Array = []
	var content: Dictionary = campaign.prologue.chapter_data if chapter == 0 else campaign.current_content()
	var expected_scenes: Array = []
	for scene in content.scenes:
		expected_scenes.append(scene.id)
		result.append("scene:"+scene.id)
		if chapter == 0:
			for id in scene.get("requires_objects",[]):
				if id not in campaign.state.observed.get(scene.id,[]): return []
				result.append("observed:"+scene.id+":"+id)
			if scene.get("mode","dialogue") != "dialogue":
				if campaign.state.puzzles.get(scene.id,false) != true: return []
				result.append("puzzle:"+scene.id+":"+scene.mode)
			continue
		var gate: Dictionary = scene.completion_gate
		var receipts: Array = campaign.state.receipts.get(scene.id,[])
		var required: Array = gate.get("all_of",gate.get("required",gate.get("required_receipts",[]))).duplicate()
		if gate.has("encounter_id") and gate.encounter_id not in required: required.append(gate.encounter_id)
		for choice in scene.get("choices",[]):
			if campaign.state.choices.get(scene.id,"") == choice.id and choice.has("required_receipt") and choice.required_receipt not in required: required.append(choice.required_receipt)
		for id in required:
			if id not in receipts: return []
			result.append("receipt:"+scene.id+":"+id)
	if not _same(campaign.state.completed,expected_scenes): return []
	if chapter == 2:
		for record in _optional_commits(campaign.chapter_two):
			result.append("optional:"+record.kind)
	return result

static func _vitals(campaign: RefCounted, value: Dictionary, chapter: int) -> String:
	var actor: Dictionary = campaign.actors.char_liang_xiao
	var maximum_before_last_battle: Dictionary
	if chapter == 1:
		maximum_before_last_battle = campaign.Growth.liang_panel(30,campaign.EQUIPMENT)
	elif chapter == 2:
		maximum_before_last_battle = campaign.Growth.liang_panel(505,actor.equipment)
	else:
		maximum_before_last_battle = campaign.Growth.liang_panel(int(actor.xp)-795,actor.equipment)
	var minimum_hp: int = int(actor.max_hp)-int(maximum_before_last_battle.max_hp)+1
	if int(value.hp) < minimum_hp or int(value.hp) > int(actor.max_hp) or int(value.mp) < 0 or int(value.mp) > int(maximum_before_last_battle.max_mp): return "归档气血或真气不满足固定成长边界"
	return ""

static func _shape(entry: Dictionary) -> String:
	if not _whole(entry.get("chapter")) or int(entry.chapter) not in [0,1,2,3]: return "归档章节未登记"
	if not _whole(entry.get("summary_version")) or int(entry.summary_version) != VERSION: return "归档摘要版本无效"
	var chapter := int(entry.chapter)
	var keys := BASE_KEYS.duplicate()
	if chapter == 0: keys.append("observed")
	if chapter == 2: keys.append_array(["optional_commits","optional_dispositions"])
	if not _keys(entry,keys): return "归档摘要字段集合不匹配"
	if not entry.choices is Dictionary or not entry.milestones is Array or not entry.boundary_vitals is Dictionary: return "归档摘要字段类型无效"
	if entry.choices.size() > 32 or entry.milestones.size() > 512: return "归档摘要超出登记边界"
	for key in entry.choices:
		if not key is String or key.length() > 128: return "归档选择索引类型无效"
		if chapter == 0:
			if not _whole(entry.choices[key]): return "序章归档选择类型无效"
		elif not entry.choices[key] is String or entry.choices[key].length() > 128: return "归档选择类型无效"
	var seen := {}
	for marker in entry.milestones:
		if not marker is String or marker.length() > 256 or seen.has(marker): return "归档里程碑重复或类型无效"
		seen[marker] = true
	if chapter == 0:
		if not entry.boundary_vitals.is_empty(): return "序章没有梁萧成长面板"
		if not entry.observed is Dictionary or entry.observed.size() > 32: return "序章摘要勘查字段无效"
		for scene_id in entry.observed:
			if not scene_id is String or scene_id.length() > 128 or not entry.observed[scene_id] is Array or entry.observed[scene_id].size() > 64: return "序章摘要勘查索引或列表无效"
			var observed_ids := {}
			for id in entry.observed[scene_id]:
				if not id is String or id.length() > 128 or observed_ids.has(id): return "序章摘要勘查物件重复或类型无效"
				observed_ids[id] = true
	elif not _keys(entry.boundary_vitals,["hp","mp"]) or not _whole(entry.boundary_vitals.get("hp")) or not _whole(entry.boundary_vitals.get("mp")): return "归档气血字段无效"
	if chapter == 2: return _optional_shape(entry)
	return ""

static func _observed_definitions(campaign: RefCounted, observed: Dictionary) -> String:
	var scenes := {}
	for scene in campaign.prologue.chapter_data.scenes:
		scenes[scene.id] = scene
		for required in scene.get("requires_objects",[]):
			if required not in observed.get(scene.id,[]): return "序章摘要缺少必需勘查"
	for scene_id in observed:
		if not scenes.has(scene_id): return "序章摘要勘查场次未登记"
		var allowed: Array = []
		for object in scenes[scene_id].get("objects",[]): allowed.append(object.id)
		for id in observed[scene_id]:
			if id not in allowed: return "序章摘要勘查物件未登记"
	return ""

static func _optional_shape(entry: Dictionary) -> String:
	if not entry.optional_commits is Array or entry.optional_commits.size() > 4 or not entry.optional_dispositions is Dictionary or not _keys(entry.optional_dispositions,SIDE_IDS): return "支线摘要字段无效"
	var solved := {}
	var archived := {}
	for record in entry.optional_commits:
		if not record is Dictionary or not record.get("kind") is String: return "支线提交类型无效"
		var kind: String = record.kind
		if kind not in ["r01_puzzle_solved","k01_puzzle_solved","r01_archived","k01_archived"]: return "支线提交未登记"
		var id := "ch02_r01" if kind.begins_with("r01_") else "ch02_k01"
		if kind.ends_with("_puzzle_solved"):
			if not _keys(record,["kind","choice_id"]) or not record.choice_id is String or record.choice_id not in SIDE_CHOICES[id] or solved.has(id): return "支线解题选择重复或无效"
			if entry.choices.get(id,"") != record.choice_id: return "支线方法与已提交选择不一致"
			solved[id] = true
		else:
			if not _keys(record,["kind"]) or not solved.has(id) or archived.has(id): return "支线归档缺少解题或重复结算"
			archived[id] = true
	for id in SIDE_IDS:
		var disposition: Variant = entry.optional_dispositions[id]
		if not disposition is String or disposition not in ["completed","missed","declined"]: return "支线最终处置无效"
		if (disposition == "completed") != archived.has(id): return "支线处置与结算不一致"
		if not solved.has(id) and entry.choices.has(id): return "未完成机关不能留下提交选择"
	return ""

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and absf(float(value)) <= 1000000000.0

static func _keys(value: Dictionary, keys: Array) -> bool:
	if value.size() != keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func _same(a: Variant, b: Variant) -> bool:
	# Dictionary insertion order is not authority. Array order is part of the schema.
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not _same(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index in range(a.size()):
			if not _same(a[index],b[index]): return false
		return true
	if (a is int or a is float) and (b is int or b is float): return a == b
	return typeof(a) == typeof(b) and a == b
