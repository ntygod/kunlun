extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const Summary=preload("res://scripts/campaign/chapter_eleven_summary.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"));var c=Campaign.new(base)
 var path:String=OS.get_environment("CH11_SOURCE")
 if path.is_empty():push_error("Set CH11_SOURCE to a verified command-generated chapter10 terminal; see chapter-eleven-campaign-contract.md");quit(1);return
 var raw:String=FileAccess.get_file_as_string(path)
 check(raw.sha256_text()=="36ee5c17f97abc183b135aba85d101f28a7d4beac500f00c200fbd5396a588cb" or not OS.get_environment("CH11_SOURCE").is_empty(),"documented automated10 fixture; not natural playthrough")
 check(c.restore_persisted(JSON.parse_string(raw))=="","formal chapter10 restore")
 var old:Dictionary=c.actors.duplicate(true);var olditems:Dictionary=c.items.duplicate(true);var oldxp:int=c.state.xp;var oldcoins:int=c.state.coins
 var side:bool=OS.get_environment("CH11_NO_SIDE")!="1";var branch:int=1 if OS.get_environment("CH11_BRANCH_B")=="1" else 0
 check(c.enter_registered_chapter(11),"chapter11 entry")
 if c.active_chapter!=11:quit(1);return
 check(Same.equivalent(old,c.actors) and Same.equivalent(olditems,c.items),"entry preserves identities/items/resources")
 for i in range(140):
  if c.state.finished:break
  var rt:RefCounted=c.current_chapter_runtime();var token:String=c.current_token();var e:Dictionary=c.current_event()
  print("CH11 ",token," ",e.id)
  var before:Dictionary=c.export_save()
  check(not rt.complete(token,{"success":true}) and Same.equivalent(before,c.export_save()),"forged proof atomic")
  if e.id=="evt_ch11_circulate_yin_yang":
   var hp:int=c.actors[Party.XIAOSHUANG].hp;var mp:int=c.actors[Party.XIAOSHUANG].mp
   if not Flow.advance(c,branch,side):check(false,"N02 explicit action");break
   check(c.actors[Party.XIAOSHUANG].hp==hp and c.actors[Party.XIAOSHUANG].mp==mini(mp,int(c.actors[Party.XIAOSHUANG].max_mp)),"N02 no hidden healing")
  else:
   if e.op in ["puzzle","world_puzzle"]:
    var model:RefCounted=rt.make_puzzle();check(model!=null,"actual puzzle "+e.id)
    if model==null:break
    var result:Dictionary=rt.puzzle_input(token,model.next_demo_action());check(result.get("ok",result.get("accepted",false)),"actual first command")
    var rebuilt=Campaign.new(base);var err:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
    check(err=="","partial input restore "+e.id+" "+err)
    if err!="":break
    check(Same.equivalent(model.snapshot(),rebuilt.current_chapter_runtime().make_puzzle().snapshot()),"partial replay identity")
    if e.id=="pz_ch11_r04_triage":
     check(rt.pause_sidequest(),"pause real partial triage")
     var paused:Dictionary=c.prepare_persisted_save();check(paused.error=="","paused R04 persists "+str(paused.error))
     check(rt.open_sidequest("R04"),"resume R04 in legal window")
   if e.op=="objective_battle":
    check(c.state.xp==oldxp+1625+(400 if side else 0),"actual preB07 main1625")
    check(not c.actors.has(Party.HUASHENG),"Huasheng not early combat recruit")
    var battle:RefCounted=rt.make_objective_encounter();check(battle!=null,"actual B07 config")
    if battle==null:break
    check(battle.set_command(Party.HERO,"self_guard",Party.HERO)=="","pending real hero command")
    check(rt.save_objective_checkpoint(battle),"partial twoactor commands saved")
    var rebuilt=Campaign.new(base);var err:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
    check(err=="","partial B07 restore "+err)
    if err!="":break
    check(Same.equivalent(battle.snapshot(),rebuilt.current_chapter_runtime().make_objective_encounter().snapshot()),"pending command round exact")
   if not Flow.advance(c,branch,side):check(false,"advance "+token);break
  if OS.get_environment("CH11_FAST")!="1":
   var rebuilt=Campaign.new(base);var err:String=rebuilt.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
   check(err=="","event replay "+token+" "+err)
   if err!="":break
 check(c.state.finished,"full chapter11 playable")
 if c.state.finished:
  check(c.state.xp==oldxp+3310+(400 if side else 0) and c.state.coins==oldcoins+700,"exact2910+400+optional400 and700copper")
  check(Same.equivalent(old.char_axue,c.actors.char_axue),"dead Axue entire historical panel unchanged")
  check(c.actors[Party.XIAOSHUANG].age==old[Party.XIAOSHUANG].age and c.actors[Party.XIAOSHUANG].story_injury==old[Party.XIAOSHUANG].story_injury,"same age/injury record")
  for id in olditems:check(Same.equivalent(olditems[id],c.items[id]),"inherited item intact "+id)
  for id in [Party.HERO,Party.LIU,Party.XIAOSHUANG,Party.HUASHENG]:check(c.actors[id].xp==c.state.xp,"recruited core synced "+id)
  check(c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A03==2 and c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A07==1 and c.actors[Party.XIAOSHUANG].skill_ranks.HXS_A06==1,"three source milestones")
  check(c.actors[Party.XIAOSHUANG].skills.has("HXS_A04")==side,"R04 optional early skill exact")
  check(c.actors.animal_kuaixue.kind=="noncombat_donkey" and not c.actors.animal_kuaixue.has("xp"),"donkey not inventory or growncore")
  var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","bounded terminal "+str(prepared.error))
  var terminal=Campaign.new(base);check(terminal.restore_persisted(prepared.payload)=="","bounded terminal reload")
  var forged:Dictionary=Summary.pack(c);forged.boundary_vitals.char_axue.hp+=1
  var rejecting=Campaign.new(base);rejecting.restore_persisted(JSON.parse_string(raw));check(Summary.apply(rejecting,forged)!="","dead vital forgery rejected")
  print("CH11_FINAL ",c.state.xp," XP / ",c.state.coins," copper; H ",c.actors[Party.HERO].hp,"/",c.actors[Party.HERO].max_hp," X ",c.actors[Party.XIAOSHUANG].hp,"/",c.actors[Party.XIAOSHUANG].max_hp)
 check(FileAccess.get_file_as_string(path)==raw,"source fixture untouched")
 print("Chapter eleven campaign: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
