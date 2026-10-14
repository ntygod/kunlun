extends SceneTree
## Actual main input routing; capture only the dispatched command, not model state.
class Probe:
 extends "res://scripts/main.gd"
 var routed:Array=[]
 func _world_puzzle_input(action:Dictionary) -> void:routed.append(action.duplicate(true))
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func press(app,logical:int,physical:int,echo:bool=false) -> void:
 var event:=InputEventKey.new();event.keycode=logical;event.physical_keycode=physical;event.pressed=true;event.echo=echo
 Input.parse_input_event(event)
 event=InputEventKey.new();event.keycode=logical;event.physical_keycode=physical;event.pressed=false
 Input.parse_input_event(event)
func run() -> void:
 var app=Probe.new();root.add_child(app);await process_frame
 var error:String=app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json")))
 check(error=="","natural source restore")
 var admitted:bool=app.story.enter_registered_chapter(8);check(admitted,"real chapter8 admission")
 var arrows:Dictionary={KEY_LEFT:[-1,0],KEY_RIGHT:[1,0],KEY_UP:[0,-1],KEY_DOWN:[0,1]}
 var letters:Dictionary={KEY_A:[-1,0],KEY_D:[1,0],KEY_W:[0,-1],KEY_S:[0,1]}
 var button:=Button.new();app.actions.add_child(button)
 for focus in [false,true]:
  for mode in ["world_puzzle","menu","chapter_puzzle","chapter_battle"]:
   app.mode=mode
   for logical in arrows:
    for physical in [logical,4194310,0,KEY_A]:
     if focus:button.grab_focus()
     else:root.gui_release_focus()
     app.routed.clear();press(app,logical,physical);await process_frame
     var expected:Array=[{"type":"move","dx":arrows[logical][0],"dy":arrows[logical][1]}] if mode=="world_puzzle" else []
     check(app.routed==expected,"arrow logical route %s/%d/%d/focus%s"%[mode,logical,physical,focus])
   for physical in letters:
    for logical in [physical,KEY_Z]:
     app.routed.clear();press(app,logical,physical);await process_frame
     var expected:Array=[{"type":"move","dx":letters[physical][0],"dy":letters[physical][1]}] if mode=="world_puzzle" else []
     check(app.routed==expected,"physical WASD layout route %s/%d/%d"%[mode,logical,physical])
 app.mode="world_puzzle";app.routed.clear();press(app,KEY_DOWN,4194310,true);await process_frame
 check(app.routed.is_empty(),"echo ignored")
 var picker:=OptionButton.new();picker.add_item("one");picker.add_item("two");app.actions.add_child(picker);picker.show_popup();await process_frame
 app.routed.clear();press(app,KEY_DOWN,4194310);await process_frame
 check(app.routed.is_empty(),"open picker retains arrow navigation")
 picker.get_popup().hide();app.queue_free();await process_frame
 print("World arrow input: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
