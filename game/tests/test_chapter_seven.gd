extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_seven_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_six_gui/manual_natural_final.json")))=="","natural chapter6")
 var old:Dictionary=c.actors.duplicate(true);var old_items:Dictionary=c.items.duplicate(true)
 check(c.enter_registered_chapter(7),"chapter7 entry")
 check(Proof.equivalent(old,c.actors) and Proof.equivalent(old_items,c.items),"entry preserves true resources/objects")
 for i in range(180):
  if c.state.finished:break
  print("CH7 ",c.current_token()," ",c.current_event().id)
  if OS.get_environment("CH07_PREFIX_ONLY")=="1" and c.current_event().op=="objective_battle":break
  var before:Dictionary=c.export_save()
  check(not c.current_chapter_runtime().complete(c.current_token(),{"success":true}),"fake success rejected")
  check(Proof.equivalent(before,c.export_save()),"fake proof atomic")
  for bad in [true,false,null,1,[],{}]:
   if c.current_event().op=="action":check(not c.current_chapter_runtime().complete(c.current_token(),{"map_id":bad,"position":[80,240]}),"bad action type")
   if c.current_event().op=="objective_battle":check(not c.current_chapter_runtime().accept_objective(c.current_token(),{"attempt_id":bad}),"bad battle type")
  if not Flow.advance(c):check(false,"advance "+c.current_token());break
  if live_id(c)=="dlg_ch07_crossed":check(c.scene().map_id=="map_ch07_yunxing_chain_bridge","after B04 bridge bank persists")
  var other=Campaign.new(base);var err:String=other.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
  check(err=="","event replay "+c.current_token()+" "+err)
  if err!="":break
 if OS.get_environment("CH07_PREFIX_ONLY")!="1":
  check(c.state.finished,"full completion")
  if c.state.finished:
   check(c.state.xp==13570,"1345+350+300 exact")
   check(c.state.coins==1900,"500 copper only")
   check(c.actors.char_axue.level==23 and c.actors.char_axue.status=="recovering_in_camp","snow fixed recovery status")
   check(c.actors.char_liu_yingying.xp==c.state.xp,"absent core growth")
   check(c.items.item_ch06_father_book.location=="ch06_home","book stays entrusted")
   var saved:Dictionary=c.prepare_persisted_save()
   check(saved.error=="","bounded chapter7 "+str(saved.error))
 print("Chapter seven integration: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

func live_id(c:RefCounted) -> String:return c.current_event().get("id","")
