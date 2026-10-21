extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"));var c=Campaign.new(base)
 var path:String=OS.get_environment("CH12_SOURCE")
 if path.is_empty():push_error("Explicit CH12_SOURCE command-generated chapter11 terminal required");quit(1);return
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","formal11 source restore")
 var old:Dictionary=c.actors.duplicate(true);var olditems:Dictionary=c.items.duplicate(true);var xp:int=c.state.xp;var coins:int=c.state.coins
 var side:bool=OS.get_environment("CH12_NO_SIDE")!="1";var branch:int=1 if OS.get_environment("CH12_BRANCH_B")=="1" else 0
 check(c.enter_registered_chapter(12),"enter12")
 if c.active_chapter!=12:quit(1);return
 check(Same.equivalent(old,c.actors) and Same.equivalent(olditems,c.items),"entry does not heal/equip/recruit")
 for i in range(240):
  if c.state.finished:break
  var rt:RefCounted=c.current_chapter_runtime();var event:Dictionary=c.current_event();var token:String=c.current_token()
  print("CH12 ",token," ",event.id)
  var before:Dictionary=c.export_save()
  var prior_actors:Dictionary=c.actors.duplicate(true)
  var battle_members:Array=rt.battle_actor_ids() if event.op=="objective_battle" else []
  check(not rt.complete(token,{"success":true}) and Same.equivalent(before,c.export_save()),"forged proof atomic")
  if event.op in ["puzzle","world_puzzle"]:
   var model:RefCounted=rt.make_puzzle();check(model!=null,"actual model "+event.id)
   if model==null:break
   var result:Dictionary=rt.puzzle_input(token,model.next_demo_action());check(result.get("ok",result.get("accepted",false)),"first real command")
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","partial proof replay "+event.id+" "+error)
   if error!="":break
   check(Same.equivalent(model.snapshot(),rebuilt.current_chapter_runtime().make_puzzle().snapshot()),"partial exact replay")
  if event.op=="objective_battle":
   if event.id=="enc_ch12_han_duel":check(c.state.xp==xp+1745+(400 if side else 0),"first duel exact XP gate")
   if event.id=="enc_ch12_chiyou_medicine":check(c.state.xp==xp+5415+(400 if side else 0),"B09 exact XP gate")
   var session:RefCounted=rt.make_objective_encounter();check(session!=null,"canonical battle "+event.id)
   if session==null:break
   var members:Array=rt.battle_actor_ids();check(session.set_command(members[0],"self_guard",members[0])=="","actual pending command")
   check(rt.save_objective_checkpoint(session),"independent checkpoint "+event.id)
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","battle pending restore "+error)
   if error!="":break
   check(Same.equivalent(session.snapshot(),rebuilt.current_chapter_runtime().make_objective_encounter().snapshot()),"pending commands preserved")
  if not Flow.advance(c,branch,side):check(false,"advance "+token);break
  if event.op=="objective_battle":
   for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:
    if id not in battle_members:check(c.actors[id].hp==prior_actors[id].hp and c.actors[id].mp==prior_actors[id].mp,"battle leaves absent resources unchanged "+id)
  if OS.get_environment("CH12_FAST")!="1":
   var rebuilt=Campaign.new(base);var error:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(error=="","event replay "+token+" "+error)
   if error!="":break
 check(c.state.finished,"complete actual chapter12")
 if c.state.finished:
  check(c.state.xp==xp+7340+(400 if side else 0) and c.state.coins==coins+750,"exact main encounter optional budgets")
  check(Same.equivalent(old.char_axue,c.actors.char_axue),"dead Axue immutable")
  for id in olditems:check(Same.equivalent(olditems[id],c.items[id]),"historic item intact "+id)
  check(Same.equivalent(old[Party.LIU].equipment,c.actors[Party.LIU].equipment),"same Liu old equipment")
  check(c.actors[Party.HUASHENG].status=="staying_with_patients" and c.world_objects.ch12_party.members==[Party.HERO,Party.XIAOSHUANG,Party.LIU],"no unauthored Huasheng reunion")
  check(c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A05==2 and c.actors[Party.HERO].skill_ranks.LX_A04==2,"source skill endpoints")
  for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:check(c.actors[id].xp==c.state.xp,"core progression "+id)
  var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","bounded terminal "+str(prepared.error))
  if prepared.error=="":
   var rebuilt=Campaign.new(base);check(rebuilt.restore_persisted(prepared.payload)=="","bounded terminal restored")
   var output:String=OS.get_environment("CH12_TERMINAL_OUTPUT")
   if not output.is_empty():
    var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(prepared.payload));file.close()
 print("CH12 CAMPAIGN ",checks," checks ",failures," failures");quit(0 if failures==0 else 1)
