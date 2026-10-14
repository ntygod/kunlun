extends VBoxContainer
signal input_submitted(action:Dictionary)
signal close_requested
const Board=preload("res://scripts/ui/chapter_eight_puzzle_board.gd")
const NAMES:={"char_liang_xiao":"梁·绞盘","npc_ranya":"兰·测水","npc_guo_shoujing":"郭·宽船锚","left":"左船","middle":"中船","wide":"宽船（2格）"}
var _view:Dictionary={}
var _identity:=""
var _epoch:=0
var _buttons:Dictionary={}
var _labels:Dictionary={}
var _selects:Dictionary={}
var _board:Control
var _side:VBoxContainer
var _scroll:ScrollContainer
var _timer:Timer
var _selected:="char_liang_xiao"
var _source_pool:=-1
var _demo_running:=false
var _auto_move:=false
var _demo_stage:=-1
var _demo_steps:=0
func _ready() -> void:
	visibility_changed.connect(func():
		if not is_visible_in_tree():stop_demonstration())
	resized.connect(_resize_board)
func _notification(what:int) -> void:
	if what in [NOTIFICATION_PAUSED,NOTIFICATION_EXIT_TREE]:stop_demonstration()
func stop_demonstration() -> void:
	_demo_running=false;_auto_move=false
	if is_instance_valid(_timer):_timer.stop()
	if _buttons.has("demo"):_buttons.demo.text="演示本题"
	if _buttons.has("stop"):_buttons.stop.disabled=true
func render(view:Dictionary) -> void:
	var identity:String=str(view.get("puzzle_id",""))+":"+str(view.get("attempt_id",""))+":"+str(view.get("token",""))
	var old_stage:int=int(_view.get("state",{}).get("problem",_view.get("state",{}).get("phase",0)))
	_view=view.duplicate(true)
	if identity!=_identity:
		stop_demonstration();_epoch+=1;_identity=identity;_selected="char_liang_xiao";_source_pool=-1
		for child in get_children():remove_child(child);child.queue_free()
		_buttons.clear();_labels.clear();_selects.clear();_build()
	var stage:int=int(_view.state.get("problem",_view.state.get("phase",0)))
	if old_stage!=stage or _view.state.complete:
		stop_demonstration();_source_pool=-1
		_rebuild_operations()
	_refresh();_resize_board.call_deferred()
func _label(key:String,text:String,parent:Node) -> Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label);_labels[key]=label;return label
func _button(key:String,title:String,parent:Node,action:Dictionary={},callback:Callable=Callable()) -> Button:
	var b:=Button.new();b.text=title;b.set_meta("puzzle_focus","ch08:"+key);b.set_meta("action_id",key)
	parent.add_child(b);_buttons[key]=b
	var born:int=_epoch
	b.pressed.connect(func():
		if born!=_epoch or not is_visible_in_tree():return
		if callback.is_valid():callback.call()
		else:_send(action))
	return b
func _flow(parent:Node) -> HFlowContainer:
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",3);flow.add_theme_constant_override("v_separation",3);parent.add_child(flow);return flow
func _build() -> void:
	add_theme_constant_override("separation",3)
	var font:=get_theme_default_font();theme=Theme.new();theme.default_font=font;theme.default_font_size=13
	for style_name in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("3d535b") if style_name in ["hover","focus"] else Color("25363b")
		style.content_margin_left=5;style.content_margin_right=5;style.content_margin_top=2;style.content_margin_bottom=2;theme.set_stylebox(style_name,"Button",style)
	_label("title",_view.title,self)
	var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(row)
	_board=Board.new();_board.custom_minimum_size=Vector2(220,198);_board.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_board)
	var born:int=_epoch
	_board.cell_chosen.connect(func(x:int,y:int):
		if born==_epoch:_choose_cell(x,y))
	_board.day_chosen.connect(func(day:int):
		if born==_epoch and _view.puzzle_id=="numbers_ch08_ranya" and _view.state.problem==0:_send({"type":"day","value":day}))
	_board.pool_chosen.connect(func(pool:int):
		if born==_epoch and _view.puzzle_id=="numbers_ch08_ranya" and _view.state.problem==1:_choose_pool(pool))
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_scroll)
	_side=VBoxContainer.new();_side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_side)
	_label("rules",_view.instruction,_side)
	_label("status","",_side)
	var operations:=VBoxContainer.new();operations.name="Operations";_side.add_child(operations)
	_rebuild_operations()
	_label("hint","",_side)
	var footer:=_flow(self)
	_button("finish","验题/方案",footer,{"type":"finish"})
	_button("hint","提示",footer,{"type":"hint"})
	_button("assist","协助一步",footer,{"type":"assist_step_v1"})
	_button("demo","演示本题",footer,{},_toggle_demo)
	_button("stop","停止",footer,{},stop_demonstration)
	_button("retry","重试",footer,{"type":"retry"})
	_button("close","暂歇",footer,{},func():stop_demonstration();close_requested.emit())
	_label("message","",self)
	_timer=Timer.new();_timer.wait_time=0.22;add_child(_timer);_timer.timeout.connect(func():
		if born==_epoch:_tick())
func _rebuild_operations() -> void:
	if not is_instance_valid(_side):return
	var parent:Node=_side.get_node("Operations")
	for child in parent.get_children():parent.remove_child(child);child.queue_free()
	# Removed command controls must never retain callbacks into a newer stage.
	for key in _buttons.keys():
		if key.begins_with("op:"):_buttons.erase(key)
	var flow:=_flow(parent)
	if _view.puzzle_id=="numbers_ch08_ranya":
		match mini(int(_view.state.problem),2):
			0:
				for day in range(13):_stage_button("day:%d"%day,str(day)+"日",flow,{"type":"day","value":day})
			1:
				for edge in [[0,1],[1,0],[1,2],[2,1]]:_stage_button("water:%d:%d"%[edge[0],edge[1]],["A","B","C"][edge[0]]+"→"+["A","B","C"][edge[1]],flow,{"type":"transfer","from":edge[0],"to":edge[1]})
			2:
				for leg in range(1,7):_stage_button("leg:%d"%leg,"腿各%d尺"%leg,flow,{"type":"leg","value":leg})
	elif _view.puzzle_id=="cannon_ch08_calibration":
		for ammo in ["light","heavy"]:_stage_button("ammo:"+ammo,"轻3筹" if ammo=="light" else "重5筹",flow,{"type":"ammo","value":ammo})
		for weight in [4,6,8]:_stage_button("weight:%d"%weight,"配重%d"%weight,flow,{"type":"weight","value":weight})
		for angle in [35,45]:_stage_button("angle:%d"%angle,"%d°"%angle,flow,{"type":"angle","value":angle})
		_stage_button("trial","模拟试射",flow,{"type":"trial"})
	else:
		for who in NAMES:
			var value:String=who
			_button("op:select:"+who,NAMES[who],flow,{},func():_selected=value;_refresh())
		_stage_button("beat","推进一拍",flow,{"type":"beat"})
		_stage_button("sink","共同沉船",flow,{"type":"sink"})
		for ratio in ["1:9","3:7","5:5"]:_stage_button("ratio:"+ratio,"石木"+ratio,flow,{"type":"ratio","value":ratio})
		_stage_button("gate","梁开闸",flow,{"type":"open_gate"})
func _stage_button(key:String,title:String,parent:Node,action:Dictionary) -> void:
	var stage:int=int(_view.state.get("problem",_view.state.get("phase",0)))
	_button("op:"+key,title,parent,{},func():
		if stage!=int(_view.state.get("problem",_view.state.get("phase",0))):return
		_send(action))
func _send(action:Dictionary) -> void:
	if not is_visible_in_tree() or get_tree().paused:return
	stop_demonstration()
	input_submitted.emit(action)
	if action.get("type","") in ["assign","boat"] and _has_orders():
		_auto_move=true;_timer.start();_refresh()
func _has_orders() -> bool:
	return not _view.state.get("orders",{}).is_empty() or not _view.state.get("boat_orders",{}).is_empty()
func _choose_cell(x:int,y:int) -> void:
	if _view.puzzle_id!="dam_ch08_submerged":return
	for actor in _view.state.actors:
		if _view.state.actors[actor]==[x,y]:_selected=actor;_refresh();return
	for boat in _view.state.boats:
		var pos:Array=_view.state.boats[boat]
		if pos==[x,y] or (boat=="wide" and [pos[0]+1,pos[1]]==[x,y]):_selected=boat;_refresh();return
	_send({"type":"assign","actor":_selected,"x":x,"y":y} if _selected.begins_with("char_") or _selected.begins_with("npc_") else {"type":"boat","boat":_selected,"x":x,"y":y})
func _choose_pool(pool:int) -> void:
	if _source_pool<0:_source_pool=pool;_refresh();return
	var source:int=_source_pool;_source_pool=-1;_send({"type":"transfer","from":source,"to":pool})
func _toggle_demo() -> void:
	if _demo_running:stop_demonstration();return
	if _view.state.hint<3 or _view.state.complete:return
	_demo_running=true;_auto_move=false;_demo_steps=0;_demo_stage=int(_view.state.get("problem",_view.state.get("phase",0)));_timer.start();_refresh()
func _tick() -> void:
	if not is_visible_in_tree() or get_tree().paused:stop_demonstration();return
	if _demo_running:
		if _view.state.complete or _demo_stage!=int(_view.state.get("problem",_view.state.get("phase",0))) or _demo_steps>=120 or _view.next_action.get("type","")=="retry":stop_demonstration();return
		var before:String=JSON.stringify(_view.state);var failures:int=_view.state.failures;_demo_steps+=1
		input_submitted.emit({"type":"assist_step_v1"})
		if JSON.stringify(_view.state)==before or _view.state.failures>failures:stop_demonstration()
	elif _auto_move:
		if not _has_orders():stop_demonstration();return
		var before:String=JSON.stringify(_view.state)
		input_submitted.emit({"type":"beat"})
		if JSON.stringify(_view.state)==before or not _has_orders():stop_demonstration()
func _refresh() -> void:
	if not is_instance_valid(_board):return
	_board.render(_view,_selected)
	_labels.rules.text=_view.instruction
	_labels.message.text=_view.message
	_labels.message.max_lines_visible=2
	_labels.hint.text=_view.hint_text
	var s:Dictionary=_view.state
	_labels.status.text="已验%d/3；当前%s"%[s.passed.size(),["七曜珠联","治水图","最长梯腿"][mini(s.problem,2)]] if _view.puzzle_id=="numbers_ch08_ranya" else ("选中："+NAMES[_selected]+"；点图上目标。黄框为工位。" if _view.puzzle_id=="dam_ch08_submerged" else "已验%d/2；只模拟，敌弩未毁。"%s.plans.size())
	if s.history_reset:_labels.status.text+=" 前史未验证，不计全手工。"
	elif s.assisted:_labels.status.text+=" 已使用协助。"
	if _source_pool>=0:_labels.status.text+=" 水源："+["A","B","C"][_source_pool]+"，再点相邻目标。"
	_buttons.demo.text="停止演示" if _demo_running else "演示本题"
	_buttons.demo.disabled=s.complete or (s.hint<3 and not _demo_running)
	_buttons.assist.disabled=s.complete or s.hint<3
	_buttons.finish.visible=_view.puzzle_id!="dam_ch08_submerged"
	_buttons.stop.disabled=not _demo_running and not _auto_move
	_buttons.retry.disabled=s.complete
	_buttons.finish.disabled=s.complete
func _resize_board() -> void:
	if not is_instance_valid(_board):return
	var width:float=clampf(size.x*0.42,198,440)
	_board.custom_minimum_size=Vector2(width,198)
