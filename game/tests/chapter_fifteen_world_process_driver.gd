extends SceneTree
const R=preload("res://scripts/world_actions/chapter_fifteen_world_actions.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var mode:=OS.get_environment("CH15_WORLD_MODE")
 print("Chapter15 world process PID ",OS.get_process_id()," ",mode)
 var path:="user://chapter15-world-partials.json"
 if mode=="writer":
  var entries:Array=[];var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(R.MAP_PATH)).maps
  for mid in maps:
   for id in maps[mid].sessions:
    var cfg:Dictionary=maps[mid].sessions[id]
    var context:Dictionary={"chapter":15,"revision":1,"current_token":"process:"+id,"objective_id":id,"map_id":mid,"control_actor_id":cfg.control_actor_id,"scene_id":cfg.scene_id,"phase":cfg.scene_id,"world_objects":{}}
    var r=R.new();check(r.begin(id,"process:"+id,context),"begin")
    for i in range(100):
     if r.state.stage==1:break
     if not r.apply_input(r.next_demo_action()).ok:check(false,"legal prefix");break
    check(r.state.stage==1 and not r.state.complete,"genuine partial after first operation")
    entries.append({"context":context,"snapshot":r.snapshot()})
  var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(entries));f.close()
 elif mode=="reader":
  var hash_before:=FileAccess.get_sha256(path)
  var entries:Array=JSON.parse_string(FileAccess.get_file_as_string(path))
  for entry in entries:
   var r=R.new();check(r.restore(entry.snapshot,entry.context),"fresh process partial replay")
   for i in range(1000):
    if r.state.complete:break
    if not r.apply_input(r.next_demo_action()).ok:check(false,"legal continuation");break
   check(r.state.complete and not R.replay_receipt(r.receipt(),entry.context).is_empty(),"continued exact receipt")
  check(FileAccess.get_sha256(path)==hash_before,"original partial bytes unchanged")
 else:check(false,"set CH15_WORLD_MODE")
 print("Chapter15 world process: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
