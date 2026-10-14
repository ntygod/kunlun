extends "res://tests/test_chapter_seven_combat.gd"
func setup():
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"));data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven_encounters.json"))
func phase_two(s,active:bool=false):
 var d=Driver.new(check)
 for n in range(40):
  if s.engine.state.outcome!="" or s.engine.state.objective.phase==2:break
  if not s.engine.state.objective.jin_repelled:d.command(s,H,"LX_A03" if active and s.engine.validate_command(H,"LX_A03","jin_fei")=="" else "normal_attack","jin_fei")
  elif not s.engine.state.objective.snow_freed:d.input(s,"free_axue")
  else:d.input(s,"handoff_haiya")
  d.resolve(s)
 check(s.engine.state.objective.phase==2,"phase two reached")
func run():
 setup()
 var d=Driver.new(check)
 var typed=session();var typed_before=typed.snapshot()
 for bad in [true,false,1.0,1.1,1.9,"1",null,[],{},-2]:
  check(typed.callv("set_command",[H,"normal_attack","jin_fei",bad])!="","public revision rejects malformed type")
  check(Compare.equivalent(typed_before,typed.snapshot()),"bad revision rejects atomically")
 for bad in [true,1,1.0,null,[],{}]:
  for slot in range(3):
   var args:Array=[H,"normal_attack","jin_fei",1];args[slot]=bad
   check(typed.callv("set_command",args)!="","public command strings reject bad type")
   check(Compare.equivalent(typed_before,typed.snapshot()),"bad string atomic")
  check(not typed.apply_input(bad).accepted,"outer input non-Dictionary rejection")
  check(not typed.restore(bad),"outer restore non-Dictionary rejection")
 check(typed.set_command(H,"normal_attack","jin_fei",1)=="","valid integer revision remains accepted")
 var s=session();phase_two(s,true)
 check(s.engine.state.objective.phase_entry.hero_mp<118,"actual spent MP retained across phase")
 var entry=s.snapshot();var prefix=s.history.size()
 d.input(s,"retreat");check(s.engine.state.outcome=="defeat","explicit retreat")
 s.retry();check(Compare.equivalent(entry,s.snapshot()),"retry restores exact phase entry and prefix")
 check(s.history.size()==prefix,"phase1 proof retained without replay rewards")
 var snap=s.snapshot();var clone=session();check(clone.restore(snap),"phase2 restore")
 for bad in [true,"1",-1,0.5]:
  var corrupt=snap.duplicate(true);corrupt.checkpoint_history_size=bad
  check(not clone.restore(corrupt),"bad checkpoint type")
 for bad in [true,"1",0.5]:
  var corrupt=snap.duplicate(true);corrupt.version=bad
  check(not clone.restore(corrupt),"bad version type")
 d.input(s,"fire","A");d.command(s,A,"self_guard",A);d.resolve(s)
 check(s.engine.state.objective.bolts==3 and s.engine.state.objective.supports.A==934,"wrong shot consumes action not ammo")
 check(s.engine.state.objective.completed_rounds==1,"wrong shot counted real full round")
 d.input(s,"calibrate","A","crossbeam");d.command(s,A,"self_guard",A);d.resolve(s)
 check(s.engine.state.objective.calibrated=="","wrong calibration rejected at resolution")
 d.input(s,"calibrate","A","left_beam");d.command(s,A,"normal_attack","bridge_threat");d.resolve(s)
 check(s.engine.actor_by_id("bridge_threat").hp==2800 and s.engine.state.objective.calibrated=="A","ordinary attacks cannot damage objective or break calibration")
 var p=party();p[1].mp=75
 var a=session("b04",p);phase_two(a)
 # Unit probes below deliberately edit transient state to isolate semantic boundaries.
 var e=a.engine;var h=e.actor_by_id(H);var snow=e.actor_by_id(A)
 h.passives.append("LX_P02")
 snow.hp=168;e._check_friend_rage();check(e._status_value(h,"friend_rage")==0,"exactly35% does not trigger")
 snow.hp=167;e._check_friend_rage();check(e._status_value(h,"friend_rage")==.2,"below35% triggers")
 var expires=h.statuses[-1].expires;e._check_friend_rage();check(h.statuses[-1].expires==expires,"active buff does not refresh")
 var base_atk=h.atk
 check(e.skill_cost(h,e.content.skills.LX_A03)==13,"ceil(max(14,.14*118)*.75)=13")
 h.discount=.5;check(e.skill_cost(h,e.content.skills.LX_A03)==9,"discount capped at50%")
 h.discount=0
 e.state.round+=2;e._check_friend_rage();check(h.statuses[-1].expires==e.state.round+1,"expires then retriggers")
 check(h.atk==base_atk,"temporary rage never changes permanent/effective base attack")
 h.statuses=[];snow.hp=480;snow.statuses=[{"kind":"captured","value":1,"starts":e.state.round,"expires":e.state.round+3}]
 e._check_friend_rage();check(e._status_value(h,"friend_rage")==0,"captured is not ordinary control")
 snow.statuses=[{"kind":"stun","value":1,"starts":e.state.round,"expires":e.state.round+3}]
 e._check_friend_rage();check(e._status_value(h,"friend_rage")==.2,"ordinary control triggers")
 h.statuses=[];snow.statuses=[];h.mp=0;snow.mp=0;e.state.round=20;e.state.objective.passive_turn=0;h.mana_gained=0
 e._axue_passive();check(h.mp==3 and snow.mp==0,"P01 no debuff still3 to hero")
 e._axue_passive();check(h.mp==3,"P01 repeated same turn no second grant")
 e.state.round=22;h.statuses=[{"kind":"bleed","value":1,"starts":18,"expires":24},{"kind":"freeze","value":1,"starts":19,"expires":26}];h.mana_gained=0
 e._axue_passive();check(h.statuses[0].expires==23 and h.statuses[1].expires==26 and h.mp==6,"P01 earliest hero status and same recipient")
 e.state.round=24;h.statuses=[];snow.statuses=[{"kind":"cold_poison","value":1,"starts":23,"expires":26}];snow.mana_gained=0
 e._axue_passive();check(snow.mp==3 and snow.statuses[0].expires==25,"P01 falls back to snow")
 e.state.round=26;h.statuses=[{"kind":"bleed","value":1,"starts":25,"expires":26}];snow.statuses=[];h.mana_gained=12
 e._axue_passive();check(h.statuses[0].expires==26 and h.mp==6,"remaining1 unchanged and total MPcap respected")
 var heal=session("b04",p);phase_two(heal)
 var he=heal.engine;var hh=he.actor_by_id(H);var aa=he.actor_by_id(A)
 hh.hp=300;hh.mp=0;hh.statuses=[{"kind":"bleed","value":1,"starts":1,"expires":30},{"kind":"cold_poison","value":1,"starts":2,"expires":30}]
 he._execute_command(aa,{"skill_id":"AX_S02","target_id":H})
 check(hh.hp==404 and hh.statuses.size()==1,"AX Lv2 display still104 and cleanse only1")
 check(aa.mp==65,"AXS02 costs10")
 he._after_preparation(aa,he.content.skills.AX_S01)
 check(hh.ax_evade and aa.ax_evade and hh.ax_speed_round==he.state.round+1,"S01 whole party next speed and single action shield")
 var before_hp=hh.hp
 he._execute_intent(he.actor_by_id("bridge_threat"),{"actor_id":"bridge_threat","intent_id":"multi_probe","name":"trap","target_id":H,"hits":[1.0,1.0],"tags":["environment_trap"],"aoe":true,"executed":false,"cancelled":false})
 check(not hh.ax_evade and not aa.ax_evade,"S01 consumes once after whole multi-hit action")
 check(before_hp-hh.hp==118,"35% applies to both trap hits, no additive shields")
 var active=session("b04",p);d.b04(active,true)
 check(active.engine.state.outcome=="victory","active skill strategy")
 print("CH07 active end resources ",JSON.stringify(active.final_party())," turns ",active.engine.state.round-1)
 print("CH07 boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
