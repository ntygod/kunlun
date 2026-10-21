extends SceneTree
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const Saves=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func tap(code:int)->void:
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func feedback(app:Node,fragment:String)->bool:
 var panel=app.get_node_or_null("SaveHotkeyFeedback")
 return panel!=null and panel.is_visible_in_tree() and fragment in panel.get_child(0).text
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false);app.size=Vector2(640,360);app._layout()
 app.saves=Saves.new("user://feedback-test")
 var source:=OS.get_environment("CH11_SOURCE")
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","formal10 fixture restore")
 check(app.story.enter_registered_chapter(11),"enter11")
 app._load_scene();check(app.mode=="chapter_dialogue","legal initial dialogue")
 var before:=JSON.stringify(app.story.state);var line:int=app.line_index
 await tap(KEY_F5)
 check(feedback(app,"未保存"),"dialogue F5 gives visible not-saved feedback")
 check(JSON.stringify(app.story.state)==before and app.line_index==line,"dialogue F5 does not advance state or line")
 check(not FileAccess.file_exists("user://feedback-test/manual.json"),"unsupported F5 writes no manual save")
 for i in range(100):
  if app.story.current_event().op=="choice":break
  if not Flow.advance(app.story,0,false):check(false,"legal choice prefix");quit(1);return
 app._load_scene();check(app.mode=="chapter_choice","legal choice modal")
 before=JSON.stringify(app.story.state);await tap(KEY_F5)
 check(feedback(app,"未保存"),"choice F5 feedback is visible above modal")
 check(JSON.stringify(app.story.state)==before,"choice F5 changes no state")
 var panel=app.get_node_or_null("SaveHotkeyFeedback")
 if panel!=null:
  check(panel.z_index>app.modal.z_index,"feedback draws above the choice modal")
  check(panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and panel.get_child(0).mouse_filter==Control.MOUSE_FILTER_IGNORE and panel.focus_mode==Control.FOCUS_NONE,"feedback cannot capture pointer or keyboard focus")
  for resolution in [Vector2i(640,360),Vector2i(1280,720)]:
   root.size=resolution;app.size=Vector2(resolution);app._layout();await process_frame;await process_frame
   check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(panel.get_global_rect()),"feedback fits "+str(resolution))
   check(panel.get_child(0).size.y>=panel.get_child(0).get_minimum_size().y,"feedback text is not vertically clipped")
 var choice:Button
 for child in app.modal_content.get_children():
  if child is Button:choice=child;break
 choice.grab_focus();await tap(KEY_ENTER)
 check(app.mode=="chapter_feedback","F5 feedback does not swallow choice Return")
 await tap(KEY_ESCAPE);check(app.mode=="menu","F5 feedback does not swallow Escape")
 for i in range(100):
  if app.story.current_event().op=="world_puzzle":break
  if not Flow.advance(app.story,0,false):check(false,"legal world prefix");quit(1);return
 app._load_scene();check(app.mode=="world_puzzle","supported world stage")
 await tap(KEY_F5)
 check(FileAccess.file_exists("user://feedback-test/manual.json"),"supported F5 uses actual save")
 check(feedback(app,"已保存") and feedback(app,"上次手动保存"),"supported save labels last successful manual save rather than current unsaved state")
 var blocker:=FileAccess.open("user://save-feedback-blocker",FileAccess.WRITE);blocker.store_string("regular file blocks directory");blocker.close()
 var saved_sha:=FileAccess.get_sha256("user://feedback-test/manual.json")
 app.saves=Saves.new("user://save-feedback-blocker/child");await tap(KEY_F5)
 check(feedback(app,"无法创建存档目录"),"actual save failure is visible")
 check(FileAccess.get_sha256("user://feedback-test/manual.json")==saved_sha,"failed save preserves prior manual bytes")
 print("Save hotkey feedback: ",checks," checks, ",failures," failures")
 app.queue_free();await process_frame;quit(1 if failures else 0)
