extends SceneTree
## Actual application controls with model-generated fixtures. Not a natural OS playthrough.
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Saves=preload("res://scripts/save_store.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
var output=""
var captures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func frame(app)->void:
 app._layout();await process_frame;await process_frame
func capture(app,label:String,resolution:Vector2i)->void:
 await frame(app)
 for control in [app.modal,app.dialogue_panel]:
  if control.is_visible_in_tree():check(Rect2(Vector2.ZERO,Vector2(resolution)).grow(1).encloses(control.get_global_rect()),"window bounds "+label)
 if output.is_empty() or DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var name:="%dx%d_%s.png"%[resolution.x,resolution.y,label]
 check(root.get_texture().get_image().save_png(output+"/"+name)==OK,"native render "+name)
 captures.append({"file":name,"source":"model-built entry and actual application controls; not natural OS chapter QA"})
func key(code:int)->void:
 for pressed in [true,false]:
  var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
func run()->void:
 var source:=OS.get_environment("CH17_SOURCE")
 if source.is_empty() or not FileAccess.file_exists(source):push_error("CH17_SOURCE required");quit(2);return
 output=OS.get_environment("KUNLUN_CH17_CAPTURE")
 if output!="":DirAccess.make_dir_recursive_absolute(output)
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
 for resolution in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=resolution
  var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frame(app)
  app.ink_reduced_motion=true;app.saves=Saves.new("user://chapter17_main")
  check(app.story.restore_persisted(base)=="" and app.story.enter_registered_chapter(17),"actual app chapter17 entry")
  app._load_scene();await capture(app,"arrival",resolution)
  var used_e:=false
  for n in range(140):
   if app.story.state.finished:break
   var e:Dictionary=app.story.current_event();var token:String=app.story.current_token();var rt:RefCounted=app.story.current_chapter_runtime()
   if e.op in ["action","puzzle"]:
    app._load_scene();await frame(app)
    var point:Dictionary=app.world.get_objective_geometry(e.id)
    if not check(not point.is_empty(),"world action geometry "+e.id):break
    app.world.player.position=point.position
    check(app.world.nearest().get("action_id")==e.id,"world interaction reachable "+e.id)
    if e.id=="ch17_chief_order":
     check(app.world.player.actor_id==Driver.L,"Liu controls village decisions")
     await capture(app,"village_chief",resolution)
    if e.op=="puzzle" or not used_e:
     await key(KEY_E)
     if e.op=="action":used_e=true;check(app.story.current_token()!=token,"actual E advances action");continue
     if not check(app.mode=="chapter_puzzle","E opens puzzle"):break
   if e.op=="quest_window":
    app._load_scene();await frame(app)
    if rt.state.optional.ch17_r07.status!="archived":app._open_optional("ch17_r07");await frame(app);check(app.story.state.scope=="ch17_r07","optional UI entry");continue
   if e.op=="puzzle":
    var panel=app.registered_puzzle_panel;await frame(app)
    if not check(panel!=null,"chapter17 puzzle panel"):break
    var before:Dictionary=rt.state.duplicate(true)
    panel.render(rt.make_puzzle().get_view());check(Same.equivalent(before,rt.state),"puzzle render read-only")
    panel._buttons.hint.pressed.emit();check(rt.make_puzzle().state.hint_level==1,"hint button reaches resolver")
    panel._buttons.reset.pressed.emit();check(rt.make_puzzle().state.hint_level==1,"reset retains hint")
    if e.puzzle_id=="pz_ch17_evidence":
     panel._buttons.clue_howls.grab_focus();panel._buttons.clue_howls.pressed.emit();check("howls" in rt.make_puzzle().state.selected,"evidence control updates selection")
     check(panel._buttons.clue_howls.has_focus(),"retained control keeps focus")
    await capture(app,e.puzzle_id,resolution)
    await key(KEY_F5);var saved:Dictionary=app.story.prepare_persisted_save();check(saved.error=="","partial puzzle save")
    await key(KEY_F9);await frame(app);check(app.mode=="chapter_puzzle","normal F9-compatible load returns puzzle")
   if e.op=="objective_battle":
    app._load_scene();await frame(app)
    if not check(app.mode=="chapter_battle" and app.encounter_session!=null,"actual battle controller"):break
    var panel=app.modal_content.get_child(0)
    if not check(panel.get_script().resource_path.ends_with("chapter_seventeen_battle_panel.gd"),"registered compact battle panel"):break
    await capture(app,e.id,resolution)
    var commands:Array=Driver.commands(app.encounter_session)
    if commands.size()>0:
     var cmd:Dictionary=commands[0];var picker:OptionButton=panel.slots[cmd.actor+"_skills"]
     for i in range(picker.item_count):
      if picker.get_item_metadata(i)==cmd.skill:picker.select(i);picker.item_selected.emit(i);break
     var target:OptionButton=panel.slots[cmd.actor+"_target"]
     for i in range(target.item_count):
      if target.get_item_metadata(i)==cmd.target:target.select(i);break
     panel.slots[cmd.actor+"_confirm"].pressed.emit();check(app.encounter_session.get_view().commands.has(cmd.actor),"actual actor/skill/target controls submit")
     app._save();app._load("manual");await frame(app);check(app.encounter_session.get_view().commands.has(cmd.actor),"pending command survives ordinary read")
   if not check(Driver.advance(app.story,0,true),"route "+token):break
  check(app.story.state.finished,"UI-integrated route terminal")
  if app.story.state.finished:
   app._load_scene();await capture(app,"farewell",resolution)
   app._show_journal();await frame(app)
   check(app.ink_journal_view!=null,"late chapter four-page journal")
   if app.ink_journal_view!=null:
    for page in range(4):app.ink_journal_view.tabs.current_tab=page
    await capture(app,"journal",resolution)
  app.queue_free();await process_frame;await process_frame
 if output!="":
  var file:=FileAccess.open(output+"/capture-report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"checks":checks,"failures":failures,"scope":"native renders/injected input; not natural GUI"},"  "));file.close()
 print("Chapter seventeen main: %d checks, %d failures, %d native images"%[checks,failures,captures.size()]);quit(1 if failures else 0)
