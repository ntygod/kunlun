extends RefCounted
## Only public commands and choices; never writes session state.
const H := "char_liang_xiao"
const A := "char_axue"
var errors: Array[String]=[]
var checker: Callable
func _init(callback: Callable=Callable()):checker=callback
func check(ok: bool,message: String):
	if not ok:errors.append(message)
	if checker.is_valid():checker.call(ok,message)
func input(s,a,id,value=""):
	var action={"actor_id":a,"action_id":id}
	if value!="":action.value=value
	check(s.apply_input(action).accepted,"input "+id)
func command(s,a,skill,target):check(s.set_command(a,skill,target)=="","command "+skill)
func resolve(s):check(s.resolve_round(),"resolve")
func run(s):
	match s.encounter.kind:
		"white_plum":
			for i in range(3):
				input(s,H,"gua",["qian_li","kun_zhen","kun_zhen"][i])
				input(s,H,"step",["qian","kun","center"][i])
				command(s,H,"normal_attack","gongyang_plum");resolve(s)
		"tutuha_spar":
			command(s,H,"ch06_punch","tutuha");resolve(s)
			command(s,H,"self_guard",H);resolve(s)
			command(s,H,"ch06_punch","tutuha");resolve(s)
		"basket_guard":
			for i in range(3):
				var c=H if i%2==0 else A
				var g=A if c==H else H
				input(s,c,"carry");command(s,g,"guard_ally",c);resolve(s)
