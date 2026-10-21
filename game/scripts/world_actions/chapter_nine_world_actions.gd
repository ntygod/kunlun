class_name ChapterNineWorldActions
extends RefCounted
## Authored development scenes. Inventory, recovery and rewards belong to runtime.
const MAP_PATH := "res://data/maps/chapter_nine_maps.json"
const SELF := "res://scripts/world_actions/chapter_nine_world_actions.gd"
const LIMIT := 4096
const H := "char_liang_xiao"
const A := "char_axue"
const IDS := ["scene_ch09_three_masters","scene_ch09_four_instruments","rescue_ch09_l05"]
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
static func _normalize_text(value: Variant) -> Variant:
	if value is StringName:return String(value)
	if value is Array:
		var result:Array=[]
		for item in value:result.append(_normalize_text(item))
		return result
	if value is Dictionary:
		var result:Dictionary={}
		for key in value:result[String(key) if key is StringName else key]=_normalize_text(value[key])
		return result
	return value
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
	if not candidate._begin_internal(id,attempt,_normalize_text(trusted_context)):return false
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
	saved=_normalize_text(saved);trusted_context=_normalize_text(trusted_context)
	var replay=load(SELF).new()
	if not replay.begin(str(saved.get("puzzle_id","")),str(saved.get("attempt_id","")),trusted_context):return false
	if not saved.get("input_log") is Array or saved.input_log.size()>LIMIT:return false
	for action in saved.input_log:
		if not action is Dictionary:return false
		if not replay.apply_input(action).get("ok",false):return false
	if _encoded(replay.snapshot())!=_encoded(saved):return false
	begin(replay.puzzle_id,replay.attempt_id,trusted_context)
	for action in saved.input_log:apply_input(action)
	return true
func receipt() -> Dictionary:
	if not state.get("complete",false):return {}
	return {"version":1,"puzzle_id":puzzle_id,"objective_id":puzzle_id,"attempt_id":attempt_id,"scene_id":scene_id,"map_id":map_id,"map_hash":frozen_hash,"before_state_hash":initial_hash,"after_state_hash":_hash_state(),"inputs":input_log.duplicate(true),"engine_events":engine_event_log.duplicate(true),"world_state":_world_state()}
func get_receipts() -> Array:return [receipt()] if state.get("complete",false) else []
static func replay_receipt(proof: Dictionary,trusted_context: Dictionary={}) -> Dictionary:
	proof=_normalize_text(proof);trusted_context=_normalize_text(trusted_context)
	var replay=load(SELF).new()
	if not replay.begin(str(proof.get("puzzle_id","")),str(proof.get("attempt_id","")),trusted_context):return {}
	if not proof.get("inputs") is Array or proof.inputs.size()>LIMIT:return {}
	for action in proof.inputs:
		if not action is Dictionary:return {}
		if not replay.apply_input(action).get("ok",false):return {}
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
	if not context.get("chapter") is int and not context.get("chapter") is float:return false
	if context.chapter!=9 or not context.get("current_token") is String or context.current_token.is_empty():return false
	if not context.get("revision") is int and not context.get("revision") is float:return false
	if not is_finite(float(context.revision)) or float(context.revision)<1 or float(context.revision)!=floor(float(context.revision)):return false
	for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",H],["scene_id",config.scene_id],["phase",config.scene_id]]:
		if not context.get(pair[0]) is String or context[pair[0]]!=pair[1]:return false
	for field in ["world_objects","items","actors","choices","inherited_choices"]:
		if not context.get(field,{}) is Dictionary:return false
	if not context.get("knowledge",[]) is Array:return false
	var prior:Variant=context.get("world_objects",{}).get("ch09_spatial_state",{})
	if not prior is Dictionary or not _valid_spatial(prior,data.maps):return false
	scene_id=config.scene_id;frozen_hash=_encoded({"layout":layout,"context":context}).sha256_text()
	_reset();initial_hash=_hash_state();return true

func _reset() -> void:
	state={"position":_anchor("entry").duplicate(),"map_id":map_id,"control_actor_id":H,"stage":0,"tick":0,"complete":false,"actor_positions":{},"actor_postures":{},"visited":[],"local_objects":{},"accepted":false,"inspected":false,"lock_slots":["fruit","fruit","fruit"],"unlocked":false,"method":"","questioned":false,"found_physician":false,"escorting":false,"returned_box":false,"sorted":[],"decoys":false,"patrol_lured":false,"patrol_departed":false,"distributed":false,"treated":false,"talked":false,"looters":{},"actor_paths":{},"stage_receipts":[]}
	for actor in layout.actors:
		state.actor_positions[actor.id]=actor.position.duplicate();state.actor_paths[actor.id]=[actor.position.duplicate()]
	state.actor_positions[H]=state.position.duplicate();state.actor_paths[H]=[state.position.duplicate()]
	if puzzle_id=="rescue_ch09_l05":
		for i in range(1,4):state.looters["npc_ch09_raider_%d"%i]={"observed":false,"disarmed":false,"departed":false,"index":i}
	message="方向键逐格走；到金色脚点再操作。场景行动不改变HP、MP或物品账。"

func is_walkable(p: Vector2) -> bool:
	return _valid_point(_a(p),layout)
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
func _event(kind: String,detail: String="") -> void:
	engine_event_log.append({"type":kind,"detail":detail,"tick":state.tick,"position":state.position.duplicate()})
	if (kind.begins_with("side_ch09_") or kind=="choice_ch09_l05_method") and kind not in state.stage_receipts:state.stage_receipts.append(kind)
func _near(anchor: String) -> bool:return _p(state.position)==_p(_anchor(anchor))
func _place_actor(id: String,p: Vector2) -> void:
	state.actor_positions[id]=_a(p)
	if state.actor_paths.has(id) and state.actor_paths[id][-1]!=_a(p):state.actor_paths[id].append(_a(p))
func _switch(id: String) -> void:
	_place_actor(state.control_actor_id,_p(state.position))
	state.control_actor_id=id;state.position=state.actor_positions[id].duplicate()
func _tick() -> void:
	state.tick+=1;_place_actor(state.control_actor_id,_p(state.position))
	if puzzle_id!="rescue_ch09_l05":return
	if state.escorting and not state.returned_box:
		var target:=_p(_anchor("doctor_station")) if _near("box") else _p(state.position)
		_place_actor("npc_ch09_physician",_path_step(_p(state.actor_positions.npc_ch09_physician),target))
	if state.patrol_lured and not state.patrol_departed:
		_place_actor("npc_ch09_patrol",_path_step(_p(state.actor_positions.npc_ch09_patrol),_p(_anchor("patrol_exit"))))
		if _p(state.actor_positions.npc_ch09_patrol)==_p(_anchor("patrol_exit")):state.patrol_departed=true;_event("patrol_left_scene")
	for id in state.looters:
		var raider:Dictionary=state.looters[id]
		if raider.disarmed and not raider.departed:
			var target:=_p(_anchor("raider_%d_exit"%raider.index))
			_place_actor(id,_path_step(_p(state.actor_positions[id]),target))
			if _p(state.actor_positions[id])==target:
				raider.departed=true;_event("raider_left_scene",id)
	if _all_departed() and "side_ch09_l05_disarm_raiders" not in state.stage_receipts:_event("side_ch09_l05_disarm_raiders")

func _wait_advances() -> bool:
	# No danger/phase clock exists in these scene sessions: tick is presentation only.
	# Moving escorts, patrols and raiders are real state changes and MUST remain recorded.
	if puzzle_id!="rescue_ch09_l05":return false
	if state.escorting and not state.returned_box:
		var target:=_p(_anchor("doctor_station")) if _near("box") else _p(state.position)
		if _p(state.actor_positions.npc_ch09_physician)!=target:return true
	if state.patrol_lured and not state.patrol_departed:return true
	for raider in state.looters.values():
		if raider.disarmed and not raider.departed:return true
	return false

func apply_input(action: Dictionary) -> Dictionary:
	action=_normalize_text(action)
	if puzzle_id.is_empty() or not action.get("type") is String:return {"ok":false}
	var type:String=action.type
	var fields:Dictionary={"move":["type","dx","dy"],"interact":["type"],"wait":["type"],"inspect":["type"],"lock":["type","slot","symbol"],"unlock":["type"],"method":["type","value"],"switch":["type"],"escort":["type"],"return_box":["type"],"sort":["type","label"],"decoy":["type"],"lure":["type"],"distribute":["type"],"disarm":["type"],"treat":["type"],"talk":["type"],"finish":["type"]}
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
	if type in ["method","sort"] and not action[fields[type][1]] is String:return {"ok":false}
	if type=="lock":
		if not action.slot is int and not action.slot is float:return {"ok":false}
		if not is_finite(float(action.slot)) or float(action.slot)!=floor(float(action.slot)) or action.slot<0 or action.slot>2 or not action.symbol is String or action.symbol not in ["leaf","flower","fruit"]:return {"ok":false}
	if not state.complete:
		var no_effect:bool=type=="inspect" or (type=="wait" and not _wait_advances())
		if type=="lock" and state.inspected and not state.unlocked and _near("box") and state.lock_slots[int(action.slot)]==action.symbol:no_effect=true
		if no_effect:
			message=_instructions() if type=="inspect" else "当前无人移动，无需再等；可走向下一脚点，或暂停返回。" if type=="wait" else "这一槽已对齐，无需重复调整。"
			return {"ok":true,"no_op":true,"message":message,"view":get_view(),"receipt":receipt()}
	if input_log.size()>=LIMIT:return {"ok":false,"message":"本支线行动记录已满。可暂停返回主线，或读取此前的支线存档；不会撤销已经救回的人。"}
	var ok:=_operate(action)
	if ok:input_log.append(action.duplicate(true))
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt()}

func _operate(action: Dictionary) -> bool:
	if state.complete:return false
	if action.type=="inspect":message=_instructions();return true
	if action.type=="move":
		var next:=_p(state.position)+Vector2(action.dx,action.dy)*16
		if not is_walkable(next):message="石壁、柱脚或深水阻路；沿浅色地面绕行。";return false
		# Raiders physically occupy their feet until they walk away; no remote removal.
		for id in state.looters:
			if not state.looters[id].departed and _p(state.actor_positions[id])==next:message="流寇挡住这一步。先察刃，再绕柱到侧位卸刃。";return false
		state.position=_a(next);_tick();_event("walk");return true
	if action.type=="wait":_tick();_event("wait");return true
	if puzzle_id!="rescue_ch09_l05":return _interactive_scene(action)
	return _rescue(action)

func _interactive_scene(action: Dictionary) -> bool:
	if action.type!="interact":return false
	var step:Dictionary=config.steps[int(state.stage)]
	if not _near(step.anchor):message="走到下一金色脚点，观察来势再行动。";return false
	state.visited.append(step.anchor);state.stage+=1;_tick();_event(step.verb)
	if state.stage==config.steps.size():state.complete=true;_event("interactive_scene_complete")
	message=step.feedback;return true

func _rescue(action: Dictionary) -> bool:
	if action.type=="interact":
		if not state.accepted and _near("entry"):
			state.accepted=true;_event("side_ch09_l05_accept");message="小喜子求援：医箱与本草属于师父，请先看青杏纹和箱签。";return true
		if state.accepted and not state.inspected and _near("box"):
			state.inspected=true;_event("side_ch09_l05_inspect_box");message="青杏纹旁公开刻着：左叶、中花、右果。箱内24格药与半卷本草仍归医者。";return true
		if state.method=="A" and not state.questioned and _near("wounded"):
			state.questioned=true;_event("side_ch09_l05_question_wounded");message="轻伤兵指向东侧城隍枯井，张郎中还在那里。";return true
		if state.method=="A" and state.questioned and not state.found_physician and _near("physician"):
			state.found_physician=true;_event("side_ch09_l05_find_physician");message="已在枯井旁找到张郎中。扶他沿实路回庙，不会瞬移。";return true
		if state.method!="" and state.control_actor_id==H:
			for id in state.looters:
				var r:Dictionary=state.looters[id]
				if _near("raider_%d_observe"%r.index) and not r.observed and not r.disarmed:
					r.observed=true;_event("observe_raider",id);message="流寇横刃挡着医箱通路。绕柱到右侧金色脚点，借柱卸刃。";return true
		return false
	if action.type=="lock":
		if not state.inspected or state.unlocked or not _near("box"):return false
		state.lock_slots[int(action.slot)]=action.symbol;_event("align_lock_slot",str(int(action.slot))+":"+action.symbol);message="铜锁公开箱签：左叶、中花、右果。三槽齐后按开锁。";return true
	if action.type=="unlock":
		if not state.inspected or state.unlocked or not _near("box"):return false
		if state.lock_slots!=["leaf","flower","fruit"]:message="刻槽尚未与公开箱签相合；错误不耗物。";return false
		state.unlocked=true;_event("side_ch09_l05_unlock_box");message="锁已开。药箱仍留医者手里，选寻医或协作分药。";return true
	if action.type=="method":
		if not state.unlocked or state.method!="" or not _near("box") or action.value not in ["A","B"]:return false
		state.method=action.value;_event("choice_ch09_l05_method",action.value);message="先询西侧轻伤兵，再去枯井扶回郎中。" if action.value=="A" else "雪按药签分药，梁布疑阵引巡骑；小喜子代师发药，不会声称郎中已救回。";return true
	if action.type=="escort":
		if state.method!="A" or not state.found_physician or state.escorting or not _near("physician"):return false
		state.escorting=true;_event("physician_escort_started");message="张郎中逐格跟随，走到医箱前并等他到配药位。";return true
	if action.type=="return_box":
		if state.method!="A" or not state.escorting or state.returned_box or not _near("box") or _p(state.actor_positions.npc_ch09_physician)!=_p(_anchor("doctor_station")):return false
		state.returned_box=true;_event("side_ch09_l05_escort_physician");_event("side_ch09_l05_return_box");message="张郎中已真正回到破庙，接管医箱与半卷本草。";return true
	if action.type=="switch":
		if state.method!="B":return false
		_switch(A if state.control_actor_id==H else H);_event("switch_scene_actor",state.control_actor_id);message="现在控制阿雪。" if state.control_actor_id==A else "现在控制梁萧。";return true
	if action.type=="sort":
		if state.method!="B" or state.control_actor_id!=A or not _near("sort") or action.label not in ["leaf","flower","fruit"] or action.label in state.sorted:return false
		state.sorted.append(action.label);_tick();_event("sort_by_public_label",action.label)
		if state.sorted.size()==3:_event("side_ch09_l05_axue_sort_medicine")
		message="按箱上同名签分好这一组；不产生背包药品，也无HP药效。";return true
	if action.type=="decoy":
		if state.method!="B" or state.control_actor_id!=H or not _near("decoy") or state.decoys:return false
		state.decoys=true;_tick();_event("side_ch09_l05_place_decoys");message="疑阵设在去城外的路上，医箱留庙。去巡骑脚点引其绕行。";return true
	if action.type=="lure":
		if state.method!="B" or state.control_actor_id!=H or not state.decoys or not _near("patrol_lure") or state.patrol_lured:return false
		state.patrol_lured=true;_tick();_event("side_ch09_l05_lure_patrol");message="巡骑沿城外路逐格转离；可等候看其退到出口。";return true
	if action.type=="distribute":
		if state.method!="B" or state.sorted.size()!=3 or not state.patrol_departed or not _near("box") or state.control_actor_id!=H or state.distributed:return false
		state.distributed=true;_event("side_ch09_l05_xixizi_distribute");message="小喜子代师发药。张郎中仍未寻回，医箱、本草与药仍由医者一方保管。";return true
	if action.type=="disarm":
		if state.control_actor_id!=H or state.method=="":return false
		for id in state.looters:
			var r:Dictionary=state.looters[id]
			if _near("raider_%d_flank"%r.index) and r.observed and not r.disarmed:
				r.disarmed=true;_tick();_event("nonlethal_raider_disarm",id);message="借柱卸落兵刃；流寇沿门路逐格退出，尚未到出口不会消失。";return true
		message="先在该流寇正面察刃，再亲自绕柱到其侧面。";return false
	if action.type=="treat":
		if not _all_departed() or state.treated or not _near("box") or state.control_actor_id!=H or not ((state.method=="A" and state.returned_box) or (state.method=="B" and state.distributed)):return false
		state.treated=true;_event("side_ch09_l05_finish_treatment");message="郎中主持救治，医箱与本草归还其手。" if state.method=="A" else "小喜子按师传与公开药签完成发药；未声称已找回师父。";return true
	if action.type=="talk":
		if not state.treated or state.talked or not _near("aftermath"):return false
		state.talked=true;_event("side_ch09_l05_aftermath");message="医者把铜钥匙托付作寻药凭信。归档后仅解锁采药辨味探索提示，不提升战斗数值。";return true
	if action.type=="finish":
		if not state.talked or not _near("aftermath") or not _all_departed():return false
		state.complete=true;_event("side_ch09_l05_archive");message="此处救治已告一段落。钥匙、记事与一次支线奖励交由章节统一结算。";return true
	return false
func _all_departed() -> bool:
	if state.looters.size()!=3:return false
	for raider in state.looters.values():
		if not raider.departed:return false
	return true
func _target_anchor() -> String:
	if puzzle_id!="rescue_ch09_l05":return config.steps[mini(int(state.stage),config.steps.size()-1)].anchor
	if not state.accepted:return "entry"
	if not state.unlocked or state.method=="":return "box"
	if state.method=="A" and not state.returned_box:
		if not state.questioned:return "wounded"
		if not state.escorting:return "physician"
		return "box"
	if state.method=="B" and not state.distributed:
		if state.sorted.size()!=3:return "sort"
		if not state.decoys:return "decoy"
		if not state.patrol_lured or not state.patrol_departed:return "patrol_lure"
		return "box"
	for r in state.looters.values():
		if not r.departed:return "raider_%d_%s"%[r.index,"flank" if r.observed else "observe"]
	return "aftermath" if state.treated else "box"
func _instructions() -> String:
	if puzzle_id!="rescue_ch09_l05":return "互动过场：四向走到金色脚点，E观察／介入。只记录现场动作，不是Boss战，不扣气血、不杀死群强。"
	if not state.accepted:return "E答应小喜子，去医箱看青杏纹、24格药与半卷本草。可随时暂停返回，直到闯帐最终确认。"
	if not state.unlocked:return "公开铜锁：左叶／中花／右果。先E观察，再分别选三槽，按开锁。错配无成本；药箱不收入背包。"
	if state.method=="":return "A：询伤兵→枯井找到郎中→扶回破庙。B：雪按公开药签分药→梁疑阵引骑→小喜子代师。两法都须拦退三个流寇。"
	if state.method=="A" and not state.returned_box:return "询西侧轻伤兵，再到东侧枯井E找到郎中、扶起护送；沿连续道路回医箱，等郎中到配药位后还箱。"
	if state.method=="B" and not state.distributed:return "切换阿雪，走到分药位按叶／花／果同名药签分别归类；切回梁布疑阵、引巡骑实际退场，再回医箱请小喜子代师。"
	if not _all_departed():return "三个流寇各自挡路：到正面E察刃→绕柱到右侧金色点卸刃→等他沿门路退出。不能远程卸刃，不发战斗经验。"
	return "回医箱完成救治，再到余话脚点听完与归档。医箱、本草、24格药始终归医者；钥匙只用于探索。"
func _option(label: String,action: Dictionary) -> Dictionary:return {"id":label,"label":label,"action":action}
func _world_state() -> Dictionary:
	var result:=state.duplicate(true);result.erase("position");result.player_position=state.position.duplicate();result.objective_id=puzzle_id
	result.target_anchor=_target_anchor();result.target_position=_anchor(result.target_anchor).duplicate();result.visible_actor_ids=config.visible_actor_ids.duplicate()
	if puzzle_id=="rescue_ch09_l05":
		for id in state.looters:
			if state.looters[id].departed:result.visible_actor_ids.erase(id)
		if state.patrol_departed:result.visible_actor_ids.erase("npc_ch09_patrol")
		result.physician_rescued=state.returned_box
		result.medicine_owner="npc_ch09_physician" if state.method!="B" else "npc_ch09_xixizi"
	return result
func get_view() -> Dictionary:
	var options:Array=[]
	options.append(_option("E 观察／回应",{"type":"interact"}))
	if puzzle_id=="rescue_ch09_l05":
		if state.inspected and not state.unlocked:
			var labels:Array=["叶","花","果"];var symbols:Array=["leaf","flower","fruit"]
			for i in range(3):
				for j in range(3):options.append(_option("%s槽：%s"%[["左","中","右"][i],labels[j]],{"type":"lock","slot":i,"symbol":symbols[j]}))
			options.append(_option("按箱签开锁",{"type":"unlock"}))
		elif state.unlocked and state.method=="":
			options.append(_option("A 寻回张郎中",{"type":"method","value":"A"}));options.append(_option("B 协作分药引骑",{"type":"method","value":"B"}))
		elif state.method!="":
			if state.method=="A" and not state.returned_box:options.append(_option("还箱，郎中主持" if state.escorting else "扶起张郎中护送",{"type":"return_box" if state.escorting else "escort"}))
			if state.method=="B":
				options.append(_option("切回梁萧" if state.control_actor_id==A else "控制阿雪分药",{"type":"switch"}))
				if state.control_actor_id==A:
					for pair in [["叶签","leaf"],["花签","flower"],["果签","fruit"]]:
						if pair[1] not in state.sorted:options.append(_option("按"+pair[0]+"归类",{"type":"sort","label":pair[1]}))
				elif not state.decoys:options.append(_option("布下疑阵",{"type":"decoy"}))
				elif not state.patrol_lured:options.append(_option("引巡骑绕城外",{"type":"lure"}))
				elif not state.distributed:options.append(_option("小喜子代师发药",{"type":"distribute"}))
			if not _all_departed():options.append(_option("绕柱侧位卸刃",{"type":"disarm"}))
			elif not state.treated:options.append(_option("完成救治",{"type":"treat"}))
			elif not state.talked:options.append(_option("听医者余话",{"type":"talk"}))
			else:options.append(_option("救治归档",{"type":"finish"}))
	options.append(_option("等候一拍",{"type":"wait"}))
	var target:=_target_anchor();var lock_text:=""
	if puzzle_id=="rescue_ch09_l05" and state.inspected and not state.unlocked:lock_text="\n当前三槽：%s／%s／%s；目标：叶／花／果"%[{"leaf":"叶","flower":"花","fruit":"果"}[state.lock_slots[0]],{"leaf":"叶","flower":"花","fruit":"果"}[state.lock_slots[1]],{"leaf":"叶","flower":"花","fruit":"果"}[state.lock_slots[2]]]
	return {"puzzle_id":puzzle_id,"title":config.label+" · "+layout.anchor_labels[target],"body":"%s%s\n下一脚点：%s %s\n%s"%[_instructions(),lock_text,layout.anchor_labels[target],str(_anchor(target)),message],"instruction":_instructions(),"state":state.duplicate(true),"complete":state.complete,"paused_step_mode":true,"world_state":_world_state(),"options":options}
