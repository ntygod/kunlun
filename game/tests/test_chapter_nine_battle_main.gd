extends SceneTree
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await process_frame;await process_frame
 main.saves.directory="user://nine_battle_main_"+str(OS.get_process_id())
 check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","source")
 check(main.story.enter_registered_chapter(9),"chapter9")
 for i in range(130):
  if main.story.current_event().get("id")=="enc_ch09_well_disarm":break
  check(Flow.advance(main.story,false),"advance")
 main._load_chapter_scene();main.encounter_session=main.story.current_chapter_runtime().make_objective_encounter();main.chapter_token=main.story.current_token();main._show_chapter_battle();await process_frame
 var old:Control=main.modal_content.get_child(0)
 var start:Dictionary=main.encounter_session.snapshot()
 main._show_chapter_battle()
 old.input_submitted.emit({"actor_id":"char_liang_xiao","action_id":"wait","value":"well_soldier_1","execute":true})
 old.retry_requested.emit();old.resolve_requested.emit();old.continue_requested.emit()
 check(Canonical.equivalent(start,main.encounter_session.snapshot()),"removed old signals rejected")
 for i in range(4):
  var panel:Control=main.modal_content.get_child(0)
  panel.slots["observe" if i%2==0 else "disarm"].pressed.emit()
  check(main.encounter_session.get_view().round==i+2,"one actual click one beat")
  check(FileAccess.file_exists(main.saves.directory.path_join("auto.json")),"real beat auto save")
 check(main.encounter_session.get_view().outcome=="victory","four clicks nonlethal victory")
 var resources:Dictionary=main.story.actors.duplicate(true)
 var panel:Control=main.modal_content.get_child(0);panel.slots.continue.pressed.emit()
 check(main.story.current_event().get("id")=="evt_ch09_well_disarm_complete","real continue route")
 check(not main.story.reward_ledger.has("reward_mq09_well_encounter_once"),"before settled receipt no300")
 check(Flow.advance(main.story,false),"receipt settled")
 check(main.story.reward_ledger.get("reward_mq09_well_encounter_once")==300,"unique300")
 main.queue_free();await process_frame
 print("Chapter nine battle main: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
