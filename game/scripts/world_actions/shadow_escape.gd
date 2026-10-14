class_name ChapterThreeEscape
extends RefCounted
## Deterministic spatial encounter. Development geometry, no rewards or story commits.
## Every world coordinate is derived from direction inputs against frozen map geometry.
const VERSION := 2
const MAP_PATH := "res://data/maps/chapter_three_maps.json"
const SHADOW := "interaction_ch03_shadow_escape"
const DECOY := "interaction_ch03_cloak_decoy"
const PHASES := ["approach", "overlap", "recede"]
const STEP := 16
var puzzle_id := ""
var attempt_id := ""
var context: Dictionary = {}
var layout: Dictionary = {}
var state: Dictionary = {}
var input_log: Array = []
var engine_event_log: Array = []
var message := ""
var initial_hash := ""
var frozen_hash := ""

func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if id not in [SHADOW, DECOY]: return false
	puzzle_id = id
	attempt_id = attempt if not attempt.is_empty() else id + ":attempt"
	context = trusted_context.duplicate(true)
	var map_id := "map_ch03_assassin_array" if id == SHADOW else "map_ch03_forest_road"
	if context.has("map_id") and context.map_id != map_id: return false
	layout = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)).maps[map_id]
	frozen_hash = JSON.stringify(layout).sha256_text()
	input_log = []
	engine_event_log = []
	_reset_state()
	initial_hash = _hash_state()
	message = "方向键逐格行走；观察不流逝时间，等候只推进一相。"
	return true

func _reset_state() -> void:
	state = {"position":[80,208],"ming":[48,272],"facing":[1,0],"last_visible":[80,208],"tick":0,"phase":0,"stage":0,"observed":false,"corrections":0,"feints":[],"carrying":false,"trail":[],"rests":[],"rest_id":"","rest_phases":[],"complete":false,"captured":false,"sheltered":false,"cloak_state":"xiaoshuang","cloak_position":[],"decoy_seen":false,"crossed_fork":false,"hollow_hidden":true,"animals_safe":false}
	if puzzle_id == DECOY:
		state.position = [80,208]
		state.ming = [48,240]
		state.carrying = true
		var occupants: Array = context.get("world_objects", {}).get("ch03_hidden_hollow", {}).get("occupants", [])
		if "char_hua_xiaoshuang" in occupants and "follower_baichier" in occupants and "follower_jinlinger" in occupants:
			state.position = _a(_p(layout.anchors.hidden_hollow))
			state.observed = true
			state.sheltered = true
			state.carrying = false
			state.animals_safe = true
			state.stage = 1

func _p(a: Array) -> Vector2: return Vector2(float(a[0]),float(a[1]))
func _a(p: Vector2) -> Array: return [int(p.x),int(p.y)]
func _at(anchor: String) -> bool: return _p(state.position).distance_to(_p(layout.anchors[anchor])) <= 8
func _hash_state() -> String: return JSON.stringify(state).sha256_text()
func _event(kind: String, details: Dictionary = {}) -> void:
	engine_event_log.append({"tick":state.tick,"type":kind,"details":details.duplicate(true)})
func _reject(text: String) -> bool:
	message = text
	return false

func is_walkable(p: Vector2) -> bool:
	var b: Array = layout.walk_bounds
	if p.x < b[0] or p.y < b[1] or p.x > b[0]+b[2] or p.y > b[1]+b[3]: return false
	for r in layout.solids:
		if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(p): return false
	return true

func line_visible(a: Vector2, b: Vector2, facing: Vector2 = Vector2.ZERO) -> bool:
	if a.distance_to(b) > 336: return false
	if facing != Vector2.ZERO and (b-a).dot(facing) < -0.01: return false
	for r in layout.solids:
		var rect := Rect2(r[0],r[1],r[2],r[3]).grow(2)
		var steps := maxi(1,int(a.distance_to(b)/3))
		for n in range(steps+1):
			if rect.has_point(a.lerp(b,float(n)/steps)): return false
	return true

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty(): return {"ok":false,"message":"场景尚未开始。"}
	if not action.get("type",null) is String or action.size() > 4: return {"ok":false,"message":"输入格式无效。"}
	for key in action:
		if key not in ["type","dx","dy","target","index"]: return {"ok":false,"message":"不接受外部位置或成功标记。"}
		if not (action[key] is String or action[key] is int or action[key] is float): return {"ok":false,"message":"输入格式无效。"}
		if action[key] is float and not is_finite(action[key]): return {"ok":false,"message":"输入格式无效。"}
	if input_log.size() >= 8192:
		if action.type != "retry" or action.size() != 1:
			return {"ok":false,"message":"操作日志已满，请用恢复本段起点重新尝试。"}
		# Discard the exhausted, uncommitted attempt while preserving the trusted
		# checkpoint and item ownership. Chronology replay takes the same branch.
		begin(puzzle_id,attempt_id,context.duplicate(true))
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	return {"ok":ok,"message":message,"receipt":receipt(),"view":get_view()}

func _operate(a: Dictionary) -> bool:
	var kind: String = a.type
	if kind == "retry":
		_reset_state()
		_event("attempt_reset",{"cloak_instances":1})
		message = "已恢复本段起点、衣物归属和人物位置；没有消耗奖励。"
		return true
	if state.complete: return _reject("本段已留存路线，不重复结算。")
	if state.captured: return _reject("被截住了。重试恢复本段安全快照。")
	if kind == "move":
		var dx := float(a.get("dx",0)); var dy := float(a.get("dy",0))
		if absf(dx)+absf(dy) != 1 or dx != floor(dx) or dy != floor(dy): return _reject("每次只能沿一个方向走一格。")
		var previous := _p(state.position)
		var next := previous+Vector2(dx,dy)*STEP
		if not is_walkable(next): return _reject("石像或树干挡住了路。")
		state.position = _a(next)
		_event("walk",{"position":state.position.duplicate(),"collision_checked":true})
		_tick(false, previous)
		_check_arrival()
		return true
	if kind == "wait":
		_tick()
		_check_arrival()
		return true
	if puzzle_id == SHADOW: return _shadow_action(a)
	return _decoy_action(a)

func _shadow_action(a: Dictionary) -> bool:
	match a.type:
		"inspect":
			if a.get("target","") != "yurang" or not _at("yurang_anchor"): return _reject("先走到豫让像旁观察。")
			state.observed = true
			state.stage = maxi(1,int(state.stage))
			_event("observe_yurang")
			message = "豫让定方位；明归前两步都错了，须分别纠正。相位：" + PHASES[state.phase]
			return true
		"correct_step":
			if not state.observed or not _at("yurang_anchor") or int(a.get("index",-1)) != state.corrections or state.corrections >= 2: return _reject("在豫让像前，依次纠正两处错步。")
			state.corrections += 1
			_event("route_correction",{"index":state.corrections})
			_tick()
			return true
		"feint":
			var target: String = a.get("target","")
			if target not in ["zhuhai","wuyang"]: return _reject("此处没有对应假势。")
			if state.corrections != 2 or not _at(target+"_anchor") or state.phase != 1: return _reject("须在对应石像的重叠相位出假势；可观察后单步等候。")
			if target in state.feints or (target == "wuyang" and (not state.carrying or not "zhuhai" in state.feints)): return _reject("先以朱亥假势接专诸影，再背起晓霜。")
			if not line_visible(_p(state.ming),_p(state.position),_p(state.facing)): return _reject("明归此刻看不到假势，先观察他的朝向与遮挡。")
			state.feints.append(target)
			state.last_visible = [int(state.position[0]),272]
			state.stage = 2 if target == "zhuhai" else 4
			_event("verified_feint",{"target":target,"phase":"overlap","ming_facing":state.facing.duplicate(),"position":state.position.duplicate()})
			_tick(true)
			message = "假势引他错步。沿下一座石影转移。"
			return true
		"carry":
			if not _at("zhuanzhu_shadow") or not "zhuhai" in state.feints: return _reject("沿专诸影抵达晓霜身旁后才能背负。")
			state.carrying = true
			state.stage = 3
			_event("single_carried_body",{"carrier":"char_liang_xiao","passenger":"char_hua_xiaoshuang"})
			return true
		"rest":
			var pocket := _rest_pocket()
			if pocket.is_empty() or line_visible(_p(state.ming),_p(state.position),_p(state.facing)): return _reject("须在完全遮蔽的石影中停留。")
			_tick()
			return true
	return _reject("观察方位、纠正错步，再按石影走位。")

func _rest_pocket() -> String:
	for id in ["rest_shadow_one","rest_shadow_two"]:
		if _at(id): return id
	return ""

func _decoy_action(a: Dictionary) -> bool:
	match a.type:
		"inspect":
			if a.get("target","") != "blood_trail" or not _at("blood_trail"): return _reject("走到林间血迹旁再调查。")
			state.observed = true
			_event("blood_trail_observed")
			message = "血迹会引来追兵，古树背后的洞口避开岔路视线。"
			return true
		"shelter":
			if not state.observed or not _at("hidden_hollow"): return _reject("先查血迹，再背晓霜到古树洞。")
			if line_visible(_p(state.ming),_p(layout.anchors.hidden_hollow)): return _reject("洞口仍在追兵视线里。")
			state.sheltered = true
			state.carrying = false
			state.stage = 1
			_event("xiaoshuang_sheltered")
			return true
		"guard_animals":
			if not state.sheltered or not _at("safe_animal_recess"): return _reject("将猴犬领到树洞旁安全凹处。")
			state.animals_safe = true
			_event("animals_stay_with_xiaoshuang")
			return true
		"take_cloak":
			if not state.sheltered or not _at("hidden_hollow") or state.cloak_state != "xiaoshuang": return _reject("回晓霜身边取她唯一的浅碧外衣。")
			state.cloak_state = "liang_xiao"
			_event("cloak_transferred",{"from":"xiaoshuang","to":"liang_xiao","quantity":1})
			return true
		"place_cloak":
			if not _at("decoy_branch") or state.cloak_state != "liang_xiao" or not state.animals_safe: return _reject("猴犬留守后，把外衣实际覆在岔路枯枝上。")
			state.cloak_state = "branch"
			state.cloak_position = layout.anchors.decoy_branch.duplicate()
			state.stage = 2
			_event("cloak_placed",{"position":state.cloak_position.duplicate(),"quantity":1})
			_tick()
			message = "衣已覆枝；还须绕向东路，亲见追兵看见衣物并越过岔路。"
			return true
	return _reject("按真实物件位置安置、取衣、覆枝，再走东路。")

func _tick(feint := false, previous_player: Vector2 = Vector2.INF) -> void:
	var p := _p(state.position)
	var ming := _p(state.ming)
	var from := previous_player if previous_player.is_finite() else p
	# A cell occupied at the start of a player move cannot be crossed while the
	# pursuer happens to vacate it later in this tick (including head-on swaps).
	if Geometry2D.get_closest_point_to_segment(ming, from, p).distance_to(ming) < 12:
		_capture("occupied_sweep",from,ming)
		state.tick += 1
		state.phase = int(state.tick) % 3
		return
	var visible := line_visible(ming,p,_p(state.facing))
	if puzzle_id == SHADOW:
		if visible and not feint: state.last_visible = state.position.duplicate()
		var pocket := _rest_pocket()
		if not pocket.is_empty() and not visible:
			if state.rest_id != pocket:
				state.rest_id = pocket
				state.rest_phases = []
			var expected: int = state.rest_phases.size()
			if state.phase == expected:
				state.rest_phases.append(int(state.phase))
				if state.rest_phases.size() == 3 and pocket not in state.rests:
					state.rests.append(pocket)
					_event("distinct_cover_rest",{"pocket":pocket,"phases":PHASES})
		else:
			state.rest_id = ""
			state.rest_phases = []
		if state.corrections == 2 and state.tick % 3 == 0: _move_ming(_p(state.last_visible))
	else:
		if state.sheltered and line_visible(ming,_p(layout.anchors.hidden_hollow)):
			state.hollow_hidden = false
			state.captured = true
			_event("shelter_exposed")
		if state.cloak_state == "branch":
			if line_visible(ming,_p(state.cloak_position),_p(state.facing)):
				if not state.decoy_seen: _event("ming_acquired_cloak",{"position":state.cloak_position.duplicate()})
				state.decoy_seen = true
				state.last_visible = state.cloak_position.duplicate()
			if state.decoy_seen and state.tick % 2 == 0:
				_move_ming(_p(layout.anchors.east_decoy_lane) if state.crossed_fork else _p(state.last_visible))
	# Compare the complete same-tick motion, not only the two final positions.
	var relative_start := from-ming
	var relative_delta := (p-from)-(_p(state.ming)-ming)
	var nearest_time := clampf(-relative_start.dot(relative_delta)/relative_delta.length_squared(),0.0,1.0) if relative_delta.length_squared() > 0.0 else 0.0
	if (relative_start+relative_delta*nearest_time).length() < 12:
		_capture("synchronized_sweep",from,ming)
	if puzzle_id == DECOY and not state.captured and state.decoy_seen and state.ming[0] > layout.anchors.fork[0]:
		if not state.crossed_fork: _event("ming_crossed_fork",{"position":state.ming.duplicate()})
		state.crossed_fork = true
	state.tick += 1
	state.phase = int(state.tick) % 3
	message = "被明归截住了。可重试恢复安全快照。" if state.captured else "相位：%s。明归依最后可见处行动；可停下观察。" % PHASES[state.phase]

func _capture(reason: String, player_from: Vector2, ming_from: Vector2) -> void:
	state.captured = true
	_event("captured_no_death",{"reason":reason,"player_from":_a(player_from),"player_to":state.position.duplicate(),"ming_from":_a(ming_from),"ming_to":state.ming.duplicate()})
	message = "被明归截住了。可重试恢复安全快照。"

func _move_ming(target: Vector2) -> void:
	# Breadth-first navigation shares the player's foot collision, rather than ghosting through cover.
	var start := _p(state.ming)
	if start.distance_to(target) < STEP: return
	var queue: Array[Vector2] = [start]
	var previous: Dictionary = {start:start}
	var end := start
	while not queue.is_empty() and previous.size() < 1000:
		var p: Vector2 = queue.pop_front()
		if p.distance_to(target) < STEP:
			end = p
			break
		for d in [Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2.LEFT]:
			var next: Vector2 = p+d*STEP
			if not previous.has(next) and is_walkable(next):
				previous[next] = p
				queue.append(next)
	if end == start: return
	while previous[end] != start: end = previous[end]
	state.facing = _a((end-start).normalized())
	state.ming = _a(end)
	_event("ming_walk",{"position":state.ming.duplicate(),"last_visible":state.last_visible.duplicate(),"collision_checked":true})

func _check_arrival() -> void:
	if state.captured: return
	if puzzle_id == SHADOW:
		if state.carrying and "wuyang" in state.feints:
			for anchor in ["gaojianli_shadow","jingke_shadow"]:
				if _at(anchor) and anchor not in state.trail:
					if anchor == "jingke_shadow" and not "gaojianli_shadow" in state.trail: continue
					state.trail.append(anchor)
					_event("shadow_transfer",{"anchor":anchor})
		var required := 2 if context.get("padding","inkstone") == "abacus" or int(context.get("required_rest_count",0)) == 2 else 0
		if _at("forest_exit") and state.carrying and state.feints.size() == 2 and state.trail.size() == 2 and state.rests.size() >= required:
			state.complete = true
	else:
		if state.cloak_state == "branch" and _at("hidden_hollow"):
			state.captured = true
			_event("returned_to_shelter_after_decoy")
		if state.stage >= 2 and _at("east_decoy_lane") and "east_decoy_lane" not in state.trail:
			state.trail.append("east_decoy_lane")
			_event("east_lane_walked")
		if _at("departure_edge") and state.decoy_seen and state.crossed_fork and state.hollow_hidden and state.animals_safe and "east_decoy_lane" in state.trail:
			state.complete = true
	if state.complete:
		_event("world_route_complete",{"reward_awarded":false})
		message = "世界走位验证完成；剧情与奖励由章节事务接续。"

func receipt() -> Dictionary:
	if not state.get("complete",false) or state.get("captured",false): return {}
	return {"version":VERSION,"chapter":3,"puzzle_id":puzzle_id,"scene_id":"ch03_assassin_shadows" if puzzle_id == SHADOW else "ch03_blood_cloak_decoy","objective_id":"shadow_escape" if puzzle_id == SHADOW else "ming_diverted","attempt_id":attempt_id,"map_id":"map_ch03_assassin_array" if puzzle_id == SHADOW else "map_ch03_forest_road","input_log":input_log.duplicate(true),"engine_event_log":engine_event_log.duplicate(true),"before_state_hash":initial_hash,"after_state_hash":_hash_state(),"frozen_config_hash":frozen_hash,"consumed_by_transaction":""}

func snapshot() -> Dictionary:
	return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context":context.duplicate(true),"frozen_config_hash":frozen_hash,"input_log":input_log.duplicate(true),"state_hash":_hash_state(),"event_hash":JSON.stringify(engine_event_log).sha256_text()}

func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if saved.get("version",0) != VERSION or not saved.get("input_log",null) is Array or saved.input_log.size() > 8192: return false
	var replay := ChapterThreeEscape.new()
	if not replay.begin(str(saved.get("puzzle_id","")),str(saved.get("attempt_id","")),trusted_context): return false
	if saved.get("frozen_config_hash","") != replay.frozen_hash or saved.get("context",{}) != trusted_context: return false
	for action in saved.input_log:
		if not action is Dictionary: return false
		replay.apply_input(action)
	if replay._hash_state() != saved.get("state_hash","") or JSON.stringify(replay.engine_event_log).sha256_text() != saved.get("event_hash",""): return false
	puzzle_id = replay.puzzle_id; attempt_id = replay.attempt_id; context = replay.context; layout = replay.layout
	state = replay.state; input_log = replay.input_log; engine_event_log = replay.engine_event_log
	initial_hash = replay.initial_hash; frozen_hash = replay.frozen_hash; message = replay.message
	return true

func get_view() -> Dictionary:
	var options: Array = []
	for entry in [["向左",-1,0],["向右",1,0],["向上",0,-1],["向下",0,1]]:
		options.append({"label":entry[0],"action":{"type":"move","dx":entry[1],"dy":entry[2]}})
	options.append({"label":"等一相","action":{"type":"wait"}})
	if puzzle_id == SHADOW:
		options.append({"label":"观察豫让","action":{"type":"inspect","target":"yurang"}})
		options.append({"label":"纠正第%d步" % (mini(1,int(state.corrections))+1),"action":{"type":"correct_step","index":mini(1,int(state.corrections))}})
		for id in ["zhuhai","wuyang"]: options.append({"label":"朱亥假势" if id == "zhuhai" else "舞阳假势","action":{"type":"feint","target":id}})
		options.append({"label":"背负晓霜","action":{"type":"carry"}})
		options.append({"label":"隐蔽喘息","action":{"type":"rest"}})
	else:
		options.append({"label":"调查血迹","action":{"type":"inspect","target":"blood_trail"}})
		for e in [["安置晓霜","shelter"],["猴犬留守","guard_animals"],["取浅碧外衣","take_cloak"],["覆衣枯枝","place_cloak"]]: options.append({"label":e[0],"action":{"type":e[1]}})
	options.append({"label":"恢复本段起点","action":{"type":"retry"}})
	var world_state := state.duplicate(true)
	world_state.player_position = state.position.duplicate()
	world_state.ming_position = state.ming.duplicate()
	world_state.ming_facing = state.facing.duplicate()
	world_state.phase = PHASES[state.phase]
	world_state.anchors = layout.anchors.duplicate(true)
	world_state.cover_rects = layout.solids.duplicate(true)
	world_state.target_anchor = _next_anchor()
	world_state.player_visible = line_visible(_p(state.ming),_p(state.position),_p(state.facing))
	return {"id":puzzle_id,"title":"刺客石影" if puzzle_id == SHADOW else "披衣引敌","body":message+"\n下一处：" + str(_next_anchor()) + " " + str(layout.anchors.get(_next_anchor(),[])) + "\n位置 %s；明归 %s；%s；已隐蔽休息 %d/2。\n方向输入与按钮同一碰撞校验；候选像素场景，非最终美术。" % [str(state.position),str(state.ming),"在其视线" if world_state.player_visible else "已遮蔽",state.rests.size()],"options":options,"complete":state.complete,"world_state":world_state,"paused_step_mode":true}

func _next_anchor() -> String:
	if puzzle_id == SHADOW:
		if state.corrections < 2: return "yurang_anchor"
		if "zhuhai" not in state.feints: return "zhuhai_anchor"
		if not state.carrying: return "zhuanzhu_shadow"
		if context.get("padding", "inkstone") == "abacus" and "rest_shadow_one" not in state.rests: return "rest_shadow_one"
		if "wuyang" not in state.feints: return "wuyang_anchor"
		if "gaojianli_shadow" not in state.trail: return "gaojianli_shadow"
		if context.get("padding", "inkstone") == "abacus" and "rest_shadow_two" not in state.rests: return "rest_shadow_two"
		if "jingke_shadow" not in state.trail: return "jingke_shadow"
		return "forest_exit"
	if not state.observed: return "blood_trail"
	if not state.sheltered or state.cloak_state == "xiaoshuang": return "hidden_hollow"
	if not state.animals_safe: return "safe_animal_recess"
	if state.cloak_state == "liang_xiao": return "decoy_branch"
	if "east_decoy_lane" not in state.trail: return "east_decoy_lane"
	return "departure_edge"
