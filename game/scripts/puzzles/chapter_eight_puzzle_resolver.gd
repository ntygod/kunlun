class_name ChapterEightPuzzleResolver
extends RefCounted
const VERSION:=1
const MAX_LOG:=2048
const SEGMENT_LIMIT:=512
const IDS:=["numbers_ch08_ranya","dam_ch08_submerged","cannon_ch08_calibration"]
const OBJECTIVES:={"numbers_ch08_ranya":"ranya_numbers_verified","dam_ch08_submerged":"submerged_dam_verified","cannon_ch08_calibration":"cannon_calibration_verified"}
const MODEL_SPEC:={"periods":[2,3,4,2,3,4,6],"pools":[4,2,0],"capacity":4,"wood":12,"rungs":4,"boats":{"left":1,"middle":1,"wide":2},"width":8,"velocity":3,"depths":{"1:9":2,"3:7":6,"5:5":8},"target":22,"angles":{"45":[11,10],"35":[3,4]}}
const ACTORS:=["char_liang_xiao","npc_ranya","npc_guo_shoujing"]
const STATIONS:={"char_liang_xiao":[-1,2],"npc_ranya":[-1,0],"npc_guo_shoujing":[-1,5]}
const BOAT_TARGETS:={"left":[0,2],"middle":[1,2],"wide":[2,2]}
var puzzle_id:=""
var attempt_id:=""
var context:Dictionary={}
var state:Dictionary={}
var input_log:Array=[]
var message:=""
var _events:Array=[]
var _proof:Dictionary={}
var _initial_hash:=""
var _context_hash:=""
static func _projection(_id:String,c:Dictionary) -> Dictionary:
	if not _bounded_tree(c):return {"invalid":true}
	c=_normalize(c)
	var out:Dictionary={}
	for k in ["chapter","current_token","revision","phase","scope","scene_id","map_id","objective_id","actors","items","world_objects","choices","knowledge","completed_receipts","authorizations","leader_id","control_actor_id"]:
		if c.has(k):out[k]=c[k].duplicate(true) if c[k] is Dictionary or c[k] is Array else c[k]
	if not _integer(c.get("chapter")) or c.chapter!=8 or not c.get("current_token") is String or c.current_token.is_empty() or not c.get("scene_id") is String:return {"invalid":true}
	if not c.get("actors") is Dictionary:return {"invalid":true}
	if not c.actors.get("char_liang_xiao") is Dictionary:return {"invalid":true}
	var leader:Dictionary=c.actors.char_liang_xiao
	if not leader.get("id","char_liang_xiao") is String or leader.get("id","char_liang_xiao")!="char_liang_xiao" or not _integer(leader.get("hp")) or leader.hp<=0:return {"invalid":true}
	if _id=="dam_ch08_submerged":
		for id in ACTORS.slice(1):
			if not c.actors.get(id) is Dictionary:return {"invalid":true}
			if not c.actors[id].get("id",id) is String or c.actors[id].get("id",id)!=id or c.actors[id].get("status","") not in ["alive","present"] or not c.actors[id].get("kind","") is String or c.actors[id].get("kind","")!="scene_support":return {"invalid":true}
	return out
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
	if id not in IDS or attempt.length()>256:return false
	var c:=_projection(id,trusted_context)
	if c.has("invalid"):return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c
	state={"hint":0,"assisted":false,"complete":false,"failures":0,"history_reset":false}
	state.merge(_fresh())
	input_log=[];_events=[];_proof={};_context_hash=_hash(c);_initial_hash=_hash(state);message="按常驻题干操作，可撤回试摆；只验证过程，不发奖励。"
	return true
func _fresh() -> Dictionary:
	if puzzle_id=="numbers_ch08_ranya":return {"problem":0,"day":0,"observed_six":false,"pools":[4,2,0],"leg":1,"passed":[]}
	if puzzle_id=="cannon_ch08_calibration":return {"phase":0,"ammo":"light","counterweight":4,"angle":35,"trials":[],"plans":[]}
	return {"actors":{"char_liang_xiao":[-3,2],"npc_ranya":[-3,0],"npc_guo_shoujing":[-3,5]},"orders":{},"boats":{"left":[0,0],"middle":[1,0],"wide":[2,0]},"boat_orders":{},"sunk":false,"ratio":"1:9","wood":[],"gate":false,"bridge_destroyed":false,"beats":0}
func set_context(c:Dictionary) -> bool:return _projection(puzzle_id,c)==context
static func _bounded_tree(value: Variant) -> bool:
	# Reject hostile save trees BEFORE recursive normalization; never traverse an
	# unbounded or cyclic Variant graph supplied by a caller.
	var pending: Array=[{"value":value,"depth":0}]; var visited:=0
	while not pending.is_empty():
		var entry: Dictionary=pending.pop_back(); var v: Variant=entry.value; var depth: int=entry.depth
		visited+=1
		if visited>200000 or depth>20: return false
		if v is Dictionary:
			if v.size()>2048: return false
			for key in v:
				if not (key is String or key is StringName) or str(key).length()>128: return false
				pending.append({"value":v[key],"depth":depth+1})
		elif v is Array:
			if v.size()>4096: return false
			for item in v: pending.append({"value":item,"depth":depth+1})
		elif v is String or v is StringName:
			if str(v).length()>512: return false
		elif v is float:
			if not is_finite(v): return false
		elif not (v is int or v is bool): return false
	return true

static func _normalize(v: Variant) -> Variant:
	if v is StringName:return str(v)
	if v is float and is_finite(v) and v == floor(v): return int(v)
	if v is Array:
		var out: Array = []
		for x in v: out.append(_normalize(x))
		return out
	if v is Dictionary:
		var out: Dictionary = {}
		for k in v: out[str(k)] = _normalize(v[k])
		return out
	return v

static func _hash(v: Variant) -> String: return JSON.stringify(_normalize(v)).sha256_text()
static func _integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and abs(float(v)) <= 1000000

func _safe(a:Dictionary) -> bool:
	var schemas:Dictionary={"hint":{},"retry":{},"finish":{},"assist_step_v1":{},"day":{"value":"int"},"transfer":{"from":"int","to":"int"},"leg":{"value":"int"},"assign":{"actor":"string","x":"int","y":"int"},"boat":{"boat":"string","x":"int","y":"int"},"beat":{},"sink":{},"ratio":{"value":"string"},"open_gate":{},"ammo":{"value":"string"},"weight":{"value":"int"},"angle":{"value":"int"},"trial":{},"restart_after_limit":{"hint":"int","assisted":"int","failures":"int","discarded_log_hash":"string"}}
	if not a.get("type") is String or not schemas.has(a.type):return false
	var schema:Dictionary=schemas[a.type]
	if a.size()!=schema.size()+1:return false
	for k in schema:
		if not a.has(k):return false
		if schema[k]=="int" and not _integer(a[k]):return false
		if schema[k]=="string" and (not a[k] is String or a[k].length()>100):return false
	return true
func _reject(reason:String) -> bool:message=reason;return false
func apply_input(a:Dictionary) -> Dictionary:
	if a.get("type") is String and a.type=="restart_after_limit":return {"ok":false,"message":"内部摘要不能作为玩家输入。"}
	return _apply_input(a)
func _apply_input(a:Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(a):return {"ok":false,"message":"操作格式无效。"}
	a=_normalize(a)
	var prefix_count:=_passed_prefix_count()
	if input_log.size()>=MAX_LOG or input_log.size()-prefix_count>=SEGMENT_LIMIT:
		if a.type!="retry" or state.complete:return {"ok":false,"message":"记录已满；请重试当前题，已验前缀与协助保留。"}
		var restart:Dictionary={"type":"restart_after_limit","hint":state.hint,"assisted":1 if state.assisted else 0,"failures":state.failures,"discarded_log_hash":_hash(input_log)}
		var prefix:Array=input_log.slice(0,prefix_count).duplicate(true)
		begin(puzzle_id,attempt_id,context)
		for command in prefix:_apply_input(command)
		return _apply_input(restart)
	var before:=_hash(state)
	var stage:int=int(state.get("problem",state.get("phase",0)))
	var before_actors:Dictionary=state.get("actors",{}).duplicate(true)
	var before_boats:Dictionary=state.get("boats",{}).duplicate(true)
	var before_wood:Array=state.get("wood",[]).duplicate()
	input_log.append(a.duplicate(true));var ok:=_operate(a)
	if not ok:state.failures=mini(1000000,state.failures+1)
	var event:Dictionary={"action":a.duplicate(true),"ok":ok,"before":before,"after":_hash(state)}
	if ok and int(state.get("problem",state.get("phase",0)))>stage:event.passed_stage=stage+1
	if ok and puzzle_id=="dam_ch08_submerged" and a.type in ["beat","assist_step_v1"]:
		var edges:Array=[]
		for actor in before_actors:
			if before_actors[actor]!=state.actors[actor]:edges.append({"actor":actor,"from":before_actors[actor],"to":state.actors[actor].duplicate()})
		for boat in before_boats:
			if before_boats[boat]!=state.boats[boat]:edges.append({"boat":boat,"from":before_boats[boat],"to":state.boats[boat].duplicate(),"width":MODEL_SPEC.boats[boat]})
		if before_wood!=state.wood:event.wood_edge={"from":before_wood,"to":state.wood.duplicate()}
		event.parallel_edges=edges
	_events.append(event)
	if state.complete and _proof.is_empty():_issue()
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt(),"receipts":get_receipts()}
func _passed_prefix_count() -> int:
	for i in range(_events.size()-1,-1,-1):
		if _events[i].has("passed_stage"):return i+1
	return 0
func _operate(a:Dictionary) -> bool:
	if a.type=="restart_after_limit":
		if (input_log.size()!=1 and (_events.is_empty() or not _events[-1].has("passed_stage"))) or a.hint<state.hint or a.hint>3 or a.assisted not in [0,1] or (state.assisted and a.assisted!=1) or a.failures<state.failures or a.discarded_log_hash.length()!=64:return _reject("非法摘要或降级已验证协助。")
		for ch in a.discarded_log_hash:
			if ch not in "0123456789abcdef":return _reject("非法摘要。")
		state.hint=a.hint;state.assisted=a.assisted==1;state.failures=a.failures;state.history_reset=true;message="当前题重新实做；已验前缀保留，丢弃前史无法核验，不计全手工。";return true
	if state.complete:return _reject("已验证完成，收起继续。")
	if a.type=="hint":state.hint=mini(3,state.hint+1);message=_hint();return true
	if a.type=="retry":
		var fresh:Dictionary=_fresh()
		if puzzle_id=="numbers_ch08_ranya":fresh.problem=state.problem;fresh.passed=state.passed.duplicate(true)
		if puzzle_id=="cannon_ch08_calibration":fresh.phase=state.phase;fresh.plans=state.plans.duplicate(true)
		state.merge(fresh,true);message="只重试当前题，已通过内容和协助不撤销。";return true
	if a.type=="assist_step_v1":
		if state.hint<3:return _reject("先读三层提示，再选择协助。")
		var next:=next_demo_action()
		if next.is_empty():return _reject("无合法下一步；可重试当前题。")
		state.assisted=true
		var ok:=_operate(next);message="协助实做："+message;return ok
	if puzzle_id=="numbers_ch08_ranya":return _numbers(a)
	if puzzle_id=="cannon_ch08_calibration":return _cannon(a)
	return _dam(a)
func _numbers(a:Dictionary) -> bool:
	if state.problem==0 and a.type=="day":
		if a.value<0 or a.value>12:return _reject("时间尺只含0至12整数日。")
		state.day=a.value
		if a.value==6:state.observed_six=true
		message="七珠同步移至第%d日。"%a.value;return true
	if state.problem==1 and a.type=="transfer":
		if a.from<0 or a.from>2 or a.to<0 or a.to>2 or abs(a.from-a.to)!=1:return _reject("只准AB、BC相邻闸各搬1筹。")
		if state.pools[a.from]<1 or state.pools[a.to]>=4:return _reject("源池需有水，目标池不可超过4筹。")
		state.pools[a.from]-=1;state.pools[a.to]+=1;message="实搬1筹，总水仍为6。";return true
	if state.problem==2 and a.type=="leg":
		if a.value<1 or a.value>6:return _reject("两条等长梯腿限1至6整数尺。")
		state.leg=a.value;message="四根1尺横档保留，两腿各%d尺，余料%d尺。"%[state.leg,8-2*state.leg];return true
	if a.type=="finish":
		if state.problem==0 and state.day!=12:return _reject("0日是起点；找1至12内七周期共同倍数最小日。")
		if state.problem==1 and state.pools!=[2,2,2]:return _reject("总水6筹，三池目标各2筹。")
		if state.problem==2 and state.leg!=4:return _reject("四档占4尺；两腿各4尺才是余料非负的最长方案。")
		state.passed.append({"problem":state.problem,"day":state.day,"pools":state.pools.duplicate(),"leg":state.leg})
		state.problem+=1;state.complete=state.problem==3;message="本题合法过程已验，保留已验前缀。";return true
	return _reject("请使用当前教学题允许的操作。")
static func shot_range(ammo:String,weight:int,angle:int) -> int:
	if ammo not in ["light","heavy"] or weight not in [4,6,8] or angle not in [35,45]:return -1
	var mass:int=3 if ammo=="light" else 5
	# GDScript int/int is integer division; never floor a float at 22.
	@warning_ignore("integer_division")
	var result:int=(10*weight*(11 if angle==45 else 3))/(mass*(10 if angle==45 else 4))
	return result
func _cannon(a:Dictionary) -> bool:
	if a.type=="ammo":
		if a.value not in ["light","heavy"]:return _reject("仅轻3、重5两种教学弹。")
		state.ammo=a.value;return true
	if a.type=="weight":
		if a.value not in [4,6,8]:return _reject("配重只可4、6、8筹。")
		state.counterweight=a.value;return true
	if a.type=="angle":
		if a.value not in [35,45]:return _reject("仰角只可35或45度。")
		state.angle=a.value;return true
	if a.type=="trial":
		var plan:=_current_plan()
		state.trials=[plan];message="模拟靶板落点%d格；敌弩未毁，炮位未实际前推。"%plan.landing;return true
	if a.type=="finish":
		var plan:=_current_plan()
		if state.trials.is_empty() or state.trials[-1]!=plan:return _reject("改参数后须重新模拟试射，不能提交未试方案。")
		if plan.landing!=22 or state.ammo!=("light" if state.phase==0 else "heavy"):return _reject("先轻弹从0恰中22；后重弹按未来10格炮位恰中22。")
		state.plans.append(plan);state.phase+=1;state.trials=[];state.complete=state.phase==2
		message="两方案仅校准完成，真实毁弩与前移由后续战役执行。" if state.complete else "轻弹方案已验；现在验证弩毁后前移至10的重弹预案。"
		return true
	return _reject("选择弹、配重、角度，试射后提交方案。")
func _current_plan() -> Dictionary:
	var origin:int=0 if state.phase==0 else 10
	return {"phase":state.phase,"origin":origin,"ammo":state.ammo,"mass":3 if state.ammo=="light" else 5,"weight":state.counterweight,"angle":state.angle,"range":shot_range(state.ammo,state.counterweight,state.angle),"landing":origin+shot_range(state.ammo,state.counterweight,state.angle),"enemy_range":21,"actual_fire":false}
func assistance_status() -> String:
	# A discarded segment cannot be authenticated by its hash or summary flag.
	# Only the retained/replayed actions establish assistance; unknown is never manual.
	if state.history_reset:
		for event in _events:
			if event.ok and event.action.type=="assist_step_v1":return "assisted"
		return "unknown"
	return "assisted" if state.assisted else "manual"
func _issue() -> void:
	_proof={"resolver_version":VERSION,"controller_version":VERSION,"chapter":"chapter_eight","scene_id":context.get("scene_id",""),"frozen_content_hash":_hash({"model":MODEL_SPEC,"stations":STATIONS,"boat_targets":BOAT_TARGETS,"walls":[[-2,1],[-2,4]],"wood_path":[[4,0],[4,1],[4,2],[4,3],[4,4],[4,5]]}),"context_hash":_context_hash,"objective_id":OBJECTIVES[puzzle_id],"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted or state.history_reset,"assistance_status":assistance_status(),"manual_process_verified":not state.assisted and not state.history_reset,"previous_attempt_history_unverified":state.history_reset,"materials_used":{},"product":state.get("product",""),"validation_results":{"complete_process":true,"no_xp":true}}
func receipt() -> Dictionary: return _proof.duplicate(true)
func get_receipts() -> Array: return [] if _proof.is_empty() else [receipt()]
func snapshot() -> Dictionary: return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_context_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(saved): return false
	saved=_normalize(saved)
	if not _integer(saved.get("version")) or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("context_hash") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary: return false
	if saved.version!=VERSION or saved.attempt_id.is_empty() or saved.attempt_id.length()>256 or saved.context_hash.length()!=64 or saved.input_log.size()>MAX_LOG: return false
	var candidate := ChapterEightPuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context) or saved.get("context_hash")!=candidate._context_hash: return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		var result:Dictionary=candidate._apply_input(a)
		if a.type=="restart_after_limit" and not result.get("ok",false):return false
	if candidate.state!=saved.state: return false
	puzzle_id=candidate.puzzle_id; attempt_id=candidate.attempt_id; context=candidate.context
	state=candidate.state; input_log=candidate.input_log; _proof=candidate._proof; _events=candidate._events; message=candidate.message; _initial_hash=candidate._initial_hash; _context_hash=candidate._context_hash
	return true
static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(proof): return false
	proof=_normalize(proof)
	if not proof.get("puzzle_id") is String or not proof.get("attempt_id") is String or not proof.get("input_log") is Array or not proof.get("context_hash") is String or not proof.get("final_state") is Dictionary: return false
	if proof.puzzle_id!=id or proof.attempt_id!=attempt: return false
	var r := ChapterEightPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":proof.get("context_hash"),"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return not r.receipt().is_empty() and r.receipt()==proof
func _boat_cells(boat:String,anchor:Array) -> Array:
	var cells:Array=[anchor]
	if boat=="wide":cells.append([anchor[0]+1,anchor[1]])
	return cells
func _cell_valid(cell:Array,kind:String,unit:String) -> bool:
	var x:int=cell[0];var y:int=cell[1]
	if kind=="actor":
		if x< -3 or x> -1 or y<0 or y>5 or cell in [[-2,1],[-2,4]]:return false
		for other in state.actors:
			if other!=unit and state.actors[other]==cell:return false
		return true
	if x<0 or y<0 or y>5 or x+(2 if unit=="wide" else 1)>4:return false
	for other in state.boats:
		if other==unit:continue
		for occupied in _boat_cells(other,state.boats[other]):
			if occupied in _boat_cells(unit,cell):return false
	return true
func _path(kind:String,unit:String,target:Array) -> Array:
	var positions:Dictionary=state.actors if kind=="actor" else state.boats
	if not positions.has(unit) or not _cell_valid(target,kind,unit) or positions[unit]==target:return []
	var queue:Array=[positions[unit].duplicate()];var seen:Dictionary={str(positions[unit]):[]}
	while not queue.is_empty():
		var here:Array=queue.pop_front()
		for d in [[0,-1],[1,0],[0,1],[-1,0]]:
			var cell:Array=[here[0]+d[0],here[1]+d[1]]
			if seen.has(str(cell)) or not _cell_valid(cell,kind,unit):continue
			var route:Array=seen[str(here)].duplicate(true);route.append(cell)
			if cell==target:return route
			seen[str(cell)]=route;queue.append(cell)
	return []
func _ready_stations() -> bool:
	return state.actors==STATIONS and state.orders.is_empty()
func _dam(a:Dictionary) -> bool:
	if a.type=="assign":
		if a.actor not in ACTORS:return _reject("只可指派梁、兰娅、郭守敬。")
		if state.gate:return _reject("木已入水，保持工位。")
		var route:=_path("actor",a.actor,[a.x,a.y])
		if route.is_empty():return _reject("银行边工位需四邻可达路径，不穿墙、不重叠。")
		state.orders[a.actor]=route;message="工位路线已排，推进施工拍时三人并行各走一格。";return true
	if a.type=="boat":
		if a.boat not in BOAT_TARGETS or state.sunk:return _reject("只能移动三艘未沉的独立船。")
		var operator:String="npc_guo_shoujing" if a.boat=="wide" else "char_liang_xiao"
		if state.actors[operator]!=STATIONS[operator] or state.orders.has(operator):return _reject("宽船需郭在下游锚点；左中船需梁在绞盘。")
		var route:=_path("boat",a.boat,[a.x,a.y])
		if route.is_empty():return _reject("船路越界、重叠或堵主流；宽船始终占两格。")
		state.boat_orders[a.boat]=route;message="引船路线已排，每施工拍沿合法水格一步。";return true
	if a.type=="beat":
		if state.orders.is_empty() and state.boat_orders.is_empty() and (not state.gate or state.complete):return _reject("暂无施工路线；先点人物或船的目标。")
		var moved:=false
		# Deterministic one edge per role within a shared construction beat.
		for actor in ACTORS:
			if not state.orders.has(actor):continue
			var cell:Array=state.orders[actor][0];var here:Array=state.actors[actor]
			if abs(cell[0]-here[0])+abs(cell[1]-here[1])!=1 or not _cell_valid(cell,"actor",actor):continue
			state.actors[actor]=cell;state.orders[actor].pop_front();moved=true
			if state.orders[actor].is_empty():state.orders.erase(actor)
		for boat in ["left","middle","wide"]:
			if not state.boat_orders.has(boat):continue
			var operator:String="npc_guo_shoujing" if boat=="wide" else "char_liang_xiao"
			if state.actors[operator]!=STATIONS[operator] or state.orders.has(operator):continue
			var cell:Array=state.boat_orders[boat][0];var here:Array=state.boats[boat]
			if abs(cell[0]-here[0])+abs(cell[1]-here[1])!=1 or not _cell_valid(cell,"boat",boat):continue
			state.boats[boat]=cell;state.boat_orders[boat].pop_front();moved=true
			if state.boat_orders[boat].is_empty():state.boat_orders.erase(boat)
		if state.gate:
			var next:Array=[state.wood[0],state.wood[1]+1]
			if next[0]<4 or next[0]>7 or next[1]>5:return _reject("主流路径不连续。")
			state.wood=next;moved=true
			if next==[4,5]:state.bridge_destroyed=true;state.complete=true
		if not moved:return _reject("路线暂被占；重新指派目标，不会穿过阻碍。")
		state.beats+=1;message="同一施工拍逐人/逐船沿一条合法边推进；日志可重放。";return true
	if a.type=="sink":
		if state.sunk or not _ready_stations() or state.boats!=BOAT_TARGETS or not state.boat_orders.is_empty():return _reject("三人须各到工位且三船停在各自标记，才可共同开底板。")
		state.sunk=true;message="三船共占4格沉下，横宽8→4，流速3×8÷4=6级。";return true
	if a.type=="ratio":
		if state.gate or not MODEL_SPEC.depths.has(a.value):return _reject("投放前只可选1:9、3:7、5:5。")
		state.ratio=a.value;message="木中心深%d尺；金网到5尺，江底8尺。"%MODEL_SPEC.depths[a.value];return true
	if a.type=="open_gate":
		if state.gate or not state.sunk or not _ready_stations():return _reject("三船沉下、三人到位后，由梁真实开闸。")
		if state.ratio!="3:7":return _reject("模拟挂网。回工作台调整，不耗材料。" if state.ratio=="1:9" else "模拟触底。回工作台调整，不耗材料。")
		state.gate=true;state.wood=[4,0];message="梁开闸，6尺深尖木入4列主流；逐拍沿流撞桥。";return true
	return _reject("先指派工位、引三船、共同沉船、调配重，再由梁开闸。")
func _water_next() -> Dictionary:
	var queue:Array=[state.pools.duplicate()];var seen:Dictionary={str(state.pools):[]}
	while not queue.is_empty():
		var pools:Array=queue.pop_front()
		for edge in [[0,1],[1,0],[1,2],[2,1]]:
			if pools[edge[0]]==0 or pools[edge[1]]==4:continue
			var next:Array=pools.duplicate();next[edge[0]]-=1;next[edge[1]]+=1
			if seen.has(str(next)):continue
			var route:Array=seen[str(pools)].duplicate(true);route.append({"type":"transfer","from":edge[0],"to":edge[1]})
			if next==[2,2,2]:return route[0]
			seen[str(next)]=route;queue.append(next)
	return {}
func next_demo_action() -> Dictionary:
	if state.complete:return {}
	if puzzle_id=="numbers_ch08_ranya":
		if state.problem==0 and not state.observed_six:return {"type":"day","value":6}
		if state.problem==0 and state.day!=12:return {"type":"day","value":12}
		if state.problem==1 and state.pools!=[2,2,2]:return _water_next()
		if state.problem==2 and state.leg!=4:return {"type":"leg","value":4}
		return {"type":"finish"}
	if puzzle_id=="cannon_ch08_calibration":
		var ammo:String="light" if state.phase==0 else "heavy"
		var weight:int=6 if state.phase==0 else 8
		var angle:int=45 if state.phase==0 else 35
		if state.ammo!=ammo:return {"type":"ammo","value":ammo}
		if state.counterweight!=weight:return {"type":"weight","value":weight}
		if state.angle!=angle:return {"type":"angle","value":angle}
		if state.trials.is_empty() or state.trials[-1]!=_current_plan():return {"type":"trial"}
		return {"type":"finish"}
	if state.gate:return {"type":"beat"}
	for actor in ACTORS:
		if state.actors[actor]!=STATIONS[actor] and not state.orders.has(actor):
			if _path("actor",actor,STATIONS[actor]).is_empty():return {"type":"retry"}
			return {"type":"assign","actor":actor,"x":STATIONS[actor][0],"y":STATIONS[actor][1]}
	if not state.orders.is_empty():return {"type":"beat"}
	for boat in ["left","middle","wide"]:
		if state.boats[boat]!=BOAT_TARGETS[boat] and not state.boat_orders.has(boat):
			if _path("boat",boat,BOAT_TARGETS[boat]).is_empty():return {"type":"retry"}
			return {"type":"boat","boat":boat,"x":BOAT_TARGETS[boat][0],"y":BOAT_TARGETS[boat][1]}
	if not state.boat_orders.is_empty():return {"type":"beat"}
	if not state.sunk:return {"type":"sink"}
	if state.ratio!="3:7":return {"type":"ratio","value":"3:7"}
	return {"type":"open_gate"}
func _hint() -> String:
	var hints:Array
	if puzzle_id=="numbers_ch08_ranya":
		hints=[["6日时4日珠还没归位。","寻找2、3、4、6的最小公倍数。","先观察6日，再拨12日逐珠验同归。"],["高水向缺水池，经B中转。","目标各2筹；每次搬1筹，总量保持6。","A→B、B→C、A→B、B→C；乱序后协助也按合法闸求路。"],["先留四根1尺横档。","剩8尺平均分两腿。","两腿各4尺，四档共4尺，无余料也不超料。"]][mini(state.problem,2)]
	elif puzzle_id=="dam_ch08_submerged":hints=["先让兰娅测水、郭守宽船锚、梁守绞盘。","三船独立堵1+1+2格；宽4流6。木深须大于5且小于8。","指派三人并行到位，三船到标沉下，3:7配重6尺深，梁开闸逐拍撞桥。"]
	else:hints=["先看x0在敌弩21格以外，靶板在22。","轻弹先恰中22；重弹按未来炮位10，只需12射程。","轻3/重6/45°得22；重5/重8/35°得12，未来10+12=22。仅校准。"]
	return hints[maxi(0,state.hint-1)]
func instruction() -> String:
	if puzzle_id=="numbers_ch08_ranya":
		return ["有限教学示意，非原著原题、非真实七曜周期。七珠同刻出发，周期2、3、4、2、3、4、6日。每日前进1/周期周。拨0～12整数日，找1～12内第一次全部回起点；0日不可交。", "有限教学渠池A/B/C容量各4筹，初始[4,2,0]。只可经AB、BC相邻闸每次搬1筹，源有水、目标未满；可反向撤回，不可溢出/丢水。目标[2,2,2]，总水6筹。", "有限教学木料12尺、等宽、锯缝忽略。四根横档固定各1尺；两根梯腿必须等长整数尺，只可1～6尺。余料=12−2×梯腿−4，不可负或重用。请选最长合法梯腿。模型木料不入背包。"][mini(state.problem,2)]
	if puzzle_id=="dam_ch08_submerged":return "离散教学：8×6水道，0～3列浅滩、4～7列主流。左/中/宽船各占1/1/2格，目标(0,2)/(1,2)/(2～3,2)，禁止重叠堵主流。梁绞盘(-1,2)、兰测水(-1,0)、郭锚点(-1,5)。点目标排四邻路线，推进一拍三人/船并行各走一格，到位共同沉船。横宽8→4，流速3×8/4=6。剖面深8尺，金网至5尺；石木1:9/3:7/5:5使木深2/6/8尺。须5<木深<8，梁开闸后木沿主流逐格撞桥。错投仅模拟，可重试无消耗。"
	return "仅校准方案，无真人开火、未毁弩、未前移。当前炮位x0，敌弩射程21、靶标x22。轻弹3筹/重弹5筹，配重4/6/8，角35°或45°。教学射程=floor(10×配重/弹重×角系数)，35°=3/4，45°=11/10；用整数有理数精确计算。先轻弹自0恰中22；再重弹按弩毁后未来炮位10恰中22。改参后模拟试射再提交。"
func get_view() -> Dictionary:
	var out:Dictionary={"kind":"chapter_eight","puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.get("current_token",""),"title":["兰娅三题 · 有限教学","三船束水与负石尖木","两炮校准 · 尚未毁弩"][IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint>0 else "","assistance_status":assistance_status(),"previous_attempt_history_unverified":state.history_reset,"next_action":next_demo_action(),"receipt":receipt(),"receipts":get_receipts()}
	if puzzle_id=="numbers_ch08_ranya":out.periods=MODEL_SPEC.periods.duplicate()
	if puzzle_id=="cannon_ch08_calibration":out.plan=_current_plan()
	if puzzle_id=="dam_ch08_submerged":out.stations=STATIONS.duplicate(true);out.boat_targets=BOAT_TARGETS.duplicate(true);out.depth=MODEL_SPEC.depths[state.ratio];out.width=4 if state.sunk else 8;out.velocity=6 if state.sunk else 3
	return out
