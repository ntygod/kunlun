extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Summary=preload("res://scripts/campaign/chapter_twelve_summary.gd")
var checks:=0
var failures:=0
var base:Dictionary
var source:Dictionary
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func until(c:RefCounted,id:String)->bool:
 for i in range(240):
  if c.current_event().get("id")==id:return true
  if c.state.finished or not Flow.advance(c,1,false):return false
 return false
func run()->void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var path:String=OS.get_environment("CH12_SOURCE")
 if path.is_empty():push_error("Set CH12_SOURCE to a verified command-generated chapter11 terminal; see chapter-twelve-campaign-contract.md");quit(1);return
 source=JSON.parse_string(FileAccess.get_file_as_string(path))
 for finish_late in [false,true]:
  var c=Campaign.new(base);check(c.restore_persisted(source)=="","legal command source11");var original_xp:int=c.state.xp;check(c.enter_registered_chapter(12),"enter12")
  check(until(c,"side_ch12_r05"),"first optional window")
  var rt:RefCounted=c.current_chapter_runtime();check(rt.open_sidequest("R05"),"open")
  check(until(c,"pz_ch12_r05_rescue"),"actual diagnosis choiceB")
  check(Flow.advance(c,1,false),"actual triage complete")
  check(c.state.choices.r05_method=="r05_method_b" and c.state.verified_puzzles.pz_ch12_r05_rescue,"B and clinical proof retained")
  check(rt.pause_sidequest(),"pause before medicine")
  var paused:Dictionary=c.prepare_persisted_save();check(paused.error=="","partial paused canonical "+str(paused.error))
  check(until(c,"confirm_ch12_enter_manor"),"deadline reached")
  if finish_late:
   check(rt.open_sidequest("R05"),"late resume after earlier pause")
   for i in range(10):
    if c.state.scope=="main":break
    if not Flow.advance(c,1,true):check(false,"late side progress");break
   check(c.state.optional.R05.status=="archived" and c.state.r05_archive_window!=c.state.r05_visit_window,"last legal window completed")
  else:check(rt.disposition("R05","declined"),"decline remainder intentionally")
  check(rt.close_window(c.current_token()),"explicit irreversible departure")
  check(not rt.open_sidequest("R05"),"closed optional cannot reopen")
  for i in range(240):
   if c.state.finished:break
   if not Flow.advance(c,1,false):check(false,"remainder "+c.current_token());break
  check(c.state.finished and c.state.xp==original_xp+7340+(400 if finish_late else 0),"late or missed reward exact")
  check(c.items.has("item_ch12_r05_oil_lamp")==finish_late,"unfinished has no skill/item")
  check(c.state.choices.r05_method=="r05_method_b","missed retains actual choice memory")
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","partial/late terminal canonical "+str(saved.error))
  var rebuild=Campaign.new(base);check(rebuild.restore_persisted(saved.payload)=="","terminal restores "+str(finish_late))
  check(Same.equivalent(c.actors,rebuild.actors) and Same.equivalent(c.items,rebuild.items),"actors and ownership roundtrip")
  var forged:Dictionary=Summary.pack(c);forged.r05_progress.puzzles=["world_ch12_r05_road_repair"]
  var rejecting=Campaign.new(base);rejecting.restore_persisted(source)
  check(Summary.apply(rejecting,forged)!="","medicine cannot precede triage in bounded outcome")
 print("Chapter twelve optional boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
