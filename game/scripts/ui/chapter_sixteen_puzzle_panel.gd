extends VBoxContainer
## Persistent controls: changing a gate never destroys a focused SpinBox.
signal input_submitted(action:Dictionary)
signal close_requested
const Board=preload("res://scripts/ui/chapter_sixteen_puzzle_board.gd")
var _view:Dictionary={}
var _identity=""
var _epoch=0
var _numbers:Dictionary={}
var _buttons:Dictionary={}
var _status:Label
var _hint:Label
var _heading:Label
var _board:Control
var _syncing=false
var _committing_numbers=false
func render(view:Dictionary)->void:
 var identity:String=str(view.get("puzzle_id",""))+":"+str(view.get("attempt_id",""))
 _view=view.duplicate(true)
 if identity!=_identity:
  _identity=identity;_epoch+=1;_numbers.clear();_buttons.clear()
  for child in get_children():remove_child(child);child.queue_free()
  _build()
 _refresh()
func _label(parent:Node,text:String="")->Label:
 var l:=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func _button(parent:Node,id:String,text:String,action:Dictionary)->Button:
 var b:=Button.new();b.name=id;b.text=text;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size.y=26
 if parent is HBoxContainer or parent is HFlowContainer:
  b.autowrap_mode=TextServer.AUTOWRAP_OFF;b.custom_minimum_size.x=96
  if parent is HBoxContainer:b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.set_meta("action_id",id);parent.add_child(b);_buttons[id]=b
 var born:int=_epoch
 b.pressed.connect(func():
  if born==_epoch and b.is_inside_tree() and is_visible_in_tree() and not b.disabled:
   if action.type not in ["reset","hint"]:_commit_numbers()
   _send(action))
 return b
func _send(action:Dictionary)->void:
 if not is_inside_tree() or not is_visible_in_tree() or get_tree().paused or _view.state.complete:return
 var value:Dictionary=action.duplicate(true);value.revision=int(_view.revision)
 input_submitted.emit(value)
func _commit_numbers()->void:
 if _committing_numbers:return
 _committing_numbers=true
 var edits:Dictionary={}
 for id in _numbers:
  var n:SpinBox=_numbers[id]
  if n.editable:edits[id]=n.get_line_edit().text
 for id in edits:
  var n:SpinBox=_numbers[id]
  n.get_line_edit().text=edits[id];n.apply()
 _committing_numbers=false
func _number(parent:Node,id:String,text:String,command:String,channel:int=-1)->void:
 var row:=HBoxContainer.new();parent.add_child(row)
 var l:=_label(row,text);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var n:=SpinBox.new();n.name=id;n.min_value=0;n.max_value=4;n.step=1;n.allow_greater=false;n.allow_lesser=false;n.custom_minimum_size.x=82;row.add_child(n);_numbers[id]=n
 var born:int=_epoch
 n.value_changed.connect(func(value:float):
  if _syncing or born!=_epoch:return
  var action:Dictionary={"type":command,"value":int(value)}
  if channel>=0:action.channel=channel
  _send(action))
 # Explicitly apply edited native text before the user moves to Test/Record.
 n.get_line_edit().text_submitted.connect(func(_text:String):
  if born==_epoch:n.apply())
func _build()->void:
 add_theme_constant_override("separation",4)
 _heading=_label(self)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(row)
 _board=Board.new();_board.custom_minimum_size=Vector2(200,130);_board.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(_board)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(scroll)
 var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",4);scroll.add_child(column)
 _status=_label(column)
 match _view.puzzle_id:
  "pz_ch16_river":
   _button(column,"survey","勘查支渠与旧河道",{"type":"survey"})
   for i in range(3):_number(column,"gate_"+str(i),["北渠 · 上限4","中渠 · 上限4","南渠 · 淤塞仅1"][i],"gate",i)
   _button(column,"dig","接通中渠旁的旧河道",{"type":"dig","site":"old_channel"})
   _button(column,"test","引入洪峰，验看分流",{"type":"test"})
  "pz_ch16_scale":
   var objects:=HFlowContainer.new();column.add_child(objects)
   for key in ["crown","manuscript","sword"]:_button(objects,key,{"crown":"王冠","manuscript":"手稿","sword":"长剑"}[key],{"type":"place","object":key})
   _button(column,"clear","取下盘上器物",{"type":"clear"})
   _button(column,"talk","与兰娅谈先父的用意",{"type":"talk"})
   _button(column,"left","梁萧踏上左盘",{"type":"stand","actor":"char_liang_xiao","side":"left"})
   _button(column,"right","请兰娅踏上右盘",{"type":"stand","actor":"npc_ranya","side":"right"})
  "pz_ch16_study":
   _button(column,"read","翻阅本季书卷",{"type":"read"})
   _number(column,"instrument","铜仪刻度","align")
   _button(column,"record","记录测角，转入下一季",{"type":"record"})
 _hint=_label(self)
 var footer:=HBoxContainer.new();add_child(footer)
 _button(footer,"hint","下一层提示",{"type":"hint"})
 _button(footer,"reset","重置本机关",{"type":"reset"})
 var leave:=Button.new();leave.text="暂歇 / 保存";footer.add_child(leave)
 var born:int=_epoch
 leave.pressed.connect(func():
  if born==_epoch and is_inside_tree() and is_visible_in_tree():close_requested.emit())
func _refresh()->void:
 _syncing=true
 var s:Dictionary=_view.state
 _heading.text=str(_view.title)+" · F5 保存 / F9 读档"
 _status.text=s.message
 _hint.text="提示 %d/3 · %s"%[s.hint_level,_view.hint]
 for b in _buttons.values():b.disabled=s.complete
 _buttons.hint.disabled=s.complete or int(s.hint_level)>=3
 match _view.puzzle_id:
  "pz_ch16_river":
   _buttons.survey.disabled=s.surveyed
   for i in range(3):
    _numbers["gate_"+str(i)].set_value_no_signal(s.gates[i]);_numbers["gate_"+str(i)].editable=s.surveyed and not s.complete
   _buttons.dig.disabled=not s.surveyed or s.overflow or s.complete;_buttons.test.disabled=not s.surveyed or s.complete
  "pz_ch16_scale":
   for key in ["crown","manuscript","sword"]:_buttons[key].disabled=s.complete or key in s.objects or s.left!="" or s.right!=""
   _buttons.clear.disabled=s.complete or s.objects.is_empty();_buttons.talk.disabled=s.complete or s.understood
   _buttons.left.disabled=s.complete or not s.understood or not s.objects.is_empty() or s.left!=""
   _buttons.right.disabled=s.complete or not s.understood or not s.objects.is_empty() or s.right!=""
  "pz_ch16_study":
   _numbers.instrument.set_value_no_signal(s.instrument);_numbers.instrument.editable=s.page_read and not s.complete
   _buttons.read.disabled=s.page_read or s.complete;_buttons.record.disabled=not s.page_read or s.complete
   _heading.text="三年书窗 · 第%d年 %s · 窗边刻线%d"%[mini(3,int(s.season_index)/4+1),["春","夏","秋","冬"][int(s.season_index)%4],[2,3,2,1][int(s.season_index)%4]]
 _board.render(_view)
 _syncing=false
