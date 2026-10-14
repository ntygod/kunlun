extends SceneTree
const Session=preload("res://scripts/combat/chapter_seven_encounter.gd")
const Driver=preload("res://tests/chapter_seven_battle_driver.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Compare=preload("res://scripts/campaign/encounter_session.gd")
const H="char_liang_xiao"
const A="char_axue"
var checks:=0
var failures:=0
var rules:Dictionary
var runtime:Dictionary
var data:Dictionary
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error("CHECK FAILED "+message)
func party(xp:int=10425) -> Array:
 var h=Growth.liang_panel(xp,{"max_hp":100,"max_mp":15,"atk":25,"def":16,"spd":3})
 h.merge({"id":H,"name":"梁萧","team":"party","hp":h.max_hp-90,"mp":0,"skills":["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03"],"passives":["LX_P01"],"skill_ranks":{"observe":2,"LX_A02":3,"LX_A03":1}})
 var a={"id":A,"name":"阿雪","team":"party","max_hp":480,"max_mp":75,"hp":480,"mp":0,"atk":55,"def":40,"spd":28,"skills":["normal_attack","guard_ally","AX_S01","AX_S02"],"passives":["AX_P01"],"skill_ranks":{"AX_S01":2,"AX_S02":2}}
 return [h,a]
func session(kind:String="b04",p:Array=[]) -> RefCounted:
 var config:Dictionary=data.encounters["enc_ch07_chasm_rescue" if kind=="b04" else "enc_ch07_fire_ox_ambush"].duplicate(true)
 config.context={"current_token":"test_b04","revision":7,"phase":"captured","fixed_level":31}
 return Session.new(rules,runtime,config,party() if p.is_empty() else p,"test_attempt")
func run():
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"));data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven_encounters.json"))
 var d=Driver.new(check)
 var s=session()
 check(s.engine.entry_error=="","entry")
 check(s.engine.actor_by_id(H).mp==118,"new battle fills hero MP")
 check(s.engine.actor_by_id(A).is_empty(),"captured snow absent from damage and commands")
 var before=s.snapshot()
 for bad in [{},{"actor_id":true,"action_id":"free_axue"},{"actor_id":H,"action_id":false},{"actor_id":H,"action_id":"free_axue","revision":true},{"actor_id":H,"action_id":"free_axue","revision":999},{"actor_id":H,"action_id":"free_axue"}]:
  check(not s.apply_input(bad).accepted,"reject malformed or premature rescue");check(Compare.equivalent(before,s.snapshot()),"atomic reject")
 check(s.set_command(A,"normal_attack","jin_fei")!="","no captured action")
 d.b04(s)
 check(s.engine.state.outcome=="victory","zero-money zero-MP no-drug normal route")
 check(s.engine.actor_by_id(H).hp==49,"actual lv32 no-N01 conservative 49HP")
 check(s.engine.actor_by_id(A).hp==236,"snow self-guard expected 236HP")
 check(s.engine.actor_by_id(BOSS_ID()).hp==1400,"repelled not killed")
 check(s.engine.state.objective.completed_rounds==6 and s.engine.state.objective.bolts==0,"six real hero actions and all supports")
 check(s.engine.state.objective.phase_entry.snow_mp==0,"no snow refill on joining")
 check(s.engine.state.round==16,"nine plus six rounds")
 check(not s.receipt().is_empty(),"receipt")
 check(not Session.replay_receipt(s.receipt(),rules,runtime,s.encounter,party()).is_empty(),"proof exact replay")
 var clone=session();check(clone.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"JSON restore")
 var forged=s.snapshot();forged.state.objective.completed_rounds=5
 check(not clone.restore(forged),"reject fabricated state")
 var ox=session("fire_ox")
 var omp=ox.engine.actor_by_id(H).mp
 d.fire_ox(ox,true)
 check(ox.engine.state.outcome=="victory","three actual hazards")
 check(ox.engine.actor_by_id(H).hp==756 and ox.engine.actor_by_id(H).mp==omp,"only 90 hazard HP and no MP refill")
 check(ox.engine.state.objective.path.size()>3,"real walking path")
 check(not Session.replay_receipt(ox.receipt(),rules,runtime,ox.encounter,party()).is_empty(),"hazard replay")
 print("CH07 combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func BOSS_ID()->String:return "jin_fei"
