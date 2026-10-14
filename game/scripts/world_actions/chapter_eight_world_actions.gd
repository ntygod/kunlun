class_name ChapterEightWorldActions
extends RefCounted
## Authored development scenes. Inventory, recovery and rewards belong to runtime.
const MAP_PATH := "res://data/maps/chapter_eight_maps.json"
const SELF := "res://scripts/world_actions/chapter_eight_world_actions.gd"
const LIMIT := 4096
const H := "char_liang_xiao"
const A := "char_axue"
const IDS := ["route_ch08_hanshui","repair_ch08_ballista","rescue_ch08_l04"]
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
		if actor not in ids or prior.actor_postures[actor] not in ["resting","working","reading","standing","bound","wounded"]:return false
	if not prior.get("local_objects",{}) is Dictionary:return false
	for object in prior.get("local_objects",{}):
		if not source.anchors.has(object) or not prior.local_objects[object] is String:return false
	if prior.has("control_actor_id") and prior.get("actor_positions",{}).has(prior.control_actor_id) and prior.has("player_position"):
		if _encoded(prior.actor_positions[prior.control_actor_id])!=_encoded(prior.player_position):return false
	return true
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

func _begin_internal(id: String,attempt: String,trusted_context: Dictionary) -> bool:
	if id not in IDS or attempt.is_empty():return false
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not data is Dictionary:return false
	for mid in data.maps:
		if data.maps[mid].sessions.has(id):map_id=mid;layout=data.maps[mid];config=layout.sessions[id];break
	if layout.is_empty():return false
	puzzle_id=id;attempt_id=attempt;context=trusted_context.duplicate(true)
	if context.get("chapter")!=8 or not context.get("current_token") is String or context.current_token.is_empty():return false
	if not context.get("revision") is int and not context.get("revision") is float:return false
	if not is_finite(float(context.revision)) or float(context.revision)<1 or float(context.revision)!=floor(float(context.revision)):return false
	for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",H],["scene_id",config.scene_id],["phase",config.scene_id]]:
		if context.get(pair[0])!=pair[1]:return false
	for field in ["world_objects","items","actors","choices","inherited_choices"]:
		if not context.get(field,{}) is Dictionary:return false
	if not context.get("knowledge",[]) is Array:return false
	var prior:Variant=context.get("world_objects",{}).get("ch08_spatial_state",{})
	if not prior is Dictionary or not _valid_spatial(prior,data.maps):return false
	scene_id=config.scene_id;frozen_hash=_encoded({"layout":layout,"context":context}).sha256_text()
	_reset();initial_hash=_hash_state();return true

func _reset() -> void:
	state={"position":_anchor("entry").duplicate(),"map_id":map_id,"control_actor_id":H,"stage":0,"tick":0,"complete":false,"actor_positions":{},"actor_postures":{},"visited":[],"local_objects":{},"observed":[],"fitted":[],"method":"","supporting":false,"retreating":false,"carrying":"","rescued":[],"victim_paths":{},"sand":false,"fire_out":false,"stone_open":false,"pad_ready":false,"pad_assigned":false,"escorting":false,"sheltered":false,"talked":false,"looters":{}}
	for actor in layout.actors:state.actor_positions[actor.id]=actor.position.duplicate()
	for id in ["npc_ch08_looter_spear","npc_ch08_looter_sabre"]:state.looters[id]={"observed":false,"disarmed":false,"departed":false}
	message="方向键逐格走；走到金色脚点再操作。所有救援均是场景行动，不消耗或恢复真气。"

func is_walkable(p: Vector2) -> bool:
	if layout.has("walkable_cells"):
		for cell in layout.walkable_cells:
			if p==_p(cell):return true
		return false
	if not _valid_point(_a(p),layout):return false
	if puzzle_id=="rescue_ch08_l04":
		# The beam fall zone is a real obstruction. The parallel passage is only opened by either approved method.
		if p==Vector2(176,192):return false
		if p.x>=208 and p.x<=240 and p.y<=192 and not state.supporting and not (state.fire_out and state.stone_open):return false
	return true

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

func _event(kind: String, detail: String="") -> void:
	engine_event_log.append({"type":kind,"detail":detail,"tick":state.tick,"position":state.position.duplicate()})
func _near(anchor: String) -> bool:return _p(state.position)==_p(_anchor(anchor))
func _victim_id(which: String) -> String:return "npc_ch08_l04_"+which
func _place_actor(id: String, p: Vector2) -> void:
	state.actor_positions[id]=_a(p)
	if state.victim_paths.has(id):state.victim_paths[id].append(_a(p))
func _switch(id: String) -> void:
	state.actor_positions[state.control_actor_id]=state.position.duplicate()
	state.control_actor_id=id;state.position=state.actor_positions[id].duplicate()
func _drop_safe() -> void:
	if state.carrying!="" and _near("safe"):
		if state.carrying not in state.rescued:state.rescued.append(state.carrying);_event("victim_reached_safe",state.carrying)
		state.carrying=""
func _tick() -> void:
	state.tick+=1;state.actor_positions[state.control_actor_id]=state.position.duplicate()
	if puzzle_id!="rescue_ch08_l04":return
	if state.retreating:
		var next:=_path_step(_p(state.position),_p(_anchor("safe")))
		state.position=_a(next);state.actor_positions[A]=state.position.duplicate()
		_event("safe_withdrawal_step")
	if state.carrying!="":_place_actor(state.carrying,_p(state.position));_drop_safe()
	if state.retreating and _near("safe"):
		state.retreating=false;state.supporting=false;_switch(H);_event("support_paused")
	if state.pad_assigned and not state.pad_ready:
		var next:=_path_step(_p(state.actor_positions[A]),_p(_anchor("safe")))
		state.actor_positions[A]=_a(next)
		if next==_p(_anchor("safe")):state.pad_ready=true;_event("snow_pad_ready")
	for id in state.looters:
		var soldier:Dictionary=state.looters[id]
		if soldier.disarmed and not soldier.departed:
			var target:=_p(_anchor("spear_exit" if id.ends_with("spear") else "sabre_exit"))
			_place_actor(id,_path_step(_p(state.actor_positions[id]),target))
			if _p(state.actor_positions[id])==target:soldier.departed=true;_event("looter_left_scene",id)
	if state.escorting:
		for id in state.rescued:
			_place_actor(id,_path_step(_p(state.actor_positions[id]),_p(_anchor("shelter")) if _near("shelter") else _p(state.position)))

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not action.get("type") is String:return {"ok":false}
	var type:String=action.type
	var fields:Dictionary={"move":["type","dx","dy"],"interact":["type"],"wait":["type"],"inspect":["type"],"retry":["type"],"method":["type","value"],"fit":["type","part"],"support":["type"],"cancel_support":["type"],"sand":["type"],"extinguish":["type"],"open_stone":["type"],"pad":["type"],"disarm":["type","move"],"escort":["type"],"shelter":["type"],"talk":["type"],"finish":["type"]}
	if not fields.has(type):return {"ok":false}
	for key in action:
		if key not in fields[type]:return {"ok":false}
	for field in fields[type]:
		if not action.has(field):return {"ok":false}
	if type=="move":
		for key in ["dx","dy"]:
			if not action[key] is int and not action[key] is float:return {"ok":false}
		var dx:=float(action.dx);var dy:=float(action.dy)
		if not is_finite(dx) or not is_finite(dy) or dx!=floor(dx) or dy!=floor(dy) or absf(dx)+absf(dy)!=1:return {"ok":false}
	if type in ["method","fit","disarm"] and not action[fields[type][1]] is String:return {"ok":false}
	if input_log.size()>=LIMIT:return {"ok":false,"message":"本段记录达到上限，请读入此前存档。"}
	input_log.append(action.duplicate(true))
	var ok:=_operate(action)
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt()}

func _operate(action: Dictionary) -> bool:
	if action.type=="retry":_reset();_event("retry");return true
	if state.complete:return false
	if state.retreating:
		if action.type!="wait":message="雪正沿安全路线退出；按等候逐格退回后才可松梁。";return false
		_tick();return true
	if action.type=="move":
		var next:=_p(state.position)+Vector2(action.dx,action.dy)*16
		if not is_walkable(next):message="水面、断梁或尚未清开的危险通道阻路。";return false
		state.position=_a(next);_tick();_event("walk");return true
	if action.type=="wait":_tick();_event("wait");return true
	if action.type=="inspect":message=_instructions();return true
	if puzzle_id=="route_ch08_hanshui":return _route(action)
	if puzzle_id=="repair_ch08_ballista":return _repair(action)
	return _rescue(action)

func _route(action: Dictionary) -> bool:
	if action.type!="interact":return false
	var step:Dictionary=config.steps[mini(int(state.stage),3)]
	if not _near(step.anchor):message="沿连接的舟板走到下一金色脚点；深水不可通行。";return false
	state.visited.append(step.anchor);state.stage+=1;_tick();_event(step.verb)
	if state.stage==4:state.complete=true;_event("platform_reached")
	message="已踏稳舟板。";return true

func _repair(action: Dictionary) -> bool:
	var parts:Dictionary={"rivet":"square","groove":"long","wheel":"round"}
	for anchor in parts:
		if not _near(anchor):continue
		if action.type=="interact":
			if anchor not in state.observed:state.observed.append(anchor);_event("inspect_broken_part",anchor)
			message=layout.anchor_labels[anchor]+"，请选形状相合的备件。";return true
		if action.type=="fit":
			if anchor not in state.observed or action.part!=parts[anchor] or anchor in state.fitted:message="先看清形状，再装对应备件；已装好的不可重复。";return false
			state.fitted.append(anchor);_tick();_event("fit_part",anchor);message="备件已固定。";return true
	if action.type=="interact" and _near("winch") and state.fitted.size()==3:
		_tick();_event("winch_test");state.complete=true;message="三件联动，试绞完成；发射方向仍由后续抉择决定。";return true
	message="走近三处损坏实体观察、装件，最后到绞盘试转。";return false

func _rescue(action: Dictionary) -> bool:
	if action.type=="interact":
		for anchor in ["beam","oil","passage"]:
			if _near(anchor) and anchor not in state.observed and state.control_actor_id==H:
				state.observed.append(anchor);_event("inspect_rescue_site",anchor);message=layout.anchor_labels[anchor]+"：已看清通道与危险。";return true
		for which in ["child","grandmother"]:
			var id:=_victim_id(which)
			if _near(which) and state.carrying=="" and id not in state.rescued:
				if not ((state.method=="A" and state.supporting and state.control_actor_id==A) or (state.method=="B" and state.fire_out and state.stone_open and state.pad_ready)):return false
				state.carrying=id;state.victim_paths[id]=[state.position.duplicate()];_event("take_victim",id);message="沿原路送到西侧接应安全点。";return true
		for id in state.looters:
			if _near("spear_intercept" if id.ends_with("spear") else "sabre_intercept") and state.rescued.size()==2 and state.control_actor_id==H:
				if state.looters[id].disarmed:return false
				state.looters[id].observed=true;_event("observe_looter",id)
				message="枪柄伸向祖孙：以引偏枪柄卸力。" if id.ends_with("spear") else "刀背压向窝棚口：以卸落刀背解围。"
				return true
	if action.type=="method":
		if state.observed.size()!=3 or state.method!="" or action.value not in ["A","B"]:return false
		state.method=action.value;_event("choose_method",action.value);message="A：走到支点持续撑梁；雪沿通道双救。" if action.value=="A" else "B：取沙覆油、运劲开石；同时安排雪在安全口接应。";return true
	if action.type=="support":
		if state.method!="A" or state.control_actor_id!=H or not _near("beam") or state.rescued.size()==2:return false
		state.supporting=true;_switch(A);_event("support_locked");message="梁已锁在支点。现在控制雪；可取消并逐格退回安全点。";return true
	if action.type=="cancel_support":
		if not state.supporting:return false
		state.retreating=true;_event("withdrawal_requested");message="保持撑梁直到雪逐格退出，按等候继续。";return true
	if action.type=="pad":
		if state.method!="B" or state.pad_assigned:return false
		state.pad_assigned=true;_tick();_event("assign_snow_pad");return true
	if action.type=="sand":
		if state.method!="B" or not _near("sand") or state.fire_out:return false
		state.sand=true;_tick();_event("take_scene_sand");return true
	if action.type=="extinguish":
		if state.method!="B" or not _near("oil") or not state.sand or state.fire_out:return false
		state.sand=false;state.fire_out=true;state.local_objects["oil"]="extinguished";_tick();_event("oil_extinguished");return true
	if action.type=="open_stone":
		if state.method!="B" or not _near("passage") or not state.fire_out or state.stone_open:return false
		state.stone_open=true;state.local_objects["rock"]="opened";_tick();_event("stone_opened_no_mp");return true
	if action.type=="disarm":
		if state.control_actor_id!=H or state.rescued.size()!=2:return false
		for id in state.looters:
			var spear:bool=id.ends_with("spear")
			if not _near("spear_intercept" if spear else "sabre_intercept"):continue
			if not state.looters[id].observed or state.looters[id].disarmed:return false
			if action.move!=("redirect_spear" if spear else "lower_sabre"):message="角度不合；观察公开兵器动作后再选。祖孙仍在雪身后。";return false
			state.looters[id].disarmed=true;_tick();_event("nonlethal_disarm",id);message="兵刃落地；需看着此人沿巷口退离。";return true
	if action.type=="escort":
		if state.rescued.size()!=2 or state.control_actor_id!=H or not _near("safe") or not _all_departed() or state.escorting:return false
		state.escorting=true;_tick();_event("escort_to_shelter");message="沿巷道走向枯井窝棚；祖孙逐格跟随，可等候他们靠近。";return true
	if action.type=="shelter":
		if not _at_shelter() or state.sheltered:return false
		state.sheltered=true;_tick();_event("shelter_covered");message="窝棚遮妥，听老妪说完。";return true
	if action.type=="talk":
		if not state.sheltered or not _at_shelter():return false
		state.talked=true;_event("grandmother_dialogue");message="老妪：孩子还在，我便还能走。愿你日后动手前，也想想屋檐下的人。";return true
	if action.type=="finish":
		if not state.talked or not _at_shelter() or not _all_departed():return false
		state.complete=true;_event("rescue_archived");message="祖孙在窝棚安顿，两个败兵已实际离场。";return true
	message="请先到对应脚点，按公开顺序操作。";return false
func _all_departed() -> bool:
	for soldier in state.looters.values():
		if not soldier.departed:return false
	return true
func _at_shelter() -> bool:
	if not state.escorting or not _near("shelter"):return false
	for id in state.rescued:
		if _p(state.actor_positions[id])!=_p(_anchor("shelter")):return false
	return state.rescued.size()==2
func _target_anchor() -> String:
	if puzzle_id=="route_ch08_hanshui":return config.steps[mini(int(state.stage),3)].anchor
	if puzzle_id=="repair_ch08_ballista":
		for anchor in ["rivet","groove","wheel"]:
			if anchor not in state.fitted:return anchor
		return "winch"
	for anchor in ["beam","oil","passage"]:
		if anchor not in state.observed:return anchor
	if state.method=="":return "beam"
	if state.retreating:return "safe"
	if state.method=="A" and not state.supporting and state.rescued.size()<2:return "beam"
	if state.method=="B":
		if not state.fire_out:return "oil" if state.sand else "sand"
		if not state.stone_open:return "passage"
	if state.carrying!="":return "safe"
	if state.rescued.size()<2:return "child" if _victim_id("child") not in state.rescued else "grandmother"
	if state.supporting:return "safe"
	for id in state.looters:
		if not state.looters[id].departed:return "spear_intercept" if id.ends_with("spear") else "sabre_intercept"
	return "shelter" if state.escorting else "safe"
func _instructions() -> String:
	if puzzle_id=="route_ch08_hanshui":return "沿连舟依次踏稳三块舟板，再登高台。浅金线是连续脚路，蓝色为不可走深水。"
	if puzzle_id=="repair_ch08_ballista":return "三处先观察再装件：方榫配断铆、长槽配焦槽、圆轴配偏轮。三件齐才试绞；只修此床弩，不生成弩矢。"
	if state.retreating:return "雪逐格退出中：只按等候；到安全点才解除撑梁。"
	if state.observed.size()<3:return "先走近斜梁、燃油锅、祖孙通道，各观察一次。金色脚点可操作；红叉断梁不能走。"
	if state.method=="":return "A：撑梁锁位，雪双救。B：泥沙灭火、运劲开石，雪同时接应。两法均不改变HP/MP。"
	if state.rescued.size()<2:return "先救幼童或老妪，带回西侧安全点后再救另一人。撑梁时控制雪；灭火法先派雪铺垫。"
	if state.supporting:return "双救已至安全点。取消撑梁，等候雪安全退出，再由梁拦截败兵。"
	if not _all_departed():return "各到败兵邻格观察：枪柄→引偏枪柄，刀背→卸落刀背。兵器落地后等他们走到出口。"
	if not state.escorting:return "两兵均已退离，回到安全点引祖孙去东侧枯井窝棚。"
	return "走到窝棚，等祖孙各自走到；遮棚、听老妪说完，最后归档。"
func _option(label: String, action: Dictionary) -> Dictionary:return {"id":label,"label":label,"action":action}
func _world_state() -> Dictionary:
	var result:=state.duplicate(true);result.erase("position")
	result.player_position=state.position.duplicate();result.objective_id=puzzle_id
	result.target_anchor=_target_anchor();result.target_position=_anchor(result.target_anchor).duplicate()
	result.visible_actor_ids=config.visible_actor_ids.duplicate()
	for id in state.looters:
		if state.looters[id].departed:result.visible_actor_ids.erase(id)
	result.story_injury=state.method=="A" and state.rescued.size()==2
	result.neighbor_huts_protected=state.fire_out
	return result
func get_view() -> Dictionary:
	var options:Array=[]
	options.append(_option("E 观察／抱扶／踏稳",{"type":"interact"}))
	if puzzle_id=="repair_ch08_ballista":
		for part in [["方榫","square"],["长槽","long"],["圆轴","round"]]:options.append(_option("装"+part[0],{"type":"fit","part":part[1]}))
	if puzzle_id=="rescue_ch08_l04":
		if state.retreating:options=[]
		elif state.observed.size()==3 and state.method=="":
			options.append(_option("A 身体作桩",{"type":"method","value":"A"}));options.append(_option("B 灭火疏石",{"type":"method","value":"B"}))
		elif state.method=="A":options.append(_option("取消撑梁／安全退出" if state.supporting else "持续撑梁",{"type":"cancel_support" if state.supporting else "support"}))
		elif state.method=="B":
			if not state.pad_assigned:options.append(_option("雪到安全口铺垫",{"type":"pad"}))
			if not state.fire_out:options.append(_option("覆沙灭油火" if state.sand else "取泥沙桶",{"type":"extinguish" if state.sand else "sand"}))
			elif not state.stone_open:options.append(_option("运劲开石 · 0MP",{"type":"open_stone"}))
		if state.rescued.size()==2 and not state.supporting and not state.retreating:
			if not _all_departed():
				options.append(_option("引偏枪柄",{"type":"disarm","move":"redirect_spear"}));options.append(_option("卸落刀背",{"type":"disarm","move":"lower_sabre"}))
			elif not state.escorting:options.append(_option("引祖孙去窝棚",{"type":"escort"}))
			elif not state.sheltered:options.append(_option("遮好窝棚",{"type":"shelter"}))
			elif not state.talked:options.append(_option("听老妪说完",{"type":"talk"}))
			else:options.append(_option("安顿归档",{"type":"finish"}))
	options.append(_option("等候一拍",{"type":"wait"}))
	var target:=_target_anchor()
	return {"puzzle_id":puzzle_id,"title":config.label+" · "+layout.anchor_labels[target],"body":"%s\n下一脚点：%s %s\n%s"%[_instructions(),layout.anchor_labels[target],str(_anchor(target)),message],"state":state.duplicate(true),"complete":state.complete,"paused_step_mode":true,"world_state":_world_state(),"options":options}
