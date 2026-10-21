extends SceneTree
const Core=preload("res://scripts/combat/chapter_twelve_engine.gd")
const Session=preload("res://scripts/combat/chapter_twelve_encounter.gd")
const BattlePanel=preload("res://scripts/ui/chapter_twelve_battle_panel.gd")
const Driver=preload("res://tests/chapter_twelve_encounter_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func fixture(id:String,xp:int)->Dictionary:
 var gear:Dictionary=Party.CH11_GEAR.get(id,{})
 var internal:String={Core.X:"HXS_N02",Core.HS:"HS_N01",Core.LIU:"LYY_N01"}.get(id,"")
 var a:Dictionary=Party.newcore_panel(id,xp,gear,internal) if id in [Core.X,Core.HS] else Growth.actor_panel(id,xp,gear)
 var active:Array={Core.HERO:["LX_A01","LX_A02","LX_A03","LX_A04"],Core.X:["HXS_A01","HXS_A02","HXS_A03","HXS_A06"],Core.HS:["HS_A01","HS_A02","HS_A03"],Core.LIU:["LYY_A01","LYY_A02","LYY_A03","LYY_A04"]}[id]
 var skills:Array=["normal_attack","self_guard","guard_ally"]
 var ranks:Dictionary={}
 for s in active:skills.append({"LX_A01":"observe","LX_A02":"sancai_counter"}.get(s,s));ranks[s]=3 if s in ["LX_A01","LX_A02","HXS_A01","HXS_A02"] or s.begins_with("LYY_") else 1
 var passives:Array={Core.HERO:["LX_P01","LX_P03"],Core.X:["HXS_P01"],Core.HS:["HS_P01","HS_P02"],Core.LIU:["LYY_P01","LYY_P02"]}[id]
 a.merge({"id":id,"name":id,"team":"party","hp":a.max_hp,"mp":0,"fixed_level":54 if xp==25970 else 58,"skills":skills,"equipped_active_skills":active,"skill_ranks":ranks,"passives":passives,"learned_passives":passives,"internal_skill":internal})
 if id in [Core.X,Core.HS]:a.internal_stats_applied=true;a.panel_internal_skill=internal
 return a
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 for id in Core.IDS:
  var cfg:=Core.encounter_config(id);cfg.context={"chapter":12,"current_token":"test_"+id,"poison_authorized":true,"combo_unlocks":["CO_01","CO_02"]}
  var party:Array=[]
  for who in {"han":[Core.X],"lei":[Core.HS],"chu":[Core.HERO],"medicine":[Core.HERO,Core.X,Core.LIU]}[cfg.kind]:party.append(fixture(who,29640 if cfg.kind=="medicine" else 25970))
  if cfg.kind=="medicine":
   party[1].skills=["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A04","HXS_A05"];party[1].equipped_active_skills=["HXS_A01","HXS_A02","HXS_A04","HXS_A05"];party[1].skill_ranks.merge({"HXS_A04":1,"HXS_A05":1})
  var s=Session.new(rules,runtime,cfg,party,cfg.context.current_token)
  check(s.engine.entry_error=="","entry "+id)
  if s.engine.entry_error!="":continue
  var initial:=s.snapshot()
  check(not s.apply_input({"action_id":"cancel","revision":true}).accepted and Same.equivalent(initial,s.snapshot()),"bad bool revision atomic")
  check(s.set_command(false,"normal_attack","none")!="" and Same.equivalent(initial,s.snapshot()),"bad actor type atomic")
  var won:=Driver.run(s)
  print("CH12_BATTLE ",id," won=",won," round=",s.engine.state.round," objective=",s.engine.state.objective," resources=",s.final_party())
  check(won,"scoped stat fixture victory "+id)
  if won:check(not Session.replay_receipt(s.receipt(),rules,runtime,cfg,party).is_empty(),"strict replay "+id)
  var saved:=s.snapshot();var forged:=saved.duplicate(true);forged.state.actors[0].hp-=1
  check(not s.restore(forged) and Same.equivalent(saved,s.snapshot()),"bad resource snapshot atomic")
  s.retry();check(Same.equivalent(initial,s.snapshot()),"exact retry "+id)
 boundaries(rules,runtime)
 print("Chapter12 combat: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func boundaries(rules:Dictionary,runtime:Dictionary)->void:
 var cfg:=Core.encounter_config(Core.IDS[3]);cfg.context={"chapter":12,"current_token":"boundaries","combo_unlocks":["CO_01","CO_02"],"poison_authorized":true}
 var party:Array=[fixture(Core.HERO,29640),fixture(Core.X,29640),fixture(Core.LIU,29640)]
 party[1].skills=["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A04","HXS_A05"];party[1].equipped_active_skills=["HXS_A01","HXS_A02","HXS_A04","HXS_A05"];party[1].skill_ranks.merge({"HXS_A04":1,"HXS_A05":1})
 var s=Session.new(rules,runtime,cfg,party,"boundaries")
 for a in s.engine.state.actors:
  if a.team=="party":check(a.mp==a.max_mp,"07§1.5 independent lowMP entry recovers MP")
 check(s.final_party().size()==3,"only participant resource receipt")
 # Explicit unit states below exercise hard boundaries; these are not campaign saves.
 var h:Dictionary=s.engine.actor_by_id(Core.HERO);var x:Dictionary=s.engine.actor_by_id(Core.X)
 h.mp=37;h.ready.LX_A04=8;s.engine._apply_status(h,"attack_down",.2,3)
 var before:=h.duplicate(true);var doctor:Dictionary=s.engine.actor_by_id("luo_mingqi");doctor.hp=1800
 s.engine.state.mode="round_end";s.engine._check_outcome()
 check(Same.equivalent(before,h),"summon preserves entire hero HP/MP/CD/status")
 check(doctor.hp==1800 and s.engine.actor_by_id("chiyou_cauldron").hp==4200,"retained doctor plus genuine4200 cauldron")
 s.engine.state.mode="commands"
 check(s.set_command(Core.X,Core.HERBS[0],"chiyou_cauldron")!="","no premature locked herb")
 check(s.set_command(Core.HERO,"normal_attack","chiyou_cauldron")!="","no premature locked attack")
 s.retry();h=s.engine.actor_by_id(Core.HERO);x=s.engine.actor_by_id(Core.X)
 h.hp=0;h.defeated=true;h.mp=17
 check(s.set_command(Core.X,"HXS_A05",Core.HERO)=="","revive command accepts battleKO")
 check(s.set_command(Core.LIU,"self_guard",Core.LIU)=="" and s.resolve_round(),"actual revival round")
 check(h.hp>0 and h.mp==17 and h.revive_used and h.revived_round==1,"revival retains MP and once quota")
 var acted:=false
 for ev in s.engine.state.events:
  if ev.round==1 and ev.type=="action" and ev.source==Core.HERO:acted=true
 check(not acted,"revived actor gets no new action")
 h.hp=0;h.defeated=true
 check(s.set_command(Core.X,"HXS_A05",Core.HERO)=="revive_used","repeat revive denied")
 s.retry();s.engine.state.objective.synergy=2
 check(s.set_command(Core.HERO,"CO_01","luo_mingqi")=="","learnedCO01 legal")
 check(s.engine.state.commands.has(Core.LIU) and not s.engine.state.commands.has(Core.X),"CO01 reserves H/L only")
 check(s.set_command(Core.X,"HXS_A02",Core.HERO)=="" and s.engine.state.objective.reserved==2,"third actor heal does not cancelCO01")
 check(s.set_command(Core.HERO,"CO_02","luo_mingqi")=="" and not s.engine.state.commands.has(Core.LIU) and s.engine.state.objective.reserved==2,"switch mutually exclusive combo reservations")
 check(s.set_command(Core.LIU,"self_guard",Core.LIU)=="" and s.resolve_round(),"CO02+third actor resolves")
 var no_combo:=cfg.duplicate(true);no_combo.context.combo_unlocks=[]
 var absent=Session.new(rules,runtime,no_combo,party,"boundaries");absent.engine.state.objective.synergy=2
 check(absent.set_command(Core.HERO,"CO_01","luo_mingqi")!="" and absent.set_command(Core.HERO,"CO_02","luo_mingqi")!="","unlearned combos rejected")
 s.retry();s.engine.actor_by_id(Core.X).hp=0;s.engine.actor_by_id(Core.X).defeated=true;s.engine._check_outcome()
 check(s.engine.state.outcome=="defeat","X medical commander KO fails")
 var dead:=party.duplicate(true);dead[0].status="dead"
 check(Session.new(rules,runtime,cfg,dead,"boundaries").engine.entry_error!="","storydead actor rejected before revival")
 s.retry();h=s.engine.actor_by_id(Core.HERO);s.engine._apply_status(h,"deathsave",1,2)
 s.engine._lose_hp(s.engine.actor_by_id("luo_mingqi"),h,99999)
 check(h.hp==1+int(h.max_hp*.2) and h.deathsave_used,"deathsave single event floor20percent")
 s.engine._lose_hp(s.engine.actor_by_id("luo_mingqi"),h,99999)
 check(h.hp==0,"deathsave not sustained invulnerability")

 # Three complete player rounds from the opening, not from summon time.
 s.retry();s.engine.state.objective.phase=2
 for id in ["luo_mingqi","puppet_east","puppet_west"]:s.engine.actor_by_id(id).defeated=true
 var pot:=Core.foe("chiyou_cauldron","蚩尤毒鼎",4200,240,235,140,48);s.engine._normalize(pot);s.engine.state.actors.append(pot)
 s.engine.state.objective.unlock_round=1;s.engine.state.objective.herb_deadline=3
 for round_index in range(3):
  check(s.set_command(Core.HERO,"self_guard",Core.HERO)=="" and s.set_command(Core.LIU,"self_guard",Core.LIU)=="","deadline guards legal")
  check(s.set_command(Core.X,Core.HERBS[2],"chiyou_cauldron")=="" and s.resolve_round(),"wrong herb uses actual full round")
 check(s.engine.state.outcome=="defeat" and s.engine.state.objective.failure=="herb_deadline","threewrong herbs really timeout")
 check(s.engine.state.objective.herbs.is_empty() and pot.hp==4200,"wrong herbs no phantom damage or progress")
 s.retry();s.engine.state.objective.synergy=2
 check(s.set_command(Core.HERO,"CO_01","luo_mingqi")=="" and s.set_command(Core.X,"self_guard",Core.X)=="" and s.resolve_round(),"CO01 actual execution plus independent Xguard")
 var executed:=0
 for ev in s.engine.state.events:
  if ev.type=="combo_executed" and ev.target==Core.LIU:executed+=1
 check(executed==1 and s.engine.state.objective.reserved==0,"CO01 executes once, no double normal actions")
 # Emergency reaction is finite and does not mint mana/synergy.
 s.retry();h=s.engine.actor_by_id(Core.HERO);x=s.engine.actor_by_id(Core.X);x.passives.append("HXS_P03");h.hp=100
 var prior_x:int=x.hp;var prior_h:int=h.hp;var prior_synergy:int=s.engine.state.objective.synergy
 s.engine._damage_action(s.engine.actor_by_id("puppet_east"),h,1.8,false,"enemy","fixture_heavy")
 check(x.hp<prior_x and h.hp<prior_h and x.emergency_used,"P03 splits one realheavy into2branches")
 check(x.mana_gained==0 and s.engine.state.objective.synergy==prior_synergy,"P03 no extra mana/synergy")
 prior_x=x.hp;h.hp=100;h.defeated=false
 s.engine._damage_action(s.engine.actor_by_id("puppet_east"),h,1.8,false,"enemy","fixture_second_heavy")
 check(x.hp==prior_x,"P03 once perbattle")
