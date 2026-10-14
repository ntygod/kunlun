extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Saves=preload("res://scripts/save_store.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_seven_campaign_driver.gd")
var checks:=0
var failures:=0
var app
var base:Dictionary
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func f5(echo:bool=false) -> void:
 var event:=InputEventKey.new();event.keycode=KEY_F5;event.physical_keycode=KEY_F5;event.pressed=true;event.echo=echo
 Input.parse_input_event(event)
 event=InputEventKey.new();event.keycode=KEY_F5;event.physical_keycode=KEY_F5;event.pressed=false
 Input.parse_input_event(event)
func save_button() -> Button:
 for child in app.modal_content.get_children():
  if child is Button and child.text=="保存当前行旅":return child
 return null
func verify_menu(label:String) -> void:
 app.saves=Saves.new("user://menu_hotkey_"+label)
 app._show_menu(false);await process_frame
 check(app.mode=="menu" and app.menu_save_allowed,"actual menu save gate "+label)
 var button:Button=save_button();check(button!=null,"same visible save button "+label)
 if button==null:return
 button.grab_focus()
 var before_token:String=app.story.current_token()
 var before_ledger:Dictionary=app.story.reward_ledger.duplicate(true)
 f5(true);await process_frame
 check(not FileAccess.file_exists(app.saves.directory.path_join("manual.json")),"echo must not save "+label)
 f5();await process_frame
 var path:String=app.saves.directory.path_join("manual.json")
 check(FileAccess.file_exists(path),"focused menu F5 writes actual disk "+label)
 check(app.notice.text=="已保存到手动槽位","same success feedback "+label)
 check(app.menu_save_feedback.visible and app.menu_save_feedback.text==app.notice.text,"menu itself displays feedback "+label)
 if not FileAccess.file_exists(path):return
 var first:String=FileAccess.get_file_as_string(path)
 var restored=Campaign.new(base)
 check(app.saves.load_game(restored)=="","disk restores in independent campaign "+label)
 check(Proof.equivalent(app.story.export_save(),restored.export_save()),"readback equals current game "+label)
 f5();await process_frame
 check(first==FileAccess.get_file_as_string(path),"repeated key byte idempotent "+label)
 button.pressed.emit();await process_frame
 check(first==FileAccess.get_file_as_string(path),"button and hotkey byte equivalent "+label)
 check(app.story.current_token()==before_token,"save does not advance scene "+label)
 check(Proof.equivalent(before_ledger,app.story.reward_ledger),"save does not duplicate rewards "+label)
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 app.saves=Saves.new("user://menu_initial_block")
 app._show_menu(true);await process_frame
 check(not app.menu_save_allowed and save_button()==null,"initial menu shares missing save-button gate")
 f5();await process_frame
 check(not FileAccess.file_exists(app.saves.directory.path_join("manual.json")),"initial title cannot overwrite manual slot")
 check(app.notice.text=="开始行旅或读取存档后才能保存。","initial refusal explanation")
 app._cancel_choice();await verify_menu("prologue")
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_six_gui/manual_natural_final.json")))=="","real natural chapter6")
 app.story=c;app._load_scene();await process_frame
 await verify_menu("chapter_six_archived")
 check(c.enter_registered_chapter(7),"real chapter7 entry")
 for n in range(90):
  if c.current_event().get("id")=="enc_ch07_fire_ox_ambush":break
  if not Flow.advance(c,false):check(false,"prefix before battle");break
 app._load_scene();await process_frame
 check(app.mode=="chapter_battle","real battle mode")
 var result:Dictionary=app.encounter_session.apply_input({"actor_id":"char_liang_xiao","action_id":"move","value":"left","revision":app.encounter_session.engine.state.revision})
 check(result.accepted,"actual movement pending checkpoint")
 check(c.current_chapter_runtime().save_objective_checkpoint(app.encounter_session),"save exact pending battle")
 var snapshot:Dictionary=app.encounter_session.snapshot()
 await verify_menu("chapter_seven_battle")
 app._load("manual");await process_frame
 check(app.mode=="chapter_battle" and Proof.equivalent(snapshot,app.encounter_session.snapshot()),"menu saved battle resumes exact command log")
 app._show_menu(false);await process_frame
 var blocker:=FileAccess.open("user://menu_save_regular_file",FileAccess.WRITE);blocker.store_string("preserve");blocker.close()
 app.saves=Saves.new("user://menu_save_regular_file/child")
 var unchanged:Dictionary={"actors":app.story.actors.duplicate(true),"items":app.story.items.duplicate(true),"reward_ledger":app.story.reward_ledger.duplicate(true),"snapshot":app.encounter_session.snapshot()}
 f5();await process_frame
 check(app.notice.text=="无法创建存档目录" and app.menu_save_feedback.text==app.notice.text,"menu exposes failed write instead of success")
 check(FileAccess.get_file_as_string("user://menu_save_regular_file")=="preserve","failed save preserves blocking file")
 check(Proof.equivalent(unchanged,{"actors":app.story.actors,"items":app.story.items,"reward_ledger":app.story.reward_ledger,"snapshot":app.encounter_session.snapshot()}),"failed save preserves gameplay resources and exact battle")
 app.queue_free();await process_frame;await process_frame
 print("Menu save hotkey: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
