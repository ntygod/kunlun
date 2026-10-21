extends SceneTree
## Real main scene + command-driven fixture; simulated frames are not GUI timing evidence.
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures+=1;push_error(label)
func key(code:int,pressed:bool=true)->InputEventKey:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;return e
func frames(app:Node,count:int)->void:
 for i in range(count):app.chapter_ten_world_ui.tick(app,0.05)
func held(app:Node)->int:return int(app.story.current_chapter_runtime().make_puzzle().get_view().world_state.held_ms)
func _initialize()->void:call_deferred("run")
func run()->void:
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 var source:=OS.get_environment("CH10_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","restore unchanged chapter9 source")
 check(app.story.enter_registered_chapter(10),"enter chapter10")
 for i in range(100):
  if app.story.current_event().id=="world_ch10_farewell":break
  if not Flow.advance(app.story):check(false,"command fixture advance "+app.story.current_token()+" "+str(app.story.current_event()));quit(1);return
 check(app.story.current_event().id=="world_ch10_farewell","reach farewell by commands")
 var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
 for i in range(100):
  if model.get_view().world_state.at_target:break
  app.story.current_chapter_runtime().puzzle_input(app.story.current_token(),model.next_demo_action())
 app._load_scene();check(app.mode=="world_puzzle","actual main opens controlled farewell")
 app._input(key(KEY_E));frames(app,5);check(held(app)==250,"actual main key hold")
 app._input(key(KEY_E,false));frames(app,10);check(held(app)==250,"actual main release")
 app._input(key(KEY_F5));check(app.chapter_ten_world_ui._token==app.story.current_token(),"F5 retains valid view")
 app._input(key(KEY_E));frames(app,5);app._input(key(KEY_E,false));check(held(app)==500,"F5 allows fresh hold")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);frames(app,10)
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(app.chapter_ten_world_ui._token==app.story.current_token(),"focus return retains valid view")
 app._input(key(KEY_E));frames(app,5);app._input(key(KEY_E,false));check(held(app)==750,"focus return allows fresh hold")
 app._show_menu();frames(app,10);check(held(app)==750,"menu blocks time")
 check(app.header.visible and app.objective.visible and app.notice.visible,"quiet scene menu restores chrome")
 app._cancel_choice();app._input(key(KEY_E));frames(app,5);app._input(key(KEY_E,false));check(held(app)==1000,"menu return rebuilds controls")
 app._load("missing-ui-regression-slot");check(app.chapter_ten_world_ui._token==app.story.current_token(),"failed load retains valid view")
 app._input(key(KEY_E));frames(app,5);app._input(key(KEY_E,false));check(held(app)==1250,"failed load permits continued hold")
 var physical:Button=app.actions.get_child(0);physical.button_down.emit();frames(app,5)
 await process_frame
 frames(app,5);check(held(app)==250,"mouse hold survives actual button removal across phase")
 var release:=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;app._input(release);frames(app,5);check(held(app)==250,"mouse release reaches actual main")
 for i in range(100):
  if app.story.state.finished:break
  if not Flow.advance(app.story):check(false,"terminal fixture advance "+app.story.current_token());quit(1);return
 check(app.story.state.finished and app.story.actors.char_axue.status=="dead","legal terminal fixture")
 root.size=Vector2i(640,360);app.size=Vector2(640,360);app._load_scene();app._layout()
 await process_frame;await process_frame
 check(app.mode=="ending","chapter10 ending shown")
 check(app.header.visible and app.objective.visible and app.notice.visible,"quiet scene exit restores chrome")
 var screen:=Rect2(Vector2.ZERO,Vector2(640,360))
 check(screen.encloses(app.modal.get_global_rect()),"640 ending modal fits")
 for child in app.modal_content.get_children():
  if child is Label:
   check(child.get_global_rect().position.x>=0 and child.get_global_rect().end.x<=640,"640 ending text wraps within viewport")
 app._show_journal();await process_frame;await process_frame
 var seat:Node=app.modal_content.get_node_or_null("axue_empty_seat")
 check(seat!=null,"actual campaign journal creates dead Axue empty seat")
 if seat!=null:
  var card:Label=seat.get_child(0)
  check("空席" in card.text and "气血" not in card.text and "真气" not in card.text,"seat has no live vitals")
  check(seat.get_theme_stylebox("panel").bg_color==Color("e8e5dc"),"empty seat uses white mourning panel")
 var journal_text:=""
 for child in app.modal_content.get_children():
  if child is Label:journal_text+=child.text
 check("阿雪" in journal_text and "不能再出战" in journal_text,"journal records permanent absence")
 app._cancel_choice();check(app.mode=="ending","journal returns to ending")
 app.queue_free();await process_frame
 print("Chapter ten real main UI: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
