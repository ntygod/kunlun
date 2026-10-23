extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_sixteen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
var base:Dictionary
func _initialize()->void:call_deferred("run")
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(note)
func run()->void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var path:=OS.get_environment("CH16_SOURCE")
 if path.is_empty() or not FileAccess.file_exists(path):push_error("CH16_SOURCE model/natural chapter15 terminal required; not a pass");quit(2);return
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 for branch in [0,1]:
  var c:=Campaign.new(base);var restored:String=c.restore_persisted(source)
  check(restored=="","chapter15 source restores: "+restored)
  if restored!="":break
  var before:Dictionary=c.actors.duplicate(true);var old_items:Dictionary=c.items.duplicate(true);var xp:int=c.actors.char_liang_xiao.xp
  check(c.enter_registered_chapter(16),"real chapter15 ->16 entry")
  for step in range(128):
   if c.state.finished:break
   var e:Dictionary=c.current_event();var rt:RefCounted=c.current_chapter_runtime()
   var pre:Dictionary=c.export_save()
   check(not rt.complete("stale",{}),"stale callback rejected")
   if e.op in ["puzzle","objective_battle"]:check(not rt.complete(c.current_token(),{"success":true}),"no success flag bypass")
   check(Same.equivalent(pre,c.export_save()),"rejected callback leaves save identical")
   if e.op=="choice" and e.choice_key=="statue_echo" and branch==0:
    check(c.available_choices().size()==1 and c.available_choices()[0].id=="statue_echo_equation","no bamboo choice without actual bamboo")
   if e.op=="action":
    check(not rt.complete(c.current_token(),{"map_id":c.scene().map_id,"position":[-1,-1]}),"unspawned action rejected")
   if e.op=="puzzle":
    var session:RefCounted=rt.make_puzzle()
    check(session!=null,"puzzle is registered "+e.id)
    if session==null:break
    check(rt.puzzle_input(c.current_token(),{"type":"hint"}).ok,"hint is real replayable input")
    check(rt.puzzle_input(c.current_token(),Driver.puzzle_action(session)).ok,"partial puzzle actual input")
    var saved:Dictionary=c.prepare_persisted_save()
    check(saved.error=="","partial save encodes")
    var clone:=Campaign.new(base);var error:String=clone.restore_persisted(saved.payload)
    check(error=="","partial save strictly restores: "+error)
    if error!="":break
    check(Same.equivalent(session.snapshot(),clone.current_chapter_runtime().make_puzzle().snapshot()),"partial puzzle exact state")
   if e.op=="objective_battle":
    var session:RefCounted=rt.make_objective_encounter()
    check(session!=null,"solo encounter constructs")
    if session==null:
     var config:Dictionary=load(rt.ENGINE_SCRIPT).encounter_config();config.context=rt.puzzle_context()
     var debug:RefCounted=load(rt.ENGINE_SCRIPT).new(c.rules,c.combat);debug.start(config,rt.combat_party());print(debug.entry_error);break
    var cmd:=Driver.command(session)
    check(session.set_command(cmd.actor,cmd.skill,cmd.target)=="","pending battle command accepted")
    check(rt.save_objective_checkpoint(session),"pending checkpoint validated")
    var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","pending battle save encodes")
    var clone:=Campaign.new(base);var error:String=clone.restore_persisted(saved.payload)
    check(error=="","pending battle restores: "+error)
    if error!="":break
    check(Same.equivalent(session.snapshot(),clone.current_chapter_runtime().make_objective_encounter().snapshot()),"pending battle exact state")
    check(rt.battle_actor_ids()==["char_liang_xiao"],"no eastern party/temporary companion in combat")
   var advanced:=Driver.advance(c,branch)
   check(advanced,"normal command advances "+e.id)
   if not advanced:print("STOP ",c.current_token()," ",e);break
  check(c.state.finished,"chapter16 entire main route completes")
  if not c.state.finished:continue
  check(int(c.actors.char_liang_xiao.xp)==xp+2255,"MQ16 exact once-only 2255XP")
  check(c.actors.char_liang_xiao.skill_ranks.LX_A06==1,"rank1 at river source, no future rank")
  check(c.state.liang_age==int(before.char_liang_xiao.age)+10,"three plus seven years exactly once")
  check(c.actors.char_axue==before.char_axue,"Axue remains dead and unchanged")
  check(c.actors.char_liang_wenjing==before.char_liang_wenjing,"Wenjing remains dead unchanged")
  check(c.actors.char_xiao_yuling==before.char_xiao_yuling,"Yuling remains dead unchanged")
  check(c.world_objects.ch16_fire_meteor.custodian=="char_feng_lian","horse gifted to Feng")
  check(c.actors.char_feng_lian.status=="stayed_sword_valley" and c.actors.char_feng_lian.kind=="exploration_only","Feng is not recruited into battle")
  check(c.world_objects.ch16_ranya.status=="stayed_malaga","Ranya remains in Malaga")
  for item in old_items:check(c.items[item]==old_items[item],"prior item preserved "+item)
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","terminal bounded save encodes: "+saved.error)
  var clone:=Campaign.new(base);var error:String=clone.restore_persisted(saved.payload)
  check(error=="","terminal bounded summary restores: "+error)
  if error=="":
   check(Same.equivalent(c.actors,clone.actors),"terminal actor state identical")
   check(Same.equivalent(c.items,clone.items),"terminal inventory identical")
   check(Same.equivalent(c.world_objects,clone.world_objects),"terminal world identical")
   var bad:Dictionary=saved.payload.duplicate(true);bad.archive[-1].boundary_vitals.char_liang_xiao.hp=999999
   var prior:Dictionary=clone.export_save();check(clone.restore_persisted(bad)!="","forged terminal resources rejected");check(Same.equivalent(prior,clone.export_save()),"bad load does not mutate live campaign")
  var out:=OS.get_environment("KUNLUN_FIXTURE_DIR")
  if not out.is_empty() and saved.error=="":
   var file:=FileAccess.open(out+"/chapter_16_branch_%d.json"%branch,FileAccess.WRITE);file.store_string(JSON.stringify(saved.payload));file.close()
 print("Chapter sixteen: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
