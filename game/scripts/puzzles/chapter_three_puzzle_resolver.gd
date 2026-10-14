class_name ChapterThreePuzzleResolver
extends RefCounted
## Frozen finite teaching models, not a reconstruction of the novel's equations.
const VERSION := 1
const MAX_LOG := 4096
const LIMIT := 1000000
const IDS := ["interaction_ch03_tea", "trial_ch03_qingyuan", "board_ch03_six", "board_ch03_seven", "board_ch03_twelve"]
const SIZES := {"board_ch03_six":6,"board_ch03_seven":7,"board_ch03_twelve":12}
const OBJECTIVES := {"interaction_ch03_tea":"tea_shared","trial_ch03_qingyuan":"qingyuan_trial","board_ch03_six":"reckoning_six","board_ch03_seven":"reckoning_seven","board_ch03_twelve":"reckoning_twelve"}
const TRIAL := ["observe_transition","guard_then_retreat","yield_and_withdraw"]
var puzzle_id := ""
var attempt_id := ""
var context: Dictionary = {}
var state: Dictionary = {}
var input_log: Array = []
var message := ""
var _undo: Array = []
var _events: Array = []
var _proof: Dictionary = {}
var _initial_hash := ""
var _last_row_change := ""

func _init(id: String = "") -> void:
	if not id.is_empty(): begin(id)

func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if not id in IDS: return false
	puzzle_id = id
	attempt_id = attempt if not attempt.is_empty() else id + ":attempt"
	context = trusted_context.duplicate(true)
	state = {"hint":0,"assisted":false,"complete":false,"failures":0}
	input_log = []; _undo = []; _events = []; _proof = {}; _last_row_change = ""
	if id == IDS[0]: state.merge({"cups":[0,0,0],"tray":3})
	elif id == IDS[1]: state.step = 0
	else:
		var n: int = SIZES[id]
		state.merge({"columns":[],"matrix":[],"values":[],"substitutions":[],"eliminations":0})
		for i in range(n):
			state.columns.append(-1); state.values.append([])
			var row: Array = []
			for j in range(n): row.append([1 if j == i or (j == i+1 and i < n-1) else 0,1])
			row.append([2*i+3 if i < n-1 else n,1]); state.matrix.append(row)
	message = "请从第一步开始；错误可撤回，不扣生命或经验。"
	_initial_hash = _hash(state)
	return true

func set_context(trusted_context: Dictionary) -> void:
	context = trusted_context.duplicate(true)

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

static func _hash(v: Variant) -> String:
	return JSON.stringify(_normalize(v)).sha256_text()

static func _integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and abs(float(v)) <= LIMIT

static func rational(a: int, b: int = 1) -> Array:
	if b == 0 or absi(a) > LIMIT*LIMIT or absi(b) > LIMIT*LIMIT: return []
	if b < 0: a = -a; b = -b
	var x := absi(a); var y := b
	while y != 0:
		var t := x % y; x = y; y = t
	a = a / x; b = b / x
	if absi(a) > LIMIT or b > LIMIT: return []
	return [a,b]

static func _mul(a: Array, b: Array) -> Array:
	if a.is_empty() or b.is_empty(): return []
	return rational(a[0]*b[0],a[1]*b[1])

static func _add(a: Array, b: Array) -> Array:
	if a.is_empty() or b.is_empty(): return []
	return rational(a[0]*b[1]+b[0]*a[1],a[1]*b[1])

static func text_fraction(a: Array) -> String:
	if a.is_empty(): return "未填"
	return str(a[0]) if a[1] == 1 else "%d/%d" % a

func _safe(a: Dictionary) -> bool:
	if not a.get("type") is String or a.size() > 8: return false
	for k in a:
		if not k is String: return false
		var v: Variant = a[k]
		if v is String:
			if v.length() > 100: return false
		elif not _integer(v): return false
	return true

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(action): return {"ok":false,"message":"操作格式无效。"}
	# Campaign chronology feeds JSON-decoded numbers directly, not only through restore.
	action = _normalize(action)
	if input_log.size() >= MAX_LOG:
		if action.type != "reset" or state.complete:
			return {"ok":false,"message":"本轮记录已满；请选择重新开始本题，提示和协助标记会保留。"}
		# End the exhausted, unfinished round. This bounded genesis entry carries only
		# non-solving metadata, never a matrix, values, substitutions, or completion.
		# A new proof must replay every solving operation in the new round.
		var restart := {"type":"restart_after_limit","hint":int(state.hint),"assisted":1 if state.assisted else 0,"failures":int(state.failures),"discarded_log_hash":_hash(input_log)}
		var old_id := puzzle_id; var old_attempt := attempt_id; var old_context := context.duplicate(true)
		begin(old_id,old_attempt,old_context)
		return apply_input(restart)
	var before := state.duplicate(true)
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	if not ok: state.failures = mini(LIMIT,state.failures+1)
	elif action.type not in ["hint","undo","reset","submit","restart_after_limit"] and not state.complete:
		_undo.append(before)
		if _undo.size() > 256: _undo.pop_front()
	_events.append({"action":action.type,"ok":ok,"before":_hash(before),"after":_hash(state)})
	if state.complete and _proof.is_empty(): _issue()
	return {"ok":ok,"message":message,"receipt":receipt(),"receipts":get_receipts(),"view":get_view()}

func _reject(reason: String) -> bool:
	message = reason
	return false

func _operate(a: Dictionary) -> bool:
	if a.type == "restart_after_limit":
		if input_log.size() != 1 or a.size() != 5 or not _integer(a.get("hint")) or not _integer(a.get("assisted")) or not _integer(a.get("failures")):
			return _reject("重开摘要只能作为新一轮的首条记录。")
		if a.hint < 0 or a.hint > 3 or a.assisted not in [0,1] or a.failures < 0 or not a.get("discarded_log_hash") is String or a.discarded_log_hash.length() != 64:
			return _reject("重开摘要格式无效。")
		for c in a.discarded_log_hash:
			if not c in "0123456789abcdef": return _reject("重开摘要格式无效。")
		state.hint = a.hint; state.assisted = a.assisted == 1; state.failures = a.failures
		message = "旧轮记录已封存摘要，题板重新开始；提示和协助标记保留，仍须完成全部操作。"
		return true
	if state.complete: return _reject("已完成验算，请收起题板继续。")
	if a.type == "hint":
		state.hint = mini(3,state.hint+1); message = _hint(); return true
	if a.type == "undo":
		if _undo.is_empty(): return _reject("还没有可撤回的操作。")
		var assisted: bool = state.assisted; var hint: int = state.hint; var failures: int = state.failures
		state = _undo.pop_back(); state.assisted = assisted; state.hint = hint; state.failures = failures
		_last_row_change = ""
		message = "已撤回上一步；可重新尝试。"; return true
	if a.type == "reset":
		var fresh := ChapterThreePuzzleResolver.new(puzzle_id)
		fresh.state.hint = state.hint; fresh.state.assisted = state.assisted; fresh.state.failures = state.failures
		state = fresh.state; _undo.clear(); _last_row_change = ""; message = "已重置题板。"; return true
	if a.type in ["demo_next","demo_next_explained"]:
		if state.hint < 3: return _reject("先阅读三层提示，再主动选择演示。")
		var next := _legacy_demo_action() if a.type == "demo_next" else next_demo_action()
		if next.is_empty(): return _reject("请撤回或重置后尝试演示。")
		state.assisted = true
		var result := _operate(next)
		message = "协助：%s。%s" % [describe_action(next),message]
		return result
	if puzzle_id == IDS[0]:
		if a.type == "tea_transfer" and _index(a.get("cup"),3) and a.get("amount") in [-1,1]:
			var i := int(a.cup); var amount := int(a.amount)
			if state.tray-amount < 0 or state.cups[i]+amount < 0: return _reject("茶盘或茶盏里没有可移动的份额。")
			state.cups[i] += amount; state.tray -= amount; message = "移一份茶；多放的可取回。"; return true
		if a.type == "submit":
			if state.cups != [1,1,1] or state.tray != 0: return _reject("三盏各一份，茶盘不留余份；多放的取回再分。")
			state.complete = true; message = "三人各得一份茶。"; return true
		return _reject("请移一份茶或取回一份。")
	if puzzle_id == IDS[1]:
		if a.type != TRIAL[state.step]: return _reject("先重看眼前招势，再选择应对；没有死亡或成长结算。")
		state.step += 1; state.complete = state.step == 3
		message = "清渊退让认输，视角回到梁萧。" if state.complete else "招势已变，请观察下一步。"
		return true
	return _math(a)

func _index(v: Variant, n: int) -> bool:
	return _integer(v) and int(v) >= 0 and int(v) < n

func _assigned() -> bool:
	return not -1 in state.columns

func _reduced() -> bool:
	var pivots: Array = []
	var n: int = SIZES[puzzle_id]
	for row in state.matrix:
		var pivot := -1
		for j in range(n):
			if row[j][0] != 0:
				if pivot >= 0: return false
				pivot = j
		if pivot < 0 or pivot in pivots: return false
		pivots.append(pivot)
	return true

func _math(a: Dictionary) -> bool:
	var n: int = SIZES[puzzle_id]
	if a.type == "assign_symbol_to_column":
		if not _index(a.get("symbol"),n) or not _index(a.get("column"),n): return _reject("请选择符号与列。")
		var old: int = state.columns.find(int(a.symbol))
		if old >= 0: state.columns[old] = -1
		state.columns[int(a.column)] = int(a.symbol)
		state.substitutions.clear(); message = "符号已分列；每个未知数只占一列。"; return true
	if a.type in ["swap_rows","scale_row","subtract_known_row"]:
		if not _assigned(): return _reject("先把所有未知符号分别安放到不同列。")
		if not _index(a.get("row"),n): return _reject("目标行不存在。")
		var r := int(a.row); var source := int(a.get("source",-1))
		if a.type != "scale_row" and (not _index(a.get("source"),n) or source == r): return _reject("必须选择两条不同的行。")
		var original: Array = state.matrix[r].duplicate(true)
		var source_before := _equation(state.matrix[source]) if source >= 0 and source < n else ""
		var changed: Array = []
		if a.type == "swap_rows":
			state.matrix[r] = state.matrix[source]; state.matrix[source] = original
		else:
			if not _integer(a.get("numerator")) or not _integer(a.get("denominator")): return _reject("倍数须填整数分子、非零分母。")
			var q := rational(int(a.numerator),int(a.denominator))
			if q.is_empty() or q[0] == 0: return _reject("倍数必须为非零有理数；不能除以零或超出范围。")
			for j in range(n+1):
				var term := _mul(original[j],q) if a.type == "scale_row" else _add(original[j],_mul(state.matrix[source][j],[-q[0],q[1]]))
				if term.is_empty(): return _reject("数值超出教学模型安全范围，请撤回或换一种消元。")
				# Explicit inverse validates equivalence before committing the whole row.
				var inverse := _mul(term,[q[1],q[0]]) if a.type == "scale_row" else _add(term,_mul(state.matrix[source][j],q))
				if inverse != original[j]: return _reject("变换未通过等价校验。")
				changed.append(term)
			state.matrix[r] = changed
			if a.type == "subtract_known_row": state.eliminations += 1
		_last_row_change = "%s\n变换前：%s" % [describe_action(a),_equation(original)]
		if a.type != "scale_row": _last_row_change += "\n来源行：" + source_before
		_last_row_change += "\n变换后：" + _equation(state.matrix[r])
		if a.type == "swap_rows": _last_row_change += "\n另一行变为：" + _equation(state.matrix[source])
		_last_row_change += "\n等式两侧同时变换，已通过有理数及逆变换校验。"
		state.substitutions.clear(); message = "行变换已通过精确有理数与逆变换校验。"; return true
	if a.type == "enter_value":
		if not _assigned() or not _reduced() or state.eliminations < n-1: return _reject("先分列并消元到每行只剩一个未知数，再填值。")
		if not _index(a.get("symbol"),n) or not _integer(a.get("numerator")) or not _integer(a.get("denominator")): return _reject("请选择未知数并输入分子、分母。")
		var q := rational(int(a.numerator),int(a.denominator))
		if q.is_empty(): return _reject("分母不能为零；数值须在安全范围。")
		state.values[int(a.symbol)] = q; state.substitutions.clear(); message = "数值已记；还需逐式代回原方程。"; return true
	if a.type == "substitute_back":
		if not _index(a.get("row"),n) or not _reduced() or not _assigned() or state.eliminations < n-1: return _reject("先完成分列与消元，再选择原式代回。")
		for value in state.values:
			if value.is_empty(): return _reject("还没有填齐所有未知数。")
		var r := int(a.row)
		var result: Array = _add(state.values[r],state.values[r+1]) if r < n-1 else state.values[r]
		var expected := [2*r+3 if r < n-1 else n,1]
		if result != expected: return _reject("第%d原式左右不等，请修正填值后重新代回。" % (r+1))
		if not r in state.substitutions: state.substitutions.append(r)
		message = "第%d原式：左侧 %s ＝ 右侧 %s，成立。" % [r+1,text_fraction(result),text_fraction(expected)]; return true
	if a.type == "submit":
		if not _assigned() or not _reduced() or state.eliminations < n-1 or state.substitutions.size() != n: return _reject("须亲自分列、合法消元、填值，并逐式代回所有原方程。")
		state.complete = true; message = "有限教学模型验算完毕；这不证明原著完整题目或任意方程可解。"; return true
	return _reject("此输入不能代替分列、消元与代回过程。")

func _equation(row: Array) -> String:
	var terms := ""
	for j in range(row.size()-1):
		var q: Array = row[j]
		if q[0] == 0: continue
		var magnitude := text_fraction([absi(q[0]),q[1]])
		var term := ("" if magnitude == "1" else magnitude + "×") + "x%d" % (j+1)
		if terms.is_empty(): terms = ("−" if q[0] < 0 else "") + term
		else: terms += (" − " if q[0] < 0 else " + ") + term
	return ("0" if terms.is_empty() else terms) + " = " + text_fraction(row[-1])

func next_demo_action() -> Dictionary:
	# New, explicitly versioned UI action. Legacy demo_next transcripts retain
	# their frozen forward algorithm below, including mid-puzzle saves/receipts.
	if not SIZES.has(puzzle_id) or not _assigned(): return _legacy_demo_action()
	var n: int = SIZES[puzzle_id]
	# A row with one unknown is already known. Prefer the last such row and
	# remove that unknown above it; the teaching chain then takes n-1 steps.
	# Row swaps/scalings do not invalidate this test. No triangular assumption.
	for source in range(n-1,-1,-1):
		var column := -1
		var count := 0
		for j in range(n):
			if state.matrix[source][j][0] != 0: column = j; count += 1
		if count != 1: continue
		var pivot: Array = state.matrix[source][column]
		for row in range(n-1,-1,-1):
			if row == source or state.matrix[row][column][0] == 0: continue
			var factor := _mul(state.matrix[row][column],[pivot[1],pivot[0]])
			if not factor.is_empty(): return {"type":"subtract_known_row","row":row,"source":source,"numerator":factor[0],"denominator":factor[1]}
	# General, equivalent Gauss-Jordan recovery when the player has mixed rows.
	# This also normalizes/swaps singleton rows and handles values/substitution.
	return _legacy_demo_action()

func _legacy_demo_action() -> Dictionary:
	if puzzle_id == IDS[0]:
		for i in range(3):
			if state.cups[i] > 1: return {"type":"tea_transfer","cup":i,"amount":-1}
		for i in range(3):
			if state.cups[i] == 0: return {"type":"tea_transfer","cup":i,"amount":1}
		return {"type":"submit"}
	if puzzle_id == IDS[1]: return {"type":TRIAL[mini(state.step,2)]}
	var n: int = SIZES[puzzle_id]
	for i in range(n):
		if state.columns[i] != i: return {"type":"assign_symbol_to_column","symbol":i,"column":i}
	# General Gauss-Jordan steps on the bounded current board, one requested operation at a time.
	for col in range(n):
		if state.matrix[col][col][0] == 0:
			for r in range(col+1,n):
				if state.matrix[r][col][0] != 0: return {"type":"swap_rows","row":col,"source":r}
			return {}
		var pivot: Array = state.matrix[col][col]
		if pivot != [1,1]: return {"type":"scale_row","row":col,"numerator":pivot[1],"denominator":pivot[0]}
		for r in range(n):
			if r != col and state.matrix[r][col][0] != 0:
				var q: Array = state.matrix[r][col]
				return {"type":"subtract_known_row","row":r,"source":col,"numerator":q[0],"denominator":q[1]}
	for i in range(n):
		if state.values[i] != state.matrix[i][n]: return {"type":"enter_value","symbol":i,"numerator":state.matrix[i][n][0],"denominator":state.matrix[i][n][1]}
	for i in range(n):
		if not i in state.substitutions: return {"type":"substitute_back","row":i}
	return {"type":"submit"}

func describe_action(a: Dictionary) -> String:
	match a.get("type",""):
		"assign_symbol_to_column": return "把 x%d 放入第%d列" % [a.symbol+1,a.column+1]
		"swap_rows": return "交换第%d与第%d行" % [a.row+1,a.source+1]
		"scale_row": return "第%d行乘 %s" % [a.row+1,text_fraction([a.numerator,a.denominator])]
		"subtract_known_row": return "第%d行减去第%d行的 %s 倍" % [a.row+1,a.source+1,text_fraction([a.numerator,a.denominator])]
		"enter_value": return "填 x%d ＝ %s" % [a.symbol+1,text_fraction([a.numerator,a.denominator])]
		"substitute_back": return "将所有填值代回第%d原式" % (a.row+1)
		"submit": return "检查全部过程"
	return str(a.type)

func _hint() -> String:
	if puzzle_id == IDS[0]: return "总共三份茶，三盏各放一份；多放可取回。只是分茶互动，没有医疗效果。"
	if puzzle_id == IDS[1]: return "依次观察袖掌转斜、守住后退、认输离场；这是清渊受挫的固定剧情。"
	if state.hint == 1: return "x1、x2 等各代表不同未知数，给每个符号单独一列；列序可自选。"
	if state.hint == 2: return "从末行倒推：例如 x5+x6=11，减去 x6=6，即得 x5=5。整行两侧同时相减，等价不变。"
	return "下方先显示将做的合法操作；只有点“同意协助”才执行一步，并永久记录协助。"

func instruction() -> String:
	if puzzle_id == IDS[0]: return "把茶盘三份茶分到三盏，各一份。可随时取回多放的份额。这是剧情分茶，不是医药教学。"
	if puzzle_id == IDS[1]: return "暂从花清渊视角观察招势并守退认输；无成长、死亡或获胜分支。"
	return "有限教学改编，原著未给完整系数。①符号分列 ②逐行消元，每行只留一个未知数 ③填值 ④逐式代回原式 ⑤检查。不是任意方程可解的证明。"

func get_view() -> Dictionary:
	var titles := ["药王亭 · 分茶","清渊 · 观势守退","牛虱六元示意","北斗七元示意","十二生肖示意"]
	var equations: Array = []
	if SIZES.has(puzzle_id):
		var n: int = SIZES[puzzle_id]
		var display_order: Array = []
		for symbol in state.columns:
			if symbol >= 0: display_order.append(symbol)
		for symbol in range(n):
			if not symbol in display_order: display_order.append(symbol)
		for r in range(n):
			var terms: Array[String] = []
			# Render in the player's column order. Sparse equations wrap, never 12 horizontal cells.
			for col in range(n):
				var symbol: int = display_order[col]
				var q: Array = state.matrix[r][symbol]
				if q[0] != 0: terms.append("(%s)x%d" % [text_fraction(q),symbol+1])
			equations.append("第%d行：%s = %s" % [r+1," + ".join(terms),text_fraction(state.matrix[r][n])])
	var next: Dictionary = next_demo_action() if not state.is_empty() and not state.complete else {}
	return {"kind":"chapter_three","puzzle_id":puzzle_id,"title":titles[IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint > 0 else "","equations":equations,"size":SIZES.get(puzzle_id,0),"last_row_change":_last_row_change,"next_demo":describe_action(next) if not next.is_empty() else "","receipt":receipt()}

func _issue() -> void:
	_proof = {"resolver_version":VERSION,"chapter":"chapter_three","objective_id":OBJECTIVES[puzzle_id],"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted,"validation_results":{"complete_process":true,"no_xp":true}}

func receipt() -> Dictionary:
	return _proof.duplicate(true)

func get_receipts() -> Array:
	return [] if _proof.is_empty() else [receipt()]

func snapshot() -> Dictionary:
	return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}

func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	saved = _normalize(saved)
	if saved.get("version") != VERSION or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary or saved.input_log.size() > MAX_LOG: return false
	var candidate := ChapterThreePuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context): return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		candidate.apply_input(a)
	if candidate.state != saved.state: return false
	puzzle_id = candidate.puzzle_id; attempt_id = candidate.attempt_id; context = candidate.context
	state = candidate.state; input_log = candidate.input_log; _proof = candidate._proof
	_undo = candidate._undo; _events = candidate._events; message = candidate.message; _initial_hash = candidate._initial_hash; _last_row_change = candidate._last_row_change
	return true

static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	proof = _normalize(proof)
	if proof.get("puzzle_id") != id or proof.get("attempt_id") != attempt or not proof.get("input_log") is Array: return false
	var r := ChapterThreePuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return not r.receipt().is_empty() and r.receipt() == proof
