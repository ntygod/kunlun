extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 var source:String=OS.get_environment("CH09_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_eight_gui/manual_natural_final.json"
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","real chapter8 source")
 var old:Dictionary=c.actors.duplicate(true);var old_items:Dictionary=c.items.duplicate(true);var old_coins:int=c.state.coins;var old_xp:int=c.state.xp
 check(c.enter_registered_chapter(9),"chapter9 entry")
 check(Proof.equivalent(old_items,c.items),"entry preserves all legacy objects")
 var side:bool=OS.get_environment("CH09_NO_SIDE")!="1";var branch:int=1 if OS.get_environment("CH09_BRANCH_B")=="1" else 0
 for i in range(160):
  if c.state.finished:break
  print("CH9 ",c.current_token()," ",c.current_event().id)
  var before:Dictionary=c.export_save()
  check(not c.current_chapter_runtime().complete(c.current_token(),{"success":true}),"fake success rejected")
  check(Proof.equivalent(before,c.export_save()),"fake proof atomic")
  if not Flow.advance(c,side,branch,"B" if branch==1 else "A",OS.get_environment("CH09_LATE_SIDE")=="1"):check(false,"advance "+c.current_token());break
  if OS.get_environment("CH09_FAST")!="1":
   var other=Campaign.new(base);var err:String=other.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(err=="","event replay "+c.current_token()+" "+err)
   if err!="":break
 check(c.state.finished,"full completion")
 if c.state.finished:
  check(c.state.xp==old_xp+2830+(300 if side else 0),"exact XP")
  check(c.state.coins==old_coins+600,"600 copper once")
  check(c.actors.char_axue.hp==old.char_axue.hp and c.actors.char_axue.mp==old.char_axue.mp and c.actors.char_axue.level==23,"snow unchanged panel")
  check(c.actors.char_liu_yingying.xp==c.state.xp,"absent core growth")
  check(c.actors.char_liu_yingying.skill_ranks.LYY_A03==(3 if c.state.inherited_ch04_optional.get("R02",{}).get("status")=="archived" else 2),"A03 actual acquisition milestone")
  for who in ["char_liang_xiao","char_liu_yingying"]:
   for skill in old[who].skill_ranks:
    if "_N" in str(skill) or "_P" in str(skill):check(c.actors[who].skill_ranks[skill]==old[who].skill_ranks[skill],"internal/passive rank unchanged "+str(skill))
  check(c.actors.char_liang_xiao.mp==old.char_liang_xiao.mp,"scene never refills MP")
  check(Proof.equivalent(old.char_liang_xiao.equipment,c.actors.char_liang_xiao.equipment),"gear retained")
  for id in old_items:check(Proof.equivalent(old_items[id],c.items[id]),"old object retained "+id)
  check(c.items.item_ch09_serpent_diamond.owner=="char_liang_xiao","diamond retained")
  check(c.world_objects.ch07_six_friends.npc_wang_ke=="dead","Wang fixed death")
  check(c.items.item_ch09_general_seal.owner=="camp","court relinquished separately")
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","bounded chapter9 "+str(saved.error))
  print("CH09_FINAL_RESOURCES ",JSON.stringify({"xp":c.state.xp,"coins":c.state.coins,"hero":c.actors.char_liang_xiao,"liu":c.actors.char_liu_yingying,"axue":c.actors.char_axue,"l05":c.state.optional.L05}))
 print("Chapter nine integration: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
