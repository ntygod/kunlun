extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_eight_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json")))=="","natural chapter7")
 var old:Dictionary=c.actors.duplicate(true);var old_items:Dictionary=c.items.duplicate(true)
 check(c.enter_registered_chapter(8),"chapter8 entry")
 check(Proof.equivalent(old_items,c.items),"entry preserves all legacy objects")
 var side:bool=OS.get_environment("CH08_NO_SIDE")!="1"
 var branch:int=1 if OS.get_environment("CH08_BRANCH_B")=="1" else 0
 for i in range(150):
  if c.state.finished:break
  print("CH8 ",c.current_token()," ",c.current_event().id)
  var before:Dictionary=c.export_save()
  check(not c.current_chapter_runtime().complete(c.current_token(),{"success":true}),"fake success rejected")
  check(Proof.equivalent(before,c.export_save()),"fake proof atomic")
  if not Flow.advance(c,side,branch,"sand" if branch==1 else "body"):check(false,"advance "+c.current_token());break
  var other=Campaign.new(base);var err:String=other.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
  check(err=="","event replay "+c.current_token()+" "+err)
  if err!="":break
 check(c.state.finished,"full completion")
 if c.state.finished:
  check(c.state.xp==13570+3795+(300 if side else 0),"exact XP")
  check(c.state.coins==2450,"550 copper only")
  check(c.actors.char_axue.hp==old.char_axue.hp and c.actors.char_axue.mp==old.char_axue.mp,"snow no healing damage or level")
  check(c.actors.char_liu_yingying.xp==c.state.xp,"absent core growth")
  check(c.items.item_ch06_father_book.location=="ch06_home","book remains entrusted")
  check(c.actors.char_liang_xiao.skill_ranks.LX_A03==2,"sword rank only end")
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","bounded chapter8 "+str(saved.error))
 print("Chapter eight integration: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
