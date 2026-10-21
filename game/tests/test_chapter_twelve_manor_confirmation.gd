extends SceneTree
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Store=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var source:=OS.get_environment("CH12_SOURCE")
 check(FileAccess.file_exists(source),"explicit legal source exists")
 if failures:quit(1);return
 var hash_before:=FileAccess.get_sha256(source)
 root.size=Vector2i(640,360)
 for finished in [true,false]:
  var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;await process_frame
  app.set_process(false);app.saves=Store.new("user://manor_confirmation")
  check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","restore actual11 source")
  check(app.story.enter_registered_chapter(12),"enter12")
  for i in range(80):
   if app.story.current_token()=="ch12_road_relief:01" and (not finished or app.story.state.optional.R05.status=="archived"):break
   check(Flow.advance(app.story,0,finished),"legal prefix")
   if failures:quit(1);return
  var rt:RefCounted=app.story.current_chapter_runtime()
  check(not rt.optional_window_view().already_acknowledged,"first window must always confirm")
  app._load_scene();await process_frame
  check(app.mode=="chapter_window","first window actually shown")
  check(rt.close_window(app.story.current_token()),"player acknowledges first window")
  check(Flow.advance(app.story,0,false),"bridging dialogue advances normally")
  check(app.story.current_event().id=="confirm_ch12_enter_manor","second model event retained")
  check(rt.optional_window_view().already_acknowledged==finished,"only completed early quest uses prior consent")
  var before:Dictionary=app.story.prepare_persisted_save()
  check(before.error=="","predeadline save remains valid")
  check(app.story.restore_persisted(before.payload)=="","predeadline load replay")
  var rewards:Dictionary=app.story.reward_ledger.duplicate(true)
  var items:Dictionary=app.story.items.duplicate(true)
  app._load_scene();await process_frame;await process_frame
  check((app.story.current_event().id=="evt_ch12_manor_pressure" and app.mode=="chapter_dialogue") if finished else (app.story.current_event().id=="confirm_ch12_enter_manor" and app.mode=="chapter_window"),"actualmain skips redundant popup, retains unfinished warning")
  check(Same.equivalent(rewards,app.story.reward_ledger) and Same.equivalent(items,app.story.items),"no duplicate reward or item")
  if finished:
   check(app.story.state.r05_closed,"deadline transaction still applied")
   var after:Dictionary=app.story.prepare_persisted_save();check(after.error=="","postclosure save")
   check(app.story.restore_persisted(after.payload)=="","postclosure replay")
   app._load_scene();await process_frame
   check(app.story.current_event().id=="evt_ch12_manor_pressure","reload never reopens confirmation")
  app.queue_free();await process_frame;await process_frame
 check(FileAccess.get_sha256(source)==hash_before,"source untouched")
 print("Chapter12 manor confirmation: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
