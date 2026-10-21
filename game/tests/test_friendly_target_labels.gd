extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const BattlePanel=preload("res://scripts/ui/chapter_eleven_battle_panel.gd")
const HERO="char_liang_xiao"
const X="char_hua_xiaoshuang"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center()
 var move:=InputEventMouseMotion.new();move.position=at;move.global_position=at;Input.parse_input_event(move)
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func run()->void:
 root.size=Vector2i(640,360)
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 var source:=FileAccess.get_file_as_string(OS.get_environment("CH11_SOURCE"))
 check(c.restore_persisted(JSON.parse_string(source))=="","formal chapter10 source")
 check(c.enter_registered_chapter(11),"enter11")
 for i in range(120):
  if c.current_event().op=="objective_battle":break
  if not Flow.advance(c,0,false):check(false,"legal campaign to B07");quit(1);return
 var session:RefCounted=c.current_chapter_runtime().make_objective_encounter()
 check(session!=null,"real campaign combat_party creates B07")
 var before:=JSON.stringify(session.snapshot())
 var view:Dictionary=session.get_view()
 for actor in view.actors:
  if actor.id==HERO:
   print("CAMPAIGN hero id=",actor.id," name=",actor.get("name","<absent>"))
   check(actor.get("name",HERO)==HERO,"fixture exposes real raw-name fallback without editing actor")
 var panel=BattlePanel.new();root.add_child(panel);panel.position=Vector2(20,20);panel.size=Vector2(600,320);panel.render(view,{},session.can_resolve());await process_frame;await process_frame
 var received:Array=[];panel.command_requested.connect(func(actor,skill,target,revision):received.append([actor,skill,target,revision]))
 for pair in [[HERO,"self_guard"],[X,"HXS_A02"]]:
  var skills:OptionButton=panel.slots[pair[0]+"_skills"]
  for i in range(skills.item_count):
   if skills.get_item_metadata(i)==pair[1]:skills.select(i);skills.item_selected.emit(i);break
  var target:OptionButton=panel.slots[pair[0]+"_target"];var found:=false
  for i in range(target.item_count):
   if target.get_item_metadata(i)==HERO:
    found=true;target.select(i)
    print("TARGET skill=",pair[1]," text=",target.get_item_text(i)," metadata=",target.get_item_metadata(i))
    check(target.get_item_text(i)=="梁萧","friendly selector uses display name "+pair[1])
  check(found,"original legal target ID remains available")
  await click(panel.slots[pair[0]+"_confirm"])
  check(not received.is_empty() and received.back()==[pair[0],pair[1],HERO,int(view.revision)],"native confirm preserves exact command IDs and revision")
 check(JSON.stringify(session.snapshot())==before,"display and command emission never mutate session snapshot")
 panel.view={"actors":[{"id":HERO,"name":""}]};check(panel._actor_name(HERO)=="梁萧","empty known display name falls back")
 panel.view={"actors":[{"id":HERO,"name":"既有称谓"}]};check(panel._actor_name(HERO)=="既有称谓","explicit display name preserved")
 panel.view={"actors":[{"id":"unknown_actor","name":"unknown_actor"}]};check(panel._actor_name("unknown_actor")=="unknown_actor","unknown ID fallback preserved")
 panel.queue_free();await process_frame
 if ResourceLoader.exists("res://scripts/ui/chapter_twelve_battle_panel.gd"):await chapter_twelve()
 else:print("Chapter12 panel absent in this chapter11 branch; conditional case not run")
 print("Friendly target labels: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

func chapter_twelve()->void:
 var path:=OS.get_environment("CH12_SOURCE")
 check(not path.is_empty() and FileAccess.file_exists(path),"chapter12 conditional test requires formal11 source")
 if path.is_empty() or not FileAccess.file_exists(path):return
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="" and c.enter_registered_chapter(12),"formal source enters12")
 var flow=load("res://tests/chapter_twelve_campaign_driver.gd")
 for i in range(100):
  if c.current_event().op=="objective_battle":break
  if not flow.advance(c,0,false):check(false,"legal12 first battle prefix");return
 var session:RefCounted=c.current_chapter_runtime().make_objective_encounter()
 var before:=JSON.stringify(session.snapshot())
 var panel=load("res://scripts/ui/chapter_twelve_battle_panel.gd").new();root.add_child(panel);panel.size=Vector2(600,320);panel.render(session.get_view(),{},session.can_resolve());await process_frame;await process_frame
 var skills:OptionButton=panel.slots[HERO+"_skills"]
 for i in range(skills.item_count):
  if skills.get_item_metadata(i)=="self_guard":skills.select(i);skills.item_selected.emit(i);break
 var target:OptionButton=panel.slots[HERO+"_target"]
 check(target.item_count==1 and target.get_item_text(0)=="梁萧" and target.get_item_metadata(0)==HERO,"chapter12 actual target uses inherited name with unchanged metadata")
 var received:Array=[];panel.command_requested.connect(func(a,b,c,d):received.append([a,b,c,d]))
 await click(panel.slots[HERO+"_confirm"])
 check(received==[[HERO,"self_guard",HERO,int(session.get_view().revision)]],"chapter12 command IDs remain unchanged")
 check(JSON.stringify(session.snapshot())==before,"chapter12 display does not mutate session")
 panel.queue_free();await process_frame
