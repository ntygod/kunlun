class_name CampaignState
extends RefCounted
## Small chapter router. Legacy prologue state remains independently testable.
const Legacy = preload("res://scripts/story_state.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
const Session = preload("res://scripts/campaign/encounter_session.gd")
const Trial = preload("res://scripts/campaign/three_move_trial.gd")
const EQUIPMENT := {"max_hp":10,"max_mp":0,"atk":3,"def":2,"spd":0}
const RegisteredRuntime = preload("res://scripts/campaign/chapter_runtime.gd")
var chapter_two: ChapterRuntime
var prior_campaign: Dictionary = {}
var prologue: StoryState
var chapter_data: Dictionary
var runtime: Dictionary
var rules: Dictionary
var combat: Dictionary
var encounters: Dictionary
var maps: Dictionary
var active_chapter := 0
var progress: Dictionary = {}
var actors: Dictionary = {}
var items: Dictionary = {}
var reward_ledger: Dictionary = {}
var world_objects: Dictionary = {}
var codex: Array = []
var state: Dictionary:
	get: return chapter_two.state if active_chapter == 2 else (prologue.state if active_chapter == 0 else progress)

func _init(prologue_data: Dictionary, chapter: Dictionary = {}) -> void:
	prologue = Legacy.new(prologue_data)
	chapter_data = chapter if not chapter.is_empty() else _json("chapter_one")
	runtime = _json("chapter_one_runtime")
	rules = _json("combat_rules")
	combat = _json("combat_runtime")
	encounters = _json("chapter_one_encounters").encounters
	maps = _json("maps/chapter_one_maps").maps

func _json(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name+".json"))
func reset() -> void:
	chapter_two = null
	prior_campaign.clear()
	prologue.reset()
	active_chapter = 0
	progress.clear()
	actors.clear()
	items.clear()
	reward_ledger.clear()
	world_objects.clear()
	codex.clear()
func scene() -> Dictionary:
	if active_chapter == 2: return chapter_two.scene()
	return prologue.scene() if active_chapter == 0 else chapter_data.scenes[int(progress.scene_index)]
func observe(id: String) -> bool:
	return prologue.observe(id) if active_chapter == 0 else false
func can_interact() -> bool:
	return prologue.can_interact() if active_chapter == 0 else not state.finished
func begin_dialogue() -> bool:
	return prologue.begin_dialogue() if active_chapter == 0 else not state.finished
func solve_puzzle(id: String) -> bool:
	return prologue.solve_puzzle(id) if active_chapter == 0 else false
func commit_choice(id: String, index: int) -> bool:
	# Only the legacy chapter uses array-index choices.
	return prologue.commit_choice(id,index) if active_chapter == 0 else false

func enter_chapter_one() -> bool:
	if active_chapter != 0 or not prologue.state.finished or not progress.is_empty(): return false
	active_chapter = 1
	progress = {"chapter":1,"quest_id":"MQ-01","quest_phase":"INVESTIGATING","scene_index":0,
		"step":0,"completed":[],"choices":{},"memories":prologue.state.memories.duplicate(),"inventory":[],
		"position":[-1.0,-1.0],"path_progress":{},"receipts":{},"xp":0,"finished":false,"events":[]}
	actors = {"char_liang_xiao":Growth.liang_panel(0,EQUIPMENT),
		"char_liang_wenjing":{"level":15,"xp":0,"max_hp":520,"max_mp":80,"hp":520,"mp":80,"atk":68,"def":55,"spd":22,"status":"present","skills":["LWJ_S01"]},
		"char_xiao_yuling":{"status":"present","kind":"story_support"},
		"follower_baichier":{"status":"not_adopted","kind":"noncombat_follower"}}
	actors.char_liang_xiao.merge({"hp":160,"mp":45,"status":"present","skills":["LX_A02"]})
	for item in prologue.state.inventory: items[item] = {"owner":"party","state":"carried"}
	_sync_inventory()
	return true

func current_event() -> Dictionary:
	if active_chapter == 2: return chapter_two.current_event()
	if active_chapter == 0 or progress.finished: return {}
	return runtime.scenes[scene().id][int(progress.step)]
func current_token() -> String:
	return str(current_event().get("step_id",""))
func available_choices() -> Array:
	if active_chapter == 2: return chapter_two.available_choices()
	var choices: Array = []
	for choice in scene().choices:
		var allowed := true
		for id in choice.get("requires_items",[]):
			if not items.has(id) or items[id].state != "carried" or items[id].owner != "char_liang_xiao": allowed = false
		if allowed: choices.append(choice.duplicate(true))
	return choices
func dialogue_lines() -> Array:
	if active_chapter == 2: return chapter_two.presentation()
	var event := current_event()
	if event.get("op","") != "dialogue": return []
	var result: Array = []
	var last: int = scene().dialogue.size()-1 if int(event.end) < 0 else int(event.end)
	if event.get("echo","") == "echo_ch00_yuechan" and "MEM_YUECHAN_CARE" in progress.memories:
		result.append({"speaker":"茶客","text":"听说当年合州那位淮安王散尽银钱，连孤苦的月婵姑娘也托人照料妥当。"})
	for i in range(int(event.start),last+1):
		for override in scene().get("effective_dialogue_overrides",[]):
			if int(override.get("insert_before_dialogue_index",-1)) == i:
				result.append({"speaker":"旁白","text":override.text})
		var line: Dictionary = scene().dialogue[i].duplicate()
		for override in scene().get("effective_dialogue_overrides",[]):
			if i in override.get("replaces_dialogue_indices",[]): line.text = override.text
		if scene().id == "ch01_baizhang_assembly" and i == 2:
			line.text = "云万程受辱后自尽。盟旗倒落，云殊徒劳地伸着双手，父亲再没有回应。"
		result.append(line)
	if event.get("echo","") == "home_reply":
		var selected: String = progress.choices.get("ch01_baishui_lesson","")
		for choice in chapter_data.scenes[0].choices:
			if choice.id == selected: result.append({"speaker":"父亲的回声","text":choice.replay_at_tomb})
	return result

func finish_dialogue(token: String) -> bool:
	if active_chapter == 2: return chapter_two.finish_dialogue(token)
	return _complete(token,{}) if current_event().get("op","") == "dialogue" else false
func complete_action(token: String, id: String, proof: Dictionary = {}) -> bool:
	if active_chapter == 2: return chapter_two.complete_action(token,id,proof)
	var event := current_event()
	if event.get("op","") != "action" or event.id != id: return false
	if event.kind == "glyph" and not _valid_glyph(event.glyph,proof): return false
	if event.kind == "work" and (not _integer(proof.get("count")) or int(proof.count) != int(event.count)): return false
	if event.kind == "route":
		if not proof.get("complete") is bool or not proof.complete or not _integer(proof.get("index")) or not _integer(proof.get("total")): return false
		if int(proof.index) <= 0 or proof.index != proof.total: return false
		if int(proof.total) != maps[scene().map_id].paths.get(event.id,[]).size(): return false
	return _complete(token,proof)
func choose(token: String, choice_id: String) -> bool:
	if active_chapter == 2: return chapter_two.choose(token,choice_id)
	if current_event().get("op","") != "choice": return false
	for choice in available_choices():
		if choice.id == choice_id: return _complete(token,{"choice_id":choice_id})
	return false
func make_encounter() -> EncounterSession:
	var event := current_event()
	if event.get("op","") != "battle": return null
	return Session.new(rules,combat,encounters[event.id],combat_party(),current_token())
func combat_party() -> Array:
	var panel: Dictionary = actors.char_liang_xiao
	return [{"id":"char_liang_xiao","name":"梁萧","team":"party","max_hp":panel.max_hp,"max_mp":panel.max_mp,
		"hp":panel.hp,"atk":panel.atk,"def":panel.def,"spd":panel.spd,"skills":["normal_attack","self_guard","sancai_counter"]}]
func finish_encounter(token: String, session: EncounterSession) -> bool:
	if current_event().get("op","") != "battle" or session == null: return false
	return _accept_battle(token,session.victory_receipt())
func _accept_battle(token: String, receipt: Variant) -> bool:
	var event := current_event()
	if event.get("op","") != "battle" or not receipt is Dictionary or receipt.get("attempt_id","") != token: return false
	var validated := Session.replay_receipt(receipt,rules,combat,encounters[event.id],combat_party())
	if validated.is_empty(): return false
	return _complete(token,validated)
func finish_trial(token: String, trial: ThreeMoveTrial) -> bool:
	if current_event().get("op","") != "trial" or trial == null: return false
	return _complete(token,trial.receipt()) if Trial.valid_receipt(trial.receipt()) else false

func _complete(token: String, proof: Dictionary) -> bool:
	if active_chapter != 1 or progress.finished or token != current_token(): return false
	var event := current_event()
	proof = _normalize_numbers(proof)
	var receipts: Array = progress.receipts.get(scene().id,[])
	if event.op == "action" and not event.id in receipts: receipts.append(event.id)
	if event.op == "choice" and not "reply_committed" in receipts: receipts.append("reply_committed")
	if event.op == "battle" or event.op == "trial": receipts.append(event.id)
	if event.op == "dialogue":
		if scene().id == "ch01_baizhang_assembly": receipts.append("assembly_scene_completed")
		if scene().id == "ch01_pursuit_last_words" and int(event.start) == 2:
			receipts.append("last_words_heard")
			receipts.append("wenjing_death_staged")
	progress.receipts[scene().id] = receipts
	progress.events.append({"step_id":token,"proof":proof.duplicate(true)})
	if event.op == "choice":
		for choice in available_choices():
			if choice.id == proof.choice_id:
				progress.choices[scene().id] = choice.id
				_add_memory(choice.flag)
				_apply_effects(choice.get("effects",[]))
	elif event.op == "battle":
		for actor in proof.final_actors:
			if actor.id == "char_liang_xiao":
				actors.char_liang_xiao.hp = int(actor.hp)
				actors.char_liang_xiao.mp = int(actor.mp)
		_award("reward_mq01_interception_once" if event.id == "enc_ch01_fantian_interception" else "reward_mq01_dogs_once",30)
	elif event.op == "action":
		_apply_action(event.id)
	_apply_effects(event.get("effects",[]))
	progress.step += 1
	if progress.step >= runtime.scenes[scene().id].size():
		_finish_scene()
	_sync_inventory()
	return true
func _finish_scene() -> void:
	var current: Dictionary = scene()
	var gate: Dictionary = current.completion_gate
	var receipts: Array = progress.receipts.get(current.id,[])
	for required in gate.get("required",gate.get("required_receipts",[])):
		assert(required in receipts,"Runtime event contract missed receipt: "+required)
	for required in gate.get("required_completed_scenes",[]):
		assert(required in progress.completed,"Runtime chapter gate missing earlier scene")
	_apply_effects(current.get("effects",[]))
	_apply_effects(current.get("irreversible_effects",[]))
	progress.completed.append(current.id)
	progress.quest_phase = "COOP_EXECUTING"
	if int(progress.scene_index) == chapter_data.scenes.size()-1:
		_award("reward_mq01_mainline_once",285)
		_add_memory(chapter_data.completion_memory)
		progress.finished = true
		progress.quest_phase = "ARCHIVED_ECHO"
	else:
		progress.scene_index += 1
		progress.step = 0
		progress.position = [-1.0,-1.0]
		progress.path_progress = {}
func _award(id: String, xp: int) -> void:
	if reward_ledger.has(id): return
	reward_ledger[id] = xp
	var total := 0
	for value in reward_ledger.values(): total += int(value)
	var actor: Dictionary = actors.char_liang_xiao
	var old_hp := int(actor.max_hp)
	var panel := Growth.liang_panel(total,EQUIPMENT)
	actor.merge(panel,true)
	actor.hp = mini(int(actor.max_hp),int(actor.hp)+int(actor.max_hp)-old_hp)
	progress.xp = total
func _add_memory(id: String) -> void:
	if not id in progress.memories: progress.memories.append(id)
func _sync_inventory() -> void:
	if active_chapter == 0: return
	progress.inventory = []
	for id in items:
		if items[id].state == "carried": progress.inventory.append(id)
func _apply_action(id: String) -> void:
	match id:
		"father_buried": world_objects.father_grave = {"state":"buried","actor_id":"char_liang_wenjing"}
		"dogs_buried": world_objects.dog_grave = {"state":"buried"}
		"obtain_wood_marker":
			world_objects.item_ch01_tomb_marker = {"state":"placed","text":"","missing_character":"靖"}
			items.item_ch01_memorial_broken_blade = {"owner":"char_liang_xiao","state":"carried"}
		"marker_liang_written": world_objects.item_ch01_tomb_marker.text = "梁"
		"marker_wen_written": world_objects.item_ch01_tomb_marker.text = "梁文"
		"wrap_xuanyuan_sword":
			world_objects.item_ch01_xuanyuan_sword = {"owner":"char_liang_xiao","state":"wrapped"}
		"puppy_adopted": actors.follower_baichier.status = "follower"
func _apply_effects(effects: Array) -> void:
	for effect in effects:
		match effect.op:
			"add_memory": _add_memory(effect.id)
			"grant_item":
				items[effect.id] = {"owner":effect.owner,"state":"carried"}
				if effect.id == "item_ch01_xuanyuan_sword": world_objects[effect.id] = items[effect.id].duplicate()
			"place_world_prop":
				if items.has(effect.id):
					items[effect.id] = {"owner":effect.world_id,"state":"placed"}
					world_objects[effect.id] = items[effect.id].duplicate()
			"transfer_owned_keepsakes_if_present":
				for id in effect.item_ids:
					if items.has(id) and items[id].owner == effect.from: items[id].owner = effect.to
			"set_story_status": actors[effect.actor]["story_injury"] = effect.status
			"depart_support": actors[effect.actor].status = "taken_north"
			"permanent_departure": actors[effect.actor].status = "dead"
			"unlock_skill":
				if not effect.source_skill in actors[effect.actor].skills: actors[effect.actor].skills.append(effect.source_skill)
			"unlock_codex":
				if not effect.id in codex: codex.append(effect.id)
			"set_portrait_empty": pass # Rendering derives distinct statuses; no resurrection.

func completed_actions() -> Array:
	var result: Array = []
	for record in progress.get("events",[]):
		for sequence in runtime.scenes.values():
			for event in sequence:
				if event.step_id == record.step_id and event.op == "action": result.append(event.id)
	return result
func world_context() -> Dictionary:
	if active_chapter == 2: return chapter_two.world_context()
	if active_chapter == 0: return {}
	var context := {"controller_id":scene().controller,"actor_appearances":{"char_liang_xiao":"child_age_10"},
		"present_actor_ids":[],"dead_actor_ids":[],"departed_actor_ids":[],"carried_by":"",
		"active_objectives":[],"completed_actions":completed_actions(),"world_objects":world_objects.duplicate(true)}
	for id in actors:
		var status: String = actors[id].get("status","")
		if status in ["present","follower"]: context.present_actor_ids.append(id)
		elif status == "dead": context.dead_actor_ids.append(id)
		elif status == "taken_north": context.departed_actor_ids.append(id)
	var names := {"黑脸恶道":"char_black_daoist","韩铮":"char_han_zheng","罗松":"char_luo_song","萧千绝":"char_xiao_qianjue","云万程":"char_yun_wancheng","云殊":"char_yun_shu","幼犬白痴儿":"follower_baichier"}
	for name in scene().cast:
		if names.has(name) and not names[name] in context.present_actor_ids: context.present_actor_ids.append(names[name])
	if scene().id == "ch01_fantian_interception" and int(progress.step) < 2: context.present_actor_ids.erase("char_xiao_qianjue")
	if scene().id == "ch01_fantian_three_moves" and int(progress.step) >= 2: context.controller_id = "char_liang_xiao"
	if scene().id == "ch01_pursuit_last_words" and current_event().get("id","") == "pursuit_path_completed": context.carried_by = "char_liang_wenjing"
	var event := current_event()
	if event.get("op","") == "action": context.active_objectives.append({"id":event.id,"name":event.name,"type":"route" if event.kind == "route" else "interact","enabled":true})
	return context

func export_save() -> Dictionary:
	if active_chapter == 2: return {"version":3,"prior_campaign":prior_campaign.duplicate(true),"chapter_two":chapter_two.state.duplicate(true),"actors":actors.duplicate(true),"items":items.duplicate(true),"reward_ledger":reward_ledger.duplicate(true),"world_objects":world_objects.duplicate(true),"codex":codex.duplicate()}
	return {"version":2,"active_chapter":active_chapter,"prologue":prologue.state.duplicate(true),
		"chapter_one":progress.duplicate(true),"actors":actors.duplicate(true),"items":items.duplicate(true),
		"reward_ledger":reward_ledger.duplicate(true),"world_objects":world_objects.duplicate(true),"codex":codex.duplicate()}
func restore(candidate: Variant) -> String:
	if not candidate is Dictionary: return "存档格式损坏"
	if not _integer(candidate.get("version")): return "存档版本格式错误"
	if int(candidate.version) == 3: return _restore_v3(candidate)
	var temp := CampaignState.new(prologue.chapter_data,chapter_data)
	if int(candidate.version) == 1:
		var legacy_error := temp.prologue.restore(candidate)
		if legacy_error != "": return legacy_error
		_replace_with(temp)
		return ""
	if int(candidate.version) != 2: return "不支持此存档版本；当前进度未变"
	var keys := ["version","active_chapter","prologue","chapter_one","actors","items","reward_ledger","world_objects","codex"]
	if candidate.size() != keys.size(): return "存档字段不完整"
	for key in keys:
		if not candidate.has(key): return "存档缺少字段"
	if not _integer(candidate.active_chapter) or int(candidate.active_chapter) not in [0,1]: return "存档章节无效"
	var error := temp.prologue.restore(candidate.prologue)
	if error != "": return error
	if int(candidate.active_chapter) == 1:
		if not temp.enter_chapter_one() or not candidate.chapter_one is Dictionary: return "缺少序章完成凭据"
		var saved: Dictionary = candidate.chapter_one
		if not saved.get("events") is Array or saved.events.size() > 200: return "章节事件记录无效"
		for record in saved.events:
			if not record is Dictionary or not record.get("step_id") is String or not record.get("proof") is Dictionary: return "章节事件类型无效"
			if not temp._replay_event(record): return "章节因果或遭遇收据无效"
		if not _position_valid(saved.get("position")): return "存档坐标无效"
		if not saved.get("path_progress") is Dictionary: return "路径记录格式错误"
		var allowed_paths: Dictionary = {}
		var sequence: Array = runtime.scenes[temp.scene().id]
		for i in range(mini(int(temp.progress.step)+1,sequence.size())):
			var event: Dictionary = sequence[i]
			if event.get("kind","") == "route": allowed_paths[event.id] = maps[temp.scene().map_id].paths.get(event.id,[]).size()
		for key in saved.path_progress:
			if not key is String or not allowed_paths.has(key) or not _integer(saved.path_progress[key]): return "路径记录格式错误"
			if int(saved.path_progress[key]) < 0 or int(saved.path_progress[key]) > int(allowed_paths[key]): return "路径进度越界"
			temp.progress.path_progress[key] = int(saved.path_progress[key])
		# Also restore position when no route is in progress.
		temp.progress.position = [float(saved.position[0]),float(saved.position[1])]
	if not Session.equivalent(temp.export_save(),candidate): return "存档状态与已发生事件不一致"
	_replace_with(temp)
	return ""
func _replay_event(record: Dictionary) -> bool:
	if active_chapter != 1 or progress.finished or current_event().is_empty() or current_token() == "" or record.step_id != current_token(): return false
	var event := current_event()
	var proof: Dictionary = record.proof
	match event.op:
		"dialogue": return finish_dialogue(record.step_id)
		"action": return complete_action(record.step_id,event.id,proof)
		"choice": return choose(record.step_id,str(proof.get("choice_id","")))
		"battle": return _accept_battle(record.step_id,proof)
		"trial": return _complete(record.step_id,proof) if Trial.valid_receipt(proof) else false
	return false
func _replace_with(other: CampaignState) -> void:
	prologue = other.prologue
	active_chapter = other.active_chapter
	progress = other.progress
	actors = other.actors
	items = other.items
	reward_ledger = other.reward_ledger
	world_objects = other.world_objects
	codex = other.codex
	chapter_two = other.chapter_two
	prior_campaign = other.prior_campaign
	if chapter_two != null: chapter_two.owner_ref = weakref(self)
static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == int(value)
static func _position_valid(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	for n in value:
		if not (n is int or n is float) or not is_finite(float(n)) or float(n) < -1 or float(n) > 4096: return false
	return true
static func _valid_glyph(glyph: String, proof: Dictionary) -> bool:
	return proof.get("glyph") is String and proof.glyph == glyph and _integer(proof.get("strokes")) and int(proof.strokes) == (11 if glyph == "梁" else 4)

static func _normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = _normalize_numbers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_normalize_numbers(item))
		return result
	if value is float and is_finite(value) and value == floor(value): return int(value)
	return value

func current_content() -> Dictionary:
	return chapter_two.content if active_chapter == 2 else chapter_data
func enter_chapter_two() -> bool:
	if active_chapter != 1 or not progress.finished or int(progress.xp) != 345 or not items.has("item_ch01_xuanyuan_sword"): return false
	prior_campaign = export_save()
	chapter_two = RegisteredRuntime.new(self,2)
	active_chapter = 2
	return true
func _restore_v3(candidate: Dictionary) -> String:
	var keys := ["version","prior_campaign","chapter_two","actors","items","reward_ledger","world_objects","codex"]
	if candidate.size() != keys.size(): return "章节存档字段不完整"
	for key in keys:
		if not candidate.has(key): return "章节存档缺少字段"
	if not candidate.prior_campaign is Dictionary or not _integer(candidate.prior_campaign.get("version")) or int(candidate.prior_campaign.version) != 2: return "缺少有效旧章终态"
	var temp := CampaignState.new(prologue.chapter_data,chapter_data)
	var error := temp.restore(candidate.prior_campaign)
	if error != "" or not temp.enter_chapter_two(): return "旧章校验未通过："+error
	if not candidate.chapter_two is Dictionary or not candidate.chapter_two.get("chronology") is Array or candidate.chapter_two.chronology.size() > 5000: return "章节事件序列无效"
	for i in range(candidate.chapter_two.chronology.size()):
		var record: Variant = candidate.chapter_two.chronology[i]
		if not record is Dictionary or not record.get("kind") is String or not record.get("token") is String or not record.get("proof") is Dictionary: return "章节事件格式无效"
		if i < temp.chapter_two.state.chronology.size():
			if not Session.equivalent(temp.chapter_two.state.chronology[i],record): return "机关自动收束记录不一致"
			continue
		if not temp.chapter_two.replay(record): return "章节目标收据或顺序无效"
	if not temp.chapter_two.restore_navigation(candidate.chapter_two): return "章节导航状态无效"
	if not Session.equivalent(temp.export_save(),candidate): return "章节状态与重放结果不一致"
	_replace_with(temp)
	return ""
