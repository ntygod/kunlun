extends SceneTree
const Core=preload("res://scripts/combat/chapter_fifteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_fifteen_encounter.gd")
const Fixture=preload("res://tests/test_chapter_fifteen_combat.gd")
const Driver=preload("res://tests/chapter_fifteen_encounter_driver.gd")
var rules:Dictionary
var runtime:Dictionary
var config:Dictionary
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func session(party:Array=[])->RefCounted:return Session.new(rules,runtime,config,Fixture.party_fixture() if party.is_empty() else party,"b12_boundaries")
func _initialize()->void:
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"));config=Core.encounter_config();config.context={"chapter":15,"current_token":"b12_boundaries"}
 for mutation in ["hero","duplicate","overheal","fractional","unlearned","foreign","slots","passives","internal","panel","hs06"]:
  var p:Array=Fixture.party_fixture()
  match mutation:
   "hero":p[0].id="char_liang_xiao"
   "duplicate":p.append(p[0].duplicate(true))
   "overheal":p[0].hp=p[0].max_hp+1
   "fractional":p[0].hp=1.5
   "unlearned":p[0].skill_ranks.erase("HXS_A01")
   "foreign":p[0].skills.append("LX_A05")
   "slots":p[0].skills.append("HXS_A03");p[0].skill_ranks.HXS_A03=1;p[0].equipped_active_skills.append("HXS_A03")
   "passives":p[0].passives.append("HXS_P04")
   "internal":p[0].internal_skill="HXS_N03"
   "panel":p[0].internal_stats_applied=false
   "hs06":p[1].skill_ranks.erase("HS_A06")
  check(session(p).engine.entry_error!="","reject illegal entry "+mutation)
 var s=session()
 for invalid in [{},{"actor_id":Core.X,"action_id":"finish"},{"actor_id":Core.X,"action_id":"cancel","extra":1},{"actor_id":Core.X,"action_id":"cancel","revision":-5}]:
  var snap:Dictionary=s.snapshot();check(not s.apply_input(invalid).accepted and s.snapshot()==snap,"invalid input atomic")
 check(s.set_command(Core.X,"HXS_A02",Core.HE)!="","healing enemy forbidden")
 for round_index in range(2):
  for c in Driver.commands(s):check(s.set_command(c[0],c[1],c[2])=="","prepare two real rounds")
  check(s.resolve_round(),"resolve two rounds")
 check(s.get_view().objective.synergy==2,"guard and break earn exactly two")
 var initial_synergy:int=s.get_view().objective.synergy
 check(s.set_command(Core.X,"CO_04",Core.HE)=="" and s.get_view().commands.size()==2,"combo reserves both actions")
 check(s.get_view().objective.synergy==initial_synergy-2 and s.get_view().objective.reserved==2,"combo reserves only once")
 check(s.set_command(Core.HS,"CO_04",Core.HE)=="" and s.get_view().objective.synergy==initial_synergy-2,"replacing combo no double spend")
 check(s.apply_input({"actor_id":Core.X,"action_id":"cancel"}).accepted and s.get_view().objective.synergy==initial_synergy,"cancel refunds once")
 check(s.apply_input({"actor_id":Core.X,"action_id":"cancel"}).accepted and s.get_view().objective.synergy==initial_synergy,"second cancel no extra refund")
 var p:Array=Fixture.party_fixture();p[0].hp=1;p[1].hp=5;p[1].passives=["HS_P01","HS_P03"]
 var rescue=session(p)
 check(rescue.set_command(Core.X,"HXS_A01",Core.HE)=="" and rescue.set_command(Core.HS,"HS_A01",Core.X)=="" and rescue.resolve_round(),"legal lowHP protection scenario")
 check(rescue.engine.actor_by_id(Core.X).hp==1 and rescue.engine.actor_by_id(Core.HS).hp==1,"P03 replaces lethal normal share with single full sacrifice")
 check(rescue.engine.actor_by_id(Core.HS).deathsave_used and rescue.engine.actor_by_id(Core.HS).sacrifice_used,"single deathsave quota consumed")
 check(rescue.get_view().objective.synergy==0,"emergency sacrifice gives no synergy")
 var no_mercy:Array=Fixture.party_fixture();no_mercy[0].passives=[]
 var cap=session(no_mercy);var enemy:Dictionary=cap.engine.actor_by_id(Core.HE)
 cap.engine._lose_hp(cap.engine.actor_by_id(Core.HS),enemy,999999)
 check(enemy.hp==1 and not enemy.defeated and cap.get_view().outcome=="","damage cannot bypass two seals or kill")
 check(cap.engine._lose_hp(cap.engine.actor_by_id(Core.X),enemy,999999)==0,"repeated damage remains nonlethal")
 var guard=session();guard.set_command(Core.X,"HXS_A01",Core.HE);guard.set_command(Core.HS,"HS_A01",Core.X);guard.resolve_round()
 check(guard.get_view().objective.synergy==1,"actual guard gives synergy")
 check(guard.engine.actor_by_id(Core.HS).hp<Fixture.party_fixture()[1].hp,"guard actually shares damage")
 check(guard.engine.actor_by_id(Core.X).hp>Fixture.party_fixture()[0].hp-150,"guard protects target with 75 percent routing")
 var staged:Dictionary=guard.snapshot();staged.state.objective.seals=2
 check(not guard.restore(staged),"fake objective rejected")
 var once=session();once.set_command(Core.X,"HXS_A01",Core.HE);once.set_command(Core.HS,"self_guard",Core.HS);once.resolve_round()
 check(once.get_view().objective.synergy==0,"diagnose alone not synergy")
 print("Chapter fifteen battle boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
