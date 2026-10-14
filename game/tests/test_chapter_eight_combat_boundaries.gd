extends "res://tests/test_chapter_eight_combat.gd"
func run():
 setup();var d=Driver.new(check)
 # Delay the first shot to round3: one actual arrow before a later action is not
 # hidden behind a normal attack. Defend changes only damage, not objective.
 var delayed=session();d.input(delayed,"inspect_hub","left_gear");d.resolve(delayed)
 d.command(delayed,"self_guard",H);d.resolve(delayed)
 d.command(delayed,"self_guard",H);d.resolve(delayed)
 check(delayed.engine.actor_by_id(H).hp==931,"38K giant arrow applies DEF and35% once")
 d.input(delayed,"release_calibrated_shot","left_gear");d.resolve(delayed)
 d.input(delayed,"inspect_hub","center_pin")
 var before=delayed.snapshot()
 check(not delayed.apply_input({"actor_id":H,"action_id":"release_calibrated_shot","value":"center_pin"}).accepted,"protect round prevents fire")
 check(Compare.equivalent(before,delayed.snapshot()),"rejected protected shot atomic")
 d.resolve(delayed);d.input(delayed,"release_calibrated_shot","center_pin");d.resolve(delayed)
 d.input(delayed,"inspect_hub","right_string");d.resolve(delayed);d.input(delayed,"release_calibrated_shot","right_string");d.resolve(delayed)
 check(delayed.engine.state.objective.phase=="intermission","delayed six objectives still pass")
 # Explicit pure combat stress fixture: no coins interface and 0MP at paused
 # phase2 entrance. This is NOT represented as a legal historical campaign save.
 var low=session("ballista_objective",party([]));d.ballista(low)
 var a=party([])[0];a.mp=0
 check(low.sync_campaign_actor(a),"unit low MP paused sync")
 check(low.resume_phase_two({"fire_confirmed":true},"stress"),"stress resume")
 check(low.engine.actor_by_id(H).mp==0,"no middle refill")
 d.input(low,"lead_batch");d.resolve(low);d.input(low,"escort_intercept");d.resolve(low)
 check(low.engine.actor_by_id(H).mp==12,"guard8 plus successful4 real cap")
 var hits:Array=low.engine.state.events.filter(func(ev):return ev.type=="damage" and ev.round==8)
 check(hits.size()==1 and hits[0].detail.raw==270.0 and hits[0].amount==123,"escort one full270 DEF and25% branch, not generic half-share")
 check(low.set_command(H,"sancai_counter","routed_pressure")=="insufficient_mp","insufficient true19MP cost")
 d.command(low,"self_guard",H);d.resolve(low)
 check(low.engine.state.objective.batch_index==0 and low.engine.state.objective.pressure==3800,"missed induction window no free objective")
 # New cycle: observe earns4, exposed second beat must really re-protect.
 d.command(low,"observe","routed_pressure");d.resolve(low)
 d.input(low,"escort_intercept");d.resolve(low)
 d.command(low,"sancai_counter","routed_pressure");d.resolve(low)
 for i in range(2):
  d.input(low,"lead_batch");d.resolve(low);d.input(low,"escort_intercept");d.resolve(low)
  if low.engine.actor_by_id(H).mp<19:
   d.command(low,"self_guard",H);d.resolve(low);d.command(low,"observe","routed_pressure");d.resolve(low);d.input(low,"escort_intercept");d.resolve(low)
  d.command(low,"sancai_counter","routed_pressure");d.resolve(low)
 check(low.engine.state.outcome=="victory","0MP stress actual guard-observe delay survives without N01/P03/items")
 print("CH08 0MP PURE STRESS ",JSON.stringify(low.final_party())," rounds ",low.engine.state.round-1)
 var p=session();d.ballista(p);p.resume_phase_two({"fire_confirmed":true},"protected")
 var e=p.engine;var h=e.actor_by_id(H)
 d.input(p,"lead_batch");d.resolve(p);d.input(p,"escort_intercept");d.resolve(p)
 e.actor_by_id("routed_pressure").protected_through=e.state.round
 var hp:int=h.hp;var mp:int=h.mp
 d.command(p,"sancai_counter","routed_pressure");d.resolve(p)
 check(e.state.objective.pressure==3800 and e.state.objective.batch_index==0,"protected three talents cannot cancel or disarm")
 check(h.hp<hp and h.mp==mp-19,"protected stance true cost and35% damage reduction")
 # Same-action and repeated event proof cannot mint layers.
 var layers=session();var le=layers.engine
 le._p03("isolated_valid_break");le._p03("isolated_valid_break")
 check(le.state.objective.p03_stacks==1 and le.state.objective.p03_events.size()==1,"P03 unique event set")
 # Formula-only probes use the real engine but never produce campaign receipts.
 var target=le.actor_by_id("ballista");target.tags=["mechanism","formation","heavy_armor"]
 target.hp=10000;var start:int=target.hp
 le._damage_action(le.actor_by_id(H),target,1.0,false,"normal","normal_attack")
 var tagged:int=start-int(target.hp)
 target.tags=[];start=target.hp;le._damage_action(le.actor_by_id(H),target,1.0,false,"normal","normal_attack")
 var ordinary:int=start-int(target.hp)
 check(tagged>ordinary and tagged<=int(ceil(ordinary*1.25))+1,"multi tags one25% only")
 var narrative=session();d.ballista(narrative);narrative.resume_phase_two({"fire_confirmed":true},"narrative")
 var nh=narrative.engine.actor_by_id(H);nh.mp=50
 d.command(narrative,"normal_attack","routed_pressure");d.resolve(narrative)
 check(nh.mp==50 and narrative.engine.state.objective.pressure==3800,"narrative normal no damage or mana")
 check(narrative.engine.state.events.filter(func(v):return v.type=="damage" and v.target=="routed_pressure").is_empty(),"no phantom entity damage event")
 print("Chapter eight combat boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
