extends SceneTree
## Actual main journal; all state comes from verified source and legal Flow12 commands.
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const SOURCE_SHA="2ee4e7e97d8741113c088639300a9fd850719f43745f56bcfb2e3771e45c1cb7"
const LABELS={"MEM_MQ10_AXUE_ETERNAL":"阿雪长忆：","MEM_MQ11_HERBAL_REUNION":"杏林重逢：","MEM_MQ11_QINGXING_LEGACY":"青杏托孤：","MEM_MQ11_XIAOSHUANG_BOTTOMLINE":"医者止戈：","MEM_R04_TRIAGE_ORDER":"危症先救：","MEM_MQ11_THREE_COMPANIONS":"古渡同行：","MEM_R05_GENTLE_STRENGTH":"拳头之外：","MEM_MQ12_CHIYOU_OATH":"蚩尤止戈："}
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func frames()->void:
 await process_frame;await process_frame
func click(button:Button)->void:
 var at:=button.get_global_rect().get_center()
 var move:=InputEventMouseMotion.new();move.position=at;move.global_position=at;Input.parse_input_event(move)
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(event)
  await process_frame
 await frames()
func journal(app:Node,phase:String)->void:
 app._load_scene();await frames()
 var before:String=JSON.stringify(app.story.export_save());var token:String=app.story.current_token()
 app._show_journal();await frames()
 var body:="";var back:Button
 for child in app.modal_content.get_children():
  if child is Label and "相处记事\n" in child.text:body=child.text.split("相处记事\n")[1]
  if child is Button and child.text=="返回":back=child
 check(app.mode=="journal" and not body.is_empty(),phase+" actual journal opens")
 for tag in LABELS:check((LABELS[tag] in body)==(tag in app.story.state.memories),phase+" earned memory only "+tag)
 for group in app.story.current_content().choice_groups.values():
  for option in group.options:
   var line:String="• "+str(group.title)+"："+str(option.label)+"\n"
   check((line in body)==(app.story.state.choices.get(group.choice_key,"")==option.id),phase+" exact choice "+option.id)
 check("阿雪长忆：" in body and "古渡同行：" in body,phase+" inherited chapter10/11 earned tags")
 check(app.modal_content.get_node_or_null("axue_empty_seat")!=null,phase+" Axue empty seat preserved")
 check(app.story.actors.char_axue.status=="dead",phase+" Axue remains permanently dead")
 check(JSON.stringify(app.story.export_save())==before,phase+" open journal leaves export unchanged")
 check(back!=null,phase+" real return button present")
 if back!=null:
  app.modal_content.get_parent().ensure_control_visible(back);await frames()
  await click(back)
 check(app.mode!="journal" and app.story.current_token()==token,phase+" native return restores current event")
 check(JSON.stringify(app.story.export_save())==before,phase+" return leaves export unchanged")
func run()->void:
 var path:=OS.get_environment("CH12_SOURCE")
 if path.is_empty() or not FileAccess.file_exists(path):push_error("CH12_SOURCE must name verified formal chapter11 command terminal");quit(1);return
 var original:=FileAccess.get_file_as_bytes(path)
 check(FileAccess.get_sha256(path)==SOURCE_SHA,"approved source SHA")
 if failures:quit(1);return
 root.size=Vector2i(640,360)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frames();app.set_process(false)
 check(app.story.restore_persisted(JSON.parse_string(original.get_string_from_utf8()))=="","formal11 restore")
 check(app.story.enter_registered_chapter(12),"registered12 entry")
 if failures:quit(1);return
 check(not "MEM_R05_GENTLE_STRENGTH" in app.story.state.memories and not "MEM_MQ12_CHIYOU_OATH" in app.story.state.memories,"entry contains no future chapter12 memories")
 await journal(app,"entry")
 var branch:=1 if OS.get_environment("CH12_BRANCH_B")=="1" else 0
 var side:bool=OS.get_environment("CH12_NO_SIDE")!="1"
 for i in range(240):
  if app.story.state.finished:break
  var token:String=app.story.current_token()
  if not Flow.advance(app.story,branch,side):check(false,"legal Flow12 progression "+token);break
 check(app.story.state.finished,"legal chapter12 terminal")
 if app.story.state.finished:
  check(("MEM_R05_GENTLE_STRENGTH" in app.story.state.memories)==side,"R05 completion memory matches actual route")
  check("MEM_MQ12_CHIYOU_OATH" in app.story.state.memories,"actual three-patient oath earned")
  check(app.story.state.optional.R05.status==("archived" if side else "missed"),"optional status matches completed or skipped route")
  check(app.story.state.choices.get("r05_method","")==(("r05_method_b" if branch else "r05_method_a") if side else ""),"actual R05 method matches route")
  check(app.story.state.choices.has("liuying_loadout") and app.story.state.choices.has("b09_loadout"),"terminal includes explicit Liu and Xiaoshuang loadout choices")
  await journal(app,"terminal")
 check(FileAccess.get_file_as_bytes(path)==original,"source bytes unchanged")
 app.queue_free();await frames()
 print("Chapter twelve actual journal: ",checks," checks, ",failures," failures; side=",side," branch=",branch)
 quit(1 if failures else 0)
