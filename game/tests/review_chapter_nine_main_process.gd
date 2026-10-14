extends SceneTree
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func settle()->void:await process_frame;await process_frame;await process_frame
func key(main:Node,code:int)->void:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;main._input(e)
func run()->void:
 var mode:String=OS.get_environment("PROCESS_MODE")
 var ids:Array=["pz_ch09_pine_needle","pz_ch09_wood_bird_begin","evt_ch09_wood_bird_resume"]
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await settle()
 if mode=="write":
  check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","source")
  check(main.story.enter_registered_chapter(9),"chapter9")
  for j in range(100):
   var event:Dictionary=main.story.current_event()
   if event.id in ids:
    var id:String=event.id
    main.saves.directory="/tmp/k9-review/main_"+id
    main._load_chapter_scene();main._show_registered_puzzle();await settle()
    var rt=main.story.current_chapter_runtime();var s=rt.make_puzzle()
    for n in range(7 if id==ids[0] else (10 if id==ids[1] else 1)):
     check(rt.puzzle_input(main.story.current_token(),s.next_demo_action()).get("ok",false),"partial legal command")
    main._show_registered_puzzle();await settle();print("DEBUG MODE ",main.mode," cap ",main.story.chapter_capability("checkpoint_inputs")," maps ",InputMap.action_get_events("save_game"));key(main,KEY_F5);await settle()
    check(FileAccess.file_exists(main.saves.directory+"/manual.json"),"F5 bytes exist "+main.notice.text)
    if not FileAccess.file_exists(main.saves.directory+"/manual.json"):quit(1);return
    var f=FileAccess.open(main.saves.directory+"/expected.json",FileAccess.WRITE)
    var snap:Dictionary=main.story.current_chapter_runtime().make_puzzle().snapshot()
    f.store_string(JSON.stringify({"token":main.story.current_token(),"snapshot":snap,"actors":main.story.actors,"items":main.story.items}));f.close()
    print("ACTUAL MAIN WROTE ",id," stage ",snap.state.get("stage")," phase ",snap.state.get("phase")," hash ",FileAccess.get_file_as_string(main.saves.directory+"/manual.json").sha256_text())
    if id==ids[-1]:break
   if not Flow.advance(main.story,false):check(false,"advance");break
 else:
  for id in ids:
   main.saves.directory="/tmp/k9-review/main_"+id
   var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(main.saves.directory+"/expected.json"))
   main._show_menu();key(main,KEY_F9);await settle()
   check(main.story.current_token()==expected.token,"separate process F9 token")
   var rt=main.story.current_chapter_runtime();var s=rt.make_puzzle()
   check(s!=null,"restored puzzle")
   if s==null:continue
   check(Proof.equivalent(s.snapshot(),expected.snapshot),"separate process exact partial phase/path")
   check(Proof.equivalent(main.story.actors,expected.actors),"exact actual actor resource")
   check(Proof.equivalent(main.story.items,expected.items),"exact unique inventory")
   var token:String=main.story.current_token()
   check(Flow.advance(main.story,false),"restored session completes normally")
   check(main.story.current_token()!=token,"manual resumed progression")
   print("ACTUAL MAIN INDEPENDENT READ ",id," PASS")
 main.queue_free();await settle()
 print("INDEPENDENT MAIN PROCESS ",mode," ",checks," checks ",failures," failures");quit(1 if failures else 0)
