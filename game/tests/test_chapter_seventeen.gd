extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func run()->void:
 var source:=OS.get_environment("CH17_SOURCE")
 if source.is_empty() or not FileAccess.file_exists(source):push_error("CH17_SOURCE required (legal ch16 terminal)");quit(2);return
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
 for branch in range(2):
  var c=Campaign.new(base)
  if not check(c.restore_persisted(original)=="" and c.enter_registered_chapter(17),"chapter17 entry"):break
  var xp:int=c.actors.char_liang_xiao.xp;var steps=0
  for n in range(140):
   if c.state.finished:break
   var token:String=c.current_token();var event:Dictionary=c.current_event();var rt:RefCounted=c.current_chapter_runtime()
   print("CH17 ",branch," ",token)
   var before:Array=[c.actors.duplicate(true),c.items.duplicate(true),c.world_objects.duplicate(true),c.state.duplicate(true)]
   check(not rt.complete("expired",{}),"expired transaction rejected "+token)
   check(Same.equivalent(before,[c.actors,c.items,c.world_objects,c.state]),"failed transaction atomic "+token)
   if event.op=="action":check(not c.complete_action(token,event.id,{"map_id":c.scene().map_id,"position":[-1,-1]}),"no off-map click "+token)
   if event.op=="objective_battle":
    var session:RefCounted=rt.make_objective_encounter()
    if not check(session!=null,"canonical encounter "+event.id):break
    check(session.engine.entry_error=="","valid learned loadout "+event.id)
    check(not rt.accept_objective(token,{"victory":true}),"no success flag "+event.id)
   if not check(Driver.advance(c,branch,branch==0),"advance "+token):break
   steps+=1
  if not check(c.state.finished,"whole chapter route "+str(branch)):continue
  check(c.actors.char_liang_xiao.xp==xp+1150+(400 if branch==0 else 0),"exact once-only XP")
  check(c.actors.char_feng_lian.fixed_level==70 and not c.actors.char_feng_lian.has("xp"),"limited actor no core XP")
  check(c.actors.char_liu_yingying.status=="stays_tianshan" and c.actors.char_feng_lian.apprentice,"autonomous farewell/apprentice")
  check(c.actors.char_axue.status=="dead" and c.actors.char_xiao_yuling.status=="dead","no resurrection")
  check(not c.actors.char_liang_xiao.skill_ranks.has("LX_A08"),"no chapter19 skill early grant")
  check(c.items.item_ch17_tianfa.owner==Driver.H and c.items.item_ch17_tianfa.form=="unsheathed_blade","sword custody once")
  check(c.world_objects.ch17_amo.status=="dead","real boss terminal")
  check(c.state.optional.ch17_r07.status==("archived" if branch==0 else "missed"),"optional outcome")
  var saved:Dictionary=c.prepare_persisted_save()
  if check(saved.error=="","bounded terminal encode: "+str(saved.error)):
   var clone=Campaign.new(base);var error:String=clone.restore_persisted(saved.payload)
   check(error=="","terminal restore: "+error)
   if error=="":check(Same.equivalent([c.actors,c.items,c.world_objects],[clone.actors,clone.items,clone.world_objects]),"terminal projections unchanged")
   var directory:=OS.get_environment("KUNLUN_FIXTURE_DIR")
   if directory!="":
    var f:=FileAccess.open(directory+"/chapter_17_route_"+str(branch)+".json",FileAccess.WRITE);f.store_string(JSON.stringify(saved.payload));f.close()
  print("CH17 route ",branch," steps=",steps," xp=",c.actors.char_liang_xiao.xp)
 print("Chapter seventeen: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
