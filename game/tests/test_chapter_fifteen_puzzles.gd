extends SceneTree
const R=preload("res://scripts/puzzles/chapter_fifteen_puzzle_resolver.gd")
const PuzzlePanel=preload("res://scripts/ui/chapter_fifteen_puzzle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
static func fixture(method:String="a")->Dictionary:
 return {"chapter":15,"scene_id":"side_ch15_r06","current_token":"side_ch15_r06:plan","r06_method":method,"actors":{"char_hua_xiaoshuang":{"hp":100},"char_huasheng":{"hp":100}}}
func reject(r:RefCounted,a:Dictionary)->void:
 var before:Dictionary=r.snapshot()
 check(not r.apply_input(a).ok and before==r.snapshot(),"invalid action atomic "+str(a))
func run()->void:
 for method in ["a","b"]:
  var r:=R.new();check(r.begin(R.IDS[0],"manual",fixture(method)),"entry "+method)
  var wrong:Dictionary=fixture(method);wrong.scene_id="ch15_graves"
  check(not R.new().begin(R.IDS[0],"bad",wrong),"wrong scene rejected")
  wrong=fixture(method);wrong.actors.char_huasheng.hp=0
  check(not R.new().begin(R.IDS[0],"bad",wrong),"unavailable helper rejected")
  reject(r,{"type":"finish"});reject(r,{"type":"assist_step_v1"});reject(r,{"type":"file_card","card":true,"family":1});reject(r,{"type":"reset_after_limit","hint":3,"assisted":0})
  for target in r.observations():r.apply_input({"type":"observe","target":target})
  reject(r,{"type":"teach","rule":"ask"})
  if method=="a":
   reject(r,{"type":"file_card","card":9,"family":0});reject(r,{"type":"store_jar","jar":0,"seal":"closed_marked"})
   for i in range(9):r.apply_input({"type":"file_card","card":i,"family":0})
   check(r.apply_input({"type":"check_atlas"}).ok and not r.state.method_ready and r.state.wrong_answers==1,"wrong atlas gives recoverable feedback")
  else:
   reject(r,{"type":"file_card","card":0,"family":0})
   check(r.apply_input({"type":"store_jar","jar":0,"seal":"open"}).ok and r.state.jars.is_empty(),"unsealed not counted")
   check(r.apply_input({"type":"put_tool","tool":"needle_case","place":"desk"}).ok and r.state.tools.is_empty(),"wrong storage not counted")
  var c:Dictionary=r.context.duplicate(true);var replayed:=true
  for i in range(60):
   if r.state.complete:break
   check(r.apply_input(r.next_demo_action()).ok,"manual legal step "+method)
   var clone:=R.new();replayed=replayed and clone.restore(JSON.parse_string(JSON.stringify(r.snapshot())),c)
  check(r.state.complete and replayed and c==r.context,"complete with every partial replay and untouched resources")
  check(R.replay_receipt(r.receipt(),R.IDS[0],"manual",c),"exact completion proof")
  check(r.receipt().validation_results.no_xp and r.receipt().manual_process_verified,"puzzle grants no resources and records manual")
  var forged:Dictionary=r.snapshot();forged.state.stage+=1
  check(not R.new().restore(forged,c),"tampered progress rejected")
  var cross:Dictionary=fixture("b" if method=="a" else "a")
  check(not R.new().restore(r.snapshot(),cross),"cannot replace chosen method on reload")
  reject(r,{"type":"finish"})
  var assisted:=R.new();assisted.begin(R.IDS[0],"help",c)
  for i in range(3):assisted.apply_input({"type":"hint"})
  assisted.apply_input({"type":"assist_step_v1"});assisted.apply_input({"type":"retry"})
  for i in range(60):
   if assisted.state.complete:break
   assisted.apply_input({"type":"assist_step_v1"})
  check(assisted.state.complete and assisted.receipt().assisted and not assisted.receipt().manual_process_verified,"retry retains assisted provenance")
  await ui(method)
 print("Chapter fifteen puzzles: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func click(b:Button)->void:
 var scroll:ScrollContainer=b.get_parent().get_parent() as ScrollContainer
 if scroll!=null:scroll.ensure_control_visible(b)
 await process_frame;await process_frame
 var at:Vector2=b.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func ui(method:String)->void:
 root.size=Vector2i(640,360)
 var r:=R.new();r.begin(R.IDS[0],"ui",fixture(method))
 var panel:=PuzzlePanel.new();root.add_child(panel);panel.position=Vector2(12,12);panel.size=Vector2(616,336)
 panel.input_submitted.connect(func(a):r.apply_input(a);panel.render(r.get_view()))
 panel.render(r.get_view());await process_frame;await process_frame
 check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(panel._scroll.get_global_rect()),"640 scroll fits "+method)
 check(panel._board.size.y>=160,"diagram labels fit available height")
 var first:Button=panel._buttons.values()[0];await click(first)
 check(r.state.observed.size()==1,"mouse observation")
 first.grab_focus()
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=KEY_ENTER;e.physical_keycode=KEY_ENTER;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(r.input_log.size()==2,"keyboard Return dispatch")
 for target in r.observations():r.apply_input({"type":"observe","target":target})
 panel.render(r.get_view())
 panel._scroll.scroll_vertical=100;await process_frame;var scroll:int=panel._scroll.scroll_vertical
 panel.render(r.get_view());await process_frame
 check(panel._scroll.scroll_vertical==scroll,"same render preserves scroll")
 for i in range(3):r.apply_input({"type":"hint"})
 panel.render(r.get_view());panel._toggle_demo();check(panel._demo_running,"explicit demo starts")
 panel.notification(NOTIFICATION_APPLICATION_FOCUS_OUT);var saved:Dictionary=r.snapshot();await create_timer(0.45).timeout
 check(not panel._demo_running and r.snapshot()==saved,"focus out stops demo")
 panel._toggle_demo();panel.hide();await create_timer(0.45).timeout
 check(not panel._demo_running and r.snapshot()==saved,"hidden/menu stops demo")
 panel.show();await process_frame
 for i in range(40):
  if r.state.complete:break
  var a:Dictionary=r.next_demo_action();var key:String=""
  match a.type:
   "file_card":panel._choices.card.select(a.card);panel._choices.family.select(a.family);key="file"
   "check_atlas","check_store":key="check"
   "store_jar":panel._choices.jar.select(a.jar);panel._choices.seal.select(2);key="store"
   "put_tool":panel._choices.tool.select(["record","model","needle_case"].find(a.tool));panel._choices.place.select(["shelf","desk","closed_case"].find(a.place));key="tool"
   "teach":panel._choices.rule.select(2);key="teach"
   "finish":key="finish"
  if key.is_empty():check(false,"UI command mapped");break
  var count:int=r.input_log.size();await click(panel._buttons[key]);check(r.input_log.size()==count+1,"mouse command "+a.type)
 check(r.state.complete,"640 full controls complete method "+method)
 panel.queue_free();await process_frame
