extends SceneTree
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func hidden(app:Node,label:String)->void:
 for i in range(1,6):
  var id:="npc_ch10_friend_"+str(i)
  check(app.world.cast_actors.has(id) and not app.world.cast_actors[id].visible,label+" "+id)
func key(code:int)->InputEventKey:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;return e
func _initialize()->void:call_deferred("run")
func run()->void:
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 if OS.get_environment("CH10_FRIENDS_MODE")=="reader":
  app._input(key(KEY_F9))
  check(app.story.active_chapter==10 and app.story.current_event().id=="world_ch10_decoy","fresh process resumes decoy")
  hidden(app,"fresh F9 hidden")
 else:
  check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_nine_gui/manual_natural_final.json")))=="","original9 source")
  check(app.story.enter_registered_chapter(10),"enter10")
  for n in range(100):
   if app.story.current_event().id=="world_ch10_friends":break
   if not Flow.advance(app.story):check(false,"advance to friends");quit(1);return
  app._load_scene()
  for i in range(1,6):check(app.world.cast_actors["npc_ch10_friend_"+str(i)].visible,"not-yet-hidden friend present")
  check(Flow.advance(app.story),"actually conceal allfive")
  app._advance_chapter();hidden(app,"completed hiding receipt")
  for n in range(20):
   if app.story.scene().id=="ch10_draw_pursuit":break
   if not Flow.advance(app.story):check(false,"advance hiding dialogue");quit(1);return
  app._load_scene();hidden(app,"nextscene beginning")
  for n in range(20):
   if app.story.current_event().id=="world_ch10_decoy":break
   if not Flow.advance(app.story):check(false,"advance bandage and sendwest");quit(1);return
  app._load_scene()
  check(app.story.world_objects.ch10_five_friends.state=="hidden_alive","canonical concealed alive")
  hidden(app,"active decoy entry")
  app._world_puzzle_input({"type":"move","dx":1,"dy":0})
  hidden(app,"active decoy partial")
  app._show_menu();app._cancel_choice();hidden(app,"menu return")
  app._input(key(KEY_F5))
  check(app.saves.load_game(app.story,"manual")=="","strict save replay remains valid")
  app._load_scene();hidden(app,"sameprocess restore")
 app.queue_free();await process_frame
 print("Chapter ten hidden friends: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
