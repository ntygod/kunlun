extends VBoxContainer
## Persistent scene-owned controls. Read-only view; every operation includes revision.
signal input_submitted(action:Dictionary)
signal close_requested
var _view:Dictionary={}
var _identity=""
var _epoch=0
var _buttons:Dictionary={}
var _heading:Label
var _status:Label
var _hint:Label
var _chain:Label
var _board:Control
func _label(parent:Node,text:String="")->Label:
 var l:=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func _button(parent:Node,key:String,text:String,action:Dictionary)->Button:
 var b:=Button.new();b.name=key;b.text=text;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size=Vector2(128,28);b.set_meta("puzzle_action",action.duplicate(true));parent.add_child(b);_buttons[key]=b
 var born:int=_epoch
 b.pressed.connect(func():
  if born==_epoch and b.is_inside_tree() and is_visible_in_tree() and not b.disabled:
   var value:Dictionary=action.duplicate(true);value.revision=int(_view.revision);input_submitted.emit(value))
 return b
func render(view:Dictionary)->void:
 _view=view.duplicate(true)
 var identity:String=str(view.puzzle_id)+":"+str(view.attempt_id)
 if identity!=_identity:
  _identity=identity;_epoch+=1;_buttons.clear()
  for child in get_children():remove_child(child);child.queue_free()
  _build()
 _refresh()
func _build()->void:
 add_theme_constant_override("separation",4)
 _heading=_label(self);_heading.name="PuzzleHeading"
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.custom_minimum_size.y=112;add_child(scroll)
 var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 _chain=_label(body);_chain.name="EvidenceChain"
 _board=preload("res://scripts/ui/chapter_seventeen_puzzle_board.gd").new();_board.custom_minimum_size.y=220;body.add_child(_board)
 if _view.puzzle_id=="pz_ch17_evidence":
  var grid:=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(grid)
  for key in _view.evidence:
   var b:=_button(grid,"clue_"+key,_view.labels[key],{"type":"toggle","clue":key});b.toggle_mode=true
  _button(body,"connect","将已选线索连接到推论",{"type":"connect","claim":"double"})
 else:
  var grid:=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(grid)
  for row in [["beam","柳莺莺 · 抬起木梁","char_liu_yingying"],["joint","梁萧 · 校正榫口","char_liang_xiao"],["wedge","风怜 · 打入木栓","char_feng_lian"],["wall","柳莺莺 · 夯实土墙","char_liu_yingying"],["brace","梁萧 · 安放支撑","char_liang_xiao"],["reeds","风怜 · 铺好苇草","char_feng_lian"]]:
   _button(grid,row[0],row[1],{"type":"place","actor":row[2],"part":row[0]})
 _status=_label(self);_status.name="PuzzleFeedback"
 _hint=_label(self);_hint.name="PuzzleHint"
 var footer:=HBoxContainer.new();add_child(footer)
 _button(footer,"hint","下一层提示",{"type":"hint"});_button(footer,"reset","重置机关",{"type":"reset"})
 var leave:=Button.new();leave.text="暂歇 / 保存";leave.custom_minimum_size=Vector2(104,28);footer.add_child(leave)
 var born:int=_epoch
 leave.pressed.connect(func():
  if born==_epoch and is_inside_tree() and is_visible_in_tree():close_requested.emit())
func _refresh()->void:
 var s:Dictionary=_view.state;var small:=get_viewport_rect().size.y<=440
 _board.visible=not small;_board.render(_view)
 _heading.text=_view.title+" · F5 保存 / F9 读档"
 for l in [_heading,_chain,_status,_hint]:l.add_theme_font_size_override("font_size",12 if small else 17)
 _status.text=s.message;_hint.text="提示 %d/3 · %s"%[s.hint_level,_view.hint]
 for b in _buttons.values():b.disabled=s.complete;b.add_theme_font_size_override("font_size",12 if small else 16)
 _buttons.hint.disabled=s.complete or s.hint_level>=3
 if _view.puzzle_id=="pz_ch17_evidence":
  var text:="已取得六处实证。当前推论："+("狼皮替身" if s.claim=="double" else "真凶阿莫")
  for link in s.links:
   var labels:PackedStringArray=[]
   for key in link.clues:labels.append(_view.labels[key])
   text+="\n"+" + ".join(labels)+" → "+("替身成立" if link.claim=="double" else "阿莫成立")
  _chain.text=text
  for key in _view.evidence:_buttons["clue_"+key].set_pressed_no_signal(key in s.selected)
  # The button is retained; replace only its command payload, not the focused Control.
  var b:Button=_buttons.connect
  for connection in b.pressed.get_connections():b.pressed.disconnect(connection.callable)
  var born:int=_epoch
  b.pressed.connect(func():
   if born==_epoch and b.is_inside_tree() and is_visible_in_tree() and not b.disabled:input_submitted.emit({"type":"connect","claim":_view.state.claim,"revision":int(_view.revision)}))
  b.disabled=s.complete or s.selected.is_empty()
 else:
  _chain.text=("九宫榫卯斜顶" if s.method=="r07_method_joinery" else "双层土墙与暖棚")+" · 分工 %d/%d"%[s.stage,_view.steps.size()]
  for part in ["beam","joint","wedge","wall","brace","reeds"]:
   _buttons[part].visible=part in (["beam","joint","wedge","reeds"] if s.method=="r07_method_joinery" else ["wall","brace","reeds"])
