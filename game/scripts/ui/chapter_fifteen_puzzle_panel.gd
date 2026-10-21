extends VBoxContainer
signal input_submitted(action:Dictionary)
signal close_requested
signal input_requested(action:Dictionary)
signal cancel_requested
const Board=preload("res://scripts/ui/chapter_fifteen_puzzle_board.gd")
var _view:Dictionary={}
var _identity:=""
var _epoch:=0
var _selected:=0
var _buttons:Dictionary={}
var _labels:Dictionary={}
var _board:Control
var _scroll:ScrollContainer
var _side:VBoxContainer
var _numbers:Dictionary={}
var _sliders:Dictionary={}
var _choices:Dictionary={}
var _timer:Timer
var _demo_running:=false
var _demo_steps:=0
func _ready()->void:
 get_window().focus_exited.connect(stop_demonstration)
 visibility_changed.connect(func():
  if not is_visible_in_tree():stop_demonstration())
 resized.connect(_resize_board)
func _notification(what:int)->void:
 if what in [NOTIFICATION_PAUSED,NOTIFICATION_EXIT_TREE,NOTIFICATION_APPLICATION_FOCUS_OUT]:stop_demonstration()
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and (event.keycode in [KEY_ESCAPE,KEY_F5,KEY_F9] or event.physical_keycode in [KEY_ESCAPE,KEY_F5,KEY_F9]):stop_demonstration()
func set_session(session:Variant)->void:
 stop_demonstration()
 if session is Dictionary:render(session)
 elif session!=null and session.has_method("get_view"):render(session.get_view())
func render(view:Dictionary)->void:
 if view.is_empty():return
 var identity:String=str(view.get("puzzle_id",""))+":"+str(view.get("attempt_id",""))+":"+str(view.get("token",""))
 _view=view.duplicate(true)
 if identity!=_identity:
  stop_demonstration();_identity=identity;_epoch+=1;_selected=-1
  for child in get_children():remove_child(child);child.queue_free()
  _buttons.clear();_labels.clear();_numbers.clear();_choices.clear();_sliders.clear();_build()
 if _view.state.complete:stop_demonstration()
 _refresh();_resize_board.call_deferred()
func _label(key:String,parent:Node)->Label:
 var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);_labels[key]=label;return label
func _flow(parent:Node)->HFlowContainer:
 var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",3);flow.add_theme_constant_override("v_separation",3);parent.add_child(flow);return flow
func _button(key:String,title:String,parent:Node,action:Dictionary={},callback:Callable=Callable())->Button:
 var b:=Button.new();b.text=title;b.set_meta("puzzle_focus","ch15:"+key);b.set_meta("action_id",key);parent.add_child(b);_buttons[key]=b
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
 _board.slot_chosen.connect(func(slot:int):
  if born==_epoch and is_visible_in_tree() and not get_tree().paused:_choose_slot(slot))
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
func _choice(key:String,title:String,names:Array,ids:Array,parent:Node)->OptionButton:
 _label(key+"_label",parent).text=title
 var c:=OptionButton.new();c.fit_to_longest_item=false;c.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for i in range(names.size()):c.add_item(names[i]);c.set_item_metadata(i,ids[i])
 parent.add_child(c);_choices[key]=c;return c
func _chosen(key:String)->Variant:return _choices[key].get_item_metadata(_choices[key].selected)
func _build_actions()->void:
 for item in _view.actions:_button(str(item.command),item.label,_side,item.command)
 if _view.method=="a":
  _choice("card","选一页图录",["第1页","第2页","第3页","第4页","第5页","第6页","第7页","第8页","第9页"],[0,1,2,3,4,5,6,7,8],_side)
  _choice("family","放入图例栏",["甲 · 圆","乙 · 三角","丙 · 方"],[0,1,2],_side)
  _button("file","放入这一栏",_side,{},func():_send({"type":"file_card","card":_chosen("card"),"family":_chosen("family")}))
  _button("check","核对九页图录",_side,{"type":"check_atlas"})
 else:
  _choice("jar","选一坛虚构储备",["第一坛","第二坛","第三坛"],[0,1,2],_side)
  _choice("seal","坛口与标记",["敞口摆放","盖好但未标明","盖紧并标明"],["open","closed_unmarked","closed_marked"],_side)
  _button("store","安放这一坛",_side,{},func():_send({"type":"store_jar","jar":_chosen("jar"),"seal":_chosen("seal")}))
  _choice("tool","选一件教具",["图录","木人教具","针匣"],["record","model","needle_case"],_side)
  _choice("place","整理到何处",["书架","案上","封存匣"],["shelf","desk","closed_case"],_side)
  _button("tool","整理这件教具",_side,{},func():_send({"type":"put_tool","tool":_chosen("tool"),"place":_chosen("place")}))
  _button("check","核对储备清单",_side,{"type":"check_store"})
 _choice("rule","让阿福复述",["不懂也凭印象试用","先看求助者贵贱","遇疑求助，不凭猜测"],["guess","status","ask"],_side)
 _button("teach","确认叮嘱",_side,{},func():_send({"type":"teach","rule":_chosen("rule")}))
 _button("finish","交代备办，去修整草庐",_side,{"type":"finish"})
func _choose_slot(slot:int)->void:
 if _view.get("method")!="a" or slot<0 or slot>8:return
 _selected=slot;_choices.card.select(slot);_board.render(_view,_selected)
func _emit(action:Dictionary)->void:input_submitted.emit(action);input_requested.emit(action)
func _send(action:Dictionary)->void:
 if not is_visible_in_tree() or get_tree().paused or (DisplayServer.get_name()!="headless" and not get_window().has_focus()):return
 stop_demonstration();_emit(action)
func stop_demonstration()->void:
 _demo_running=false
 if is_instance_valid(_timer):_timer.stop()
 if _buttons.has("demo"):_buttons.demo.text="演示本题"
 if _buttons.has("stop"):_buttons.stop.disabled=true
func _toggle_demo()->void:
 if not is_visible_in_tree() or get_tree().paused or (DisplayServer.get_name()!="headless" and not get_window().has_focus()):return
 if _demo_running:stop_demonstration();return
 if _view.state.complete or _view.state.hint<3:return
 _demo_running=true;_demo_steps=0;_timer.start();_refresh()
func _tick()->void:
 if not _demo_running:return
 if DisplayServer.get_name()!="headless" and not get_window().has_focus():stop_demonstration();return
 if not is_visible_in_tree() or get_tree().paused or _view.state.complete or _demo_steps>=100 or _view.get("next_action",{}).get("type")=="retry":stop_demonstration();return
 var before:Dictionary=_view.state.duplicate(true);_demo_steps+=1;_emit({"type":"assist_step_v1"})
 if _view.state==before:stop_demonstration()
func _refresh()->void:
 if not is_instance_valid(_board):return
 var s:Dictionary=_view.state;_board.render(_view,_selected);_labels.title.text=_view.title
 _labels.rules.text=_view.instruction
 _labels.message.text=_view.get("message","");_labels.hint.text=_view.get("hint_text","")
 _labels.status.text="观察%d/%d · 步骤%d · %s\n%s"%[s.observed.size(),_view.observations.size(),s.stage,"完成" if s.complete else "待操作",{"manual":"手工尝试","assisted":"已使用协助","unknown":"旧历史未核实"}.get(_view.get("assistance_status","unknown"),"旧历史未核实")]
 for key in _buttons:
  if key not in ["close","stop","demo","assist","retry","hint"]:_buttons[key].disabled=s.complete
 for key in _choices:_choices[key].disabled=s.complete
 _buttons.demo.text="停止演示" if _demo_running else "演示本题";_buttons.demo.disabled=s.complete or (s.hint<3 and not _demo_running)
 _buttons.assist.disabled=s.complete or s.hint<3;_buttons.retry.disabled=s.complete;_buttons.hint.disabled=s.complete;_buttons.stop.disabled=not _demo_running
func _resize_board()->void:
 if is_instance_valid(_board):_board.custom_minimum_size=Vector2(clampf(size.x*0.42,198,420),145)
