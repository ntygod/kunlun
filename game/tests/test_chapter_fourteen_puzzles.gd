extends SceneTree
const R=preload("res://scripts/puzzles/chapter_fourteen_puzzle_resolver.gd")
const PuzzlePanel=preload("res://scripts/ui/chapter_fourteen_puzzle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
static func fixture(id:String)->Dictionary:
 return {"chapter":14,"scene_id":R.SCENES[R.IDS.find(id)],"current_token":"test:"+id,"actors":{"char_liang_xiao":{"hp":100}}}
func reject(r:RefCounted,a:Dictionary)->void:
 var before:Dictionary=r.snapshot()
 check(not r.apply_input(a).ok and before==r.snapshot(),"invalid input atomic "+str(a))
func run()->void:
 for id in R.IDS:
  var r:=R.new();check(r.begin(id,"manual",fixture(id)),"entry")
  reject(r,{"type":"finish"});reject(r,{"type":"assist_step_v1"});reject(r,{"type":"aim","position":true,"beam":3})
  var replayed:=true;var steps:=0
  for i in range(30):
   if r.state.complete:break
   check(r.apply_input(r.next_demo_action()).ok,"legal input")
   steps+=1;replayed=replayed and R.new().restore(JSON.parse_string(JSON.stringify(r.snapshot())),r.context)
  check(r.state.complete and steps>=6,"full actual process")
  check(replayed,"every partial JSON replay")
  check(R.replay_receipt(r.receipt(),id,"manual",r.context),"exact terminal proof")
  var bad:Dictionary=r.snapshot();bad.state.stage+=1
  check(not R.new().restore(bad,r.context),"forged state rejected")
  bad=r.snapshot();bad.context_hash="invented"
  check(not R.new().restore(bad,r.context),"wrong context rejected")
  var assisted:=R.new();assisted.begin(id,"assist",fixture(id))
  for i in range(3):assisted.apply_input({"type":"hint"})
  assisted.apply_input({"type":"assist_step_v1"});assisted.apply_input({"type":"retry"})
  for i in range(30):
   if assisted.state.complete:break
   assisted.apply_input({"type":"assist_step_v1"})
  check(assisted.state.complete and assisted.receipt().assisted and not assisted.receipt().manual_process_verified,"assistance provenance survives retry")
 var calendar:=R.new();calendar.begin(R.IDS[0],"negative",fixture(R.IDS[0]))
 for target in calendar.observations():calendar.apply_input({"type":"observe","target":target})
 reject(calendar,{"type":"lock"});reject(calendar,{"type":"finalize"});reject(calendar,{"type":"aim","position":1462,"beam":-1})
 calendar.apply_input({"type":"aim","position":1462,"beam":3});calendar.apply_input({"type":"lock"})
 calendar.apply_input({"type":"station_group","group":0});reject(calendar,{"type":"station_group","group":0})
 reject(calendar,{"type":"year","days":365,"fraction":2425})
 var debate:=R.new();debate.begin(R.IDS[1],"debate",fixture(R.IDS[1]))
 for target in debate.observations():debate.apply_input({"type":"observe","target":target})
 check(debate.apply_input({"type":"answer","id":"force"}).ok and debate.state.debate_stage==0 and debate.receipt().is_empty(),"wrong argument gives hint without reward/progress")
 check(R.new().restore(debate.snapshot(),debate.context),"wrong argument replayable")
 for i in range(3):check(debate.apply_input(debate.next_demo_action()).ok,"can recover after wrong answer")
 check(debate.state.complete,"wrong answer never softlocks")
 await ui()
 print("Chapter fourteen puzzles: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func key(code:int)->void:
 for down in [true,false]:
  var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func click(control:Control)->void:
 var at:=control.get_global_rect().get_center()
 for down in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func ui()->void:
 root.size=Vector2i(640,360)
 for id in R.IDS:
  var r:=R.new();r.begin(id,"ui",fixture(id))
  var panel:=PuzzlePanel.new();root.add_child(panel);panel.position=Vector2(12,12);panel.size=Vector2(616,336)
  panel.input_submitted.connect(func(a):r.apply_input(a);panel.render(r.get_view()))
  panel.render(r.get_view());await process_frame;await process_frame
  var first:Button=panel._buttons.values()[0];await click(first)
  check(r.state.observed.size()==1,"mouse observation640")
  first.grab_focus();await key(KEY_ENTER)
  check(r.input_log.size()==2,"Return observation")
  check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(panel._scroll.get_global_rect()),"scroll viewport640 fits")
  panel._scroll.scroll_vertical=120;await process_frame;var scroll:int=panel._scroll.scroll_vertical
  panel.render(r.get_view());await process_frame;check(panel._scroll.scroll_vertical==scroll,"refresh retains scroll")
  if id==R.IDS[0]:
   for target in r.observations():r.apply_input({"type":"observe","target":target})
   panel.render(r.get_view());panel._scroll.ensure_control_visible(panel._sliders.position);await process_frame;await process_frame
   panel._sliders.position.grab_focus();await key(KEY_RIGHT)
   check(int(panel._sliders.position.value)==1401,"actual keyboard slider increments")
   panel._sliders.position.set_value(1462);panel._sliders.beam.set_value(3)
   panel._scroll.ensure_control_visible(panel._buttons.aim);await process_frame;await process_frame;await click(panel._buttons.aim)
   check(r.state.position==1462 and r.state.beam==3,"actual mouse commits prepared slider values")
  for i in range(3):r.apply_input({"type":"hint"})
  panel.render(r.get_view());panel._toggle_demo();check(panel._demo_running,"explicit demo starts")
  panel.notification(NOTIFICATION_APPLICATION_FOCUS_OUT);var saved:Dictionary=r.snapshot();await create_timer(0.45).timeout
  check(not panel._demo_running and saved==r.snapshot(),"focus loss stops timed demonstration")
  panel._toggle_demo();panel.hide();saved=r.snapshot();await create_timer(0.45).timeout
  check(not panel._demo_running and saved==r.snapshot(),"hidden/menu stops demonstration")
  panel.queue_free();await process_frame
