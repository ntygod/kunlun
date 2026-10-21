extends SceneTree
## Real first F5, then presentation-only length/resize checks. Not GUI pixel QA.
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for initial in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=initial
  var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false);app.size=Vector2(initial);app._layout()
  var source:=OS.get_environment("CH11_SOURCE")
  check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="" and app.story.enter_registered_chapter(11),"legal first-save fixture")
  for i in range(100):
   if app.story.current_event().op=="world_puzzle":break
   if not Flow.advance(app.story,0,false):check(false,"legal world prefix");quit(1);return
  app._load_scene()
  for pressed in [true,false]:
   var e:=InputEventKey.new();e.keycode=KEY_F5;e.physical_keycode=KEY_F5;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
  var panel:Control=app.get_node("SaveHotkeyFeedback");var label:Label=panel.get_child(0)
  check(FileAccess.file_exists("user://saves/manual.json") and "已保存" in label.text,"first native F5 really saves without prior warning")
  print("FIRST_F5 initial=",initial," panel=",panel.get_global_rect()," label=",label.get_global_rect())
  check(panel.size.y<=72,"first native F5 compact before any corrective layout")
  var messages:Array[String]=[label.text,"无法创建存档目录","本次未保存。请返回行走界面，或在可保存的机关、战斗阶段按 F5。",label.text]
  for stage in range(messages.size()):
   if stage>0:app._show_save_hotkey_feedback(messages[stage])
   var compact:=true;var contained:=true;var readable:=true
   for resolution in [initial,Vector2i(1280,720) if initial.x==640 else Vector2i(640,360),initial]:
    root.size=resolution;app.size=Vector2(resolution);app._layout()
    for frame in range(8):
     await process_frame
     if frame not in [0,1,7]:continue
     print("TOAST initial=",initial," stage=",stage," frame=",frame+1," screen=",resolution," panel=",panel.get_global_rect()," label=",label.get_global_rect()," minimum=",panel.get_combined_minimum_size()," label_minimum=",label.get_minimum_size())
     compact=compact and panel.size.y<=72
     contained=contained and Rect2(Vector2.ZERO,Vector2(resolution)).encloses(panel.get_global_rect())
     readable=readable and panel.get_global_rect().encloses(label.get_global_rect()) and label.size.y>=label.get_minimum_size().y and label.text==messages[stage] and label.visible_ratio==1.0
   check(compact,"multi-frame max72px stage"+str(stage))
   check(contained,"resize stays within viewport stage"+str(stage))
   check(readable,"full text within panel stage"+str(stage))
  app.queue_free();await process_frame
 print("Save toast layout: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
