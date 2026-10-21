extends VBoxContainer
signal input_submitted(action:Dictionary)
signal close_requested
signal input_requested(action:Dictionary)
signal cancel_requested
const Board=preload("res://scripts/ui/chapter_eleven_puzzle_board.gd")
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
func _meridian()->bool:return _view.get("puzzle_id","")=="pz_ch11_meridian_channels"
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
	var b:=Button.new();b.text=title;b.set_meta("puzzle_focus","ch11:"+key);b.set_meta("action_id",key);parent.add_child(b);_buttons[key]=b
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
	_scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_scroll)
	_side=VBoxContainer.new();_side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_side)
	_label("status",_side)
	_build_actions()
	_label("hint",_side)
	var footer:=_flow(self)
	_button("hint","提示",footer,{"type":"hint"});_button("assist","协助一步",footer,{"type":"assist_step_v1"})
	_button("demo","演示本题",footer,{},_toggle_demo);_button("stop","停止",footer,{},stop_demonstration)
	_button("retry","重试",footer,{"type":"retry"});_button("close","暂歇",footer,{},func():stop_demonstration();close_requested.emit();cancel_requested.emit())
	_label("message",self).max_lines_visible=2
	_timer=Timer.new();_timer.wait_time=0.4;add_child(_timer);_timer.timeout.connect(func():
		if born==_epoch:_tick())
func _build_actions()->void:
	for item in _view.actions:_button(str(item.command),item.label,_side,item.command)
	if _meridian():
		for i in range(3):
			_label("joint%d"%i,_side).text="经节%d · 方向/阴阳"%(i+1)
			var row:=_flow(_side)
			for n in range(3):_button("rotate:%d:%d"%[i,n],["直行","斜/","斜反"][n],row,{"type":"rotate","index":i,"value":n})
			row=_flow(_side)
			for n in range(2):_button("polarity:%d:%d"%[i,n],["阴","阳"][n],row,{"type":"polarity","index":i,"value":n})
		_button("flow","试运经流",_side,{"type":"flow"})
	if _view.puzzle_id=="pz_ch11_r04_medicine":
		var row:=_flow(_side)
		for n in range(4):_button("heat:%d"%n,"火%d"%n,row,{"type":"heat","value":n})
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
	_labels.rules.text=_view.instruction
	_labels.message.text=_view.get("message","");_labels.hint.text=_view.get("hint_text","")
	_labels.status.text="观察%d/3 · 步骤%d · %s\n%s"%[s.observed.size(),s.stage,"完成" if s.complete else "待操作",str(_view.get("assistance_status","unknown"))]
	for key in _buttons:
		if key not in ["close","stop","demo","assist","retry","hint"]:_buttons[key].disabled=s.complete
	_buttons.demo.text="停止演示" if _demo_running else "演示本题";_buttons.demo.disabled=s.complete or (s.hint<3 and not _demo_running)
	_buttons.assist.disabled=s.complete or s.hint<3;_buttons.retry.disabled=s.complete;_buttons.hint.disabled=s.complete;_buttons.stop.disabled=not _demo_running
func _resize_board()->void:
	if is_instance_valid(_board):_board.custom_minimum_size=Vector2(clampf(size.x*0.42,198,420),145)
