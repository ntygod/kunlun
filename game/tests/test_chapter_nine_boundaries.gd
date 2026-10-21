extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const WorldFlow=preload("res://tests/chapter_nine_world_driver.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
var failures:=0
var checks:=0
var base:Dictionary
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func make() -> RefCounted:
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","real source")
 check(c.enter_registered_chapter(9),"enter9");return c
func until(c:RefCounted,id:String) -> void:
 for i in range(120):
  if c.current_event().get("id")==id:return
  if not Flow.advance(c,false):check(false,"advance boundary "+c.current_token());return
 check(false,"target not reached "+id)
func reject_save(c:RefCounted,payload:Dictionary,label:String) -> void:
 var before:Dictionary=c.export_save();var err:String=c.restore_persisted(payload)
 check(err!="",label);check(Proof.equivalent(before,c.export_save()),label+" atomic")
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=make();until(c,"pz_ch09_wood_bird_begin")
 check(not c.reward_ledger.has("reward_mq09_wood_bird_once"),"no bird reward on open")
 check(Flow.advance(c,false),"actual assembly")
 check(c.state.wood_bird_checkpoint.state.stage=="prepared","trusted prepared retained")
 check(not c.reward_ledger.has("reward_mq09_wood_bird_once"),"prepared has no500")
 var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","prepared persisted")
 var copy=Campaign.new(base);check(copy.restore_persisted(prepared.payload)=="","prepared independent reload")
 check(Proof.equivalent(copy.state.wood_bird_checkpoint,c.state.wood_bird_checkpoint),"prepared exact proof")
 until(c,"evt_ch09_wood_bird_resume")
 var flight:RefCounted=c.current_chapter_runtime().make_puzzle();check(flight.state.stage=="prepared","same bird resumed")
 var resources:Dictionary=c.actors.duplicate(true)
 for action in [{"type":"set_phase","stage":"drifted"},{"type":"sync","complete":true},{"type":"resume"},{"type":"grant_reward"},{"type":"rail","extra":true},{"type":"stand","actor":"char_axue","value":true}]:
  var before:Dictionary=c.export_save();var result:Dictionary=c.current_chapter_runtime().puzzle_input(c.current_token(),action)
  check(not result.ok,"fake flight rejected");check(Proof.equivalent(before,c.export_save()),"fake flight atomic")
 check(Flow.advance(c,false),"actual full flight")
 check(Proof.equivalent(resources,c.actors),"flight no resource rollback or refill")
 until(c,"side_ch09_l05")
 var rt:RefCounted=c.current_chapter_runtime();check(rt.open_sidequest("L05"),"accept L05")
 var session:RefCounted=rt.make_puzzle()
 for i in range(10):check(rt.puzzle_input(c.current_token(),WorldFlow.next_input(session,"A")).ok,"partial rescue input")
 check(not c.reward_ledger.has("reward_ch09_l05") and not c.items.has("item_ch09_physician_key"),"partial no reward/key")
 check(rt.pause_sidequest(),"pause partial L05")
 check(rt.open_sidequest("L05"),"return partial L05")
 check(rt.make_puzzle().snapshot()==session.snapshot(),"resume actual prefix")
 check(rt.pause_sidequest(),"pause again")
 var partial:Dictionary=c.prepare_persisted_save();check(partial.error=="","partial paused persisted")
 var bad:Dictionary=partial.payload.duplicate(true);bad.current.events.back().proof.position=[true,0]
 reject_save(c,bad,"boolean navigation rejected")
 until(c,"confirm_ch09_enter_command_tent")
 check(not rt.state.l05_closed and rt.state.optional.L05.status!="missed","blood well does not close L05")
 check(rt.open_sidequest("L05"),"return after blood well")
 check(rt.make_puzzle().snapshot()==session.snapshot(),"post-well same partial proof")
 check(rt.pause_sidequest(),"return to tent junction")
 check(rt.close_window(c.current_token()),"confirm tent")
 check(Flow.advance(c,false),"close event")
 check(rt.state.l05_closed and rt.state.optional.L05.status=="missed","deadline closed partial")
 check(not rt.open_sidequest("L05"),"cannot reopen after confirmation")
 for i in range(80):
  if c.state.finished:break
  check(Flow.advance(c,false),"finish after deadline")
 check(c.state.finished and not c.items.has("item_ch09_physician_key") and "MEM_L05" not in c.state.memories and not c.reward_ledger.has("reward_ch09_l05"),"closed side never mints results")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","closed partial final bounded")
 for mutate in ["mp","hp"]:
  bad=saved.payload.duplicate(true);bad.archive[9].boundary_vitals.char_liang_xiao[mutate]=c.actors.char_liang_xiao[mutate]+10000
  reject_save(c,bad,"forged final "+mutate)
 bad=saved.payload.duplicate(true);bad.archive[9].boundary_vitals.char_axue.hp=true
 reject_save(c,bad,"boolean vital")
 bad=saved.payload.duplicate(true);bad.archive[9].optional_dispositions.L05="completed"
 reject_save(c,bad,"fake side summary")
 bad=saved.payload.duplicate(true);bad.archive[9].semantic_commits.erase("evt_ch09_pine_harvest_authorized")
 reject_save(c,bad,"missing semantic material source")
 print("Chapter nine boundaries: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
