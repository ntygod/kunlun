extends SceneTree
## Two real optional visit windows; persistence must retain partial work without rewards.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func restore(base:Dictionary,payload:Dictionary,label:String)->RefCounted:
 var c=Campaign.new(base)
 var error:String=c.restore_persisted(payload)
 check(error=="",label+": "+error)
 return c if error=="" else null
func roundtrip(c:RefCounted,base:Dictionary,label:String)->RefCounted:
 var saved:Dictionary=c.prepare_persisted_save()
 if not check(saved.error=="","encode "+label+": "+str(saved.error)):return null
 var clone:RefCounted=restore(base,saved.payload,label)
 if clone!=null:check(Same.equivalent([c.actors,c.items,c.world_objects,c.state],[clone.actors,clone.items,clone.world_objects,clone.state]),"exact active projection "+label)
 return clone
func run()->void:
 var source:=OS.get_environment("CH17_SOURCE")
 if source=="" or not FileAccess.file_exists(source):push_error("CH17_SOURCE required");quit(2);return
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
 var first=Campaign.new(base)
 if not check(first.restore_persisted(original)=="" and first.enter_registered_chapter(17),"optional test entry"):quit(1);return
 for n in range(40):
  if first.current_token()=="ch17_roof_offer:01":break
  if not check(Driver.advance(first,1,false),"lead-in to optional"):quit(1);return
 var first_save:Dictionary=first.prepare_persisted_save()
 if not check(first_save.error=="","first window snapshot"):quit(1);return
 # (progress at first window, finish at last window, explicit refusal).
 for configuration in [[0,true,false],[3,true,false],[5,true,false],[5,false,false],[0,false,true]]:
  var c:RefCounted=restore(base,first_save.payload,"first window clone")
  if c==null:continue
  var progress:int=configuration[0];var finish:bool=configuration[1];var decline:bool=configuration[2]
  var rt:RefCounted=c.current_chapter_runtime()
  if progress>0:
   check(rt.open_sidequest("ch17_r07"),"first visit")
   for step in range(progress):check(Driver.advance(c,1,true),"partial roof step "+str(step))
   check(c.current_event().op==("puzzle" if progress==5 else "choice"),"expected partial event")
   if progress==5:
    check(rt.puzzle_input(c.current_token(),{"type":"hint"}).ok,"partial roof hint")
    check(rt.puzzle_input(c.current_token(),Driver.puzzle_action(rt.make_puzzle())).ok,"partial construction input")
   c=roundtrip(c,base,"partial roof visit")
   if c==null:continue
   rt=c.current_chapter_runtime()
   check(rt.pause_sidequest(),"pause optional without losing progress")
  elif decline:check(rt.disposition("ch17_r07","declined"),"explicit refusal")
  else:check(rt.disposition("ch17_r07","deferred"),"deferred first offer")
  check(rt.close_window(c.current_token()),"leave first visit window")
  for n in range(100):
   if c.current_token()=="ch17_last_roof:00":break
   if not check(Driver.advance(c,1,false),"main route to last window"):break
  if not check(c.current_token()=="ch17_last_roof:00","last window reached"):continue
  c=roundtrip(c,base,"return before last offer")
  if c==null:continue
  rt=c.current_chapter_runtime()
  if finish:
   check(rt.open_sidequest("ch17_r07"),"resume at last window")
   check(int(rt.state.side_step)==progress,"resume exact step")
   if progress==5:check(rt.make_puzzle().state.hint_level==1 and rt.make_puzzle().state.stage==1,"roof input and hint survived main battles")
   for n in range(12):
    if rt.state.scope=="main":break
    if not check(Driver.advance(c,1,true),"finish optional on second visit"):break
   check(rt.state.optional.ch17_r07.status=="archived","roof archived once")
   check(not rt.open_sidequest("ch17_r07"),"cannot repeat archived reward")
  for n in range(35):
   if c.state.finished:break
   if not check(Driver.advance(c,1,false),"departure route"):break
  check(c.state.finished,"route ended")
  check(c.actors.char_liang_xiao.xp==44375+(400 if finish else 0),"no rewards for partial/refused construction")
  var saved:Dictionary=c.prepare_persisted_save()
  if not check(saved.error=="","optional terminal encode "+str(configuration)+": "+str(saved.error)):continue
  var clone:RefCounted=restore(base,saved.payload,"optional terminal restore")
  if clone!=null:
   check(Same.equivalent([c.actors,c.items,c.world_objects],[clone.actors,clone.items,clone.world_objects]),"optional terminal resources unchanged")
   check(clone.state.optional.ch17_r07.disposition==("completed" if finish else ("declined" if decline else "missed")),"exact optional disposition")
 print("Chapter seventeen optional windows: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
