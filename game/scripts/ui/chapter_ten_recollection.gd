extends RefCounted
## Optional presentation only. No runtime input, receipt, reward, or persisted timer.
const EVENT_ID:="evt_ch10_three_months_complete"
var active:=false
var elapsed:=0.0
var remembered:=false
var _focused:=true
var _token:=""
var _dismissed:=""
var _origin:=Vector2.ZERO
var _last:=Vector2.ZERO
var _hearth:=Vector2(112,224)
var _epoch:=0
var _owner:WeakRef
func reset(main:Node,new_load:bool=false)->void:
 if active:
  main.world.controlled_view.clear()
  main.world.set_runtime_context(main.story.world_context())
  if main.story.current_token()==_token:main.world.player.position=_origin
  main.world.queue_redraw()
 active=false;elapsed=0.0;remembered=false;_epoch+=1
 if new_load:_dismissed=""
func set_focused(value:bool)->void:
 _focused=value;elapsed=0.0
 var main=_owner.get_ref() if _owner!=null else null
 if active and is_instance_valid(main):main.world.player.enabled=value and main.mode=="chapter_recollection" and main.dialogue_panel.is_visible_in_tree()
func saved_position(fallback:Vector2)->Vector2:return _origin if active else fallback
func offer(main:Node,event:Dictionary)->bool:
 if main.story.active_chapter!=10 or event.get("id","")!=EVENT_ID or main.story.actors.get("char_axue",{}).get("status")!="dead" or _dismissed==main.story.current_token():return false
 _owner=weakref(main)
 var anchor:Array=main.story.current_chapter_runtime().maps[main.story.scene().map_id].anchors.hearth
 _hearth=Vector2(anchor[0],anchor[1])
 _token=main.story.current_token();_origin=main.world.player.position;_last=_origin
 active=true;elapsed=0.0;remembered=false;_epoch+=1
 main.mode="chapter_recollection";main.modal.hide();main.dialogue_panel.show();main.world.player.enabled=true
 main.speaker.show();main.speaker.text="灶边追思";main.speaker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 main._clear(main.actions);var born:=_epoch
 main._button("继续行路",func():
  if active and _focused and born==_epoch and main.story.current_token()==_token:leave(main),main.actions)
 main._button("暂歇",func():
  if active and _focused and born==_epoch and main.story.current_token()==_token:main._show_menu(),main.actions)
 main.get_viewport().gui_release_focus();_text(main)
 return true
func _text(main:Node)->void:
 main.dialogue_text.text="梁萧在灶边低下目光，手轻轻按住衣襟里的旧物。火光微动，身旁再没有人回应。\nE／空格或继续行路：接回原对白。" if remembered else "临时灶的火还未熄。可用方向键／WASD 走到灶边，停留三秒，想一想阿雪。\nE／空格或继续行路：随时接回原对白；F5 保存、F9 读取。追思停留不写入存档。"
func leave(main:Node)->void:
 _dismissed=_token;reset(main);main._advance_chapter()
func handle_input(main:Node,event:InputEvent)->bool:
 if not active or main.mode!="chapter_recollection" or not event is InputEventKey:return false
 if event.is_action_pressed("save_game"):
  elapsed=0.0;main._save();return true
 if event.is_action_pressed("load_game"):
  elapsed=0.0;main._load("manual");return true
 if not _focused:return false
 var key:int=event.keycode if event.keycode!=0 else event.physical_keycode
 if event.pressed and not event.echo and (event.is_action_pressed("interact") or key in [KEY_E,KEY_SPACE,KEY_ENTER]):leave(main);return true
 return false
func tick(main:Node,delta:float)->void:
 if not active:return
 if main.story.current_token()!=_token:reset(main);return
 var position:Vector2=main.world.player.position
 var valid:bool=_focused and main.mode=="chapter_recollection" and main.dialogue_panel.is_visible_in_tree() and main.is_visible_in_tree() and not main.get_tree().paused
 main.world.player.enabled=valid
 if not valid or position.distance_to(_last)>0.01 or position.distance_to(_hearth)>12:elapsed=0.0
 elif not remembered:
  elapsed+=clampf(delta,0,0.1)
  if elapsed>=3.0-0.000001:remembered=true;_text(main)
 _last=position
 # Overlay follows actual feet; never let presentation project an old receipt's position.
 main.world.controlled_view={"map_id":main.story.scene().map_id,"control_actor_id":"char_liang_xiao","player_position":[position.x,position.y],"target_position":[_hearth.x,_hearth.y],"recollection":remembered}
 main.world.queue_redraw()
