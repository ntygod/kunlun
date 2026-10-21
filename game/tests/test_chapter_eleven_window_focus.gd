extends SceneTree
## Headless WM-notification and native-event regression; no OS focus simulation claim.
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 print("CHECK ",label," = ",value)
 if not value:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func tap(code:int)->void:
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func snapshot(app:Node)->String:
 var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
 return JSON.stringify([model.state,model.input_log,app.story.current_token(),app.world.player.position])
func find_button(node:Node,text:String)->Button:
 if node is Button and node.text==text:return node
 for child in node.get_children():
  var result:=find_button(child,text)
  if result!=null:return result
 return null
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false);app.size=Vector2(640,360);app._layout()
 var source:=OS.get_environment("CH11_SOURCE")
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","formal chapter10 source restored")
 check(app.story.enter_registered_chapter(11),"entered11")
 var flow=load("res://tests/chapter_eleven_campaign_driver.gd")
 for i in range(100):
  if app.story.current_event().op=="world_puzzle":break
  if not flow.advance(app.story,0,false):check(false,"legal prefix");quit(1);return
 app._load_scene();await process_frame;await process_frame
 print("EVENT ",app.story.current_token()," MODE ",app.mode)
 var picker:OptionButton=app.actions.get_child(4)
 await click(picker);check(picker.get_popup().visible,"native mouse opens picker")
 await tap(KEY_ESCAPE);check(not picker.get_popup().visible and app.mode=="world_puzzle","first Escape closes picker only")
 print("FOCUS after picker ",root.gui_get_focus_owner())
 var before:=snapshot(app)
 app._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 var focus_id:int=root.gui_get_focus_owner().get_instance_id()
 await tap(KEY_RIGHT)
 check(snapshot(app)==before,"unfocused native arrow cannot mutate authoritative model or feet")
 check(is_instance_valid(root.gui_get_focus_owner()) and root.gui_get_focus_owner().get_instance_id()==focus_id,"unfocused gameplay key cannot navigate GUI focus")
 await tap(KEY_F5)
 check(not app.chapter_eleven_world_ui._focused,"F5 cannot grant application focus")
 before=snapshot(app);await tap(KEY_RIGHT)
 check(snapshot(app)==before,"unfocused F5 then arrow cannot advance")
 await tap(KEY_F9)
 check(not app.chapter_eleven_world_ui._focused,"F9 cannot grant application focus")
 before=snapshot(app);await tap(KEY_RIGHT)
 check(snapshot(app)==before,"unfocused F9 then arrow cannot advance")
 await tap(KEY_ESCAPE);check(app.mode=="menu","unfocused Escape opens menu without popup")
 var resume:=find_button(app.modal_content,"返回行旅")
 check(resume!=null,"menu offers native resume control")
 if resume==null:quit(1);return
 await click(resume)
 check(app.mode=="world_puzzle" and not app.chapter_eleven_world_ui._focused,"native menu resume preserves application focus boundary")
 before=snapshot(app);await tap(KEY_RIGHT)
 check(snapshot(app)==before,"menu resume while unfocused cannot advance")
 app._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
 app.chapter_eleven_world_ui.tick(app,0.14)
 check(snapshot(app)==before,"focus return cannot replay stale movement")
 await tap(KEY_RIGHT);check(snapshot(app)!=before,"fresh focused key resumes legal movement")
 before=snapshot(app);app.chapter_eleven_world_ui.tick(app,0.14)
 check(snapshot(app)==before,"native keyup prevents held repeat")
 before=snapshot(app)
 app.get_window().focus_exited.emit()
 await tap(KEY_RIGHT)
 check(not app.chapter_eleven_world_ui._focused and snapshot(app)==before,"connected window focus_exited signal gates movement without application notification")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(not app.chapter_eleven_world_ui._focused,"application focus-in alone cannot override window focus-out")
 app.get_window().focus_entered.emit()
 check(app.chapter_eleven_world_ui._focused,"connected window focus_entered restores cache after application focus-in")
 var fresh_picker:OptionButton=app.actions.get_child(4)
 await click(fresh_picker)
 check(fresh_picker.get_popup().visible,"window focus tracking does not close native dropdown")
 await tap(KEY_ESCAPE)
 check(not fresh_picker.get_popup().visible and app.mode=="world_puzzle","dropdown still owns first Escape")
 # Reach a genuine two-option follower state through legal model commands.
 for i in range(100):
  var current:RefCounted=app.story.current_chapter_runtime().make_puzzle()
  if current.get_view().options.size()>1:break
  app._world_puzzle_input(current.next_demo_action())
 await process_frame;await process_frame
 var choices:Array=app.story.current_chapter_runtime().make_puzzle().get_view().options
 check(choices.size()==2,"legal follower stage offers second option")
 if choices.size()==2:
  fresh_picker=app.actions.get_child(4)
  await click(fresh_picker);await tap(KEY_DOWN);await tap(KEY_DOWN);await tap(KEY_ENTER)
  check(app.chapter_eleven_world_ui._selected==str(choices[1].id),"native popup second selection updates semantic UI state")
  check(not fresh_picker.get_popup().visible,"native item selection closes popup normally")
  var count:int=app.story.current_chapter_runtime().make_puzzle().input_log.size()
  await click(app.actions.get_child(5))
  var updated:RefCounted=app.story.current_chapter_runtime().make_puzzle()
  check(updated.input_log.size()==count+1 and updated.input_log.back().type=="wait","native execute dispatches selected follower wait")
 print("Chapter eleven window focus boundary: ",checks," checks, ",failures," failures")
 app.queue_free();await process_frame;quit(1 if failures else 0)
