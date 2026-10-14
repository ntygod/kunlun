extends SceneTree
const Session = preload("res://scripts/combat/chapter_nine_encounter.gd")
const Driver = preload("res://tests/chapter_nine_encounter_driver.gd")
const Compare = preload("res://scripts/campaign/encounter_session.gd")
const H := "char_liang_xiao"
var checks := 0
var failures := 0
var rules: Dictionary
var runtime: Dictionary
var config: Dictionary
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1; push_error("FAIL "+message)
func setup():
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
 runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_nine_encounters.json")).encounters.enc_ch09_well_disarm
 config.context={"chapter":9,"current_token":"test_well","revision":1,"phase":"ch09_blood_well","scope":"ch09_blood_well","scene_id":"ch09_blood_well","map_id":"map_ch09_changzhou_street","objective_id":"enc_ch09_well_disarm","actors":{},"items":{},"world_objects":{},"choices":{},"completed_receipts":{},"authorizations":[],"rest_receipts":["evt_ch09_blood_well_rest"],"leader_id":H,"control_actor_id":H}
func party(hp: int=1200,mp: int=0) -> Array:
 return [{"id":H,"name":"梁萧","team":"party","hp":hp,"max_hp":1200,"mp":mp,"max_mp":150,"atk":200,"def":120,"spd":42,"skills":["normal_attack","self_guard","observe","sancai_counter","LX_A03"],"passives":["LX_P01","LX_P03"],"acquired_passives":["LX_P01","LX_P03"],"internal_skill":""}]
func session(p: Array=[]) -> RefCounted: return Session.new(rules,runtime,config,party() if p.is_empty() else p,"test_well")
func run():
 setup()
 var s=session();var before=s.snapshot()
 check(s.engine.entry_error=="","valid scene entrance")
 for value in [true,false,1.0,1.9,"1",null,[],{},-1]:
  check(not s.apply_input({"actor_id":H,"action_id":"observe","value":"well_soldier_1","revision":value}).accepted,"revision Variant strict")
  check(Compare.equivalent(before,s.snapshot()),"bad revision atomic")
 for bad in [true,1,1.0,null,[],"bad"]:
  check(not s.apply_input(bad).accepted and not s.restore(bad),"outer Variant rejects")
 for key in ["actor_id","action_id","value"]:
  for bad in [true,1,1.0,null,[],{}]:
   var action={"actor_id":H,"action_id":"observe","value":"well_soldier_1"};action[key]=bad
   check(not s.apply_input(action).accepted and Compare.equivalent(before,s.snapshot()),"invalid field atomic "+key)
 check(s.set_command(H,"self_guard",H)!="" and s.set_command(H,"sancai_counter","well_soldier_1")!="","no martial or mana actions")
 check(Driver.run(s),"standard four actions")
 check(s.engine.state.round==5 and s.engine.state.objective.pressure==0 and s.engine.state.actors.size()==1,"four actions two scene targets no fake actors")
 check(s.final_party()==[{"id":H,"hp":1200,"mp":0}],"zero MP zero damage preserved")
 for soldier in s.engine.state.objective.soldiers:
  check(soldier.retired and soldier.path==soldier.exit_route and soldier.position==soldier.exit_route[-1],"visible actual retirement route")
 check(not Session.replay_receipt(s.receipt(),rules,runtime,config,s.initial_party).is_empty(),"exact victory replay")
 var map:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_nine_maps.json")).maps.map_ch09_changzhou_street
 var bounds=Rect2(map.walk_bounds[0],map.walk_bounds[1],map.walk_bounds[2],map.walk_bounds[3])
 for soldier in s.engine.state.objective.soldiers:
  for i in range(soldier.path.size()):
   var point=Vector2(soldier.path[i][0],soldier.path[i][1])
   check(bounds.has_point(point),"retirement inside actual walk bounds")
   for solid in map.solids:
    check(not Rect2(solid[0],solid[1],solid[2],solid[3]).grow(5).has_point(point),"retirement avoids real map solid with body margin")
   if i>0:
    var previous=Vector2(soldier.path[i-1][0],soldier.path[i-1][1])
    check(absf(point.x-previous.x)+absf(point.y-previous.y)==16,"retirement each actual four-neighbour tile")
 var world:Dictionary=s.get_view().world_state
 check(world.map_id=="map_ch09_changzhou_street" and world.visible_actor_ids==[H],"world retires only after actual exit")
 for soldier in s.engine.state.objective.soldiers:
  check(world.actor_positions[soldier.id]==soldier.path[-1] and world.actor_paths[soldier.id]==soldier.path,"world receives exact formal paths")
 var fake=s.receipt();fake.final_actors[0].mp=150
 check(Session.replay_receipt(fake,rules,runtime,config,s.initial_party).is_empty(),"forged resource rejected")
 s.retry();check(Compare.equivalent(s.snapshot(),before),"retry identical entrance no refill")
 check(Driver.step(s,"observe","well_soldier_1"),"observe first")
 check(s.apply_input({"actor_id":H,"action_id":"disarm","value":"well_soldier_1"}).accepted,"partial preparation")
 var partial=s.snapshot();var clone=Session.from_snapshot(JSON.parse_string(JSON.stringify(partial)),rules,runtime)
 check(clone!=null and Compare.equivalent(clone.snapshot(),partial),"JSON prepared state restore")
 check(clone.resolve_round() and clone.engine.state.objective.pressure==1,"prepared retirement resumes")
 var retired=clone.snapshot()
 check(not clone.apply_input({"actor_id":H,"action_id":"observe","value":"well_soldier_1"}).accepted and Compare.equivalent(retired,clone.snapshot()),"retired target no action spent")
 for key in partial:
  var missing=partial.duplicate(true);missing.erase(key);missing["replacement"]=0
  check(not s.restore(missing) and Compare.equivalent(s.snapshot(),partial),"same size missing required key atomic "+key)
 for value in [true,false,1.5,"1",null]:
  var malformed=partial.duplicate(true);malformed.version=value
  check(not s.restore(malformed),"version strict")
 s=session(party(1200,7))
 check(Driver.step(s,"observe","well_soldier_2") and Driver.step(s,"disarm","well_soldier_1"),"wrong target committed")
 var expected=maxi(1,int(floor(169.0*Session.Core.K/(Session.Core.K+120.0))))
 check(s.final_party()[0].hp==1200-expected and s.final_party()[0].mp==7,"fixed K40 DEF floor exact mistake damage")
 check(s.engine.state.objective.observed=="" and s.engine.beat()==1,"mistake clears observation cycle")
 check(Driver.run(s),"recover after wrong action")
 s=session(party(1,0));check(Driver.run(s),"one HP zero MP isolated stress")
 s=session(party(1,0));Driver.step(s,"wait","well_soldier_1");Driver.step(s,"wait","well_soldier_1")
 check(s.engine.state.outcome=="defeat" and s.final_party()[0].hp==0,"wrong sequence low HP defeat")
 s.retry();check(s.final_party()[0].hp==1 and s.final_party()[0].mp==0 and Driver.run(s),"defeat retry returns true low entrance")
 for key in config.context:
  var c=config.duplicate(true);c.context.erase(key)
  var invalid=Session.new(rules,runtime,c,party(),"test_well")
  check(invalid.engine.entry_error!="","required context key "+key)
 var named=config.duplicate(true)
 for key in ["current_token","phase","scope","scene_id","map_id","objective_id","leader_id","control_actor_id"]:named.context[key]=StringName(named.context[key])
 var ns=Session.new(rules,runtime,named,party(),"test_well")
 check(ns.engine.entry_error=="" and Driver.run(ns),"StringName context accepted")
 for key in ["hp","mp","max_hp","max_mp","atk","def","spd"]:
  for bad in [true,false,-1,1.5,"1",null]:
   var p=party();p[0][key]=bad
   check(session(p).engine.entry_error!="","actor malformed "+key)
 for bad in [null,true,0,[],"bad"]:
  var malformed_config=config.duplicate(true);malformed_config.context=bad
  var invalid=Session.new(rules,runtime,malformed_config,party(),"test_well")
  check(invalid.engine.entry_error!="" and not invalid.restore(before),"malformed constructor context safe")
 for malformed_config in [{},{"id":"enc_ch09_well_disarm"}]:
  var malformed=before.duplicate(true);malformed.initial_encounter=malformed_config
  check(Session.from_snapshot(malformed,rules,runtime)==null,"missing config safe from_snapshot")
 print("Chapter nine encounter: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
