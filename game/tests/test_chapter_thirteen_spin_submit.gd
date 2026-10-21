extends SceneTree
const PanelType=preload("res://scripts/ui/chapter_thirteen_puzzle_panel.gd")
const R=preload("res://scripts/puzzles/chapter_thirteen_puzzle_resolver.gd")
const Fixtures=preload("res://tests/test_chapter_thirteen_puzzles.gd")
var checks:=0
var failures:=0
var sent:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func click(b:Button)->void:
 var at:=b.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
  Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func edit(n:SpinBox,text:String)->void:
 n.get_line_edit().grab_focus();await process_frame;n.get_line_edit().select_all()
 var erase:=InputEventKey.new();erase.keycode=KEY_BACKSPACE;erase.pressed=true;Input.parse_input_event(erase);Input.flush_buffered_events()
 erase=InputEventKey.new();erase.keycode=KEY_BACKSPACE;erase.pressed=false;Input.parse_input_event(erase);Input.flush_buffered_events()
 for character in text:
  var e:=InputEventKey.new();e.unicode=character.unicode_at(0);e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()

func run()->void:
 root.size=Vector2i(640,360)
 var r:=R.new();r.begin(R.IDS[2],"spin",Fixtures.fixture(R.IDS[2]))
 var panel:=PanelType.new();root.add_child(panel);panel.position=Vector2(12,12);panel.size=Vector2(616,336);panel.render(r.get_view())
 panel.input_submitted.connect(func(a):sent.append(a))
 await process_frame;await process_frame
 panel._scroll.ensure_control_visible(panel._buttons.wheel);await process_frame;await process_frame
 var front:SpinBox=panel._numbers.front;var rear:SpinBox=panel._numbers.rear
 await edit(front,"2");front.apply();await edit(rear,"1")
 check(rear.get_line_edit().text=="1","focused edit remains visible before click")
 await click(panel._buttons.wheel)
 check(sent.size()==1 and sent[-1].front==2 and sent[-1].rear==1,"mouse submit uses visible 2:1")
 check(rear.value==1 and rear.get_line_edit().text=="1","visible and numeric agree after click")
 for pair in [["99",3],["-4",0],["oops",0],["",0],["2",2]]:
  await edit(rear,pair[0]);await click(panel._buttons.wheel)
  check(sent[-1].rear==pair[1] and rear.value==pair[1] and rear.get_line_edit().text==str(pair[1]),"normalize invalid/bounded text "+pair[0])
 await edit(rear,"1")
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=KEY_ENTER;e.physical_keycode=KEY_ENTER;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(rear.value==1,"LineEdit Return commits value")
 panel._buttons.wheel.grab_focus()
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=KEY_ENTER;e.physical_keycode=KEY_ENTER;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(sent[-1].front==2 and sent[-1].rear==1,"button Return submits current values")
 # Exercise the callback while the editor still owns focus. This is a
 # submission-boundary test, not a claim to reproduce the native GUI cause.
 await edit(rear,"2")
 check(rear.value==1 and rear.get_line_edit().text=="2","pending text differs from stored value")
 panel._buttons.wheel.pressed.emit()
 check(sent[-1].rear==2 and rear.value==2,"callback commits still-focused text")
 for pair in [["99",3],["-4",0],["oops",0],["",0]]:
  await edit(rear,pair[0]);panel._buttons.wheel.pressed.emit()
  check(sent[-1].rear==pair[1] and rear.get_line_edit().text==str(pair[1]),"focused callback normalizes "+pair[0])
 check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(panel._buttons.wheel.get_global_rect()),"640 submitted button visible")
 panel.queue_free();await process_frame
 print("Chapter thirteen pending SpinBox: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
