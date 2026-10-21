extends SceneTree
const UI=preload("res://scripts/ui/chapter_twelve_world_ui.gd")
const Prior=preload("res://tests/test_chapter_ten_world_ui.gd")
class Host extends Prior.FakeMain:
 func _input(event:InputEvent)->void:
  if helper.handle_input(self,event):get_viewport().set_input_as_handled()
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func keyboard(code:int,pressed:bool=true,echo:bool=false)->void:
 var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.echo=echo;Input.parse_input_event(event)
func mouse(at:Vector2,pressed:bool)->void:
 var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(event)
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center();mouse(at,true);await process_frame;mouse(at,false);await process_frame
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(640,360)
 var m:=Host.new();root.add_child(m);await process_frame
 m.helper=UI.new();m.story.active_chapter=12;m.story.token="ch12:test:0"
 m.current_view={"title":"竹丝护人","body":"先牵开兵器，再让众人走向安全路。","world_state":{"control_actor_id":"char_liang_xiao","player_position":[64,128],"target_position":[128,128],"stage":0},"options":[{"id":"interact","label":"牵开兵器","action":{"type":"interact"}},{"id":"wait","label":"等同伴跟上","action":{"type":"wait"}}]}
 check(m.helper.render(m,m.current_view),"chapter12 owned")
 await process_frame;await process_frame
 var arrow:Button=m.actions.get_child(3);var arrow_id:=arrow.get_instance_id()
 await click(arrow);check(m.submitted==[{"type":"move","dx":1,"dy":0}],"parsed mouse movement")
 check(m.actions.get_child(3).get_instance_id()==arrow_id,"same phase retains real button")
 await click(arrow);check(m.submitted.size()==2,"second native mouse click works on retained button")
 keyboard(KEY_LEFT);keyboard(KEY_LEFT,false);await process_frame;check(m.submitted.back()=={"type":"move","dx":-1,"dy":0},"parsed keyboard move/release")
 var before:int=m.submitted.size();keyboard(KEY_LEFT,true,true);keyboard(KEY_LEFT,false);await process_frame;check(m.submitted.size()==before,"keyboard echo does not invent timed moves")
 keyboard(KEY_E);keyboard(KEY_E,false);await process_frame;check(m.submitted.back()=={"type":"interact"},"parsed E uses offered action")
 var execute:Button=m.actions.get_child(5);var at:=execute.get_global_rect().get_center()
 mouse(at,true);await process_frame;m.current_view.world_state.stage=1;m.helper.render(m,m.current_view);before=m.submitted.size();mouse(at,false);await process_frame
 check(m.submitted.size()==before,"phase change cancels pending pressed action")
 await click(execute);check(m.submitted.size()==before+1,"new phase accepts fresh parsed click")
 mouse(at,true);await process_frame;m.helper.set_focused(false);m.helper.set_focused(true);mouse(at,false);await process_frame;before=m.submitted.size()
 check(m.helper._armed.is_empty(),"focus clears pending click")
 await click(execute);check(m.submitted.size()==before+1,"focus return fresh click works")
 for code in [KEY_F5,KEY_F9,KEY_ESCAPE]:
  mouse(at,true);await process_frame;before=m.submitted.size();keyboard(code);keyboard(code,false);mouse(at,false);await process_frame;check(m.submitted.size()==before,"system key cancels pending click "+str(code))
 mouse(at,true);await process_frame;m.helper.reset();mouse(at,false);await process_frame;check(m.submitted.size()==before,"reset cancels pending click")
 m.helper.render(m,m.current_view);await process_frame
 await click(m.actions.get_child(6));check(m.mode=="menu","parsed pause opens menu")
 before=m.submitted.size();keyboard(KEY_E);keyboard(KEY_E,false);await process_frame;check(m.submitted.size()==before,"menu no world actions")
 m.mode="world_puzzle";m.helper.render(m,m.current_view)
 for pair in [["char_hua_xiaoshuang","花晓霜"],["char_huasheng","花生"]]:
  m.current_view.world_state.control_actor_id=pair[0];m.helper.render(m,m.current_view);check(m.speaker.text==pair[1],"controller label "+pair[1])
 var picker:OptionButton=m.actions.get_child(4);picker.select(1);picker.item_selected.emit(1)
 m.current_view.options.reverse();m.helper.render(m,m.current_view);check(picker.selected==0,"stable option across reordering")
 keyboard(KEY_ENTER);keyboard(KEY_ENTER,false);await process_frame;check(m.submitted.back()=={"type":"wait"},"parsed Enter retains chosen meaning")
 for width in [640,1280]:
  root.size=Vector2i(width,360 if width==640 else 720);m.dialogue_panel.size.x=width-24
  await process_frame;await process_frame
  for child in m.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(child.get_global_rect()),"control fits "+str(width))
 m.helper.reset();m.queue_free();await process_frame
 print("Chapter twelve world UI: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
