extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_fifteen_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:=OS.get_environment("CH15_SOURCE");var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="" and c.enter_registered_chapter(15),"formal source enters15")
 for i in range(140):
  if c.current_event().get("op")=="quest_window":break
  if not Flow.advance(c,0,false):check(false,"prefix legal step");quit(1);return
 var rt:RefCounted=c.current_chapter_runtime()
 check(not c.current_event().get("deadline",false) and "仍可" in rt.optional_window_view().confirmation,"first window accurately deferrable")
 var checkpoint:Dictionary=c.export_save()
 for finish_later in [false,true]:
  var branch=Campaign.new(base);check(branch.restore_persisted(checkpoint)=="","window snapshot restore")
  var r:RefCounted=branch.current_chapter_runtime();check(r.open_sidequest("R06"),"open optional")
  for i in range(20):
   if branch.current_event().get("id")=="world_ch15_r06_clinic_repair":break
   if not Flow.advance(branch,1,true):check(false,"real side preparation");quit(1);return
  check(r.state.verified_puzzles.get("pz_ch15_r06_clinic_plan",false),"actual method B plan completed")
  check(r.pause_sidequest(),"pause after plan before repair")
  check(r.close_window(branch.current_token()),"early closure advances without closing optional")
  check(r.state.optional.R06.disposition=="deferred","partial remains resumable")
  for i in range(200):
   if branch.state.finished:break
   var event:Dictionary=branch.current_event()
   if event.op=="quest_window":
    check(event.get("deadline",false) and "关闭" in r.optional_window_view().confirmation,"final window explicit closure")
   if not Flow.advance(branch,1,finish_later):check(false,"late branch legal step "+str(event));break
  check(branch.state.finished,"finish late/abandoned branch")
  check(branch.state.optional.R06.disposition==("completed" if finish_later else "missed"),"disposition matches executed branch")
  check(branch.items.has("item_ch15_r06_child_herb_sheet")==finish_later,"no rewards for unfinished repair")
  var packed:Dictionary=branch.prepare_persisted_save();check(packed.error=="","partial optional bounded archive "+str(packed.error))
  if packed.error=="":
   var restored=Campaign.new(base);check(restored.restore_persisted(packed.payload)=="","late/abandoned strict restore")
   check(Same.equivalent(restored.prepare_persisted_save().payload,packed.payload),"optional terminal canonical exact")
 print("Chapter fifteen optional boundaries: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
