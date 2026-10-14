class_name ChapterFourPuzzleResolver
extends RefCounted
## Frozen, finite teaching boards. Graph edges are not claims about world jumping distances.
const VERSION := 2
const STAFF_RIVAL_START := 12
const MAX_LOG := 1024
const IDS := ["tile_ch04_intercept", "board_ch04_wood", "trial_ch04_staff", "r02", "l01", "ledger_ch04_r02"]
const COUNTS := [3,9,27,81,243,729]
const OBJECTIVES := {"tile_ch04_intercept":"tile_trajectory_verified","board_ch04_wood":"wood_count_derivation","trial_ch04_staff":"staff_trial_verified","r02":"r02_rain_test","l01":"l01_leak_test","ledger_ch04_r02":"r02_ledger_verified"}
const SCENES := {"tile_ch04_intercept":"ch04_tile_intercept","board_ch04_wood":"ch04_spring_thirds","trial_ch04_staff":"ch04_staff_wager","r02":"ch04_r02","l01":"ch04_l01","ledger_ch04_r02":"ch04_r02"}
const CONTENT_HASH := "ch04_finite_models_v2_three_hops_six_powers_ring45_start12_weave6_hull3"
var puzzle_id := ""
var attempt_id := ""
var context: Dictionary = {}
var state: Dictionary = {}
var input_log: Array = []
var message := ""
var _undo: Array = []
var _events: Array = []
var _proofs: Array = []
var _initial_hash := ""

func _init(id: String = "") -> void:
	if not id.is_empty(): begin(id)

func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if not id in IDS: return false
	puzzle_id = id; attempt_id = attempt if not attempt.is_empty() else id+":attempt"
	context = trusted_context.duplicate(true)
	state = {"hint":0,"assisted":false,"complete":false,"failures":0}
	match id:
		"tile_ch04_intercept": state.merge({"observed":false,"vx":0,"dy":0,"selected":false,"contacts":[],"rope_cut":false,"boat_angle":0,"landing":"","launched":false,"missed":false})
		"board_ch04_wood": state.merge({"observations":[],"groups":[],"rows":[]})
		"trial_ch04_staff": state.merge({"posts":[],"checked":false,"rules":false,"consent":false,"player":0,"rival":STAFF_RIVAL_START,"round":0,"intent":false,"trace":[],"collapsed":false,"collapse_seen":false,"landing":"","captured":false,"feet_ground":false})
		"r02": state.merge({"materials":[],"slots":["","","","","",""],"woven":false,"rain":[],"hat_instance":"item_ch04_liu_willow_hat"})
		"l01": state.merge({"materials":false,"boards":["","",""],"filler":[false,false,false],"load":2,"anchor":false,"level":false,"released":false,"ticks":0,"water":0,"tide_log":[]})
		"ledger_ch04_r02": state.merge({"observations":[],"legal_total":0,"excess":0,"sum_checked":false,"difference_checked":false})
	input_log.clear(); _events.clear(); _proofs.clear(); _undo.clear()
	_initial_hash = _hash(state)
	message = "先观察并操作题板；错误可撤回或重试，不扣经验或真实材料。"
	return true

func set_context(trusted_context: Dictionary) -> void: context = trusted_context.duplicate(true)

static func _normalize(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floor(v): return int(v)
	if v is Array:
		var out: Array = []
		for x in v: out.append(_normalize(x))
		return out
	if v is Dictionary:
		var out: Dictionary = {}
		for k in v: out[k] = _normalize(v[k])
		return out
	return v

static func _hash(v: Variant) -> String: return JSON.stringify(_normalize(v)).sha256_text()
static func _integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and abs(float(v)) <= 1000000
func _index(v: Variant, n: int) -> bool: return _integer(v) and int(v) >= 0 and int(v) < n
func _safe(a: Dictionary) -> bool:
	if not a.get("type") is String or a.size() > 8: return false
	for k in a:
		if not k is String: return false
		if a[k] is String:
			if a[k].length() > 100: return false
		elif not _integer(a[k]): return false
	return true
func _reject(reason: String) -> bool:
	message = reason
	return false

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(action): return {"ok":false,"message":"操作格式无效。"}
	action = _normalize(action)
	if input_log.size() >= MAX_LOG:
		if action.type not in ["reset","retry"] or state.complete: return {"ok":false,"message":"本轮记录已满；重试可清空题面，保留提示和协助记录。"}
		var restart := {"type":"restart_after_limit","hint":state.hint,"assisted":1 if state.assisted else 0,"failures":state.failures,"discarded_log_hash":_hash(input_log)}
		begin(puzzle_id,attempt_id,context)
		return apply_input(restart)
	var before := state.duplicate(true)
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	if not ok: state.failures = mini(1000000,state.failures+1)
	elif action.type not in ["hint","undo","reset","retry","restart_after_limit"] and not state.complete:
		_undo.append(before)
		if _undo.size() > 128: _undo.pop_front()
	_events.append({"action":action.type,"ok":ok,"before":_hash(before),"after":_hash(state)})
	if ok: _milestones()
	return {"ok":ok,"message":message,"receipt":receipt(),"receipts":get_receipts(),"view":get_view()}

func _operate(a: Dictionary) -> bool:
	if a.type == "restart_after_limit":
		if input_log.size() != 1 or a.size() != 5 or not _integer(a.get("hint")) or not _integer(a.get("assisted")) or not _integer(a.get("failures")): return _reject("重开摘要只能是首条记录。")
		if a.hint < 0 or a.hint > 3 or a.assisted not in [0,1] or a.failures < 0 or not a.get("discarded_log_hash") is String or a.discarded_log_hash.length() != 64: return _reject("重开摘要无效。")
		for c in a.discarded_log_hash:
			if not c in "0123456789abcdef": return _reject("重开摘要无效。")
		state.hint = a.hint; state.assisted = a.assisted == 1; state.failures = a.failures
		message = "已清空旧轮题面，仍需从第一步做完；提示和协助保留。"; return true
	if state.complete: return _reject("已验收，请收起题板继续。")
	if a.type == "hint":
		state.hint = mini(3,state.hint+1); message = _hint(); return true
	if a.type == "undo":
		if _undo.is_empty(): return _reject("本阶段没有可撤回操作。")
		var meta := {"hint":state.hint,"assisted":state.assisted,"failures":state.failures}
		state = _undo.pop_back(); state.merge(meta,true); message = "已撤回上一步，提示和协助记录保留。"; return true
	if a.type in ["reset","retry"]:
		var fresh := ChapterFourPuzzleResolver.new(puzzle_id)
		fresh.state.hint = state.hint; fresh.state.assisted = state.assisted; fresh.state.failures = state.failures
		state = fresh.state; _undo.clear(); _proofs.clear(); message = "本题重新开始；真实钱物与角色状态不变。"; return true
	if a.type in ["assist_stage_v1","assist_stage_v2"]:
		if state.hint < 3: return _reject("先读三层提示，再主动同意本阶段协助。")
		state.assisted = true
		var report: Array[String] = []
		# Each stage is bounded and executes the SAME validators, no success flag injection.
		var count := 5 if puzzle_id == "board_ch04_wood" else 1
		var starting_row: int = state.rows.size() if puzzle_id == "board_ch04_wood" else -1
		for i in range(count):
			var next := _assist_v1_next_action()
			if next.is_empty(): break
			if not _operate(next): return false
			report.append(describe_action(next))
			if state.complete: break
			if a.type == "assist_stage_v2" and puzzle_id == "board_ch04_wood" and state.rows.size() > starting_row: break
		message = "协助实际执行："+"；".join(report)+"。"; return not report.is_empty()
	match puzzle_id:
		"tile_ch04_intercept": return _tile(a)
		"board_ch04_wood": return _wood(a)
		"trial_ch04_staff": return _staff(a)
		"r02": return _hat(a)
		"l01": return _boat(a)
		"ledger_ch04_r02": return _ledger(a)
	return false

func _tile(a: Dictionary) -> bool:
	match a.type:
		"observe_current":
			state.observed = true; message = "浮标每跳向东漂1格。缆索在(10,5)，起点(1,5)。"; return true
		"set_launch":
			if not state.observed or not a.get("vx") in [1,2,3] or not a.get("dy") in [-1,0,1] or state.launched: return _reject("先观察；推力取1/2/3，纵移取−1/0/1；发射后请撤回或重试。")
			state.vx = a.vx; state.dy = a.dy; state.selected = true; message = "参数已设置；每跳横移＝推力＋水流1格。"; return true
		"launch":
			if not state.selected or state.launched: return _reject("先设定发射参数。")
			state.launched = true; state.contacts.clear()
			var p := Vector2i(1,5)
			for hop in range(3):
				p += Vector2i(state.vx+1,state.dy)
				state.contacts.append([p.x,p.y])
				if p.x < 0 or p.x > 12 or p.y < 0 or p.y > 8 or (hop < 2 and (p.y not in [4,5,6] or p.x > 9)):
					state.missed = true; message = "瓦片离开合法水面，缆索未断。可撤回调整或重试。"; return true
			state.rope_cut = p == Vector2i(10,5); state.missed = not state.rope_cut
			message = "三跳接触缆索，绳断；下一步观察水流使船横转。" if state.rope_cut else "三跳未碰到缆索，船仍系住。请撤回后调整。"; return true
		"current_tick":
			if not state.rope_cut or state.boat_angle != 0: return _reject("只有断缆后水流才能转船。")
			state.boat_angle = 90; message = "小船顺水横转90度，船尾稳固落脚区转到(9,6)。"; return true
		"land":
			if state.boat_angle != 90 or a.get("x") != 9 or a.get("y") != 6: return _reject("请等船转稳，再落到(9,6)船尾；不能落水或落在原位置。")
			state.landing = "safe_stern"; state.complete = true; message = "柳莺莺落在转后的船尾，稳住身形；完整拦船过程已验。"; return true
	return _reject("请依次观察、设参、投瓦、转船、选择安全落点。")

func _wood(a: Dictionary) -> bool:
	var row: int = state.rows.size()
	if a.type == "observe_cut":
		if row >= 6 or a.get("cut") != row+1 or state.observations.size() != row: return _reject("只观察下一次三分剑招；取下原木的第一剑不计入六招。")
		state.observations.append(row+1); message = "第%d招：每一根都分为三根。把当前全部木柴分入三组。" % (row+1); return true
	if a.type == "split_group":
		if state.observations.size() != row+1 or not _index(a.get("group"),3) or a.group in state.groups: return _reject("先观察本招，再把当前木柴分别放到三处不同子组。")
		state.groups.append(a.group); message = "第%d子组各有%d根；这是上一行数量的一份。" % [a.group+1,1 if row==0 else COUNTS[row-1]]; return true
	if a.type == "multiply_row":
		var previous: int = 1 if row == 0 else COUNTS[mini(row-1,5)]
		if row >= 6 or state.groups.size()!=3 or a.get("prior") != previous or a.get("factor") != 3 or a.get("result") != previous*3: return _reject("须三组齐全，并填写 上一行×3＝本行；只填729不算推导。")
		state.rows.append({"cut":row+1,"prior":previous,"factor":3,"result":previous*3}); state.groups.clear()
		message = "%d × 3 = %d；已完成%d/6行。" % [previous,previous*3,row+1]; return true
	if a.type == "submit":
		if row != 6 or state.observations != [1,2,3,4,5,6]: return _reject("须六次不同观察与对应六行乘算。")
		state.complete = true; message = "六行逐一对应六招：3、9、27、81、243、729。"; return true
	return _reject("按观察、三组分木、乘算的顺序逐行进行。")

static func ring_route(start: int, stride: int, direction: int) -> Array:
	var result: Array = []
	for i in range(stride): result.append(posmod(start+direction*(i+1),45))
	return result
static func rival_route(start: int, target: int) -> Array:
	var clockwise := posmod(target-start,45)
	return ring_route(start,4,1 if clockwise <= 22 else -1)
func _staff(a: Dictionary) -> bool:
	if state.captured or state.feet_ground: return _reject("此轮已失败；请重试。胭脂马仍归柳莺莺，没有失马结算。")
	match a.type:
		"place_batch":
			if not _index(a.get("batch"),9) or state.checked: return _reject("选择尚未放置的五根一组棍位。")
			for i in range(a.batch*5,a.batch*5+5):
				if i in state.posts: return _reject("该组棍位已有支撑，不能重复计数。")
			for i in range(a.batch*5,a.batch*5+5): state.posts.append(i)
			state.posts.sort(); message = "已实放%d/45根，棍位各不重复。" % state.posts.size(); return true
		"check_supports":
			if state.posts.size() != 45: return _reject("须45个不同棍位全部有支撑。")
			state.checked = true; message = "45处支撑已逐一检查。图中相邻编号连成环，仅沿边移动。"; return true
		"read_rules":
			state.rules = true; message = "三轮逐棍追逐；被追上或双脚落地判负。棍毁后手可撑地。裁定前不得翻身。"; return true
		"owner_consent":
			if not state.rules: return _reject("先读赌约，再由柳莺莺明确同意以自己的马为注。")
			state.consent = true; message = "柳莺莺同意赌约；失败只重试，不转移马匹所有权。"; return true
		"read_intent":
			if not state.checked or not state.rules or not state.consent or state.collapsed: return _reject("先布棍验撑、读约、取得马主同意。")
			state.intent = true
			var clockwise := posmod(int(state.rival)-int(state.player),45)
			message = "你在%d号，海雨在%d号；从你到他顺时针%d根、逆时针%d根。他在你移动后沿最短环路追4根，途中碰到即捉住；宜沿远离他的方向走。" % [state.player,state.rival,clockwise,45-clockwise]
			return true
		"move_posts":
			if not state.intent or state.collapsed or not a.get("stride") in [1,2,3] or not a.get("direction") in [-1,1]: return _reject("先看对手意图；每轮沿环顺/逆走1—3根。")
			var path := ring_route(state.player,a.stride,a.direction)
			for p in path:
				if not p in state.posts: return _reject("路径经过无支撑棍位。")
				if p == state.rival: state.captured = true
			state.player = path.back()
			var chase := rival_route(state.rival,state.player)
			var actual: Array = []
			if not state.captured:
				for p in chase:
					actual.append(p); state.rival = p
					if p == state.player: state.captured = true; break
			state.round += 1; state.intent = false
			state.trace.append({"round":state.round,"player_path":path,"rival_path":actual,"captured":state.captured})
			if state.round == 3 and not state.captured: state.collapsed = true; state.posts.clear()
			message = "梁萧沿%s；海雨逐棍沿%s。%s" % [str(path),str(actual),"被追上，请重试。" if state.captured else ("三轮已过，全部棍位折断。" if state.collapsed else "未被追上，请观察下一轮。")]; return true
		"observe_collapse":
			if not state.collapsed: return _reject("棍位尚未折断。")
			state.collapse_seen = true; message = "45棍均毁，海雨双脚落地；标记地面仍可用双手支撑。"; return true
		"support_landing":
			if not state.collapse_seen or a.get("ground") != "marked_ground" or a.get("support") not in ["hands","feet"]: return _reject("先看清棍毁，再选择标记地面的支撑部位。")
			state.landing = a.support; state.feet_ground = a.support == "feet"
			message = "双手撑地，双脚未着地；请由裁判按赌约核对。" if not state.feet_ground else "双脚着地，此轮不合赌约，可重试。"; return true
		"submit":
			if not state.collapsed or state.landing != "hands" or state.round != 3 or state.captured or state.feet_ground: return _reject("须三轮合法避让、棍毁后双手撑地，且从未被捉或双脚落地。")
			state.complete = true; message = "裁判核对逐棍轨迹与手撑姿态，双脚未落地，赌约成立。现在才可翻身站起。"; return true
	return _reject("依阶段布棍、读约、观势、走棍，再处理棍毁后的落地。")

func _hat(a: Dictionary) -> bool:
	if a.type == "collect_willow":
		if not _index(a.get("material"),3) or a.material in state.materials: return _reject("仅有三段已标记柳条，不能重复领取。")
		state.materials.append(a.material); message = "取得柳条%d，一段跨两槽；修的是莺莺原来的柳笠。" % (a.material+1); return true
	if a.type == "weave_slot":
		if state.woven or not _index(a.get("slot"),6) or not a.get("pattern") in ["over","under"]: return _reject("选择六槽之一与上穿/下穿。")
		var slot: int = a.slot
		if not int(slot/2) in state.materials: return _reject("该两槽所需的柳条尚未取得。")
		state.slots[slot] = a.pattern; message = "第%d槽已%s；需上、下交替封住笠沿。" % [slot+1,"上穿" if a.pattern=="over" else "下穿"]; return true
	if a.type == "check_weave":
		if state.slots != ["over","under","over","under","over","under"] or state.materials.size()!=3: return _reject("六槽必须上下交替，每段柳条跨两槽；尚有缺口或错编。")
		state.woven = true; message = "六槽编织吻合，接着试雨检查每处笠沿。"; return true
	if a.type == "rain_test":
		if not state.woven: return _reject("先完成并检查织补，不能只凭试雨按钮宣布修好。")
		state.rain.clear()
		for i in range(6): state.rain.append({"slot":i,"covered":state.slots[i] == ("over" if i%2==0 else "under")})
		state.complete = true; message = "雨滴逐槽试过，六处均无缺口；原柳笠修补完成。"; return true
	return _reject("取三段柳条，织六槽，检查后试雨。")

func _boat(a: Dictionary) -> bool:
	match a.type:
		"collect_stores":
			if state.materials: return _reject("现场木板和三份填料已领，不可重复领取。")
			state.materials = true; message = "从老周现场料堆取得三块编号板与三份填料；不扣行囊铜钱。"; return true
		"transfer_priority":
			if state.load != 2: return _reject("优先货物已卸，不能重复减少载重。")
			state.load = 1; message = "将所选优先货物搬至岸边指定处，剩余载重1；另一种货物尚需现场检查。"; return true
		"seat_board":
			if not state.materials or state.level or not _index(a.get("slot"),3) or not _index(a.get("board"),3): return _reject("先领现场材料，扶正前选择槽位与木板。")
			if a.board != a.slot: return _reject("榫口不合：A对船首、B对中段、C对船尾。")
			if state.boards[a.slot] != "": return _reject("这块板已入榫，不能重复计数。")
			state.boards[a.slot] = ["board_a","board_b","board_c"][a.board]; message = "木板入榫；仍须填料封住该槽缝隙。"; return true
		"fill_seam":
			if not _index(a.get("slot"),3) or state.boards[a.slot]=="" or state.filler[a.slot] or state.level: return _reject("先放对板，每槽只用一份填料，扶正前填好。")
			state.filler[a.slot] = true; message = "一份填料封住该板缝隙。"; return true
		"attach_winch":
			if a.get("anchor") != "dock_willow" or state.anchor: return _reject("仅码头柳树锚点能承力，且不重复挂索。")
			state.anchor = true; message = "柳莺莺把绞索接到码头柳树锚点。"; return true
		"level_hull":
			if not state.anchor or state.load>1 or state.filler != [true,true,true] or state.level: return _reject("先卸载到1、校好三板并封缝、挂好绞索，再扶正。")
			state.level = true; message = "绞索受力将船扶正，接着松索让船自行浮稳。"; return true
		"release_winch":
			if not state.level or state.released: return _reject("扶正后才可松索。")
			state.released = true; message = "已松索，船身水平；逐次观察三个潮汐拍。"; return true
		"tide_tick":
			if not state.released or state.ticks>=3: return _reject("须先扶正并松索，再观察三个独立潮汐拍。")
			var leak := 0
			for i in range(3):
				if state.boards[i] == "" or not state.filler[i]: leak += 1
			var before: int = state.water; state.water += leak; state.ticks += 1
			state.tide_log.append({"tick":state.ticks,"before":before,"after":state.water,"load":state.load,"level":state.level})
			state.complete = state.ticks==3 and state.water==0 and state.level and state.load<=1
			message = "第%d潮汐拍：进水%d→%d。%s" % [state.ticks,before,state.water,"三拍均无渗漏，修船通过。" if state.complete else "继续观察下一拍。"]; return true
	return _reject("领料、卸货、入榫封缝、挂索扶正、松索，再看三拍潮汐。")

func _ledger(a: Dictionary) -> bool:
	match a.type:
		"inspect_account":
			if a.get("field") not in ["principal","interest","demand"] or a.field in state.observations: return _reject("逐项核对三条不同账目，不重复计数。")
			state.observations.append(a.field)
			message = {"principal":"账簿本金10文。","interest":"双方议定利息2文。","demand":"掌柜实际索款15文。"}[a.field]+"此为明确标注的改编示例数字。"; return true
		"sum_account":
			if state.observations.size()!=3 or a.get("principal")!=10 or a.get("interest")!=2 or a.get("total")!=12: return _reject("先核读三项，再以本金10＋议定利息2计算应还总数。")
			state.legal_total=12; state.sum_checked=true; state.difference_checked=false; state.excess=0
			message="10＋2＝12，应还12文；接着与索款15文对读。"; return true
		"compare_account":
			if not state.sum_checked or a.get("demand")!=15 or a.get("legal")!=state.legal_total or a.get("excess")!=15-state.legal_total: return _reject("索款15减应还12，差额还须逐项算清；不能先填最终差额跳过对读。")
			state.excess=a.excess; state.difference_checked=true
			message="15－12＝3，账外多索3文；这项账目证据不自动打败敌人。"; return true
		"submit":
			if not state.sum_checked or not state.difference_checked or state.observations.size()!=3: return _reject("须核读三项、计算应还总数并比对索款差额。")
			state.complete=true; message="示例账目核对完整：应还12文、多索3文；交回现场继续对质。"; return true
	return _reject("核读三项账目，再相加、相减，最后核对全过程。")

func _milestones() -> void:
	if puzzle_id == "trial_ch04_staff" and state.checked: _issue("staff_layout_verified")
	if puzzle_id == "r02" and state.woven: _issue("r02_weave")
	if puzzle_id == "l01" and state.released: _issue("l01_repair")
	if state.complete: _issue(OBJECTIVES[puzzle_id])
func _issue(objective: String) -> void:
	for p in _proofs:
		if p.objective_id == objective: return
	_proofs.append({"resolver_version":VERSION,"controller_version":VERSION,"chapter":"chapter_four","scene_id":SCENES[puzzle_id],"frozen_content_hash":("ch04_ledger_sample_v1_10_plus2_demand15" if puzzle_id=="ledger_ch04_r02" else CONTENT_HASH).sha256_text(),"objective_id":objective,"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted,"validation_results":{"complete_process":true,"no_xp":true}})
	_undo.clear()
func receipt() -> Dictionary: return {} if _proofs.is_empty() else _proofs.back().duplicate(true)
func get_receipts() -> Array: return _proofs.duplicate(true)
func snapshot() -> Dictionary: return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	saved = _normalize(saved)
	if saved.get("version") != VERSION or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary or saved.input_log.size()>MAX_LOG: return false
	var candidate := ChapterFourPuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context): return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		candidate.apply_input(a)
	if candidate.state != saved.state: return false
	puzzle_id=candidate.puzzle_id; attempt_id=candidate.attempt_id; context=candidate.context
	state=candidate.state; input_log=candidate.input_log; _proofs=candidate._proofs; _events=candidate._events; _undo=candidate._undo; message=candidate.message; _initial_hash=candidate._initial_hash
	return true
static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	proof = _normalize(proof)
	if proof.get("puzzle_id") != id or proof.get("attempt_id") != attempt or not proof.get("input_log") is Array: return false
	var r := ChapterFourPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return proof in r.get_receipts()

func next_demo_action() -> Dictionary:
	return _assist_v1_next_action()

# Frozen action semantics. A future UI recommendation algorithm must not change
# how saved assist_stage_v1 entries replay; add a new action/version instead.
func _assist_v1_next_action() -> Dictionary:
	if state.complete: return {}
	match puzzle_id:
		"tile_ch04_intercept":
			if not state.observed: return {"type":"observe_current"}
			if state.missed: return {"type":"retry"}
			if not state.selected or state.vx!=2 or state.dy!=0: return {"type":"set_launch","vx":2,"dy":0}
			if not state.launched: return {"type":"launch"}
			if state.boat_angle==0: return {"type":"current_tick"}
			return {"type":"land","x":9,"y":6}
		"board_ch04_wood":
			var row: int = state.rows.size()
			if row==6: return {"type":"submit"}
			if state.observations.size()==row: return {"type":"observe_cut","cut":row+1}
			for i in range(3):
				if not i in state.groups: return {"type":"split_group","group":i}
			return {"type":"multiply_row","prior":1 if row==0 else COUNTS[row-1],"factor":3,"result":COUNTS[row]}
		"trial_ch04_staff":
			if state.captured or state.feet_ground: return {"type":"retry"}
			if not state.checked:
				for i in range(9):
					if not i*5 in state.posts: return {"type":"place_batch","batch":i}
				return {"type":"check_supports"}
			if not state.rules: return {"type":"read_rules"}
			if not state.consent: return {"type":"owner_consent"}
			if not state.collapsed:
				if not state.intent: return {"type":"read_intent"}
				# Choose the legal move maximizing distance after rival pursuit.
				var best: Dictionary = {}; var score := -1
				for direction in [-1,1]:
					for stride in [1,2,3]:
						var path := ring_route(state.player,stride,direction)
						var target: int = path.back(); var chase := rival_route(state.rival,target)
						if state.rival in path or target in chase: continue
						var distance := mini(posmod(target-int(chase.back()),45),posmod(int(chase.back())-target,45))
						if distance > score: score = distance; best = {"type":"move_posts","stride":stride,"direction":direction}
				return best if not best.is_empty() else {"type":"retry"}
			if not state.collapse_seen: return {"type":"observe_collapse"}
			if state.landing == "": return {"type":"support_landing","ground":"marked_ground","support":"hands"}
			return {"type":"submit"}
		"r02":
			for i in range(3):
				if not i in state.materials: return {"type":"collect_willow","material":i}
			for i in range(6):
				var pattern := "over" if i%2==0 else "under"
				if state.slots[i] != pattern: return {"type":"weave_slot","slot":i,"pattern":pattern}
			return {"type":"rain_test"} if state.woven else {"type":"check_weave"}
		"l01":
			if not state.materials: return {"type":"collect_stores"}
			if state.load>1: return {"type":"transfer_priority"}
			for i in range(3):
				if state.boards[i]=="": return {"type":"seat_board","slot":i,"board":i}
				if not state.filler[i]: return {"type":"fill_seam","slot":i}
			if not state.anchor: return {"type":"attach_winch","anchor":"dock_willow"}
			if not state.level: return {"type":"level_hull"}
			if not state.released: return {"type":"release_winch"}
			return {"type":"tide_tick"}
		"ledger_ch04_r02":
			for field in ["principal","interest","demand"]:
				if not field in state.observations: return {"type":"inspect_account","field":field}
			if not state.sum_checked: return {"type":"sum_account","principal":10,"interest":2,"total":12}
			if not state.difference_checked: return {"type":"compare_account","demand":15,"legal":12,"excess":3}
			return {"type":"submit"}
	return {}

func describe_action(a: Dictionary) -> String:
	match a.get("type",""):
		"observe_current": return "观察浮标漂移与缆索位置"
		"set_launch": return "设推力%d、纵移%d" % [a.vx,a.dy]
		"launch": return "投瓦，计算并显示三跳接触点"
		"current_tick": return "推进一拍水流，观察小船横转"
		"land": return "落到横转后的船尾(%d,%d)" % [a.x,a.y]
		"observe_cut": return "观察第%d次三分剑招" % a.cut
		"split_group": return "把上一行木柴放入第%d子组" % (a.group+1)
		"multiply_row": return "记录%d×%d＝%d" % [a.prior,a.factor,a.result]
		"place_batch": return "布第%d组五根（编号%d—%d）" % [a.batch+1,a.batch*5,a.batch*5+4]
		"check_supports": return "逐一检查45处支撑"
		"read_rules": return "读清捉住与双脚落地判负的赌约"
		"owner_consent": return "听柳莺莺明确同意以马为注"
		"read_intent": return "观察海雨下一轮追逐意图"
		"move_posts": return "%s沿环走%d根，海雨随后逐棍追4根" % ["顺时针" if a.direction==1 else "逆时针",a.stride]
		"observe_collapse": return "观察棍毁与标记地面"
		"support_landing": return "%s撑住标记地面" % ("双手" if a.support=="hands" else "双脚")
		"collect_willow": return "取第%d段现场柳条" % (a.material+1)
		"weave_slot": return "第%d槽%s" % [a.slot+1,"上穿" if a.pattern=="over" else "下穿"]
		"check_weave": return "检查六槽交替织补"
		"rain_test": return "雨滴逐槽检查笠沿缺口"
		"collect_stores": return "从老周料堆取三板与三份填料"
		"transfer_priority": return "将已选优先货物卸往岸上指定处"
		"seat_board": return "将板%s嵌入%s" % [["A","B","C"][a.board],["船首","中段","船尾"][a.slot]]
		"fill_seam": return "用一份填料封%s板缝" % ["船首","中段","船尾"][a.slot]
		"attach_winch": return "将绞索接牢码头柳树"
		"level_hull": return "绞索扶正船体"
		"release_winch": return "松索，检查船能否自行浮稳"
		"tide_tick": return "再观察一个潮汐拍的水位"
		"inspect_account": return "核读"+{"principal":"本金10文","interest":"利息2文","demand":"索款15文"}[a.field]
		"sum_account": return "以10＋2计算应还12文"
		"compare_account": return "以15－12计算多索3文"
		"retry": return "重试本题，从头按规则操作"
		"submit": return "核对所有过程，提交裁定"
	return ""

func _hint() -> String:
	var hints := {
		"tile_ch04_intercept":["先看浮标每跳漂多少格，以及绳的位置。","三跳共须横移9格，每跳推力＋水流1格。","推力2、纵移0；三跳碰绳后，等船横转，再落在(9,6)。"],
		"board_ch04_wood":["取下原木的一剑不是六次三分。","每一招将上一行全部木柴分成三组，每组数量等于上一行。","从1连续乘3六次：3、9、27、81、243、729。协助一次执行一行的真实操作。"],
		"trial_ch04_staff":["图上的边代表合法移动，不能跳过编号直接落地。","初始你在0号，海雨在12号。先看双方编号，朝远离对手的方向走，他随后追4根；切勿迎面靠近。","棍毁后不是无路可走：赌约禁双脚落地，允许双手支撑；需观察后选择手撑。"],
		"r02":["修的是原柳笠，三段柳条各跨两个槽。","依笠沿编号从上穿开始，之后上下交替。","六槽上/下/上/下/上/下；检查后还要试雨。"],
		"ledger_ch04_r02":["先分别看本金、议定利息和实际索款。","本金与议定利息相加才是应还金额，再和实际索款比较。","示例账目：10＋2＝12；15－12＝3。协助仍逐项执行核读与计算。"],
		"l01":["先卸优先货物，再领现场修补材料。","A/B/C分别对首/中/尾，每处一份填料；码头柳树作锚。","三板三缝齐、载重1，挂索扶正后松索，再独立观察三次潮汐。"]}
	return hints[puzzle_id][maxi(0,state.hint-1)]

func instruction() -> String:
	match puzzle_id:
		"tile_ch04_intercept": return "有限投瓦教学模型：起点(1,5)，三跳每跳横移推力＋1，纵移自选。前两跳须在水面4—6行且横坐标≤9，第三跳须碰(10,5)缆索。断缆不等于完成，还须转船和安全落脚。"
		"board_ch04_wood": return "原木初为1。逐招观察、把现有木柴分到三组，填写上一行×3＝本行。六次观察与六行一一对应，最终再验算。"
		"trial_ch04_staff": return "45棍简化环形图论棋盘，不冒充世界距离碰撞。布9组各5棍，验撑、读约、获马主同意。初始你在0号，海雨在12号。每轮你沿边走1—3根，海雨按最短环路追4根，逐根检查捉住。三轮后棍毁，按双脚不落地赌约选择支撑。"
		"r02": return "三段现场柳条各跨两槽，修莺莺原柳笠的六处破沿；上下交替，最后逐槽试雨。不是现实制笠教程，不生成另一顶笠。"
		"ledger_ch04_r02": return "改编示例账目（并非原著精确账数）：本金10文、约定利息2文、掌柜索款15文。逐项核读，再填写应还金额与多索差额；本题只形成账目证据，不替代对质遭遇。"
		"l01": return "现场修舟教学：卸优先货物到岸上，三块匹配板入榫，各用一份填料。将绞索接码头柳树，扶正后松索，三拍潮汐均不进水才通过。不是现实修船教程。"
	return ""
func get_view() -> Dictionary:
	var titles := ["投瓦拦舟 · 三跳与落脚","春色三分 · 六招算木","四十五棍 · 赌约与手撑","柳笠上的雨 · 修原笠","江边失船 · 校板试潮","当铺黑账 · 核读与差额"]
	var next := next_demo_action()
	return {"kind":"chapter_four","puzzle_id":puzzle_id,"title":titles[IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint>0 else "","next_demo":describe_action(next),"next_action":next,"receipt":receipt(),"receipts":get_receipts()}
