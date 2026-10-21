extends SceneTree
const Helper=preload("res://scripts/ui/chapter_eleven_world_ui.gd")
const Prior=preload("res://tests/test_chapter_ten_world_ui.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func key(code:int,pressed:bool=true,echo:bool=false)->InputEventKey:
 var e:=InputEventKey.new();e.keycode=code;e.pressed=pressed;e.echo=echo;return e
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(640,360)
 var m=Prior.FakeMain.new();root.add_child(m);await process_frame
 m.helper=Helper.new();m.story.active_chapter=11;m.story.token="ch11:walk:0"
 m.current_view={"title":"雨中扶行","body":"目标：石棚；同行者尚在后面。","world_state":{"control_actor_id":"char_hua_xiaoshuang","stage":1},"options":[{"id":"care","label":"靠近照应","action":{"type":"interact"}},{"id":"wait","label":"等同行者","action":{"type":"wait"}}]}
 check(m.helper.render(m,m.current_view),"chapter11 handled")
 check(m.speaker.text.begins_with("花晓霜"),"current controller visible")
 check("石棚" in m.dialogue_text.text,"model target feedback retained")
 m.helper.handle_input(m,key(KEY_RIGHT));check(m.submitted==[{"type":"move","dx":1,"dy":0}],"press one legal move")
 m.helper.tick(m,0.07);check(m.submitted.size()==1,"repeat waits")
 m.helper.tick(m,0.07);check(m.submitted.size()==2,"repeat survives rerender")
 m.helper.handle_input(m,key(KEY_RIGHT,false));m.helper.tick(m,10);check(m.submitted.size()==2,"release stops")
 m.helper.handle_input(m,key(KEY_RIGHT));var count:int=m.submitted.size();m.helper.tick(m,60);check(m.submitted.size()==count,"stall cannot bank movements")
 m.helper.set_focused(false);m.helper.tick(m,1);m.helper.set_focused(true);m.helper.tick(m,1);check(m.submitted.size()==count,"focus return no autorepeat")
 m.helper.handle_input(m,key(KEY_E));check(m.submitted.back()=={"type":"interact"},"E offered interaction")
 count=m.submitted.size();m.helper.handle_input(m,key(KEY_E,true,true));check(m.submitted.size()==count,"E echo never repeats")
 m.helper.handle_input(m,key(KEY_SPACE));check(m.submitted.back()=={"type":"wait"},"Space offered wait")
 count=m.submitted.size();m.helper.handle_input(m,key(KEY_R));check(m.submitted.size()==count,"retry not invented")
 for code in [KEY_F5,KEY_F9,KEY_ESCAPE]:check(not m.helper.handle_input(m,key(code)),"system key remains main-owned")
 var picker:OptionButton=m.actions.get_child(4);picker.item_selected.emit(1)
 m.current_view.options.reverse();m.helper.render(m,m.current_view)
 picker=m.actions.get_child(4);check(picker.selected==0,"stable option ID across reorder")
 m.helper.handle_input(m,key(KEY_ENTER));check(m.submitted.back()=={"type":"wait"},"Enter selected semantic action")
 var stale:Button=m.actions.get_child(5);m.helper.render(m,m.current_view);count=m.submitted.size();stale.pressed.emit();check(m.submitted.size()==count,"stale execute rejected")
 picker=m.actions.get_child(4);picker.show_popup();check(not m.helper.handle_input(m,key(KEY_DOWN)),"open picker owns arrows");picker.get_popup().hide()
 m.helper.handle_input(m,key(KEY_RIGHT));m.mode="menu";m.helper.tick(m,0.2);m.mode="world_puzzle";count=m.submitted.size();m.helper.tick(m,0.2);check(m.submitted.size()==count,"menu clears held direction")
 m.helper.handle_input(m,key(KEY_RIGHT));m.dialogue_panel.hide();m.helper.tick(m,1);m.dialogue_panel.show();count=m.submitted.size();m.helper.tick(m,1);check(m.submitted.size()==count,"offscreen does not move")
 m.helper.handle_input(m,key(KEY_RIGHT));m.helper.handle_input(m,key(KEY_LEFT));count=m.submitted.size();m.helper.tick(m,0.07);m.helper.tick(m,0.07);check(m.submitted.size()==count,"opposing held keys do not drift")
 m.helper.set_focused(true)
 m.current_view.options=[];m.helper.render(m,m.current_view);count=m.submitted.size();m.helper.handle_input(m,key(KEY_E));m.helper.handle_input(m,key(KEY_SPACE));check(m.submitted.size()==count,"unoffered verbs not sent")
 m.current_view.options=[{"id":"long","label":"等待同行者跨过最后一道湿滑石阶后一起进入石棚","action":{"type":"wait"}}];m.helper.render(m,m.current_view)
 await process_frame;await process_frame
 for child in m.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(child.get_global_rect()),"640 control rectangle within screen")
 m.story.active_chapter=10;check(not m.helper.render(m,{}),"other chapter not intercepted")
 m.helper.reset();m.queue_free();await process_frame
 await real_main()
 print("Chapter eleven world UI: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

func real_main()->void:
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 app.size=Vector2(640,360);app._layout()
 var path:=OS.get_environment("CH11_SOURCE")
 if path.is_empty():path="/tmp/kunlun-ch10-gui-fixtures/command_terminal.json"
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","real main formal chapter10 command fixture restore")
 check(app.story.enter_registered_chapter(11),"real main enters11")
 var flow=load("res://tests/chapter_eleven_campaign_driver.gd")
 var tested:=0;var saw_x:=false
 for i in range(100):
  if app.story.state.finished:break
  if app.story.current_event().op=="world_puzzle":
   app._load_scene();check(app.mode=="world_puzzle","real main world routing")
   var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
   var actor:String=model.get_view().world_state.control_actor_id
   check(("花晓霜" if actor=="char_hua_xiaoshuang" else "梁萧") in app.speaker.text,"real main controller label")
   if actor=="char_hua_xiaoshuang":saw_x=true
   var action:Dictionary=model.next_demo_action()
   if action.type=="move":
    var code:int=KEY_RIGHT if action.dx>0 else (KEY_LEFT if action.dx<0 else (KEY_DOWN if action.dy>0 else KEY_UP))
    var before:int=model.input_log.size();app._input(key(code));check(model.input_log.size()==before+1,"actual main routes one legal move")
    app._input(key(code,false));app.chapter_eleven_world_ui.tick(app,1);check(model.input_log.size()==before+1,"actual main release halts repeat")
    app._input(key(code));app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);before=model.input_log.size()
    app.chapter_eleven_world_ui.tick(app,1);app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);app.chapter_eleven_world_ui.tick(app,1)
    check(model.input_log.size()==before,"actual main focus resume requires new press")
   app._input(key(KEY_F5));check(app.chapter_eleven_world_ui._token==app.story.current_token(),"actual main F5 retains live helper")
   app._show_menu();app._cancel_choice();check(app.mode=="world_puzzle" and app.chapter_eleven_world_ui._token==app.story.current_token(),"actual main menu rebuilds controls")
   app._input(key(KEY_F9));check(app.mode=="world_puzzle" and app.chapter_eleven_world_ui._token==app.story.current_token(),"actual main F9 rebuilds controls")
   await process_frame;await process_frame
   for child in app.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(child.get_global_rect()),"actual640 control fits "+str(child.get_global_rect())+" panel="+str(app.dialogue_panel.get_global_rect())+" screen="+str(app.size))
   tested+=1
   if tested>=2 and saw_x:break
  if not flow.advance(app.story,0,false):check(false,"real main command fixture advance "+app.story.current_token());break
 check(tested>=2 and saw_x,"both H and X control phases tested")
 app.queue_free();await process_frame
