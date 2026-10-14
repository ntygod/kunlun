class_name ChapterFivePuzzleResolver
extends RefCounted
## Versioned finite teaching models; no inventory, rewards, or campaign mutations.
const Optics = preload("res://scripts/puzzles/chapter_five_optics.gd")
const VERSION := 1
const MAX_LOG := 1024
const BOX := "item_ch05_pure_yang_box"
const IDS := ["chain_ch05_linkage","lock_ch05_six","bagua_ch05_reverse","oranges_ch05_hundred","box_ch05_light","box_ch05_reseal"]
const OBJECTIVES := {"chain_ch05_linkage":"chain_triple_verified","lock_ch05_six":"six_locks_opened","bagua_ch05_reverse":"reverse_bagua_verified","oranges_ch05_hundred":"oranges_verified","box_ch05_light":"light_box_opened","box_ch05_reseal":"box_deception_verified"}
const LOCK_DEPTHS := [2,1,3,2,3,1]
const LOCK_DIRECTIONS := [1,-1,1,-1,-1,1]
const TRIGRAMS := ["乾","兑","离","震","巽","坎","艮","坤"]
const MIRRORS := [Vector2(160,64),Vector2(64,64),Vector2(64,128)]
const CONTENT := "ch05_finite_models_v1"
const MODEL_SPEC := {
	"chain_ch05_linkage":{"two_path":[0,1,2,4],"three_path":[0,1,2,3,4],"max_hops":5},
	"lock_ch05_six":{"depths":LOCK_DEPTHS,"directions":LOCK_DIRECTIONS},
	"bagua_ch05_reverse":{"light_source":[32,90],"disc_center":[160,90],"radius":64,"anchor":"west","forward":TRIGRAMS,"reverse":[0,7,6,5,4,3,2,1]},
	"oranges_ch05_hundred":{"prices_thirds":[21,9,1],"quantity":100,"cost_thirds":300,"strictly_positive":true},
	"box_ch05_light":{"source":[160,16],"direction":[0,1],"mirrors":[[160,64],[64,64],[64,128]],"initial_angles":[105,150,30],"mirror_half_length_squared":128,"angle_step":15,"box_center":[128,128],"radius":16,"ring_step":45,"screen":[224,128],"word":"紫府元宗","max_bounces":12},
	"box_ch05_reseal":{"instance":BOX,"panels":12,"balls":["yin","yang"],"stones":2,"distinct_rubbings":12}
}
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
var _context_hash := ""
func _init(id: String = "") -> void:
	if not id.is_empty(): begin(id)
func begin(id: String, attempt: String = "", trusted_context: Dictionary = {}) -> bool:
	if id not in IDS or attempt.length()>256: return false
	if trusted_context.has("scene_id") and not trusted_context.scene_id is String: return false
	if id in ["box_ch05_light","box_ch05_reseal"] and not _valid_box_context(id,trusted_context): return false
	puzzle_id=id; attempt_id=attempt if not attempt.is_empty() else id+":attempt"; context=trusted_context.duplicate(true)
	state={"hint":0,"assisted":false,"complete":false,"failures":0}
	match id:
		"chain_ch05_linkage": state.merge({"links":[-1,-1,-1,-1],"observed":false,"double_tested":false,"third_installed":false,"trace":[]})
		"lock_ch05_six": state.merge({"lock":0,"observed":[],"open_locks":[],"probe":0,"direction":0})
		"bagua_ch05_reverse": state.merge({"light_observed":false,"light_point":[],"anchor":"","observed":false,"slots":[-1,-1,-1,-1,-1,-1,-1,-1],"checks":[]})
		"oranges_ch05_hundred": state.merge({"observed":[],"counts":[0,0,0],"count_check":false,"cost_check":false,"quantity_sum":0,"triple_cost":0})
		"box_ch05_light": state.merge({"box_instance":BOX,"candle_out":false,"observed":false,"mounted":[false,false,false],"angles":[105,150,30],"ring":0,"ray":{},"projected":false,"opened":false})
		"box_ch05_reseal": state.merge({"box_instance":BOX,"opened":true,"removed_panels":[],"copies":[],"taken_balls":[],"stones":[],"loaded_stones":[],"refitted_panels":[],"sealed":false,"box_contents":{"balls":["yin","yang"],"panels":[0,1,2,3,4,5,6,7,8,9,10,11],"stones":[]},"table_contents":{"balls":[],"panels":[],"stones":[],"copies":[]}})
	input_log=[]; _undo=[]; _events=[]; _proof={}
	_context_hash=_hash(_context_projection()); _initial_hash=_hash(state)
	message="先观察再操作。可撤回、重试或收起保留进度；不扣真实钱物。"
	return true
static func _valid_box_context(id: String, value: Dictionary) -> bool:
	if not value.get("box_instance") is String or not value.get("items") is Dictionary: return false
	if value.box_instance!=BOX: return false
	var item: Variant=value.items.get(BOX)
	if not item is Dictionary or not item.get("form") is String or not item.get("owner") is String: return false
	if item.owner.is_empty() or not _bounded_tree(item): return false
	return item.form==("sealed" if id=="box_ch05_light" else "opened")
func _context_projection() -> Dictionary:
	if puzzle_id not in ["box_ch05_light","box_ch05_reseal"]: return {}
	if not context.get("items") is Dictionary: return {"invalid":true}
	return {"box_instance":context.get("box_instance"),"item":context.items.get(BOX,{})}
func set_context(trusted_context: Dictionary) -> bool:
	if trusted_context.has("scene_id") and not trusted_context.scene_id is String: return false
	if puzzle_id in ["box_ch05_light","box_ch05_reseal"] and not _valid_box_context(puzzle_id,trusted_context): return false
	var previous := context
	context=trusted_context.duplicate(true)
	if _hash(_context_projection())!=_context_hash: context=previous; return false
	return true

static func _bounded_tree(value: Variant) -> bool:
	# Reject hostile save trees BEFORE recursive normalization; never traverse an
	# unbounded or cyclic Variant graph supplied by a caller.
	var pending: Array=[{"value":value,"depth":0}]; var visited:=0
	while not pending.is_empty():
		var entry: Dictionary=pending.pop_back(); var v: Variant=entry.value; var depth: int=entry.depth
		visited+=1
		if visited>50000 or depth>20: return false
		if v is Dictionary:
			if v.size()>64: return false
			for key in v:
				if not key is String or key.length()>128: return false
				pending.append({"value":v[key],"depth":depth+1})
		elif v is Array:
			if v.size()>2048: return false
			for item in v: pending.append({"value":item,"depth":depth+1})
		elif v is String:
			if v.length()>512: return false
		elif v is float:
			if not is_finite(v): return false
		elif not (v is int or v is bool): return false
	return true

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
	if not a.get("type") is String or a.size()>8: return false
	# All action field shapes are checked before input logging or state changes.
	var fields := {
		"hint":{},"undo":{},"reset":{},"retry":{},"assist_step_v1":{},"submit":{},
		"restart_after_limit":{"hint":"int","assisted":"int","failures":"int","discarded_log_hash":"string"},
		"inspect_chain":{},"connect_link":{"source":"int","target":"int"},"install_third":{},"test_chain":{},
		"inspect_lock":{"lock":"int"},"set_probe":{"depth":"int","direction":"int"},"turn_lock":{},
		"observe_bagua_light":{},"set_bagua_anchor":{"direction":"string"},"inspect_bagua_sequence":{},"place_trigram":{"slot":"int","trigram":"int"},"verify_reverse_pair":{"slot":"int"},"test_cabinet":{},
		"inspect_price":{"fruit":"int"},"set_oranges":{"warm":"int","green":"int","flat":"int"},"check_orange_count":{},"check_orange_cost":{},
		"extinguish_candle":{},"inspect_light_room":{},"mount_mirror":{"mirror":"int"},"rotate_mirror":{"mirror":"int","step":"int"},"rotate_box_ring":{"step":"int"},"trace_light":{},"open_original_box":{},
		"remove_panel":{"page":"int"},"rub_page":{"page":"int"},"take_ball":{"ball":"string"},"collect_stone":{"stone":"int"},"load_stone":{"stone":"int"},"refit_panel":{"page":"int"},"seal_original_box":{}
	}
	if not fields.has(a.type): return false
	var schema: Dictionary=fields[a.type]
	for field in schema:
		if not a.has(field): return false
		if schema[field]=="int" and not _integer(a[field]): return false
		if schema[field]=="string" and (not a[field] is String or a[field].length()>100): return false
	for key in a:
		if not key is String: return false
		if key=="type": continue
		if key=="box" and a.type in ["remove_panel","rub_page","take_ball","collect_stone","load_stone","refit_panel","seal_original_box"]:
			if not a[key] is String or a[key].length()>100: return false
		elif not schema.has(key): return false
	return true
func _reject(reason: String) -> bool:
	message = reason
	return false

func apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(action): return {"ok":false,"message":"操作格式无效。"}
	action=_normalize(action)
	if input_log.size()>=MAX_LOG:
		if action.type not in ["reset","retry"] or state.complete: return {"ok":false,"message":"本轮记录已满；重试始终可恢复，提示与协助保留。"}
		var restart := {"type":"restart_after_limit","hint":state.hint,"assisted":1 if state.assisted else 0,"failures":state.failures,"discarded_log_hash":_hash(input_log)}
		begin(puzzle_id,attempt_id,context)
		return apply_input(restart)
	var before := state.duplicate(true)
	input_log.append(action.duplicate(true))
	var ok := _operate(action)
	if not ok: state.failures=mini(1000000,state.failures+1)
	elif action.type not in ["hint","undo","reset","retry","restart_after_limit"] and not state.complete:
		_undo.append(before)
		if _undo.size()>128: _undo.pop_front()
	_events.append({"action":action.type,"ok":ok,"before":_hash(before),"after":_hash(state)})
	if state.complete and _proof.is_empty(): _issue()
	return {"ok":ok,"message":message,"receipt":receipt(),"receipts":get_receipts(),"view":get_view()}
func _operate(a: Dictionary) -> bool:
	if a.type=="restart_after_limit":
		if input_log.size()!=1 or a.size()!=5 or not _integer(a.get("hint")) or not _integer(a.get("assisted")) or not _integer(a.get("failures")): return _reject("重开摘要只能是首条记录。")
		if a.hint<0 or a.hint>3 or a.assisted not in [0,1] or a.failures<0 or not a.get("discarded_log_hash") is String or a.discarded_log_hash.length()!=64: return _reject("重开摘要无效。")
		for c in a.discarded_log_hash:
			if c not in "0123456789abcdef": return _reject("重开摘要无效。")
		state.hint=a.hint; state.assisted=a.assisted==1; state.failures=a.failures; message="已重开题面，提示和协助保留。"; return true
	if state.complete: return _reject("已完成本题，请收起继续现场流程。")
	if a.type=="hint": state.hint=mini(3,state.hint+1); message=_hint(); return true
	if a.type=="undo":
		if _undo.is_empty(): return _reject("当前没有可撤回的操作。")
		var meta := {"hint":state.hint,"assisted":state.assisted,"failures":state.failures}
		state=_undo.pop_back(); state.merge(meta,true); message="已撤回；真实钱物从未在本面板中结算。"; return true
	if a.type in ["reset","retry"]:
		var fresh := ChapterFivePuzzleResolver.new()
		if not fresh.begin(puzzle_id,attempt_id,context): return _reject("可信现场物品已不符，不能凭空重建盒子。")
		fresh.state.hint=state.hint; fresh.state.assisted=state.assisted; fresh.state.failures=state.failures
		state=fresh.state; _undo.clear(); message="回到本题开始时的操作台；同一物件全部恢复，没有复制或丢失。"; return true
	if a.type=="assist_step_v1":
		if state.hint<3: return _reject("先读三层提示，再明确同意协助这一步。")
		var next := _assist_v1_next_action()
		if next.is_empty(): return _reject("暂无下一步；可撤回或重试。")
		state.assisted=true
		var ok := _operate(next)
		message="协助实际操作："+describe_action(next)+"。"+message
		return ok
	match puzzle_id:
		"chain_ch05_linkage": return _chain(a)
		"lock_ch05_six": return _locks(a)
		"bagua_ch05_reverse": return _bagua(a)
		"oranges_ch05_hundred": return _oranges(a)
		"box_ch05_light": return _light(a)
		"box_ch05_reseal": return _reseal(a)
	return false
func _chain(a: Dictionary) -> bool:
	if a.type=="inspect_chain": state.observed=true; message="教学传动图：踏板0送力，翻板1、锁闩2联动后通出口4；试过二连环再装配重3。"; return true
	if a.type=="connect_link":
		if not state.observed or not _index(a.get("source"),4) or not _index(a.get("target"),5): return _reject("先看传动图，选择起点与接收端。")
		if (a.source==3 or a.target==3) and not state.third_installed: return _reject("配重3尚未安装；须先实测二连环。")
		state.links[a.source]=a.target; state.trace=[]; message="已把%d号输出接到%d号；接法可试动，不自动宣布成功。" % [a.source,a.target]; return true
	if a.type=="install_third":
		if not state.double_tested or state.third_installed: return _reject("先实际试通二连环，且配重只安装一次。")
		state.third_installed=true; message="配重3已到位；把锁闩2与出口4间的传动改经配重。"; return true
	if a.type=="test_chain":
		if not state.observed: return _reject("先检查结构。")
		state.trace=[0]
		var visited := {0:true}; var current := 0
		for step in range(5):
			var next: int = state.links[current]
			if next<0: return _reject("传动停在%d号：输出未连接。" % current)
			state.trace.append(next)
			if next==4: break
			if visited.has(next): return _reject("力绕回%d号形成环路，出口未动作。" % next)
			visited[next]=true; current=next
		var expected: Array = [0,1,2,3,4] if state.third_installed else [0,1,2,4]
		if state.trace!=expected: return _reject("实际逐节点传动%s，须每一机构依次受力，不可绕过翻板或锁闩。" % str(state.trace))
		if not state.third_installed: state.double_tested=true; message="二连环实测0→1→2→4通过；现在可加配重。"
		else: state.complete=true; message="三连环逐节点0→1→2→3→4传动通过。只完成机关装配，尚未打赢船战。"
		return true
	return _reject("观察传动，连接输出并真实试动；二连环实测后再升级。")
func _locks(a: Dictionary) -> bool:
	var index: int = state.lock
	if a.type=="inspect_lock":
		if a.get("lock")!=index or index>=6: return _reject("请核读当前这一道尚未开的外锁。")
		if index not in state.observed: state.observed.append(index)
		message="第%d锁：齿痕深%d格，转向刻痕为%s。" % [index+1,LOCK_DEPTHS[index],"顺时针" if LOCK_DIRECTIONS[index]==1 else "逆时针"]; return true
	if a.type=="set_probe":
		if index not in state.observed or a.get("depth") not in [1,2,3] or a.get("direction") not in [-1,1]: return _reject("先读当前齿痕，再选探针深度1—3与转向。")
		state.probe=a.depth; state.direction=a.direction; message="探针深%d格，方向%s；试转才会检验。" % [a.depth,"顺时针" if a.direction==1 else "逆时针"]; return true
	if a.type=="turn_lock":
		if index>=6 or index not in state.observed or state.probe!=LOCK_DEPTHS[index] or state.direction!=LOCK_DIRECTIONS[index]: return _reject("齿深或转向不合，锁舌未退；可重新选探针，没有材料损失。")
		state.open_locks.append(index); state.lock+=1; state.probe=0; state.direction=0
		state.complete=state.lock==6
		message="第%d道外锁已退。%s" % [index+1,"六道外锁全开，纯阳铁盒仍未开启。" if state.complete else "继续核读下一道独立齿痕。"]
		return true
	return _reject("逐锁观察、配探针、试转；本题不打开铁盒。")
func _bagua(a: Dictionary) -> bool:
	if a.type=="observe_bagua_light":
		# Cardinal ray from (32,90) east intersects the radius64 disc at its west edge.
		var origin := Vector2i(32,90); var center := Vector2i(160,90)
		state.light_point=[center.x-64,origin.y]; state.light_observed=true
		message="晨光从盘左侧(32,90)向右照，落在盘缘(96,90)；盘心(160,90)，上北下南。先定这处参照方向。"; return true
	if a.type=="set_bagua_anchor":
		if not state.light_observed or a.get("direction")!="west" or state.light_point!=[96,90]: return _reject("根据光斑相对盘心的位置定参照；光斑在盘心左侧同一横线。")
		state.anchor="west"; message="以西沿光斑定0位，从这里顺时针读正序纹样。"; return true
	if a.type=="inspect_bagua_sequence":
		if state.anchor!="west": return _reject("先以光斑定西沿参照，再读序列。")
		state.observed=true; message="正序从西沿0位顺时针：乾兑离震巽坎艮坤；柜闩反读，编号i映到(8−i)余8。"; return true
	if a.type=="place_trigram":
		if not state.observed or not _index(a.get("slot"),8) or not _index(a.get("trigram"),8): return _reject("先读带参照的正序，再摆唯一卦牌。")
		var previous: int=state.slots.find(a.trigram); var displaced: int=state.slots[a.slot]
		if previous>=0: state.slots[previous]=displaced
		state.slots[a.slot]=a.trigram; state.checks=[]
		message="%s牌移到第%d位；每张牌只有一枚，不会复制。" % [TRIGRAMS[a.trigram],a.slot]; return true
	if a.type=="verify_reverse_pair":
		if not _index(a.get("slot"),8) or state.slots[a.slot]!=posmod(-int(a.slot),8): return _reject("该位没有与正序反向编号对应；重看西沿0位和反读方向。")
		if a.slot not in state.checks: state.checks.append(a.slot)
		message="第%d位与正序第%d牌反向对应，已核对%d/8处。" % [a.slot,posmod(-int(a.slot),8),state.checks.size()]; return true
	if a.type=="test_cabinet":
		if state.checks.size()!=8 or state.slots!=[0,7,6,5,4,3,2,1]: return _reject("须八枚唯一牌就位且逐处对应核对，柜闩才可试开。")
		state.complete=true; message="反向柜闩已退，暗柜可取未开的真盒；本题不产生开盒、球或经文。"; return true
	return _reject("观光定西，再读正序、反向摆牌、逐处核对，最后试柜闩。")
func _oranges(a: Dictionary) -> bool:
	if a.type=="inspect_price":
		if not _index(a.get("fruit"),3): return _reject("选择三种桔中的一种。")
		if a.fruit not in state.observed: state.observed.append(a.fruit)
		message=["温柑每只7文。","绿桔每只3文。","匾桔每3只1文，即每只三分之一文。"][a.fruit]; return true
	if a.type=="set_oranges":
		if state.observed.size()!=3 or not _integer(a.get("warm")) or not _integer(a.get("green")) or not _integer(a.get("flat")) or a.warm<=0 or a.green<=0 or a.flat<=0 or a.warm>100 or a.green>100 or a.flat>100: return _reject("三种都要购买正整数只，先读三种单价，各数量1—100。")
		state.counts=[a.warm,a.green,a.flat]; state.count_check=false; state.cost_check=false
		state.quantity_sum=0; state.triple_cost=0; message="数量已记；分别核对总只数和总价，不只认一种答案。"; return true
	if a.type=="check_orange_count":
		state.quantity_sum=state.counts[0]+state.counts[1]+state.counts[2]
		state.count_check=state.quantity_sum==100 and state.counts.min()>0
		message="总只数%d＋%d＋%d＝%d。" % [state.counts[0],state.counts[1],state.counts[2],state.quantity_sum]
		return state.count_check
	if a.type=="check_orange_cost":
		state.triple_cost=21*state.counts[0]+9*state.counts[1]+state.counts[2]
		state.cost_check=state.triple_cost==300 and state.counts.min()>0
		message="把总价同乘3：21×%d＋9×%d＋%d＝%d；须等于300（原价100文）。" % [state.counts[0],state.counts[1],state.counts[2],state.triple_cost]
		return state.cost_check
	if a.type=="submit":
		if not state.count_check or not state.cost_check or state.observed.size()!=3: return _reject("数量100、三倍总价300，两项都须实际验过。")
		state.complete=true; message="三种正整数数量同时满足百只百文；这是合法答案，不要求只报6/10/84。"; return true
	return _reject("读价、填三种正整数数量，再分别验总数与总价。")
func _light(a: Dictionary) -> bool:
	if a.type=="extinguish_candle": state.candle_out=true; message="明烛熄灭，能看清外光穿孔后的微弱字影。"; return true
	if a.type=="inspect_light_room": state.observed=true; message="顶孔(160,16)向南，三镜位为(160,64)/(64,64)/(64,128)。盒心(128,128)，接收面中心(224,128)。"; return true
	if a.type=="mount_mirror":
		if not state.observed or not _index(a.get("mirror"),3) or state.mounted[a.mirror]: return _reject("先看镜座，三片原有铜镜各归其位，不能重复取镜。")
		state.mounted[a.mirror]=true; _invalidate_light(); message="第%d镜固定在原镜座，可按15°一格转动。" % (a.mirror+1); return true
	if a.type=="rotate_mirror":
		if not _index(a.get("mirror"),3) or not state.mounted[a.mirror] or a.get("step") not in [-1,1]: return _reject("先安放该镜，再每次转±15°。")
		state.angles[a.mirror]=posmod(int(state.angles[a.mirror])+15*int(a.step),180)
		_invalidate_light(); message="第%d镜切线角现在%d°，旧光路检验失效。" % [a.mirror+1,state.angles[a.mirror]]; return true
	if a.type=="rotate_box_ring":
		if not state.observed or a.get("step") not in [-1,1]: return _reject("先观察铜环，再每次转±45°。")
		state.ring=posmod(int(state.ring)+int(a.step),8); _invalidate_light()
		message="同一盒的铜环转到%d°；双孔位置与字模方向同时改变。" % (state.ring*45); return true
	if a.type=="trace_light":
		if not state.observed: return _reject("先观察房内光源和镜座。")
		state.ray=Optics.trace(state.mounted,state.angles,state.ring)
		state.projected=state.ray.projected and state.candle_out
		message="实际光路：镜序%s，穿孔%s。%s" % [str(state.ray.mirrors),str(state.ray.holes),"四字正立投影可辨，可以检查暗簧。" if state.projected else ("烛火未灭，字影不可辨。" if state.ray.projected else "光束未形成正立四字，请根据路径调镜/铜环。")]
		return true
	if a.type=="open_original_box":
		if not state.candle_out or not state.projected or state.ray.is_empty() or not state.ray.projected: return _reject("实际光路须经三镜与两孔形成正立四字，才能检查盒簧；不能凭成功开关开盒。")
		state.opened=true; state.complete=true
		message="同一纯阳真盒暗簧弹开。双球与盒板仍在原盒内；下一阶段才取球、拓印及填石。"; return true
	return _reject("熄烛、观室、三镜归位并转角、转铜环、实际试光，再检查原盒暗簧。")
func _invalidate_light() -> void:
	state.ray={}; state.projected=false
func _reseal(a: Dictionary) -> bool:
	if a.get("box",BOX)!=BOX: return _reject("只允许操作当前这一个纯阳真盒，不能替换盒子实例。")
	if a.type=="remove_panel":
		if not _index(a.get("page"),12) or a.page in state.removed_panels or not state.opened: return _reject("十二块原盒板逐块拆下，不能重复或另造一块。")
		state.removed_panels.append(a.page); state.box_contents.panels.erase(a.page); state.table_contents.panels.append(a.page); message="已拆第%d块原盒板，暂放操作台，尚未拓印。" % (a.page+1); return true
	if a.type=="rub_page":
		if not _index(a.get("page"),12) or a.page not in state.removed_panels or a.page in state.copies or a.page in state.refitted_panels: return _reject("先拆下对应原板；每篇只拓一份，装回的板不能隔盒拓印。")
		state.copies.append(a.page); state.table_contents.copies.append(a.page); message="第%d篇已拓到独立纸页；原板仍属原盒。" % (a.page+1); return true
	if a.type=="take_ball":
		if a.get("ball") not in ["yin","yang"] or a.ball in state.taken_balls: return _reject("原盒只有阴、阳各一球，各取一次。")
		state.taken_balls.append(a.ball); state.box_contents.balls.erase(a.ball); state.table_contents.balls.append(a.ball)
		message="已从同一原盒取出%s球，暂由操作台托管；未产生第二份。" % ("阴" if a.ball=="yin" else "阳"); return true
	if a.type=="collect_stone":
		if not _index(a.get("stone"),2) or a.stone in state.stones: return _reject("现场标记两块鹅卵石，各取一次。")
		state.stones.append(a.stone); state.table_contents.stones.append(a.stone); message="取得现场第%d块石头，尚未放盒。" % (a.stone+1); return true
	if a.type=="load_stone":
		if state.taken_balls.size()!=2 or not _index(a.get("stone"),2) or a.stone not in state.stones or a.stone in state.loaded_stones: return _reject("须先取出双球，再把已取得的两块石头分别放回原盒。")
		state.loaded_stones.append(a.stone); state.table_contents.stones.erase(a.stone); state.box_contents.stones.append(a.stone); message="第%d块石头已装入同一原盒；没有另造假盒。" % (a.stone+1); return true
	if a.type=="refit_panel":
		if not _index(a.get("page"),12) or a.page not in state.copies or a.page in state.refitted_panels or state.loaded_stones.size()!=2: return _reject("对应经文须已拓，两石须已装；再把原板逐块装回。")
		state.refitted_panels.append(a.page); state.table_contents.panels.erase(a.page); state.box_contents.panels.append(a.page); message="原第%d板已装回同一盒体。" % (a.page+1); return true
	if a.type=="seal_original_box":
		if state.removed_panels.size()!=12 or state.copies.size()!=12 or state.taken_balls.size()!=2 or state.loaded_stones.size()!=2 or state.refitted_panels.size()!=12 or not state.box_contents.balls.is_empty() or state.table_contents.balls.size()!=2 or not state.table_contents.panels.is_empty() or not state.table_contents.stones.is_empty(): return _reject("需十二篇全拓、双球已取、两石已装、十二块原板全回装，才可封同一盒。")
		state.sealed=true; state.opened=false; state.complete=true
		message="同一原盒以两石复封；双球与十二份拓本完整在台，待现场一次原子归入物品账。"; return true
	return _reject("拆原板、逐篇拓印、取双球、取两石装盒、装回原板，最后封同一盒。")
func _issue() -> void:
	_proof={"resolver_version":VERSION,"controller_version":VERSION,"chapter":"chapter_five","scene_id":context.get("scene_id",""),"frozen_content_hash":_hash({"algorithm":CONTENT,"model":MODEL_SPEC[puzzle_id]}),"context_hash":_context_hash,"objective_id":OBJECTIVES[puzzle_id],"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted,"validation_results":{"complete_process":true,"no_xp":true,"same_box":state.get("box_instance",BOX)==BOX}}
func receipt() -> Dictionary: return _proof.duplicate(true)
func get_receipts() -> Array: return [] if _proof.is_empty() else [receipt()]
func snapshot() -> Dictionary: return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_context_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(saved): return false
	saved=_normalize(saved)
	if not _integer(saved.get("version")) or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("context_hash") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary: return false
	if saved.version!=VERSION or saved.attempt_id.is_empty() or saved.attempt_id.length()>256 or saved.context_hash.length()!=64 or saved.input_log.size()>MAX_LOG: return false
	var candidate := ChapterFivePuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context) or saved.get("context_hash")!=candidate._context_hash: return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		candidate.apply_input(a)
	if candidate.state!=saved.state: return false
	puzzle_id=candidate.puzzle_id; attempt_id=candidate.attempt_id; context=candidate.context
	state=candidate.state; input_log=candidate.input_log; _proof=candidate._proof; _events=candidate._events; _undo=candidate._undo; message=candidate.message; _initial_hash=candidate._initial_hash; _context_hash=candidate._context_hash
	return true
static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(proof): return false
	proof=_normalize(proof)
	if not proof.get("puzzle_id") is String or not proof.get("attempt_id") is String or not proof.get("input_log") is Array or not proof.get("context_hash") is String or not proof.get("final_state") is Dictionary: return false
	if proof.puzzle_id!=id or proof.attempt_id!=attempt: return false
	var r := ChapterFivePuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":proof.get("context_hash"),"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return not r.receipt().is_empty() and r.receipt()==proof
func next_demo_action() -> Dictionary: return _assist_v1_next_action()
# Frozen assist_step_v1 semantics. Add a new action version for future changes.
func _assist_v1_next_action() -> Dictionary:
	if state.complete: return {}
	match puzzle_id:
		"chain_ch05_linkage":
			if not state.observed: return {"type":"inspect_chain"}
			var expected: Array = [1,2,3,4] if state.third_installed else [1,2,4,-1]
			for i in range(4 if state.third_installed else 3):
				if state.links[i]!=expected[i]: return {"type":"connect_link","source":i,"target":expected[i]}
			if state.double_tested and not state.third_installed: return {"type":"install_third"}
			return {"type":"test_chain"}
		"lock_ch05_six":
			var i: int=state.lock
			if i not in state.observed: return {"type":"inspect_lock","lock":i}
			if state.probe!=LOCK_DEPTHS[i] or state.direction!=LOCK_DIRECTIONS[i]: return {"type":"set_probe","depth":LOCK_DEPTHS[i],"direction":LOCK_DIRECTIONS[i]}
			return {"type":"turn_lock"}
		"bagua_ch05_reverse":
			if not state.light_observed: return {"type":"observe_bagua_light"}
			if state.anchor!="west": return {"type":"set_bagua_anchor","direction":"west"}
			if not state.observed: return {"type":"inspect_bagua_sequence"}
			for i in range(8):
				if state.slots[i]!=posmod(-i,8): return {"type":"place_trigram","slot":i,"trigram":posmod(-i,8)}
			for i in range(8):
				if i not in state.checks: return {"type":"verify_reverse_pair","slot":i}
			return {"type":"test_cabinet"}
		"oranges_ch05_hundred":
			for i in range(3):
				if i not in state.observed: return {"type":"inspect_price","fruit":i}
			var c: Array=state.counts
			if c.min()<=0 or c[0]+c[1]+c[2]!=100 or 21*c[0]+9*c[1]+c[2]!=300: return {"type":"set_oranges","warm":6,"green":10,"flat":84}
			if not state.count_check: return {"type":"check_orange_count"}
			if not state.cost_check: return {"type":"check_orange_cost"}
			return {"type":"submit"}
		"box_ch05_light":
			if not state.candle_out: return {"type":"extinguish_candle"}
			if not state.observed: return {"type":"inspect_light_room"}
			for i in range(3):
				if not state.mounted[i]: return {"type":"mount_mirror","mirror":i}
			var targets := [135,135,45]
			for i in range(3):
				if state.angles[i]!=targets[i]:
					return {"type":"rotate_mirror","mirror":i,"step":1 if posmod(targets[i]-int(state.angles[i]),180)<=90 else -1}
			if state.ring!=0: return {"type":"rotate_box_ring","step":1 if state.ring>=4 else -1}
			if not state.projected: return {"type":"trace_light"}
			return {"type":"open_original_box"}
		"box_ch05_reseal":
			for i in range(12):
				if i not in state.removed_panels: return {"type":"remove_panel","page":i}
				if i not in state.copies: return {"type":"rub_page","page":i}
			for ball in ["yin","yang"]:
				if ball not in state.taken_balls: return {"type":"take_ball","ball":ball}
			for i in range(2):
				if i not in state.stones: return {"type":"collect_stone","stone":i}
				if i not in state.loaded_stones: return {"type":"load_stone","stone":i}
			for i in range(12):
				if i not in state.refitted_panels: return {"type":"refit_panel","page":i}
			return {"type":"seal_original_box"}
	return {}
func describe_action(a: Dictionary) -> String:
	match a.get("type",""):
		"inspect_chain": return "观察踏板、翻板、锁闩、出口的传动"
		"connect_link": return "连接%d号输出到%d号接收端" % [a.source,a.target]
		"install_third": return "安装第三联配重"
		"test_chain": return "送入踏板脉冲，逐节点实际试动"
		"inspect_lock": return "观察第%d外锁齿痕与转向" % (a.lock+1)
		"set_probe": return "将探针伸入%d格并选%s" % [a.depth,"顺时针" if a.direction==1 else "逆时针"]
		"turn_lock": return "试转当前外锁"
		"observe_bagua_light": return "观察入射光与盘缘光斑的实际位置"
		"set_bagua_anchor": return "按光斑确定西沿0位"
		"inspect_bagua_sequence": return "从西沿顺时针读正序纹样"
		"place_trigram": return "把%s唯一卦牌移到%d位" % [TRIGRAMS[a.trigram],a.slot]
		"verify_reverse_pair": return "核对第%d位的正反编号对应" % a.slot
		"test_cabinet": return "试开暗柜闩（盒盖仍封闭）"
		"inspect_price": return "核读%s单价" % ["温柑","绿桔","匾桔"][a.fruit]
		"set_oranges": return "记录温%d、绿%d、匾%d只" % [a.warm,a.green,a.flat]
		"check_orange_count": return "相加核对百只"
		"check_orange_cost": return "以21x＋9y＋z核对三倍总价300"
		"submit": return "核对全部输入过程"
		"extinguish_candle": return "吹灭明烛，准备辨读微光"
		"inspect_light_room": return "看清顶光、三镜座与原盒孔位"
		"mount_mirror": return "把第%d片原铜镜固定到镜座" % (a.mirror+1)
		"rotate_mirror": return "第%d镜切线角转%+d°" % [a.mirror+1,a.step*15]
		"rotate_box_ring": return "原盒铜环转%+d°，同时移动孔与字模" % (a.step*45)
		"trace_light": return "实际追踪反射、穿孔与投影"
		"open_original_box": return "检查正立四字引动的原盒暗簧"
		"remove_panel": return "拆下原盒第%d板，放到操作台" % (a.page+1)
		"rub_page": return "拓印原板第%d篇" % (a.page+1)
		"take_ball": return "从原盒取出%s球" % ("阴" if a.ball=="yin" else "阳")
		"collect_stone": return "取现场第%d块鹅卵石" % (a.stone+1)
		"load_stone": return "把第%d石填入原盒" % (a.stone+1)
		"refit_panel": return "把原第%d板装回同一盒" % (a.page+1)
		"seal_original_box": return "确认双球/拓本在台、两石在盒，再复封原盒"
	return ""
func _hint() -> String:
	var hints := {
		"chain_ch05_linkage":["看每一机构的输入端与输出端，力不能越过空线。","先0→1→2→4试二连环，再把配重3串入锁闩与出口之间。","协助将逐条连线并实际试动；断路和环路仍会被同一验证器拒绝。"],
		"lock_ch05_six":["每道锁的齿深和旋痕不同，先观察当前锁。","深度要对齐齿痕，转向要对齐旋痕；错一项锁舌都不退。","协助只做当前观察/配针/试转中的下一小步，不会一键跳过六锁。"],
		"bagua_ch05_reverse":["光斑相对盘心在左、右、上还是下？先确定参照。","西沿为0；从这里读正序，反向位置用(8−i)余8，不复制任何卦牌。","反读0—7位依次乾坤艮坎巽震离兑；仍要逐处核对，再试柜闩。"],
		"oranges_ch05_hundred":["总数与总价是两条不同条件，三种都要正整数只。","令温x、绿y、匾z：x+y+z=100；总价同乘3得到21x+9y+z=300。","消去z得5x+2y=50；可得2/20/78、4/15/81、6/10/84、8/5/87。四解均合法。"],
		"box_ch05_light":["明烛遮住微弱字影；先熄烛再看顶光与三处镜座。","光必须从顶向南，经东镜向西、西镜向南、下镜向东，再穿原盒两孔。转铜环也会转字模。","三镜切线角135°/135°/45°，铜环0°。从105°/150°/30°各转+30°/−15°/+15°，实际试光后才开原盒。"],
		"box_ch05_reseal":["原盒只有一份；拆出的原板、双球、拓本和石头要分别留有去向。","逐板拆下并拓12篇，取双球；实取2石装入，再装回12块原板。","协助每次只操作一件原物或一篇拓本。未集齐12篇/双球/两石/12回装板，不能复封。"]}
	return hints[puzzle_id][maxi(0,state.hint-1)]
func instruction() -> String:
	match puzzle_id:
		"chain_ch05_linkage": return "批准的简化传动图，不是原著精确机括：0踏板→1翻板→2锁闩→4出口先实测二连环，再安装3配重并改线升级三连环。连接错误可实际试出断路或环路。本题不代替B02战斗。"
		"lock_ch05_six": return "简化六外锁教学：每道独立观察齿深和转向，选探针并试转；不能用上一锁答案自动开下一锁。只开启六道外锁，尚未得到或打开纯阳盒。"
		"bagua_ch05_reverse": return "暗柜反八卦教学：先观察光斑定西沿参照，读正序，再将8枚唯一牌按反向编号摆放并核对。只退暗柜闩，不开盒、不授球和经文。"
		"oranges_ch05_hundred": return "已裁定校正题面：温柑7文/只，绿桔3文/只，匾桔3只/文；100文买100只，三种都要正整数。须分别验总数与总价，所有合法解都通过。"
		"box_ch05_light": return "V3外光三镜有限模型：屏面右东下南，镜面切线角15°步进。熄烛、安放原镜、调镜和铜环后实际追光；第三镜缺少或角度错误都会失光。180°铜环即使穿孔也倒字，不能开盒。"
		"box_ch05_reseal": return "同一个已开真盒的操作台：逐块拆下原板并拓印12篇，取出阴阳双球，拾取两石替入，再装回原板复封。部分进度可存读；完成前物件由同一会话托管，不直接发奖或改真实库存。"
	return ""
func get_view() -> Dictionary:
	var titles := ["千里船 · 二连环升三连环","雷公堡 · 六道外锁","暗柜 · 光斑与反八卦","天圆室 · 百钱百桔","残红小筑 · 三镜开原盒","操作台 · 拓印取球与原盒复封"]
	var next := next_demo_action()
	return {"kind":"chapter_five","puzzle_id":puzzle_id,"title":titles[IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint>0 else "","next_demo":describe_action(next),"next_action":next,"receipt":receipt(),"receipts":get_receipts()}
