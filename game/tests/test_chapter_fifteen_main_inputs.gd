extends SceneTree
## Headless actual-main input/geometry regression; not desktop GUI or natural play.
const Flow=preload("res://tests/chapter_fifteen_campaign_driver.gd")
var checks:=0
var failures:=0
var app:Node
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func frames()->void:
 await process_frame;await process_frame
func key(code:int,pressed:bool)->void:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events()
func tap(code:int)->void:
 key(code,true);await process_frame;key(code,false);await frames()
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center()
 var move:=InputEventMouseMotion.new();move.position=at;move.global_position=at;Input.parse_input_event(move)
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 await frames()
func button(node:Node,text:String)->Button:
 if node is Button and node.text==text:return node
 for child in node.get_children():
  var result:=button(child,text)
  if result!=null:return result
 return null
func model()->RefCounted:return app.story.current_chapter_runtime().make_puzzle()
func snapshot()->String:return JSON.stringify([model().get_view().world_state,model().input_log,app.story.current_token(),app.world.player.actor_id,app.world.player.position])
func next_key()->int:
 var action:Dictionary=model().next_demo_action()
 if action.get("type")=="interact":return KEY_E
 if action.get("type")=="wait":return KEY_SPACE
 return KEY_RIGHT if action.get("dx",0)>0 else (KEY_LEFT if action.get("dx",0)<0 else (KEY_DOWN if action.get("dy",0)>0 else KEY_UP))
func arrow_index(code:int)->int:return [KEY_LEFT,KEY_UP,KEY_DOWN,KEY_RIGHT].find(code)
func assert_controller(expected:String)->void:
 var names:Dictionary={"char_liang_xiao":"梁萧","char_liu_yingying":"柳莺莺","char_hua_xiaoshuang":"花晓霜","char_huasheng":"花生"}
 check(app.world.player.actor_id==expected and model().get_view().world_state.control_actor_id==expected,"actual model and world controller agree "+expected)
 check(app.speaker.text==names[expected],"controller label names "+expected)
func run()->void:
 var source:=OS.get_environment("CH15_SOURCE")
 check(not source.is_empty() and FileAccess.file_exists(source),"CH15_SOURCE must name formal chapter14 terminal")
 if failures:quit(1);return
 var bytes:=FileAccess.get_file_as_bytes(source);var source_sha:=FileAccess.get_sha256(source)
 var saved:Dictionary=JSON.parse_string(bytes.get_string_from_utf8())
 check(int(saved.get("active_chapter",0))==14,"source is chapter14, not misleadingly named old chapter12 fixture")
 if failures:quit(1);return
 print("CH15_SOURCE ",source," SHA256 ",source_sha)
 root.size=Vector2i(640,360)
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frames();app.set_process(false);app.size=Vector2(640,360);app._layout()
 check(app.story.restore_persisted(saved)=="","strict formal14 restore")
 check(app.story.state.finished and app.story.enter_registered_chapter(15),"finished14 enters registered14")
 if failures:app.queue_free();await process_frame;quit(1);return
 for i in range(100):
  if app.story.current_event().op=="world_puzzle":break
  if not Flow.advance(app.story,0,true):check(false,"legal15 first world prefix "+str(app.story.current_event()));quit(1);return
 app._load_scene();await frames()
 check(app.mode=="world_puzzle","first world enters actual main controls")
 assert_controller(app.story.current_chapter_runtime().control_actor_id())
 var count:int=model().input_log.size();var code:=next_key()
 check(arrow_index(code)>=0,"first world begins with legal movement")
 if arrow_index(code)<0:quit(1);return
 await click(app.actions.get_child(arrow_index(code)))
 check(model().input_log.size()==count+1,"parsed arrow mouse click dispatches one command")
 count=model().input_log.size();await tap(next_key())
 check(model().input_log.size()==count+1,"parsed directional key dispatches one command")
 var before:=snapshot();app.chapter_fifteen_world_ui.tick(app,60)
 check(snapshot()==before,"no hidden repeat or time progression after release")
 # First save in this process: no unsupported warning prewarms toast layout.
 await tap(KEY_F5)
 var toast:Control=app.get_node("SaveHotkeyFeedback")
 check(FileAccess.file_exists("user://saves/manual.json"),"first F5 actually saves")
 check(toast.is_visible_in_tree() and toast.size.y<=72 and "上次手动保存" in toast.get_child(0).text,"first-save banner is compact and explicit")
 print("FIRST15_TOAST ",toast.get_global_rect())
 before=snapshot();await tap(next_key());await tap(KEY_F9)
 check(snapshot()==before,"F9 restores exact partial world state and controller feet")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);before=snapshot()
 await tap(next_key());check(snapshot()==before,"application focus-out blocks parsed movement")
 await tap(KEY_F5);check(not app.chapter_fifteen_world_ui._focused,"F5 does not grant focus")
 await tap(next_key());check(snapshot()==before,"unfocused F5 cannot reactivate movement")
 await tap(KEY_F9);before=snapshot();await tap(next_key())
 check(snapshot()==before and not app.chapter_fifteen_world_ui._focused,"unfocused F9 preserves input gate")
 await tap(KEY_ESCAPE);check(app.mode=="menu","unfocused Escape still opens menu")
 var resume:=button(app.modal_content,"返回行旅")
 check(resume!=null,"menu has resume control")
 if resume==null:quit(1);return
 await click(resume);before=snapshot();await tap(next_key())
 check(snapshot()==before and not app.chapter_fifteen_world_ui._focused,"parsed menu resume preserves focus boundary")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);await tap(next_key())
 check(snapshot()!=before,"new input after focus-in resumes movement")
 for resolution in [Vector2i(1280,720),Vector2i(640,360)]:
  root.size=resolution;app.size=Vector2(resolution);app._layout();await frames()
  var fits:=true
  for child in app.actions.get_children():fits=fits and Rect2(Vector2.ZERO,Vector2(resolution)).encloses(child.get_global_rect())
  check(fits,"world controls fit "+str(resolution))
 var picker:OptionButton=app.actions.get_child(4)
 await click(picker);check(picker.get_popup().visible,"parsed mouse opens semantic options")
 await tap(KEY_ESCAPE);check(not picker.get_popup().visible and app.mode=="world_puzzle","first Escape closes popup only")
 before=snapshot();await click(picker);await tap(KEY_DOWN);await tap(KEY_ENTER)
 check(not picker.get_popup().visible and app.chapter_fifteen_world_ui._selected==model().get_view().options[picker.selected].id,"parsed popup selection preserves offered semantic identity")
 check(snapshot()==before,"popup selection does not execute a world action")
 # Reach a real interaction using legal parsed moves; execute via visible option.
 for i in range(100):
  if model().next_demo_action().get("type")=="interact":break
  await tap(next_key())
 check(model().next_demo_action().get("type")=="interact","target reached through actual movement")
 count=model().input_log.size();await click(app.actions.get_child(5))
 check(model().input_log.size()==count+1,"visible execute dispatches one offered interaction")
 await tap(KEY_ESCAPE)
 var scroll:ScrollContainer=app.modal_content.get_parent();scroll.scroll_vertical=100000;await frames()
 check(scroll.scroll_vertical>0,"actual menu can scroll")
 # Journal is an existing UI entry; opening it changes presentation only.
 app._show_journal();await frames()
 check(scroll.scroll_vertical==0 and app.modal_content.get_child(0).get_global_rect().position.y>=scroll.get_global_rect().position.y,"new journal entry clears previous menu offset")
 app._cancel_choice();await frames()
 # Reach the independent eastline from legal commands, never edit character state.
 for i in range(160):
  if app.story.current_event().op=="world_puzzle" and app.story.current_chapter_runtime().control_actor_id()=="char_hua_xiaoshuang":break
  if not Flow.advance(app.story,0,true):check(false,"legal prefix to eastline");quit(1);return
 app._load_scene();await frames();assert_controller("char_hua_xiaoshuang")
 check(hidden_standing("char_liang_xiao"),"westbound Liang not visible on independent eastline")
 await tap(next_key());await tap(KEY_F5);before=snapshot()
 await tap(next_key());await tap(KEY_F9)
 check(snapshot()==before,"eastline partial restores controller and position")
 check(hidden_standing("char_liang_xiao"),"Liang stays absent after F9")
 for i in range(180):
  if app.story.current_event().op=="objective_battle":break
  if not Flow.advance(app.story,0,true):check(false,"legal prefix to B12");quit(1);return
 app._load_scene();await frames()
 check(app.story.current_event().op=="objective_battle","B12 entered")
 check(app.story.current_chapter_runtime().battle_actor_ids()==["char_hua_xiaoshuang","char_huasheng"],"B12 uses independent healer and Huasheng party")
 check(hidden_standing("char_liang_xiao"),"Liang not projected in B12")
 for i in range(180):
  if app.story.state.finished:break
  if not Flow.advance(app.story,0,true):check(false,"legal prefix to chapter15 terminal");quit(1);return
 check(app.story.state.finished,"legal chapter15 terminal reached")
 app._load_scene();await frames()
 app._show_journal();await frames()
 var journal:=visible_text(app.modal_content)
 check("百丈离散" in journal and "东线自立" in journal,"both chapter memories visible in generated journal")
 check("荒村留灯" in journal and app.story.state.optional.R06.status=="archived","R06 committed memory visible in actual journal")
 check(app.modal_content.find_child("axue_empty_seat",true,false)!=null,"Axue empty seat retained")
 check(FileAccess.get_sha256(source)==source_sha,"formal source bytes remain untouched")
 print("Chapter fifteen actual main inputs: ",checks," checks, ",failures," failures")
 app.queue_free();await process_frame;quit(1 if failures else 0)
func visible_text(node:Node)->String:
 var result:String=node.text if node is Label or node is RichTextLabel else ""
 for child in node.get_children():result+="\n"+visible_text(child)
 return result
func hidden_standing(id:String)->bool:
 return not app.world.cast_actors.has(id) or not app.world.cast_actors[id].visible
