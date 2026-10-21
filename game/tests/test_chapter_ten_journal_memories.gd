extends SceneTree
## Actual main journal from legal command progress; no edits to input save or memory tags.
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
const LABELS:={"MEM_MQ10_AXUE_ETERNAL":"阿雪长忆","MEM_MQ10_QIANTANG_FAREWELL":"魂断钱塘，怒潮卷浪","MEM_MQ10_TIDE_SURVIVED":"死战待潮","MEM_MQ10_STONE_REBIRTH":"三月破器出新","MEM_MQ10_LAOSHAN_DEPARTURE":"携老北行"}
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func journal(app:Node,phase:String)->void:
 app._load_scene()
 var before:String=JSON.stringify(app.story.export_save())
 app._show_journal();var body:=""
 for child in app.modal_content.get_children():
  if child is Label and "相处记事" in child.text:body=child.text
 check(not body.is_empty(),phase+" actual campaign journal")
 var memories:String=body.split("相处记事\n")[1] if "相处记事\n" in body else ""
 for tag in LABELS:
  check((LABELS[tag] in memories)==(tag in app.story.state.memories),phase+" exact earned memory "+tag)
 for group in app.story.current_content().choice_groups:
  for option in app.story.current_content().choice_groups[group].options:
   check((option.label in memories)==(app.story.state.choices.get(group,"")==option.id),phase+" exact chosen option "+option.id)
 check(JSON.stringify(app.story.export_save())==before,phase+" journal is read only")
 if app.story.actors.char_axue.status=="dead":
  check(app.modal_content.get_node_or_null("axue_empty_seat")!=null,phase+" mourning seat retained")
  check("不能再出战" in body,phase+" absence retained")
  check(body.count("阿雪的旧针线包")==1,phase+" item listed once")
 app._cancel_choice()
func _initialize()->void:call_deferred("run")
func run()->void:
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 var source:=OS.get_environment("CH10_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
 var original:=FileAccess.get_file_as_string(source)
 check(app.story.restore_persisted(JSON.parse_string(original))=="","original9 restore")
 check(app.story.enter_registered_chapter(10),"enter10")
 journal(app,"entry")
 var branch:=1 if OS.get_environment("CH10_BRANCH_B")=="1" else 0
 for i in range(100):
  if app.story.current_event().id=="pz_ch10_stone_array":break
  if app.story.current_event().id=="world_ch10_rescue":await check_controlled(app)
  if not Flow.advance(app.story,branch):check(false,"stage command advance");quit(1);return
 check(app.story.current_event().id=="pz_ch10_stone_array","legal three stone stage")
 check("MEM_MQ10_QIANTANG_FAREWELL" in app.story.state.memories and "MEM_MQ10_AXUE_ETERNAL" in app.story.state.memories,"tags already persisted before display")
 journal(app,"stone stage")
 await check_arrows(app)
 for i in range(100):
  if app.story.state.finished:break
  if not Flow.advance(app.story,branch):check(false,"terminal command advance");quit(1);return
 check(app.story.state.finished,"legal terminal")
 journal(app,"terminal")
 check(FileAccess.get_file_as_string(source)==original,"original source bytes unchanged")
 app.queue_free();await process_frame
 print("Chapter ten journal memories: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

func check_arrows(app:Node)->void:
 await tap(KEY_J,KEY_J)
 check(app.mode=="journal","actual J opens journal")
 await tap(KEY_ESCAPE,KEY_ESCAPE)
 check(app.mode=="explore","actual Esc returns from J")
 print("After journal mode=",app.mode," enabled=",app.world.player.enabled," focus=",app.get_viewport().gui_get_focus_owner())
 for pair in [[KEY_RIGHT,KEY_RIGHT,"native right"],[KEY_RIGHT,0,"logical-only right"],[0,KEY_RIGHT,"physical-only right"],[KEY_RIGHT,KEY_LEFT,"logical right with unrelated physical left"],[KEY_D,KEY_D,"physical D"]]:
  var start:Vector2=app.world.player.position
  var event:=InputEventKey.new();event.keycode=pair[0];event.physical_keycode=pair[1];event.pressed=true;Input.parse_input_event(event)
  Input.flush_buffered_events()
  await process_frame
  var mapped:bool=Input.is_action_pressed("move_right")
  for i in range(6):await physics_frame
  event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame
  print(pair[2]," mapped=",mapped," position ",start," -> ",app.world.player.position)
  check(mapped and app.world.player.position.x>start.x,"post-journal "+pair[2]+" moves with actual input")
  var stopped:Vector2=app.world.player.position
  for i in range(3):await physics_frame
  check(app.world.player.position==stopped and not Input.is_action_pressed("move_right"),"keyup stops "+pair[2])
 var held:=InputEventKey.new();held.physical_keycode=KEY_RIGHT;held.pressed=true;Input.parse_input_event(held);Input.flush_buffered_events();await process_frame
 await tap(KEY_ESCAPE,KEY_ESCAPE);check(app.mode=="menu","Esc opens menu during physical-only movement")
 var stopped:Vector2=app.world.player.position
 for i in range(3):await physics_frame
 check(app.world.player.position==stopped and not Input.is_action_pressed("move_right"),"menu cancels normalized arrow")
 held.pressed=false;Input.parse_input_event(held);Input.flush_buffered_events();await process_frame
 await tap(KEY_ESCAPE,KEY_ESCAPE)
 stopped=app.world.player.position
 for i in range(3):await physics_frame
 check(app.mode=="explore" and app.world.player.position==stopped,"menu return no stale movement")
func tap(logical:int,physical:int)->void:
 var event:=InputEventKey.new();event.keycode=logical;event.physical_keycode=physical;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
 event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
func check_controlled(app:Node)->void:
 app._load_scene()
 var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
 var action:Dictionary=model.next_demo_action()
 check(action.type=="move","controlled fixture starts with move")
 var key:int=KEY_RIGHT if action.dx>0 else (KEY_LEFT if action.dx<0 else (KEY_DOWN if action.dy>0 else KEY_UP))
 var count:int=model.input_log.size();await tap(0,key)
 check(model.input_log.size()==count+1,"physical-only controlled arrow executes once")

