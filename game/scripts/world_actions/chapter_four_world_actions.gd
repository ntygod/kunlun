class_name ChapterFourWorldActions
extends RefCounted
## Position-derived chapter-four interactions. No campaign rewards or caller positions.
const VERSION := 1
const LIMIT := 4096
const MAP_PATH := "res://data/maps/chapter_four_maps.json"
const IDS := ["window_anchor_verified","horse_call_and_arrival","liu_carried_not_combat","shelter_route_verified","shelter_care_performed","patrol_escape_verified","horse_release_verified","horse_calm_and_led","gate_encounter_verified","chu_wan_released","bell_cover_position","moor_and_sit","bell_response_verified"]
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
var scene_id := ""
var map_id := ""
func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if id == "enc_ch04_courtyard_escape": id = "gate_encounter_verified"
	if id not in IDS: return false
	if trusted_context.has("objective_id") and trusted_context.objective_id != id: return false
	puzzle_id = id; attempt_id = attempt; context = trusted_context.duplicate(true)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_four.json"))
	scene_id = str(data.objective_registry[id].scene_id)
	for scene in data.scenes:
		if scene.id == scene_id: map_id = scene.map_id
	if context.has("scene_id") and context.scene_id != scene_id: return false
	layout = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)).maps[map_id]
	frozen_hash = JSON.stringify(layout).sha256_text()
	input_log.clear(); engine_event_log.clear(); _reset()
	initial_hash = _hash_state()
	return true
func _p(a: Array) -> Vector2: return Vector2(float(a[0]),float(a[1]))
func _a(p: Vector2) -> Array: return [int(p.x),int(p.y)]
func _anchor(id: String) -> Array: return layout.anchors.get(id,layout.spawn)
func _at(id: String) -> bool: return _p(state.position).distance_to(_p(_anchor(id))) <= 8
static func _canonical(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floor(v): return int(v)
	if v is Array:
		var out: Array = []
		for item in v: out.append(_canonical(item))
		return out
	if v is Dictionary:
		var out := {}
		for key in v: out[key] = _canonical(v[key])
		return out
	return v
static func _encoded(v: Variant) -> String: return JSON.stringify(_canonical(v))
func _hash_state() -> String: return _encoded(state).sha256_text()
func _reset() -> void:
	var starts := {"horse_call_and_arrival":"window","liu_carried_not_combat":"fork","shelter_route_verified":"fork","shelter_care_performed":_shelter(),"patrol_escape_verified":_shelter(),"horse_release_verified":"woodpile","horse_calm_and_led":"horse_snag","chu_wan_released":"courtyard_gate","bell_response_verified":"safe_recess"}
	state = {"position":_anchor(starts.get(puzzle_id,"spawn")).duplicate(),"tick":0,"stage":0,"complete":false,"captured":false,"carrying":puzzle_id in ["shelter_route_verified","shelter_care_performed","patrol_escape_verified","horse_release_verified","horse_calm_and_led","gate_encounter_verified","chu_wan_released","bell_cover_position"],"horse_id":"animal_yanzhi","horse_position":_anchor("horse_snag").duplicate(),"horse_called":false,"horse_arrived":false,"horse_released":puzzle_id == "horse_calm_and_led","chu_wan_held":puzzle_id == "chu_wan_released","guard_position":_anchor("patrol_start").duplicate() if puzzle_id in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"] else [80,176],"guard_facing":[1,0],"approaches":0,"guarded":false,"observed":false,"rope_attached":false,"window_clear":false,"screen_closed":false,"care_done":false,"map_id":map_id,"pulses":0,"fragments":[]}
	if puzzle_id in ["window_anchor_verified","horse_call_and_arrival"]: state.horse_position = _anchor("horse_wait").duplicate()
	var previous: Dictionary = context.get("world_objects",{}).get("ch04_spatial_state",{})
	if previous.get("map_id","") == map_id:
		var shared_keys := ["player_position","horse_position","carrying","horse_released","chu_wan_held","screen_closed","care_done"]
		var previous_id: String = previous.get("objective_id","")
		if puzzle_id in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"] and previous_id in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"]:
			shared_keys.append_array(["tick","guard_position","guard_facing"])
		if puzzle_id == "chu_wan_released" and previous_id == "gate_encounter_verified":
			shared_keys.append_array(["tick","guard_position","guard_facing","approaches","guarded","observed"])
		if puzzle_id == "horse_call_and_arrival" and previous_id == "window_anchor_verified": shared_keys.append_array(["rope_attached","window_clear"])
		for key in shared_keys:
			if previous.has(key): state["position" if key == "player_position" else key] = previous[key].duplicate() if previous[key] is Array else previous[key]
	message = "方向键逐格行走，到标记位置按 E 操作；等候推进巡逻一相。"
func _inscription() -> bool:
	var choices: Dictionary = context.get("choices",{})
	return context.get("bell_method","") == "inscription" or "ch04_bell_inscription" in choices.values() or choices.has("ch04_bell_inscription")
func _shelter() -> String: return "empty_boat" if context.get("shelter_method","spring") == "boat" else "spring"
func _event(kind: String) -> void: engine_event_log.append({"tick":state.tick,"type":kind,"position":state.position.duplicate()})
func is_walkable(p: Vector2) -> bool:
	var b: Array = layout.walk_bounds
	if p.x < b[0] or p.y < b[1] or p.x > b[0]+b[2] or p.y > b[1]+b[3]: return false
	for r in layout.solids:
		if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(p): return false
	return true
func line_visible(a: Vector2,b: Vector2,facing: Vector2 = Vector2.ZERO) -> bool:
	if a.distance_to(b)>144 or (facing != Vector2.ZERO and (b-a).dot(facing)<0): return false
	var blockers: Array = layout.solids.duplicate(true)
	if state.get("screen_closed",false) and layout.anchors.has("empty_boat"):
		var boat := _p(_anchor("empty_boat")); blockers.append([boat.x-24,boat.y-24,48,6])
	for r in blockers:
		for i in range(int(a.distance_to(b)/2)+1):
			if Rect2(r[0],r[1],r[2],r[3]).grow(2).has_point(a.lerp(b,float(i)/maxi(1,int(a.distance_to(b)/2)))): return false
	return true
static func swept_contact(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	# Relative-motion minimum distance catches swapped cells and crossing segments.
	var r := a-c; var v := (b-a)-(d-c)
	var t := clampf(-r.dot(v)/v.length_squared(),0,1) if v.length_squared()>0 else 0.0
	return (r+v*t).length() < 12
func _tick(old: Vector2) -> void:
	state.tick += 1
	if state.horse_called and not state.horse_arrived:
		var hp := _p(state.horse_position); var target := _p(_anchor("horse_landing"))
		var next := hp.move_toward(target,16)
		if is_walkable(next): state.horse_position = _a(next); _event("horse_path_step")
		state.horse_arrived = next == target
	if puzzle_id in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"]:
		if not state.horse_released and _p(state.horse_position) != _p(_anchor("horse_snag")):
			var horse_next := _p(state.horse_position).move_toward(_p(_anchor("horse_snag")),16)
			if is_walkable(horse_next): state.horse_position = _a(horse_next); _event("horse_approaches_snag")
		var before := _p(state.guard_position)
		var phase: int = state.tick%3
		state.guard_facing = [1,0] if int(state.tick/3)%2 == 0 else [-1,0]
		if phase == 2:
			var next := before+_p(state.guard_facing)*16
			if next.x>=272 and next.x<=336: state.guard_position = _a(next)
		_event("patrol_"+["look","turn","walk"][phase])
		if swept_contact(old,_p(state.position),before,_p(state.guard_position)) or line_visible(_p(state.guard_position),_p(state.position),_p(state.guard_facing)):
			state.captured = true; _event("captured"); message = "追兵发现了行踪，恢复本段起点后重试。"
func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty(): return {"ok":false}
	var kind: Variant = action.get("type",null)
	if not kind is String: return {"ok":false}
	var allowed := ["type","dx","dy"] if kind == "move" else (["type","value"] if kind == "choose_fragment" else ["type"])
	for key in action:
		if key not in allowed: return {"ok":false,"message":"不接受位置、成功标记或额外字段。"}
	if kind not in ["move","wait","interact","inspect","guard","retry","choose_fragment"]: return {"ok":false}
	if kind == "choose_fragment":
		if not action.get("value",null) is int and not action.get("value",null) is float: return {"ok":false}
		var value := float(action.value)
		if not is_finite(value) or value != floor(value) or value < 0 or value > 2: return {"ok":false}
	if kind == "move":
		if not action.get("dx",null) is int and not action.get("dx",null) is float: return {"ok":false}
		if not action.get("dy",null) is int and not action.get("dy",null) is float: return {"ok":false}
		var dx := float(action.dx); var dy := float(action.dy)
		if not is_finite(dx) or not is_finite(dy) or absf(dx)+absf(dy)!=1 or dx!=floor(dx) or dy!=floor(dy): return {"ok":false}
	if input_log.size() >= LIMIT:
		if kind != "retry": return {"ok":false,"message":"日志已满，恢复本段起点后仍可继续。"}
		begin(puzzle_id,attempt_id,context.duplicate(true))
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt()}
func _operate(a: Dictionary) -> bool:
	if a.type == "retry": _reset(); _event("retry"); return true
	if state.complete or state.captured: return false
	var old := _p(state.position)
	if a.type == "move":
		var next := old+Vector2(a.dx,a.dy)*16
		if not is_walkable(next): message = "墙、水岸或家具挡住了路。"; return false
		state.position = _a(next)
		if puzzle_id == "horse_calm_and_led" and state.horse_released:
			var horse_before := _p(state.horse_position)
			if horse_before.distance_to(old) <= 24:
				var horse_next := horse_before.move_toward(old,16)
				if is_walkable(horse_next): state.horse_position = _a(horse_next); _event("horse_led_step")
		_event("walk"); _tick(old)
		if not context.get("world_objects",{}).get("l01_water_movement_no_slow",false):
			for r in layout.get("water_rects",[]):
				if Rect2(r[0],r[1],r[2],r[3]).has_point(next): _event("shallow_water_extra_step"); _tick(next); break
		return true
	if a.type == "wait": _tick(old); return true
	if a.type == "inspect":
		if puzzle_id == "gate_encounter_verified" and not _at("gate_guard"): return false
		state.observed = true; _event("observe_world"); message = "已看清门前追兵：在此护住莺莺，挡过两次接近后再靠近楚婉。" if puzzle_id == "gate_encounter_verified" else "已观察当前巡逻方位与掩体。"; return true
	if a.type == "choose_fragment":
		if puzzle_id != "bell_response_verified" or not _inscription() or not _at(_next_anchor()) or a.get("value",-1) != state.fragments.size(): return false
		state.fragments.append(a.value); _event("moon_fragment_ordered")
		if state.fragments.size() == 3: _finish()
		return true
	if a.type == "guard":
		if puzzle_id != "gate_encounter_verified" or not _at("gate_guard") or not state.observed or state.approaches >= 2 or not state.carrying: return false
		var g := _p(state.guard_position); var next := g.move_toward(old,24)
		state.guard_position = _a(next); state.approaches += 1; state.guarded = true
		state.tick += 1; _event("pursuer_real_approach"); message = "已护住莺莺，追兵第%d次接近；其实际位置%s。" % [state.approaches,str(state.guard_position)]; return true
	if not _at(_next_anchor()): message = "先走到标记的位置，再按 E。"; return false
	match puzzle_id:
		"window_anchor_verified":
			if state.stage == 0: state.rope_attached = true; state.stage = 1; _event("liu_attached_rope"); message = "莺莺已系稳软索，走到右侧窗前清开障碍。"
			else: state.window_clear = true; _event("liang_cleared_window"); _finish()
		"horse_call_and_arrival":
			if not state.horse_called: state.horse_called = true; _event("liu_whistled"); _tick(old); message = "哨声已响；等胭脂沿巷走到落点，才能跃窗共骑。"
			elif state.horse_arrived:
				var landing := _p(state.horse_position)
				if old.distance_to(landing)>16 or not is_walkable(landing): return false
				state.position = state.horse_position.duplicate(); _event("both_window_step_to_landing"); _event("both_exit_to_same_horse"); _finish()
			else: message = "胭脂正在沿巷赶来，等到落脚点再跃窗。"; return false
		"liu_carried_not_combat": state.carrying = true; _event("carry_liu"); _finish()
		"shelter_route_verified":
			if not state.carrying: return false
			_event("carried_to_shelter"); _finish()
		"shelter_care_performed":
			if not state.carrying: return false
			state.screen_closed = _shelter() == "empty_boat"; state.care_done = true
			_event("closed_opaque_screen" if state.screen_closed else "spring_cloth_care"); _finish()
		"patrol_escape_verified": _event("cover_ray_checked"); _finish()
		"horse_release_verified":
			if _p(state.horse_position).distance_to(old)>8: message = "胭脂还在赶到绊缰处，不能隔空解缰。"; return false
			state.horse_released = true; _event("same_horse_knot_released"); _finish()
		"horse_calm_and_led":
			if not state.horse_released or _p(state.horse_position).distance_to(old)>17: return false
			_event("same_horse_led_to_safety"); _finish()
		"gate_encounter_verified":
			if state.stage == 0:
				if state.approaches < 2 or not state.guarded: message = "须先在门前观察、护住莺莺，挡过两次实际接近。"; return false
				state.chu_wan_held = true; state.stage = 1; _event("brief_restraint")
			else: _event("gate_crossed"); _finish()
		"chu_wan_released":
			if not state.chu_wan_held: return false
			state.chu_wan_held = false; _event("chu_wan_released"); _finish()
		"bell_cover_position": state.carrying = false; _event("liu_placed_safe_recess"); _finish()
		"moor_and_sit":
			state.stage += 1; _event("moor_tied" if state.stage == 1 else "both_seated"); message = "缆绳已系稳。走到舟首，再按E坐定。"
			if state.stage == 2: _finish()
		"bell_response_verified":
			if _inscription(): message = "在当前月光纹片处选择空、色、相依的次序。"; return false
			state.pulses += 1; _event("ear_cover_before_pulse"); message = "第一阵钟声已过，仍需捂好双耳应对第二阵；再按E护住。"
			if state.pulses == 2: _finish()
	return true
func _finish() -> void:
	state.complete = true; _event("objective_verified"); message = "本段位置与操作已验证。"
func _next_anchor() -> String:
	match puzzle_id:
		"window_anchor_verified": return "rope_anchor" if state.stage == 0 else "window"
		"horse_call_and_arrival": return "window"
		"liu_carried_not_combat": return "fork"
		"shelter_route_verified","shelter_care_performed": return _shelter()
		"patrol_escape_verified": return "woodpile"
		"horse_release_verified": return "horse_snag"
		"horse_calm_and_led": return "exit"
		"gate_encounter_verified": return "gate_guard" if state.approaches < 2 else ("chu_wan" if state.stage == 0 else "courtyard_gate")
		"chu_wan_released": return "release_point"
		"bell_cover_position": return "safe_recess"
		"moor_and_sit": return "moor" if state.stage == 0 else "boat_bow"
		"bell_response_verified": return ["inscription","inscription_two","inscription_three"][mini(2,state.fragments.size())] if _inscription() else "liu_rest"
	return "spawn"
func _anchor_label(id: String) -> String:
	return {"rope_anchor":"窗边系索点","window":"右侧窗前","fork":"巷口莺莺身旁","spring":"清泉边","empty_boat":"空船舱内","woodpile":"柴堆后","horse_snag":"受阻马缰","exit":"巷道安全出口","gate_guard":"门前守位（先观察，再护住两次）","chu_wan":"楚婉身旁","courtyard_gate":"院门内侧","release_point":"门后放行点","safe_recess":"钟下安全处","moor":"系舟缆柱","boat_bow":"舟首座位","liu_rest":"莺莺休息处","inscription":"月光纹片一","inscription_two":"月光纹片二","inscription_three":"月光纹片三"}.get(id,id)
func _visibility_label() -> String:
	var guard := _p(state.guard_position); var player := _p(state.position)
	if guard.distance_to(player)>144: return "警戒范围外"
	if (player-guard).dot(_p(state.guard_facing))<0: return "追兵背向此处"
	return "已进入视线" if line_visible(guard,player,_p(state.guard_facing)) else "柴堆墙体遮住视线"
func _title() -> String:
	return {"window_anchor_verified":"系索与清窗","horse_call_and_arrival":"唤马接应","liu_carried_not_combat":"背负莺莺","shelter_route_verified":"携人寻隐","shelter_care_performed":"泉舟照拂","patrol_escape_verified":"柴堆避巡","horse_release_verified":"解开马缰","horse_calm_and_led":"牵马离险","gate_encounter_verified":"院门护行","chu_wan_released":"门后放行","bell_cover_position":"钟下安置","moor_and_sit":"系舟并坐","bell_response_verified":"钟内相护"}.get(puzzle_id,"江南现场")
func _world_state() -> Dictionary:
	var result := state.duplicate(true); result.objective_id = puzzle_id; result.player_position = state.position.duplicate(); result.target_anchor = _next_anchor(); result.anchors = layout.anchors.duplicate(true)
	result.mounted_on = "animal_yanzhi" if puzzle_id == "horse_call_and_arrival" and state.complete else ""
	result.liu_position = state.position.duplicate() if state.carrying else _anchor("fork").duplicate()
	if puzzle_id == "bell_response_verified": result.liu_position = _anchor("liu_rest").duplicate()
	if puzzle_id == "bell_cover_position" and state.complete: result.liu_position = _anchor("safe_recess").duplicate()
	if puzzle_id == "window_anchor_verified": result.liu_position = _anchor("rope_anchor").duplicate()
	if puzzle_id == "horse_call_and_arrival": result.liu_position = _anchor("window").duplicate()
	if puzzle_id == "moor_and_sit": result.liu_position = _anchor("boat_bow").duplicate()
	return result
func _action_label() -> String:
	match puzzle_id:
		"window_anchor_verified": return "莺莺系索" if state.stage == 0 else "梁萧清窗"
		"horse_call_and_arrival": return "吹哨唤胭脂" if not state.horse_called else "跃窗共骑"
		"liu_carried_not_combat": return "背负莺莺"
		"shelter_care_performed": return "合上船屏" if _shelter()=="empty_boat" else "湿布擦脸"
		"horse_release_verified": return "解开实际马缰"
		"horse_calm_and_led": return "确认同马牵出"
		"gate_encounter_verified": return "靠近楚婉临时同行" if state.stage==0 else "走过院门"
		"chu_wan_released": return "放开楚婉"
		"bell_response_verified": return "护好双耳"
		"moor_and_sit": return "系牢舟缆" if state.stage==0 else "并肩坐定"
	return "操作当前位置"
func get_view() -> Dictionary:
	var options: Array = [{"label":"E · "+_action_label(),"action":{"type":"interact"}},{"label":"等一相","action":{"type":"wait"}},{"label":"恢复本段起点","action":{"type":"retry"}}]
	if puzzle_id in ["gate_encounter_verified","patrol_escape_verified","horse_release_verified","horse_calm_and_led"]: options.insert(1,{"label":"观察现场","action":{"type":"inspect"}})
	if puzzle_id == "gate_encounter_verified": options.insert(2,{"label":"护住莺莺，迎下一次接近","action":{"type":"guard"}})
	if puzzle_id == "bell_response_verified" and _inscription():
		for i in range(3): options.append({"label":["空","色","相依"][i],"action":{"type":"choose_fragment","value":i}})
	var status := ""
	if puzzle_id == "bell_response_verified": status = "\n护耳声脉 %d/2；纹片 %d/3" % [state.pulses,state.fragments.size()]
	if puzzle_id == "horse_call_and_arrival": status = "\n胭脂位置 %s；%s" % [str(state.horse_position),"已到落点" if state.horse_arrived else "尚未到达"]
	if puzzle_id in ["gate_encounter_verified","chu_wan_released"]:
		status = "\n观察：%s；守势：%s；接近 %d/2；楚婉：%s" % ["已看清" if state.observed else "未观察","护住" if state.guarded else "未就位",state.approaches,"临时同行" if state.chu_wan_held else "自由"]
	return {"id":puzzle_id,"title":_title(),"body":message+status+"\n目标："+_anchor_label(_next_anchor())+" "+str(_anchor(_next_anchor()))+"\n位置 "+str(state.position)+("；追兵 "+str(state.guard_position)+" · "+["看前","转向","步行"][int(state.tick)%3]+" · "+_visibility_label() if puzzle_id in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"] else ""),"options":options,"state":state.duplicate(true),"complete":state.complete,"world_state":_world_state(),"paused_step_mode":true}
func receipt() -> Dictionary:
	if not state.get("complete",false) or state.get("captured",false): return {}
	return {"version":VERSION,"chapter":4,"puzzle_id":puzzle_id,"objective_id":puzzle_id,"scene_id":scene_id,"attempt_id":attempt_id,"map_id":map_id,"input_log":input_log.duplicate(true),"engine_event_log":engine_event_log.duplicate(true),"before_state_hash":initial_hash,"after_state_hash":_hash_state(),"frozen_config_hash":frozen_hash,"world_state":_world_state(),"consumed_by_transaction":""}
func get_receipts() -> Array: return [] if receipt().is_empty() else [receipt()]
func snapshot() -> Dictionary:
	return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context":context.duplicate(true),"frozen_config_hash":frozen_hash,"input_log":input_log.duplicate(true),"state_hash":_hash_state(),"event_hash":_encoded(engine_event_log).sha256_text()}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if saved.size()!=8 or saved.get("version",0)!=VERSION or not saved.get("input_log",null) is Array or saved.input_log.size()>LIMIT: return false
	var replay := ChapterFourWorldActions.new()
	if not replay.begin(str(saved.get("puzzle_id","")),str(saved.get("attempt_id","")),trusted_context): return false
	if _encoded(saved.get("context",{})) != _encoded(trusted_context) or saved.get("frozen_config_hash","") != replay.frozen_hash: return false
	for action in saved.input_log:
		if not action is Dictionary: return false
		replay.apply_input(action)
	if _encoded(replay.snapshot()) != _encoded(saved): return false
	begin(replay.puzzle_id,replay.attempt_id,trusted_context)
	for action in saved.input_log: apply_input(action)
	return true
static func replay_receipt(proof: Dictionary, trusted_context: Dictionary = {}) -> Dictionary:
	if proof.get("version",0)!=VERSION or not proof.get("input_log",null) is Array or proof.input_log.size()>LIMIT: return {}
	var replay := ChapterFourWorldActions.new()
	if not replay.begin(str(proof.get("puzzle_id","")),str(proof.get("attempt_id","")),trusted_context): return {}
	for action in proof.input_log:
		if not action is Dictionary: return {}
		replay.apply_input(action)
	var actual := replay.receipt()
	return actual if _encoded(actual) == _encoded(proof) else {}
