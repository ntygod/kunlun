extends RefCounted
## Persistent world controls; model owns every action and progression rule.
const DIRS:={KEY_LEFT:Vector2i.LEFT,KEY_A:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_D:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_W:Vector2i.UP,KEY_DOWN:Vector2i.DOWN,KEY_S:Vector2i.DOWN}
var _token:=""
var _version:=0
var _focused:=true
var _view:Dictionary={}
var _selected:=""
var _signature:=""
var _picker:OptionButton
var _execute:Button
var _buttons:Array[Button]=[]
var _armed:Dictionary={}
func reset()->void:
 _token="";_view={};_selected="";_signature="";_version+=1;_armed.clear()
func cancel_input()->void:
 _armed.clear()
func set_focused(value:bool)->void:
 _focused=value;_armed.clear()
func tick(_main:Node,_delta:float)->void:pass
func _valid_scene(main:Node)->bool:
 return is_instance_valid(main) and main.is_inside_tree() and main.is_visible_in_tree() and main.story.active_chapter==15 and main.mode=="world_puzzle" and main.dialogue_panel.is_visible_in_tree() and main.story.current_token()==_token and not main.get_tree().paused
func _valid(main:Node)->bool:
 return _valid_scene(main) and _focused and (DisplayServer.get_name()=="headless" or (main.get_window()!=null and main.get_window().has_focus()))
func _identity(option:Dictionary)->String:
 if option.has("id"):return str(option.id)
 return JSON.stringify(option.action)
func _selected_action()->Dictionary:
 for option in _view.get("options",[]):
  if _identity(option)==_selected:return option.action.duplicate(true)
 return {}
func _offered(kind:String)->Dictionary:
 for option in _view.get("options",[]):
  if option.action.get("type","")==kind:return option.action.duplicate(true)
 return {}
func _dispatch(main:Node,action:Dictionary)->void:
 if _valid(main) and not action.is_empty():main._world_puzzle_input(action)
func _compact(button:Button)->void:
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style:StyleBox=button.get_theme_stylebox(state).duplicate()
  style.content_margin_left=6;style.content_margin_right=6
  button.add_theme_stylebox_override(state,style)
func _button(main:Node,label:String,action:Dictionary,kind:String="move")->Button:
 var b:Button=main._button(label,func():pass,main.actions)
 b.custom_minimum_size=Vector2(34 if kind=="move" else 52,34);_compact(b)
 var id:int=b.get_instance_id()
 b.button_down.connect(func():
  if _valid(main) and b.get_parent()==main.actions:_armed[id]={"version":_version,"action":_selected_action() if kind=="execute" else action.duplicate(true)})
 b.pressed.connect(func():
  var armed:Dictionary=_armed.get(id,{});_armed.erase(id)
  if armed.get("version",-1)!=_version or not _valid(main) or b.get_parent()!=main.actions:return
  if kind=="pause":main._show_menu()
  else:_dispatch(main,armed.action))
 _buttons.append(b);return b
func _build(main:Node)->void:
 main._clear(main.actions);_buttons.clear();_armed.clear()
 for pair in [["←",Vector2i.LEFT],["↑",Vector2i.UP],["↓",Vector2i.DOWN],["→",Vector2i.RIGHT]]:
  var d:Vector2i=pair[1]
  _button(main,pair[0],{"type":"move","dx":d.x,"dy":d.y}).tooltip_text="移动一步"
 _picker=OptionButton.new();_picker.custom_minimum_size=Vector2(130,34);_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _picker.fit_to_longest_item=false;_picker.clip_text=true;_picker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 _picker.item_selected.connect(func(index:int):
  if not _valid_scene(main):return
  var options:Array=_view.get("options",[])
  if index>=0 and index<options.size():_selected=_identity(options[index]);_picker.tooltip_text=str(options[index].label))
 main.actions.add_child(_picker)
 _execute=_button(main,"执行",{},"execute")
 _button(main,"暂歇",{},"pause")
func render(main:Node,view:Dictionary)->bool:
 if main.story.active_chapter!=15:return false
 var token:String=main.story.current_token()
 var spatial:Dictionary=view.get("world_state",{})
 var actor:String=str(spatial.get("control_actor_id",view.get("state",{}).get("control_actor_id","char_liang_xiao")))
 var options:Array=view.get("options",[])
 # A press begun in an earlier phase must not silently become the next action.
 var signature:String=JSON.stringify([token,actor,spatial.get("stage",view.get("state",{}).get("stage",0)),options])
 if token!=_token:reset();_token=token
 if signature!=_signature:_version+=1;_armed.clear();_signature=signature
 _view=view.duplicate(true)
 var who:String={"char_liang_xiao":"梁萧","char_hua_xiaoshuang":"花晓霜","char_huasheng":"花生","char_liu_yingying":"柳莺莺"}.get(actor,"当前角色")
 main.speaker.show();main.speaker.autowrap_mode=TextServer.AUTOWRAP_OFF;main.speaker.text=who
 var heading:String=who+" · "+str(view.get("title",""))
 if spatial.get("target_position") is Array and spatial.get("player_position") is Array:
  var target:Array=spatial.target_position;var player:Array=spatial.player_position
  var dx:float=float(target[0])-float(player[0]);var dy:float=float(target[1])-float(player[1])
  var direction:=("左" if dx < -8 else ("右" if dx > 8 else ""))+("上" if dy < -8 else ("下" if dy > 8 else ""))
  heading+=" · "+("已近目标" if direction.is_empty() else "目标在"+direction+"方")
 if not is_instance_valid(_picker) or _picker.get_parent()!=main.actions:_build(main)
 # Preserve Control instances and native mouse/focus state across normal updates.
 var labels:Array=[]
 for option in options:labels.append(str(option.label))
 var old_labels:Array=[]
 for i in range(_picker.item_count):old_labels.append(_picker.get_item_text(i))
 if labels!=old_labels:
  _picker.get_popup().hide();_picker.clear()
  for label in labels:_picker.add_item(label)
 var selected:=0
 for i in range(options.size()):
  if _identity(options[i])==_selected:selected=i
 if not options.is_empty():
  _picker.select(selected);_selected=_identity(options[selected]);_picker.tooltip_text=str(options[selected].label)
 else:_selected="";_picker.tooltip_text="当前无可执行动作"
 _picker.disabled=options.is_empty();_execute.disabled=options.is_empty()
 for i in range(mini(4,_buttons.size())):_buttons[i].disabled=bool(view.get("movement_locked",false))
 var feedback:String=str(options[selected].label)+"\n" if not options.is_empty() else ""
 main.dialogue_text.text=heading+"\n"+feedback+str(view.get("body",""))+"\n"+("锁链拘身，仅可原地环顾与回应 · E／Enter 继续 · Esc 暂歇" if view.get("movement_locked",false) else "方向键／WASD 单步行走 · E 照应 · Enter 执行所选 · Esc 暂歇")
 return true
func handle_input(main:Node,event:InputEvent)->bool:
 if not event is InputEventKey:return false
 var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:key=event.keycode
 if key in [KEY_F5,KEY_F9,KEY_ESCAPE]:_armed.clear();return false
 var known:bool=DIRS.has(key) or key in [KEY_E,KEY_ENTER,KEY_SPACE,KEY_R]
 # Paused world controls own gameplay keys, preventing hidden GUI navigation.
 if not _valid(main):return known and main.story.active_chapter==15 and main.mode=="world_puzzle"
 if is_instance_valid(_picker) and _picker.get_popup().visible:return false
 if not event.pressed or event.echo:return known
 _armed.clear()
 if DIRS.has(key):
  if not _view.get("movement_locked",false):_dispatch(main,{"type":"move","dx":DIRS[key].x,"dy":DIRS[key].y})
  return true
 if key==KEY_E:_dispatch(main,_offered("interact"))
 elif key==KEY_ENTER:_dispatch(main,_selected_action())
 elif key==KEY_SPACE:_dispatch(main,_offered("wait"))
 elif key==KEY_R:_dispatch(main,_offered("retry"))
 else:return false
 return true
