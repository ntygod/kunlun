class_name ChapterTenPuzzleResolver
extends RefCounted
## Finite teaching models. No actor resources, rewards or learned skills are mutated.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch10_wooden_ox","pz_ch10_stone_array"]
const SCENES:=["ch10_repair_ox","ch10_stone_array"]
const STONE_COLUMNS:=[2,3,4]
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
	if not _integer(c.get("chapter")) or c.chapter!=10 or not c.get("current_token") is String or c.current_token.is_empty() or not c.get("scene_id") is String or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
	var actor:Variant=c.actors.get("char_liang_xiao")
	if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
	if actor.has("id") and (not actor.id is String or actor.id!="char_liang_xiao"):return false
	if not c.get("assistance_status","manual") is String or c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[]
	state=_fresh();message="先查看图示，再调整实物；试验不会扣除角色资源。";return true
func _fresh()->Dictionary:
	var s:Dictionary={"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted"}
	if puzzle_id==IDS[0]:s.merge({"axle":2,"left_phase":0,"right_phase":0,"cargo":{"light":-1,"heavy":1},"steps":0,"walk":[],"jammed":false})
	else:s.merge({"rows":[4,4,4],"turns":["/","/","/"],"wave":0,"breaths":0,"awaiting_breath":false,"used":[],"routes":[],"last_trace":[],"last_safe":false,"last_exit":"","locked":false})
	return s
func _safe(a:Dictionary)->bool:
	if not _bounded_tree(a):return false
	var schemas:Dictionary={"axle":{"length":"i"},"phase":{"side":"s","value":"i"},"cargo":{"bundle":"s","position":"i"},"step":{},"stone":{"index":"i","row":"i"},"turn":{"index":"i","orientation":"s"},"pulse":{},"breathe":{},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
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
	return _ox(a) if puzzle_id==IDS[0] else _stones(a)
func calculation()->Dictionary:
	if puzzle_id!=IDS[0]:return {}
	var torque:int=2*int(state.cargo.light)+3*int(state.cargo.heavy)
	return {"torque":torque,"phase_offset":(state.right_phase-state.left_phase+4)%4,"valid":state.axle==3 and torque==0 and (state.right_phase-state.left_phase+4)%4==2}
func _ox(a:Dictionary)->bool:
	if a.type in ["axle","phase","cargo"]:
		if state.steps>0:return _reject("负载试走中不能拆轴换料；需要重试回工位。")
		if a.type=="axle":
			if a.length not in [2,3,4]:return false
			state.axle=a.length
		elif a.type=="phase":
			if a.side not in ["left","right"] or a.value<0 or a.value>3:return false
			state[a.side+"_phase"]=a.value
		else:
			if a.bundle not in ["light","heavy"] or a.position not in [-3,-2,-1,1,2,3]:return false
			if state.cargo["heavy" if a.bundle=="light" else "light"]==a.position:return _reject("同一承重点不能叠放两个包。")
			state.cargo[a.bundle]=a.position
		state.jammed=false;message="已调整；图示实时显示偏载和曲柄相位。";return true
	if a.type=="step":
		if not calculation().valid:
			state.jammed=true;message="木牛卡住：轴需3格、曲柄错开2相、两包力矩需为0。先调整，货包和角色都未受损。";return true
		state.jammed=false;state.steps+=1;state.left_phase=(state.left_phase+1)%4;state.right_phase=(state.right_phase+1)%4
		state.walk.append({"left":state.left_phase,"right":state.right_phase,"torque":calculation().torque})
		state.complete=state.steps==3;message="负载前行 %d/3 步。%s"%[state.steps,"木牛已修妥；还需实际护送孩子。" if state.complete else "两侧交替落脚，继续试走。"]
		return true
	return _reject("请修轴、调曲柄和配重，再实际负载试走。")
func trace(lane:int)->Dictionary:
	var at:Array=[0,lane];var direction:Array=[1,0];var path:Array=[at.duplicate()];var used:Array=[];var seen:Dictionary={}
	for beat in range(96):
		var key:String=str(at)+str(direction)
		if seen.has(key):return {"safe":false,"exit":"loop","path":path,"used":used}
		seen[key]=true
		var index:int=-1
		for i in range(3):
			if at==[STONE_COLUMNS[i],state.rows[i]]:index=i;break
		if index>=0:
			if index not in used:used.append(index)
			direction=[-direction[1],-direction[0]] if state.turns[index]=="/" else [direction[1],direction[0]]
		at=[at[0]+direction[0],at[1]+direction[1]];path.append(at.duplicate())
		if at[1]<0 or at[1]>4:return {"safe":true,"exit":"north" if at[1]<0 else "south","path":path,"used":used}
		if at[0]<0 or at[0]>6:return {"safe":false,"exit":"west" if at[0]<0 else "rest_bank","path":path,"used":used}
	return {"safe":false,"exit":"loop","path":path,"used":used}
func _stones(a:Dictionary)->bool:
	if a.type in ["stone","turn"]:
		if state.locked:return _reject("来势已起，不能边调息边挪石；重试后可重新布局。")
		if a.index<0 or a.index>2:return false
		if a.type=="stone":
			if a.row<0 or a.row>4:return false
			state.rows[a.index]=a.row
		else:
			if a.orientation not in ["/","\\"]:return false
			state.turns[a.index]=a.orientation
		message="阵石已移，图上预览下一股来势。";return true
	if a.type=="pulse":
		if state.awaiting_breath or state.wave>=3:return _reject("先在刚争取的空隙调息。")
		var flow:Dictionary=trace(state.wave+1)
		state.last_trace=flow.path;state.last_safe=flow.safe;state.last_exit=flow.exit
		if not flow.safe:
			message="来势仍撞向调息岸，未争取到空隙；无资源损失，重试后调整阵石。";state.locked=true;return true
		state.locked=true;state.awaiting_breath=true
		for index in flow.used:
			if index not in state.used:state.used.append(index)
		state.routes.append(flow.path.duplicate(true));message="来势已导向外侧，按“调息一回合”把空隙化为实际调息。";return true
	if a.type=="breathe":
		if not state.awaiting_breath:return _reject("来势尚未移开，不能空点调息。")
		state.awaiting_breath=false;state.breaths+=1;state.wave+=1
		state.complete=state.breaths==3 and state.used.size()==3
		message="已调息 %d/3 回合。%s"%[state.breaths,"三石共同分流，留出连续练武的空间。" if state.complete else "下一股来势已在图上标出。"]
		if state.wave==3 and not state.complete:message="三次空隙已有，但仍有阵石未参与；重试布局，使三石都承担分流。"
		return true
	return _reject("挪三石改变来势，试一股，再于真实空隙调息。")
func next_demo_action()->Dictionary:
	if state.is_empty() or state.complete:return {}
	if puzzle_id==IDS[0]:
		if state.steps>0:return {"type":"step"}
		if state.axle!=3:return {"type":"axle","length":3}
		if state.left_phase!=state.steps%4:return {"type":"phase","side":"left","value":0}
		if state.right_phase!=(2+state.steps)%4:return {"type":"phase","side":"right","value":2}
		if state.cargo.heavy==-3:return {"type":"cargo","bundle":"heavy","position":1 if state.cargo.light!=1 else -1}
		if state.cargo.light!=-3:return {"type":"cargo","bundle":"light","position":-3}
		if state.cargo.heavy!=2:return {"type":"cargo","bundle":"heavy","position":2}
		return {"type":"step"}
	if state.awaiting_breath:return {"type":"breathe"}
	if state.locked and (not state.last_safe or state.wave>=3):return {"type":"retry"}
	if not state.locked:
		for i in range(3):
			if state.rows[i]!=i+1:return {"type":"stone","index":i,"row":i+1}
			if state.turns[i]!="/":return {"type":"turn","index":i,"orientation":"/"}
	return {"type":"pulse"}
func assistance_status()->String:
	if state.is_empty():return "unknown"
	return "assisted" if state.assisted or state.history_status=="assisted" else state.history_status
func _hint()->String:
	if state.hint==0:return ""
	if puzzle_id==IDS[0]:return ["", "轴承间距3格；左右腿应交替，不要同时落地。", "两包分别重2筹、3筹。筹重×到轴距离相加为0；曲柄需错开2相。", "轻包放左3、重包放右2；轴3、左相0、右相2，再试走3步。可明确请求逐步协助。"][state.hint]
	return ["", "右岸是梁萧调息处，必须把来势导出上/下边界。", "三股来势从左侧第1、2、3行依次入阵；斜石会转向，移石后看实际路径。", "甲石第1行、乙石第2行、丙石第3行，都朝/。每次引势后单独调息；三石都要参与。"][state.hint]
func get_view()->Dictionary:
	if state.is_empty():return {}
	return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":"木牛修复 · 负载试走" if puzzle_id==IDS[0] else "乱石悟道 · 引势调息","state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"calculation":calculation(),"preview":trace(mini(3,state.wave+1)) if puzzle_id==IDS[1] else {},"instruction":"有限教学示意，不等于完整木牛机械或真实武学；调整与试验不扣人物资源。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(saved):return false
	var data:Dictionary=_normalize(saved)
	if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
	var r:=ChapterTenPuzzleResolver.new()
	if not r.begin(data.puzzle_id,data.attempt_id,trusted_context) or data.get("context_hash")!=_hash(r.context):return false
	for command in data.input_log:
		if not command is Dictionary or not r._apply(command).ok:return false
	if r.state!=data.state:return false
	puzzle_id=r.puzzle_id;attempt_id=r.attempt_id;context=r.context;state=r.state;input_log=r.input_log;message=r.message;return true
func set_context(c:Dictionary)->bool:return _bounded_tree(c) and _normalize(c)==context
func receipt()->Dictionary:
	if state.is_empty() or not state.complete:return {}
	return {"resolver_version":VERSION,"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"scene_id":context.scene_id,"objective_id":"wooden_ox_repaired" if puzzle_id==IDS[0] else "stone_array_verified","context_hash":_hash(context),"input_log":input_log.duplicate(true),"final_state":state.duplicate(true),"assistance_status":assistance_status(),"assisted":assistance_status()!="manual","manual_process_verified":assistance_status()=="manual","validation_results":{"complete_process":true,"no_xp":true}}
func proof()->Dictionary:return receipt()
func get_receipts()->Array:return [receipt()] if not receipt().is_empty() else []
static func replay_receipt(proof:Dictionary,id:String,attempt:String,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(proof):return false
	var p:Dictionary=_normalize(proof)
	if not p.get("puzzle_id") is String or not p.get("attempt_id") is String or p.get("puzzle_id")!=id or p.get("attempt_id")!=attempt:return false
	var r:=ChapterTenPuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
	return not r.receipt().is_empty() and r.receipt()==p
