extends "res://tests/test_chapter_three.gd"
const Proof=preload("res://scripts/campaign/encounter_session.gd")
const WorldDriver=preload("res://tests/chapter_four_world_driver.gd")
const BattleDriver=preload("res://tests/chapter_four_battle_driver.gd")
var chapter_case:String=OS.get_environment("CH04_CASE")
var side_interleaved:=false
const Party=preload("res://scripts/campaign/party_progression.gd")
func intro(c: CampaignState) -> bool:
 var rt:ChapterRuntime=c.current_chapter_runtime()
 var e:=c.current_event();var token:=c.current_token()
 match e.op:
  "dialogue","stage","branch_feedback":return c.finish_dialogue(token)
  "choice":return c.choose(token,c.available_choices()[1 if chapter_case=="second" and c.available_choices().size()>1 else 0].id)
  "action":
   if e.has("requires_leader") and rt.state.leader_id!=e.requires_leader:rt.switch_leader(e.requires_leader)
   var p:Array=rt.maps[c.scene().map_id].actions[e.id].position
   var proof:Dictionary={"map_id":c.scene().map_id,"position":p}
   if e.kind=="route":
    var n:int=rt.maps[c.scene().map_id].paths[e.id].size()
    proof.merge({"index":n,"total":n,"complete":true})
   var accepted:bool=c.complete_action(token,e.id,proof)
   if accepted and e.id=="ride_route":check(Proof.equivalent(c.world_objects.ch04_spatial_state.horse_position,p),"same mounted horse reaches verified rider endpoint")
   return accepted
  "quest_window":return rt.complete(token,{"closure_acknowledged":true})
  "objective_battle":
   var session:=rt.make_objective_encounter()
   if session==null:return false
   var driver:=BattleDriver.new()
   if rt.state.scope=="R02":driver.r02_disarm(session)
   elif session.encounter.get("context",{}).get("environment_method")=="oil":driver.oil(session)
   else:driver.lamp(session)
   if not driver.errors.is_empty():print(driver.errors);return false
   return rt.complete(token,session.receipt())
  "world_puzzle":
   var session:=rt.make_puzzle()
   if session==null:return false
   for index in range(500):
    if c.current_token()!=token:return true
    var input:Dictionary=WorldDriver.next_input(session.get_view())
    if input.is_empty():print(session.get_view());return false
    rt.puzzle_input(token,input)
   return false
  "puzzle":
   var session:=rt.make_puzzle()
   if session==null:return false
   for index in range(200):
    if c.current_token()!=token:return true
    rt.puzzle_input(token,session.next_demo_action())
   return false
 return false
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c:CampaignState=Campaign.new(base)
 var fixture:="res://../output/cache/chapter_three_gui/manual_natural_final.json"
 if FileAccess.file_exists(fixture):check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","actual natural chapter3 migration")
 else:
  c=chapter_two_ending(true);c.enter_chapter_three()
  while not c.state.finished:
   if not act_three(c,16):check(false,"fallback chapter3");quit(1);return
 var hp:int=c.actors[Party.HERO].hp;var mp:int=c.actors[Party.HERO].mp;var xp:int=c.state.xp
 check(c.enter_registered_chapter(4),"registered chapter4 entry")
 check(c.actors[Party.HERO].hp==hp and c.actors[Party.HERO].mp==mp,"entry preserves resources")
 var steps:=0
 while c.current_event().op!="objective_battle":
  if not intro(c):check(false,"intro advances "+c.current_token());quit(1);return
  var copy:=Campaign.new(base)
  var error:=copy.restore(c.export_save())
  check(error=="","every intro event v4 replay "+c.current_token()+" "+error)
  if error!="":quit(1);return
  steps+=1
  if steps>100:check(false,"intro bounded");quit(1);return
 var natural_session:=c.current_chapter_runtime().make_objective_encounter()
 check(natural_session.set_command(Party.HERO,"guard_ally",Party.HERO)!="","actual hero cannot guard self")
 check(natural_session.set_command(Party.HERO,"guard_ally",Party.LIU)=="","actual hero guards teammate")
 check(natural_session.set_command(Party.LIU,"guard_ally",Party.HERO)=="","actual Liu guards teammate")
 check(c.actors[Party.LIU].xp==xp+300 and c.actors[Party.HERO].xp==xp+300,"both exact XP at encounter")
 check(c.state.coins==550,"pouch returned original balance")
 check(c.actors[Party.HERO].skill_ranks.LX_A01==2,"no old skill reset")
 while not c.state.finished:
  if c.current_event().op=="quest_window" and not c.current_event().get("deadline",false):
   for side in ["R02","L01"]:
    if c.state.optional[side].status=="archived":continue
    check(c.current_chapter_runtime().open_sidequest(side),"open "+side)
    while c.state.scope!="main":
     if chapter_case in ["residual","unfinished"] and side=="R02":
      var rt:=c.current_chapter_runtime()
      var should_pause:bool=c.current_event().op=="dialogue" if chapter_case=="residual" else c.current_event().op=="puzzle"
      if should_pause:
       if chapter_case=="unfinished":rt.puzzle_input(c.current_token(),rt.make_puzzle().next_demo_action())
       check(rt.pause_sidequest(),"leave R02 unarchived before deadline")
       break
     if chapter_case=="interleave" and side=="R02" and c.current_event().op=="puzzle" and not side_interleaved:
      var rt:=c.current_chapter_runtime()
      var puzzle:=rt.make_puzzle()
      rt.puzzle_input(c.current_token(),puzzle.next_demo_action())
      var partial:Dictionary=puzzle.snapshot()
      check(rt.pause_sidequest(),"pause partial R02")
      check(rt.open_sidequest("L01"),"interleave L01")
      while c.state.scope!="main":
       if not intro(c):check(false,"interleave L01 advances");quit(1);return
      check(rt.open_sidequest("R02"),"resume partial R02")
      check(Proof.equivalent(rt.make_puzzle().snapshot(),partial),"partial session exact across other reward")
      side_interleaved=true
     print("integrating side ",c.current_token())
     if not intro(c):check(false,"side advances "+c.current_token());quit(1);return
     var side_copy:=Campaign.new(base)
     var side_error:=side_copy.restore(c.export_save())
     check(side_error=="","side event replay "+c.current_token()+" "+side_error)
     if side_error!="":quit(1);return
  print("integrating ",c.current_token())
  if not intro(c):check(false,"full main advances "+c.current_token());quit(1);return
  var restored:=Campaign.new(base)
  var error:=restored.restore(c.export_save())
  check(error=="","full event replay "+c.current_token()+" "+error)
  if error!="":quit(1);return
 var expected:int=5415 if chapter_case in ["residual","unfinished"] else 5815
 check(c.state.xp==expected,"full chapter total actual "+str(c.state.xp))
 check(c.actors[Party.LIU].xp==expected,"both growth total")
 if chapter_case in ["residual","unfinished"]:
  check(c.state.optional.R02.disposition=="missed","unarchived side missed")
  check("LYY_A03" not in c.actors[Party.LIU].skills,"no unearned A03")
  check(c.items.item_ch04_liu_willow_hat.form==("repaired_by_r02" if chapter_case=="residual" else "torn_rim"),"actual repair residue retained")
 check(c.state.coins==550,"no invented coins")
 var saved:Dictionary=c.prepare_persisted_save()
 if saved.get("error","")=="":
  var f:=FileAccess.open("/tmp/kunlun-ch4-final-"+chapter_case+".json",FileAccess.WRITE)
  f.store_string(JSON.stringify(saved.payload));f.close()
 check(saved.get("error","")=="","terminal compact preparation "+str(saved.get("error")))
 print("Chapter four integration: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
