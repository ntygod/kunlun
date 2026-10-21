extends RefCounted
const H := "char_liang_xiao"
const A := "char_axue"
var errors: Array[String]=[]
var checker: Callable
func _init(callback: Callable=Callable()):checker=callback
func check(ok: bool,message: String):
 if not ok:errors.append(message)
 if checker.is_valid():checker.call(ok,message)
func input(s,id,value="",mark=""):
 var action={"actor_id":H,"action_id":id}
 if value!="":action.value=value
 if mark!="":action.mark=mark
 check(s.apply_input(action).accepted,"input "+id)
func command(s,a,skill,target):check(s.set_command(a,skill,target)=="","command "+skill)
func resolve(s):check(s.resolve_round(),"resolve")
func run(s):
 if s.encounter.kind=="fire_ox":fire_ox(s);return
 b04(s)
func fire_ox(s,mistakes: bool=false):
 for i in range(3):
  if mistakes:
   input(s,"cover");resolve(s)
  var target: int=[128,352,448][i]
  for n in range(40):
   var pos: int=s.engine.state.objective.position[0]
   if pos==target:break
   input(s,"move","right" if pos<target else "left")
  input(s,"cover");resolve(s)
func b04(s,active: bool=false):
 for n in range(40):
  if s.engine.state.outcome!="" or int(s.engine.state.objective.phase)==2:break
  if not s.engine.state.objective.jin_repelled:
   var skill="LX_A03" if active and s.engine.validate_command(H,"LX_A03","jin_fei")=="" else "normal_attack"
   command(s,H,skill,"jin_fei")
  elif not s.engine.state.objective.snow_freed:input(s,"free_axue")
  else:input(s,"handoff_haiya")
  resolve(s)
 for support in ["A","B","C"]:
  if s.engine.state.outcome!="":break
  input(s,"calibrate",support,{"A":"left_beam","B":"crossbeam","C":"right_winch"}[support])
  command(s,A,"self_guard",A);resolve(s)
  input(s,"fire",support)
  if active and s.engine.validate_command(A,"AX_S02",H)=="":command(s,A,"AX_S02",H)
  else:command(s,A,"self_guard",A)
  resolve(s)
