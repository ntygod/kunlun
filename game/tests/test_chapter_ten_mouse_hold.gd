extends SceneTree
## Real Godot input dispatch; 32 x 50ms simulated ticks are NOT wall-clock GUI evidence.
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func mouse(at:Vector2,pressed:bool)->void:
 var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;event.pressed=pressed;Input.parse_input_event(event)
func frames(app:Node,count:int)->void:
 for i in range(count):
  app.chapter_ten_world_ui.tick(app,0.05)
  await process_frame
func progress(app:Node)->int:
 var state:Dictionary=app.story.current_chapter_runtime().make_puzzle().get_view().state
 return int(state.stage)*1500+int(state.held_ms)
func press(app:Node)->void:
 await process_frame;await process_frame
 mouse(app.actions.get_child(0).get_global_rect().get_center(),true)
 await process_frame
func release()->void:
 mouse(Vector2(3,3),false);await process_frame
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 var source:=OS.get_environment("CH10_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","original9 restore")
 check(app.story.enter_registered_chapter(10),"enter10")
 for i in range(100):
  if app.story.current_event().id=="world_ch10_farewell":break
  if not Flow.advance(app.story):check(false,"fixture command advance");quit(1);return
 var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
 for i in range(100):
  if model.get_view().world_state.at_target:break
  app.story.current_chapter_runtime().puzzle_input(app.story.current_token(),model.next_demo_action())
 app._load_scene();app._layout();await process_frame;await process_frame
 var hold:Button=app.actions.get_child(0)
 check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(hold.get_global_rect()),"640 hold button visible")
 print("Hold rect ",hold.get_global_rect()," viewport ",root.size)
 await press(app);check(app.chapter_ten_world_ui._mouse_action=="hold","parse mouse press starts hold")
 await frames(app,32)
 print("After simulated1600ms progress ",progress(app)," mouse_action ",app.chapter_ten_world_ui._mouse_action)
 check(progress(app)==1500,"held mouse spans six rerenders in simulated1600ms")
 await release();var before:=progress(app);await frames(app,10);check(progress(app)==before,"global offbutton release stops")
 await press(app);await frames(app,5);check(progress(app)==before+250,"fresh mouse press resumes")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);before=progress(app);await frames(app,10)
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);await frames(app,10);check(progress(app)==before,"focus return no held resume")
 await release();await press(app);app._show_menu();before=progress(app);await frames(app,10);app._cancel_choice();await frames(app,10);check(progress(app)==before,"menu return no held resume")
 await release();await press(app);app.chapter_ten_world_ui.reset();before=progress(app);await frames(app,10);check(progress(app)==before,"reset discards held input")
 await release()
 app._show_world_puzzle();var farewell_token:String=app.story.current_token()
 await press(app);await frames(app,30);await release()
 check(app.story.current_token()!=farewell_token,"second-stage parsed hold completes farewell without driver")
 for i in range(100):
  if app.story.current_event().id=="world_ch10_shore_walk":break
  if not Flow.advance(app.story):check(false,"shore fixture command advance");quit(1);return
 check(app.story.current_event().id=="world_ch10_shore_walk","reach shore by legal commands")
 app._load_scene();await process_frame;await process_frame
 model=app.story.current_chapter_runtime().make_puzzle()
 var start:Array=model.get_view().world_state.player_position.duplicate()
 var arrow:Button=app.actions.get_child(3)
 check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(arrow.get_global_rect()),"640 right arrow visible")
 mouse(arrow.get_global_rect().get_center(),true);await process_frame;await frames(app,32)
 print("Shore start ",start," end ",model.state.position," active_ms ",model.state.active_ms," mouse ",app.chapter_ten_world_ui._mouse_action)
 check(model.state.active_ms==1500 and Vector2(model.state.position[0],model.state.position[1])==Vector2(start[0]+6,start[1]),"parsed shore right hold survives six rerenders")
 await release();before=int(model.state.active_ms);await frames(app,10);check(model.state.active_ms==before,"shore release stops")
 mouse(app.actions.get_child(3).get_global_rect().get_center(),true);await process_frame
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);await frames(app,10);app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);await frames(app,10)
 check(model.state.active_ms==before,"shore focus return stops held arrow")
 await release();mouse(app.actions.get_child(3).get_global_rect().get_center(),true);await process_frame
 app._show_menu();await frames(app,10);app._cancel_choice();await frames(app,10)
 model=app.story.current_chapter_runtime().make_puzzle();check(model.state.active_ms==before,"shore menu return stops held arrow")
 await release();app.queue_free();await process_frame
 print("Chapter ten parsed mouse hold: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
