extends SceneTree
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const LABELS:={"MEM_MQ11_HERBAL_REUNION":"杏林重逢","MEM_MQ11_QINGXING_LEGACY":"青杏托孤","MEM_MQ11_XIAOSHUANG_BOTTOMLINE":"医者止戈","MEM_R04_TRIAGE_ORDER":"危症先救","MEM_MQ11_THREE_COMPANIONS":"古渡同行"}
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func journal(app:Node,phase:String)->void:
 app._load_scene();var before:String=JSON.stringify(app.story.export_save());app._show_journal()
 var body:=""
 for child in app.modal_content.get_children():
  if child is Label and "相处记事\n" in child.text:body=child.text.split("相处记事\n")[1]
 check(not body.is_empty(),phase+" journal includes inherited memories")
 for tag in LABELS:check((LABELS[tag] in body)==(tag in app.story.state.memories),phase+" exact memory "+tag)
 for group in app.story.current_content().choice_groups:
  var key:String={"choice_ch11_r04_method":"r04_method","choice_ch11_xiaoshuang_loadout":"b07_loadout"}.get(group,group)
  for option in app.story.current_content().choice_groups[group].options:
   check((option.label in body)==(app.story.state.choices.get(key,"")==option.id),phase+" choice "+option.id)
 check("阿雪长忆" in body,phase+" earned chapter10 remembrance retained")
 check(app.modal_content.get_node_or_null("axue_empty_seat")!=null,phase+" white empty seat preserved")
 var missing:=""
 for i in range(body.length()):
  var code:int=body.unicode_at(i)
  if code>32 and not app.title_font.has_char(code) and body[i] not in missing:missing+=body[i]
 check(missing.is_empty(),phase+" journal font covers text; missing="+missing)
 check(JSON.stringify(app.story.export_save())==before,phase+" journal read only")
 app._cancel_choice()
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:=OS.get_environment("CH11_SOURCE")
 if path.is_empty():push_error("CH11_SOURCE must point to verified chapter10 command terminal");quit(1);return
 var original:=FileAccess.get_file_as_string(path)
 var app:Node=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame;app.set_process(false)
 check(app.story.restore_persisted(JSON.parse_string(original))=="","formal source restore")
 check(app.story.enter_registered_chapter(11),"enter11")
 journal(app,"entry")
 var branch:=1 if OS.get_environment("CH11_BRANCH_B")=="1" else 0
 var side:bool=OS.get_environment("CH11_NO_SIDE")!="1"
 for i in range(140):
  if app.story.current_event().op=="objective_battle":break
  var choice:int=0 if app.story.current_event().op=="choice" and app.story.available_choices().size()<=branch else branch
  if not Flow.advance(app.story,choice,side):check(false,"prebattle commands "+app.story.current_token());quit(1);return
 check(app.story.current_event().op=="objective_battle" and app.story.state.choices.has("b07_loadout"),"legal stage with explicit loadout key")
 journal(app,"before B07")
 for i in range(140):
  if app.story.state.finished:break
  var choice:int=0 if app.story.current_event().op=="choice" and app.story.available_choices().size()<=branch else branch
  if not Flow.advance(app.story,choice,side):check(false,"terminal commands "+app.story.current_token());quit(1);return
 check(app.story.state.finished,"legal terminal")
 journal(app,"terminal")
 check(FileAccess.get_file_as_string(path)==original,"source bytes unchanged")
 app.queue_free();await process_frame
 print("Chapter eleven journal: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
