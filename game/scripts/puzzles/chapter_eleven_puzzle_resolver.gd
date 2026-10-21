class_name ChapterElevenPuzzleResolver
extends RefCounted
## Finite teaching models. No actor resources, rewards or learned skills are mutated.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch11_dragon_needle","pz_ch11_meridian_channels","pz_ch11_yaer_treatment","pz_ch11_r04_triage","pz_ch11_r04_medicine"]
const SCENES:=["ch11_dragon_needle","ch11_meridian_insight","ch11_yaer_treatment","R04","R04"]
const OBJECTIVES:=["dragon_needle_removed","meridian_channels_verified","yaer_treatment_verified","r04_triage_verified","r04_medicine_verified"]
const TITLES:=["晓霜主诊 · 龙须取针","医武互参 · 经脉流转","针药施治 · 哑儿习声","杏林分诊 · 轻重有序","晓霜定方 · 协同施治"]
const Safe=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
var puzzle_id:=""
var attempt_id:=""
var context:Dictionary={}
var state:Dictionary={}
var input_log:Array=[]
var message:=""
static func _bounded_tree(v:Variant)->bool:return Safe._bounded_tree(v)
static func _normalize(v:Variant)->Variant:return Safe._normalize(v)
static func _integer(v:Variant)->bool:return Safe._integer(v)
static func _hash(v:Variant)->String:return Safe._hash(v)
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
	if id not in IDS or attempt.length()>256 or not _bounded_tree(trusted_context):return false
	var c:Dictionary=_normalize(trusted_context)
	if not _integer(c.get("chapter")) or c.chapter!=11 or not c.get("current_token") is String or c.current_token.is_empty() or not c.get("scene_id") is String or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
	for id_actor in ["char_liang_xiao","char_hua_xiaoshuang"]:
		var actor:Variant=c.actors.get(id_actor)
		if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
		if actor.has("id") and (not actor.id is String or actor.id!=id_actor):return false
	if id in [IDS[3],IDS[4]] and (not c.get("r04_method") is String or c.r04_method not in ["a","b"]):return false
	if not c.get("assistance_status","manual") is String or c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[]
	state=_fresh();message="先查看图示，再调整实物；试验不会扣除角色资源。";return true
func _fresh()->Dictionary:
	return {"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted","observed":[],"stage":0,"done":[],"position":[0,1],"flow":[],"rotations":[0,0,0],"polarity":[0,0,0],"heat":0,"simmer":0,"practice":0,"steady":0}
func _safe(a:Dictionary)->bool:
	if not _bounded_tree(a):return false
	var schemas:Dictionary={"observe":{"target":"s"},"act":{"action":"s"},"rotate":{"index":"i","value":"i"},"polarity":{"index":"i","value":"i"},"heat":{"value":"i"},"flow":{},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
	if not a.get("type") is String or not schemas.has(a.type) or a.size()!=schemas[a.type].size()+1:return false
	for k in schemas[a.type]:
		if not a.has(k) or (schemas[a.type][k]=="i" and not _integer(a[k])) or (schemas[a.type][k]=="s" and not a[k] is String):return false
	return true
func apply_input(action:Dictionary)->Dictionary:
	if not action.get("type") is String and not action.get("type") is StringName:return {"ok":false,"message":"操作类型无效。"}
	if action.get("type")=="reset_after_limit":return {"ok":false,"message":"内部记录不是玩家命令。"}
	if not puzzle_id.is_empty() and not state.complete and action=={"type":"retry"} and input_log.size()>=MAX_LOG-1:
		var hint:int=state.hint;var assisted:int=1 if assistance_status()=="assisted" else 0
		var id:String=puzzle_id;var attempt:String=attempt_id;var c:Dictionary=context.duplicate(true)
		if not begin(id,attempt,c):return {"ok":false,"message":"入口无效。"}
		return _apply({"type":"reset_after_limit","hint":hint,"assisted":assisted})
	return _apply(action)
func _apply(raw:Dictionary)->Dictionary:
	if puzzle_id.is_empty() or not _bounded_tree(raw):return {"ok":false,"message":"无效操作，状态未改。"}
	var a:Dictionary=_normalize(raw)
	if not _safe(a) or input_log.size()>=MAX_LOG:return {"ok":false,"message":"操作无效或记录已满；可重试，保留协助标记。"}
	var before:Dictionary=state.duplicate(true)
	if not _operate(a):state=before;return {"ok":false,"message":message}
	input_log.append(a.duplicate(true));return {"ok":true,"message":message,"view":get_view(),"receipt":receipt(),"receipts":get_receipts()}
func _reject(text:String)->bool:message=text;return false
func _operate(a:Dictionary)->bool:
	if state.complete:return _reject("已验证，收起机关继续。")
	if a.type=="reset_after_limit":
		if not input_log.is_empty() or a.hint<0 or a.hint>3 or a.assisted not in [0,1]:return false
		state.hint=a.hint;state.assisted=state.assisted or a.assisted==1;state.history_status="assisted" if state.assisted else "unknown"
		message="旧尝试记录已满，新试验保留协助标记；旧历史不宣称手工。";return true
	if a.type=="retry":
		var hint:int=state.hint;var assisted:bool=state.assisted;var history:String=state.history_status
		state=_fresh();state.hint=hint;state.assisted=assisted;state.history_status=history
		message="重新摆设，角色资源和原有物品不变。";return true
	if a.type=="hint":state.hint=mini(state.hint+1,3);message=_hint();return true
	if a.type=="assist_step_v1":
		if state.hint<3:return _reject("先展开三层提示，才可明确请求协助。")
		var action:Dictionary=next_demo_action()
		if action.is_empty():return false
		state.assisted=true;state.history_status="assisted";return _operate(action)
	return _medical(a)
func observations()->Dictionary:
	match puzzle_id:
		IDS[0]:return {"arm":"臂侧无针影，活动牵痛来自深处。","chest":"晓霜诊定胸侧旧针影；先稳住呼吸，不能贸然拔取。","pulse":"脉息随紧张波动；梁萧是病人，听从晓霜。"}
		IDS[1]:return {"source":"入口阴流，从左向右。","junction":"中央上转，右上再向右；阴阳相间。","sink":"出口阳流，晓霜辨经，梁萧依图试运。"}
		IDS[2]:return {"pulse":"晓霜先辨旧疾；本图不提供现实针位或药量。","breath":"呼吸尚稳，可按晓霜制定的针药流程施治。","voice":"哑儿需在施治后反复习声，不能一键奇迹痊愈。"}
		_:return {"farmer":"农夫呻吟虽响，皮外挫伤，脉稳；可短暂温粥安抚。","swordsman":"刀客断腿流血，但气脉尚稳；需要止血固定。","constable":"衙役面色青紫，脾脉暗裂危症；立即优先抢救，不按善恶排队。"}
func sequence()->Array:
	match puzzle_id:
		IDS[0]:return ["locate_chest","steady","steady","extract","recheck"]
		IDS[2]:return ["doctor_needle","doctor_medicine","later_visit","practice","later_visit","practice","recheck"]
		IDS[3]:return ["hold_constable","doctor_rescue","recheck"] if context.r04_method=="a" else ["porridge_farmer","hold_constable","doctor_rescue","recheck"]
		IDS[4]:return ["doctor_order","liang_chop","simmer","simmer","doctor_align","liang_support","doctor_bind","recheck"]
	return []
func trace()->Dictionary:
	var path:Array=[[0,1]];var at:=Vector2i(0,1);var direction:=Vector2i(1,0)
	var positions:Array=[Vector2i(1,1),Vector2i(1,0),Vector2i(2,0)]
	var used:Array=[];var tone:int=0
	for n in range(12):
		at+=direction;path.append([at.x,at.y])
		if at==Vector2i(3,0):return {"safe":used.size()==3 and tone==1,"path":path,"used":used}
		if at.x<0 or at.x>2 or at.y<0 or at.y>2:return {"safe":false,"path":path,"used":used}
		var i:int=positions.find(at)
		if i<0 or i in used:return {"safe":false,"path":path,"used":used}
		if state.polarity[i]!=tone:return {"safe":false,"path":path,"used":used}
		used.append(i);tone=1-tone
		match state.rotations[i]:
			0:pass
			1:direction=Vector2i(-direction.y,-direction.x)
			2:direction=Vector2i(direction.y,direction.x)
	return {"safe":false,"path":path,"used":used}
func _medical(a:Dictionary)->bool:
	if a.type=="observe":
		if not observations().has(a.target):return false
		if a.target not in state.observed:state.observed.append(a.target)
		message=observations()[a.target];return true
	if state.observed.size()!=3:return _reject("先由晓霜完成三处观察，再据症行动。")
	if puzzle_id==IDS[1]:
		if a.type in ["rotate","polarity"]:
			if a.index<0 or a.index>2 or a.value<0 or a.value>(2 if a.type=="rotate" else 1):return false
			state["rotations" if a.type=="rotate" else "polarity"][a.index]=a.value
			state.flow=[];message="经路已调；观察图示阴阳和转向，再实际行流。";return true
		if a.type=="flow":
			var result:Dictionary=trace();state.flow=result.path;state.complete=result.safe
			message="三节经路贯通；合招由后续剧情正式授予。" if result.safe else "经路在错向或阴阳不合处停住；无人物资源损失。"
			return true
		return false
	if a.type=="heat" and puzzle_id==IDS[4]:
		if state.stage<2 or state.stage>3 or a.value<0 or a.value>3:return false
		state.heat=a.value;message="火候%d/3；晓霜嘱咐用文火2，不可猛催。"%a.value;return true
	if a.type!="act":return false
	if puzzle_id==IDS[0] and state.stage==0 and a.action in ["locate_arm","locate_pulse"]:
		message="晓霜否定此定位：观察证据不支持这里有旧针，未施针、无人受伤。";return true
	var route:Array=sequence()
	if state.stage>=route.size() or a.action!=route[state.stage]:return _reject("次序不合：请依据晓霜诊断与当前分工继续。")
	if a.action=="simmer" and state.heat!=2:return _reject("需先调为文火2，再实际煎煮；没有损失药物。")
	state.done.append(a.action);state.stage+=1
	if a.action=="steady":state.steady+=1
	if a.action=="practice":state.practice+=1
	if a.action=="simmer":state.simmer+=1
	state.complete=state.stage==route.size()
	message=action_label(a.action)+"已执行。"+("本次流程已核验，后续剧情另行结算。" if state.complete else "继续观察反馈与分工。")
	return true
static func action_label(action:String)->String:
	return {"locate_arm":"尝试定位臂侧","locate_pulse":"尝试定位脉侧","later_visit":"转入后日复诊习声","locate_chest":"晓霜定位旧针","steady":"梁萧依嘱稳息一回","extract":"晓霜取针","recheck":"晓霜复查","doctor_needle":"晓霜行针","doctor_medicine":"晓霜施药","practice":"稍后陪哑儿习声一回","porridge_farmer":"先给农夫温粥安抚","hold_constable":"梁萧依嘱扶稳危症衙役","doctor_rescue":"晓霜立即救治危症衙役","doctor_order":"晓霜定参汤与夹板方案","liang_chop":"梁萧劈柴备火","simmer":"文火煎煮一回","doctor_align":"晓霜判断断处并对位","liang_support":"梁萧依嘱支托","doctor_bind":"晓霜夹板固定"}.get(action,action)
func next_demo_action()->Dictionary:
	if state.is_empty() or state.complete:return {}
	for target in observations():
		if target not in state.observed:return {"type":"observe","target":target}
	if puzzle_id==IDS[1]:
		for i in range(3):
			if state.rotations[i]!=[1,1,0][i]:return {"type":"rotate","index":i,"value":[1,1,0][i]}
			if state.polarity[i]!=[0,1,0][i]:return {"type":"polarity","index":i,"value":[0,1,0][i]}
		return {"type":"flow"}
	if puzzle_id==IDS[4] and state.stage in [2,3] and state.heat!=2:return {"type":"heat","value":2}
	return {"type":"act","action":sequence()[state.stage]}
func assistance_status()->String:
	if state.is_empty():return "unknown"
	return "assisted" if state.assisted or state.history_status=="assisted" else state.history_status
static func target_label(target:String)->String:
	return {"arm":"臂侧","chest":"胸侧旧针影","pulse":"脉息","source":"阴流入口","junction":"转向经节","sink":"阳流出口","breath":"呼吸","voice":"旧疾与习声","farmer":"采药农夫","swordsman":"断腿刀客","constable":"危症衙役"}.get(target,target)
func command_label(a:Dictionary)->String:
	match a.get("type",""):
		"observe":return "观察"+target_label(a.target)
		"act":return action_label(a.action)
		"rotate":return "经节%d改为%s"%[a.index+1,["直行","斜/","斜反"][a.value]]
		"polarity":return "经节%d设为%s"%[a.index+1,["阴","阳"][a.value]]
		"heat":return "调为文火2"
		"flow":return "试运经流"
	return "已完成"
func _hint()->String:
	if state.hint==0:return ""
	if state.hint==1:return "先完成三项观察。身份善恶不是病情轻重，晓霜负责医理决定。"
	if state.hint==2:return "经路需实际连通且阴阳交替；治疗需依诊断分工，不能跳过稳息、习声或煎煮。"
	return "下一合法步骤："+command_label(next_demo_action())+"。可明确请求逐步协助，记录会保留标记。"
func get_view()->Dictionary:
	if state.is_empty():return {}
	var actions:Array=[]
	for target in observations():actions.append({"label":"观察 · "+target_label(target),"command":{"type":"observe","target":target}})
	for action in (sequence()+["locate_arm","locate_pulse"] if puzzle_id==IDS[0] else sequence()):
		var item:Dictionary={"label":action_label(action),"command":{"type":"act","action":action}}
		if item not in actions:actions.append(item)
	return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":TITLES[IDS.find(puzzle_id)],"state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"actions":actions,"progress_total":sequence().size(),"labels":observations().keys().map(target_label),"observations":observations(),"preview":trace() if puzzle_id==IDS[1] else {},"instruction":"剧情有限示意，非现实医疗指导。晓霜主诊，梁萧配合；不消耗人物资源。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(saved):return false
	var data:Dictionary=_normalize(saved)
	if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
	var r:=ChapterElevenPuzzleResolver.new()
	if not r.begin(data.puzzle_id,data.attempt_id,trusted_context) or data.get("context_hash")!=_hash(r.context):return false
	for command in data.input_log:
		if not command is Dictionary or not r._apply(command).ok:return false
	if r.state!=data.state:return false
	puzzle_id=r.puzzle_id;attempt_id=r.attempt_id;context=r.context;state=r.state;input_log=r.input_log;message=r.message;return true
func set_context(c:Dictionary)->bool:return _bounded_tree(c) and _normalize(c)==context
func receipt()->Dictionary:
	if state.is_empty() or not state.complete:return {}
	return {"resolver_version":VERSION,"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"scene_id":context.scene_id,"objective_id":OBJECTIVES[IDS.find(puzzle_id)],"context_hash":_hash(context),"input_log":input_log.duplicate(true),"final_state":state.duplicate(true),"assistance_status":assistance_status(),"assisted":assistance_status()!="manual","manual_process_verified":assistance_status()=="manual","validation_results":{"complete_process":true,"no_xp":true}}
func proof()->Dictionary:return receipt()
func get_receipts()->Array:return [receipt()] if not receipt().is_empty() else []
static func replay_receipt(proof:Dictionary,id:String,attempt:String,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(proof):return false
	var p:Dictionary=_normalize(proof)
	if not p.get("puzzle_id") is String or not p.get("attempt_id") is String or p.get("puzzle_id")!=id or p.get("attempt_id")!=attempt:return false
	var r:=ChapterElevenPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
	return not r.receipt().is_empty() and r.receipt()==p
