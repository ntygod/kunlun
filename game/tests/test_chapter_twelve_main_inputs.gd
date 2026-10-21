extends SceneTree
## Legal chapter11 command fixture -> Flow12 prefix -> actual main input routing.
## Parsed input + headless Control layout are not manual GUI or wall-clock evidence.
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Store=preload("res://scripts/save_store.gd")
const SOURCE_SHA="2ee4e7e97d8741113c088639300a9fd850719f43745f56bcfb2e3771e45c1cb7"
const SAVE_DIR="user://chapter_twelve_main_inputs"
var checks:=0
var failures:=0
var app:Node
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func keyboard(code:int,pressed:bool=true,echo:bool=false)->void:
 var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.echo=echo;Input.parse_input_event(event)
func mouse(at:Vector2,pressed:bool)->void:
 var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(event)
func frames()->void:
 await process_frame;await process_frame
func tap(code:int)->void:
 keyboard(code);keyboard(code,false);await frames()
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center();mouse(at,true);await process_frame;mouse(at,false);await frames()
func model()->RefCounted:return app.story.current_chapter_runtime().make_puzzle()
func snapshot()->Dictionary:return model().snapshot().duplicate(true)
func next_key()->int:
 var action:Dictionary=model().next_demo_action()
 if action.get("type")!="move":return KEY_E
 return KEY_RIGHT if action.dx>0 else (KEY_LEFT if action.dx<0 else (KEY_DOWN if action.dy>0 else KEY_UP))
func arrow_index(code:int)->int:return {KEY_LEFT:0,KEY_UP:1,KEY_DOWN:2,KEY_RIGHT:3}.get(code,3)
func button_named(node:Node,label:String)->Button:
 if node is Button and node.text==label:return node
 for child in node.get_children():
  var found:=button_named(child,label)
  if found!=null:return found
 return null
func instantiate_main()->void:
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frames()
 app.set_process(false);app.size=Vector2(640,360);app.saves=Store.new(SAVE_DIR);app._layout();await frames()
func run()->void:
 root.size=Vector2i(640,360)
 var source:String=OS.get_environment("CH12_SOURCE")
 if source.is_empty() or not FileAccess.file_exists(source):push_error("CH12_SOURCE must name a verified chapter11 command terminal");quit(1);return
 var original:=FileAccess.get_file_as_bytes(source)
 check(original.hex_encode().length()>0,"source actual bytes available")
 check(FileAccess.get_sha256(source)==SOURCE_SHA,"approved formal11 noR04 source hash")
 if failures:quit(1);return
 await instantiate_main()
 check(app.story.restore_persisted(JSON.parse_string(original.get_string_from_utf8()))=="","main formal restore of chapter11 command source")
 check(app.story.enter_registered_chapter(12),"main enters registered12 without fabricated state")
 for i in range(40):
  if app.story.current_event().id=="world_ch12_bamboo_disarm":break
  check(Flow.advance(app.story,0,false),"legal Flow12 prefix "+str(app.story.current_event().id))
  if failures:break
 check(app.story.current_event().id=="world_ch12_bamboo_disarm","prefix stops at first controlled world before B08")
 if failures:quit(1);return
 app._load_scene();await frames()
 check(app.mode=="world_puzzle","main routes controlled world")
 check(app.speaker.text=="梁萧" and model().get_view().world_state.control_actor_id=="char_liang_xiao","actual model and displayed controller agree")
 check(app.world.player.position==Vector2(model().state.position[0],model().state.position[1]),"initial projection agrees with live model")
 var code:=next_key();check(code!=KEY_E,"initial target requires physical movement")
 var b:Button=app.actions.get_child(arrow_index(code));var instance:=b.get_instance_id();var count:int=model().input_log.size()
 await click(b)
 check(model().input_log.size()==count+1,"native mouse click sends exactly one legal model move")
 check(app.actions.get_child(arrow_index(code)).get_instance_id()==instance,"same-phase main refresh retains native button instance")
 count=model().input_log.size();code=next_key();await click(app.actions.get_child(arrow_index(code)))
 check(model().input_log.size()==count+1,"second actual mouse click survives refresh")
 count=model().input_log.size();code=next_key();await tap(code)
 check(model().input_log.size()==count+1,"parsed key movement passes main event router")
 var before:=snapshot();keyboard(code,true,true);keyboard(code,false);await frames()
 check(Same.equivalent(before,snapshot()),"key echo does not append hidden movement")
 # A real picker popup owns the first Escape; it must not open the system menu.
 var picker:OptionButton
 for child in app.actions.get_children():
  if child is OptionButton:picker=child
 await click(picker)
 check(picker.get_popup().visible,"native mouse opens world choice popup")
 await tap(KEY_ESCAPE)
 check(not picker.get_popup().visible and app.mode=="world_puzzle","Escape closes picker without opening system menu")
 # Focus notifications route through the real main, then inject real input.
 before=snapshot();app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
 var focus_before:=root.gui_get_focus_owner()
 await tap(next_key())
 check(root.gui_get_focus_owner()==focus_before,"unfocused gameplay keys cannot move GUI focus")
 check(Same.equivalent(before,snapshot()),"unfocused key cannot fall through generic main movement")
 await tap(KEY_F5)
 check(FileAccess.file_exists(SAVE_DIR+"/manual.json"),"unfocused F5 still uses explicit save route")
 await tap(next_key())
 check(Same.equivalent(before,snapshot()),"unfocused save does not restore gameplay focus")
 await tap(KEY_ESCAPE)
 check(app.mode=="menu","unfocused Escape opens system menu")
 var unfocused_return:=button_named(app.modal_content,"返回行旅")
 check(unfocused_return!=null,"unfocused system menu offers resume")
 if unfocused_return==null:quit(1);return
 await click(unfocused_return);await tap(next_key())
 check(app.mode=="world_puzzle" and Same.equivalent(before,snapshot()),"menu resume cannot grant focus without focus-in notification")
 await tap(KEY_F9);await tap(next_key())
 check(Same.equivalent(before,snapshot()),"unfocused F9 restores saved state without enabling world movement")
 app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);await frames()
 check(Same.equivalent(before,snapshot()),"focus return alone never advances model")
 count=model().input_log.size();await tap(next_key())
 check(model().input_log.size()==count+1,"fresh key after focus restores movement")
 # Cancel a native pending click via focus, not direct signal emission.
 b=app.actions.get_child(arrow_index(next_key()));var at:=b.get_global_rect().get_center();before=snapshot()
 mouse(at,true);await process_frame;app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);mouse(at,false);await frames()
 check(Same.equivalent(before,snapshot()),"focus invalidates a pending native mouse press")
 before=snapshot();await click(app.actions.get_child(6))
 check(app.mode=="menu","native pause click opens real main menu")
 await tap(KEY_RIGHT)
 check(Same.equivalent(before,snapshot()),"menu keyboard does not mutate controlled world")
 var resume:=button_named(app.modal_content,"返回行旅")
 check(resume!=null,"actual menu offers return button")
 if resume==null:quit(1);return
 await click(resume)
 check(app.mode=="world_puzzle" and Same.equivalent(before,snapshot()),"native resume restores exact partial phase")
 # F5 writes the real manual file; F9 restores after actual further movement.
 before=snapshot();var saved_token:String=app.story.current_token();await tap(KEY_F5)
 var manual:=SAVE_DIR+"/manual.json"
 check(FileAccess.file_exists(manual),"physical F5 produced an actual manual file")
 check(app.notice.text=="已保存到手动槽位","main reports successful actual save")
 var saved_bytes:=FileAccess.get_file_as_bytes(manual)
 count=model().input_log.size();await tap(next_key())
 check(model().input_log.size()==count+1,"actual movement after save changes live state")
 await tap(KEY_F9)
 check(app.mode=="world_puzzle" and app.story.current_token()==saved_token,"physical F9 returns exact token and world mode")
 check(Same.equivalent(before,snapshot()),"F9 restores actual model input history and position")
 check(app.world.player.position==Vector2(model().state.position[0],model().state.position[1]),"F9 projection and model position match")
 check(FileAccess.get_file_as_bytes(manual)==saved_bytes,"reading does not rewrite original saved bytes")
 # Walk to the first objective using parsed keys only; Enter executes offered verb.
 for i in range(100):
  if next_key()==KEY_E:break
  await tap(next_key())
 check(next_key()==KEY_E,"actual main key route reaches first weapon")
 var stage:int=model().state.stage;await tap(KEY_ENTER)
 check(int(model().state.stage)==stage+1,"parsed Enter performs current offered objective, not synthetic completion")
 check(app.story.current_event().id=="world_ch12_bamboo_disarm","first weapon does not skip remaining actions")
 for width in [640,1280]:
  root.size=Vector2i(width,360 if width==640 else 720);app.size=Vector2(root.size);app._layout();await frames()
  for child in app.actions.get_children():
   check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(child.get_global_rect()),"actual main control fits width "+str(width)+" "+child.get_class())
  check(app.speaker.text=="梁萧","layout change retains actual controller")
 # A fresh main node loads the real file via F9; this is not a new OS process.
 app.queue_free();await frames();root.size=Vector2i(640,360);await instantiate_main();await tap(KEY_F9)
 check(app.mode=="world_puzzle" and app.story.current_token()==saved_token,"fresh main instance receives F9 from menu")
 check(Same.equivalent(before,snapshot()),"fresh main restores same saved world history")
 check(app.speaker.text=="梁萧","fresh main restores controller label")
 check(FileAccess.get_file_as_bytes(source)==original,"source fixture bytes untouched")
 app.queue_free();await frames()
 print("Chapter twelve actual main inputs: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
