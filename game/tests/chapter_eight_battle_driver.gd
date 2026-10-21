extends RefCounted
const H="char_liang_xiao"
var errors: Array[String]=[]
var checker: Callable
func _init(callback: Callable=Callable()):checker=callback
func check(ok: bool,message: String):
 if not ok:errors.append(message)
 if checker.is_valid():checker.call(ok,message)
func input(s,id,value=""):
 var a:Dictionary={"actor_id":H,"action_id":id}
 if value!="":a.value=value
 check(s.apply_input(a).accepted,"input "+id)
func command(s,skill,target):check(s.set_command(H,skill,target)=="","command "+skill)
func resolve(s):check(s.resolve_round(),"resolve")
func river(s,route="cover"):
 for i in range(3):
  if route=="cover":input(s,"borrow_cover")
  elif route=="flystar":command(s,"LX_A03","river_yunshu")
  else:command(s,"self_guard",H)
  resolve(s)
  command(s,"sancai_counter" if route=="sancai" else "self_guard","river_yunshu" if route=="sancai" else H);resolve(s)
func ballista(s):
 for hub in ["left_gear","center_pin","right_string"]:
  input(s,"inspect_hub",hub);resolve(s);input(s,"release_calibrated_shot",hub);resolve(s)
func escort(s):
 for i in range(3):
  input(s,"lead_batch");resolve(s);input(s,"escort_intercept");resolve(s)
  command(s,"sancai_counter","routed_pressure");resolve(s)
func run(s):
 if s.engine.state.objective.phase=="river_duel":river(s)
 elif s.engine.state.objective.phase=="phase_one":ballista(s)
 elif s.engine.state.objective.phase=="phase_two":escort(s)
