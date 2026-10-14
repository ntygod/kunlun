class_name ChapterSixPuzzleResolver
extends RefCounted
## Approved finite teaching models, not literal astronomy or historical craft simulation.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["stars_ch06_sword","array_ch06_steps","basket_ch06_weave","r03","l02"]
const OBJECTIVES:={"stars_ch06_sword":"stars_sword_verified","array_ch06_steps":"ten_directions_verified","basket_ch06_weave":"basket_weave_verified","r03":"r03_craft_verified","l02":"l02_repairs_verified"}
const BAMBOO:="item_ch06_bamboo"
const FINE:="item_ch06_fine_strips"
const PINE:="item_ch06_dry_pine"
const SLEEVE:="item_ch06_reused_sleeve"
const PIN:="item_ch06_willow_pin"
const HOOP:="item_ch06_iron_hoop"
const HIDE:="item_ch06_rawhide"
const RESIN:="item_ch06_pine_resin"
const MATERIALS:={"basket_ch06_weave":{BAMBOO:2},"r03":{FINE:1},"l02":{PINE:2,SLEEVE:1,PIN:1,HOOP:1,HIDE:1,RESIN:3}}
const AUTH:={"r03":["r03_soak_verified","r03_family_letter"],"l02":["l02_measure_waterwheel","l02_measure_cart","l02_measure_plough","l02_borrowed_materials_verified","l02_liting_help"]}
const SQUARE:=[16,2,3,13,5,11,10,8,9,7,6,12,4,14,15,1]
const LINES:=[[0,1,2,3],[4,5,6,7],[8,9,10,11],[12,13,14,15],[0,4,8,12],[1,5,9,13],[2,6,10,14],[3,7,11,15],[0,5,10,15],[3,6,9,12]]
const STARS:=[[2,0],[0,2],[-2,0]]
const MODEL_SPEC:={"stars_ch06_sword":{"stars":STARS,"rotation":90,"notes":3},"array_ch06_steps":{"fixed_square":SQUARE,"lines":LINES,"sum":34,"steps":10},"basket_ch06_weave":{"bamboo":2,"strips_each":3,"rows":6},"r03":{"fine_bundle":1,"strips":6,"bake_ticks":3,"products":["bird","box"]},"l02":{"pine":2,"pieces_each":2,"reuse":[SLEEVE,PIN],"jobs":["waterwheel","cart","plough"],"test_ticks":3,"resin_coats":3}}
var puzzle_id:=""
var attempt_id:=""
var context:Dictionary={}
var state:Dictionary={}
var input_log:Array=[]
var message:=""
var _undo:Array=[]
var _events:Array=[]
var _proof:Dictionary={}
var _initial_hash:=""
var _context_hash:=""
func _init(id:String="") -> void:
	if not id.is_empty():begin(id)
static func _projection(id:String,c:Dictionary) -> Dictionary:
	if c.has("scene_id") and (not c.scene_id is String or c.scene_id.length()>256):return {"invalid":true}
	if c.has("objective_id") and (not c.objective_id is String or c.objective_id!=id):return {"invalid":true}
	var out:Dictionary={"items":{},"authorizations":[],"method":"","scene_id":c.get("scene_id",""),"objective_id":id}
	if id in MATERIALS:
		if not c.get("items") is Dictionary:return {"invalid":true}
		for item in MATERIALS[id]:
			var v:Variant=c.items.get(item)
			if not v is Dictionary or not _bounded_tree(v):return {"invalid":true}
			if not v.get("owner") is String or v.owner not in ["ch06_workbench","char_liang_xiao"]:return {"invalid":true}
			if not v.get("state") is String or v.state!="available" or not v.get("form") is String or v.form.is_empty():return {"invalid":true}
			if not _integer(v.get("quantity")) or v.quantity<MATERIALS[id][item]:return {"invalid":true}
			out.items[item]=v.duplicate(true)
	if id in AUTH:
		if not c.get("authorizations") is Array or not c.get("method") is String:return {"invalid":true}
		if c.authorizations.size()>256:return {"invalid":true}
		for authorization in c.authorizations:
			if not authorization is String or authorization.length()>128:return {"invalid":true}
		for key in AUTH[id]:
			if key not in c.authorizations:return {"invalid":true}
			out.authorizations.append(key)
		if c.method not in (["bird","box"] if id=="r03" else ["waterwheel","cart"]):return {"invalid":true}
		out.method=c.method
	return out
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
	if id not in IDS or attempt.length()>256 :return false
	if trusted_context.has("scene_id") and not trusted_context.scene_id is String:return false
	var projection:=_projection(id,trusted_context)
	if projection.has("invalid"):return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=projection.duplicate(true);context.scene_id=trusted_context.get("scene_id","")
	state={"hint":0,"assisted":false,"complete":false,"failures":0,"history_reset":false}
	match id:
		"stars_ch06_sword":state.merge({"notes":[],"observed":[],"predictions":[],"sword_vectors":[]})
		"array_ch06_steps":state.merge({"principle":false,"observed":[],"verified":[],"sums":[],"steps":[],"position":-1})
		"basket_ch06_weave":state.merge({"principle":false,"raw":[0,1],"split":[],"loose":[],"woven":[],"patterns":[],"rim":false,"load_ticks":0,"product":""})
		"r03":state.merge({"principle":false,"method":projection.method,"bundle":1,"loose":[],"woven":[],"patterns":[],"heat":0,"bake":0,"parts":[],"test_ticks":0,"product":""})
		"l02":state.merge({"principle":false,"method":projection.method,"raw":[0,1],"cut":[],"pieces":[],"installed_pieces":[],"inspected":[],"recovered":[],"repaired":[],"joined":[],"resined":[],"lifted":[],"tests":{},"completed_jobs":[],"resin_left":3,"locations":{"sleeve":"site","pin":"site","hoop":"table","hide":"table"},"product":""})
	input_log=[];_undo=[];_events=[];_proof={};_context_hash=_hash(projection);_initial_hash=_hash(state)
	message="先看原理，再逐步试做；收起保留进度，重试归还本题尚未交付的材料。"
	return true
func set_context(c:Dictionary) -> bool:
	if c.has("scene_id") and not c.scene_id is String:return false
	var projection:=_projection(puzzle_id,c)
	if projection.has("invalid") or _hash(projection)!=_context_hash:return false
	context=projection.duplicate(true);context.scene_id=c.get("scene_id","");return true
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
func _safe(a:Dictionary) -> bool:
	if not a.get("type") is String or a.size()>8:return false
	var schema:Dictionary={
	"hint":{},"undo":{},"reset":{},"retry":{},"assist_step_v1":{},"read_principle":{},"finish":{},
	"restart_after_limit":{"hint":"int","assisted":"int","failures":"int","discarded_log_hash":"string"},
	"read_note":{"note":"int"},"observe_star":{"time":"int"},"predict_star":{"x":"int","y":"int"},"sword_vector":{"x":"int","y":"int"},
	"observe_line":{"line":"int"},"verify_line":{"line":"int","sum":"int"},"step_line":{"line":"int","endpoint":"int"},
	"split_bamboo":{"bamboo":"int"},"weave_row":{"strip":"int","pattern":"int"},"bind_rim":{},"load_test":{},
	"split_fine":{},"set_heat":{"level":"int"},"bake_tick":{},"fit_part":{"part":"string"},"test_product":{},
	"inspect_reuse":{"part":"string"},"recover_reuse":{"part":"string"},"repair_reuse":{"part":"string"},"cut_pine":{"log":"int","length":"int"},"join":{"job":"string","fit":"int"},"resin":{"job":"string"},"lift":{"job":"string","partner":"string"},"test_repair":{"job":"string"}}
	if not schema.has(a.type):return false
	var fields:Dictionary=schema[a.type]
	if a.size()!=fields.size()+1:return false
	for field in fields:
		if not a.has(field):return false
		if fields[field]=="int" and not _integer(a[field]):return false
		if fields[field]=="string" and (not a[field] is String or a[field].length()>100):return false
	return true
func _reject(reason: String) -> bool:
	message = reason
	return false

func apply_input(action: Dictionary) -> Dictionary:
	if action.get("type") is String and action.type=="restart_after_limit":
		return {"ok":false,"message":"重开摘要由本题记录管理，不能作为玩家操作。"}
	return _apply_input(action)
func _apply_input(action: Dictionary) -> Dictionary:
	if puzzle_id.is_empty() or not _safe(action): return {"ok":false,"message":"操作格式无效。"}
	action=_normalize(action)
	if input_log.size()>=MAX_LOG:
		if action.type not in ["reset","retry"] or state.complete: return {"ok":false,"message":"本轮记录已满；重试始终可恢复，提示与协助保留。"}
		var restart := {"type":"restart_after_limit","hint":state.hint,"assisted":1 if state.assisted else 0,"failures":state.failures,"discarded_log_hash":_hash(input_log)}
		begin(puzzle_id,attempt_id,context)
		return _apply_input(restart)
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
		state.hint=a.hint; state.assisted=a.assisted==1; state.failures=a.failures;state.history_reset=true; message="已重开题面；此前详细记录已清理，旧尝试是否用过提示或协助不再核验。"; return true
	if state.complete: return _reject("已完成本题，请收起继续现场流程。")
	if a.type=="hint": state.hint=mini(3,state.hint+1); message=_hint(); return true
	if a.type=="undo":
		if _undo.is_empty(): return _reject("当前没有可撤回的操作。")
		var meta := {"hint":state.hint,"assisted":state.assisted,"failures":state.failures,"history_reset":state.history_reset}
		state=_undo.pop_back(); state.merge(meta,true); message="已撤回；材料仍在本题操作台。"; return true
	if a.type in ["reset","retry"]:
		var fresh := ChapterSixPuzzleResolver.new()
		if not fresh.begin(puzzle_id,attempt_id,context): return _reject("现场材料不符，不能重建操作台。")
		fresh.state.hint=state.hint; fresh.state.assisted=state.assisted; fresh.state.failures=state.failures;fresh.state.history_reset=state.history_reset
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
		"stars_ch06_sword":return _stars(a)
		"array_ch06_steps":return _array(a)
		"basket_ch06_weave":return _basket(a)
		"r03":return _r03(a)
		"l02":return _l02(a)
	return false
func _done(text:String) -> bool:
	state.complete=true;message=text;return true
func _stars(a:Dictionary) -> bool:
	if a.type=="read_note":
		if not _index(a.note,3) or a.note in state.notes:return _reject("三处旧批各读一次。")
		state.notes.append(a.note);message=["旧批启发·教学规则：变易有序。图中每拍绕中心逆时针转四分之一圈。","旧批启发·教学规则：万变有常。转前后离中心距离平方不变。","旧批启发·教学规则：顺势而行。剑路取星位的逆时针切向，与径向垂直。"][a.note];return true
	if state.notes.size()!=3:return _reject("先读三处父批，图中规则才完整。")
	var i:int=state.sword_vectors.size()
	if a.type=="observe_star":
		if i>=3 or a.time!=i or i in state.observed:return _reject("依三次观察推进，同一时刻不重复登记。")
		state.observed.append(i);message="第%d拍星位%s；下一拍逆时针转90°：新坐标=(-y,x)。" % [i+1,str(STARS[i])];return true
	if i>=3:
		if a.type=="finish":return _done("三次星位转动与切向剑路均验过，梁萧悟出天行剑的运行之理。")
		return _reject("三拍已验，收束剑理即可。")
	var p:Array=STARS[i]
	if a.type=="predict_star":
		if i not in state.observed or state.predictions.size()!=i:return _reject("先观察当前星位，再预测下一拍。")
		if a.x!=-p[1] or a.y!=p[0] or a.x*a.x+a.y*a.y!=p[0]*p[0]+p[1]*p[1]:return _reject("下一拍须逆时针转90°且半径不变；本拍尚未通过。")
		state.predictions.append([a.x,a.y]);message="预测落点保持半径，接着用当前星位的切向出剑。";return true
	if a.type=="sword_vector":
		if state.predictions.size()!=i+1:return _reject("先验证下一拍星位。")
		if a.x*p[0]+a.y*p[1]!=0 or p[0]*a.y-p[1]*a.x<=0 or a.x*a.x+a.y*a.y!=4:return _reject("剑向须垂直径向、沿逆时针行势，图上长度为2。")
		state.sword_vectors.append([a.x,a.y]);message="切向与径向点积为0，方向顺势；第%d拍剑路已验。" % (i+1);return true
	return _reject("依次观察、预测、验证切向剑路。")
func _array(a:Dictionary) -> bool:
	if a.type=="read_principle":state.principle=true;message="固定正常幻方：1—16各一次，四行四列两对角共10条，每条和34；不是任意四数。";return true
	if not state.principle:return _reject("先读十条验线与步位映射规则。")
	if a.type=="observe_line":
		if not _index(a.line,10) or a.line in state.observed:return _reject("选择尚未观察的十条线之一。")
		state.observed.append(a.line);message="线%d经过格%s；按图将四格相加，再踏此线末格%d。" % [a.line,str(LINES[a.line]),LINES[a.line][3]];return true
	if a.type=="verify_line":
		if not _index(a.line,10) or a.line not in state.observed or a.line in state.verified:return _reject("先观察该线，每线验一次。")
		var total:=0
		for cell in LINES[a.line]:total+=SQUARE[cell]
		if a.sum!=total:return _reject("此线四数之和不符，请按图重新相加。")
		state.verified.append(a.line);state.sums.append(total);message="第%d线四数相加为%d。" % [a.line,total];return true
	if a.type=="step_line":
		var next:int=state.steps.size()
		if next>=10 or a.line!=next or a.line not in state.verified or a.endpoint!=LINES[a.line][3]:return _reject("步序按图0—9；先验当前线，再踏其末格。不是世界碰撞跳跃。")
		state.position=a.endpoint;state.steps.append({"line":a.line,"endpoint":a.endpoint});message="沿已验第%d线走到末格%d；下条线仍显示在图上。" % [a.line,a.endpoint];return true
	if a.type=="finish" and state.steps.size()==10:return _done("十条数学关系与对应十步均验过，十方步之理已明。")
	return _reject("观察各线、填其总和、按图踏该线末格；十步后收束。")
func _weave_integrity() -> bool:
	if state.woven.size()!=6 or state.patterns.size()!=6 or not state.loose.is_empty():return false
	var unique:Dictionary={}
	for n in range(6):
		unique[state.woven[n]]=true
		if state.patterns[n]!=(21 if n%2==0 else 42):return false
	return unique.size()==6
func _weave(a:Dictionary) -> bool:
	if not _index(a.strip,6) or a.strip not in state.loose or state.woven.size()>=6:return _reject("选择台上尚未使用的一条篾。")
	var row:int=state.woven.size()
	var expected:int=21 if row%2==0 else 42
	if a.pattern!=expected:return _reject("六经交错：奇行上下上下上下，偶行下上下上下上；相邻行须反扣。")
	state.loose.erase(a.strip);state.woven.append(a.strip);state.patterns.append(a.pattern);message="第%d行已穿入，篾%d从台上移入编面。" % [row+1,a.strip+1];return true
func _basket(a:Dictionary) -> bool:
	if a.type=="read_principle":state.principle=true;message="两根竹各破三篾，六行交替上下穿插；六条唯一篾全部编入后收口试承重。";return true
	if not state.principle:return _reject("先读破篾与交错编织原理。")
	if a.type=="split_bamboo":
		if not _index(a.bamboo,2) or a.bamboo not in state.raw:return _reject("只有两根实际竹材，各破一次。")
		state.raw.erase(a.bamboo);state.split.append(a.bamboo)
		for n in range(3):state.loose.append(a.bamboo*3+n)
		message="一根竹材已破成三条独立篾，没有增加原料。";return true
	if a.type=="weave_row":return _weave(a)
	if a.type=="bind_rim":
		if state.woven.size()!=6 or state.rim:return _reject("六条都编入后才能折回原篾收口，不另取材料。")
		state.rim=true;message="原篾尾折回扣紧筐沿，接着逐次放入试重。";return true
	if a.type=="load_test":
		if not state.rim or not _weave_integrity() or state.load_ticks>=3:return _reject("先收好筐沿，再做三次承重观察。")
		state.load_ticks+=1;message="第%d次承重：相邻反扣、筐沿未松。" % state.load_ticks;return true
	if a.type=="finish" and state.load_ticks==3:state.product="basket";return _done("竹筐承重三次均稳，可以带去换粮。")
	return _reject("破篾、六行穿插、收口、三次试重，再交付竹筐。")
func _r03(a:Dictionary) -> bool:
	if a.type=="read_principle":state.principle=true;message="仅一份细篾，已选%s；六行交错后小火定形三拍，再装配并实测。" % ("檐下风簧鸟" if state.method=="bird" else "隔水家书盒");return true
	if not state.principle:return _reject("先读所选器物的工序；本题不会改为另一分支。")
	if a.type=="split_fine":
		if state.bundle!=1:return _reject("唯一一份细篾已经分开。")
		state.bundle=0;state.loose=[0,1,2,3,4,5];message="一份细篾分为六条，全部只够这一件器物。";return true
	if a.type=="weave_row":return _weave(a)
	if a.type=="set_heat":
		if a.level not in [0,1,2]:return _reject("火力只能为停火、小火或旺火。")
		state.heat=a.level;message="当前%s；小火才能均匀定形，旺火不推进也不烧毁任务材料。" % ["停火","小火","旺火"][a.level];return true
	if a.type=="bake_tick":
		if state.woven.size()!=6 or state.heat!=1 or state.bake>=3:return _reject("编面完整后以小火定形，共三拍。")
		state.bake+=1;message="小火定形%d/3拍，原篾形状渐稳。" % state.bake;return true
	if a.type=="fit_part":
		var needed:Array=["reed","hanger"] if state.method=="bird" else ["inner","seal"]
		if state.bake!=3 or a.part not in needed or a.part in state.parts:return _reject("定形后仅装本分支的两处结构，各一次。")
		state.parts.append(a.part);message="从同件器物预留篾尾制成%s，未取第二份细篾。" % {"reed":"风簧","hanger":"悬环","inner":"内层","seal":"密封收边"}[a.part];return true
	if a.type=="test_product":
		if state.parts.size()!=2 or not _weave_integrity() or state.bake!=3 or state.test_ticks>=3:return _reject("两处结构完成后做三次风/水试验。")
		state.test_ticks+=1;message=("试风：风簧随气流鸣响、悬环稳固。" if state.method=="bird" else "试水：外层受水，内层家书替纸仍干。")+"第%d/3次。" % state.test_ticks;return true
	if a.type=="finish" and state.test_ticks==3:state.product=state.method;return _done("唯一%s制作完成，待与阿雪灶前叙话后安置。" % ("风簧鸟" if state.method=="bird" else "隔水盒"))
	return _reject("唯一细篾只制作已选一物；逐行编、三拍定形、装配、三次实测。")
func _job() -> String:
	var order:Array=[state.method,"cart" if state.method=="waterwheel" else "waterwheel","plough"]
	return order[state.completed_jobs.size()] if state.completed_jobs.size()<3 else ""
func _l02(a:Dictionary) -> bool:
	if a.type=="read_principle":state.principle=true;message="套管复接水车、柳销修车；两松木各分两件，只作两副犁柄。铁箍与牛皮分别固定两处旧结构。";return true
	if not state.principle:return _reject("先读三户复用与两木分料图。")
	if a.type in ["inspect_reuse","recover_reuse","repair_reuse"]:
		if a.part not in ["sleeve","pin"]:return _reject("现场仅旧套管与柳木穿销两种复用件。")
		if a.type=="inspect_reuse":
			if a.part in state.inspected:return _reject("这件旧料已检查。")
			state.inspected.append(a.part);message="已检旧料裂口：保留完整段，拆回后修整端面。";return true
		if a.type=="recover_reuse":
			if a.part not in state.inspected or a.part in state.recovered:return _reject("先检查现场旧件，再拆取一次。")
			state.recovered.append(a.part);state.locations[a.part]="table";message="现场原件已移到操作台，未新生一件。";return true
		if a.part not in state.recovered or a.part in state.repaired:return _reject("先实取旧件，再修整一次。")
		state.repaired.append(a.part);message="旧件端面修整完毕，能按图接榫复用。";return true
	if a.type=="cut_pine":
		if not _index(a.log,2) or a.log not in state.raw or a.length!=2:return _reject("每根长度4单位，只能按中线2单位锯开，形成两件犁柄料。")
		state.raw.erase(a.log);state.cut.append(a.log);state.pieces.append(a.log*2);state.pieces.append(a.log*2+1);message="一根松木变为两件犁柄料，长度2+2=4，无新轴耗用松木。";return true
	if a.type in ["join","resin","lift","test_repair"]:
		if a.job!=_job():return _reject("按已选优先次序修完一户，再修另一大件，最后两副犁柄。")
		var job:String=a.job
		if a.type=="join":
			if job in state.joined:return _reject("这处已经接好，不能再耗同一材料。")
			var fit:int=2 if job=="waterwheel" else (1 if job=="cart" else 4)
			if a.fit!=fit:return _reject("榫位不合：水车套深2、车销贯深1、犁柄四件配两副。")
			if job=="plough":
				if state.pieces.size()!=4:return _reject("两根松木各切两件才够两副犁柄；20%未来资格不减本题用料。")
				state.installed_pieces=state.pieces.duplicate();state.pieces.clear()
			elif ("sleeve" if job=="waterwheel" else "pin") not in state.repaired:return _reject("现场旧件须已检查、拆取、修整才能复接。")
			if job!="plough":
				state.locations["sleeve" if job=="waterwheel" else "pin"]=job
				state.locations["hoop" if job=="waterwheel" else "hide"]=job
			state.joined.append(job);message="接榫吻合，原料转为当前器具组成，接着涂脂。";return true
		if a.type=="resin":
			if job not in state.joined or job in state.resined or state.resin_left<=0:return _reject("接榫后涂松脂一次。")
			state.resined.append(job);state.resin_left-=1;message="原工具台松脂薄涂接缝，防水处理完成。";return true
		if a.type=="lift":
			if job not in state.resined or job in state.lifted or a.partner!="li_ting":return _reject("涂脂后请现场李庭共同抬装，不能独自假称完成。")
			state.lifted.append(job);state.tests[job]=0;message="与李庭合力把修整部件抬回原位置，待实际运转。";return true
		if job not in state.lifted or state.tests[job]>=3:return _reject("抬装后才能进行三次负载实测。")
		state.tests[job]+=1;message={"waterwheel":"水流带动复接轴，水斗升水。","cart":"载物车轮转动，柳销与皮带不松。","plough":"两副犁柄分别受力，四件连接不松。"}[job]+"第%d/3次。" % state.tests[job]
		if state.tests[job]==3:state.completed_jobs.append(job)
		return true
	if a.type=="finish" and state.completed_jobs.size()==3:state.product="three_repairs";return _done("水车、推车及两副犁柄都已实测修好；两根松木和现场复用件各有去处。")
	return _reject("按图检查复用件、取回修整、两木分料，再逐户接榫、涂脂、合抬与实测。")
func _issue() -> void:
	_proof={"resolver_version":VERSION,"controller_version":VERSION,"chapter":"chapter_six","scene_id":context.get("scene_id",""),"frozen_content_hash":_hash(MODEL_SPEC[puzzle_id]),"context_hash":_context_hash,"objective_id":OBJECTIVES[puzzle_id],"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"input_log":input_log.duplicate(true),"engine_events":_events.duplicate(true),"before_hash":_initial_hash,"after_hash":_hash(state),"final_state":state.duplicate(true),"assisted":state.assisted,"previous_attempt_history_unverified":state.history_reset,"materials_used":MATERIALS.get(puzzle_id,{}).duplicate(true),"product":state.get("product",""),"validation_results":{"complete_process":true,"no_xp":true}}
func receipt() -> Dictionary: return _proof.duplicate(true)
func get_receipts() -> Array: return [] if _proof.is_empty() else [receipt()]
func snapshot() -> Dictionary: return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_context_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Dictionary, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(saved): return false
	saved=_normalize(saved)
	if not _integer(saved.get("version")) or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("context_hash") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary: return false
	if saved.version!=VERSION or saved.attempt_id.is_empty() or saved.attempt_id.length()>256 or saved.context_hash.length()!=64 or saved.input_log.size()>MAX_LOG: return false
	var candidate := ChapterSixPuzzleResolver.new()
	if not candidate.begin(saved.puzzle_id,saved.attempt_id,trusted_context) or saved.get("context_hash")!=candidate._context_hash: return false
	for a in saved.input_log:
		if not a is Dictionary or not candidate._safe(a): return false
		candidate._apply_input(a)
	if candidate.state!=saved.state: return false
	puzzle_id=candidate.puzzle_id; attempt_id=candidate.attempt_id; context=candidate.context
	state=candidate.state; input_log=candidate.input_log; _proof=candidate._proof; _events=candidate._events; _undo=candidate._undo; message=candidate.message; _initial_hash=candidate._initial_hash; _context_hash=candidate._context_hash
	return true
static func replay_receipt(proof: Dictionary, id: String, attempt: String, trusted_context: Dictionary = {}) -> bool:
	if not _bounded_tree(proof): return false
	proof=_normalize(proof)
	if not proof.get("puzzle_id") is String or not proof.get("attempt_id") is String or not proof.get("input_log") is Array or not proof.get("context_hash") is String or not proof.get("final_state") is Dictionary: return false
	if proof.puzzle_id!=id or proof.attempt_id!=attempt: return false
	var r := ChapterSixPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":proof.get("context_hash"),"input_log":proof.input_log,"state":proof.get("final_state",{})},trusted_context): return false
	return not r.receipt().is_empty() and r.receipt()==proof
func next_demo_action() -> Dictionary:return _assist_v1_next_action()
func _assist_v1_next_action() -> Dictionary:
	if state.complete:return {}
	match puzzle_id:
		"stars_ch06_sword":
			for n in range(3):
				if n not in state.notes:return {"type":"read_note","note":n}
			var i:int=state.sword_vectors.size()
			if i==3:return {"type":"finish"}
			if i not in state.observed:return {"type":"observe_star","time":i}
			return {"type":"predict_star" if state.predictions.size()==i else "sword_vector","x":-STARS[i][1],"y":STARS[i][0]}
		"array_ch06_steps":
			if not state.principle:return {"type":"read_principle"}
			var i:int=state.steps.size()
			if i==10:return {"type":"finish"}
			if i not in state.observed:return {"type":"observe_line","line":i}
			if i not in state.verified:return {"type":"verify_line","line":i,"sum":34}
			return {"type":"step_line","line":i,"endpoint":LINES[i][3]}
		"basket_ch06_weave","r03":
			if not state.principle:return {"type":"read_principle"}
			if puzzle_id=="basket_ch06_weave" and not state.raw.is_empty():return {"type":"split_bamboo","bamboo":state.raw[0]}
			if puzzle_id=="r03" and state.bundle==1:return {"type":"split_fine"}
			if state.woven.size()<6:return {"type":"weave_row","strip":state.loose[0],"pattern":21 if state.woven.size()%2==0 else 42}
			if puzzle_id=="basket_ch06_weave":
				if not state.rim:return {"type":"bind_rim"}
				if state.load_ticks<3:return {"type":"load_test"}
			else:
				if state.heat!=1:return {"type":"set_heat","level":1}
				if state.bake<3:return {"type":"bake_tick"}
				for part in (["reed","hanger"] if state.method=="bird" else ["inner","seal"]):
					if part not in state.parts:return {"type":"fit_part","part":part}
				if state.test_ticks<3:return {"type":"test_product"}
			return {"type":"finish"}
		"l02":
			if not state.principle:return {"type":"read_principle"}
			for part in ["sleeve","pin"]:
				if part not in state.inspected:return {"type":"inspect_reuse","part":part}
				if part not in state.recovered:return {"type":"recover_reuse","part":part}
				if part not in state.repaired:return {"type":"repair_reuse","part":part}
			if not state.raw.is_empty():return {"type":"cut_pine","log":state.raw[0],"length":2}
			var job:=_job()
			if job.is_empty():return {"type":"finish"}
			if job not in state.joined:return {"type":"join","job":job,"fit":2 if job=="waterwheel" else (1 if job=="cart" else 4)}
			if job not in state.resined:return {"type":"resin","job":job}
			if job not in state.lifted:return {"type":"lift","job":job,"partner":"li_ting"}
			return {"type":"test_repair","job":job}
	return {}
func describe_action(a:Dictionary) -> String:
	var names:Dictionary={"read_note":"读所选父批","observe_star":"观察本拍星位","predict_star":"检验下一拍落点","sword_vector":"检验本拍切向剑路","read_principle":"读本题原理","observe_line":"观察所选验线","verify_line":"核算所选线四数和","step_line":"沿验线踏向对应末格","split_bamboo":"破开所选竹材","weave_row":"穿入所选篾与上下模式","bind_rim":"折回原篾收口","load_test":"放入试重并察看筐沿","split_fine":"分开唯一一份细篾","set_heat":"调整烤形火力","bake_tick":"小火定形一拍","fit_part":"装配所选结构","test_product":"实测本分支成品","inspect_reuse":"检查现场旧件","recover_reuse":"实取已检查旧件","repair_reuse":"修整台上旧件","cut_pine":"按中线锯所选松木","join":"按图接榫","resin":"薄涂松脂","lift":"请李庭合力抬装","test_repair":"带负载检验此户器具","finish":"收束已完成的全部检验"}
	if a.is_empty():return "已完成"
	var fields:Dictionary={"note":"旧批","time":"拍数","x":"x","y":"y","line":"线号","sum":"总和","endpoint":"末格","bamboo":"竹材编号","strip":"篾条编号","pattern":"穿法","level":"火力","part":"结构","log":"松木编号","length":"锯口","job":"器具","fit":"接合规格","partner":"伙伴"}
	var values:Dictionary={"reed":"风簧","hanger":"悬环","inner":"内层","seal":"密封收边","sleeve":"旧套管","pin":"柳木销","waterwheel":"水车","cart":"推车","plough":"两副犁柄","li_ting":"李庭"}
	var detail:Array=[]
	for key in a:
		if key=="type":continue
		var value:String=str(a[key])
		if a[key] is String:value=values.get(a[key],a[key])
		if key=="pattern":value="上下上下上下" if a[key]==21 else "下上下上下上"
		detail.append(fields.get(key,key)+" "+value)
	return names.get(a.type,a.type)+("（"+"，".join(detail)+"）" if not detail.is_empty() else "")
func _hint() -> String:
	var hints:Dictionary={
	"stars_ch06_sword":["看旧批启发的恒量与变化。","教学图逆时针四分之一圈：(x,y)→(-y,x)；径向与切向点积0。","每次协助只读一处、观一拍或检验一个向量；你可随时停止。"],
	"array_ch06_steps":["固定阵只核四行、四列和两对角。","每线和34，步序0—9，落点是该线显示的第四格。不是任意四数都34。","每次协助只观察、验算或踏一条已显示的线。"],
	"basket_ch06_weave":["两竹各三篾，六条原篾不会复制。","两种交错模式轮换：上下上下上下／下上下上下上。","每次协助只破一竹、织一行或完成一项试验。"],
	"r03":["一份细篾只能做已选一件。","六行交替穿插后小火三拍，装本分支两处结构，再试三次。","协助追加同样的真实一步；重试不改变已选分支。"],
	"l02":["先检旧套管/柳销，拆回修整；两松木都留给犁柄。","每根4单位中线切2；水车套深2、车销贯深1、犁柄4件。","协助一步一步复用、锯切、接榫、涂脂、合抬和试转，不减少两木。"]}
	return hints[puzzle_id][maxi(0,state.hint-1)]
func instruction() -> String:
	return {"stars_ch06_sword":"父批启发的有限教学图，不预测真实天象：三处旧批、三拍星位和三次切向剑路都需亲自验过。","array_ch06_steps":"十方步数理教学：固定1—16唯一阵，验四行四列两对角共十条线，并依可见线序走到各线末格；不以错误的‘任意四数=34’作规则。","basket_ch06_weave":"两根竹材各破三篾，六条原篾交替穿插、折回收口，再三次承重。材料在本题托管，收起保存，完成后才交付换粮。","r03":"溪泡与家书调查已完成；一份细篾只够所选一物。六行编织、小火定形、装配后实际试风或试水；普通携行竹马是另一件物品。","l02":"农忙三户修具：旧套管/柳销真实检查拆取修整，两松木切四件做两副犁柄，铁箍与牛皮各有用处。按所选先后接榫、涂脂、合抬、负载实测。未来20%生产资格不减少本题材料。"}[puzzle_id]
func get_view() -> Dictionary:
	return {"kind":"chapter_six","puzzle_id":puzzle_id,"title":["观星坪 · 天行剑理","十条验线 · 十方步","院中操作台 · 编筐换粮","细篾一份 · 竹鸟与家书","农忙互济 · 三户修具"][IDS.find(puzzle_id)],"instruction":instruction(),"state":state.duplicate(true),"message":message,"hint_text":_hint() if state.hint>0 else "","next_demo":describe_action(next_demo_action()),"next_action":next_demo_action(),"receipt":receipt(),"receipts":get_receipts()}
