extends SceneTree
## Run writer then reader in separate Godot processes with the SAME isolated XDG_DATA_HOME.
## Input-driven navigation and real SaveStore files; no saved-state mutation.
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func key(code:int)->InputEventKey:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;return e
func same(a:Vector2,b:Array)->bool:return a==Vector2(float(b[0]),float(b[1]))
func _initialize()->void:call_deferred("run")
func run()->void:
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 var reader:=OS.get_environment("CH10_NAV_MODE")=="reader"
 print("Navigation process ","reader" if reader else "writer"," PID ",OS.get_process_id())
 if not reader:
  var source:=OS.get_environment("CH10_SOURCE")
  if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
  check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","natural9 restore")
  check(app.story.enter_registered_chapter(10),"enter10")
  for i in range(100):
   if app.story.current_event().id=="world_ch10_rescue":break
   if not Flow.advance(app.story):check(false,"fixture before rescue");quit(1);return
  app._load_scene()
  var model:RefCounted=app.story.current_chapter_runtime().make_puzzle()
  app._world_puzzle_input(model.next_demo_action())
  var controlled:Array=model.get_view().world_state.player_position
  check(same(app.world.player.position,controlled),"live controlled partial remains authoritative")
  app.world.set_runtime_context(app.story.world_context())
  check(same(app.world.player.position,controlled),"live controlled context refresh retains current partial")
  for i in range(100):
   if app.story.current_event().id=="pz_ch10_wooden_ox":break
   if not Flow.advance(app.story):check(false,"fixture before woodox");quit(1);return
  app._load_scene();check(app.mode=="explore","woodox starts in exploration")
  # Real physics navigation yields fractional coordinates without editing player/save position.
  Input.action_press("move_up")
  for i in range(29):await physics_frame
  Input.action_release("move_up");Input.action_press("move_right")
  for i in range(59):await physics_frame
  Input.action_release("move_right");await physics_frame
  var expected:Array=[app.world.player.position.x,app.world.player.position.y]
  check(app.world.player.is_walkable(app.world.player.position),"navigated point walkable")
  check(expected!=[144,224] and expected[0]!=round(expected[0]),"navigation produces distinct fractional position")
  app._chapter_interact();check(app.mode=="chapter_puzzle","physical location enters woodox")
  app._registered_puzzle_input({"type":"axle","length":3})
  app._registered_puzzle_input({"type":"phase","side":"right","value":2})
  app._input(key(KEY_F5))
  var meta:=FileAccess.open("user://navigation-expected.json",FileAccess.WRITE);meta.store_string(JSON.stringify(expected));meta.close()
  print("Writer saved navigation ",expected)
  app._show_menu();app._cancel_choice()
  check(same(app.world.player.position,expected),"menu return preserves navigation")
  app.world.set_runtime_context(app.story.world_context())
  check(same(app.world.player.position,expected),"ordinary explore context refresh preserves navigation")
 else:
  var expected:Array=JSON.parse_string(FileAccess.get_file_as_string("user://navigation-expected.json"))
  app._input(key(KEY_F9))
  check(app.story.current_event().id=="pz_ch10_wooden_ox","fresh process F9 restores woodox")
  print("Reader expected ",expected," got ",app.world.player.position)
  check(same(app.world.player.position,expected),"fresh process F9 exact fractional navigation")
  var state:Dictionary=app.story.current_chapter_runtime().make_puzzle().get_view().state
  check(state.axle==3 and state.right_phase==2,"partial axle and rightphase preserved")
  app._chapter_interact();check(app.mode=="chapter_puzzle","restored navigation can reenter puzzle")
  app._input(key(KEY_F5))
  if app.mode=="explore":app._unhandled_input(key(KEY_F5))
  var fresh:RefCounted=app.Story.new(app.content)
  check(app.saves.load_game(fresh,"manual")=="","second F5 file valid")
  check(same(Vector2(fresh.state.position[0],fresh.state.position[1]),expected),"second F5 retains exact fractional navigation")
 app.queue_free();await process_frame
 print("Navigation process: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
