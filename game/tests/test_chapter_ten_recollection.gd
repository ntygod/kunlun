extends SceneTree
## Presentation-only simulated-frame test; separate writer/reader process modes.
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func key(code:int,pressed:bool=true,physical_only:bool=false)->void:
 var e:=InputEventKey.new();e.keycode=0 if physical_only else code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events()
func tap(code:int)->void:
 key(code);await process_frame;key(code,false);await process_frame
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
 var release:=event.duplicate() as InputEventMouseButton;release.pressed=false;release.button_mask=0;Input.parse_input_event(release);Input.flush_buffered_events();await process_frame
func ticks(app:Node,count:int)->void:
 for i in range(count):app.chapter_ten_recollection.tick(app,0.1)
func fingerprint(app:Node)->String:
 var s:Dictionary=app.story.state
 return JSON.stringify([app.story.actors,app.story.items,s.xp,s.coins,s.memories,s.choices,s.receipts,s.completed,app.story.current_token()])
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 print("Recollection PID ",OS.get_process_id()," mode ",OS.get_environment("CH10_RECOLLECTION_MODE"))
 if OS.get_environment("CH10_RECOLLECTION_MODE")=="reader":
  await tap(KEY_F9)
  var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://recollection-expected.json"))
  check(app.mode=="chapter_recollection","fresh process F9 reoffers optional presentation")
  check(app.story.current_token()==expected.token,"original event token preserved")
  check(app.world.player.position==Vector2(expected.position[0],expected.position[1]),"fresh process restores original floating feet")
  check(app.chapter_ten_recollection.elapsed==0 and not app.chapter_ten_recollection.remembered,"presentation timer intentionally not persisted")
  check(fingerprint(app)==expected.fingerprint,"rewards actors old items and receipts preserved")
  await tap(KEY_SPACE);check(app.mode=="chapter_dialogue" and app.story.current_token()==expected.token,"Space immediately resumes original dialogue")
 else:
  var source:=OS.get_environment("CH10_SOURCE")
  if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
  var original:=FileAccess.get_file_as_string(source)
  check(app.story.restore_persisted(JSON.parse_string(original))=="","original9 restore")
  check(app.story.enter_registered_chapter(10),"enter10")
  for i in range(100):
   if app.story.current_event().id=="pz_ch10_stone_array":break
   if not Flow.advance(app.story):check(false,"stone fixture commands");quit(1);return
  app._load_scene();check(app.mode=="explore","ordinary stone exploration")
  key(KEY_RIGHT,true,true)
  for i in range(44):await physics_frame
  key(KEY_RIGHT,false,true);await physics_frame
  key(KEY_UP)
  for i in range(29):await physics_frame
  key(KEY_UP,false);await physics_frame
  app._save();var origin:Vector2=app.world.player.position
  check(origin.x!=round(origin.x) and origin.distance_to(Vector2(112,224))<=12,"actual physics creates floating preentry near hearth")
  for i in range(100):
   if app.story.current_event().id=="evt_ch10_three_months_complete":break
   if not Flow.advance(app.story):check(false,"preentry fixture commands");quit(1);return
  check(app.saves.save_game(app.story)=="","formal old chronology preentry file generated")
  var token:String=app.story.current_token();var unchanged:=fingerprint(app)
  app._load("manual");check(app.mode=="chapter_recollection" and app.world.player.position==origin,"optional offer never snaps floating feet")
  await process_frame;await process_frame
  for button in app.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(button.get_global_rect()),"640 optional control fits")
  await click(app.actions.get_child(0));check(app.mode=="chapter_dialogue" and app.story.current_token()==token,"native mouse immediately resumes original dialogue")
  app._load("manual");ticks(app,29);check(not app.chapter_ten_recollection.remembered,"less than3s no recollection")
  ticks(app,1);check(app.chapter_ten_recollection.remembered and "身旁再没有人回应" in app.dialogue_text.text,"3 focused seconds shows legible remembrance")
  check(fingerprint(app)==unchanged,"presentation grants no reward memory or main proof")
  app._load("manual");ticks(app,20);key(KEY_D);app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);ticks(app,100)
  var unfocused_position:Vector2=app.world.player.position
  for i in range(6):await physics_frame
  check(app.world.player.position==unfocused_position,"held movement cannot drift while unfocused")
  key(KEY_D,false)
  check(not app.world.player.enabled and app.chapter_ten_recollection.elapsed==0,"focus out stops movement and cancels partial dwell")
  app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);ticks(app,29);check(not app.chapter_ten_recollection.remembered,"no hidden time catchup")
  await click(app.actions.get_child(1));ticks(app,100);check(app.mode=="menu" and app.world.player.position==origin,"native mouse pause restores original feet")
  app._cancel_choice();check(app.chapter_ten_recollection.elapsed==0,"menu resumes presentation at zero")
  ticks(app,20);key(KEY_D)
  for i in range(4):await physics_frame
  key(KEY_D,false);await physics_frame;ticks(app,1)
  check(app.chapter_ten_recollection.elapsed==0,"moving resets dwell")
  check(app.world.player.position!=origin,"presentation navigation actually moved")
  await tap(KEY_F5);check(app.story.state.position==[origin.x,origin.y],"F5 saves original main position not presentation movement")
  check(app.chapter_ten_recollection.elapsed==0,"F5 cancels partial dwell")
  var meta:=FileAccess.open("user://recollection-expected.json",FileAccess.WRITE)
  meta.store_string(JSON.stringify({"token":token,"position":[origin.x,origin.y],"fingerprint":fingerprint(app)}));meta.close()
  await tap(KEY_E);check(app.world.player.position==origin and app.mode=="chapter_dialogue","leave restores feet and original dialogue")
  check(fingerprint(app)==unchanged,"exit remains pure presentation")
  for i in range(100):
   if app.story.state.finished:break
   if not Flow.advance(app.story):check(false,"terminal fixture commands");quit(1);return
  app._load_scene();check(app.mode=="ending" and not app.chapter_ten_recollection.active,"old terminal not forced to replay")
  check(FileAccess.get_file_as_string(source)==original,"source file unchanged")
 app.queue_free();await process_frame
 print("Chapter ten recollection: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
