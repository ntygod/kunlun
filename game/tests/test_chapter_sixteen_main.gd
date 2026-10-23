extends SceneTree
## Native application/controller integration driven through controls and model-built
## fixtures. Screenshots are native renders, not an OS-input natural playthrough.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_sixteen_driver.gd")
const Saves=preload("res://scripts/save_store.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
var captures:Array=[]
var output=""
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func mouse_click(button:Control)->void:
 var position:Vector2=button.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=position;e.global_position=position;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed
  Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func frame(app)->void:
 app._layout();await process_frame;await process_frame
func capture(app,label:String,resolution:Vector2i)->void:
 await frame(app)
 if output.is_empty() or DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var filename:="%dx%d_%s.png"%[resolution.x,resolution.y,label]
 check(root.get_texture().get_image().save_png(output+"/"+filename)==OK,"native screenshot "+filename)
 for control in [app.modal,app.dialogue_panel]:
  if control.is_visible_in_tree():check(Rect2(Vector2.ZERO,Vector2(resolution)).grow(1).encloses(control.get_global_rect()),"native panel fits "+filename)
 captures.append({"file":filename,"source":"normal command-generated chapter15 entry + actual main/controller controls; not natural GUI"})
func run()->void:
 var source_path:=OS.get_environment("CH16_SOURCE")
 if source_path.is_empty() or not FileAccess.file_exists(source_path):push_error("CH16_SOURCE required");quit(2);return
 output=OS.get_environment("KUNLUN_CH16_CAPTURE")
 if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
 var puzzle_ids:Array=[]
 for resolution in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=resolution
  var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frame(app)
  app.ink_reduced_motion=true;app.saves=Saves.new("user://ch16_main_"+str(resolution.x))
  check(app.story.restore_persisted(source)=="","prior terminal restores into actual app")
  check(app.story.enter_registered_chapter(16),"actual app enters registered16")
  app._load_scene();await frame(app)
  check(app.viewport.size==Vector2i(320,180),"world remains independent pixel canvas")
  await capture(app,"entry",resolution)
  var real_world_action_count:=0
  for step in range(100):
   if app.story.state.finished:break
   var e:Dictionary=app.story.current_event();var rt:RefCounted=app.story.current_chapter_runtime()
   if e.op in ["action","puzzle"]:
    app._load_scene();await frame(app)
    var geometry:Dictionary=app.world.get_objective_geometry(e.id)
    check(not geometry.is_empty(),"real world objective geometry "+e.id)
    if geometry.is_empty():break
    # Place the fixture at a legal interaction point; the actual E event and
    # controller still must validate distance, active objective and transaction.
    app.world.player.position=geometry.position
    check(app.world.nearest().get("action_id")==e.id,"authored objective is actually reachable "+e.id)
    if e.op=="puzzle" or real_world_action_count==0:
     var interaction_token:String=app.story.current_token()
     for pressed in [true,false]:
      var key:=InputEventKey.new();key.keycode=KEY_E;key.physical_keycode=KEY_E;key.pressed=pressed;Input.parse_input_event(key);Input.flush_buffered_events();await process_frame
     if e.op=="action":
      real_world_action_count+=1
      check(app.story.current_token()!=interaction_token,"representative E action advances "+e.id)
      if app.story.current_token()==interaction_token:break
      continue
     check(app.mode=="chapter_puzzle","actual E enters puzzle "+e.id)
   if e.op=="puzzle":
    await frame(app)
    var panel=app.registered_puzzle_panel
    check(panel!=null and app.mode=="chapter_puzzle","registered puzzle panel opens "+e.id)
    check(Rect2(Vector2.ZERO,Vector2(resolution)).grow(1).encloses(panel.get_global_rect()),"puzzle fits "+str(resolution))
    for id in ["hint","reset"]:
     check(panel._buttons[id].size.x>=90 and panel._buttons[id].size.y<=50,"footer is readable, not narrow wrapped strips")
    var before:Dictionary=app.story.export_save()
    panel._board.render(rt.make_puzzle().get_view())
    check(Same.equivalent(before,app.story.export_save()),"drawing board is read-only")
    # Use a real input event for the first visible button rather than direct method.
    if e.puzzle_id=="pz_ch16_river":
     await mouse_click(panel._buttons.survey)
     check(rt.make_puzzle().state.surveyed,"mouse on survey reaches model")
     panel._numbers.gate_0.get_line_edit().grab_focus();panel._numbers.gate_0.get_line_edit().text="4"
     panel._buttons.dig.pressed.emit()
     check(rt.make_puzzle().state.gates[0]==4,"native text without Enter committed before action")
     check(not rt.make_puzzle().state.overflow,"unready dig does not manufacture completion")
     check(panel._numbers.gate_0.get_line_edit().has_focus(),"panel redraw does not destroy number focus")
     var old_revision:int=rt.make_puzzle().state.revision
     rt.puzzle_input(app.story.current_token(),{"type":"hint"})
     check(rt.puzzle_input(app.story.current_token(),{"type":"reset"}).ok,"runtime reset creates new attempt")
     check(rt.make_puzzle().state.revision>old_revision and rt.make_puzzle().state.hint_level==1,"reset keeps hint and changes revision epoch")
     check(not rt.puzzle_input(app.story.current_token(),{"type":"survey","revision":old_revision}).ok,"pre-reset delayed action is stale")
     panel.render(rt.make_puzzle().get_view())
    else:
     var key:String="talk" if e.puzzle_id=="pz_ch16_scale" else "read"
     panel._buttons[key].pressed.emit()
     check(rt.make_puzzle().state.understood if e.puzzle_id=="pz_ch16_scale" else rt.make_puzzle().state.page_read,"puzzle control reaches model")
    await capture(app,e.puzzle_id,resolution)
    app._save()
    var persisted:Dictionary=app.story.prepare_persisted_save()
    check(persisted.error=="","UI partial save encodes")
    var clone:=Campaign.new(app.content)
    var restored:String=clone.restore_persisted(persisted.payload)
    check(restored=="","UI partial strict restore "+restored)
    if restored=="":check(Same.equivalent(clone.current_chapter_runtime().make_puzzle().snapshot(),rt.make_puzzle().snapshot()),"UI partial identical after restore")
    # A removed panel must not change the fresh event after a re-entry.
    app._show_registered_puzzle();await frame(app)
    var untouched:Dictionary=app.story.export_save()
    if is_instance_valid(panel):panel.input_submitted.emit({"type":"hint"})
    check(Same.equivalent(untouched,app.story.export_save()),"old panel signal ignored")
    puzzle_ids.append(e.puzzle_id)
   if e.op=="objective_battle":
    app._load_scene();await frame(app)
    check(app.mode=="chapter_battle" and app.encounter_session!=null,"chapter16 uses actual battle controller")
    await capture(app,"night_raid",resolution)
    var cmd:Dictionary=Driver.command(app.encounter_session)
    app._chapter_command(cmd.actor,cmd.skill,cmd.target,int(app.encounter_session.get_view().revision))
    check(not app.encounter_session.get_view().commands.is_empty(),"real controller command queues")
    app._save();app._load("manual");await frame(app)
    check(app.mode=="chapter_battle" and not app.encounter_session.get_view().commands.is_empty(),"normal manual load restores pending battle")
   check(Driver.advance(app.story,1),"main route advances "+e.id)
  check(app.story.state.finished,"actual app state reaches chapter16 ending")
  app._load_scene();await capture(app,"ending",resolution)
  app._show_journal();await frame(app)
  check(is_instance_valid(app.ink_journal_view),"late chapter empty-seat card keeps four-page folio")
  if not is_instance_valid(app.ink_journal_view):app.queue_free();await process_frame;continue
  for page in range(4):
   app.ink_journal_view.tabs.current_tab=page
   if page in [1,2]:await capture(app,"journal_"+str(page),resolution)
  var saved:Dictionary=app.story.prepare_persisted_save()
  check(saved.error=="","journal terminal save: "+saved.error)
  app.queue_free();await process_frame;await process_frame
 check(puzzle_ids.size()==6,"all three puzzle types exercised at both resolutions")
 if not output.is_empty():
  var file:=FileAccess.open(output+"/capture-report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"checks":checks,"failures":failures,"scope":"native rendering and injected engine input; not full natural OS gameplay"},"  "));file.close()
 print("Chapter sixteen main: %d checks, %d failures; %d native images"%[checks,failures,captures.size()]);quit(1 if failures else 0)
