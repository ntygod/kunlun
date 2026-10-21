extends SceneTree
const R=preload("res://scripts/puzzles/chapter_fifteen_puzzle_resolver.gd")
const Tests=preload("res://tests/test_chapter_fifteen_puzzles.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var mode:=OS.get_environment("CH15_PUZZLE_MODE")
 for method in ["a","b"]:
  var file:String="user://ch15_puzzle_"+method+".json"
  var c:Dictionary=Tests.fixture(method)
  if mode=="writer":
   var r:=R.new();check(r.begin(R.IDS[0],"process",c),"writer entry")
   for i in range(7):check(r.apply_input(r.next_demo_action()).ok,"write real partial command")
   check(not r.state.complete,"partial remains incomplete")
   var f:=FileAccess.open(file,FileAccess.WRITE);check(f!=null,"partial disk open")
   if f!=null:f.store_string(JSON.stringify(r.snapshot()));f.close()
  elif mode=="reader":
   check(FileAccess.file_exists(file),"independent writer file exists")
   if not FileAccess.file_exists(file):continue
   var raw:=FileAccess.get_file_as_string(file);var snapshot:Dictionary=JSON.parse_string(raw)
   var r:=R.new();check(r.restore(snapshot,c),"independent JSON strict restore")
   check(r.snapshot()==R._normalize(snapshot),"partial exact state and input log")
   for i in range(60):
    if r.state.complete:break
    if not r.apply_input(r.next_demo_action()).ok:check(false,"remaining manual input");break
   check(r.state.complete and R.replay_receipt(r.receipt(),R.IDS[0],"process",c),"finish normally and receipt replay")
  else:check(false,"CH15_PUZZLE_MODE writer or reader required")
 print("R06 process ",mode,": ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
