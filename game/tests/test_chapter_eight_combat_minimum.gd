extends "res://tests/chapter_seven_minimum_source.gd"
const SevenFlow=preload("res://tests/chapter_seven_campaign_driver.gd")
const EightSession=preload("res://scripts/combat/chapter_eight_encounter.gd")
const Growth8=preload("res://scripts/campaign/progression.gd")
const H8="char_liang_xiao"
func after_source(c:RefCounted) -> void:
 check(c.enter_registered_chapter(7),"minimum ch7 entry")
 for j in range(400):
  if c.state.finished:break
  if not SevenFlow.advance(c,false,0):check(false,"ch7 progress");return
 check(c.state.finished and c.state.xp==11220 and c.state.coins==500,"real 0-7 minimum11220 500 copper; no spending")
 var saved=c.prepare_persisted_save();check(saved.error=="","formal minimum chapter7 save")
 var actors:Dictionary=c.actors.duplicate(true);var h:Dictionary=actors[H8]
 check(h.get("internal_skill","")!="LX_N01","real source no N01")
 var hp:int=h.hp;var mp:int=h.mp
 h.merge(Growth8.actor_panel(H8,h.xp,{"max_hp":160,"max_mp":20,"atk":36,"def":24,"spd":4}),true);h.hp=hp;h.mp=mp
 h.hp=h.max_hp # approved explicit river preparation, only Liang
 h.id=H8;h.team="party";h.skills=["normal_attack","self_guard","observe","sancai_counter","LX_A03"]
 h.acquired_passives=h.passives.duplicate()
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_eight_encounters.json"))
 var river=EightSession.new(c.rules,c.combat,data.encounters.enc_ch08_river_duel,[h],"real_minimum_river")
 for j in range(3):
  check(river.apply_input({"actor_id":H8,"action_id":"borrow_cover"}).accepted,"river cover")
  check(river.resolve_round(),"river odd")
  check(river.set_command(H8,"self_guard",H8)=="","river guard")
  check(river.resolve_round(),"river even")
 check(river.engine.state.outcome=="victory" and river.engine.state.round==7,"river six rounds nonlethal")
 Party.accept_resources(actors,river.final_party(),[H8])
 var ledger:Dictionary={}
 # Exact approved first-nine main transaction order, with puzzle receipts in place.
 for pair in [["approach",20],["river",30],["repair",30],["numbers",40],["bridge",20],["dam_puzzle",800],["dam",30],["medicine",20],["siege",20],["cannon_puzzle",800],["cannon",20]]:Party.award(actors,ledger,pair[0],pair[1])
 h=actors[H8];h.hp=h.max_hp;h.passives=["LX_P01","LX_P03"];h.acquired_passives=["LX_P01","LX_P02","LX_P03"]
 check(h.xp==13050 and h.level==37 and h.max_hp==1127 and h.max_mp==132,"minimum actual B05 panel")
 var s=EightSession.new(c.rules,c.combat,data.encounters.enc_ch08_ballista_objective,[h],"real_minimum_b05")
 for hub in ["left_gear","center_pin","right_string"]:
  check(s.apply_input({"actor_id":H8,"action_id":"inspect_hub","value":hub}).accepted,"inspect "+hub);check(s.resolve_round(),"inspect round")
  check(s.apply_input({"actor_id":H8,"action_id":"release_calibrated_shot","value":hub}).accepted,"fire "+hub);check(s.resolve_round(),"fire round")
 check(s.engine.state.objective.phase=="intermission" and s.engine.state.round==7,"B05 six actual actions")
 check(s.engine.actor_by_id(H8).hp==1127 and s.engine.state.objective.p03_stacks==3,"zero-arrow solution and three P03 layers")
 check(not EightSession.replay_receipt(s.receipt(),c.rules,c.combat,s.encounter,[h]).is_empty(),"phase1 receipt replay")
 Party.accept_resources(actors,s.final_party(),[H8])
 for pair in [["ballista",300],["window",65],["fire",150]]:
  Party.award(actors,ledger,pair[0],pair[1]);check(s.sync_campaign_actor(actors[H8]),"sync legitimate growth")
 check(s.resume_phase_two({"fire_confirmed":true},"phase2"),"same battle resume")
 var checkpoint=s.snapshot()
 for batch in range(3):
  check(s.apply_input({"actor_id":H8,"action_id":"lead_batch"}).accepted,"lead");check(s.resolve_round(),"lead round")
  check(s.apply_input({"actor_id":H8,"action_id":"escort_intercept"}).accepted,"escort");check(s.resolve_round(),"escort round")
  check(s.set_command(H8,"sancai_counter","routed_pressure")=="","real three talents legal CD and MP");check(s.resolve_round(),"counter round")
 check(s.engine.state.outcome=="victory" and s.engine.state.objective.pressure==0,"real minimum three batch completion")
 var restored=EightSession.from_snapshot(s.snapshot(),c.rules,c.combat)
 check(restored!=null,"complete deterministic resume replay")
 var config:Dictionary=data.encounters.enc_ch08_civilian_escort.duplicate(true);config.context={"campaign_checkpoint":checkpoint}
 check(not EightSession.replay_receipt(s.receipt(),c.rules,c.combat,config,[h]).is_empty(),"phase2 trusted-prefix receipt")
 print("CH08 REAL MINIMUM ",JSON.stringify(s.final_party())," K=",s.engine.state.k," rounds=",s.engine.state.round-1," payments=",JSON.stringify(s.engine.state.events.filter(func(e):return e.type=="skill_paid"))," source11220/500/noN01; no coin interface, zero spending")
