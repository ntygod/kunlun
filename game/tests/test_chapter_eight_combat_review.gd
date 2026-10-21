extends "res://tests/test_chapter_eight_combat.gd"
func run():
 setup();var d=Driver.new(check)
 var p=party(["LX_P03"]);p[0].erase("acquired_passives")
 check(session("ballista_objective",p).engine.entry_error!="","missing acquisition is not grant")
 for invalid in [null,true,1,[],{},["LX_P04"],["LX_P03","LX_P03"]]:
  p=party(["LX_P03"]);p[0].acquired_passives=invalid
  check(session("ballista_objective",p).engine.entry_error!="","malformed acquisition rejected")
 var s=session();d.ballista(s);var before=s.snapshot()
 for key in before:
  var bad=before.duplicate(true);bad.erase(key);bad.unexpected=[]
  check(not s.restore(bad),"missing required snapshot "+key)
  check(Compare.equivalent(before,s.snapshot()),"missing key rejection atomic")
 for value in [true,1,1.0,"x",null,[]]:
  check(not s.resume_phase_two({"fire_confirmed":true,"l04":value},"p2"),"bad L04 type rejected before mutation")
  check(Compare.equivalent(before,s.snapshot()),"bad resume atomic")
  check(not s.resume_phase_two(value,"p2"),"bad context outer shape")
  check(not s.sync_campaign_actor(value),"bad sync actor outer shape")
  check(not s.sync_campaign_context(value),"bad sync context outer shape")
  check(not s.engine.resume_phase_two(value),"engine resume outer shape")
  check(not s.engine.sync_campaign_actor(value),"engine actor sync outer shape")
  check(not s.engine.sync_campaign_context(value),"engine context sync outer shape")
  if not value is String:check(not s.resume_phase_two({"fire_confirmed":true},value),"bad attempt type")
 check(not s.resume_phase_two({"fire_confirmed":true},""),"empty attempt rejected")
 var bad=before.duplicate(true);bad.state.objective.medicine_uses=1
 check(not s.restore(bad),"nonzero medicine state rejects")
 # Real world movement can exceed the per-round edit limit; it belongs to the
 # bounded campaign history, never the next combat turn's command budget.
 for i in range(180):check(s.sync_campaign_context({"l04":{"status":"active","progress":{"move":i,"position":[i%8,2]}}}),"bounded context step")
 check(s.history.size()>128,"long intermission preserves audit history")
 check(s.resume_phase_two({"fire_confirmed":true,"l04":{"status":"archived"}},"p2"),"long intermission resumes")
 check(s.get_view().objective.input_budget.command_remaining==128,"fresh phase2 player edit budget")
 var checkpoint=s.snapshot();d.escort(s)
 check(s.engine.state.outcome=="victory","long intermission allows all actual escort actions")
 var restored=Session.from_snapshot(s.snapshot(),rules,runtime)
 check(restored!=null,"long middle replay retains full proof")
 var config=data.encounters.enc_ch08_civilian_escort.duplicate(true);config.context={"campaign_checkpoint":checkpoint}
 check(not Session.replay_receipt(s.receipt(),rules,runtime,config,s.initial_party).is_empty(),"long trusted prefix accepted")
 var names=session();d.ballista(names)
 var named_context:Dictionary={"fire_confirmed":true,"l04":{"status":&"archived"},&"world_objects":{&"earned_rewards":{},&"skill_ranks":{&"LX_A02":3}}}
 check(names.resume_phase_two(named_context,"named_p2"),"real StringName context supported")
 check(Session.from_snapshot(JSON.parse_string(JSON.stringify(names.snapshot())),rules,runtime)!=null,"StringName JSON process normalization")
 print("Chapter eight combat independent-review fixes: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
