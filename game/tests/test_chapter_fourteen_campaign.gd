extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_fourteen_campaign_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"));var c=Campaign.new(base)
 var path:String=OS.get_environment("CH14_SOURCE")
 if path.is_empty():push_error("Explicit CH14_SOURCE verified chapter13 terminal required");quit(1);return
 var source_sha:=FileAccess.get_sha256(path)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","formal13 source restore")
 check(c.active_chapter==13 and c.state.finished,"source is actually archived13, not inferred from filename")
 var old:Dictionary=c.actors.duplicate(true);var olditems:Dictionary=c.items.duplicate(true);var xp:int=c.state.xp;var coins:int=c.state.coins
 var branch:int=1 if OS.get_environment("CH14_BRANCH_B")=="1" else 0
 check(c.enter_registered_chapter(14),"enter14")
 if c.active_chapter!=14:quit(1);return
 check(Same.equivalent(old,c.actors) and Same.equivalent(olditems,c.items),"entry preserves actor injury equipment items")
 for i in range(280):
  if c.state.finished:break
  var rt:RefCounted=c.current_chapter_runtime();var event:Dictionary=c.current_event();var token:String=c.current_token()
  print("CH14 ",token," ",event.id)
  var before:Dictionary=c.export_save();var prior_actors:Dictionary=c.actors.duplicate(true)
  check(not rt.complete(token,{"success":true}) and Same.equivalent(before,c.export_save()),"forged proof atomic")
  if event.op in ["puzzle","world_puzzle"]:
   var model:RefCounted=rt.make_puzzle();check(model!=null,"actual model "+event.id)
   if model==null:break
   var result:Dictionary=rt.puzzle_input(token,model.next_demo_action());check(result.get("ok",result.get("accepted",false)),"first real command")
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","partial strict replay "+event.id+" "+error)
   if error!="":break
   check(Same.equivalent(model.snapshot(),rebuilt.current_chapter_runtime().make_puzzle().snapshot()),"partial exact snapshot")
  if event.op=="objective_battle":
   check(c.state.xp==xp+1600,"B11 entry main600 and calendar1000")
   if not OS.get_environment("CH14_ENTRY_OUTPUT").is_empty():
    var f=FileAccess.open(OS.get_environment("CH14_ENTRY_OUTPUT"),FileAccess.WRITE);f.store_string(JSON.stringify({"party":rt.combat_party(),"context":rt.puzzle_context()}));f.close()
   check(rt.battle_actor_ids()==[Party.HERO,Party.HUASHENG] and c.actors[Party.XIAOSHUANG].status=="abducted","brother party excludes captive healer and departed Liu")
   var session:RefCounted=rt.make_objective_encounter();check(session!=null,"canonical B11")
   if session==null:break
   check(session.set_command(Party.HERO,"self_guard",Party.HERO)=="","actual unresolved command")
   check(rt.save_objective_checkpoint(session),"battle checkpoint")
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","battle pending restore "+error)
   if error!="":break
   check(Same.equivalent(session.snapshot(),rebuilt.current_chapter_runtime().make_objective_encounter().snapshot()),"pending exact replay")
  if not Flow.advance(c,branch):check(false,"advance "+token);break
  if event.op=="objective_battle":
   for id in [Party.LIU,Party.XIAOSHUANG]:check(c.actors[id].hp==prior_actors[id].hp and c.actors[id].mp==prior_actors[id].mp,"absent resources unchanged "+id)
  if event.id in ["evt_ch14_stone_lion_mastered","evt_ch14_temple_loadout_committed","evt_ch14_dawn_vow"] and c.actors[Party.HERO].xp==prior_actors[Party.HERO].xp:
   for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:
    check(c.actors[id].hp==prior_actors[id].hp and c.actors[id].mp==prior_actors[id].mp,"authorization does not heal "+id)
  if OS.get_environment("CH14_REPLAY_EVERY_EVENT")=="1":
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","event replay "+token+" "+error)
   if error!="":break
 check(c.state.finished,"complete actual chapter14")
 if c.state.finished:
  check(c.state.xp==xp+2105 and c.state.coins==coins+850,"exact rewards")
  check(Same.equivalent(old.char_axue,c.actors.char_axue),"dead Axue immutable")
  for id in olditems:check(Same.equivalent(olditems[id],c.items[id]),"historic item preserved "+id)
  check(c.actors[Party.LIU].status=="departed_chaoyun" and c.world_objects.ch13_liu_departure.can_rejoin_later,"Liu remains voluntarily departed alive")
  check(Same.equivalent(old[Party.LIU].equipment,c.actors[Party.LIU].equipment),"same Liu historic equipment")
  check(c.actors.animal_kuaixue.status=="dead" and c.world_objects.ch13_kuaixue.revivable==false,"prior donkey death preserved")
  check(c.actors.char_xiao_yuling.status=="dead" and c.world_objects.ch14_mother.cause=="both_palms","same mother identity, authored double-palm death")
  check(c.world_objects.ch14_xiao_leng.status=="dead" and c.world_objects.ch14_qianjue.alive,"Leng dead, Qianjue alive departed")
  check(c.state.leader_id==Party.XIAOSHUANG and c.actors[Party.XIAOSHUANG].status=="active","healer controls dawn")
  check(c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A05==3 and c.actors[Party.HERO].skill_ranks.LX_A05==1,"medical rank3 without premature tide rank2")
  check(c.actors[Party.HERO].skill_ranks.LX_P03==3 and c.actors[Party.HUASHENG].skill_ranks.HS_A05==1 and "CO_05" in c.state.knowledge,"calendar and temple permanent grants")
  check(not c.world_objects.ch14_party.burial_completed,"no premature chapter15 burial")
  var context:Dictionary=c.world_context()
  check("char_xiao_yuling" in context.dead_actor_ids and "npc_xiao_leng" in context.dead_actor_ids and Party.LIU in context.departed_actor_ids,"terminal projection never resurrects departed/dead")
  for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:check(c.actors[id].xp==c.state.xp,"core growth includes departed "+id)
  var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","bounded terminal "+str(prepared.error))
  if prepared.error=="":
   var rebuilt=Campaign.new(base);check(rebuilt.restore_persisted(prepared.payload)=="","bounded terminal restored")
   var output:String=OS.get_environment("CH14_TERMINAL_OUTPUT")
   if not output.is_empty():
    var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(prepared.payload));file.close()
 check(FileAccess.get_sha256(path)==source_sha,"source bytes unchanged")
 print("CH14 CAMPAIGN ",checks," checks ",failures," failures");quit(0 if failures==0 else 1)
