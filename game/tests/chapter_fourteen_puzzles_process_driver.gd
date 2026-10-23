extends SceneTree
const R=preload("res://scripts/puzzles/chapter_fourteen_puzzle_resolver.gd")
const Tests=preload("res://tests/test_chapter_fourteen_puzzles.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var mode:=OS.get_environment("CH14_PUZZLES_MODE")
 print("Chapter14 puzzle process PID ",OS.get_process_id()," ",mode)
 if mode=="writer":
  var entries:Array=[]
  for id in R.IDS:
   var r:=R.new();var context:Dictionary=Tests.fixture(id)
   check(r.begin(id,"process:"+id,context),"process begin")
   for i in range(4):check(r.apply_input(r.next_demo_action()).ok,"actual partial command")
   check(not r.state.complete,"saved genuine partial")
   entries.append({"context":context,"snapshot":r.snapshot()})
  var f:=FileAccess.open("user://ch14-puzzle-partials.json",FileAccess.WRITE);f.store_string(JSON.stringify(entries));f.close()
 elif mode=="reader":
  var hash_before:=FileAccess.get_sha256("user://ch14-puzzle-partials.json")
  var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("user://ch14-puzzle-partials.json"))
  for entry in entries:
   var r:=R.new();check(r.restore(entry.snapshot,entry.context),"fresh process restores partial")
   for i in range(120):
    if r.state.complete:break
    if not r.apply_input(r.next_demo_action()).ok:check(false,"remaining legal input");break
   check(r.state.complete and R.replay_receipt(r.proof(),r.puzzle_id,r.attempt_id,r.context),"fresh continued proof")
  check(FileAccess.get_sha256("user://ch14-puzzle-partials.json")==hash_before,"read leaves original partial bytes unchanged")
 else:check(false,"set CH14_PUZZLES_MODE writer/reader")
 print("Chapter14 puzzle process: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
