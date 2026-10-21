extends SceneTree
const R=preload("res://scripts/puzzles/chapter_thirteen_puzzle_resolver.gd")
const PuzzlePanel=preload("res://scripts/ui/chapter_thirteen_puzzle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
static func fixture(id:String,method:String="a")->Dictionary:
 return {"chapter":13,"scene_id":R.SCENES[R.IDS.find(id)],"current_token":"test:"+id,"water_method":method,"actors":{"char_liang_xiao":{"hp":100},"char_liu_yingying":{"hp":100},"char_hua_xiaoshuang":{"hp":100},"char_huasheng":{"hp":100}}}
func reject(r:RefCounted,a:Dictionary)->void:
 var before:Dictionary=r.snapshot()
 check(not r.apply_input(a).ok and before==r.snapshot(),"invalid action atomic "+str(a))
func run()->void:
 for id in R.IDS:
  for method in ["a","b"] if id==R.IDS[0] else ["a"]:
   var r:=R.new();check(r.begin(id,"manual",fixture(id,method)),"entry "+id)
   reject(r,{"type":"finish"});reject(r,{"type":"assist_step_v1"});reject(r,{"type":"breath","length":true});reject(r,{"type":"reset_after_limit","hint":3,"assisted":0})
   var context:Dictionary=r.context.duplicate(true)
   var replayed:=true;var steps:=0
   for i in range(120):
    if r.state.complete:break
    var a:Dictionary=r.next_demo_action()
    if not r.apply_input(a).ok:check(false,"manual legal step "+str(a));break
    steps+=1
    var clone:=R.new();replayed=replayed and clone.restore(JSON.parse_string(JSON.stringify(r.snapshot())),context)
   check(r.state.complete and steps>5,"finite actual sequence "+id)
   check(replayed and context==r.context,"every partial JSON replay and immutable context")
   check(R.replay_receipt(r.receipt(),id,"manual",context),"exact completion receipt")
   var forged:Dictionary=r.snapshot();forged.state.stage+=1
   check(not R.new().restore(forged,context),"forged partial rejected")
   if id==R.IDS[0]:check(r.state.water==0 and r.state.served.size()==2 and r.state.night==3,"finite water and three nights")
   if id==R.IDS[1]:check(r.state.segment==13 and r.state.breaths.size()==39,"all thirteen three-part breaths")
   if id==R.IDS[2]:check(r.state.workdays==[1,2,3,4] and r.state.timber_fake+r.state.timber_real==10 and r.state.bulkheads==[0,1,2,3,4],"four days conserve materials and seal each hold")
   var assisted:=R.new();assisted.begin(id,"help",context)
   for i in range(3):assisted.apply_input({"type":"hint"})
   assisted.apply_input({"type":"assist_step_v1"});assisted.apply_input({"type":"retry"})
   for i in range(120):
    if assisted.state.complete:break
    if not assisted.apply_input({"type":"assist_step_v1"}).ok:break
   check(assisted.state.complete and assisted.receipt().assisted and not assisted.receipt().manual_process_verified,"assisted retry never becomes manual")
 var ship:=R.new();ship.begin(R.IDS[2],"badship",fixture(R.IDS[2]))
 for target in ship.observations():ship.apply_input({"type":"observe","target":target})
 reject(ship,{"type":"workday"});reject(ship,{"type":"bulkhead","slot":0});reject(ship,{"type":"pin"})
 var nav:=R.new();nav.begin(R.IDS[3],"nav",fixture(R.IDS[3]))
 for target in nav.observations():nav.apply_input({"type":"observe","target":target})
 reject(nav,{"type":"calibrate"});reject(nav,{"type":"sail"});reject(nav,{"type":"shadow","morning":-1,"evening":3})
 await ui()
 print("Chapter thirteen puzzles: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func ui()->void:
 root.size=Vector2i(640,360)
 for id in R.IDS:
  var r:=R.new();r.begin(id,"ui",fixture(id))
  var panel:=PuzzlePanel.new();root.add_child(panel);panel.position=Vector2(12,12);panel.size=Vector2(616,336)
  panel.input_submitted.connect(func(a):r.apply_input(a);panel.render(r.get_view()))
  panel.render(r.get_view());await process_frame;await process_frame
  var before:Dictionary=r.snapshot()
  var first:Button=panel._buttons.values()[0]
  var at:Vector2=first.get_global_rect().get_center()
  for pressed in [true,false]:
   var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
  check(r.state.observed.size()==1,"640 mouse observation "+id)
  first.grab_focus()
  for pressed in [true,false]:
   var e:=InputEventKey.new();e.keycode=KEY_ENTER;e.physical_keycode=KEY_ENTER;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
  check(r.input_log.size()==2,"keyboard Return dispatch "+id)
  check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(panel._scroll.get_global_rect()),"640 scroll viewport fits "+id)
  var scroll:int=panel._scroll.scroll_vertical;panel._scroll.scroll_vertical=100;await process_frame;scroll=panel._scroll.scroll_vertical
  panel.render(r.get_view());await process_frame;check(panel._scroll.scroll_vertical==scroll,"same refresh preserves scroll")
  for i in range(3):r.apply_input({"type":"hint"})
  panel.render(r.get_view());panel._toggle_demo();check(panel._demo_running,"explicit demo begins")
  panel.notification(NOTIFICATION_APPLICATION_FOCUS_OUT);var saved:Dictionary=r.snapshot();await create_timer(0.5).timeout
  check(not panel._demo_running and saved==r.snapshot(),"focus out stops demo without advancing")
  panel._toggle_demo();panel.hide();saved=r.snapshot();await create_timer(0.5).timeout
  check(not panel._demo_running and saved==r.snapshot(),"hidden/menu stops demo")
  panel.queue_free();await process_frame
