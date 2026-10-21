extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
const WD=preload("res://tests/chapter_nine_world_driver.gd")
var checks:=0
var failures:=0
var base:Dictionary
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func rejected(c:RefCounted,bad:Dictionary,label:String)->void:
 var before:Dictionary=c.export_save()
 check(c.restore_persisted(bad)!="",label+" rejected")
 check(Proof.equivalent(before,c.export_save()),label+" atomic")
func run()->void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var source:String=OS.get_environment("REVIEW_SOURCE")
 if source.is_empty():source="res://../output/cache/chapter_eight_gui/manual_natural_final.json"
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","real source")
 var original_archive:Array=c.export_bounded_save().archive.duplicate(true)
 var old:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var xp:int=c.state.xp;var coins:int=c.state.coins
 var r02:bool=c.state.inherited_ch04_optional.get("R02",{}).get("status")=="archived"
 var scenario:String=OS.get_environment("REVIEW_CASE")
 var side:bool=scenario in ["A","B","late","resumeA","resumeB"]
 check(c.enter_registered_chapter(9),"enter")
 var partial_done:=false
 for n in range(160):
  if c.state.finished:break
  var rt=c.current_chapter_runtime();var event:Dictionary=c.current_event();var token:String=c.current_token()
  if event.op in ["puzzle","world_puzzle"]:
   var session=rt.make_puzzle();var initial:Dictionary=session.snapshot()
   for action in [{"type":"sync","state":{"complete":true}},{"type":"set_phase","phase":2},{"type":"grant_reward"},{"type":"move","dx":true,"dy":0},{"type":"move","dx":0.5,"dy":0},{"type":"resume","complete":true}]:
    rt.puzzle_input(token,action)
    check(Proof.equivalent(initial,session.snapshot()),"bad model input atomic "+event.id+str(action))
   var legal:Dictionary=WD.next_input(session) if event.op=="world_puzzle" else session.next_demo_action()
   check(rt.puzzle_input(token,legal).get("ok",false),"actual partial input "+event.id)
   var save:Dictionary=c.export_bounded_save();var clone=Campaign.new(base)
   check(clone.restore_persisted(save)=="","partial formal replay "+event.id)
   var bad:Dictionary=save.duplicate(true);bad.current.events.back().proof.action={"type":"sync","state":{"complete":true}}
   rejected(c,bad,"forged history sync "+event.id)
   bad=save.duplicate(true);bad.current.events.back().token="forged:00";rejected(c,bad,"forged token "+event.id)
  if event.op=="quest_window" and scenario in ["partial","partialA","partialB","resumeA","resumeB"] and not partial_done:
   check(rt.open_sidequest("L05"),"open partial L05")
   var session=rt.make_puzzle()
   for i in range(180):
    if (scenario=="partial" and i==14) or (scenario in ["partialA","resumeA"] and session.state.escorting) or (scenario in ["partialB","resumeB"] and session.state.sorted.size()>0):break
    check(rt.puzzle_input(c.current_token(),WD.next_input(session,"B" if scenario in ["partialB","resumeB"] else "A")).get("ok",false),"partial L05 command")
   check(not session.state.complete,"pause unfinished actual L05 method")
   var partial:Dictionary=c.export_bounded_save();var partial_copy=Campaign.new(base)
   check(partial_copy.restore_persisted(partial)=="","partial L05 formal replay")
   check(Proof.equivalent(partial_copy.current_chapter_runtime().make_puzzle().state,session.state),"actual escort/sort persisted")
   check(rt.pause_sidequest(),"pause partial L05")
   partial_done=true
  if event.id=="confirm_ch09_enter_command_tent":
   var before:Dictionary=c.export_save()
   check(not rt.complete(token,{"closure_acknowledged":false}),"cancel deadline rejected")
   check(Proof.equivalent(before,c.export_save()),"cancel deadline atomic")
  if event.id=="evt_ch09_wood_bird_assembly_complete":check(not c.reward_ledger.has("reward_mq09_wood_bird_once"),"no prepared 500")
  if event.id=="evt_ch09_wood_bird_proof_complete":check(c.world_objects.ch09_wood_bird.state=="drifted","500 requires actual drifted")
  if not Flow.advance(c,side,1 if scenario=="B" else 0,"B" if scenario in ["B","resumeB"] else "A",scenario in ["late","resumeA","resumeB"]):check(false,"advance "+token);break
  var after:Dictionary=c.export_save()
  check(not rt.complete(token,{}),"old event rejected "+token)
  check(Proof.equivalent(after,c.export_save()),"old event atomic "+token)
 check(c.state.finished,"finished "+scenario)
 if c.state.finished:
  check(c.state.xp==xp+2830+(300 if side else 0),"exact XP")
  check(c.state.coins==coins+600,"exact coins")
  for id in items:check(Proof.equivalent(c.items[id],items[id]),"legacy item "+id)
  check(c.actors.char_axue.hp==old.char_axue.hp and c.actors.char_axue.mp==old.char_axue.mp and c.actors.char_axue.xp==0 and c.actors.char_axue.level==23,"snow fixed")
  var liu:Dictionary=c.actors.char_liu_yingying
  check(liu.hp==old.char_liu_yingying.hp+liu.max_hp-old.char_liu_yingying.max_hp and liu.mp==old.char_liu_yingying.mp,"absent Liu HP delta only")
  check(liu.status==old.char_liu_yingying.status and liu.xp==c.state.xp,"Liu stays absent same XP")
  for skill in ["LYY_A01","LYY_A02"]:check(liu.skill_ranks[skill]==3,"Liu +5 "+skill)
  for skill in ["LYY_N01","LYY_P01"]:check(liu.skill_ranks.get(skill)==old.char_liu_yingying.skill_ranks.get(skill),"N/P ranks not invented "+skill)
  for skill in ["LYY_A04","LYY_A05"]:
   if skill in old.char_liu_yingying.skills:check(liu.skill_ranks[skill]>=2,"Liu +2 "+skill)
   else:check(skill not in liu.skills,"no missing skill grant "+skill)
  for skill in ["LX_A01","LX_A02"]:check(c.actors.char_liang_xiao.skill_ranks[skill]>=3,"hero overdue +5 "+skill)
  check(c.actors.char_liang_xiao.skill_ranks.LX_A03>=2,"hero existing A03 +2")
  check(liu.skill_ranks.LYY_A03==(3 if r02 else 2),"R02 actual acquire+5 rank "+str(r02)+" got "+str(liu.skill_ranks.LYY_A03))
  check(c.actors.char_liang_xiao.skill_ranks.LX_P03==old.char_liang_xiao.skill_ranks.LX_P03,"P03 not fourteen")
  check(c.actors.char_liang_xiao.mp==old.char_liang_xiao.mp,"hero no MP restore")
  check(Proof.equivalent(c.actors.char_liang_xiao.equipment,old.char_liang_xiao.equipment),"gear retained")
  check(Proof.equivalent(c.actors.char_liang_xiao.equipped_passives,old.char_liang_xiao.equipped_passives),"two slots retained")
  check(c.items.item_ch09_wang_hammer.owner=="char_liang_xiao" and c.items.item_ch09_shadow_slips.owner=="char_liang_xiao","both bag priorities retained")
  check(c.items.item_ch09_serpent_diamond.form=="intact" and c.items.item_ch09_serpent_diamond.quantity==1,"diamond unique intact")
  check(c.items.has("item_ch09_physician_key")==side and ("MEM_L05" in c.state.memories)==side,"L05 exact rewards")
  for id in ["npc_zhao_shan","npc_yang_que","npc_wang_ke"]:
   if c.world_objects.ch07_six_friends.has(id):check(c.world_objects.ch07_six_friends[id]=="dead","dead stays dead "+id)
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","final bounded accepted "+str(saved.error))
  var good:Dictionary=saved.payload
  check(Proof.equivalent(good.archive.slice(0,9),original_archive),"frozen 0-8 summaries preserved")
  var exact:Dictionary=c.export_bounded_save()
  check(c.restore_persisted(good)=="","repeat restore once")
  check(c.restore_persisted(good)=="","repeat restore twice")
  check(Proof.equivalent(exact,c.export_bounded_save()),"summary repeated adoption idempotent")
  for field in ([] if OS.get_environment("REVIEW_FAST")=="1" else good.archive[9].keys()):
   for value in [true,null,[],{},"bad",-1,0.5]:
    var bad:Dictionary=good.duplicate(true);bad.archive[9][field]=value
    rejected(c,bad,"summary "+field+" "+str(value))
  var bad:Dictionary=good.duplicate(true);bad.archive[9].boundary_vitals.char_axue.hp+=1;rejected(c,bad,"snow invented healing")
  bad=good.duplicate(true);bad.archive[9].boundary_vitals.char_liu_yingying.mp+=1;rejected(c,bad,"Liu invented mana")
  bad=good.duplicate(true);bad.archive[9].rewards={"fake":500};rejected(c,bad,"summary rewards injection")
  var f=FileAccess.open("/tmp/k9-review/final_"+scenario+".json",FileAccess.WRITE);f.store_string(JSON.stringify(good));f.close()
 print("INDEPENDENT STATE ",scenario," ",source," ",checks," checks ",failures," failures")
 quit(1 if failures else 0)
