class_name ChapterTwelvePuzzleResolver
extends RefCounted
## Finite teaching models. No actor resources, rewards or learned skills are mutated.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch12_care_visits","pz_ch12_clinic_supply","pz_ch12_reverse_five_phases","pz_ch12_r05_rescue"]
const SCENES:=["ch12_two_months_care","ch12_jiangxi_clinic","ch12_reverse_five_phases","R05"]
const OBJECTIVES:=["care_visits_verified","clinic_supply_verified","reverse_five_phases_verified","r05_rescue_verified"]
const TITLES:=["两月照护 · 日常不辍","江西医棚 · 按需分物","反五行 · 逆转来势","拳头之外 · 托石救人"]
const DAYS:=[1,14,30,60]
const ELEMENTS:=["木","火","土","金","水"]
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
	if not _integer(c.get("chapter")) or c.chapter!=12 or not c.get("current_token") is String or c.current_token.is_empty() or not c.get("scene_id") is String or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
	for id_actor in ["char_liang_xiao","char_hua_xiaoshuang"]:
		var actor:Variant=c.actors.get(id_actor)
		if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
		if actor.has("id") and (not actor.id is String or actor.id!=id_actor):return false
	if id==IDS[3]:
		if not c.get("r05_method") is String or c.r05_method not in ["a","b"]:return false
		var h:Variant=c.actors.get("char_huasheng")
		if not h is Dictionary or not _integer(h.get("hp")) or h.hp<=0:return false
		if h.has("id") and (not h.id is String or h.id!="char_huasheng"):return false
	if not c.get("assistance_status","manual") is String or c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[]
	state=_fresh();message="先查看图示，再调整实物；试验不会扣除角色资源。";return true
func _fresh()->Dictionary:
	return {"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted","observed":[],"stage":0,"done":[],"visit":0,"care":[],"visits":[],"supplies":{"water":2,"blanket":1,"cloth":1},"delivered":{},"slots":[2,4,1,0,3],"reverse":false,"flow":[],"pulses":0,"support":0,"height":0,"rescued":false,"blade_broken":false}
func _safe(a:Dictionary)->bool:
	if not _bounded_tree(a):return false
	var schemas:Dictionary={"observe":{"target":"s"},"act":{"action":"s"},"supply":{"patient":"s","item":"s"},"swap":{"left":"i","right":"i"},"direction":{"reverse":"i"},"pulse":{},"support":{"position":"i"},"lift":{},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
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
		IDS[0]:return {"wrist":"第%d日：晓霜旧腕伤须休息，不能把照护当作随时回满人物资源。"%DAYS[state.visit],"liu":"柳伤势与旧事须逐日照看；先送温水与饭，再听晓霜复查安排。"}
		IDS[1]:return {"traveller":"晓霜分派：旅人缺饮水，需两份水。这里只分物，不诊现实疾病。","child":"晓霜分派：孩子衣薄，送一份毯子。","worker":"晓霜分派：工人需一份净布，药方仍由晓霜定夺。"}
		IDS[2]:return {"cycle":"原顺势木→火→土→金→水；从木起反向绕行。","gate":"五个槽内各放一种，反向流须依次木→水→金→土→火。","pulse":"调整节点与方向后，实际运行三股来势；错序会截停，无人物伤害。"}
		_:return {"shaft":"硬拽车辕会把老汉拖向崖缘；必须从石下稳定承托。","stone":"石重在中点2；抬高两格才有救人空隙。","cliff":"右侧崖缘不能落脚；承托点仅中点2稳定。","blade":"恶仆刀刃在前；A扛石震慑，B先折刃再搬石。均不打人。"}
func trace()->Dictionary:
	var path:Array=[]
	var expected:Array=[0,4,3,2,1]
	for i in range(5):
		var slot:int=(5-i)%5 if state.reverse else i
		path.append(slot)
		if state.slots[slot]!=expected[i]:return {"safe":false,"path":path}
	return {"safe":true,"path":path}
func _medical(a:Dictionary)->bool:
	if a.type=="observe":
		if not observations().has(a.target):return false
		if a.target not in state.observed:state.observed.append(a.target)
		message=observations()[a.target];return true
	if state.observed.size()!=observations().size():return _reject("先把现场情况全部看清，再采取行动。")
	match puzzle_id:
		IDS[0]:return _care(a)
		IDS[1]:return _supply(a)
		IDS[2]:return _flow(a)
		_:return _rescue(a)
func _care(a:Dictionary)->bool:
	if a.type!="act":return false
	if a.action in ["bring_water","bring_meal"]:
		if a.action in state.care:return _reject("这一天已经送过；不能反复领取恢复。")
		state.care.append(a.action)
	elif a.action=="doctor_review":
		if state.care.size()!=2:return _reject("先完成本日温水与饭食照护。")
		state.care.append(a.action);state.visits.append(DAYS[state.visit]);state.complete=state.visit==3
	elif a.action=="later_visit":
		if state.care.size()!=3 or state.visit>=3:return _reject("本日照护还未完成。")
		state.visit+=1;state.observed=[];state.care=[]
	else:return false
	state.done.append(a.action);state.stage+=1;message="第%d日：%s。人物资源保持原账。"%[DAYS[state.visit],action_label(a.action)];return true
func _supply(a:Dictionary)->bool:
	if a.type!="supply" or a.patient not in ["traveller","child","worker"] or a.item not in ["water","blanket","cloth"]:return false
	var needs:Dictionary={"traveller":"water","child":"blanket","worker":"cloth"}
	var amount:int=2 if a.patient=="traveller" else 1
	if needs[a.patient]!=a.item:return _reject("晓霜分派的需要不匹配，物资没有扣除。")
	if state.delivered.get(a.patient,0)>=amount or state.supplies[a.item]<=0:return _reject("已经送足，有限物资不能重复领取。")
	state.delivered[a.patient]=state.delivered.get(a.patient,0)+1;state.supplies[a.item]-=1;state.stage+=1
	state.complete=state.stage==4;message="已按晓霜安排送出一份，图上库存与收取数同步变化。";return true
func _flow(a:Dictionary)->bool:
	if a.type in ["swap","direction"]:
		if state.pulses>0:return _reject("行流中不能改路；重试后再调整。")
		if a.type=="swap":
			if a.left<0 or a.left>4 or a.right<0 or a.right>4 or a.left==a.right:return false
			var old:int=state.slots[a.left];state.slots[a.left]=state.slots[a.right];state.slots[a.right]=old
		else:
			if a.reverse not in [0,1]:return false
			state.reverse=a.reverse==1
		state.flow=[];message="经路已调整，请观察五行次序后试运。";return true
	if a.type!="pulse":return false
	var result:Dictionary=trace();state.flow=result.path
	if not result.safe:message="来势在不合的节点截停，未增加进度，也未伤害人物。";return true
	state.pulses+=1;state.complete=state.pulses==3;state.stage=state.pulses;message="实际逆行%d/3股；不是技能授予。"%state.pulses;return true
func _rescue(a:Dictionary)->bool:
	if a.type=="support":
		if a.position<0 or a.position>4 or state.height>0:return false
		state.support=a.position;message="承托位置%d；重心在2，先确保不会滑向崖边。"%a.position;return true
	if a.type=="lift":
		if state.support!=2:return _reject("重心不稳，花生停手，老汉与车架未移动。")
		if context.r05_method=="b" and not state.blade_broken:return _reject("本法先折兵刃，消除刀口威胁后搬石。")
		if state.height>=2:return false
		state.height+=1;state.stage+=1;message="花生稳托抬石%d/2格，仍须晓霜救出老汉。"%state.height;return true
	if a.type!="act":return false
	if a.action=="break_blade":
		if context.r05_method!="b" or state.blade_broken or state.height>0:return false
		state.blade_broken=true;message="只折刀刃，不伤恶仆。";return true
	if a.action=="pull_shaft":return _reject("观察已见硬拽会滑崖，花生不执行此危险动作。")
	if a.action=="rescue_elder":
		if state.height!=2:return _reject("石下还没有安全空隙，先稳托抬高。")
		state.rescued=true;state.complete=true;state.stage+=1;message="晓霜从稳定空隙救出老汉；救治与修路在后续真实场景进行。";return true
	return false
static func action_label(action:String)->String:
	return {"bring_water":"梁萧送温水","bring_meal":"梁萧送饭食","doctor_review":"晓霜复查本日照护","later_visit":"进入下一日期探视","break_blade":"花生先折兵刃","pull_shaft":"尝试硬拽车辕","rescue_elder":"晓霜救出老汉"}.get(action,action)
func next_demo_action()->Dictionary:
	if state.is_empty() or state.complete:return {}
	for target in observations():
		if target not in state.observed:return {"type":"observe","target":target}
	match puzzle_id:
		IDS[0]:
			for action in ["bring_water","bring_meal","doctor_review"]:
				if action not in state.care:return {"type":"act","action":action}
			return {"type":"act","action":"later_visit"}
		IDS[1]:
			for patient in ["traveller","child","worker"]:
				if state.delivered.get(patient,0)<(2 if patient=="traveller" else 1):return {"type":"supply","patient":patient,"item":{"traveller":"water","child":"blanket","worker":"cloth"}[patient]}
		IDS[2]:
			if state.pulses>0:return {"type":"pulse"}
			for i in range(5):
				if state.slots[i]!=i:return {"type":"swap","left":i,"right":state.slots.find(i)}
			if not state.reverse:return {"type":"direction","reverse":1}
			return {"type":"pulse"}
		IDS[3]:
			if context.r05_method=="b" and not state.blade_broken:return {"type":"act","action":"break_blade"}
			if state.support!=2:return {"type":"support","position":2}
			if state.height<2:return {"type":"lift"}
			return {"type":"act","action":"rescue_elder"}
	return {}
func assistance_status()->String:
	if state.is_empty():return "unknown"
	return "assisted" if state.assisted or state.history_status=="assisted" else state.history_status
static func target_label(target:String)->String:
	return {"wrist":"晓霜腕伤","liu":"柳的照护","traveller":"旅人","child":"孩子","worker":"工人","cycle":"五行原序","gate":"逆行次序","pulse":"试运方式","shaft":"车辕","stone":"落石","cliff":"崖缘","blade":"刀刃"}.get(target,target)
func command_label(a:Dictionary)->String:
	match a.get("type",""):
		"observe":return "观察"+target_label(a.target)
		"act":return action_label(a.action)
		"supply":return "给"+target_label(a.patient)+{"water":"水","blanket":"毯子","cloth":"净布"}[a.item]
		"swap":return "交换槽%d与%d"%[a.left,a.right]
		"direction":return "改为逆向"
		"pulse":return "试运一股"
		"support":return "承托点移到2"
		"lift":return "抬石一格"
	return "已完成"
func _hint()->String:
	if state.hint==0:return ""
	if state.hint==1:return "先观察全部情况；照护要逐日、分物要按需、搬石要稳住重心。"
	if state.hint==2:return "逆流从木走水金土火；承托中点2，稳抬两格才可救人。照护不产生额外恢复。"
	return "下一合法步骤："+command_label(next_demo_action())+"。协助会保留标记。"
func get_view()->Dictionary:
	if state.is_empty():return {}
	var actions:Array=[]
	for target in observations():actions.append({"label":"观察 · "+target_label(target),"command":{"type":"observe","target":target}})
	var commands:Array=["bring_water","bring_meal","doctor_review","later_visit"] if puzzle_id==IDS[0] else (["break_blade","pull_shaft","rescue_elder"] if puzzle_id==IDS[3] else [])
	for action in commands:actions.append({"label":action_label(action),"command":{"type":"act","action":action}})
	return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":TITLES[IDS.find(puzzle_id)],"state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"actions":actions,"observations":observations(),"labels":observations().keys().map(target_label),"day":DAYS[state.visit],"preview":trace() if puzzle_id==IDS[2] else {},"instruction":"有限剧情示意；按观察实际行动，人物资源不变。医方由晓霜掌握，非现实医疗指南。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(saved):return false
	var data:Dictionary=_normalize(saved)
	if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
	var r:=ChapterTwelvePuzzleResolver.new()
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
	var r:=ChapterTwelvePuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
	return not r.receipt().is_empty() and r.receipt()==p
