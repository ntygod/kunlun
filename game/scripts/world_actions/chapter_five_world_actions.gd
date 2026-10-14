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
	if id=="axue_bank" and state.get("actor_positions",{}).has("char_axue"):return state.actor_positions.char_axue
	return layout.anchors[id]
func _hash_state() -> String: return _encoded(state).sha256_text()
func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	# Validation happens on a temporary instance; any failure preserves this live session.
	var candidate=load("res://scripts/world_actions/chapter_five_world_actions.gd").new()
	if not candidate._begin_internal(id,attempt,trusted_context):return false
	for field in ["puzzle_id","attempt_id","scene_id","map_id","context","layout","config","state","input_log","engine_event_log","frozen_hash","initial_hash","message"]:
		var value: Variant=candidate.get(field)
		set(field,value.duplicate(true) if value is Dictionary or value is Array else value)
	return true
static func _valid_point(value: Variant, map: Dictionary) -> bool:
	if not value is Array or value.size()!=2:return false
	for number in value:
		if not number is int and not number is float:return false
		if not is_finite(float(number)) or fmod(float(number),16)!=0:return false
	var pos:=Vector2(value[0],value[1]);var b:Array=map.walk_bounds
	if pos.x<b[0] or pos.y<b[1] or pos.x>b[0]+b[2] or pos.y>b[1]+b[3]:return false
	for rect in map.solids+map.get("deep_water_rects",[]):
		if Rect2(rect[0]-8,rect[1]-4,rect[2]+16,rect[3]+8).has_point(pos):return false
	return true
func _valid_spatial(prior: Dictionary, maps: Dictionary) -> bool:
	if prior.is_empty():return true
	if not prior.get("map_id") is String or not maps.has(prior.map_id):return false
	var source:Dictionary=maps[prior.map_id]
	if prior.has("player_position") and not _valid_point(prior.player_position,source):return false
	if not prior.get("actor_positions",{}) is Dictionary:return false
	var ids:Array=[]
	for actor in source.actors:ids.append(actor.id)
	if prior.has("control_actor_id") and prior.control_actor_id not in ids:return false
	for actor in prior.get("actor_positions",{}):
		if actor not in ids or not _valid_point(prior.actor_positions[actor],source):return false
	if not prior.get("actor_postures",{}) is Dictionary:return false
	for actor in prior.get("actor_postures",{}):
		if actor not in ids or prior.actor_postures[actor] not in ["resting","concealed","guarding","assisted","carried"]:return false
	for field in ["hat_position","windbreak_position","guard_position"]:
		if prior.has(field) and prior[field]!=[] and not _valid_point(prior[field],source):return false
	if not prior.get("carrying_pair",{}) is Dictionary:return false
	var pair:Dictionary=prior.get("carrying_pair",{})
	if not pair.is_empty() and (pair.size()!=2 or pair.get("carrier_id") not in ids or pair.get("passenger_id") not in ids or pair.get("carrier_id")==pair.get("passenger_id")):return false
	return true
func _begin_internal(id: String, attempt: String, trusted_context: Dictionary) -> bool:
	if id not in IDS: return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not data is Dictionary: return false
	puzzle_id = id; attempt_id = attempt; context = trusted_context.duplicate(true)
	for mid in data.maps:
		if data.maps[mid].sessions.has(id): map_id = mid; layout = data.maps[mid]; config = layout.sessions[id]; break
	if layout.is_empty(): return false
	for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",config.control_actor_id]]:
		if context.has(pair[0]) and context[pair[0]] != pair[1]: return false
	if not context.get("world_objects",{}) is Dictionary or not context.get("items",{}) is Dictionary or not context.get("carrying_pair",{}) is Dictionary:return false
	var previous_value:Variant=context.get("world_objects",{}).get("ch05_spatial_state",{})
	if not previous_value is Dictionary or not _valid_spatial(previous_value,data.maps):return false
	scene_id = str(context.get("scene_id", "ch05_"+id))
	frozen_hash = _encoded(layout).sha256_text()
	if id=="axue_capture_verified":
		var prior: Dictionary=context.get("world_objects",{}).get("ch05_spatial_state",{})
		var actor_position: Variant=prior.get("actor_positions",{}).get("char_liang_xiao")
		if prior.get("objective_id","")!="small_hat_dropped_verified" or prior.get("map_id","")!=map_id or prior.get("control_actor_id","")!="char_liang_xiao" or prior.get("complete")!=true or prior.get("stage")!=1 or not actor_position is Array or actor_position.size()!=2:return false
		if _encoded(actor_position)!=_encoded(layout.anchors.thorn_hat) or _encoded(prior.get("player_position"))!=_encoded(actor_position):return false
		for number in actor_position:
			if not number is int and not number is float:return false
			if not is_finite(float(number)) or fmod(float(number),16)!=0:return false
		if not is_walkable(_p(actor_position)):return false
	if id in ["pool_escape_verified","cave_refuge_verified"]:
		var prior: Dictionary=context.get("world_objects",{}).get("ch05_spatial_state",{})
		var expected: String="axue_escape_verified" if id=="pool_escape_verified" else "pool_escape_verified"
		if prior.get("objective_id","")!=expected or prior.get("complete")!=true or prior.get("map_id","")!="map_ch05_pool_escape" or prior.get("control_actor_id","")!="char_liang_xiao":return false
		if prior.get("stage")!=(2 if id=="pool_escape_verified" else 3):return false
		if prior.get("carrying_pair",{})!={"carrier_id":"char_liang_xiao","passenger_id":"char_axue"}:return false
		var passenger: Variant=prior.get("actor_positions",{}).get("char_axue")
		var carrier: Variant=prior.get("player_position")
		if not passenger is Array or passenger.size()!=2 or not carrier is Array or carrier.size()!=2:return false
		if _encoded(passenger)!=_encoded(carrier):return false
		var required_endpoint:Array=data.maps.map_ch05_pool_escape.anchors["pine_cover" if id=="pool_escape_verified" else "cave_mouth"]
		if _encoded(carrier)!=_encoded(required_endpoint):return false
		if _encoded(prior.get("actor_positions",{}).get("char_liang_xiao"))!=_encoded(carrier):return false
	input_log.clear(); engine_event_log.clear(); _reset()
	if not is_walkable(_p(state.position)) or float(state.position[0])!=floor(float(state.position[0])) or float(state.position[1])!=floor(float(state.position[1])) or int(state.position[0])%16 or int(state.position[1])%16: return false
	if id in ["pool_escape_verified","cave_refuge_verified"] and not _same_carried_axue():return false
	initial_hash = _hash_state(); return true
func _reset() -> void:
	state = {"position":_anchor(config.entry_anchor).duplicate(),"stage":0,"tick":0,"complete":false,"captured":false,"control_actor_id":config.control_actor_id,"map_id":map_id,"carrying_pair":context.get("carrying_pair",{}).duplicate(true),"actor_positions":{},"actor_postures":{},"guard_position":[336,144],"guard_facing":[1,0],"observed":false,"concealed":false,"submerged":false,"decoy_released":false,"hat_position":[],"hat_recovered":false,"tray_taken":false,"cover_withdrawn":false,"breath_observations":0,"escorted_actor_id":"","tray_delivered":false,"sword_found":false,"windbreak_position":[],"gate_unlatched":false}
	var previous: Dictionary = context.get("world_objects",{}).get("ch05_spatial_state",{})
	if previous.get("map_id","") == map_id:
		# Positions belong to an actual actor, not a universal cursor across viewpoints.
		if previous.get("control_actor_id","") == config.control_actor_id:
			state.position = previous.get("player_position",state.position).duplicate()
			state.carrying_pair = previous.get("carrying_pair",state.carrying_pair).duplicate(true)
		for key in ["actor_positions","actor_postures","hat_position","hat_recovered","decoy_released"]:
			if previous.has(key): state[key] = previous[key].duplicate(true) if previous[key] is Dictionary or previous[key] is Array else previous[key]
	if puzzle_id == "wulong_hide_verified": state.carrying_pair = {"carrier_id":"char_liu_yingying","passenger_id":"char_liang_xiao"}

	if puzzle_id=="leigong_infiltration_verified":
		if not state.actor_positions.has("char_liang_xiao"):state.actor_positions.char_liang_xiao=_a(_p(layout.anchors.side_latch)-Vector2(16,0))
	if puzzle_id=="axue_escape_verified":state.actor_postures.char_axue="resting"
	if puzzle_id=="cave_refuge_verified":
		# Explicit cross-map transfer carries the same verified pair to cave entry.
		state.carrying_pair=previous.carrying_pair.duplicate(true);state.actor_positions.char_axue=state.position.duplicate()
	if puzzle_id == "small_hat_dropped_verified": state.position = _anchor("thorn_hat").duplicate();state.actor_postures.char_liang_xiao="resting"
	if puzzle_id == "small_hat_recovered_verified":
		var hat: Dictionary=context.get("items",{}).get("item_ch04_small_willow_hat",context.get("world_objects",{}).get("item_ch04_small_willow_hat",{}))
		if hat.get("owner","")=="ch05_thorn_hat" and hat.get("state","")=="placed" and hat.get("location","")==map_id and hat.get("position") is Array:state.hat_position=hat.position.duplicate()
	for actor in layout.actors:
		if actor.id in config.visible_actor_ids and not state.actor_positions.has(actor.id):state.actor_positions[actor.id]=actor.position.duplicate()
	if puzzle_id=="canal_rescue_verified":state.actor_postures.npc_bayan="resting"
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
	var blockers: Array=layout.solids.duplicate(true)
	for actor in state.get("actor_postures",{}):
		if state.actor_postures[actor]=="concealed" and state.actor_positions.has(actor):
			var pos:=_p(state.actor_positions[actor]);blockers.append([pos.x-24,pos.y-16,48,6])
	for r in blockers:
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
	if puzzle_id=="leigong_infiltration_verified" and state.gate_unlatched:
		state.actor_positions.char_liang_xiao=_a(_path_step(_p(state.actor_positions.char_liang_xiao),old))
	if not state.escorted_actor_id.is_empty():
		var guest:=_p(state.actor_positions[state.escorted_actor_id])
		if guest.distance_to(old)<=24:
			var next:=guest.move_toward(old,16)
			if is_walkable(next):state.actor_positions[state.escorted_actor_id]=_a(next)
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
		if puzzle_id=="leigong_infiltration_verified" and not state.gate_unlatched and next.x>float(layout.anchors.side_latch[0]):message="门闩尚未解开，不能越过侧门。";return false
		if not is_walkable(next): message="岸壁、门墙或家具阻路。"; return false
		state.position = _a(next); _event("walk"); _tick(old); return true
	if a.type=="wait": _tick(old); return true
	if a.type=="inspect": state.observed=true; _event("observe"); message="观察眼前掩体与守卫朝向。"; return true
	if old.distance_to(_p(_anchor(_next_anchor())))>8: message="先走到眼前标记再按 E。"; return false
	var verb: String = config.steps[state.stage].verb
	match verb:
		"unlatch":
			if puzzle_id=="leigong_infiltration_verified":state.gate_unlatched=true
		"enter":
			if puzzle_id=="leigong_infiltration_verified" and (not state.gate_unlatched or _p(state.actor_positions.char_liang_xiao).distance_to(old)>8):message="梁萧仍沿已开小径赶来；空格等一相，等他到门口再一起进入。";return false
		"assist":
			if puzzle_id in ["canal_rescue_verified","chuxianliu_rescue_verified"]:
				var who: String="npc_bayan" if puzzle_id=="canal_rescue_verified" else "npc_chu_xianliu"
				if _p(state.actor_positions[who]).distance_to(old)>8:return false
				state.escorted_actor_id=who;state.actor_postures[who]="guarding" if puzzle_id=="chuxianliu_rescue_verified" else "assisted"
			if puzzle_id=="axue_escape_verified":
				if _p(state.actor_positions.char_axue).distance_to(old)>8:return false
				state.carrying_pair={"carrier_id":"char_liang_xiao","passenger_id":"char_axue"};state.actor_postures.char_axue="carried"
		"settle":
			state.carrying_pair={};state.actor_positions.char_axue=state.position.duplicate();state.actor_postures.char_axue="resting"
		"lift": state.carrying_pair={"carrier_id":"char_axue","passenger_id":"char_liang_xiao"}
		"lay_down": state.carrying_pair={}; state.actor_positions.char_liang_xiao=state.position.duplicate(); state.actor_postures.char_liang_xiao="resting"
		"conceal": state.concealed=true;state.actor_postures.char_liang_xiao="concealed"
		"drop_hat": state.hat_position=state.position.duplicate();state.actor_postures.char_liang_xiao="resting"
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
			state.tray_delivered=true
		"reclaim":state.sword_found=true
		"withdraw_cover","escort":
			if state.escorted_actor_id.is_empty() or _p(state.actor_positions[state.escorted_actor_id]).distance_to(old)>24:return false
			state.cover_withdrawn=true;state.actor_postures[state.escorted_actor_id]="guarding" if puzzle_id=="chuxianliu_rescue_verified" else "resting";state.escorted_actor_id=""
		"release_decoy":state.decoy_released=true
		"submerge":
			if not state.decoy_released:return false
			state.submerged=true
		"surface":
			if not _same_carried_axue():return false
			state.submerged=false
		"shelter":
			if puzzle_id=="cave_refuge_verified":
				if state.actor_postures.get("char_axue","")!="resting":return false
				state.windbreak_position=state.position.duplicate()
	state.actor_positions[config.control_actor_id]=state.position.duplicate()
	_event(verb);state.stage+=1
	message=_verb_feedback(verb)
	if state.stage==config.steps.size():state.complete=true;_event("objective_complete");message+=" 本段已完成。"
	return true
func _world_state() -> Dictionary:
	var result:=state.duplicate(true);result.erase("position");result.player_position=state.position.duplicate();result.objective_id=puzzle_id
	result.target_position=_anchor(_next_anchor()).duplicate();result.target_anchor=_next_anchor();result.visible_actor_ids=config.visible_actor_ids.duplicate();result.restricted=config.restricted
	if puzzle_id=="leigong_infiltration_verified":result.visible_actor_ids.append("char_liang_xiao")
	for actor in result.actor_positions.keys():
		if actor not in result.visible_actor_ids:result.actor_positions.erase(actor)
	if not config.guarded:result.erase("guard_position");result.erase("guard_facing")
	return result
func get_view() -> Dictionary:
	var target:=_anchor(_next_anchor())
	var status: String="\n梁萧 %s；侧门%s。" % [str(state.actor_positions.char_liang_xiao),"已开，可等他会合" if state.gate_unlatched else "尚闭，梁在门外待候"] if puzzle_id=="leigong_infiltration_verified" else ""
	return {"puzzle_id":puzzle_id,"title":_scene_label(),"body":"%s\n阶段 %d/%d　目标 %s %s\n%s" % [_scene_label(),mini(int(state.stage)+1,config.get("steps",[]).size()),config.get("steps",[]).size(),_anchor_label(_next_anchor()),str(target),message+status],"state":{"complete":state.complete,"captured":state.captured,"stage":state.stage},"complete":state.get("complete",false),"paused_step_mode":true,"world_state":_world_state(),"options":[{"id":"interact","label":"E 操作","action":{"type":"interact"}},{"id":"wait","label":"等候一相","action":{"type":"wait"}},{"id":"retry","label":"重试本段","action":{"type":"retry"}}]}
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

func _anchor_label(id: String) -> String:
	return {"boarding_plank":"靠船跳板","wounded_guest":"蓝袍伤者身旁","cabin_cover":"船舱掩护处","wall_shadow":"外墙阴影","side_latch":"侧门门闩","vault_entry":"秘库入口","hollow_bed":"树洞干草卧处","leaf_screen":"树洞叶屏","water_exit":"取水出口","stream":"山溪取水处","return_trail":"回林山道","blood_trace":"草间血迹","broken_branch":"折断的枝条","hollow_return":"重返树洞小径","thorn_hat":"荆棘遗笠处","weak_liang":"虚弱梁萧身旁","concealed_transfer":"隐蔽押送出口","porridge_tray":"温粥托盘","cell_hatch":"圆室送粥口","cell_latch":"甬道暗闩","chu_position":"楚仙流掩护位置","screened_exit":"有遮蔽的出口","sword_rack":"铉元剑置架","axue_bank":"受伤阿雪身旁","pine_cover":"岸边松木掩护","submerged_rock":"水下伏石","cave_mouth":"隐蔽水洞入口","dry_ledge":"洞中干燥石台","dry_moss":"干苔藓","sheltered_rest":"石台东侧遮风屏","breath_seat":"持球静坐处"}.get(id,"当前落足处")
func _scene_label() -> String:
	return "借楚仙流掩护撤离" if puzzle_id=="chuxianliu_rescue_verified" else str(config.get("label","局部操作"))
func _verb_feedback(verb: String) -> String:
	if puzzle_id=="chuxianliu_rescue_verified":
		return {"unlatch":"楚仙流正牵制追来之人，你趁机打开脱困暗闩。","assist":"已与楚仙流确认掩护方向，由他护住侧后，一同向出口撤离。","escort":"已抵达脱困出口，楚仙流仍站在侧后警戒掩护。"}.get(verb,"借同伴掩护继续撤离。")
	if verb=="shelter" and puzzle_id=="cave_refuge_verified":return "已在石台东侧支起干苔遮风屏；阿雪仍覆衣安卧石台。"
	return {"board":"踏稳跳板，已经登船。","assist":"已靠近伤者并扶稳，继续向掩护处移动。","withdraw_cover":"伤者已退入船舱掩护。","inspect":"已俯身辨认当前痕迹。","unlatch":"已在门边解开暗闩。","enter":"已沿侧门潜入秘库入口。","lay_down":"已将虚弱的梁萧平放在干草上，伏卧休息。","conceal":"已拉拢枝叶遮住树洞，梁萧仍卧在叶屏之后。","leave":"已经离开树洞前缘，准备独自取水。","collect_water":"已经在溪边装满水囊。","return":"携水回到林间小径。","search":"逐处搜过，仍未找到梁萧。","drop_hat":"手指松开，染血的小笠落在眼前荆棘处。","recover_hat":"在同一荆棘处拾起染血小笠。","lift":"阿雪扶起虚弱的梁萧，将他背稳。","shelter":"已停在遮挡处，暂避外侧视线。","handoff":"已背着伤者到达隐蔽押送出口。","take_tray":"已端起温粥，向送粥口走去。","deliver":"温粥已从送粥口送到梁萧面前。","escort":"已经接应楚仙流至有遮蔽的出口。","reclaim":"已在置架处找回同一柄铉元剑。","release_decoy":"松木诱饵已放开，下一步潜到伏石。","submerge":"已潜伏水下伏石，屏息等追兵视线掠过。","surface":"已从隐蔽水洞入口出水。","settle":"已把受伤的阿雪安置在干燥石台，覆衣休息。","gather":"已取到干苔藓，准备避风遮护。","breathe_observe":"已完成一次持球呼吸与体感观察。"}.get(verb,"当前操作已完成。")

func _same_carried_axue() -> bool:
	return state.get("control_actor_id","")=="char_liang_xiao" and state.get("carrying_pair",{})=={"carrier_id":"char_liang_xiao","passenger_id":"char_axue"} and _encoded(state.get("actor_positions",{}).get("char_axue"))==_encoded(state.get("position"))

func _path_step(start: Vector2,target: Vector2) -> Vector2:
	if start==target:return start
	var queue:Array=[start];var previous:Dictionary={start:start};var index:=0
	while index<queue.size():
		var p:Vector2=queue[index];index+=1
		if p==target:
			while previous[p]!=start:p=previous[p]
			return p
		for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next:Vector2=p+direction*16
			if not previous.has(next) and is_walkable(next):previous[next]=p;queue.append(next)
	return start
