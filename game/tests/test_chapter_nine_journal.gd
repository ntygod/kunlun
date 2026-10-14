extends SceneTree
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func settle()->void:
 await process_frame;await process_frame;await process_frame
func button(main:Node,label:String)->Button:
 for n in main.modal_content.get_children():
  if n is Button and n.text==label:return n
 return null
func run()->void:
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await settle()
 check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","real old natural source")
 check(main.story.enter_registered_chapter(9),"chapter9")
 for phase in ["live","finished"]:
  if phase=="finished":
   for i in range(160):
    if main.story.state.finished:break
    check(Flow.advance(main.story,true),"formal completion")
   check(main.story.state.finished,"actual chapter finished")
  for size in [Vector2i(640,360),Vector2i(1280,720)]:
   root.size=size;main._layout();main._load_chapter_scene();await settle()
   var before:Dictionary=main.story.export_save()
   var before_mode:String=main.mode
   if phase=="finished":
    var open:Button=button(main,"查看记事");check(open!=null,"ending journal button exists");open.pressed.emit()
   else:main._show_journal()
   await settle();check(main.mode=="journal","journal route "+phase)
   var scroll:ScrollContainer=main.modal_content.get_parent()
   check(main.modal.visible and scroll.get_global_rect().size.x<=size.x,"journal bounded width")
   var text:=""
   for node in main.modal_content.get_children():
    if node is Label:text+=node.text
   check(text.contains("行旅记事") and text.contains("第09章"),"actual journal content displayed")
   if phase=="finished":check(text.contains("蛇眼魔钻") and text.contains("张郎中的铜钥匙"),"real new items have readable registry names")
   var back:Button=button(main,"返回");check(back!=null,"journal return exists")
   scroll.scroll_vertical=100000;await settle();check(scroll.get_global_rect().intersects(back.get_global_rect()),"640 scroll reaches return")
   back.pressed.emit();await settle();check(main.mode==before_mode,"return proper mode")
   main._show_journal();await settle();main._cancel_choice();await settle()
   check(Same.equivalent(before,main.story.export_save()),"journal/return/cancel never advance or mutate save")
 main.queue_free();await settle();print("Chapter nine journal: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
