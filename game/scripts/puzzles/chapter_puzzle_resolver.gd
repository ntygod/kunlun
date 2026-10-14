class_name ChapterPuzzleResolver
extends RefCounted
## Chapter-two teaching fixtures. Only this rules layer issues proofs; no XP is paid here.
## Saving retains every operation and rebuilds proofs by replay, never trusting saved success.
const VERSION := 1
const MAX_LOG := 4096
const TITLES := ["天地生成解", "太玄两难·上", "太玄两难·下", "双手十指题", "二十八宿周天解", "治河图", "鬼谷子问", "子午线之惑", "日变奇算"]
const WEIGHTS := [512,256,128,64,32,16,8,4,2,1]
const TARGETS := [5,13,42]
const LOSHU := [4,9,2,3,5,7,8,1,6]
const MEASURES := {"front_rod":8, "rear_rod":8, "baseline":600, "front_setback":12, "rear_setback":18, "rod_shadow":4, "peak_shadow":404}
const MEASURE_LABELS := {"front_rod":"近表高", "rear_rod":"远表高", "baseline":"两表间距（100步）", "front_setback":"近表退距", "rear_setback":"远表退距", "rod_shadow":"模型杆影", "peak_shadow":"模型峰影"}
const PIECES := ["一页·题号", "一页·推演", "一页·错处", "二页·题号", "二页·推演", "二页·错处", "三页·题号", "三页·借阴补阳", "三页·错处"]
var puzzle_id := ""
var state: Dictionary = {}
var input_log: Array = []
var _receipts: Dictionary = {}
var message := ""
var attempt_id := ""
var context: Dictionary = {}

func _init(id: String = "") -> void:
	if not id.is_empty(): begin(id)

func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if id in ["ch02_r01","R01"]: id = "r01"
	if id in ["ch02_k01","K01"]: id = "k01"
	if not (id in ["r01","k01","pz01_tenth"] or id in problem_ids()): return false
	puzzle_id = id
	attempt_id = attempt if not attempt.is_empty() else id + ":attempt"
	context = trusted_context.duplicate(true)
	input_log = []
	_receipts = {}
	message = "先观察题面，再动筹验算。"
	state = {"values":[], "hint":0, "assisted":false, "complete":false, "failures":0,"correct_highlight":-1}
	match id:
		"pz01_problem_01": state.values = [0,0,0,0,5,0,0,0,0]
		"pz01_problem_02": state.values = [12,8]
		"pz01_problem_03": state.values = [0,0]
		"pz01_problem_04":
			state.values = [0,0,0,0,0,0,0,0,0,0]
			state.target_index = 0
			state.proofs = []
		"pz01_problem_05":
			state.values = [0]
			state.observations = [0]
		"pz01_problem_06": state.values = [0,0,0,0]
		"pz01_problem_07": state.values = [0,0,0,0,0]
		"pz01_problem_08": state.values = [0,0]
		"pz01_problem_09": state.values = [0,0,0,0,0]
		"pz01_tenth":
			state.extensions = 0
			state.tracks = 1
			state.overload = false
			state.stopped = false
		"r01":
			state.values = [-1,-1,-1,-1,-1,-1,-1,-1,-1]
			state.matched = false
			state.segment = ""
			state.method = ""
			state.binding = []
			state.correct_highlight = -1
		"k01":
			state.observed = {}
			state.method = ""
			# baseline conversion, heights, setbacks, model shadows, result in chi/zhang
			state.values = [0,0,0,0,0,0,0,0,0,0]
			state.formula = ""
			state.proofs = {}
	return true

static func problem_ids() -> Array:
	var ids: Array = []
	for n in range(1,10): ids.append("pz01_problem_%02d" % n)
	return ids

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or input_log.size() >= MAX_LOG: return {"ok":false,"message":"操作记录已达安全上限，请重开此题。"}
	if not _safe_action(action): return {"ok":false,"message":"操作格式无效。"}
	input_log.append({"action":action.duplicate(true),"context":_record_context()})
	state.correct_highlight = -1
	var ok := _operate(action)
	if not ok:
		state.failures += 1
		if "assist_ch02_trial_reflection" in context.get("assist_flags",[]): state.correct_highlight = _verified_component()
	return {"ok":ok,"message":message,"receipt":receipt(),"receipts":get_receipts(),"view":get_view()}

func _safe_action(a: Dictionary) -> bool:
	if not a.get("type",null) is String or a.size() > 8: return false
	for key in a:
		if not key is String: return false
		var v: Variant = a[key]
		if not (v is String or v is int or v is float or v is bool): return false
		if v is String and v.length() > 160: return false
		if (v is int or v is float) and (not is_finite(float(v)) or absf(float(v)) > 1000000): return false
	return true

func _operate(a: Dictionary) -> bool:
	var kind: String = a.type
	if kind == "hint":
		state.hint = mini(3,int(state.hint)+1)
		message = _hint()
		return true
	if state.complete and puzzle_id != "k01": return _reject("本题已留存验算，不重复结算。")
	if kind == "reset":
		if puzzle_id == "pz01_tenth": return _reject("第十算保留已见的发散；请听晓霜劝慰后歇手。")
		var fresh := ChapterPuzzleResolver.new(puzzle_id)
		fresh.state.hint = state.hint
		fresh.state.assisted = state.assisted
		fresh.state.failures = state.failures
		if puzzle_id == "k01": fresh.state.observed = state.observed.duplicate(true)
		state = fresh.state.duplicate(true)
		_receipts.clear()
		message = "筹盘已重置，现场记录与协助标记保留，不扣经验或生命。"
		return true
	if kind == "demo_next":
		if state.hint < 3 or not puzzle_id.begins_with("pz01_problem_"): return _reject("先逐层看提示；支线与第十算不提供自动解题。")
		state.assisted = true
		var next := _demo_action()
		if next.is_empty(): return _reject("演示已完成。")
		var result := _operate(next)
		message = "协助演示：" + message
		return result
	if kind == "set":
		if not _integer(a.get("index")) or not _integer(a.get("value")): return _reject("筹数须为整数。")
		var index := int(a.index)
		var value := int(a.value)
		if index < 0 or index >= state.values.size(): return _reject("没有这个筹位。")
		if puzzle_id in ["pz01_problem_02","pz01_problem_04","pz01_problem_05","pz01_tenth","r01"]: return _reject("请使用这件机关的移动或拨动操作。")
		if value < 0 or value > 100000: return _reject("筹数超出模型范围。")
		if puzzle_id == "pz01_problem_01":
			if value > 9 or index == 4 or value == 5: return _reject("中宫固定五，其余格填一至九。")
			if value != 0:
				var old: int = state.values.find(value)
				if old >= 0: state.values[old] = 0
		state.values[index] = value
		message = "第%d筹位记为%d。" % [index+1,value]
		return true
	if kind == "submit": return _submit()
	match puzzle_id:
		"pz01_problem_02":
			if kind == "transfer" and _integer(a.get("amount")) and abs(int(a.amount)) == 1:
				var amount := int(a.amount)
				if state.values[0]-amount < 0 or state.values[1]+amount < 0: return _reject("盘中已无筹可移。")
				state.values[0] -= amount
				state.values[1] += amount
				message = "移一筹；两盘现为%d与%d，总数仍为20。" % state.values
				return true
		"pz01_problem_04":
			if kind == "toggle" and _integer(a.get("index")) and int(a.index) >= 0 and int(a.index) < 10:
				state.values[int(a.index)] = 1-int(state.values[int(a.index)])
				message = "此刻十指合数：%d。" % _binary_value()
				return true
		"pz01_problem_05":
			if kind == "advance" and _integer(a.get("steps")) and int(a.steps) == 7:
				if state.observations.size() >= 5: return _reject("四次观测已记，提交验算即可。")
				state.values[0] = (int(state.values[0])+7)%28
				state.observations.append(state.values[0])
				message = "转七宿到%d，已记录%d次转动。" % [state.values[0],state.observations.size()-1]
				return true
		"pz01_tenth":
			if kind == "extend":
				state.extensions = mini(4,int(state.extensions)+1)
				state.tracks = 1+int(state.extensions)*3
				state.overload = true
				_issue("pz01_tenth_overload_seen",{"bounded_tracks":state.tracks,"finite_solution":false})
				message = "新添的关系又引出未知星轨。此刻的筹法推不尽；先听晓霜的话。"
				return true
			if kind == "stop" and state.overload and context.get("authorize_acceptance",false):
				state.stopped = true
				state.complete = true
				_issue("accept_imperfection_choice",{"stopped_voluntarily":true,"finite_solution":false})
				message = "主动歇手，留下未解的第十算。前九算的成果不因此失去。"
				return true
		"r01": return _r01(a)
		"k01": return _k01(a)
	return _reject("此操作不适用于眼前机关。")

func _submit() -> bool:
	var v: Array = state.values
	var valid := false
	var proof: Dictionary = {}
	match puzzle_id:
		"pz01_problem_01":
			var lines: Array = []
			for row in range(3): lines.append(v[row*3]+v[row*3+1]+v[row*3+2])
			for col in range(3): lines.append(v[col]+v[col+3]+v[col+6])
			lines.append(v[0]+v[4]+v[8]); lines.append(v[2]+v[4]+v[6])
			var sorted := v.duplicate(); sorted.sort()
			valid = sorted == [1,2,3,4,5,6,7,8,9] and v[4] == 5
			for sum in lines: valid = valid and sum == 15
			proof = {"eight_line_sums":lines,"unique_1_to_9":sorted == [1,2,3,4,5,6,7,8,9]}
			message = "横竖斜八线为：%s；每线须十五，筹数不可重复。" % str(lines)
		"pz01_problem_02":
			valid = v == [10,10]
			proof = {"total":v[0]+v[1],"equal":v[0] == v[1]}
			message = "两盘需各十筹，并保留原来二十筹。"
		"pz01_problem_03":
			valid = v[0]+v[1] == 9 and v[0]-v[1] == 3
			proof = {"sum":v[0]+v[1],"difference":v[0]-v[1]}
			message = "两数相加须九，相减须三。"
		"pz01_problem_04":
			var target: int = TARGETS[int(state.target_index)]
			if _binary_value() != target: return _reject("当前合数%d，目标%d；按512到1的权重重新屈伸十指。" % [_binary_value(),target])
			state.proofs.append({"target":target,"bits":v.duplicate(),"sum":_binary_value()})
			if state.target_index < 2:
				state.target_index += 1
				message = "这一组验过；保留当前十指，请拨到%d。" % TARGETS[int(state.target_index)]
				return true
			valid = true
			proof = {"targets":state.proofs.duplicate(true)}
		"pz01_problem_05":
			valid = state.observations == [0,7,14,21,0]
			proof = {"observations":state.observations.duplicate()}
			message = "从零位出发，每次转七宿；需记录四次，回到零位。"
		"pz01_problem_06":
			valid = v == [12,3,2,72] and v[0]*v[1]*v[2] == v[3]
			proof = {"length_width_depth":v.slice(0,3),"cubic_chi":v[3]}
			message = "模型长12尺、宽3尺、深2尺；体积＝长×宽×深，单位立方尺。"
		"pz01_problem_07":
			valid = v == [1,3,6,10,20] and v[0]+v[1]+v[2]+v[3] == v[4]
			proof = {"layers":v.slice(0,4),"sum":v[4]}
			message = "逐层按一、三、六、十筹搭垒，再合计全部筹数。"
		"pz01_problem_08":
			valid = v == [100,36000] and v[0]*360 == v[1]
			proof = {"li_per_degree":v[0],"model_full_circle_li":v[1]}
			message = "虚构比例模型：3度对应300里，先求每度，再乘360。不是实测地球。"
		"pz01_problem_09":
			var sums := [v[0]+v[1],v[1]+v[2],v[2]+v[3],v[3]+v[4],v[0]+v[4]]
			valid = sums == [3,5,7,9,6]
			proof = {"substitutions":sums,"required":[3,5,7,9,6]}
			message = "逐式代回：a+b=3，b+c=5，c+d=7，d+e=9，a+e=6。"
		"r01":
			valid = v == [0,1,2,3,4,5,6,7,8]
			state.matched = valid
			state.correct_highlight = -1
			if not valid:
				for i in range(9):
					if v[i] == i:
						state.correct_highlight = i
						break
				return _reject("按页号与墨线接续拼回九片。仅标亮确实放对的一片；没有正确片时不标亮。")
			message = "三张已拼回。请辨认第三页的可用推演中段。"
			return true
		"k01": return _submit_geometry()
		_: return _reject("这里没有有限答案可提交；请完成观察并主动歇手。")
	if not valid: return false
	state.complete = true
	_issue(puzzle_id,proof)
	message = "验算成立，已保存过程。此为简化教学样例，后续研究另有岁月。"
	return true

func _r01(a: Dictionary) -> bool:
	match a.type:
		"place_piece":
			if not _integer(a.get("slot")) or not _integer(a.get("piece")): return _reject("请选择残片与槽位。")
			var slot := int(a.slot); var piece := int(a.piece)
			if slot < 0 or slot > 8 or piece < 0 or piece > 8 or not state.method.is_empty(): return _reject("此处不能放这张残片。")
			var old: int = state.values.find(piece)
			if old >= 0: state.values[old] = -1
			state.values[slot] = piece
			state.correct_highlight = -1
			state.matched = false
			state.segment = ""
			_receipts.erase("r01_three_pages_matched")
			message = "残片已移入第%d页第%d段。" % [slot/3+1,slot%3+1]
			return true
		"select_segment":
			if not state.matched or a.get("segment","") != "borrow_yin_to_balance_yang": return _reject("先拼全三页，再辨认第三页可用的借阴补阳中段。")
			state.segment = a.segment
			_issue("r01_three_pages_matched",{"nine_pieces":state.values.duplicate(),"third_segment":state.segment})
			message = "结论虽错，中段借阴补阳仍可留用。"
			return true
		"method":
			if state.segment.is_empty() or a.get("value","") not in ["keep_all","keep_later"]: return _reject("先辨认有用中段，再决定如何留稿。")
			if not state.method.is_empty(): return _reject("留稿方式已记，不重复改变代存页归属。")
			state.method = a.value
			state.choice_id = "ch02_r01_" + a.value
			_issue("r01_keep_method_recorded",{"method":state.method,"first_page_owner":"char_hua_xiaoshuang" if state.method == "keep_later" else "char_liang_xiao"})
			message = "开始装订：先糊封面，再穿线，最后题名；末页留白。"
			return true
		"bind":
			var stages := ["paste_cover","thread","title"]
			if state.method.is_empty() or state.binding.size() >= 3 or a.get("step","") != stages[state.binding.size()]: return _reject("按糊封面、穿线、题名的次序装订。")
			state.binding.append(a.step)
			message = "装订已完成%d/3步。" % state.binding.size()
			if state.binding.size() == 3:
				state.complete = true
				_issue("r01_book_bound",{"binding":state.binding.duplicate(),"blank_last_page":true,"method":state.method})
			return true
	return _reject("请操作残片、辨认中段或装订。")

func _k01(a: Dictionary) -> bool:
	match a.type:
		"observe":
			var key: String = a.get("key","")
			if not MEASURES.has(key): return _reject("此测点不存在。")
			var observed: Variant = context.get("observed_measurements",{})
			if not (observed is Array or observed is Dictionary) or not key in observed: return _reject("请先走到这个现场测点观察。")
			if observed is Dictionary and observed[key] != MEASURES[key]: return _reject("现场量值不匹配。")
			state.observed[key] = MEASURES[key]
			message = "%s：%d尺，已记录现场量值。" % [MEASURE_LABELS[key],MEASURES[key]]
			if state.observed.size() == MEASURES.size(): _issue("k01_measurements_recorded",{"observations":state.observed.duplicate(true)})
			return true
		"method":
			if state.observed.size() != MEASURES.size(): return _reject("请先在露台七个测点记录双表、基线、退距和模型影长。")
			if a.get("value","") not in ["double_difference","similar_triangles"]: return _reject("选择重差或相似三角形。")
			state.method = a.value
			state.choice_id = "ch02_k01_" + a.value
			state.formula = ""
			_issue("k01_method_recorded",{"method":state.method})
			message = "先换算单位，填入现场数值，再选与该方法相符的等式。"
			return true
		"formula":
			if state.method.is_empty(): return _reject("先记录测量并选择方法。")
			if a.get("value","") not in ["rod_plus_baseline_over_difference","shadow_ratio","baseline_over_sum"]: return _reject("等式无效。")
			state.formula = a.value
			message = "等式已记；提交时将代入检查。"
			return true
	return _reject("请使用现场量值建立等式。")

func _submit_geometry() -> bool:
	if state.observed.size() != MEASURES.size() or state.method.is_empty(): return _reject("没有完整现场测量与方法，不能提交。")
	var v: Array = state.values
	# 100 bu*6=600 chi; 8 chi rods; 12/18 setbacks; 4/404 shadows; chi/zhang conversion.
	if v.slice(0,8) != [600,8,8,12,18,4,404,10]: return _reject("请核对现场量值与单位：一步六尺，一丈十尺，两根表木都八尺。")
	if v[4] <= v[3]: return _reject("后退距必须大于前退距；差为零或负不能使用重差式。")
	var height_a := float(v[1])+float(v[1]*v[0])/float(v[4]-v[3])
	var height_b := float(v[1]*v[6])/float(v[5])
	var expected_formula := "rod_plus_baseline_over_difference" if state.method == "double_difference" else "shadow_ratio"
	if state.formula != expected_formula: return _reject("所选等式与测量方法不符。重差取退距之差，相似取对应影长比。")
	# Last field is remaining chi after 80 whole zhang, avoids floating point text entry.
	if v[8] != 808 or v[9] != 8 or not is_equal_approx(height_a,height_b): return _reject("峰高以尺记，并换成80丈又几尺；两法应求得同一高度。")
	var proof := {"method":state.method,"formula":state.formula,"height_chi":height_a,"crosscheck_chi":height_b,"height_zhang":80.8,"front_distance_chi":1200,"observations":state.observed.duplicate(true),"inputs":v.duplicate()}
	state.proofs[state.method] = proof
	state.complete = true
	_issue("k01_double_difference_proof" if state.method == "double_difference" else "k01_similar_triangle_proof",proof)
	_issue("k01_geometry_verified",proof)
	message = "两法互验：808尺＝80丈8尺。几何札记已存；可切换另一方法复算。"
	return true

func _integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floorf(float(v))

func _binary_value() -> int:
	var result := 0
	for i in range(10): result += int(state.values[i])*WEIGHTS[i]
	return result

func _reject(reason: String) -> bool:
	message = reason
	return false

func _issue(id: String, validation: Dictionary) -> void:
	_receipts[id] = {"objective_id":id,"problem_id":puzzle_id,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"final_state":state.duplicate(true),"validation_results":validation.duplicate(true),"assisted":state.assisted,"resolver_version":VERSION,"choice_id":state.get("choice_id","")}

func receipt() -> Dictionary:
	if not state.get("complete",false): return {}
	var id := puzzle_id
	if id == "pz01_tenth": id = "accept_imperfection_choice"
	if id == "r01": id = "r01_book_bound"
	if id == "k01": id = "k01_geometry_verified"
	return _receipts.get(id,{}).duplicate(true)

func get_receipts() -> Array:
	return _receipts.values().duplicate(true)

func snapshot() -> Dictionary:
	return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}

func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	saved = _normalize(saved)
	trusted_context = _normalize(trusted_context)
	if saved.get("version") != VERSION or not saved.get("puzzle_id") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary: return false
	if saved.input_log.size() > MAX_LOG: return false
	var candidate := ChapterPuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,str(saved.get("attempt_id","")),trusted_context): return false
	for entry in saved.input_log:
		if not candidate._replay_entry(entry,trusted_context): return false
	candidate.set_context(trusted_context)
	if _normalize(candidate.state) != saved.state: return false
	puzzle_id = candidate.puzzle_id
	attempt_id = candidate.attempt_id
	context = candidate.context.duplicate(true)
	state = candidate.state.duplicate(true)
	input_log = candidate.input_log.duplicate(true)
	_receipts = candidate._receipts.duplicate(true)
	message = candidate.message
	return true

func _hint() -> String:
	var hints := ["观察实物上的筹数、刻度与题面条件。", instruction(), "可选择“演示下一步”，每次执行一次真实操作，再用同一规则验算。"]
	if puzzle_id == "pz01_tenth": return "此刻的筹法推不尽这道题。先歇手，听听晓霜的话。"
	if puzzle_id == "r01": return "每页依题号、推演墨线、错处续接；第三页的借阴补阳中段可用。"
	if puzzle_id == "k01": return "辅助线：两表等高，测线水平；重差取18−12，相似取404/4。请亲自记录、代入与验算。"
	return hints[maxi(0,int(state.hint)-1)]

func instruction() -> String:
	match puzzle_id:
		"pz01_problem_01": return "放置1至9筹，五居中，横三线、竖三线、两条斜线皆十五。点击格位后选筹；重复筹会移走原位。"
		"pz01_problem_02": return "左盘十二，右盘八；每次移一筹，直到两盘相等。"
		"pz01_problem_03": return "摆两列筹a、b，使a+b=9，a−b=3。"
		"pz01_problem_04": return "十指从左至右权重512到1；点击屈伸，依次表示5、13、42，每组分别验算。"
		"pz01_problem_05": return "二十八宿盘：从0出发，每次转7宿，记录四次转动后回0。"
		"pz01_problem_06": return "纸上渠模型长12尺、宽3尺、深2尺；填量值并计算体积（立方尺），不是已完成治河。"
		"pz01_problem_07": return "四层三角筹垒按1、3、6、10筹搭起，再记录总数。"
		"pz01_problem_08": return "虚构比例模型中3度对应300里；每度多少里？一周360度又多少里？不是实测地球。"
		"pz01_problem_09": return "五元简化模型：a+b=3，b+c=5，c+d=7，d+e=9，a+e=6。逐列排筹并代回全部等式。"
		"pz01_tenth": return "拨筹延展关系，观察新未知星轨。此演示有界，不声称证明数学不可解；主动歇手留下此题。"
		"r01": return "九片拼回三页：每页题号→推演→错处。拼全后辨第三页可用中段，再选择留稿方式、糊封面、穿线、题名。"
		"k01": return "先在露台记录七个测点。一步六尺，一丈十尺。选择重差或模型影长比例，代入量值验同一峰高。真实山脚不可达，影长来自标定模型。"
	return ""

func _demo_action() -> Dictionary:
	var solution: Array = []
	match puzzle_id:
		"pz01_problem_01": solution = LOSHU
		"pz01_problem_02":
			if state.values[0] != 10: return {"type":"transfer","amount":1 if state.values[0]>10 else -1}
		"pz01_problem_03": solution = [6,3]
		"pz01_problem_04":
			var target: int = TARGETS[int(state.target_index)]
			for i in range(10):
				if int(state.values[i]) != (1 if (target & WEIGHTS[i]) != 0 else 0): return {"type":"toggle","index":i}
		"pz01_problem_05":
			if state.observations.size() < 5: return {"type":"advance","steps":7}
		"pz01_problem_06": solution = [12,3,2,72]
		"pz01_problem_07": solution = [1,3,6,10,20]
		"pz01_problem_08": solution = [100,36000]
		"pz01_problem_09": solution = [1,2,3,4,5]
	for i in range(solution.size()):
		if state.values[i] != solution[i]: return {"type":"set","index":i,"value":solution[i]}
	return {"type":"submit"}

func get_view() -> Dictionary:
	var title := ""
	if puzzle_id in problem_ids(): title = TITLES[int(puzzle_id.right(2))-1]
	elif puzzle_id == "pz01_tenth": title = "元外之元 · 留一道空白"
	elif puzzle_id == "r01": title = "未合的算册"
	elif puzzle_id == "k01": title = "日影初算"
	return {"puzzle_id":puzzle_id,"title":title,"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.get("hint",0)>0 else "","weights":WEIGHTS.duplicate(),"target":TARGETS[int(state.get("target_index",0))],"piece_labels":PIECES.duplicate(),"measure_labels":MEASURE_LABELS.duplicate(),"receipt":receipt(),"authorize_acceptance":context.get("authorize_acceptance",false),"reflection_highlight":state.get("correct_highlight",-1),"geometry_guides":"assist_ch02_geometry_guides" in context.get("assist_flags",[])}

func set_context(trusted_context: Dictionary) -> void:
	context = trusted_context.duplicate(true)

static func replay_receipt(proof: Dictionary, expected_id: String, expected_attempt: String, trusted_context: Dictionary = {}) -> bool:
	proof = _normalize(proof)
	trusted_context = _normalize(trusted_context)
	if proof.get("puzzle_id","") != expected_id or proof.get("attempt_id","") != expected_attempt or not proof.get("input_log") is Array: return false
	if proof.input_log.size() > MAX_LOG: return false
	var candidate := ChapterPuzzleResolver.new()
	if not candidate.begin(expected_id,expected_attempt,trusted_context): return false
	for entry in proof.input_log:
		if not candidate._replay_entry(entry,trusted_context): return false
	var rebuilt: Dictionary = candidate._receipts.get(proof.get("objective_id",""),{})
	return not rebuilt.is_empty() and _normalize(rebuilt) == proof

func _record_context() -> Dictionary:
	return {"observed_measurements":context.get("observed_measurements",{}).duplicate(true),"authorize_acceptance":bool(context.get("authorize_acceptance",false)),"assist_flags":context.get("assist_flags",[]).duplicate()}

func _replay_entry(entry: Variant, trusted_context: Dictionary) -> bool:
	if not entry is Dictionary or not entry.get("action") is Dictionary or not entry.get("context") is Dictionary: return false
	if not _safe_action(entry.action): return false
	var recorded: Dictionary = entry.context
	if recorded.get("authorize_acceptance",false) and not trusted_context.get("authorize_acceptance",false): return false
	var flags: Variant = recorded.get("assist_flags",[])
	if not flags is Array: return false
	for flag in flags:
		if not flag in trusted_context.get("assist_flags",[]): return false
	var observations: Variant = recorded.get("observed_measurements",{})
	var permitted: Variant = trusted_context.get("observed_measurements",{})
	if not (observations is Dictionary or observations is Array) or not (permitted is Dictionary or permitted is Array): return false
	for key in observations:
		if not key in permitted: return false
		if observations is Dictionary and permitted is Dictionary and observations[key] != permitted[key]: return false
	context = recorded.duplicate(true)
	apply_input(entry.action)
	return true

static func _normalize(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floorf(value): return int(value)
	if value is Array:
		var out: Array = []
		for item in value: out.append(_normalize(item))
		return out
	if value is Dictionary:
		var out: Dictionary = {}
		for key in value: out[key] = _normalize(value[key])
		return out
	return value

func _verified_component() -> int:
	# A highlight is a proven local component, never a solved-board assertion.
	# Only center 5 is invariant across all eight legal Lo Shu orientations.
	if puzzle_id == "pz01_problem_01": return 4 if state.values[4] == 5 else -1
	var expected: Array = []
	match puzzle_id:
		"pz01_problem_02": expected = [10,10]
		"pz01_problem_03": expected = [6,3]
		"pz01_problem_04":
			var target: int = TARGETS[int(state.target_index)]
			for weight in WEIGHTS: expected.append(1 if (target & weight) != 0 else 0)
		"pz01_problem_05":
			return 0 if state.observations.size() > 1 and state.values[0] == ((state.observations.size()-1)*7)%28 else -1
		"pz01_problem_06": expected = [12,3,2,72]
		"pz01_problem_07": expected = [1,3,6,10,20]
		"pz01_problem_08": expected = [100,36000]
		"pz01_problem_09": expected = [1,2,3,4,5]
		"r01": expected = [0,1,2,3,4,5,6,7,8]
		"k01":
			if state.observed.size() != MEASURES.size(): return -1
			expected = [600,8,8,12,18,4,404,10,808,8]
	for i in range(expected.size()):
		if state.values[i] == expected[i]: return i
	return -1
