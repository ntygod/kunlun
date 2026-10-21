extends VBoxContainer
signal input_submitted(action:Dictionary)
signal close_requested
signal input_requested(action:Dictionary)
signal cancel_requested
const Board=preload("res://scripts/ui/chapter_ten_puzzle_board.gd")
var _view:Dictionary={}
var _identity:=""
var _epoch:=0
var _selected:=0
var _buttons:Dictionary={}
var _labels:Dictionary={}
var _board:Control
var _scroll:ScrollContainer
var _side:VBoxContainer
var _timer:Timer
var _demo_running:=false
var _demo_steps:=0
func _ready()->void:
	visibility_changed.connect(func():
		if not is_visible_in_tree():stop_demonstration())
	resized.connect(_resize_board)
func _notification(what:int)->void:
	if what in [NOTIFICATION_PAUSED,NOTIFICATION_EXIT_TREE,NOTIFICATION_APPLICATION_FOCUS_OUT]:stop_demonstration()
func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_F5,KEY_F9]:stop_demonstration()
func set_session(session:Variant)->void:
	stop_demonstration()
	if session is Dictionary:render(session)
	elif session!=null and session.has_method("get_view"):render(session.get_view())
func _ox()->bool:return _view.get("puzzle_id","")=="pz_ch10_wooden_ox"
func render(view:Dictionary)->void:
	if view.is_empty():return
	var identity:String=str(view.get("puzzle_id",""))+":"+str(view.get("attempt_id",""))+":"+str(view.get("token",""))
	_view=view.duplicate(true)
	if identity!=_identity:
		stop_demonstration();_identity=identity;_epoch+=1;_selected=0
		for child in get_children():remove_child(child);child.queue_free()
		_buttons.clear();_labels.clear();_build()
	if _view.state.complete:stop_demonstration()
	_refresh();_resize_board.call_deferred()
func _label(key:String,parent:Node)->Label:
	var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);_labels[key]=label;return label
func _flow(parent:Node)->HFlowContainer:
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",3);flow.add_theme_constant_override("v_separation",3);parent.add_child(flow);return flow
func _button(key:String,title:String,parent:Node,action:Dictionary={},callback:Callable=Callable())->Button:
	var b:=Button.new();b.text=title;b.set_meta("puzzle_focus","ch10:"+key);b.set_meta("action_id",key);parent.add_child(b);_buttons[key]=b
	var born:int=_epoch
	b.pressed.connect(func():
		if born!=_epoch or not is_visible_in_tree() or get_tree().paused:return
		if callback.is_valid():callback.call()
		else:_send(action))
	return b
func _build()->void:
	add_theme_constant_override("separation",3)
	var font:Font=get_theme_default_font();theme=Theme.new();theme.default_font=font;theme.default_font_size=13
	for name in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("405b60") if name in ["hover","focus"] else Color("25383d")
		style.content_margin_left=5;style.content_margin_right=5;style.content_margin_top=2;style.content_margin_bottom=2;theme.set_stylebox(name,"Button",style)
	_label("title",self);_label("rules",self)
	var row:=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(row)
	_board=Board.new();_board.custom_minimum_size=Vector2(205,145);_board.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_board)
	var born:int=_epoch
	_board.cell_chosen.connect(func(x:int,y:int):
		if born!=_epoch or not is_visible_in_tree() or get_tree().paused or _ox():return
		if x in [2,3,4]:_selected=x-2
		_send({"type":"stone","index":_selected,"row":y}))
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_scroll)
	_side=VBoxContainer.new();_side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_side)
	_label("status",_side)
	if _ox():_build_ox()
	else:_build_stones()
	_label("hint",_side)
	var footer:=_flow(self)
	_button("hint","提示",footer,{"type":"hint"});_button("assist","协助一步",footer,{"type":"assist_step_v1"})
	_button("demo","演示本题",footer,{},_toggle_demo);_button("stop","停止",footer,{},stop_demonstration)
	_button("retry","重试",footer,{"type":"retry"});_button("close","暂歇",footer,{},func():stop_demonstration();close_requested.emit();cancel_requested.emit())
	_label("message",self).max_lines_visible=2
	_timer=Timer.new();_timer.wait_time=0.4;add_child(_timer);_timer.timeout.connect(func():
		if born==_epoch:_tick())
func _build_ox()->void:
	_label("axle",_side).text="轴长（承孔宽3格）"
	var row:=_flow(_side)
	for n in [2,3,4]:_button("axle:%d"%n,str(n)+"格",row,{"type":"axle","length":n})
	for side in ["left","right"]:
		_label(side,_side).text=("左" if side=="left" else "右")+"曲柄相位"
		row=_flow(_side)
		for n in range(4):_button("phase:%s:%d"%[side,n],str(n),row,{"type":"phase","side":side,"value":n})
	for bundle in ["light","heavy"]:
		_label(bundle,_side).text="轻包2筹" if bundle=="light" else "重包3筹"
		row=_flow(_side)
		for n in [-3,-2,-1,1,2,3]:_button("cargo:%s:%d"%[bundle,n],str(n),row,{"type":"cargo","bundle":bundle,"position":n})
	_button("step","负载试走一步",_side,{"type":"step"})
func _build_stones()->void:
	var row:=_flow(_side)
	for i in range(3):
		var index:int=i
		_button("select:%d"%i,["选甲石","选乙石","选丙石"][i],row,{},func():_selected=index;_refresh())
	_label("placement",_side).text="沿竖槽移石，也可直接点棋盘"
	row=_flow(_side)
	for y in range(5):
		var target:int=y
		_button("row:%d"%y,"第%d行"%y,row,{},func():_send({"type":"stone","index":_selected,"row":target}))
	row=_flow(_side)
	for orientation in ["/","\\"]:
		var value:String=orientation
		_button("turn:"+orientation,orientation+" 引势",row,{},func():_send({"type":"turn","index":_selected,"orientation":value}))
	_button("pulse","引下一股来势",_side,{"type":"pulse"});_button("breathe","调息一回合",_side,{"type":"breathe"})
func _emit(action:Dictionary)->void:input_submitted.emit(action);input_requested.emit(action)
func _send(action:Dictionary)->void:
	if not is_visible_in_tree() or get_tree().paused:return
	stop_demonstration();_emit(action)
func stop_demonstration()->void:
	_demo_running=false
	if is_instance_valid(_timer):_timer.stop()
	if _buttons.has("demo"):_buttons.demo.text="演示本题"
	if _buttons.has("stop"):_buttons.stop.disabled=true
func _toggle_demo()->void:
	if _demo_running:stop_demonstration();return
	if _view.state.complete or _view.state.hint<3:return
	_demo_running=true;_demo_steps=0;_timer.start();_refresh()
func _tick()->void:
	if not _demo_running:return
	if not is_visible_in_tree() or get_tree().paused or _view.state.complete or _demo_steps>=64 or _view.get("next_action",{}).get("type")=="retry":stop_demonstration();return
	var before:Dictionary=_view.state.duplicate(true);_demo_steps+=1;_emit({"type":"assist_step_v1"})
	if _view.state==before:stop_demonstration()
func _refresh()->void:
	if not is_instance_valid(_board):return
	var s:Dictionary=_view.state;_board.render(_view,_selected);_labels.title.text=_view.title
	_labels.rules.text="轴3格；曲柄相差2。力矩=2×轻包位置+3×重包位置=0；合法配置后负载走3步。" if _ox() else "三石引开第1、2、3行来势，右岸不可受击；每股导出上下边界后，单独调息一次。"
	_labels.message.text=_view.get("message","");_labels.hint.text=_view.get("hint_text","")
	if _ox():
		_labels.status.text="轴%d格 · 曲柄%d/%d\n力矩%d · 试走%d/3%s"%[s.axle,s.left_phase,s.right_phase,_view.calculation.torque,s.steps," · 卡住" if s.jammed else ""]
		for key in _buttons:
			if key.begins_with("axle:") or key.begins_with("phase:") or key.begins_with("cargo:"):_buttons[key].disabled=s.complete or s.steps>0
		_buttons.step.disabled=s.complete
	else:
		_labels.status.text="选中%s · 调息%d/3\n参与阵石%d/3 · %s"%[["甲石","乙石","丙石"][_selected],s.breaths,s.used.size(),"空隙已开，调息" if s.awaiting_breath else "观察路径后引势"]
		for key in _buttons:
			if key.begins_with("row:") or key.begins_with("turn:"):_buttons[key].disabled=s.locked or s.complete
		_buttons.pulse.disabled=s.complete or s.awaiting_breath or s.wave>=3;_buttons.breathe.disabled=s.complete or not s.awaiting_breath
	_labels.status.text+="\n"+str(_view.get("assistance_status","unknown"))
	_buttons.demo.text="停止演示" if _demo_running else "演示本题";_buttons.demo.disabled=s.complete or (s.hint<3 and not _demo_running)
	_buttons.assist.disabled=s.complete or s.hint<3;_buttons.retry.disabled=s.complete;_buttons.hint.disabled=s.complete;_buttons.stop.disabled=not _demo_running
func _resize_board()->void:
	if is_instance_valid(_board):_board.custom_minimum_size=Vector2(clampf(size.x*0.42,198,420),145)
