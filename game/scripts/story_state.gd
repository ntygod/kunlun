class_name StoryState
extends RefCounted
## Pure state; the renderer cannot grant rewards or bypass scene prerequisites.
const SAVE_VERSION := 1
const SAVE_KEYS := ["version", "chapter", "scene_index", "quest_id", "quest_phase", "completed", "choices", "memories", "inventory", "observed", "puzzles", "position", "xp", "finished"]
const QUEST_PHASES := ["UNDISCOVERED", "ACCEPTED", "INVESTIGATING", "LOCAL_CHOICE", "COOP_EXECUTING", "AFTERMATH_TALK", "ARCHIVED_ECHO"]
var chapter_data: Dictionary
var state: Dictionary

func _init(data: Dictionary = {}) -> void:
	chapter_data = data
	reset()

func reset() -> void:
	state = {"version": SAVE_VERSION, "chapter": 0, "scene_index": 0,
		"quest_id": "MQ-00", "quest_phase": "ACCEPTED", "completed": [],
		"choices": {}, "memories": [], "inventory": [], "observed": {},
		"puzzles": {}, "position": [112.0, 116.0], "xp": 0, "finished": false}

func scene() -> Dictionary:
	return chapter_data.scenes[int(state.scene_index)]

func observe(object_id: String) -> bool:
	var valid := false
	for object in scene().get("objects", []):
		if object.id == object_id:
			valid = true
	if not valid:
		return false
	var key: String = scene().id
	var seen: Array = state.observed.get(key, [])
	if not object_id in seen:
		seen.append(object_id)
	state.observed[key] = seen
	if state.quest_phase == "ACCEPTED":
		state.quest_phase = "INVESTIGATING"
	return true

func can_interact() -> bool:
	if state.finished:
		return false
	for required in scene().get("requires_objects", []):
		if not required in state.observed.get(scene().id, []):
			return false
	return true

func begin_dialogue() -> bool:
	if not can_interact():
		return false
	# Quest phases are monotone over the chapter, scene interactions have their own commits.
	for phase in ["INVESTIGATING", "LOCAL_CHOICE"]:
		if QUEST_PHASES.find(state.quest_phase) < QUEST_PHASES.find(phase):
			state.quest_phase = phase
	return true

func solve_puzzle(puzzle_id: String) -> bool:
	if not can_interact() or puzzle_id != str(scene().get("mode", "dialogue")):
		return false
	if not puzzle_id in ["lesson", "calibration"]:
		return false
	state.puzzles[scene().id] = true
	return true

func commit_choice(scene_id: String, choice_index: int) -> bool:
	# Scene ID acts as an idempotency key: stale UI callbacks cannot commit a new scene.
	if scene_id != scene().id or scene_id in state.completed or not can_interact():
		return false
	if choice_index < 0 or choice_index >= scene().choices.size():
		return false
	if scene().get("mode", "dialogue") != "dialogue" and not state.puzzles.get(scene_id, false):
		return false
	begin_dialogue()
	var choice: Dictionary = scene().choices[choice_index]
	state.choices[scene_id] = choice_index
	_add_unique(state.memories, choice.flag)
	state.completed.append(scene_id)
	if scene_id == "shenxian_crossing":
		_add_unique(state.inventory, "item_nine_dragon_token")
	if choice.flag == "ITEM_BASHU_JOURNAL":
		_add_unique(state.inventory, "item_bashu_journal")
	state.quest_phase = "COOP_EXECUTING"
	if int(state.scene_index) == chapter_data.scenes.size() - 1:
		state.quest_phase = "AFTERMATH_TALK"
		state.inventory.erase("item_nine_dragon_token")
		_add_unique(state.memories, chapter_data.completion_memory)
		state.quest_phase = "ARCHIVED_ECHO"
		state.finished = true
	else:
		state.scene_index = int(state.scene_index) + 1
		state.position = [112.0, 116.0]
	return true

func _add_unique(array: Array, value: String) -> void:
	if not value in array:
		array.append(value)

func restore(candidate: Variant) -> String:
	# Validate into a temporary value. A failed load must never mutate the live session.
	if not candidate is Dictionary:
		return "存档格式损坏"
	for key in ["version", "chapter", "scene_index", "xp"]:
		var number: Variant = candidate.get(key)
		if (not number is int and not number is float) or not is_finite(float(number)) or number != int(number):
			return "存档数值字段类型错误：" + key
	for key in ["quest_id", "quest_phase"]:
		if not candidate.get(key) is String:
			return "存档文字字段类型错误：" + key
	if candidate.get("version", -1) != SAVE_VERSION:
		return "不支持此存档版本；原文件未改动"
	if candidate.size() != SAVE_KEYS.size():
		return "存档字段集合不匹配"
	for key in SAVE_KEYS:
		if not candidate.has(key):
			return "存档缺少字段：" + key
	for key in ["completed", "memories", "inventory", "position"]:
		if not candidate[key] is Array:
			return "存档字段类型错误：" + key
	for key in ["completed", "memories", "inventory"]:
		for value in candidate[key]:
			if not value is String:
				return "存档列表类型错误：" + key
	for key in ["choices", "observed", "puzzles"]:
		if not candidate[key] is Dictionary:
			return "存档字段类型错误：" + key
		for entry_key in candidate[key]:
			if not entry_key is String:
				return "存档索引类型错误：" + key
	if not candidate.finished is bool or not candidate.scene_index is float and not candidate.scene_index is int:
		return "存档进度类型错误"
	var index := int(candidate.scene_index)
	if index != candidate.scene_index or index < 0 or index >= chapter_data.scenes.size():
		return "存档场次越界"
	if candidate.chapter != 0 or candidate.quest_id != "MQ-00" or candidate.xp != 0:
		return "存档章节与成长账不匹配"
	if not candidate.quest_phase in QUEST_PHASES:
		return "存档任务状态无效"
	if candidate.position.size() != 2:
		return "存档坐标无效"
	for n in candidate.position:
		if (not n is int and not n is float) or not is_finite(float(n)) or abs(float(n)) > 4096:
			return "存档坐标无效"
	# Type-check nested payloads before any membership expression consumes them.
	for key in candidate.observed:
		if not candidate.observed[key] is Array:
			return "存档勘查记录类型错误"
	for key in candidate.puzzles:
		if not candidate.puzzles[key] is bool:
			return "存档机关记录类型错误"
	var expected_count := index + (1 if candidate.finished else 0)
	if candidate.completed.size() != expected_count or candidate.choices.size() != expected_count:
		return "存档因果链不完整"
	for i in range(expected_count):
		var entry: Dictionary = chapter_data.scenes[i]
		if candidate.completed[i] != entry.id or not candidate.choices.has(entry.id):
			return "存档场次顺序无效"
		var choice: Variant = candidate.choices[entry.id]
		if (not choice is int and not choice is float) or not is_finite(float(choice)) or choice != int(choice) or int(choice) < 0 or int(choice) >= entry.choices.size():
			return "存档选择无效"
		if not entry.choices[int(choice)].flag in candidate.memories:
			return "存档记事不完整"
	var expected_inventory: Array = []
	var expected_memories: Array = []
	var known: Dictionary = {}
	for i in range(index + 1):
		known[chapter_data.scenes[i].id] = chapter_data.scenes[i]
	for i in range(expected_count):
		var entry: Dictionary = chapter_data.scenes[i]
		var flag: String = entry.choices[int(candidate.choices[entry.id])].flag
		_add_unique(expected_memories, flag)
		if entry.id == "shenxian_crossing":
			_add_unique(expected_inventory, "item_nine_dragon_token")
		if flag == "ITEM_BASHU_JOURNAL":
			_add_unique(expected_inventory, "item_bashu_journal")
		for required in entry.get("requires_objects", []):
			if not required in candidate.observed.get(entry.id, []):
				return "存档已完成场次缺少勘查"
		if entry.get("mode", "dialogue") != "dialogue" and candidate.puzzles.get(entry.id, false) != true:
			return "存档已完成场次缺少机关结算"
	for key in candidate.observed:
		if not known.has(key) or not candidate.observed[key] is Array:
			return "存档勘查记录无效"
		var valid_ids: Array = []
		for object in known[key].objects:
			valid_ids.append(object.id)
		var seen_ids: Array = []
		for object_id in candidate.observed[key]:
			if not object_id in valid_ids or object_id in seen_ids:
				return "存档勘查物件无效"
			seen_ids.append(object_id)
	for key in candidate.puzzles:
		if not known.has(key) or known[key].get("mode", "dialogue") == "dialogue" or not candidate.puzzles[key] is bool or candidate.puzzles[key] != true:
			return "存档机关记录无效"
	if candidate.finished:
		if index != chapter_data.scenes.size()-1 or candidate.quest_phase != "ARCHIVED_ECHO":
			return "存档终章事务不完整"
		expected_inventory.erase("item_nine_dragon_token")
		_add_unique(expected_memories, chapter_data.completion_memory)
	elif index > 0 and candidate.quest_phase != "COOP_EXECUTING":
		return "存档任务阶段与进度不符"
	elif index == 0 and not candidate.quest_phase in ["ACCEPTED", "INVESTIGATING", "LOCAL_CHOICE"]:
		return "存档任务阶段与进度不符"
	if candidate.inventory != expected_inventory or candidate.memories != expected_memories:
		return "存档物品或记事与场次事务不符"
	state = candidate.duplicate(true)
	for key in ["version", "chapter", "scene_index", "xp"]:
		state[key] = int(state[key])
	for key in state.choices:
		state.choices[key] = int(state.choices[key])
	state.position = [float(state.position[0]), float(state.position[1])]
	return ""
