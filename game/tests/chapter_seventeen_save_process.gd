extends SceneTree
## Independent writer/reader processes; model inputs, never edited save flags.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var failures=0
var checks=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func store(c:RefCounted,label:String,directory:String)->void:
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","encode "+label)
 if saved.error!="":return
 var file:=FileAccess.open(directory+"/"+label+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify(saved.payload));file.close()
 var observation:Dictionary={"actors":c.actors.duplicate(true),"items":c.items.duplicate(true),"world":c.world_objects.duplicate(true),"token":c.current_token(),"finished":c.state.finished}
 if c.current_event().get("op")=="puzzle":observation.puzzle=c.current_chapter_runtime().make_puzzle().snapshot()
 elif c.current_event().get("op")=="objective_battle":observation.battle=c.current_chapter_runtime().make_objective_encounter().snapshot()
 file=FileAccess.open(directory+"/"+label+".expected.json",FileAccess.WRITE);file.store_string(JSON.stringify(observation));file.close()
func run()->void:
 var directory:=OS.get_environment("CH17_PROCESS_DIR");var mode:=OS.get_environment("CH17_PROCESS_MODE")
 if directory.is_empty() or mode not in ["write","read"]:push_error("independent process directory/mode required");quit(2);return
 DirAccess.make_dir_recursive_absolute(directory)
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c:=Campaign.new(base)
 if mode=="write":
  var source:=OS.get_environment("CH17_SOURCE")
  if source.is_empty() or not FileAccess.file_exists(source):push_error("CH17_SOURCE required");quit(2);return
  check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="" and c.enter_registered_chapter(17),"writer chapter entry")
  for i in range(100):
   if c.state.finished:break
   var event:Dictionary=c.current_event();var rt:RefCounted=c.current_chapter_runtime()
   if event.op=="puzzle":
    rt.puzzle_input(c.current_token(),Driver.puzzle_action(rt.make_puzzle()))
    store(c,event.puzzle_id,directory)
   elif event.op=="objective_battle":
    var session:RefCounted=rt.make_objective_encounter();var command:Dictionary=Driver.commands(session)[0]
    check(session.set_command(command.actor,command.skill,command.target)=="" and rt.save_objective_checkpoint(session),"writer pending battle")
    store(c,event.id+"_pending",directory)
    for cmd in Driver.commands(session):
     check(session.set_command(cmd.actor,cmd.skill,cmd.target)=="","writer all party intents")
    check(session.resolve_round() and rt.save_objective_checkpoint(session),"writer resolved round")
    store(c,event.id+"_round",directory)
   if not Driver.advance(c,1,true):check(false,"writer route advance");break
  check(c.state.finished,"writer real terminal");store(c,"terminal",directory)
 else:
  for label in ["pz_ch17_roof","pz_ch17_evidence","ch17_road_wolves_pending","ch17_road_wolves_round","ch17_wolf_double_pending","ch17_wolf_double_round","ch17_amo_pending","ch17_amo_round","terminal"]:
   var path:String=directory+"/"+label+".json"
   if not FileAccess.file_exists(path):check(false,"missing writer fixture "+label);continue
   var value:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"/"+label+".expected.json"))
   var error:String=c.restore_persisted(value);check(error=="","fresh-process restore "+label+": "+error)
   if error!="":continue
   check(Same.equivalent([c.actors,c.items,c.world_objects,c.current_token(),c.state.finished],[expected.actors,expected.items,expected.world,expected.token,expected.finished]),"persistent projection exact "+label)
   if expected.has("puzzle"):check(Same.equivalent(c.current_chapter_runtime().make_puzzle().snapshot(),expected.puzzle),"partial puzzle exact "+label)
   if expected.has("battle"):check(Same.equivalent(c.current_chapter_runtime().make_objective_encounter().snapshot(),expected.battle),"battle replay exact "+label)
   var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="" and Same.equivalent(saved.payload,value),"reload save unchanged "+label)
 print("Chapter seventeen process %s: %d checks, %d failures"%[mode,checks,failures]);quit(1 if failures else 0)
