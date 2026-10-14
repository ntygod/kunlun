class_name ChapterNinePuzzleResolver
extends RefCounted
# Hashes below detect accidental changes only. Authority is supplied by campaign
# context, and every retained command is replayed against that trusted context.
const VERSION:=1
const MAX_LOG:=4096
const SEGMENT_LIMIT:=512
const IDS:=["pz_ch09_pine_needle","pz_ch09_wood_bird"]
const PATH:=[[4,4],[4,3],[3,3],[3,2],[2,2],[2,1],[1,1],[1,0],[0,0]]
const PINS:={"start":[4,4],"middle":[2,2],"end":[0,0]}
const ACTORS:=["char_liang_xiao","char_axue"]
const STATIONS:={"char_liang_xiao":[3,2],"char_axue":[5,2]}
const RAIL:=[[4,3],[5,3],[6,3],[7,3],[8,3]]
const PARTS:={"body":["body"],"left_wing":["light","heavy"],"right_wing":["light","heavy"],"tail":["single","double"],"frame":["straight","flexible"],"linkage":["linked"]}
const STANDARD:={"body":"body","left_wing":"light","right_wing":"light","tail":"double","frame":"flexible","linkage":"linked"}
const STAGE_EVENTS:={"prepared":"evt_ch09_wood_bird_assembled","cranking":"evt_ch09_dual_crank_ready","mooring_released":"evt_ch09_release_mooring","rail_moving":"evt_ch09_launch_rail_traversed","stalled":"evt_ch09_fixed_stall","palm_lifted":"evt_ch09_he_palm_lift","cloud_exit":"evt_ch09_cloud_exit_reached","water_landed":"evt_ch09_water_landing","drifted":"evt_ch09_wood_bird_drifted"}
const Safe=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
var puzzle_id:=""
var attempt_id:=""
var context:Dictionary={}
var state:Dictionary={}
var input_log:Array=[]
var message:=""
var _events:Array=[]
var _entry:Dictionary={}
static func _bounded_tree(v:Variant)->bool:return Safe._bounded_tree(v)
static func _normalize(v:Variant)->Variant:return Safe._normalize(v)
static func _integer(v:Variant)->bool:return Safe._integer(v)
static func _hash(v:Variant)->String:return Safe._hash(v)
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
	if id not in IDS or attempt.length()>256 or not _bounded_tree(trusted_context):return false
	var c:Dictionary=_normalize(trusted_context)
	if not _integer(c.get("chapter")) or c.get("chapter")!=9 or not c.get("current_token") is String or c.current_token.is_empty() or not c.get("scene_id") is String or not c.get("actors") is Dictionary:return false
	if not c.actors.get(ACTORS[0]) is Dictionary or not _integer(c.actors[ACTORS[0]].get("hp")) or c.actors[ACTORS[0]].hp<=0:return false
	if id==IDS[1]:
		if not c.actors.get(ACTORS[1]) is Dictionary:return false
		for who in ACTORS:
			if c.actors[who].has("id") and (not c.actors[who].id is String or c.actors[who].id!=who):return false
			if c.actors[who].has("hp") and (not _integer(c.actors[who].hp) or c.actors[who].hp<=0):return false
		if c.scene_id not in ["ch09_wood_bird_assembly","ch09_cloud_escape"]:return false
	var s:Dictionary={"hint":0,"complete":false,"history_status":c.get("assistance_status","manual"),"assisted":false}
	if s.history_status not in ["manual","assisted","unknown"]:return false
	if id==IDS[0]:s.merge({"pins":{"start":[],"middle":[],"end":[]},"phase":0,"cursor":-1,"path":[],"gates":[]})
	else:
		if c.scene_id=="ch09_cloud_escape":
			if not c.get("wood_bird_checkpoint") is Dictionary or not c.get("wood_bird_context") is Dictionary:return false
			if c.wood_bird_context.get("scene_id")!="ch09_wood_bird_assembly" or c.wood_bird_context.has("wood_bird_checkpoint"):return false
			var prior:=ChapterNinePuzzleResolver.new()
			if not prior.restore(c.wood_bird_checkpoint,c.wood_bird_context) or prior.puzzle_id!=IDS[1] or prior.state.stage!="prepared" or not prior.state.complete:return false
			s=prior.state.duplicate(true);s.complete=false
			if c.get("assistance_status","manual")=="assisted":s.history_status="assisted";s.assisted=true
			elif c.get("assistance_status","manual")=="unknown" and s.history_status=="manual":s.history_status="unknown"
		else:
			# Material source is campaign-owned; opening this model cannot grant it.
			var auth:Variant=c.get("authorizations",[])
			if not auth is Array or "evt_ch09_pine_harvest_authorized" not in auth:return false
			if not c.get("material_receipt") is Dictionary or not c.get("choices") is Dictionary:return false
			if not _integer(c.material_receipt.get("quantity")):return false
			var prayer:Variant=c.choices.get("choice_ch09_pine_prayer")
			if prayer not in ["ch09_prayer_life","ch09_prayer_repay"]:return false
			if c.material_receipt!={"id":"evt_ch09_pine_harvest_authorized","source":"living_pine_after_prayer","owner":"scene","quantity":1,"parts":["body","left_wing","right_wing","tail","frame","linkage"],"prayer":prayer}:return false
			s.merge({"stage":"collecting","parts":STANDARD.duplicate(),"installed":[],"connections":[],"actors":{"char_liang_xiao":[0,5],"char_axue":[0,6]},"actor_paths":{"char_liang_xiao":[[0,5]],"char_axue":[[0,6]]},"orders":{},"positions":{"char_liang_xiao":-1,"char_axue":-1},"wind":0,"cranks":0,"passengers":[],"both_safe":false,"rail_index":0,"rail_path":[RAIL[0].duplicate()],"flags":[],"construction":[],"carrying":{"char_liang_xiao":["body","left_wing","right_wing"],"char_axue":["frame","tail","linkage"]},"part_owners":{"body":"char_liang_xiao","left_wing":"char_liang_xiao","right_wing":"char_liang_xiao","frame":"char_axue","tail":"char_axue","linkage":"char_axue"}})
	puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;state=s;input_log=[];_events=[];_entry=s.duplicate(true);message="有限教学模型：按公开规则逐步操作，错误不扣资源。"
	return true
func _safe(a:Dictionary)->bool:
	if not _bounded_tree(a):return false
	a=_normalize(a)
	var schemas:Dictionary={"place":{"pin":"s","x":"i","y":"i"},"remove":{"pin":"s"},"move":{"x":"i","y":"i"},"wait":{},"wait_window":{},"retry":{},"hint":{},"assist_step_v1":{},"finish":{},"select":{"part":"s","value":"s"},"assign":{"actor":"s","x":"i","y":"i"},"beat":{},"connect":{"edge":"i"},"stand":{"actor":"s","value":"i"},"wind":{},"trial":{},"crank":{},"release":{},"rail":{},"advance":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
	if not a.get("type") is String or not schemas.has(a.type):return false
	var schema:Dictionary=schemas[a.type]
	if a.size()!=schema.size()+1:return false
	for k in schema:
		if not a.has(k) or (schema[k]=="s" and not a[k] is String) or (schema[k]=="i" and not _integer(a[k])):return false
	return true
func apply_input(action:Dictionary)->Dictionary:
	if str(action.get("type",""))=="reset_after_limit":return {"ok":false,"message":"内部摘要不是玩家操作。"}
	return _apply_input(action)
func _prefix_count()->int:
	for i in range(_events.size()-1,-1,-1):
		if _events[i].get("gate",false):return i+1
	return 0
func _apply_input(action:Dictionary)->Dictionary:
	if puzzle_id.is_empty() or not _safe(action) or input_log.size()>=MAX_LOG:return {"ok":false,"message":"操作格式无效或记录已满；原状态未改。"}
	var a:Dictionary=_normalize(action)
	if input_log.size()-_prefix_count()>=SEGMENT_LIMIT and a.type!="reset_after_limit":
		if a.type!="retry" or state.complete:return {"ok":false,"message":"本段记录已满；重试保留已验前缀，丢弃尾段记未知。"}
		var prefix:Array=input_log.slice(0,_prefix_count()).duplicate(true)
		var marker:Dictionary={"type":"reset_after_limit","hint":state.hint,"assisted":1 if assistance_status()=="assisted" else 0}
		var id:String=puzzle_id;var attempt:String=attempt_id;var c:Dictionary=context.duplicate(true)
		if not begin(id,attempt,c):return {"ok":false,"message":"可信入口失效。"}
		for command in prefix:_apply_input(command)
		return _apply_input(marker)
	var old:Dictionary=state.duplicate(true)
	var ok:=_operate(a)
	if not ok:state=old;return {"ok":false,"message":message}
	input_log.append(a.duplicate(true));_events.append({"action":a.duplicate(true),"state":_hash(state),"gate":puzzle_id==IDS[0] and old.gates.size()<state.gates.size()})
	return {"ok":true,"message":message,"view":get_view(),"receipt":receipt(),"receipts":get_receipts()}
func _reject(reason:String)->bool:message=reason;return false
func _operate(a:Dictionary)->bool:
	if state.complete:return _reject("本节点已验证；收起继续剧情。")
	if a.type=="reset_after_limit":
		if input_log.size()!=_prefix_count() or a.hint<state.hint or a.hint>3 or a.assisted not in [0,1]:return _reject("内部重试记录无效。")
		state.hint=a.hint
		state.assisted=state.assisted or a.assisted==1
		state.history_status="assisted" if state.assisted or state.history_status=="assisted" else "unknown"
		message="已验前缀保留；丢弃尾段的历史不可认证，绝不宣称全手工。";return true
	if a.type=="hint":state.hint=mini(3,state.hint+1);message=_hint();return true
	if a.type=="assist_step_v1":
		if state.hint<3:return _reject("先读三层提示。")
		var next:=next_demo_action()
		if next.is_empty():return _reject("暂无合法下一步。")
		state.assisted=true;state.history_status="assisted";return _operate(next)
	if a.type=="retry":
		var h:int=state.hint;var assisted:bool=state.assisted;var history:String=state.history_status
		state=_entry.duplicate(true);state.hint=h;state.assisted=assisted;state.history_status=history
		message="回到可信本节点入口；完整旧操作保留，协助状态不降级。";return true
	if puzzle_id==IDS[0]:return _pine(a)
	return _bird(a)
func _pine(a:Dictionary)->bool:
	if a.type=="place":
		if state.cursor!=-1 or not PINS.has(a.pin) or a.x<0 or a.x>4 or a.y<0 or a.y>4:return _reject("只可入阵前在5×5盘摆针。")
		for pin in state.pins:
			if pin!=a.pin and state.pins[pin]==[a.x,a.y]:return _reject("两针不能占同格。")
		state.pins[a.pin]=[a.x,a.y];return true
	if a.type=="remove":
		if state.cursor!=-1 or not PINS.has(a.pin):return _reject("入阵前才可撤针。")
		state.pins[a.pin]=[];return true
	if a.type in ["wait","wait_window"]:
		var count:=1
		if a.type=="wait_window":
			var desired:int={0:0,4:1,8:2}.get(state.cursor+1,state.phase)
			count=(desired-state.phase+3)%3
			if count==0:return _reject("当前已是可行时窗，无需等待。")
		for i in range(count):state.phase=(state.phase+1)%3;state.path.append({"type":"wait","phase_after":state.phase})
		return true
	if a.type=="move":
		if state.pins!=PINS:return _reject("三针须先指生门(4,4)、景门(2,2)、阵眼(0,0)。")
		var index:int=state.cursor+1
		if index>=PATH.size() or [a.x,a.y]!=PATH[index]:return _reject("只能沿公开四邻路径走下一格，旗格封锁。")
		if {0:0,4:1,8:2}.has(index) and state.phase!={0:0,4:1,8:2}[index]:return _reject("门窗未开，可等下一声号角。")
		state.cursor=index;state.phase=(state.phase+1)%3;state.path.append({"type":"move","cell":[a.x,a.y],"phase_after":state.phase})
		if index in [0,4,8]:state.gates.append(index)
		state.complete=index==8;return true
	return _reject("摆针后逐格推演，等待调整三相；不接受直接完成。")
func calculation()->Dictionary:
	if puzzle_id!=IDS[1]:return {}
	var p:Dictionary=state.parts;var tail:int=2 if p.tail=="double" else 1
	var mass:int=6+(3 if p.left_wing=="light" else 5)+(3 if p.right_wing=="light" else 5)+tail+7
	var torque:int=3*tail+4*state.positions.char_liang_xiao+3*state.positions.char_axue
	var strength:int=2 if p.frame=="flexible" else 1
	return {"mass":mass,"torque":torque,"strength":strength,"balanced":p.left_wing==p.right_wing,"linked":state.connections.size()==4,"valid":mass<=21 and torque==-1 and strength>=2 and p.left_wing==p.right_wing and state.connections.size()==4 and state.installed.size()==6}
func _cell_ok(cell:Array,who:String)->bool:
	if cell[0]<0 or cell[0]>8 or cell[1]<0 or cell[1]>6:return false
	for other in ACTORS:
		if other!=who and state.actors[other]==cell:return false
	return true
func _route(who:String,target:Array)->Array:
	if not _cell_ok(target,who) or state.actors[who]==target:return []
	var queue:Array=[state.actors[who]];var seen:Dictionary={str(state.actors[who]):[]}
	while not queue.is_empty():
		var here:Array=queue.pop_front()
		for d in [[0,-1],[1,0],[0,1],[-1,0]]:
			var cell:Array=[here[0]+d[0],here[1]+d[1]]
			if not _cell_ok(cell,who) or seen.has(str(cell)):continue
			var route:Array=seen[str(here)].duplicate(true);route.append(cell)
			if cell==target:return route
			seen[str(cell)]=route;queue.append(cell)
	return []
func _mark(stage:String)->void:
	state.stage=stage
	if stage not in state.flags:state.flags.append(stage)
func _bird(a:Dictionary)->bool:
	var editing:bool=state.stage in ["collecting","assembling"]
	if a.type=="select":
		if not editing or not PARTS.has(a.part) or a.value not in PARTS[a.part]:return _reject("只可在装配阶段选有限合法规格。")
		state.parts[a.part]=a.value;state.installed.erase(a.part)
		var owner:String=ACTORS[0] if a.part in ["body","left_wing","right_wing"] else ACTORS[1]
		state.part_owners[a.part]=owner
		if a.part not in state.carrying[owner]:state.carrying[owner].append(a.part)
		if a.part=="linkage":state.connections=[]
		return true
	if a.type=="assign":
		if not editing or a.actor not in ACTORS:return _reject("仅施工阶段可走工作位。")
		var route:=_route(a.actor,[a.x,a.y])
		if route.is_empty():return _reject("目标不可达或已到达，不瞬移。")
		state.orders[a.actor]=route;return true
	if a.type=="beat":
		if not editing:return _reject("当前不是施工阶段。")
		if not state.orders.is_empty():
			var moved:=false
			for who in ACTORS:
				if not state.orders.has(who):continue
				var next:Array=state.orders[who][0]
				if not _cell_ok(next,who):
					var detour:=_route(who,state.orders[who][-1])
					if detour.is_empty():continue
					state.orders[who]=detour;next=detour[0]
				state.actors[who]=next;state.actor_paths[who].append(next.duplicate());state.orders[who].pop_front();moved=true
				if state.orders[who].is_empty():state.orders.erase(who)
			if not moved:return _reject("路径被另一人占据；请改目标。")
			return true
		if state.actors!=STATIONS:return _reject("梁与雪都须走到工位，方可并行施工。")
		for pair in [["body","frame"],["left_wing","tail"],["right_wing","linkage"]]:
			if pair[0] not in state.installed or pair[1] not in state.installed:
				for part in pair:
					if part not in state.installed:
						state.installed.append(part)
						for who in ACTORS:state.carrying[who].erase(part)
						state.part_owners[part]="wood_bird"
				state.construction.append({"parts":pair.duplicate(),"actors":state.actors.duplicate(true)})
				state.stage="assembling";return true
		return _reject("六构件均装妥，请接四风车并试验。")
	if a.type=="connect":
		if not editing or "linkage" not in state.installed or state.actors!=STATIONS or a.edge<0 or a.edge>3 or a.edge in state.connections:return _reject("联动件装妥、两人到位后接四条独立边。")
		state.connections.append(a.edge);return true
	if a.type=="stand":
		if not editing or a.actor not in ACTORS or a.value not in [-1,1]:return _reject("只能选前梁-1或后梁+1。")
		state.positions[a.actor]=a.value;return true
	if a.type=="wind":
		if not editing:return _reject("起飞后不可调风窗。")
		state.wind=1-state.wind;return true
	if a.type in ["trial","finish"]:
		if not editing or not calculation().valid or state.actors!=STATIONS or not state.orders.is_empty() or state.wind!=1:return _reject("须六件/四连接齐、两人到位、质量≤21、力矩=-1、强度≥2、翼平衡、可借升力。")
		_mark("prepared");state.complete=true;return true
	if a.type=="crank":
		if state.stage!="prepared" or context.scene_id!="ch09_cloud_escape" or state.actors!=STATIONS:return _reject("从可信准备记录进入逃峰后，双人同拍绞动。")
		state.cranks=2;state.passengers=ACTORS.duplicate();_mark("cranking");return true
	if a.type=="release":
		if state.stage!="cranking" or state.cranks!=2:return _reject("双柄真实绞动后才可解缆。")
		_mark("mooring_released");return true
	if a.type=="rail":
		if state.stage not in ["mooring_released","rail_moving"] or state.rail_index>=RAIL.size()-1:return _reject("解缆后沿有向轨道逐格前行。")
		state.rail_index+=1;state.rail_path.append(RAIL[state.rail_index].duplicate());state.stage="rail_moving"
		if state.rail_index==RAIL.size()-1:_mark("rail_moving")
		return true
	if a.type=="advance":
		var stages:Array=["rail_moving","stalled","palm_lifted","cloud_exit","water_landed","drifted"]
		var index:int=stages.find(state.stage)
		if index<0 or index>=stages.size()-1 or state.rail_index!=RAIL.size()-1:return _reject("须完整轨道才可触发固定失速与掌托。")
		_mark(stages[index+1])
		if state.stage=="water_landed":state.both_safe=state.passengers==ACTORS
		state.complete=state.stage=="drifted" and state.both_safe;return true
	return _reject("此操作不适用于当前阶段。")
func next_demo_action()->Dictionary:
	if state.complete:return {}
	if puzzle_id==IDS[0]:
		for pin in PINS:
			if state.pins[pin]!=PINS[pin]:
				for other in PINS:
					if other!=pin and state.pins[other]==PINS[pin]:return {"type":"remove","pin":other}
				return {"type":"place","pin":pin,"x":PINS[pin][0],"y":PINS[pin][1]}
		var index:int=state.cursor+1
		if {0:0,4:1,8:2}.has(index) and state.phase!={0:0,4:1,8:2}[index]:return {"type":"wait"}
		return {"type":"move","x":PATH[index][0],"y":PATH[index][1]}
	if state.stage in ["collecting","assembling"]:
		for part in STANDARD:
			if state.parts[part]!=STANDARD[part]:return {"type":"select","part":part,"value":STANDARD[part]}
		for who in ACTORS:
			if state.positions[who]!=-1:return {"type":"stand","actor":who,"value":-1}
		for who in ACTORS:
			if state.actors[who]!=STATIONS[who] and not state.orders.has(who):return {"type":"assign","actor":who,"x":STATIONS[who][0],"y":STATIONS[who][1]}
		if not state.orders.is_empty() or state.installed.size()<6:return {"type":"beat"}
		for edge in range(4):
			if edge not in state.connections:return {"type":"connect","edge":edge}
		if state.wind!=1:return {"type":"wind"}
		return {"type":"trial"}
	if state.stage=="prepared":return {"type":"crank"}
	if state.stage=="cranking":return {"type":"release"}
	if state.rail_index<RAIL.size()-1:return {"type":"rail"}
	return {"type":"advance"}
func assistance_status()->String:return "assisted" if state.assisted else str(state.history_status)
func _hint()->String:
	var hints:Array=["辨认东南生门、中岳景门、西北阵眼。","入门前相位分别0/1/2；移动和等待均+1模3。","三针定位后沿公开路径逐步走；错过开口可等待。"] if puzzle_id==IDS[0] else ["先让梁与雪各走到标记工位，共同装六件。","骨架与绞柄质量含于机身6；轻翼3+3、双尾2、两人4+3，总21。","两人前梁，力矩6-4-3=-1；韧竹强度2，四连接、借风后试验。起飞仍须绞动解缆逐格行轨。"]
	return hints[maxi(0,state.hint-1)]
func instruction()->String:
	if puzzle_id==IDS[0]:return "5×5有限教学阵，非完整玄黄九变。三针start生门(4,4)、middle景门(2,2)、end阵眼(0,0)。路径(4,4)→(4,3)→(3,3)→(3,2)→(2,2)→(2,1)→(1,1)→(1,0)→(0,0)，其余阵旗封锁。生门/景门/阵眼仅入前相位0/1/2开放。入阵、走一步、等一声均相位+1 mod3；拒绝不改状态。"
	return "有限配重教学，非航空设计。六件：机身6、左右翼各轻3/重5、尾1/2、骨架强度1/2、绞柄。骨架/柄质量已含机身。总质量=6+左右翼+尾+梁4+雪3≤21；力矩=3×尾+4×梁位+3×雪位=-1；前梁-1/后梁+1。左右同翼，强度≥2，四风车全连接。梁雪走四邻到工位，同施工拍装一对件；借风试验只准备，无500。逃峰须双柄→解缆→轨道→失速→掌托→云海→水落→漂去。"
func get_view()->Dictionary:
	var out:Dictionary={"kind":"chapter_nine","puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.get("current_token",""),"title":"松针三相推阵" if puzzle_id==IDS[0] else "木鸟 · 双人施工与逃峰","state":state.duplicate(true),"instruction":instruction(),"message":message,"hint_text":_hint() if state.hint>0 else "","assistance_status":assistance_status(),"next_action":next_demo_action(),"path":PATH.duplicate(true),"stations":STATIONS.duplicate(true),"rail":RAIL.duplicate(true),"calculation":calculation(),"receipt":receipt(),"receipts":get_receipts()}
	if puzzle_id==IDS[1]:
		var actors:Dictionary={}
		for who in ACTORS:actors[who]=[176+16*state.actors[who][0],144+16*state.actors[who][1]]
		# Workstation paths stay as construction evidence; aboard movement belongs
		# to the shared vehicle rail, not a fabricated walking route.
		if state.passengers==ACTORS:
			for i in range(ACTORS.size()):actors[ACTORS[i]]=[176+16*RAIL[state.rail_index][0]-6+12*i,144+16*RAIL[state.rail_index][1]]
		out.world_state={"actors":actors,"actor_positions":actors.duplicate(true),"control_actor_id":ACTORS[0],"player_position":actors[ACTORS[0]],"visible_actor_ids":ACTORS.duplicate(),"map_id":"map_ch09_tiandu_peak","objective_id":IDS[1],"target_position":[224,176],"wood_bird":{"installed":state.installed.duplicate(),"position":[176+16*RAIL[state.rail_index][0],144+16*RAIL[state.rail_index][1]],"stage":state.stage}}
	return out
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(saved):return false
	saved=_normalize(saved)
	if saved.size()!=6 or saved.get("version")!=VERSION or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("input_log") is Array or not saved.get("state") is Dictionary or saved.input_log.size()>MAX_LOG:return false
	var r:=ChapterNinePuzzleResolver.new()
	if not r.begin(saved.puzzle_id,saved.attempt_id,trusted_context) or saved.get("context_hash")!=_hash(r.context):return false
	for a in saved.input_log:
		if not a is Dictionary or not r._apply_input(a).ok:return false
	if r.state!=saved.state:return false
	puzzle_id=r.puzzle_id;attempt_id=r.attempt_id;context=r.context;state=r.state;input_log=r.input_log;_events=r._events;_entry=r._entry;message=r.message
	return true
func set_context(c:Dictionary)->bool:return _bounded_tree(c) and _normalize(c)==context
func receipt()->Dictionary:
	if state.is_empty() or not state.complete:return {}
	return {"resolver_version":VERSION,"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"scene_id":context.scene_id,"objective_id":"pine_needle_verified" if puzzle_id==IDS[0] else ("wood_bird_prepared" if state.stage=="prepared" else "wood_bird_escaped"),"context_hash":_hash(context),"input_log":input_log.duplicate(true),"final_state":state.duplicate(true),"assistance_status":assistance_status(),"assisted":assistance_status()!="manual","manual_process_verified":assistance_status()=="manual","validation_results":{"complete_process":true,"no_xp":true}}
func get_receipts()->Array:
	if state.is_empty():return []
	var out:Array=[]
	if puzzle_id==IDS[1]:
		for stage in state.flags:out.append({"event_id":STAGE_EVENTS[stage],"stage":stage,"puzzle_id":puzzle_id})
	if state.complete:out.append(receipt())
	return out
static func replay_receipt(proof:Dictionary,id:String,attempt:String,trusted_context:Dictionary={}) -> bool:
	if not _bounded_tree(proof):return false
	proof=_normalize(proof)
	if proof.get("puzzle_id")!=id or proof.get("attempt_id")!=attempt:return false
	var r:=ChapterNinePuzzleResolver.new()
	if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":proof.get("context_hash",""),"input_log":proof.get("input_log",[]),"state":proof.get("final_state",{})},trusted_context):return false
	return not r.receipt().is_empty() and r.receipt()==proof
