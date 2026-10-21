extends SceneTree
const Session=preload("res://scripts/combat/chapter_thirteen_encounter.gd")
const Core=preload("res://scripts/combat/chapter_thirteen_engine.gd")
const Driver=preload("res://tests/chapter_thirteen_encounter_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:=OS.get_environment("B10_OLD_ENTRY")
 var terminal:=OS.get_environment("B10_OLD_TERMINAL")
 check(FileAccess.file_exists(path) and FileAccess.file_exists(terminal),"existing unedited command evidence required")
 if failures:quit(1);return
 var hash_before:=FileAccess.get_sha256(path);var terminal_hash:=FileAccess.get_sha256(terminal)
 var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var s=Session.from_snapshot(old.initial,rules,runtime)
 check(s!=null,"actual minimum entry restores")
 if s==null:quit(1);return
 var cfg:Dictionary=old.initial.initial_encounter;var party:Array=old.initial.initial_party
 check(s.engine.actor_by_id(Core.HERO).hp==old.initial.state.actors[0].hp,"entry matches old snapshot including legitimate first-round whale breath")
 check(s.engine.actor_by_id(Core.HERO).mp==s.engine.actor_by_id(Core.HERO).max_mp,"ordinary independent battle MP rule retained")
 for i in range(3):
  for cmd in Driver.commands(s):check(s.set_command(cmd[0],cmd[1],cmd[2])=="","legal command")
  check(s.resolve_round(),"actual round")
 for cmd in Driver.commands(s):check(s.set_command(cmd[0],cmd[1],cmd[2])=="","pending command")
 var partial:=s.snapshot();var loaded=Session.from_snapshot(partial,rules,runtime)
 check(loaded!=null and Same.equivalent(partial,loaded.snapshot()),"unfinished load preserves commands and resources")
 check(Driver.run(s) and Driver.run(loaded),"actual minimum entry still wins without added HP")
 check(Same.equivalent(s.receipt(),loaded.receipt()),"loaded continuation same corrected result")
 check(not s.engine.state.objective.postheal,"no new postbattle reward")
 check(s.engine.state.events.filter(func(e):return e.type=="postbattle_heal").is_empty(),"no hidden HP event")
 var old_hp:int=old.receipt.final_actors[0].hp;var new_hp:int=s.final_party()[0].hp
 check(old_hp-new_hp==int(floor(float(s.engine.actor_by_id(Core.HERO).max_hp)*.20)),"exact old extra20 removed with identical strategy")
 check(not Session.replay_receipt(s.receipt(),rules,runtime,cfg,party).is_empty(),"new receipt strict replay")
 var old_loaded=Session.from_snapshot(old.final,rules,runtime)
 check(old_loaded!=null and Same.equivalent(old_loaded.snapshot(),old.final),"old completed victory preserved exactly")
 check(not Session.replay_receipt(old.receipt,rules,runtime,cfg,party).is_empty(),"old completed receipt strict compatibility")
 var forged:Dictionary=old.final.duplicate(true);forged.state.actors[0].hp+=1
 check(Session.from_snapshot(forged,rules,runtime)==null,"arbitrary HP inflation rejected")
 s.retry();check(s.engine.actor_by_id(Core.HERO).hp==old.initial.state.actors[0].hp and not s.engine.state.objective.postheal,"retry does not inherit historic award")
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(terminal))
 check(c.restore_persisted(payload)=="","old chapter13 terminal resources preserved")
 var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="" and Same.equivalent(prepared.payload,payload),"old terminal parsed resave unchanged")
 check(FileAccess.get_sha256(path)==hash_before and FileAccess.get_sha256(terminal)==terminal_hash,"both original files untouched")
 print("B10 actual minimum HP ",old_hp," -> ",new_hp)
 print("B10 recovery policy: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
