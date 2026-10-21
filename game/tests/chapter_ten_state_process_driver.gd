extends SceneTree
## GUI starting points generated solely by real headless commands from the unchanged natural9 archive.
## These fixtures are not natural playthrough or wallclock/visual acceptance evidence.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
const Battle=preload("res://tests/chapter_ten_encounter_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const SOURCE="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
var checks:=0
var failures:=0
var directory:String
var manifest:Dictionary={"provenance":"headless legal-command fixtures; not natural or graphical acceptance","source_sha256":"","revision":"","cases":[]}
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func capture(c:RefCounted,name:String)->void:
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","capture "+name+" "+str(saved.error))
 if saved.error!="":return
 var raw:String=JSON.stringify(saved.payload);var path:String=directory+"/command_"+name+".json"
 var file=FileAccess.open(path,FileAccess.WRITE);check(file!=null,"write "+path)
 if file==null:return
 file.store_string(raw);file.close()
 manifest.cases.append({"name":name,"filename":path.get_file(),"sha256":raw.sha256_text(),"bytes":raw.to_utf8_buffer().size(),"token":c.current_token(),"event":c.current_event().get("id",""),"finished":c.state.finished,"actors":c.actors.duplicate(true),"world":c.world_objects.duplicate(true),"objective_snapshot":c.state.objective_snapshot.duplicate(true),"puzzle_snapshot":c.state.puzzle_snapshot.duplicate(true)})
 print("CH10 CAPTURE ",name," ",path," ",raw.sha256_text())
func run()->void:
 directory=OS.get_environment("CH10_FIXTURE_DIR")
 if directory.is_empty():directory="/tmp/kunlun-ch10-gui-fixtures"
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 if OS.get_environment("CH10_STATE_MODE")=="read":
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"/manifest.json"))
  for sample in data.cases:
   var raw:String=FileAccess.get_file_as_string(directory+"/"+sample.filename)
   check(raw.sha256_text()==sample.sha256 and raw.to_utf8_buffer().size()==int(sample.bytes),"fixture hash "+sample.name)
   var c=Campaign.new(base);var error:String=c.restore_persisted(JSON.parse_string(raw))
   check(error=="","fresh process restore "+sample.name+" "+error)
   if error!="":continue
   check(c.current_token()==sample.token and c.state.finished==sample.finished,"exact location "+sample.name)
   check(Same.equivalent(c.actors,sample.actors) and Same.equivalent(c.world_objects,sample.world),"exact actors/world "+sample.name)
   check(Same.equivalent(c.state.objective_snapshot,sample.objective_snapshot) and Same.equivalent(c.state.puzzle_snapshot,sample.puzzle_snapshot),"exact partial inputs "+sample.name)
   for i in range(100):
    if c.state.finished:break
    if not Flow.advance(c,1):check(false,"resume "+sample.name+" "+c.current_token());break
   check(c.state.finished and c.state.xp==23865 and c.state.coins==3700,"finish exact reward ledger "+sample.name)
  print("Chapter ten state read: ",checks," checks, ",failures," failures");quit(1 if failures else 0);return
 check(DirAccess.make_dir_recursive_absolute(directory)==OK,"fixture directory")
 var raw:String=FileAccess.get_file_as_string(SOURCE);manifest.source_sha256=raw.sha256_text();manifest.revision=OS.get_environment("CH10_REVISION")
 check(manifest.source_sha256=="e70144a3feb471293a5ec3cd47988cbbd4cc5b9db5f7ec387aa2d4acd9f9b06d","original natural9 hash")
 var c=Campaign.new(base);check(c.restore_persisted(JSON.parse_string(raw))=="","source restore");check(c.enter_registered_chapter(10),"enter10")
 for i in range(100):
  if c.state.finished:break
  var id:String=c.current_event().id;var rt:RefCounted=c.current_chapter_runtime();var token:String=c.current_token()
  if id in ["world_ch10_farewell","world_ch10_shore_walk","pz_ch10_stone_array"]:
   var label:String={"world_ch10_farewell":"farewell","world_ch10_shore_walk":"shore","pz_ch10_stone_array":"stone"}[id]
   capture(c,label+"_entry")
   var model:RefCounted=rt.make_puzzle()
   for j in range(4096):
    if c.current_token()!=token:break
    var state:Dictionary=model.get_view().state
    if id=="world_ch10_farewell" and int(state.held_ms)>=750:break
    if id=="world_ch10_shore_walk" and int(state.active_ms)>=30000:break
    if id=="pz_ch10_stone_array" and state.awaiting_breath:break
    var result:Dictionary=rt.puzzle_input(token,model.next_demo_action());check(result.get("ok",result.get("accepted",false)),"partial "+label)
   var partial:Dictionary=model.get_view().state
   check(not partial.complete and c.current_token()==token,"partial remains live "+label)
   if id=="world_ch10_farewell":check(int(partial.held_ms)==750 and int(partial.stage)==0,"farewell actual unfinished750ms hold")
   if id=="world_ch10_shore_walk":check(int(partial.active_ms)==30000,"shore actual30seconds modeled walk")
   if id=="pz_ch10_stone_array":check(partial.awaiting_breath and int(partial.breaths)==0,"stone actual first pulse awaiting breath")
   capture(c,label+"_partial")
  if id=="enc_ch10_bayan_tide":
   capture(c,"b06_entry")
   var session:RefCounted=rt.make_objective_encounter()
   check(session.set_command("char_liang_xiao","self_guard","char_liang_xiao")=="","pending guard")
   check(rt.save_objective_checkpoint(session),"pending checkpoint");capture(c,"b06_pending")
   for j in range(3):
    if j>0:check(session.set_command("char_liang_xiao","self_guard","char_liang_xiao")=="","guard")
    check(session.resolve_round(),"round")
   check(session.get_view().objective.phase=="phase_two" and int(session.get_view().round)==4,"actual B06 phase2 round4")
   check(rt.save_objective_checkpoint(session),"phase2 checkpoint");capture(c,"b06_phase_two")
   check(Battle.run(session,true),"battle remainder")
   check(rt.accept_objective(token,session.receipt()),"battle accepted");continue
  if c.scene().id=="ch10_three_months" and int(c.state.step)==0:capture(c,"recollection_window")
  if not Flow.advance(c,1):check(false,"flow "+c.current_token());break
 check(c.state.finished,"fixture trajectory complete")
 if c.state.finished:capture(c,"terminal")
 check(FileAccess.get_file_as_string(SOURCE).sha256_text()==manifest.source_sha256,"original source unchanged")
 var file=FileAccess.open(directory+"/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest));file.close()
 print("Chapter ten state write: ",checks," checks, ",failures," failures; ",manifest.cases.size()," command fixtures")
 quit(1 if failures else 0)
