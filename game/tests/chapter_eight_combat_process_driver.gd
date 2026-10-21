extends "res://tests/test_chapter_eight_combat.gd"
func run():
 setup();var d=Driver.new(check)
 var file="user://chapter_eight_combat_snapshots.json"
 if OS.get_environment("CH08_REPLAY_MODE")=="write":
  var s=session();var cases:Array=[]
  d.input(s,"inspect_hub","left_gear");cases.append({"name":"phase1_queued","snapshot":s.snapshot()});d.resolve(s)
  d.input(s,"release_calibrated_shot","left_gear");d.resolve(s)
  for hub in ["center_pin","right_string"]:
   d.input(s,"inspect_hub",hub);d.resolve(s);d.input(s,"release_calibrated_shot",hub);d.resolve(s)
  cases.append({"name":"world_intermission","snapshot":s.snapshot()})
  var grown:Dictionary=party()[0];grown.max_hp+=27;grown.hp+=27;grown.max_mp+=2;grown.mp=120;grown.atk+=4;grown.def+=2
  s.sync_campaign_actor(grown);cases.append({"name":"growth_in_intermission","snapshot":s.snapshot()})
  s.resume_phase_two({"fire_confirmed":true,"l04":{"status":"archived"}},"phase2token")
  cases.append({"name":"phase2_checkpoint","snapshot":s.snapshot()})
  for i in range(3):
   d.input(s,"lead_batch");d.resolve(s);cases.append({"name":"batch_%d_crossing"%i,"snapshot":s.snapshot()})
   d.input(s,"escort_intercept");d.resolve(s);cases.append({"name":"batch_%d_protected"%i,"snapshot":s.snapshot()})
   d.command(s,"sancai_counter","routed_pressure");cases.append({"name":"batch_%d_queued_counter"%i,"snapshot":s.snapshot()});d.resolve(s)
  cases.append({"name":"completed","snapshot":s.snapshot()})
  var f=FileAccess.open(file,FileAccess.WRITE);f.store_string(JSON.stringify(cases));f.close()
 else:
  var cases:Array=JSON.parse_string(FileAccess.get_file_as_string(file))
  for case in cases:
   var s=Session.from_snapshot(case.snapshot,rules,runtime)
   check(s!=null,"fresh process restores "+case.name)
   if s==null:continue
   check(Compare.equivalent(s.snapshot(),case.snapshot),"exact resources/CD/P03/routes "+case.name)
   for field in ["pressure","p03_stacks","phase_round","medicine_uses"]:
    var corrupt=case.snapshot.duplicate(true);corrupt.state.objective[field]=999
    var before=s.snapshot();check(not s.restore(corrupt),"reject tampered "+field)
    check(Compare.equivalent(before,s.snapshot()),"reject atomic")
   if s.engine.state.objective.phase=="phase_two":
    var bad=case.snapshot.duplicate(true)
    for step in bad.history:
     if step.op=="sync":step.actor.hp+=1;break
    check(not s.restore(bad),"sync/history mismatch rejected")
 print("Chapter eight independent process ",OS.get_environment("CH08_REPLAY_MODE"),": ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
