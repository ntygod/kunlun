extends SceneTree
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func frames()->void:
 for i in range(4):await process_frame
func run()->void:
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frames();app.set_process(false);app.size=Vector2(640,360);app._layout()
 var source:=FileAccess.get_file_as_string(OS.get_environment("CH11_SOURCE"))
 check(app.story.restore_persisted(JSON.parse_string(source))=="","formal10 source")
 check(app.story.enter_registered_chapter(11),"enter11")
 for i in range(160):
  if app.story.current_event().get("group")=="choice_ch11_xiaoshuang_loadout":break
  if not Flow.advance(app.story,0,true):check(false,"legal R04 path to B07 loadout");quit(1);return
 check(app.story.current_event().get("group")=="choice_ch11_xiaoshuang_loadout","real B07 loadout choice reached")
 app._load_scene();await frames()
 var token:String=app.story.current_token();var before:=JSON.stringify(app.story.state)
 app._show_menu();await frames()
 var scroll:ScrollContainer=app.modal_content.get_parent()
 scroll.scroll_vertical=100000;await frames()
 var old_offset:int=scroll.scroll_vertical
 print("MENU scroll=",old_offset," rect=",scroll.get_global_rect())
 check(old_offset>0,"real menu container scrolls below top")
 app._cancel_choice();await frames()
 var title:Control=app.modal_content.get_child(0);var description:Control=app.modal_content.get_child(1);var first:Control=app.modal_content.get_child(2)
 print("LOADOUT scroll=",scroll.scroll_vertical," scroll_rect=",scroll.get_global_rect()," title_rect=",title.get_global_rect()," description_rect=",description.get_global_rect()," first_rect=",first.get_global_rect())
 check(app.mode=="chapter_choice" and scroll.scroll_vertical==0,"new loadout clears previous menu offset")
 check(title.get_global_rect().position.y>=scroll.get_global_rect().position.y and first.get_global_rect().position.y>=scroll.get_global_rect().position.y,"loadout title and first option remain onscreen")
 scroll.scroll_vertical=80;await frames();var offset:int=scroll.scroll_vertical
 check(offset>0,"loadout can still scroll normally")
 await frames();check(scroll.scroll_vertical==offset,"same content stays scrolled across frames")
 app._show_chapter_choices();await frames()
 check(scroll.scroll_vertical==offset,"same-content refresh preserves scroll")
 app.modal.hide();app._show_chapter_choices();await frames()
 check(scroll.scroll_vertical==0,"hidden popup reentry starts at top")
 check(app.story.current_token()==token and JSON.stringify(app.story.state)==before,"scroll presentation never changes choice state")
 print("Modal scroll entry: ",checks," checks, ",failures," failures")
 app.queue_free();await process_frame;quit(1 if failures else 0)
