extends SceneTree
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const WU="npc_wu_changqing"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func tap(code:int)->void:
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func hidden(app:Node,label:String)->void:
 var context:Dictionary=app.story.world_context()
 check(WU in context.dead_actor_ids and WU not in context.present_actor_ids,label+" context excludes deceased Wu")
 var actor=app.world.cast_actors.get(WU)
 print("WU ",label," token=",app.story.current_token()," actor_exists=",actor!=null," visible=",actor.visible if actor!=null else false," position=",actor.position if actor!=null else Vector2.ZERO)
 check(actor==null or not actor.visible,label+" actual world actor hidden")
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 print("Wu projection PID ",OS.get_process_id()," mode ",OS.get_environment("CH11_WU_MODE"))
 if OS.get_environment("CH11_WU_MODE")=="reader":
  var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://wu-projection-expected.json"))
  await tap(KEY_F9)
  check(app.story.current_token()==expected.token,"fresh process restores exact plum token")
  check(app.story.world_objects.ch11_wu_changqing.status=="dead","fresh process restores original death transaction")
  check(FileAccess.get_sha256("user://saves/manual.json")==expected.sha,"fresh load does not rewrite saved bytes")
  hidden(app,"fresh process plum")
 else:
  var path:=OS.get_environment("CH11_SOURCE");var source_sha:=FileAccess.get_sha256(path)
  check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","formal10 source restore")
  check(app.story.enter_registered_chapter(11),"enter11")
  for i in range(180):
   if app.story.current_event().id=="evt_ch11_wu_changqing_died":break
   if not Flow.advance(app.story,0,false):check(false,"legal path through B07");quit(1);return
  check(app.story.current_event().id=="evt_ch11_wu_changqing_died","before death event reached legally")
  app._load_scene();await process_frame
  check(app.story.world_objects.get("ch11_wu_changqing",{}).get("status","")!="dead","death transaction not applied early")
  check(WU not in app.story.world_context().dead_actor_ids,"living Wu not prematurely excluded")
  check(app.world.cast_actors.has(WU) and app.world.cast_actors[WU].visible,"living Wu remains visible before final dialogue")
  check(Flow.advance(app.story,0,false),"complete actual death dialogue transaction")
  check(app.story.world_objects.ch11_wu_changqing.status=="dead","death transaction recorded")
  app._load_scene();await process_frame;hidden(app,"after death")
  for i in range(100):
   if app.story.current_event().id=="world_ch11_plum_practice":break
   if not Flow.advance(app.story,0,false):check(false,"legal Yaer to plum prefix");quit(1);return
  check(app.story.current_event().id=="world_ch11_plum_practice","real plum practice reached")
  app._load_scene();await process_frame;hidden(app,"plum entry")
  var session:RefCounted=app.story.current_chapter_runtime().make_puzzle()
  app._world_puzzle_input(session.next_demo_action());await process_frame
  hidden(app,"plum live projection after move")
  await tap(KEY_F5)
  check(FileAccess.file_exists("user://saves/manual.json"),"actual F5 persists legal partial plum")
  var meta:=FileAccess.open("user://wu-projection-expected.json",FileAccess.WRITE)
  meta.store_string(JSON.stringify({"token":app.story.current_token(),"sha":FileAccess.get_sha256("user://saves/manual.json")}));meta.close()
  check(Flow.advance(app.story,0,false),"legally finish plum")
  for i in range(4):
   app._load_scene();await process_frame;hidden(app,"later node "+str(i))
   if not Flow.advance(app.story,0,false):check(false,"later legal advance");break
  check(FileAccess.get_sha256(path)==source_sha,"original formal source bytes unchanged")
 print("Chapter eleven Wu projection: ",checks," checks, ",failures," failures")
 app.queue_free();await process_frame;quit(1 if failures else 0)
