extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eight_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const WD=preload("res://tests/chapter_eight_world_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json")))=="","natural source")
 check(c.enter_registered_chapter(8),"enter")
 for i in range(60):
  if c.current_event().get("id")=="ch08_passive_loadout":break
  check(Flow.advance(c,false),"to loadout")
 var rt:RefCounted=c.current_chapter_runtime()
 for bad in [["LX_P01","LX_P02","LX_P03"],["LX_P03","LX_P03"],["LX_P04"],[true],[null],[1]]:
  var before:Dictionary=c.export_save();check(not rt.set_passive_loadout(bad),"invalid slots");check(Same.equivalent(before,c.export_save()),"slot reject atomic")
 for i in range(128):check(rt.set_passive_loadout(["LX_P01","LX_P03"]),"bounded loadout edit")
 var before:Dictionary=c.export_save();check(not rt.set_passive_loadout([]),"edit129 denied");check(Same.equivalent(before,c.export_save()),"budget atomic")
 check(not rt.replay({"kind":"passive_loadout","token":"wrong","proof":{"ids":[]}}),"stale loadout replay")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","128 edits persisted "+str(saved.error))
 var copy=Campaign.new(base);check(copy.restore_persisted(saved.payload)=="","128 edits restore")
 check(Flow.advance(c,false),"confirm slots")
 for i in range(60):
  if c.current_event().get("id")=="ch08_alley_window":break
  check(Flow.advance(c,false),"to intermission")
 rt=c.current_chapter_runtime()
 if not rt.navigation_valid(rt.state.position,c.scene().map_id):rt.state.position=rt.maps[c.scene().map_id].spawn.duplicate()
 check(rt.open_sidequest("L04"),"open rescue")
 var model:RefCounted=rt.make_puzzle()
 for i in range(30):check(rt.puzzle_input(c.current_token(),WD.next_input(model,"body")).ok,"partial rescue command")
 var battle_before:Dictionary=rt.state.campaign_battle_snapshot.duplicate(true)
 var ledger_before:Dictionary=c.reward_ledger.duplicate(true)
 check(not rt.set_passive_loadout(["LX_P01","LX_P02"]),"intermission slots locked")
 check(Same.equivalent(battle_before,rt.state.campaign_battle_snapshot),"locked slots preserve paused session")
 rt._award("reward_mq08_ballista_objective",300)
 check(Same.equivalent(battle_before,rt.state.campaign_battle_snapshot) and Same.equivalent(ledger_before,c.reward_ledger),"duplicate reward no resources/history changes")
 check(rt.pause_sidequest(),"pause partial")
 check(rt.close_window(c.current_token()),"leave first window")
 check(c.current_event().id=="ch08_fire_confirmed","deadline reached")
 var pending:Dictionary=c.export_save()
 check(not rt.complete(c.current_token(),{"closure_acknowledged":false}),"cancel does not close")
 check(Same.equivalent(pending,c.export_save()),"cancel atomic")
 check(rt.close_window(c.current_token()),"confirm deadline")
 check(rt.state.optional.L04.status=="missed" and not c.reward_ledger.has("reward_ch08_l04") and not c.items.has("item_ch08_peace_charm"),"partial no reward")
 check(not rt.open_sidequest("L04"),"cannot reopen after deadline")
 for i in range(60):
  if c.state.finished:break
  check(Flow.advance(c,false),"finish missed side")
 check(c.state.xp==17365 and c.state.coins==2450,"partial route exact mandatory totals")
 saved=c.prepare_persisted_save();check(saved.error=="","partial closed final summary "+str(saved.error))
 print("CH08 BOUNDARIES ",checks," checks, ",failures," failures");quit(1 if failures else 0)
