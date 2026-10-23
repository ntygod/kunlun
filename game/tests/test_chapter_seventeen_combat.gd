extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Core=preload("res://scripts/combat/chapter_seventeen_engine.gd")
const Session=preload("res://scripts/combat/chapter_seventeen_encounter.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func act(session:RefCounted,commands:Array)->bool:
 for cmd in commands:
  if not check(session.set_command(cmd[0],cmd[1],cmd[2])=="","legal command "+str(cmd)):return false
 return check(session.resolve_round(),"actual round resolution")
func count_event(s:RefCounted,kind:String)->int:
 var count=0
 for event in s.engine.state.events:
  if event.type==kind:count+=1
 return count
func run()->void:
 var path:=OS.get_environment("CH17_SOURCE")
 if path.is_empty() or not FileAccess.file_exists(path):push_error("CH17_SOURCE required");quit(2);return
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="" and c.enter_registered_chapter(17),"real entry")
 var double_session:RefCounted
 var amo_session:RefCounted
 for n in range(140):
  if c.state.finished:break
  if c.current_event().get("id")=="ch17_wolf_double":double_session=c.current_chapter_runtime().make_objective_encounter()
  if c.current_event().get("id")=="ch17_amo":amo_session=c.current_chapter_runtime().make_objective_encounter();break
  if not check(Driver.advance(c,0,false),"real lead-in "+c.current_token()):break
 if not check(double_session!=null and amo_session!=null,"both authored encounter parts available"):quit(1);return
 var s:RefCounted=double_session
 check(s.engine.actor_by_id(Core.DOUBLE).max_hp==4600,"V3 double HP unchanged")
 var wolves=0
 for a in s.engine.state.actors:
  if str(a.id).begins_with("npc_ch17_b13_wolf_"):wolves+=1;check(a.max_hp==1800 and a.atk==290 and a.def==170 and a.spd==65,"V3 wolf panels")
 check(wolves==3,"all three wolves")
 act(s,[[Driver.H,"LX_A06",Driver.H],[Driver.L,"LYY_A08",Core.DOUBLE],[Driver.F,"FL_S02",Core.DOUBLE]])
 check(s.engine.state.objective.wind_hit and not s.engine.state.objective.hook_hit and not s.engine.state.objective.revolt,"one skill cannot pretend to complete group control")
 var snap:Dictionary=s.snapshot();check(Session.from_snapshot(JSON.parse_string(JSON.stringify(snap)),c.rules,c.combat)!=null,"resolved round strict replay")
 act(s,[[Driver.H,"observe",Core.DOUBLE],[Driver.L,"LYY_A03",Core.DOUBLE],[Driver.F,"FL_S01",Core.DOUBLE]])
 check(s.engine.state.objective.revolt,"actual two skills enable revolt")
 act(s,[[Driver.H,"observe",Core.DOUBLE],[Driver.L,"self_guard",Driver.L],[Driver.F,"self_guard",Driver.F]])
 var total=0
 for e in s.engine.state.events:
  if e.type=="damage" and e.detail.channel=="enemy_revolt" and e.target==Core.DOUBLE:total+=int(e.amount)
 check(total>0,"wolves inflict real damage on their controller")
 s=amo_session
 check(s.engine.actor_by_id(Core.AMO).max_hp==6800 and s.engine.actor_by_id(Core.AMO).atk==335,"V3 Amo panel")
 for a in s.initial_party:
  var initial_mp:int=s.engine.actor_by_id(a.id).mp
  check(initial_mp==mini(int(a.max_mp),int(a.mp)+4) if a.id==Driver.H else initial_mp==a.mp,"phase2 preserves mana except legal whale-breath income")
 check(s.engine.validate_command(Driver.H,"LX_A08",Core.AMO)=="skill_unavailable","future ultimate cannot be selected")
 var before:Dictionary=s.snapshot();check(s.set_command(Driver.H,"normal_attack",Core.AMO,999)=="stale_revision","stale command rejected");check(Same.equivalent(before,s.snapshot()),"stale command atomic")
 act(s,[[Driver.H,"normal_attack",Core.AMO],[Driver.L,"self_guard",Driver.L],[Driver.F,"self_guard",Driver.F]])
 check(count_event(s,"blind_strike_ambush")==1,"blind attack triggers one real backstab")
 check(not s.engine.state.objective.rescued,"guarding alone cannot rescue hostage")
 s.retry();check(Same.equivalent(before,s.snapshot()),"retry restores entry including phase mana")
 var feng_hp:int=s.engine.actor_by_id(Driver.F).hp
 act(s,[[Driver.H,"observe",Core.AMO],[Driver.L,"LYY_A01",Core.AMO],[Driver.F,"FL_S02",Core.AMO]])
 check(s.engine.state.objective.exposed and s.engine.state.objective.rescued,"joint observation + actual feint rescue")
 check(s.engine.actor_by_id(Driver.F).hp==feng_hp,"redirected miss protects Feng without refunding damage")
 check(count_event(s,"feint_miss")==1,"one feint resolves one enemy action")
 check(s.engine.state.objective.synergy<=1,"all sources share one synergy income per round")
 for index in range(60):
  if s.engine.state.outcome!="":break
  for cmd in Driver.commands(s):check(s.set_command(cmd.actor,cmd.skill,cmd.target)=="","tactical command")
  check(s.resolve_round(),"tactical round")
 check(s.engine.state.outcome=="victory" and s.engine.state.objective.sword_finish,"Amo requires actual Fly-Star finishing blow")
 var result:Dictionary=s.receipt();check(not result.is_empty(),"earned receipt")
 var fake:Dictionary=result.duplicate(true);fake.final_actors[0].hp+=1
 check(Session.replay_receipt(fake,c.rules,c.combat,s.encounter,s.initial_party).is_empty(),"edited HP is not a victory receipt")
 var clone:=Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),c.rules,c.combat)
 check(clone!=null and Same.equivalent(clone.receipt(),result),"terminal replay exactly")
 # Genuine failed tactics: ordinary attacks never satisfy the double-control objective.
 var doomed=Session.new(c.rules,c.combat,double_session.encounter,double_session.initial_party,double_session.attempt_id)
 var doomed_entry:Dictionary=doomed.snapshot()
 for n in range(80):
  if doomed.engine.state.outcome!="":break
  for id in [Driver.H,Driver.L,Driver.F]:
   check(doomed.set_command(id,"normal_attack" if id==Driver.H else "self_guard",Core.DOUBLE if id==Driver.H else id)=="","legal losing tactic")
  check(doomed.resolve_round(),"losing route resolves real enemy attacks")
 check(doomed.engine.state.outcome=="defeat","a real exhausted companion causes defeat")
 check(doomed.receipt().is_empty(),"failed battle has no reward receipt")
 var lost=Session.from_snapshot(JSON.parse_string(JSON.stringify(doomed.snapshot())),c.rules,c.combat)
 check(lost!=null and lost.engine.state.outcome=="defeat","defeat survives strict replay")
 doomed.retry();check(Same.equivalent(doomed.snapshot(),doomed_entry),"failed battle retry is the original entry, not full HP")
 # Invalid metadata is rejected before any stage can start.
 for kind in ["limited","ultimate","refill"]:
  var party:Array=s.initial_party.duplicate(true)
  if kind=="limited":party[2].max_hp+=1
  elif kind=="ultimate":party[0].skills.append("LX_A08")
  else:party[1].mp=party[1].max_mp
  var broken=Session.new(c.rules,c.combat,s.encounter,party,s.attempt_id)
  check(broken.engine.entry_error!="","reject forged "+kind)
 print("Chapter seventeen combat: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
