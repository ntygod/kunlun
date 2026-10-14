class_name ChapterSixWorldActions
extends RefCounted
## Authored development scenes. Inventory, recovery and rewards belong to runtime.
const MAP_PATH := "res://data/maps/chapter_six_maps.json"
const SELF := "res://scripts/world_actions/chapter_six_world_actions.gd"
const LIMIT := 4096
const H := "char_liang_xiao"
const A := "char_axue"
const IDS := ["borrowed_body_recovery","sword_reclaimed_ch06","old_home_three_objects_verified","home_roof_repaired","home_bucket_made","bamboo_gathered_verified","axue_hearth_verified","r03_soak_verified","l02_borrowed_materials_verified"]
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
static func _canonical(value: Variant) -> Variant:
	if value is float and is_finite(value) and value==floor(value):return int(value)
	if value is Array:
		var result:Array=[]
		for item in value:result.append(_canonical(item))
		return result
	if value is Dictionary:
		var result:Dictionary={}
		for key in value:result[key]=_canonical(value[key])
		return result
	return value
static func _encoded(value: Variant) -> String:return JSON.stringify(_canonical(value))
func _p(value: Array) -> Vector2:return Vector2(value[0],value[1])
func _a(value: Vector2) -> Array:return [int(value.x),int(value.y)]
func _anchor(id: String) -> Array:return layout.anchors[id]
func _hash_state() -> String:return _encoded(state).sha256_text()
func begin(id: String,attempt: String="",trusted_context: Dictionary={}) -> bool:
	var candidate=load(SELF).new()
	if not candidate._begin_internal(id,attempt,trusted_context):return false
	for field in ["puzzle_id","attempt_id","scene_id","map_id","context","layout","config","state","input_log","engine_event_log","frozen_hash","initial_hash","message"]:
		var value:Variant=candidate.get(field)
		set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
	return true
static func _valid_point(value: Variant,map: Dictionary) -> bool:
	if not value is Array or value.size()!=2:return false
	for number in value:
		if not number is int and not number is float:return false
		if not is_finite(float(number)) or fmod(float(number),16)!=0:return false
	var p:=Vector2(value[0],value[1]);var b:Array=map.walk_bounds
	if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]:return false
	for r in map.solids+map.get("deep_water_rects",[]):
		if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(p):return false
	return true
func _valid_spatial(prior: Dictionary,maps: Dictionary) -> bool:
	if prior.is_empty():return true
	if not prior.get("map_id") is String or not maps.has(prior.map_id):return false
	var source:Dictionary=maps[prior.map_id];var ids:Array=[]
	for actor in source.actors:ids.append(actor.id)
	if prior.has("player_position") and not _valid_point(prior.player_position,source):return false
	if prior.has("control_actor_id") and prior.control_actor_id not in ids:return false
	if not prior.get("actor_positions",{}) is Dictionary or not prior.get("actor_postures",{}) is Dictionary:return false
	for actor in prior.get("actor_positions",{}):
		if actor not in ids or not _valid_point(prior.actor_positions[actor],source):return false
	for actor in prior.get("actor_postures",{}):
		if actor not in ids or prior.actor_postures[actor] not in ["resting","working","reading","standing"]:return false
	if not prior.get("local_objects",{}) is Dictionary:return false
	for object in prior.get("local_objects",{}):
		if not source.anchors.has(object) or not prior.local_objects[object] is String:return false
	if prior.has("control_actor_id") and prior.get("actor_positions",{}).has(prior.control_actor_id) and prior.has("player_position"):
		if _encoded(prior.actor_positions[prior.control_actor_id])!=_encoded(prior.player_position):return false
	return true
func _begin_internal(id: String,attempt: String,trusted_context: Dictionary) -> bool:
	if id not in IDS:return false
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not data is Dictionary:return false
	for mid in data.maps:
		if data.maps[mid].sessions.has(id):map_id=mid;layout=data.maps[mid];config=layout.sessions[id];break
	if layout.is_empty():return false
	puzzle_id=id;attempt_id=attempt;context=trusted_context.duplicate(true)
	for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",config.control_actor_id]]:
		if context.has(pair[0]) and context[pair[0]]!=pair[1]:return false
	for field in ["world_objects","items","actors"]:
		if not context.get(field,{}) is Dictionary:return false
	var prior:Variant=context.get("world_objects",{}).get("ch06_spatial_state",{})
	if not prior is Dictionary or not _valid_spatial(prior,data.maps):return false
	var items:Dictionary=context.get("items",{})
	if id=="sword_reclaimed_ch06":
		var sword:Variant=items.get("item_ch01_xuanyuan_sword",{})
		if not sword is Dictionary or sword.get("owner")!="ch06_plum_rock" or sword.get("state")!="lodged":return false
	if id=="borrowed_body_recovery":
		var pages:Variant=items.get("item_ch05_twelve_rubbings",{})
		if not pages is Dictionary or pages.get("owner")!=A or pages.get("state","")=="destroyed":return false
	if id=="r03_soak_verified":
		var strips:Variant=items.get("item_ch06_fine_strips",{})
		if not strips is Dictionary or strips.get("quantity",0)!=1 or strips.get("state","") in ["consumed","destroyed"]:return false
	scene_id=str(context.get("scene_id","ch06_"+id));frozen_hash=_encoded(layout).sha256_text()
	_reset();initial_hash=_hash_state();return true
func _reset() -> void:
	state={"position":_anchor(config.entry_anchor).duplicate(),"map_id":map_id,"control_actor_id":config.control_actor_id,"stage":0,"tick":0,"complete":false,"actor_positions":{},"actor_postures":{},"visited":[],"local_objects":{},"helper_active":false,"material_taken":false,"tool_taken":false,"rubbings_open":false,"breath_observations":0,"sword_observed":false,"sword_gripped":false,"sword_found":false}
	for actor in layout.actors:state.actor_positions[actor.id]=actor.position.duplicate()
	state.actor_positions[config.control_actor_id]=state.position.duplicate()
	var prior:Dictionary=context.get("world_objects",{}).get("ch06_spatial_state",{})
	if prior.get("map_id","")==map_id:
		state.local_objects=prior.get("local_objects",{}).duplicate(true)
		for actor in prior.get("actor_positions",{}):state.actor_positions[actor]=prior.actor_positions[actor].duplicate()
		if prior.get("actor_positions",{}).has(config.control_actor_id):state.position=prior.actor_positions[config.control_actor_id].duplicate()
		elif prior.get("control_actor_id","")==config.control_actor_id and prior.has("player_position"):state.position=prior.player_position.duplicate()
		state.actor_positions[config.control_actor_id]=state.position.duplicate()
	if puzzle_id=="borrowed_body_recovery":state.actor_postures[H]="resting"
	message="沿脚点走近标记，按 E 操作；R 从本段可信起点重试。"
func is_walkable(p: Vector2) -> bool:return _valid_point(_a(p),layout)
func _event(kind: String) -> void:engine_event_log.append({"type":kind,"tick":state.tick,"position":state.position.duplicate()})
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
func _tick() -> void:
	state.tick+=1;state.actor_positions[config.control_actor_id]=state.position.duplicate()
	if state.helper_active:
		state.actor_positions[A]=_a(_path_step(_p(state.actor_positions[A]),_p(_anchor(config.helper_anchor))))
		if _p(state.actor_positions[A])==_p(_anchor(config.helper_anchor)):state.actor_postures[A]="working"
func _step_index() -> int:
	if config.get("free_order",false):
		for i in range(config.steps.size()):
			if config.steps[i].anchor not in state.visited:return i
	return mini(int(state.stage),config.steps.size()-1)
func _next_anchor() -> String:return config.steps[_step_index()].anchor
func apply_input(action: Dictionary) -> Dictionary:
	var type:Variant=action.get("type")
	if puzzle_id.is_empty() or not type is String or type not in ["move","interact","inspect","wait","retry"]:return {"ok":false}
	for key in action:
		if key not in (["type","dx","dy"] if type=="move" else ["type"]):return {"ok":false}
	if type=="move":
		for key in ["dx","dy"]:
			if not action.get(key) is int and not action.get(key) is float:return {"ok":false}
		var dx:=float(action.dx);var dy:=float(action.dy)
		if not is_finite(dx) or not is_finite(dy) or dx!=floor(dx) or dy!=floor(dy) or absf(dx)+absf(dy)!=1:return {"ok":false}
	if input_log.size()>=LIMIT:
		if type!="retry":return {"ok":false,"message":"本段记录已满，R 仍可重新开始。"}
		begin(puzzle_id,attempt_id,context)
	input_log.append(action.duplicate(true));var ok:=_operate(action)
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt()}
func _operate(action: Dictionary) -> bool:
	if action.type=="retry":_reset();_event("retry");return true
	if state.complete:return false
	if action.type=="move":
		var next:=_p(state.position)+Vector2(action.dx,action.dy)*16
		if not is_walkable(next):message="墙、深水或工料阻路。";return false
		state.position=_a(next);_tick();_event("walk");return true
	if action.type=="wait":_tick();_event("wait");message="等候一相，让同伴走到实际工位。";return true
	if action.type=="inspect":message="请走近脚点标记再按 E；各工序需实际完成。";return true
	var index:=_step_index()
	if config.get("free_order",false):
		index=-1
		for i in range(config.steps.size()):
			if config.steps[i].anchor not in state.visited and _p(state.position).distance_to(_p(_anchor(config.steps[i].anchor)))<=8:index=i;break
		if index<0:message="走到尚未调查的旧物脚点再看。";return false
	var step:Dictionary=config.steps[index]
	if _p(state.position).distance_to(_p(_anchor(step.anchor)))>8:message="尚未走到实际操作点。";return false
	if step.verb in ["patch_roof","seal_bucket"]:
		if not state.material_taken or not state.tool_taken or _p(state.actor_positions[A]).distance_to(_p(_anchor(config.helper_anchor)))>8:message="阿雪尚未走到收拾床铺的位置；等候或行走让她实际到场。";return false
	match step.verb:
		"take_material":state.material_taken=true
		"take_plane":state.tool_taken=true
		"shape_material":state.helper_active=true
		"take_rubbings":state.rubbings_open=true
		"read_first","read_second":state.actor_postures[A]="reading"
		"observe_breath":state.breath_observations+=1
		"observe_sword":state.sword_observed=true
		"grip_sword":
			if not state.sword_observed:return false
			state.sword_gripped=true
		"pull_sword":
			if not state.sword_gripped:return false
			state.sword_found=true
	state.local_objects[step.anchor]=step.verb
	state.visited.append(step.anchor);state.stage+=1;_tick();_event(step.verb);message=step.feedback
	if state.stage==config.steps.size():state.complete=true;_event("objective_complete");message+=" 本段已完成。"
	return true
func _world_state() -> Dictionary:
	var result:=state.duplicate(true);result.erase("position");result.player_position=state.position.duplicate();result.objective_id=puzzle_id
	result.target_anchor=_next_anchor();result.target_position=_anchor(result.target_anchor).duplicate();result.visible_actor_ids=config.visible_actor_ids.duplicate()
	if puzzle_id=="l02_borrowed_materials_verified":result.visible_actor_ids.append("npc_sishen")
	for id in result.actor_positions.keys():
		if id not in result.visible_actor_ids:result.actor_positions.erase(id)
	return result
func get_view() -> Dictionary:
	var label:String=layout.anchor_labels.get(_next_anchor(),"操作点")
	return {"puzzle_id":puzzle_id,"title":config.label,"body":"%s\n阶段 %d/%d　%s %s\n%s" % [config.label,mini(int(state.stage)+1,config.steps.size()),config.steps.size(),label,str(_anchor(_next_anchor())),message],"state":{"complete":state.complete,"stage":state.stage},"complete":state.complete,"paused_step_mode":true,"world_state":_world_state(),"options":[{"id":"interact","label":"E 操作","action":{"type":"interact"}},{"id":"wait","label":"等候一相","action":{"type":"wait"}},{"id":"retry","label":"重试本段","action":{"type":"retry"}}]}
func snapshot() -> Dictionary:return {"version":1,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"map_hash":frozen_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true),"events":engine_event_log.duplicate(true)}
func restore(saved: Dictionary,trusted_context: Dictionary={}) -> bool:
	var replay=load(SELF).new()
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
func get_receipts() -> Array:return [receipt()] if state.get("complete",false) else []
static func replay_receipt(proof: Dictionary,trusted_context: Dictionary={}) -> Dictionary:
	var replay=load(SELF).new()
	if not replay.begin(str(proof.get("puzzle_id","")),str(proof.get("attempt_id","")),trusted_context):return {}
	if not proof.get("inputs") is Array or proof.inputs.size()>LIMIT:return {}
	for action in proof.inputs:
		if not action is Dictionary:return {}
		replay.apply_input(action)
	var actual:Dictionary=replay.receipt()
	return actual if _encoded(actual)==_encoded(proof) else {}
