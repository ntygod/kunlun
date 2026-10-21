extends SceneTree
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(640,360)
 var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;await process_frame
 app.saves.directory="user://ten_battle_main_"+str(OS.get_process_id())
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_nine_gui/manual_natural_final.json")))=="","unchanged natural source")
 check(app.story.enter_registered_chapter(10),"chapter10")
 for i in range(100):
  if app.story.current_event().get("op")=="objective_battle":break
  if not Flow.advance(app.story):check(false,"actual chapter events to battle");quit(1);return
 check(app.story.current_event().id=="enc_ch10_bayan_tide","real B06 boundary")
 app._load_chapter_scene();app.encounter_session=app.story.current_chapter_runtime().make_objective_encounter();app.chapter_token=app.story.current_token();app._show_chapter_battle();await process_frame
 var old:Control=app.modal_content.get_child(0)
 var before:Dictionary=app.encounter_session.snapshot()
 app._show_chapter_battle();old.command_requested.emit("char_liang_xiao","self_guard","char_liang_xiao",before.state.revision);old.retry_requested.emit();old.resolve_requested.emit();old.continue_requested.emit()
 check(Same.equivalent(before,app.encounter_session.snapshot()),"removed panel signals are scoped")
 for round_number in range(1,7):
  var skill:String={1:"LX_A03",2:"observe",3:"sancai_counter",4:"ch10_borrow_tide",5:"LX_A03",6:"self_guard"}[round_number]
  var panel:Control=app.modal_content.get_child(0)
  check(panel.slots.has(skill) and not panel.slots[skill].disabled,"real legal control "+skill)
  panel.slots[skill].pressed.emit()
  check(app.encounter_session.get_view().commands.char_liang_xiao.skill_id==skill,"exact real skill signal")
  if round_number==4:
   check(app.encounter_session.get_view().skill_costs.char_liang_xiao.ch10_borrow_tide==0,"custom skill cost exists and zero")
   app._save();var selected:Dictionary=app.encounter_session.snapshot();var stale:Control=app.modal_content.get_child(0)
   app._load("manual")
   check(Same.equivalent(selected,app.encounter_session.snapshot()),"real F5/F9 API rebuild selected borrow command")
   stale.resolve_requested.emit();check(Same.equivalent(selected,app.encounter_session.snapshot()),"old loaded-session callback rejected")
  panel=app.modal_content.get_child(0);panel.slots.resolve.pressed.emit()
  check(app.encounter_session.get_view().objective.survived_rounds==round_number,"one signal resolves exactly one round")
  check(FileAccess.file_exists(app.saves.directory.path_join("auto.json")),"round autosave exists")
 var final_resources:Array=app.encounter_session.final_party()
 check(app.encounter_session.get_view().outcome=="victory","survival won through actual controls")
 var panel:Control=app.modal_content.get_child(0);panel.slots.continue.pressed.emit()
 check(app.story.actors.char_liang_xiao.hp==final_resources[0].hp and app.story.actors.char_liang_xiao.mp==final_resources[0].mp,"exact session final resources committed")
 check(app.story.current_event().get("id")!="enc_ch10_bayan_tide","continue leaves old token")
 check(not app.story.actors.char_liang_xiao.skill_ranks.has("LX_A04"),"no early A04")
 app.queue_free();await process_frame
 print("Chapter ten battle main: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
