extends SceneTree
const Core=preload("res://scripts/combat/chapter_fourteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_fourteen_encounter.gd")
const Fixtures=preload("res://tests/test_chapter_fourteen_combat.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
 var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 for skill in ["HS_A01","HS_A01_self","HS_A04"]:
  # Legal four-slot loadout prepared before encounter entry; no actor/state mutation.
  var party:=Fixtures.party_fixture()
  party[1].equipped_active_skills=["HS_A01","HS_A04","HS_A03","HS_A05"]
  party[1].skills=["normal_attack","self_guard","guard_ally","HS_A01","HS_A04","HS_A03","HS_A05"]
  var cfg:=Core.encounter_config();cfg.context={"chapter":14,"current_token":"guard_test"}
  var s=Session.new(rules,runtime,cfg,party,"guard_test")
  check(s.engine.entry_error.is_empty(),"legal four-slot entry")
  var target:String=Core.HS if skill=="HS_A01_self" else Core.HERO
  var action:String="HS_A01" if skill=="HS_A01_self" else skill
  check(s.set_command(Core.HERO,"observe",Core.MASTER).is_empty(),"legal observation")
  check(s.set_command(Core.HS,action,target).is_empty(),"legal preparation "+skill)
  check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"pending replay "+skill)
  check(s.resolve_round(),"actual round "+skill)
  var guard_damage:=0;var reflection:=0;var hero_damage:=0;var shield_loss:=0;var guard_rewards:=0
  for event in s.engine.state.events:
   if event.type=="mana" and event.source==Core.HS and event.detail.get("reason")=="successful_guard":guard_rewards+=1
   if event.type!="damage":continue
   if event.detail.get("channel")=="guard" and event.target==Core.HS:guard_damage+=int(event.amount)
   if event.detail.get("channel")=="reflection" and event.source==Core.HS:reflection+=int(event.amount)
   if event.source==Core.MASTER and event.target==Core.HERO:hero_damage+=int(event.amount);shield_loss+=int(event.detail.get("shield_loss",0))
  if skill=="HS_A01":
   check(guard_damage>0 and hero_damage>0 and hero_damage<110,"A01 takes 75 percent raw share, better than ordinary 50 percent guard")
   check(reflection>0,"successful guard reflects")
   check(s.engine.state.objective.synergy==1,"successful guard earns one synergy")
   check(guard_rewards==0 and s.engine.actor_by_id(Core.HS).mp==s.engine.actor_by_id(Core.HS).max_mp,"full MP guard does not overflow")
  elif skill=="HS_A01_self":
   check(guard_damage==0 and hero_damage==220,"self protection does not cover ally")
  else:
   check(s.engine.content.skills.HS_A04.kind=="release","release definition consistent")
   check(shield_loss>0 and guard_damage==0,"release shields ally without redirecting damage")
  check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"settled replay "+skill)
 # Optional independently captured pre-fix fixtures, never generated with the new engine.
 var old_dir:=OS.get_environment("CH14_GUARD_OLD_FIXTURES")
 if not old_dir.is_empty():
  var pending:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(old_dir.path_join("old_pending.json")))
  check(Session.from_snapshot(pending,rules,runtime)!=null,"pre-fix legal non-A01 pending compatible")
  var settled:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(old_dir.path_join("old_a01_settled.json")))
  check(Session.from_snapshot(settled,rules,runtime)==null,"pre-fix wrongly settled A01 rejected rather than silently rewritten")
 print("Chapter 14 guard: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
