class_name ChapterFiveWorldActions
extends RefCounted
## Compact authored local scenes. Only runtime may award items or alter actor stats.
const MAP_PATH := "res://data/maps/chapter_five_maps.json"
const LIMIT := 4096
const IDS := ["canal_rescue_verified","leigong_infiltration_verified","wulong_hide_verified","liu_water_search_verified","liu_wounded_search_verified","small_hat_dropped_verified","small_hat_recovered_verified","axue_capture_verified","porridge_delivered_verified","chuxianliu_rescue_verified","sword_reclaimed_verified","axue_escape_verified","pool_escape_verified","cave_refuge_verified","yin_yang_breath_verified"]
var puzzle_id := ""
var attempt_id := ""
var scene_id := ""
var map_id := ""
var context: Dictionary = {}
var layout: Dictionary = {}
var config: Dictionary = {}
var state: Dictionary = {}
var input_log: Array = []
var engine_event_log: Array = []
var frozen_hash := ""
var initial_hash := ""
var message := ""
static func _canonical(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floor(v): return int(v)
	if v is Array:
		var a: Array = []
		for x in v: a.append(_canonical(x))
		return a
	if v is Dictionary:
		var d := {}
		for k in v: d[k] = _canonical(v[k])
		return d
	return v
static func _encoded(v: Variant) -> String: return JSON.stringify(_canonical(v))
func _p(a: Array) -> Vector2: return Vector2(a[0],a[1])
func _a(p: Vector2) -> Array: return [int(p.x),int(p.y)]
func _anchor(id: String) -> Array:
	if id=="weak_liang" and state.get("actor_positions",{}).has("char_liang_xiao"):return state.actor_positions.char_liang_xiao
	return layout.anchors[id]
func _hash_state() -> String: return _encoded(state).sha256_text()
func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if id not in IDS: return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not data is Dictionary: return false
	puzzle_id = id; attempt_id = attempt; context = trusted_context.duplicate(true)
	for mid in data.maps:
		if data.maps[mid].sessions.has(id): map_id = mid; layout = data.maps[mid]; config = layout.sessions[id]; break
	if layout.is_empty(): return false
	for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",config.control_actor_id]]:
		if context.has(pair[0]) and context[pair[0]] != pair[1]: return false
	scene_id = str(context.get("scene_id", "ch05_"+id))
	frozen_hash = _encoded(layout).sha256_text()
	if id=="axue_capture_verified":
		var prior: Dictionary=context.get("world_objects",{}).get("ch05_spatial_state",{})
		var actor_position: Variant=prior.get("actor_positions",{}).get("char_liang_xiao")
		if prior.get("objective_id","")!="small_hat_dropped_verified" or prior.get("map_id","")!=map_id or not actor_position is Array or actor_position.size()!=2:return false
		for number in actor_position:
			if not number is int and not number is float:return false
			if not is_finite(float(number)) or fmod(float(number),16)!=0:return false
		if not is_walkable(_p(actor_position)):return false
	input_log.clear(); engine_event_log.clear(); _reset()
	if not is_walkable(_p(state.position)) or float(state.position[0])!=floor(float(state.position[0])) or float(state.position[1])!=floor(float(state.position[1])) or int(state.position[0])%16 or int(state.position[1])%16: return false
	initial_hash = _hash_state(); return true
func _reset() -> void:
	state = {"position":_anchor(config.entry_anchor).duplicate(),"stage":0,"tick":0,"complete":false,"captured":false,"control_actor_id":config.control_actor_id,"map_id":map_id,"carrying_pair":context.get("carrying_pair",{}).duplicate(true),"actor_positions":{},"guard_position":[336,144],"guard_facing":[1,0],"observed":false,"concealed":false,"submerged":false,"decoy_released":false,"hat_position":[],"hat_recovered":false,"tray_taken":false,"cover_withdrawn":false,"breath_observations":0}
	var previous: Dictionary = context.get("world_objects",{}).get("ch05_spatial_state",{})
	if previous.get("map_id","") == map_id:
		# Positions belong to an actual actor, not a universal cursor across viewpoints.
		if previous.get("control_actor_id","") == config.control_actor_id:
			state.position = previous.get("player_position",state.position).duplicate()
			state.carrying_pair = previous.get("carrying_pair",state.carrying_pair).duplicate(true)
		for key in ["actor_positions","hat_position","hat_recovered","decoy_released"]:
			if previous.has(key): state[key] = previous[key].duplicate(true) if previous[key] is Dictionary or previous[key] is Array else previous[key]
	if puzzle_id == "wulong_hide_verified": state.carrying_pair = {"carrier_id":"char_liu_yingying","passenger_id":"char_liang_xiao"}

	if puzzle_id in ["axue_escape_verified","pool_escape_verified","cave_refuge_verified"]: state.actor_positions.char_axue = state.position.duplicate()
	if puzzle_id == "small_hat_dropped_verified": state.position = _anchor("thorn_hat").duplicate()
	state.actor_positions[config.control_actor_id]=state.position.duplicate()
	message = "走到当前标记按 E；方向逐格移动，空格等候，R 重试。"
func is_walkable(p: Vector2) -> bool:
	var b: Array = layout.walk_bounds
	if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]: return false
	for r in layout.solids+layout.get("deep_water_rects",[]):
		if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(p): return false
	return true
func line_visible(a: Vector2,b: Vector2,facing: Vector2 = Vector2.ZERO) -> bool:
	if a.distance_to(b)>128 or (facing!=Vector2.ZERO and (b-a).dot(facing)<0): return false
	for r in layout.solids:
		for i in range(int(a.distance_to(b)/2)+1):
			if Rect2(r[0],r[1],r[2],r[3]).grow(2).has_point(a.lerp(b,float(i)/maxi(1,int(a.distance_to(b)/2)))): return false
	return true
static func swept_contact(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	var r := a-c; var v := b-a-d+c
	var t := clampf(-r.dot(v)/v.length_squared(),0,1) if v.length_squared()>0 else 0.0
	return (r+v*t).length()<12
func _event(kind: String) -> void: engine_event_log.append({"type":kind,"tick":state.tick,"position":state.position.duplicate()})
func _tick(old: Vector2) -> void:
	state.tick += 1
	state.actor_positions[config.control_actor_id]=state.position.duplicate()
	if not state.carrying_pair.is_empty(): state.actor_positions[state.carrying_pair.passenger_id] = state.position.duplicate()
	if config.guarded:
		var before := _p(state.guard_position)
		state.guard_facing = [1,0] if int(state.tick/4)%2==0 else [-1,0]
		if state.tick%2==0: state.guard_position = _a(before+_p(state.guard_facing)*16)
		if swept_contact(old,_p(state.position),before,_p(state.guard_position)) or line_visible(_p(state.guard_position),_p(state.position),_p(state.guard_facing)):
			state.captured = true; _event("discovered"); message = "行迹暴露。R 恢复本段可信起点，不更改生命或物品。"
func _next_anchor() -> String: return config.steps[mini(int(state.stage),config.steps.size()-1)].anchor
func apply_input(action: Dictionary) -> Dictionary:
	var type: Variant = action.get("type")
	if not type is String or type not in ["move","interact","inspect","wait","retry"] or puzzle_id.is_empty(): return {"ok":false}
	var allowed := ["type","dx","dy"] if type=="move" else ["type"]
	for key in action:
		if key not in allowed: return {"ok":false,"message":"不接受外部坐标、成功或角色状态。"}
	if type=="move":
		for key in ["dx","dy"]:
			if not action.get(key) is int and not action.get(key) is float: return {"ok":false}
		var dx := float(action.dx); var dy := float(action.dy)
		if not is_finite(dx) or not is_finite(dy) or dx!=floor(dx) or dy!=floor(dy) or absf(dx)+absf(dy)!=1: return {"ok":false}
	if input_log.size()>=LIMIT:
		if type!="retry": return {"ok":false,"message":"记录已满；R 重开本段仍可继续。"}
		begin(puzzle_id,attempt_id,context.duplicate(true))
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt()}
func _operate(a: Dictionary) -> bool:
	if a.type=="retry": _reset(); _event("retry"); return true
	if state.complete or state.captured: return false
	var old := _p(state.position)
	if a.type=="move":
		if config.restricted: message="重伤视角无法自由行走；只回应眼前可感知的物件。"; return false
		var next := old+Vector2(a.dx,a.dy)*16
		if not is_walkable(next): message="岸壁、门墙或家具阻路。"; return false
		state.position = _a(next); _event("walk"); _tick(old); return true
	if a.type=="wait": _tick(old); return true
	if a.type=="inspect": state.observed=true; _event("observe"); message="观察眼前掩体与守卫朝向。"; return true
	if old.distance_to(_p(_anchor(_next_anchor())))>8: message="先走到眼前标记再按 E。"; return false
	var verb: String = config.steps[state.stage].verb
	match verb:
		"assist":
			if puzzle_id=="axue_escape_verified":state.carrying_pair={"carrier_id":"char_liang_xiao","passenger_id":"char_axue"}
		"settle":
			state.carrying_pair={};state.actor_positions.char_axue=state.position.duplicate()
		"lift": state.carrying_pair={"carrier_id":"char_axue","passenger_id":"char_liang_xiao"}
		"lay_down": state.carrying_pair={}; state.actor_positions.char_liang_xiao=state.position.duplicate()
		"conceal": state.concealed=true
		"drop_hat": state.hat_position=state.position.duplicate()
		"recover_hat":
			var hat: Dictionary=context.get("items",{}).get("item_ch04_small_willow_hat",context.get("world_objects",{}).get("item_ch04_small_willow_hat",{}))
			if hat.get("owner","")!="ch05_thorn_hat" or hat.get("state","")!="placed" or hat.get("location","")!=map_id or not hat.get("position") is Array:return false
			var saved_hat: Array=hat.position
			if _p(saved_hat).distance_to(old)>8: return false
			state.hat_position=saved_hat.duplicate();state.hat_recovered=true
		"breathe_observe":state.breath_observations+=1
		"take_tray": state.tray_taken=true
		"deliver":
			if not state.tray_taken:return false
		"withdraw_cover":state.cover_withdrawn=true
		"release_decoy":state.decoy_released=true
		"submerge":
			if not state.decoy_released:return false
			state.submerged=true
		"surface":state.submerged=false
	state.actor_positions[config.control_actor_id]=state.position.duplicate()
	_event(verb);state.stage+=1
	message="已完成当前局部操作，继续前往下一标记。"
	if state.stage==config.steps.size():state.complete=true;_event("objective_complete");message="位置与动作已验证；剧情、物品和队伍交由主流程结算。"
	return true
func _world_state() -> Dictionary:
	var result:=state.duplicate(true);result.erase("position");result.player_position=state.position.duplicate();result.objective_id=puzzle_id
	result.target_position=_anchor(_next_anchor()).duplicate();result.target_anchor=_next_anchor();result.visible_actor_ids=config.visible_actor_ids.duplicate();result.restricted=config.restricted
	for actor in result.actor_positions.keys():
		if actor not in result.visible_actor_ids:result.actor_positions.erase(actor)
	if not config.guarded:result.erase("guard_position");result.erase("guard_facing")
	return result
func get_view() -> Dictionary:
	var target:=_anchor(_next_anchor())
	return {"puzzle_id":puzzle_id,"title":config.get("label","局部操作"),"body":"%s\n阶段 %d/%d　目标 %s %s\n%s" % [config.get("label",""),mini(int(state.stage)+1,config.get("steps",[]).size()),config.get("steps",[]).size(),_next_anchor(),str(target),message],"state":{"complete":state.complete,"captured":state.captured,"stage":state.stage},"complete":state.get("complete",false),"paused_step_mode":true,"world_state":_world_state(),"options":[{"id":"interact","label":"E 操作","action":{"type":"interact"}},{"id":"wait","label":"等候一相","action":{"type":"wait"}},{"id":"retry","label":"重试本段","action":{"type":"retry"}}]}
func snapshot() -> Dictionary:
	return {"version":1,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"map_hash":frozen_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true),"events":engine_event_log.duplicate(true)}
func restore(saved: Dictionary,trusted_context: Dictionary = {}) -> bool:
	var replay=load("res://scripts/world_actions/chapter_five_world_actions.gd").new()
	if not replay.begin(str(saved.get("puzzle_id","")),str(saved.get("attempt_id","")),trusted_context):return false
	if not saved.get("input_log") is Array or saved.input_log.size()>LIMIT:return false
	for action in saved.input_log:
		if not action is Dictionary:return false
		replay.apply_input(action)
	if _encoded(replay.snapshot())!=_encoded(saved):return false
	begin(replay.puzzle_id,replay.attempt_id,trusted_context)
	for action in saved.input_log:apply_input(action)
	return true
func receipt() -> Dictionary:
	if not state.get("complete",false):return {}
	return {"version":1,"puzzle_id":puzzle_id,"objective_id":puzzle_id,"attempt_id":attempt_id,"scene_id":scene_id,"map_id":map_id,"map_hash":frozen_hash,"before_state_hash":initial_hash,"after_state_hash":_hash_state(),"inputs":input_log.duplicate(true),"engine_events":engine_event_log.duplicate(true),"world_state":_world_state()}
func get_receipts() -> Array: return [receipt()] if state.get("complete",false) else []
static func replay_receipt(proof: Dictionary,trusted_context: Dictionary = {}) -> Dictionary:
	var replay=load("res://scripts/world_actions/chapter_five_world_actions.gd").new()
	if not replay.begin(str(proof.get("puzzle_id","")),str(proof.get("attempt_id","")),trusted_context):return {}
	if not proof.get("inputs") is Array or proof.inputs.size()>LIMIT:return {}
	for action in proof.inputs:
		if not action is Dictionary:return {}
		replay.apply_input(action)
	var actual:Dictionary=replay.receipt()
	return actual if _encoded(actual)==_encoded(proof) else {}
