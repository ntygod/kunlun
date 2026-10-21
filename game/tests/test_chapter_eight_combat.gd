extends SceneTree
const Session=preload("res://scripts/combat/chapter_eight_encounter.gd")
const Driver=preload("res://tests/chapter_eight_battle_driver.gd")
const Compare=preload("res://scripts/campaign/encounter_session.gd")
const H="char_liang_xiao"
var checks:=0
var failures:=0
var rules:Dictionary
var runtime:Dictionary
var data:Dictionary
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error("FAIL "+message)
func setup():
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"));data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_eight_encounters.json"))
func party(passives:Array=["LX_P01","LX_P03"]) -> Array:
 return [{"id":H,"name":"梁萧","team":"party","hp":1127,"mp":1,"max_hp":1127,"max_mp":132,"atk":178,"def":111,"spd":40,"skills":["normal_attack","self_guard","observe","sancai_counter","LX_A03"],"skill_ranks":{"LX_A01":2,"observe":2,"LX_A02":3,"LX_A03":1},"passives":passives,"acquired_passives":["LX_P01","LX_P02","LX_P03"],"internal_skill":""}]
func session(kind:String="ballista_objective",p:Array=[]) -> RefCounted:
 return Session.new(rules,runtime,data.encounters["enc_ch08_"+kind],party() if p.is_empty() else p,"test:"+kind)
func run():
 setup();var d=Driver.new(check)
 for route in ["cover","sancai","flystar"]:
  var r=session("river_duel");d.river(r,route)
  check(r.engine.state.outcome=="victory" and r.engine.state.round==7,"river actual six rounds "+route)
  check(r.engine.actor_by_id("river_yunshu").hp>=1 and r.engine.state.objective.river_path==[[0,0],[1,0],[2,0],[3,0]],"nonlethal retreat path")
  check(not Session.replay_receipt(r.receipt(),rules,runtime,r.encounter,r.initial_party).is_empty(),"river replay "+route)
 var s=session();var before=s.snapshot()
 for bad in [true,false,1.0,1.9,"1",null,[],{},-2]:
  check(s.callv("set_command",[H,"observe","ballista",bad])!="","strict public command revision")
  check(s.engine.callv("set_command",[H,"observe","ballista",bad])!="","strict engine command revision too")
  check(not s.apply_input({"actor_id":H,"action_id":"inspect_hub","value":"left_gear","revision":bad}).accepted,"strict input revision")
  check(Compare.equivalent(before,s.snapshot()),"malformed types atomic")
 for bad in [true,1,1.0,null,[],{}]:
  check(not s.apply_input(bad).accepted and not s.restore(bad),"outer variants rejected")
  for n in range(3):
   var args:Array=[H,"observe","ballista",1];args[n]=bad
   check(s.callv("set_command",args)!="","command strings strict")
 check(not s.apply_input({"actor_id":H,"action_id":"release_calibrated_shot","value":"left_gear"}).accepted,"uninspected shot rejects")
 check(s.set_command(H,"LX_A03","ballista")!="" and s.set_command(H,"normal_attack","ballista")!="","distance blocks melee before spend")
 d.input(s,"inspect_hub","left_gear");d.resolve(s);d.input(s,"release_calibrated_shot","left_gear");d.resolve(s)
 check(s.engine.state.objective.p03_stacks==1 and s.engine.actor_by_id(H).mp==132,"structure gives layer not MP")
 check(not s.apply_input({"actor_id":H,"action_id":"inspect_hub","value":"left_gear"}).accepted,"destroyed hub unavailable")
 d.input(s,"inspect_hub","center_pin");d.resolve(s)
 check(s.engine.actor_by_id(H).hp==1127,"round2 break cancels pending shot3")
 d.input(s,"release_calibrated_shot","center_pin");d.resolve(s)
 d.input(s,"inspect_hub","right_string");d.resolve(s);d.input(s,"release_calibrated_shot","right_string");d.resolve(s)
 check(s.engine.state.objective.phase=="intermission" and s.engine.state.objective.p03_stacks==3,"three disarms capped")
 check(s.sync_campaign_context({"l04":{"status":"active","progress":{"method":"support","rescued":["child"]}}}),"bounded L04 progress sync")
 var prior=s.snapshot()
 check(s.sync_campaign_context({"l04":{"status":"active","progress":{"method":"support","rescued":["child"]}}}) and Compare.equivalent(prior,s.snapshot()),"same context true noop")
 check(Session.replay_receipt(s.receipt(),rules,runtime,s.encounter,s.initial_party).is_empty(),"phase1 receipt forbids injected world sync or context")
 var pause=s.snapshot();var clone=Session.from_snapshot(pause,rules,runtime)
 check(clone!=null and Compare.equivalent(clone.snapshot(),pause),"paused restore exact")
 var old=s.engine.actor_by_id(H).duplicate(true)
 var grown=party()[0];grown.max_hp+=27;grown.hp=old.hp+27;grown.max_mp+=2;grown.mp=old.mp;grown.atk+=4;grown.def+=2
 check(s.sync_campaign_actor(grown),"legitimate middle growth")
 check(s.engine.actor_by_id(H).hp==1154 and s.engine.actor_by_id(H).mp==132 and s.engine.state.round==7,"growth difference no MP refill/no round")
 check(s.resume_phase_two({"fire_confirmed":false},"p2")==false,"requires fire confirmation")
 check(s.resume_phase_two({"fire_confirmed":true,"l04":{"status":"archived"}},"p2"),"resume same battle")
 check(not s.resume_phase_two({"fire_confirmed":true},"p2again"),"one checkpoint only")
 var checkpoint=s.snapshot()
 check(not s.engine.actor_by_id("routed_pressure").has("hp") and not s.engine.actor_by_id("routed_pressure").has("max_hp"),"pressure carrier has no organism HP")
 d.input(s,"lead_batch");d.resolve(s);d.command(s,"normal_attack","routed_pressure");d.resolve(s)
 check(s.engine.state.outcome=="defeat" and s.engine.state.objective.pressure==3800,"unprotected exposure fails without death narrative")
 s.retry();check(Compare.equivalent(s.snapshot(),checkpoint),"retry exact confirmed phase2 entry")
 d.escort(s)
 check(s.engine.state.outcome=="victory" and s.engine.state.objective.pressure==0,"all three routes+disarms win")
 check(s.receipt().phase_attempt_id=="p2","phase-specific proof token")
 var conf:Dictionary=data.encounters.enc_ch08_civilian_escort.duplicate(true);conf.context={"campaign_checkpoint":checkpoint}
 check(not Session.replay_receipt(s.receipt(),rules,runtime,conf,s.initial_party).is_empty(),"trusted prefix receipt")
 var corrupt=s.receipt();corrupt.commands[0].input.value="right_string"
 check(Session.replay_receipt(corrupt,rules,runtime,conf,s.initial_party).is_empty(),"tampered prefix rejected")
 for slots in [["LX_P01","LX_P02","LX_P03"],["LX_P03","LX_P03"],["fake"]]:check(session("ballista_objective",party(slots)).engine.entry_error!="","invalid passive slots")
 for slots in [[],["LX_P03"],["LX_P01","LX_P02"]]:
  var t=session("ballista_objective",party(slots));d.ballista(t)
  check(t.engine.state.objective.p03_stacks==(3 if "LX_P03" in slots else 0),"only equipped P03 stacks")
  check(t.resume_phase_two({"fire_confirmed":true},"second"),"resume slot variant");d.escort(t)
  check(t.engine.state.outcome=="victory","minimum no N01 slot variant viable")
 print("Chapter eight combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
