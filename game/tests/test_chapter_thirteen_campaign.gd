extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_thirteen_campaign_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"));var c=Campaign.new(base)
 var path:String=OS.get_environment("CH13_SOURCE")
 if path.is_empty():push_error("Explicit CH13_SOURCE verified chapter12 terminal required");quit(1);return
 var source_sha:=FileAccess.get_sha256(path)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","formal12 source restore")
 check(c.active_chapter==12 and c.state.finished,"source is actually archived12, not inferred from filename")
 var old:Dictionary=c.actors.duplicate(true);var olditems:Dictionary=c.items.duplicate(true);var xp:int=c.state.xp;var coins:int=c.state.coins
 var branch:int=1 if OS.get_environment("CH13_BRANCH_B")=="1" else 0
 check(c.enter_registered_chapter(13),"enter13")
 if c.active_chapter!=13:quit(1);return
 check(Same.equivalent(old,c.actors) and Same.equivalent(olditems,c.items),"entry preserves actor injury equipment items")
 for i in range(280):
  if c.state.finished:break
  var rt:RefCounted=c.current_chapter_runtime();var event:Dictionary=c.current_event();var token:String=c.current_token()
  print("CH13 ",token," ",event.id)
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
   check(c.state.xp==xp+1985,"B10 exact gate main485 plus ship1500")
   check(rt.battle_actor_ids()==[Party.HERO],"solo hero not offscreen allies")
   var session:RefCounted=rt.make_objective_encounter();check(session!=null,"canonical B10")
   if session==null:break
   check(session.set_command(Party.HERO,"self_guard",Party.HERO)=="","actual unresolved command")
   check(rt.save_objective_checkpoint(session),"battle checkpoint")
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","battle pending restore "+error)
   if error!="":break
   check(Same.equivalent(session.snapshot(),rebuilt.current_chapter_runtime().make_objective_encounter().snapshot()),"pending exact replay")
  if not Flow.advance(c,branch):check(false,"advance "+token);break
  if event.op=="objective_battle":
   for id in [Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:check(c.actors[id].hp==prior_actors[id].hp and c.actors[id].mp==prior_actors[id].mp,"absent resources unchanged "+id)
  if event.id in ["evt_ch13_whale_breath_learned","evt_ch13_sisters_reconciled","evt_ch13_loadout_committed"] and c.actors[Party.HERO].xp==prior_actors[Party.HERO].xp:
   for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:
    check(c.actors[id].hp==prior_actors[id].hp and c.actors[id].mp==prior_actors[id].mp,"authorization does not heal "+id)
  if OS.get_environment("CH13_REPLAY_EVERY_EVENT")=="1":
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","event replay "+token+" "+error)
   if error!="":break
 check(c.state.finished,"complete actual chapter13")
 if c.state.finished:
  check(c.state.xp==xp+4030 and c.state.coins==coins+800,"exact rewards")
  check(Same.equivalent(old.char_axue,c.actors.char_axue),"dead Axue immutable")
  for id in olditems:check(Same.equivalent(olditems[id],c.items[id]),"historic item preserved "+id)
  check(c.actors[Party.LIU].status=="departed_chaoyun" and c.world_objects.ch13_liu_departure.can_rejoin_later,"Liu departs voluntarily alive")
  check(Same.equivalent(old[Party.LIU].equipment,c.actors[Party.LIU].equipment),"same Liu historic equipment")
  check(c.actors.animal_kuaixue.status=="dead" and c.world_objects.ch13_kuaixue.revivable==false,"authored donkey death")
  check(c.actors[Party.HERO].internal_skill=="LX_N02" and c.actors[Party.LIU].internal_skill=="LYY_N02" and "CO_03" in c.state.knowledge,"new authorized internals and sisters combo")
  check(c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A03==3 and c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A05==2,"medical skill endpoints")
  for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:check(c.actors[id].xp==c.state.xp,"core growth includes departed "+id)
  var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","bounded terminal "+str(prepared.error))
  if prepared.error=="":
   var rebuilt=Campaign.new(base);check(rebuilt.restore_persisted(prepared.payload)=="","bounded terminal restored")
   var output:String=OS.get_environment("CH13_TERMINAL_OUTPUT")
   if not output.is_empty():
    var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(prepared.payload));file.close()
 check(FileAccess.get_sha256(path)==source_sha,"source bytes unchanged")
 print("CH13 CAMPAIGN ",checks," checks ",failures," failures");quit(0 if failures==0 else 1)
