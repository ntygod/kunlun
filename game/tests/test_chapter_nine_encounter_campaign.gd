extends "res://tests/test_chapter_nine_encounter.gd"
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
func run():
 setup()
 for source in ["user://chapter_nine_minimum_source.json","res://../output/cache/chapter_eight_gui/manual_natural_final.json"]:
  var base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
  var c=Campaign.new(base)
  check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","real chapter8 restore")
  var old_mp:int=c.actors[H].mp
  check(c.enter_registered_chapter(9),"chapter9 entered")
  var saw_rest:=false
  for index in range(300):
   if c.current_event().id=="enc_ch09_well_disarm":break
   var e:Dictionary=c.current_event()
   var prior:Dictionary=c.actors.duplicate(true)
   check(Flow.advance(c,false),"real chapter9 advance "+e.id)
   if e.id=="evt_ch09_blood_well_rest":
    saw_rest=true
    check(c.actors[H].hp==c.actors[H].max_hp and c.actors[H].mp==prior[H].mp,"explicit living hero HP only rest")
    check(Compare.equivalent(c.actors.char_axue,prior.char_axue) and Compare.equivalent(c.actors.char_liu_yingying,prior.char_liu_yingying),"rest never heals/rebuilds Axue or absent Liu")
  check(saw_rest and c.current_event().id=="enc_ch09_well_disarm","reach actual blood well")
  if c.current_event().id!="enc_ch09_well_disarm":continue
  var rt:RefCounted=c.current_chapter_runtime();var token:String=c.current_token()
  var s:RefCounted=rt.make_objective_encounter()
  check(s!=null,"actual context accepted")
  if s==null:continue
  var entrance:Dictionary=s.snapshot();var xp:int=c.state.xp
  check(s.final_party()[0].mp==old_mp and s.final_party()[0].hp==c.actors[H].max_hp,"all prior chapter9 path preserves real MP")
  check(Driver.step(s,"wait","well_soldier_1") and Driver.step(s,"wait","well_soldier_1"),"actual mistake damage")
  check(rt.save_objective_checkpoint(s),"persist real damaged checkpoint")
  var save:Dictionary=c.prepare_persisted_save();check(save.error=="","campaign damaged save validates")
  var restored=Campaign.new(base);check(restored.restore_persisted(save.payload)=="","campaign damaged save restore")
  var continued:RefCounted=restored.current_chapter_runtime().make_objective_encounter()
  check(continued!=null and Compare.equivalent(continued.snapshot(),s.snapshot()),"campaign restores exact damage and round")
  s.retry()
  check(Compare.equivalent(entrance,s.snapshot()),"actual entrance retry exact")
  check(c.state.xp==xp and rt.state.rest_receipts.count("evt_ch09_blood_well_rest")==1,"retry no XP/repeated rest")
  var damage=maxi(1,int(floor(169.0*Session.Core.K/(Session.Core.K+float(s.initial_party[0].def)))))
  var hits:=0
  while s.final_party()[0].hp>damage:
   check(Driver.step(s,"wait","well_soldier_1") and Driver.step(s,"wait","well_soldier_1"),"legal low resources from repeated mistakes")
   hits+=1
  var lowest:int=s.final_party()[0].hp
  check(lowest>0 and lowest<=damage and Driver.run(s),"reachable low health then four zero-damage actions")
  var receipt:Dictionary=s.receipt()
  check(rt.accept_objective(token,receipt),"campaign accepts actual nonlethal proof")
  check(c.actors[H].hp==lowest and c.actors[H].mp==old_mp,"campaign consumes only verified HP/MP")
  check(not rt.accept_objective(token,receipt),"repeat old completion token rejects")
  check(c.state.xp==xp,"encounter itself no hidden reward")
  var reward_token:String=c.current_token()
  check(c.current_event().id=="evt_ch09_well_disarm_complete" and Flow.advance(c,false),"unique300 transaction")
  check(c.state.xp==xp+300 and c.reward_ledger.get("reward_mq09_well_encounter_once")==300,"exact once300")
  check(not c.finish_dialogue(reward_token) and c.state.xp==xp+300,"repeating transaction no300")
  check(c.world_objects.ch09_well_soldiers.lethal_kills==0,"nonlethal world result")
  print("CH09_ACTUAL_WELL source=",source," entrance=",entrance.initial_party[0].hp,"HP/",old_mp,"MP damage=",damage," hits=",hits," low=",lowest,"XP=",xp,"->",c.state.xp)
 print("Chapter nine encounter campaign: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
