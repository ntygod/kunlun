class_name ChapterSevenPuzzleResolver
extends RefCounted
const F=preload("res://scripts/puzzles/chapter_seven_formation.gd")
const VERSION:=1
const MAX_LOG:=2048
const SEGMENT_LIMIT:=512
const IDS:=["grain_ch07_accounts","formation_ch07_drill","formation_ch07_regroup","letters_ch07_l03"]
const OBJECTIVES:={"grain_ch07_accounts":"grain_accounts_verified","formation_ch07_drill":"six_flower_breakout","formation_ch07_regroup":"regroup_withdrawal","letters_ch07_l03":"l03_letters_verified"}
const MODEL_SPEC:={"grain":[40000,36300,2,500],"formation":F.TEMPLATES,"units":F.UNITS,"waves":3,"letters":["npc_zhao_shan","npc_wang_ke","npc_hu_san"]}
const PAPERS:=["supply","wet","fodder"]
const PEOPLE:=["npc_zhao_shan","npc_wang_ke","npc_hu_san"]
const LETTER_TEXT := {
"joy":{"npc_zhao_shan":"娘亲放心，军中分了厚被肉汤，儿一切平安，莫省灯油。","npc_wang_ke":"我在军中平安。待归乡，仍想修好铁匠铺，替乡邻打造牢靠的器具。","npc_hu_san":"家中勿念，我在军中尚安，托人捎此信报个平安。"},
"truth":{"npc_zhao_shan":"山川路遥，军粮吃紧，烦四邻照应老母。梁萧随侍在侧，定护兄弟周全。","npc_wang_ke":"军旅艰辛，仍盼平安回乡，替李叔的推车换上铁轱辘。","npc_hu_san":"行军前路凶险，心中惦念家人。先写下平安话，愿有归期。"}}
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
static func _projection(id:String,c:Dictionary) -> Dictionary:
	if not _bounded_tree(c):return {"invalid":true}
	c=_normalize(c)
	var out:Dictionary={}
	for k in ["chapter","current_token","revision","phase","scene_id","map_id","objective_id","scope","actors","items","world_objects","choices","inherited_choices","knowledge","completed_receipts","leader_id","control_actor_id","fixed_level","method"]:
		if c.has(k):out[k]=c[k].duplicate(true) if c[k] is Dictionary or c[k] is Array else c[k]
	if not out.get("scene_id","") is String:return {"invalid":true}
	if id=="grain_ch07_accounts":
		for key in ["grain_dispatch_verified","grain_rations_verified","grain_loss_verified"]:
			if key not in c.get("knowledge",[]):return {"invalid":true}
	if id=="letters_ch07_l03" and c.get("method","") not in ["joy","truth"]:return {"invalid":true}
	if id.begins_with("formation"):
		if not c.get("actors") is Dictionary:return {"invalid":true}
		for unit in F.UNITS:
			if not c.actors.get(unit) is Dictionary:return {"invalid":true}
			if unit!="char_liang_xiao" and (c.actors[unit].get("id","")!=unit or c.actors[unit].get("kind","")!="scene_support" or c.actors[unit].get("status","") not in ["alive","recovering_mobile"]):return {"invalid":true}
		if not _integer(c.actors.char_liang_xiao.get("hp")) or c.actors.char_liang_xiao.hp<=0:return {"invalid":true}
	if id.begins_with("formation") and c.get("scope","")!=("ch07_qincha_drill" if id=="formation_ch07_drill" else "ch07_counter_ambush"):return {"invalid":true}
	return out
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
	if id not in IDS or attempt.length()>256:return false
	var c:=_projection(id,trusted_context)
	if c.has("invalid"):return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c
	state={"hint":0,"assisted":false,"complete":false,"failures":0,"history_reset":false}
	if id=="grain_ch07_accounts":state.merge({"papers":{},"difference":false,"equation":false,"values":{}})
	elif id=="letters_ch07_l03":
		state.merge({"method":c.method,"letters":{}})
		for person in PEOPLE:state.letters[person]={"written":false,"sealed":false,"returned":false,"content":""}
	else:state.merge({"positions":[[-3,2],[-2,2],[-1,2],[1,2],[2,2],[3,2]],"directions":["N","N","N","N","N","N"],"wave":0,"center":[0,0],"moving":{},"undo_available":false,"last_move":{},"wave_receipts":[],"assist_plan":[]})
	input_log=[];_events=[];_proof={};_context_hash=_hash(c);_initial_hash=_hash(state);message="按公开规格操作；收起与存档保留实际进度。"
	return true
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
	var schemas:Dictionary={"hint":{},"retry":{},"finish":{},"assist_step_v1":{},"step_move":{},"undo_move":{},"horn":{},"plan_formation":{},"place_paper":{"paper":"string","column":"string"},"difference":{"value":"int"},"equation":{"value":"string"},"value":{"column":"string","value":"string"},"write_letter":{"person":"string","content":"string"},"seal_letter":{"person":"string"},"return_letter":{"person":"string"},"move":{"unit":"int","x":"int","y":"int"},"turn":{"unit":"int","direction":"string"},"restart_after_limit":{"hint":"int","assisted":"int","failures":"int","discarded_log_hash":"string"}}
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
	if a.get("type")=="restart_after_limit":return {"ok":false,"message":"内部摘要不能作为玩家输入。"}
	return _apply_input(a)
func _apply_input(a:Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(a):return {"ok":false,"message":"操作格式无效。"}
	a=_normalize(a)
	var prefix_count:=_passed_prefix_count()
	if input_log.size()>=MAX_LOG or input_log.size()-prefix_count>=SEGMENT_LIMIT:
		if a.type!="retry" or state.complete:return {"ok":false,"message":"记录已满；请重试，提示与协助记录保留。"}
		var restart:Dictionary={"type":"restart_after_limit","hint":state.hint,"assisted":1 if state.assisted else 0,"failures":state.failures,"discarded_log_hash":_hash(input_log)}
		var verified_prefix:Array=input_log.slice(0,prefix_count).duplicate(true)
		begin(puzzle_id,attempt_id,context)
		for command in verified_prefix:_apply_input(command)
		return _apply_input(restart)
	var before:=_hash(state)
	var old_wave:int=int(state.get("wave",0))
	var old_positions:Array=state.get("positions",[]).duplicate(true)
	var old_moving:Dictionary=state.get("moving",{}).duplicate(true)
	input_log.append(a.duplicate(true));var ok:=_operate(a)
	if not ok:state.failures=mini(1000000,state.failures+1)
	var event:Dictionary={"action":a.type,"ok":ok,"before":before,"after":_hash(state)}
	if ok and puzzle_id.begins_with("formation"):
		if state.wave>old_wave:event.passed_wave=state.wave
		if old_moving.is_empty() and not state.moving.is_empty():event.move_transaction=state.moving.duplicate(true)
		elif not old_moving.is_empty() and old_positions!=state.positions:
			event.verified_step={"unit":old_moving.unit,"actor_id":F.UNITS[old_moving.unit],"from":old_positions[old_moving.unit],"to":state.positions[old_moving.unit],"transaction_before_hash":old_moving.before_hash}
		elif a.type=="undo_move":event.undo_transaction={"from_hash":_hash(old_positions),"to_hash":_hash(state.positions),"wave":state.wave}
	_events.append(event)
	if state.complete and _proof.is_empty():_issue()
	return {"ok":ok,"message":message,"view":get_view(),"receipt":receipt(),"receipts":get_receipts()}
func _passed_prefix_count() -> int:
	if not puzzle_id.begins_with("formation"):return 0
	for i in range(_events.size()-1,-1,-1):
		if _events[i].has("passed_wave"):return i+1
	return 0
func _operate(a:Dictionary) -> bool:
	if a.type=="restart_after_limit":
		if (input_log.size()!=1 and (_events.is_empty() or not _events[-1].has("passed_wave"))) or a.hint<0 or a.hint>3 or a.assisted not in [0,1] or a.failures<0 or a.discarded_log_hash.length()!=64:return _reject("非法摘要。")
		for ch in a.discarded_log_hash:
			if ch not in "0123456789abcdef":return _reject("非法摘要。")
		state.hint=a.hint;state.assisted=a.assisted==1;state.failures=a.failures;state.history_reset=true;message="此前详细尝试已压缩，前史提示/协助未验证；当前题重新实做。";return true
	if state.complete:return _reject("本题已验，收起继续。")
	if a.type=="hint":state.hint=mini(3,state.hint+1);message=_hint();return true
	if a.type=="retry":
		var fresh:=ChapterSevenPuzzleResolver.new();fresh.begin(puzzle_id,attempt_id,context)
		for key in ["hint","assisted","failures","history_reset"]:fresh.state[key]=state[key]
		# Formation retry is only the current wave, never a passed wave.
		if puzzle_id.begins_with("formation"):
			for key in ["wave","center","wave_receipts"]:fresh.state[key]=state[key].duplicate(true) if state[key] is Array else state[key]
			fresh.state.positions=state.positions.duplicate(true);fresh.state.directions=state.directions.duplicate()
		state=fresh.state;message="重整当前操作，已通过波不可倒转。";return true
	if not state.get("moving",{}).is_empty() and a.type not in ["step_move","assist_step_v1"]:return _reject("本次移动尚未走完，请等待或暂歇保存。")
	if a.type=="assist_step_v1":
		if state.hint<3:return _reject("先读三层提示，再确认协助一步。")
		var next:=next_demo_action()
		if next.is_empty():return _reject("没有可执行协助；当前布阵需检查。")
		state.assisted=true;var ok:=_operate(next);message="协助实际一步："+message;return ok
	if puzzle_id=="grain_ch07_accounts":return _grain(a)
	if puzzle_id=="letters_ch07_l03":return _letters(a)
	return _formation(a)
func _grain(a:Dictionary) -> bool:
	if a.type=="place_paper":
		if a.paper not in PAPERS or a.paper!=a.column:return _reject("给养簿、湿袋记录、饲料簿应分别归原栏。")
		state.papers[a.column]=a.paper;message="纸据放入对应栏。";return true
	if a.type=="difference":
		if a.value!=40000-36300:return _reject("总差=运出40000−可交36300；不是凭空补回粮。")
		state.difference=true;message="总差3700石待核清去向。";return true
	if a.type=="equation":
		if a.value!="4y+500=3700":return _reject("用x=2y、z=y+500代入三项总差。")
		state.equation=true;message="三关系合为4y+500=3700。";return true
	if a.type=="value":
		if a.column not in PAPERS or a.value.is_empty() or a.value.length()>6:return _reject("请填非负整数石数。")
		for ch in a.value:
			if ch not in "0123456789":return _reject("拒绝负数、小数及非法文字。")
		var n:=int(a.value)
		if n>40000:return _reject("石数超过账册运出总量。")
		state.values[a.column]=n;message="已记入该栏；最后核三条约束。";return true
	if a.type=="finish":
		if state.papers.size()!=3 or not state.difference or not state.equation or state.values.size()!=3:return _reject("三纸据、差额、合式、三栏均须实际填写。")
		var x:int=state.values.supply;var y:int=state.values.wet;var z:int=state.values.fodder
		if x+y+z!=3700 or x!=2*y or z!=y+500:return _reject("三栏须合3700，给养为雨湿2倍，饲料比雨湿多500。")
		state.complete=true;message="1600给养、800雨湿、1300饲料，共3700石实际去向核清。";return true
	return _reject("按纸据归栏、差额、合式及三栏核账。")
func _letters(a:Dictionary) -> bool:
	if a.type=="finish":
		for person in PEOPLE:
			if not state.letters[person].returned:return _reject("三封信都须写好、封蜡、交回本人待寄。")
		state.complete=true;message="三封信已各交本人待寄，并未冒称寄出。";return true
	if a.get("person","") not in PEOPLE:return _reject("选择三位托书同袍之一。")
	var letter:Dictionary=state.letters[a.person]
	if a.type=="write_letter":
		if letter.sealed or a.content!=state.method+":"+a.person:return _reject("选取对应同袍与已定口吻内容，封蜡后不能改写。")
		letter.written=true;letter.content=a.content;message="对应口吻内容已落纸。";return true
	if a.type=="seal_letter" and letter.written and not letter.sealed:letter.sealed=true;message="此封信已封蜡。";return true
	if a.type=="return_letter" and letter.sealed and not letter.returned:letter.returned=true;message="信袋交回本人待寄。";return true
	return _reject("依次写信、封蜡、交回本人，不可略过。")
func _issue() -> void:
	_proof={"resolver_version":VERSION,"controller_version":VERSION,"chapter":"chapter_seven","scene_id":context.get("scene_id",""),"frozen_content_hash":_hash({"model":MODEL_SPEC,"letters":LETTER_TEXT}),"context_hash":_context_hash,"objective_id":OBJECTIVES[puzzle_id],"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted,"previous_attempt_history_unverified":state.history_reset,"materials_used":{},"product":state.get("product",""),"validation_results":{"complete_process":true,"no_xp":true}}
func receipt() -> Dictionary: return _proof.duplicate(true)
func get_receipts() -> Array: return [] if _proof.is_empty() else [receipt()]
func snapshot() -> Dictionary: return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_context_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(saved): return false
	saved=_normalize(saved)
	if not _integer(saved.get("version")) or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("context_hash") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary: return false
	if saved.version!=VERSION or saved.attempt_id.is_empty() or saved.attempt_id.length()>256 or saved.context_hash.length()!=64 or saved.input_log.size()>MAX_LOG: return false
	var candidate := ChapterSevenPuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context) or saved.get("context_hash")!=candidate._context_hash: return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		candidate._apply_input(a)
	if candidate.state!=saved.state: return false
	puzzle_id=candidate.puzzle_id; attempt_id=candidate.attempt_id; context=candidate.context
	state=candidate.state; input_log=candidate.input_log; _proof=candidate._proof; _events=candidate._events; message=candidate.message; _initial_hash=candidate._initial_hash; _context_hash=candidate._context_hash
	return true
static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(proof): return false
	proof=_normalize(proof)
	if not proof.get("puzzle_id") is String or not proof.get("attempt_id") is String or not proof.get("input_log") is Array or not proof.get("context_hash") is String or not proof.get("final_state") is Dictionary: return false
	if proof.puzzle_id!=id or proof.attempt_id!=attempt: return false
	var r := ChapterSevenPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":proof.get("context_hash"),"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return not r.receipt().is_empty() and r.receipt()==proof
func _formation(a:Dictionary) -> bool:
	if not F.valid(state.positions):return _reject("六个存活指挥支点身份/坐标失效。")
	var spec:Dictionary=F.wave(context.scope,mini(state.wave,2))
	if a.type=="plan_formation":
		state.assist_plan=F.plan(state.positions,F.targets(spec.shape,spec.orientation,state.center));message="已排出四邻合法布阵路线，仍须逐次移动。";return not state.assist_plan.is_empty()
	if a.type=="move":
		if a.unit<0 or a.unit>=6:return _reject("仅梁与五位存活同袍可布阵。")
		var route:Array=F.path(state.positions,a.unit,[a.x,a.y])
		if route.is_empty():return _reject("目标被占、越界、原位或无可达四邻路径；原位保留。")
		var before:Array=state.positions.duplicate(true)
		state.moving={"unit":a.unit,"path":route,"cursor":0,"before":before,"before_hash":_hash(before),"wave":state.wave}
		state.undo_available=false
		if not state.assist_plan.is_empty() and state.assist_plan[0].unit==a.unit and state.assist_plan[0].target==[a.x,a.y]:state.assist_plan.pop_front()
		else:state.assist_plan=[]
		message="已选最短路径，逐格校验前进。";return true
	if a.type=="step_move":
		if state.moving.is_empty():return _reject("没有正在行进的移动。")
		var m:Dictionary=state.moving;var next:Array=m.path[m.cursor];var here:Array=state.positions[m.unit]
		if abs(next[0]-here[0])+abs(next[1]-here[1])!=1 or next in state.positions or abs(next[0])>5 or abs(next[1])>5:return _reject("移动格不合法；没有穿越单位。")
		state.positions[m.unit]=next.duplicate();m.cursor+=1
		if m.cursor==m.path.size():state.last_move=m.duplicate(true);state.undo_available=true;state.moving={}
		message="沿合法四邻空格移动一格。";return true
	if a.type=="undo_move":
		if not state.undo_available or state.last_move.is_empty() or state.last_move.wave!=state.wave:return _reject("只能撤回本波最近一次未鸣号移动，且仅一次。")
		state.positions=state.last_move.before.duplicate(true);state.undo_available=false;state.last_move={};state.assist_plan=[];message="最近一次移动已撤回，不倒转已过波。";return true
	if a.type=="turn":
		if a.unit<0 or a.unit>=6 or a.direction not in F.VECTORS:return _reject("选择本阵单位与N/E/S/W朝向。")
		state.directions[a.unit]=a.direction;message="此单位朝向已调整，点击目标不会自动转向。";return true
	if a.type=="horn":
		var fit:Dictionary=F.fit(state.positions,spec.shape)
		if fit.is_empty() or fit.orientation!=spec.orientation or fit.center!=state.center:return _reject("阵形/阵朝向或本波中心不合；参看公开轮廓，可继续重排。")
		if state.directions!=F.directions(state.positions,spec.enemy,spec.gap):return _reject("来敌方向投影最前排全部面敌，其他单位朝空隙。")
		var delta:Array=F.VECTORS[spec.gap];var moved:Array=[]
		for cell in state.positions:moved.append([cell[0]+delta[0],cell[1]+delta[1]])
		if not F.valid(moved):return _reject("整阵推进越界或重叠，当前波未通过。")
		# All six simultaneous destinations checked against the vacated source
		# set. Atomic group translation must not falsely collide with its own tail.
		state.positions=moved;state.center=[state.center[0]+delta[0],state.center[1]+delta[1]]
		state.wave_receipts.append({"scope":context.scope,"context_hash":_context_hash,"wave":state.wave,"formation_hash":_hash(fit),"center":state.center.duplicate()})
		state.wave+=1;state.undo_available=false;state.last_move={};state.assist_plan=[]
		if state.wave==3:
			var endpoint:Array=[2,-1] if context.scope=="ch07_qincha_drill" else [1,-2]
			if state.center!=endpoint or state.wave_receipts.size()!=3:return _reject("出口与三波收据未同时满足。")
			state.complete=true
		message="本波号令通过，整阵沿公开空隙推进一格。";return true
	return _reject("禁箭：只可合法移动、单独转向、撤回或鸣号。")
func next_demo_action() -> Dictionary:
	if state.complete:return {}
	if puzzle_id=="grain_ch07_accounts":
		for paper in PAPERS:
			if not state.papers.has(paper):return {"type":"place_paper","paper":paper,"column":paper}
		if not state.difference:return {"type":"difference","value":3700}
		if not state.equation:return {"type":"equation","value":"4y+500=3700"}
		for column in PAPERS:
			var correct:int={"supply":1600,"wet":800,"fodder":1300}[column]
			if state.values.get(column,-1)!=correct:return {"type":"value","column":column,"value":str(correct)}
		return {"type":"finish"}
	if puzzle_id=="letters_ch07_l03":
		for person in PEOPLE:
			var l:Dictionary=state.letters[person]
			if not l.written:return {"type":"write_letter","person":person,"content":state.method+":"+person}
			if not l.sealed:return {"type":"seal_letter","person":person}
			if not l.returned:return {"type":"return_letter","person":person}
		return {"type":"finish"}
	if not state.moving.is_empty():return {"type":"step_move"}
	var spec:Dictionary=F.wave(context.scope,mini(state.wave,2));var target:Array=F.targets(spec.shape,spec.orientation,state.center)
	if state.positions!=target:
		if state.assist_plan.is_empty():return {"type":"plan_formation"}
		var next:Dictionary=state.assist_plan[0]
		return {"type":"move","unit":next.unit,"x":next.target[0],"y":next.target[1]}
	var dirs:Array=F.directions(state.positions,spec.enemy,spec.gap)
	for i in range(6):
		if state.directions[i]!=dirs[i]:return {"type":"turn","unit":i,"direction":dirs[i]}
	return {"type":"horn"}
func _hint() -> String:
	if puzzle_id=="grain_ch07_accounts":return ["先用40000−36300求总差。","x=2y，z=y+500，代入总差。","合式4y=3200；协助每次实填一项。"][maxi(0,state.hint-1)]
	if puzzle_id=="letters_ch07_l03":return "逐封选择对应口吻内容，落纸、封蜡、交回同袍本人待寄。"
	return ["看公开骑军来向与安全空隙。","按当前轮廓摆阵，最前排面敌，其余朝空隙。","协助先排可达路线，再逐格移动并独立转向；不会直接填终态。"][maxi(0,state.hint-1)]
func instruction() -> String:
	if puzzle_id=="grain_ch07_accounts":return "运出40000，可交36300；给养x=雨湿y的2倍，饲料z比雨湿多500。归纸据、核差额、合式，再填非负整数三栏并验和。"
	if puzzle_id=="letters_ch07_l03":return "三封代书各依已选口吻落纸，封蜡后把信袋交回本人待寄；没有寄出或支出玩家铜钱。"
	return "禁箭教学沙盘；点单位再点空格，按N/E/S/W顺序寻最短四邻路。阵形依本波中心轮廓，来向最前排全体面敌，其余朝突破口。逐人转向后鸣号；可撤最近单次移动，不能撤已过波。"
func get_view() -> Dictionary:
	var out:Dictionary={"kind":"chapter_seven","puzzle_id":puzzle_id,"title":["核清粮账","禁箭六花演武","收拢散兵稳军","同袍家书"][IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint>0 else "","next_action":next_demo_action(),"receipt":receipt(),"receipts":get_receipts(),"letter_texts":LETTER_TEXT.duplicate(true)}
	if puzzle_id.begins_with("formation"):
		out.wave_spec=F.wave(context.scope,mini(state.wave,2));out.target_positions=F.targets(out.wave_spec.shape,out.wave_spec.orientation,state.center)
	return out
