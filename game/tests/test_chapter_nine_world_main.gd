extends SceneTree
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const Driver=preload("res://tests/chapter_nine_world_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func settle()->void:
 await process_frame;await process_frame;await process_frame
func run()->void:
 for dimensions in [Vector2i(640,359),Vector2i(1280,720)]:
  root.size=dimensions
  var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await settle();main._layout()
  main.saves.directory="user://world_layout_"+str(OS.get_process_id())+"_"+str(dimensions.x)
  var resume:String=OS.get_environment("CH09_LAYOUT_RESUME") if dimensions.x==640 else ""
  if not resume.is_empty():
   check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(resume)))=="","resume original interrupted 640 run")
  else:
   check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","old natural source")
   check(main.story.enter_registered_chapter(9),"enter9")
   for i in range(100):
    if main.story.current_event().id=="side_ch09_l05":break
    check(Flow.advance(main.story,false),"reach L05")
   check(main.story.current_chapter_runtime().open_sidequest("L05"),"open L05")
  main._load_chapter_scene();await settle()
  var paused:Dictionary={}
  for i in range(300):
   if main.story.state.scope=="main":break
   main._show_world_puzzle();await settle()
   var session:RefCounted=main.story.current_chapter_runtime().make_puzzle()
   var rect:Rect2=Rect2(Vector2.ZERO,Vector2(dimensions))
   check(rect.encloses(main.dialogue_panel.get_global_rect()),"panel within "+str(dimensions)+" "+str(i))
   check(rect.encloses(main.dialogue_scroll.get_global_rect()),"body scroll within viewport")
   check(main.dialogue_text.size.x<=main.dialogue_scroll.size.x+1,"long body wraps")
   check(rect.encloses(main.speaker.get_global_rect()),"title wraps within footer")
   for control in main.actions.get_children():check(rect.encloses(control.get_global_rect()),"actual action fully clickable "+str(control))
   var before:Dictionary=session.snapshot()
   var pause:Button=main.actions.get_child(main.actions.get_child_count()-1);check(pause.text=="暂歇","pause always present")
   var pause_key:String=JSON.stringify(session.state.get("stage_receipts",[]))+JSON.stringify(session.state.get("looters",{}))
   if not paused.has(pause_key):
    paused[pause_key]=true
    pause.pressed.emit();await settle();check(main.mode=="menu","real pause click enters menu")
    main._cancel_choice();await settle();check(main.mode=="world_puzzle","cancel returns world action")
    session=main.story.current_chapter_runtime().make_puzzle();check(Same.equivalent(session.snapshot(),before),"pause/cancel does not act")
   var action:Dictionary=Driver.next_input(session,"A");check(not action.is_empty(),"formal next command")
   var index:=-1
   var options:Array=session.get_view().options
   for j in range(options.size()):
    if Same.equivalent(options[j].action,action):index=j;break
   if index>=0:
    var picker:OptionButton=main.actions.get_child(0);picker.select(index);picker.item_selected.emit(index)
    var execute:Button=main.actions.get_child(1);check(execute.text=="执行","real execute button");execute.pressed.emit()
   else:main._world_puzzle_input(action)
   await settle()
   if i%20==0:print("LAYOUT_PROGRESS ",dimensions.x," ",i)
  check(main.story.state.optional.L05.status=="archived","real A complete through main UI")
  main.queue_free();await settle()
 print("Chapter nine world main layout: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
