extends RefCounted
## Chapter-eleven world controls. No progression or wall-clock objectives live here.
const PERIOD:=0.14
const DIRECTIONS:={KEY_LEFT:Vector2i.LEFT,KEY_A:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_D:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_W:Vector2i.UP,KEY_DOWN:Vector2i.DOWN,KEY_S:Vector2i.DOWN}
var _token:=""
var _epoch:=0
var _held:Dictionary={}
var _elapsed:=0.0
var _focused:=true
var _view:Dictionary={}
var _selected:=""
func reset()->void:
 _token="";_view={};_held.clear();_elapsed=0.0;_epoch+=1;_selected=""
func set_focused(value:bool)->void:
 _focused=value;_held.clear();_elapsed=0.0
func _valid(main:Node)->bool:
 return is_instance_valid(main) and main.is_inside_tree() and main.is_visible_in_tree() and main.story.active_chapter==11 and main.mode=="world_puzzle" and main.dialogue_panel.is_visible_in_tree() and main.story.current_token()==_token
func _identity(option:Dictionary)->String:
 if option.has("id"):return str(option.id)
 var names:Array=option.action.keys();names.sort();var pairs:Array=[]
 for name in names:pairs.append([name,option.action[name]])
 return JSON.stringify(pairs)
func _dispatch(main:Node,action:Dictionary,born:int)->void:
 if born==_epoch and _focused and _valid(main):main._world_puzzle_input(action)
func _picker_open(main:Node)->bool:
 for control in main.actions.get_children():
  if control is OptionButton and control.get_popup().visible:return true
 return false
func _offered(kind:String)->Dictionary:
 for option in _view.get("options",[]):
  if option.action.get("type","")==kind:return option.action
 return {}
func _selected_action()->Dictionary:
 for option in _view.get("options",[]):
  if _identity(option)==_selected:return option.action
 return {}
func _compact(button:Button)->void:
 for state in ["normal","hover","pressed","focus","disabled"]:
  var style:StyleBox=button.get_theme_stylebox(state).duplicate()
  style.content_margin_left=6;style.content_margin_right=6
  button.add_theme_stylebox_override(state,style)
func render(main:Node,view:Dictionary)->bool:
 if main.story.active_chapter!=11:return false
 if _token!=main.story.current_token():reset();_token=main.story.current_token()
 _view=view.duplicate(true);_epoch+=1;var born:=_epoch
 var spatial:Dictionary=view.get("world_state",{})
 var actor:String=str(spatial.get("control_actor_id",view.get("state",{}).get("control_actor_id","char_liang_xiao")))
 var who:String={"char_liang_xiao":"梁萧","char_hua_xiaoshuang":"花晓霜"}.get(actor,"当前角色")
 main.speaker.show();main.speaker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 main.speaker.text=who+" · "+str(view.get("title",""))
 main.dialogue_text.text=str(view.get("body",""))+"\n方向键／WASD 行走 · E 照应 · Enter 执行所选 · Esc 暂歇"
 if spatial.get("target_position") is Array and spatial.get("player_position") is Array:
  var target:Array=spatial.target_position;var player:Array=spatial.player_position
  var dx:float=float(target[0])-float(player[0]);var dy:float=float(target[1])-float(player[1])
  var direction:=("左" if dx < -8 else ("右" if dx > 8 else ""))+("上" if dy < -8 else ("下" if dy > 8 else ""))
  main.speaker.text+=" · "+("已近目标" if direction.is_empty() else "目标在"+direction+"方")
 main.dialogue_text.text=main.speaker.text+"\n"+main.dialogue_text.text
 main.speaker.autowrap_mode=TextServer.AUTOWRAP_OFF;main.speaker.text=who
 main._clear(main.actions)
 for pair in [["←",Vector2i.LEFT],["↑",Vector2i.UP],["↓",Vector2i.DOWN],["→",Vector2i.RIGHT]]:
  var dir:Vector2i=pair[1]
  var b:Button=main._button(pair[0],func():_dispatch(main,{"type":"move","dx":dir.x,"dy":dir.y},born),main.actions)
  b.custom_minimum_size=Vector2(34,34);b.tooltip_text="移动一步";_compact(b)
 var options:Array=view.get("options",[])
 if not options.is_empty():
  var picker:=OptionButton.new();picker.custom_minimum_size=Vector2(130,34);picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  picker.fit_to_longest_item=false;picker.clip_text=true;picker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var selected:=0
  for i in range(options.size()):
   picker.add_item(str(options[i].label))
   if _identity(options[i])==_selected:selected=i
  picker.select(selected);_selected=_identity(options[selected]);picker.tooltip_text=str(options[selected].label)
  main.dialogue_text.text=str(options[selected].label)+"\n"+main.dialogue_text.text
  picker.item_selected.connect(func(i:int):
   if born==_epoch and _valid(main):_selected=_identity(options[i]);picker.tooltip_text=str(options[i].label))
  main.actions.add_child(picker)
  var execute:Button=main._button("执行",func():
   var action:=_selected_action()
   if not action.is_empty():_dispatch(main,action,born),main.actions)
  execute.custom_minimum_size=Vector2(52,34);_compact(execute)
 var pause:Button=main._button("暂歇",func():
  if born==_epoch and _valid(main) and _focused:set_focused(true);main._show_menu(),main.actions)
 pause.custom_minimum_size=Vector2(52,34);_compact(pause)
 main.get_viewport().gui_release_focus()
 return true
func handle_input(main:Node,event:InputEvent)->bool:
 if not event is InputEventKey:return false
 var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:key=event.keycode
 if key in [KEY_ESCAPE,KEY_F5,KEY_F9]:_held.clear();_elapsed=0.0;return false
 if not _valid(main) or not _focused:return false
 if not event.pressed:
  _held.erase(key);_elapsed=0.0;return DIRECTIONS.has(key)
 if _picker_open(main):_held.clear();_elapsed=0.0;return false
 if event.echo:return DIRECTIONS.has(key) or key in [KEY_E,KEY_SPACE,KEY_ENTER,KEY_R]
 if DIRECTIONS.has(key):
  _held[key]=true;_elapsed=0.0
  _dispatch(main,{"type":"move","dx":DIRECTIONS[key].x,"dy":DIRECTIONS[key].y},_epoch);return true
 var action:Dictionary={}
 if key==KEY_ENTER:action=_selected_action()
 elif key==KEY_E:action=_offered("interact")
 elif key==KEY_SPACE:action=_offered("wait")
 elif key==KEY_R:action=_offered("retry")
 else:return false
 if not action.is_empty():_dispatch(main,action,_epoch)
 return true
func tick(main:Node,delta:float)->void:
 if not _focused or not _valid(main) or main.get_tree().paused or _picker_open(main):_held.clear();_elapsed=0.0;return
 var direction:=Vector2i.ZERO
 for key in _held:direction+=DIRECTIONS.get(key,Vector2i.ZERO)
 if direction==Vector2i.ZERO:_elapsed=0.0;return
 direction=Vector2i(signi(direction.x),0) if direction.x!=0 else Vector2i(0,signi(direction.y))
 _elapsed+=clampf(delta,0,0.07)
 if _elapsed+0.000001<PERIOD:return
 _elapsed=0.0
 _dispatch(main,{"type":"move","dx":direction.x,"dy":direction.y},_epoch)
