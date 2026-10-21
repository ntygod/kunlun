extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_ten_campaign_driver.gd")
const Summary=preload("res://scripts/campaign/chapter_ten_summary.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"));var c=Campaign.new(base)
 var source:String=OS.get_environment("CH10_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_nine_gui/manual_natural_final.json"
 var original:String=FileAccess.get_file_as_string(source)
 check(c.restore_persisted(JSON.parse_string(original))=="","genuine chapter9 source")
 var old:Dictionary=c.actors.duplicate(true);var old_items:Dictionary=c.items.duplicate(true);var old_coins:int=c.state.coins;var old_xp:int=c.state.xp
 check(c.enter_registered_chapter(10),"chapter10 entry")
 if c.active_chapter!=10:quit(1);return
 check(Same.equivalent(old,c.actors) and Same.equivalent(old_items,c.items),"entry resources and ownership unchanged")
 var branch:int=1 if OS.get_environment("CH10_BRANCH_B")=="1" else 0
 for i in range(100):
  if c.state.finished:break
  var rt:RefCounted=c.current_chapter_runtime();var event:Dictionary=c.current_event();var token:String=c.current_token()
  print("CH10 ",token," ",event.id)
  var before:Dictionary=c.export_save()
  check(not rt.complete(token,{"success":true}),"fake completion refused")
  check(Same.equivalent(before,c.export_save()),"bad proof atomic")
  if event.id=="evt_ch10_prepare_escape":
   var mp:int=c.actors.char_liang_xiao.mp
   if not Flow.advance(c,branch):check(false,"explicit bandaging");break
   check(c.actors.char_liang_xiao.hp==c.actors.char_liang_xiao.max_hp and c.actors.char_liang_xiao.mp==mp,"once hero HP only")
   check(not rt.complete(token,{}),"old bandage token refused")
  else:
   if event.op in ["puzzle","world_puzzle"]:
    var model:RefCounted=rt.make_puzzle();check(model!=null,"real puzzle exists")
    if model==null:break
    check(rt.puzzle_input(token,model.next_demo_action()).get("ok",true),"legal first input")
    var partial=Campaign.new(base);var error:String=partial.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
    check(error=="","partial puzzle restored "+event.id+" "+error)
    if error!="":break
    check(Same.equivalent(rt.make_puzzle().snapshot(),partial.current_chapter_runtime().make_puzzle().snapshot()),"partial state identical")
   if event.op=="objective_battle":
    check(c.state.xp==old_xp+1505 and c.actors.char_axue.status=="dead","B06 after exact first seven rewards and death")
    var battle:RefCounted=rt.make_objective_encounter();check(battle!=null,"actual B06 entry")
    if battle==null:break
    check(battle.set_command("char_liang_xiao","self_guard","char_liang_xiao")=="" and battle.resolve_round(),"actual first guard round")
    check(rt.save_objective_checkpoint(battle),"battle checkpoint accepted")
    var partial=Campaign.new(base);var error:String=partial.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
    check(error=="","partial battle restore "+error)
    check(Same.equivalent(battle.snapshot(),partial.current_chapter_runtime().make_objective_encounter().snapshot()),"partial battle identical")
    # Clear only test's local checkpoint via legitimate retry and save, then driver starts at entry.
    battle.retry();check(rt.save_objective_checkpoint(battle),"retry restores original entry")
   if not Flow.advance(c,branch):check(false,"advance "+token);break
  if OS.get_environment("CH10_FAST")!="1":
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","event replay "+token+" "+error)
   if error!="":break
 check(c.state.finished,"full playable completion")
 if c.state.finished:
  check(c.state.xp==old_xp+3070 and c.state.coins==old_coins+650,"exact main2770+B06 300 and650 copper")
  check(c.actors.char_axue.status=="dead" and c.actors.char_axue.hp==old.char_axue.hp and c.actors.char_axue.mp==old.char_axue.mp,"death preserves historical resources")
  check(c.actors.char_liu_yingying.xp==c.state.xp,"absent Liu progression")
  check(c.actors.char_liang_xiao.skill_ranks.LX_A04==1 and c.world_objects.ch10_stone_lesson.months==3,"A04 at three months only")
  check(c.items.item_ch10_axue_sewing_kit.quantity==1 and not c.items.item_ch10_axue_sewing_kit.sellable,"unique nontrade kit")
  check(c.world_objects.ch10_farewell.held_relic=="" and c.world_objects.ch10_farewell.r03_memory_only,"R03 custody respected")
  for id in old_items:check(Same.equivalent(old_items[id],c.items[id]),"old owned object intact "+id)
  for who in ["char_liang_xiao","char_liu_yingying"]:check(Same.equivalent(old[who].equipment,c.actors[who].equipment),"inherited equipment "+who)
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","bounded terminal save "+str(saved.error))
  var restored=Campaign.new(base);check(restored.restore_persisted(saved.get("payload",{}))=="","bounded restore")
  var summary:Dictionary=Summary.pack(c)
  var baseline=Campaign.new(base);check(baseline.restore_persisted(JSON.parse_string(original))=="","fresh source for summary")
  check(Summary.apply(baseline,summary)=="","bounded reducer accepted genuine outcome")
  var forged:Dictionary=summary.duplicate(true);forged.boundary_vitals.char_axue.hp+=1
  var rejecting=Campaign.new(base);rejecting.restore_persisted(JSON.parse_string(original))
  check(Summary.apply(rejecting,forged)!="","fixed historical Axue vital forgery refused")
  print("CH10_FINAL ",JSON.stringify({"xp":c.state.xp,"coins":c.state.coins,"hero":c.actors.char_liang_xiao,"axue":c.actors.char_axue,"summary":summary}))
 check(FileAccess.get_file_as_string(source)==original,"original natural source unmodified")
 print("Chapter ten campaign: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
