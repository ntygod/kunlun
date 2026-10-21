extends VBoxContainer
signal input_submitted(action:Dictionary)
signal close_requested
const Board=preload("res://scripts/ui/chapter_nine_puzzle_board.gd")
const PINE_PATH=Board.PINE_PATH
const PART_NAMES:={"body":"机身","left_wing":"左翼","right_wing":"右翼","tail":"尾舵","frame":"骨架","linkage":"绞柄"}
const STAGES:={"collecting":"取材","assembling":"组装","prepared":"组装完成，返回剧情","cranking":"双人绞动","mooring_released":"解缆","rail_moving":"沿轨行进","stalled":"固定失速","palm_lifted":"掌风误托","cloud_exit":"云海出口","water_landed":"水落","drifted":"木鸟漂去","completed":"已归档"}
var _view:Dictionary={}
var _identity:=""
var _epoch:=0
var _stage_epoch:=0
var _stage:=""
var _selected:="start"
var _buttons:Dictionary={}
var _labels:Dictionary={}
var _board:Control
var _scroll:ScrollContainer
var _side:VBoxContainer
var _timer:Timer
var _demo_running:=false
var _demo_steps:=0
var _demo_identity:=""
func _ready() -> void:
	visibility_changed.connect(func():
		if not is_visible_in_tree():stop_demonstration())
	resized.connect(_resize_board)
func _notification(what:int) -> void:
	if what in [NOTIFICATION_PAUSED,NOTIFICATION_EXIT_TREE]:stop_demonstration()
func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_F9]:stop_demonstration()
func _pine() -> bool:return str(_view.get("puzzle_id","")).contains("pine")
func stop_demonstration() -> void:
	_demo_running=false
	if is_instance_valid(_timer):_timer.stop()
	if _buttons.has("demo"):_buttons.demo.text="演示本题"
	if _buttons.has("stop"):_buttons.stop.disabled=true
func render(view:Dictionary) -> void:
	var identity:String=str(view.get("puzzle_id",""))+":"+str(view.get("attempt_id",""))+":"+str(view.get("token",""))
	var state:Dictionary=view.get("state",{})
	var stage:String=str(state.get("stage","pine"))
	_view=view.duplicate(true)
	if identity!=_identity:
		stop_demonstration();_epoch+=1;_stage_epoch+=1;_identity=identity;_stage=stage;_selected="start" if _pine() else "char_liang_xiao"
		for child in get_children():remove_child(child);child.queue_free()
		_buttons.clear();_labels.clear();_build()
	elif stage!=_stage:
		_stage=stage;_stage_epoch+=1;_rebuild_operations()
	if state.get("complete",false) or stage in ["drifted","completed"]:stop_demonstration()
	_refresh();_resize_board.call_deferred()
func _label(key:String,parent:Node) -> Label:
	var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label);_labels[key]=label;return label
func _flow(parent:Node) -> HFlowContainer:
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",3);flow.add_theme_constant_override("v_separation",3);parent.add_child(flow);return flow
func _button(key:String,title:String,parent:Node,action:Dictionary={},callback:Callable=Callable(),stage_bound:bool=false) -> Button:
	var button:=Button.new();button.text=title;button.set_meta("puzzle_focus","ch09:"+key);button.set_meta("action_id",key);parent.add_child(button);_buttons[key]=button
	var born:int=_epoch;var phase:int=_stage_epoch
	button.pressed.connect(func():
		if born!=_epoch or (stage_bound and phase!=_stage_epoch) or not is_visible_in_tree() or get_tree().paused:return
		if callback.is_valid():callback.call()
		else:_send(action))
	return button
func _op(key:String,title:String,parent:Node,action:Dictionary) -> void:_button("op:"+key,title,parent,action,Callable(),true)
func _build() -> void:
	add_theme_constant_override("separation",3)
	var font:=get_theme_default_font();theme=Theme.new();theme.default_font=font;theme.default_font_size=13
	for name in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("3d535b") if name in ["hover","focus"] else Color("25363b")
		style.content_margin_left=5;style.content_margin_right=5;style.content_margin_top=2;style.content_margin_bottom=2;theme.set_stylebox(name,"Button",style)
	_label("title",self)
	_label("rules",self)
	_label("formula",self)
	var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(row)
	_board=Board.new();_board.custom_minimum_size=Vector2(210,155);_board.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_board)
	var born:int=_epoch
	_board.cell_chosen.connect(func(x:int,y:int):
		if born==_epoch and is_visible_in_tree() and not get_tree().paused:_choose_cell(x,y))
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_scroll)
	_side=VBoxContainer.new();_side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_side)
	_label("status",_side)
	var operations:=VBoxContainer.new();operations.name="Operations";_side.add_child(operations);_rebuild_operations()
	_label("hint",_side)
	_label("details",_side)
	var footer:=_flow(self)
	for item in [["hint","提示"],["assist","协助一步"],["demo","演示本题"],["stop","停止"],["retry","重试"],["close","暂歇"]]:
		match item[0]:
			"demo":_button("demo",item[1],footer,{},_toggle_demo)
			"stop":_button("stop",item[1],footer,{},stop_demonstration)
			"close":_button("close",item[1],footer,{},func():stop_demonstration();close_requested.emit())
			_:_button(item[0],item[1],footer,{"type":"assist_step_v1" if item[0]=="assist" else item[0]})
	_label("message",self).max_lines_visible=2
	_timer=Timer.new();_timer.wait_time=0.25;add_child(_timer);_timer.timeout.connect(func():
		if born==_epoch:_tick())
func _rebuild_operations() -> void:
	if not is_instance_valid(_side):return
	var parent:Node=_side.get_node("Operations")
	for child in parent.get_children():parent.remove_child(child);child.queue_free()
	for key in _buttons.keys():
		if key.begins_with("op:"):_buttons.erase(key)
	var flow:=_flow(parent)
	if _pine():
		for pin in ["start","middle","end","move"]:
			var value:String=pin
			_button("op:select:"+pin,{"start":"生门针","middle":"景门针","end":"阵眼针","move":"移动领阵"}[pin],flow,{},func():_selected=value;_refresh(),true)
		for pin in ["start","middle","end"]:_op("remove:"+pin,"撤"+{"start":"生","middle":"景","end":"眼"}[pin],flow,{"type":"remove","pin":pin})
		_button("op:move","推演一拍",flow,{},_move_next,true)
		_op("wait","等下一声",flow,{"type":"wait"});_op("wait_window","等到下一时窗",flow,{"type":"wait_window"});_op("finish","验阵",flow,{"type":"finish"})
	else:
		for who in ["char_liang_xiao","char_axue"]:
			var actor:String=who
			_button("op:actor:"+who,"选梁" if who=="char_liang_xiao" else "选雪",flow,{},func():_selected=actor;_refresh(),true)
		if _stage in ["collecting","assembling"]:
			for part in PART_NAMES:
				var line:=_flow(parent)
				var choices:Array={"body":[["body","机身6"]],"left_wing":[["light","左轻3"],["heavy","左厚5"]],"right_wing":[["light","右轻3"],["heavy","右厚5"]],"tail":[["single","尾1"],["double","尾2"]],"frame":[["straight","直竹1"],["flexible","韧竹2"]],"linkage":[["linked","绞柄联动"]]}[part]
				for choice in choices:_op("select:"+part+":"+choice[0],choice[1],line,{"type":"select","part":part,"value":choice[0]})
			flow=_flow(parent)
			_op("beat","推进施工拍",flow,{"type":"beat"})
			for edge in range(4):_op("connect:%d"%edge,"接风车%d"%(edge+1),flow,{"type":"connect","edge":edge})
			for who in ["char_liang_xiao","char_axue"]:
				for value in [-1,1]:_op("stand:%s:%d"%[who,value],("梁" if who=="char_liang_xiao" else "雪")+("前梁" if value==-1 else "后梁"),flow,{"type":"stand","actor":who,"value":value})
			_op("wind","观察风口",flow,{"type":"wind"});_op("trial","装配试验",flow,{"type":"trial"})
		elif not _view.state.get("complete",false):
			for item in [["crank","双人绞动"],["release","共同解缆"],["rail","沿轨一格"],["advance","继续飞行阶段"]]:_op(item[0],item[1],flow,{"type":item[0]})
func _send(action:Dictionary) -> void:
	if not is_visible_in_tree() or get_tree().paused:return
	stop_demonstration();input_submitted.emit(action)
func _choose_cell(x:int,y:int) -> void:
	if _pine():_send({"type":"move","x":x,"y":y} if _selected=="move" else {"type":"place","pin":_selected,"x":x,"y":y})
	else:
		for actor in _view.state.get("actors",{}):
			if _view.state.actors[actor]==[x,y]:_selected=actor;_refresh();return
		_send({"type":"assign","actor":_selected,"x":x,"y":y})
func _move_next() -> void:
	var next:int=int(_view.state.get("cursor",-1))+1
	if next<PINE_PATH.size():_send({"type":"move","x":PINE_PATH[next][0],"y":PINE_PATH[next][1]})
func _toggle_demo() -> void:
	if _demo_running:stop_demonstration();return
	if int(_view.state.get("hint",0))<3 or _view.state.get("complete",false):return
	_demo_running=true;_demo_identity=_identity;_demo_steps=0;_timer.start();_refresh()
func _tick() -> void:
	if not _demo_running:return
	if not is_visible_in_tree() or get_tree().paused or _demo_identity!=_identity or _view.state.get("complete",false) or _stage in ["drifted","completed"] or _demo_steps>=256 or _view.get("next_action",{}).get("type","")=="retry":stop_demonstration();return
	var before:String=JSON.stringify(_view.state);_demo_steps+=1
	input_submitted.emit({"type":"assist_step_v1"})
	if JSON.stringify(_view.state)==before:stop_demonstration()
func _refresh() -> void:
	if not is_instance_valid(_board):return
	var s:Dictionary=_view.state;_board.render(_view,_selected)
	_labels.title.text=str(_view.get("title","松针推阵" if _pine() else "双人木鸟"))
	_labels.rules.text="四邻路径；生门0 / 景门1 / 阵眼2。走或等一拍，号角相位+1（模3）。" if _pine() else "六件有限料；梁翼轴(3,2)，雪尾架(5,2)。四邻走到黄框，再推进施工拍。"
	_labels.formula.text="三针：生(4,4)、景(2,2)、眼(0,0)。旗格不可走；可等待，无资源损失。" if _pine() else "质量=6+双翼+尾+7≤21；力矩=3×尾+4×梁位+3×雪位=-1；强度≥2、双翼等重、四连接。"
	_labels.message.text=str(_view.get("message",""));_labels.hint.text=str(_view.get("hint_text",""));_labels.details.text=str(_view.get("instruction",""))
	if _pine():
		var next:int=int(s.get("cursor",-1))+1
		_labels.status.text="号角相位：%d\n当前：%s → 下一格：%s\n选中：%s"%[int(s.get("phase",0)),"盘外" if next==0 else str(PINE_PATH[mini(next-1,8)]),str(PINE_PATH[next]) if next<9 else "阵眼已达",{"start":"生门针","middle":"景门针","end":"阵眼针","move":"领阵移动"}.get(_selected,_selected)]
	else:
		var c:Dictionary=_view.get("calculation",{})
		_labels.status.text="%s · 选%s\n质量%s/21，力矩%s/-1，强度%s/2\n已装%d/6 · 连接%d/4 · 绞动%d\n配件：%s\n梁位%s / 雪位%s；风：%s"%[("准备就绪，双人绞动" if _stage=="prepared" and not s.get("complete",false) else STAGES.get(_stage,_stage)),"梁" if _selected=="char_liang_xiao" else "雪",str(c.get("mass","?")),str(c.get("torque","?")),str(c.get("strength","?")),s.get("installed",[]).size(),s.get("connections",[]).size(),int(s.get("cranks",0)),_part_summary(s),str(s.get("positions",{}).get("char_liang_xiao",-1)),str(s.get("positions",{}).get("char_axue",-1)),"可借升力" if s.get("wind",0)==1 else "偏风"]
	if not _pine():
		var c:Dictionary=_view.get("calculation",{})
		var carrying:Dictionary=s.get("carrying",{})
		for actor in ["char_liang_xiao","char_axue"]:
			var carried:Array[String]=[]
			for part in carrying.get(actor,[]):carried.append(str(PART_NAMES.get(part,part)))
			_labels.status.text+="\n"+("梁搬件：" if actor=="char_liang_xiao" else "雪搬件：")+("无" if carried.is_empty() else "、".join(carried))
		var reasons:Array[String]=[]
		if int(c.get("mass",0))>21:reasons.append("超载")
		if int(c.get("torque",0))!=-1:reasons.append("重心偏后" if int(c.get("torque",0))>-1 else "重心过前")
		if int(c.get("strength",0))<2:reasons.append("骨架强度不足")
		if not c.get("balanced",false):reasons.append("左右翼不平衡")
		if not c.get("linked",false):reasons.append("四连接未齐")
		_labels.status.text+="\n"+("配重/结构条件通过" if reasons.is_empty() else "；".join(reasons))
	_labels.status.text+="\n"+str(_view.get("assistance_status",""))
	_buttons.demo.text="停止演示" if _demo_running else "演示本题"
	_buttons.demo.disabled=s.get("complete",false) or (int(s.get("hint",0))<3 and not _demo_running)
	_buttons.assist.disabled=s.get("complete",false) or int(s.get("hint",0))<3
	_buttons.retry.disabled=s.get("complete",false);_buttons.stop.disabled=not _demo_running
func _part_summary(s:Dictionary) -> String:
	var names:Dictionary={"body":"6筹","light":"轻3","heavy":"厚5","single":"薄1","double":"双薄2","straight":"直竹1","flexible":"韧竹2","linked":"双柄"}
	var values:Array[String]=[]
	for part in PART_NAMES:
		var value:String=str(s.get("parts",{}).get(part,"未选"))
		values.append(PART_NAMES[part]+str(names.get(value,value))+("✓" if part in s.get("installed",[]) else "待装"))
	return " / ".join(values)
func _resize_board() -> void:
	if is_instance_valid(_board):_board.custom_minimum_size=Vector2(clampf(size.x*0.42,198,440),155)
