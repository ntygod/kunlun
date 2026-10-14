extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Saves=preload("res://scripts/save_store.gd")
const Flow=preload("res://tests/chapter_seven_campaign_driver.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
var app
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func open_panel() -> Control:
 app._show_registered_puzzle()
 await process_frame;await process_frame
 return app.registered_puzzle_panel
func start_demo(panel:Control):
 for n in range(3-int(panel._view.state.hint)):panel._buttons.hint.pressed.emit()
 panel._buttons.demo.pressed.emit()
 check(panel._demo_running,"explicit demo start")
func ticks(panel:Control,count:int):
 for n in range(count):
  if not panel._demo_running:break
  panel._timer.timeout.emit()
func same_snapshot(c:RefCounted,saved:Dictionary,label:String):check(Proof.equivalent(saved,c.current_chapter_runtime().make_puzzle().snapshot()),label)
func run():
 var base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_six_gui/manual_natural_final.json")))=="","actual chapter6 natural source")
 check(c.enter_registered_chapter(7),"actual chapter7 entry")
 for n in range(100):
  if c.current_event().get("id")=="formation_ch07_drill":break
  if not Flow.advance(c,false):check(false,"actual prefix "+c.current_token());quit(2);return
 check(c.current_event().get("id")=="formation_ch07_drill","real B04 and fold bow before drill")
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 app.story=c;app.saves=Saves.new("user://demo_main");app._load_scene();await process_frame
 root.size=Vector2i(1280,720);app._layout()
 var panel:Control=await open_panel()
 check(panel._board.size.x>=300,"normal window actually enlarges board")
 var scroll:ScrollContainer=app.modal_content.get_parent()
 check(scroll.get_global_rect().encloses(panel.get_global_rect()),"normal panel fits actual modal")
 start_demo(panel);ticks(panel,4)
 check(c.current_chapter_runtime().make_puzzle().state.assisted,"individual real assist inputs retain assisted history")
 var old_token:String=c.current_token();var old_epoch:int=app.registered_puzzle_epoch
 app._show_menu();await process_frame
 var paused:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
 app._registered_panel_input({"type":"assist_step_v1"},old_token,old_epoch)
 await create_timer(0.2).timeout
 same_snapshot(c,paused,"menu stops timers and rejects late input")
 panel=await open_panel()
 app._registered_panel_input({"type":"assist_step_v1"},old_token,old_epoch)
 same_snapshot(c,paused,"reopened same token rejects former panel epoch")
 check(not panel._demo_running,"reopening never restarts demonstration")
 start_demo(panel);ticks(panel,3)
 app._save()
 var saved:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
 old_epoch=app.registered_puzzle_epoch
 app._load("manual");await process_frame
 same_snapshot(c,saved,"F9 restores actual intermediate legal state")
 panel=await open_panel()
 check(not panel._demo_running,"F9 never autostarts demonstration")
 app._registered_panel_input({"type":"assist_step_v1"},old_token,old_epoch)
 same_snapshot(c,saved,"F9 rejects former panel signal")
 start_demo(panel);ticks(panel,2)
 app.modal.hide();await process_frame
 var hidden:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
 check(not panel._demo_running,"hidden modal stops demonstration")
 await create_timer(0.2).timeout
 same_snapshot(c,hidden,"hidden modal cannot keep advancing")
 app.modal.show();await process_frame
 check(not panel._demo_running,"showing modal doesn't resume demo")
 start_demo(panel);ticks(panel,600)
 check(not panel._demo_running,"demonstration stops at ready formation")
 var resolver:RefCounted=c.current_chapter_runtime().make_puzzle()
 check(resolver.state.wave==0 and resolver.state.wave_receipts.is_empty() and not resolver.state.complete,"demo cannot award wave or complete objective")
 check(resolver.next_demo_action().get("type")=="horn","ready formation awaits actual player horn")
 var ready:Dictionary=resolver.snapshot();await create_timer(0.2).timeout
 same_snapshot(c,ready,"no automatic horn after waiting")
 panel._buttons.horn.pressed.emit()
 check(c.current_chapter_runtime().make_puzzle().state.wave==1,"explicit horn alone advances wave")
 check(not panel._demo_running,"horn never starts next wave demonstration")
 root.size=Vector2i(640,360);app._layout();await process_frame;await process_frame
 panel._resize_board();await process_frame;await process_frame
 check(panel._board.size.x<=208 and panel._board.size.x>=198,"small-window board remains usable and compact")
 check(scroll.get_global_rect().encloses(panel.get_global_rect()),"small panel fits after hints and demonstration")
 start_demo(panel);ticks(panel,3)
 app._return_from_puzzle();await process_frame
 var closed:Dictionary=c.current_chapter_runtime().make_puzzle().snapshot()
 await create_timer(0.2).timeout
 same_snapshot(c,closed,"return to world stops demo at current legal step")
 check(app.mode=="explore","close really returns to exploration")
 var independent=Campaign.new(base)
 check(independent.restore_persisted(c.export_save())=="","all demonstrated commands independently replay")
 same_snapshot(independent,closed,"demonstrated history has exact legal proof state")
 app.queue_free();await process_frame;await process_frame
 print("Chapter seven demo main: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
