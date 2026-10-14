extends RefCounted
## Public-input reference routes; no actor/engine state writes or success flags.
const H := "char_liang_xiao"
const L := "char_liu_yingying"
const Y := "char_yun_shu"
var errors: Array[String] = []
var checker: Callable
func _init(callback: Callable = Callable()): checker=callback
func check(ok: bool,message: String):
	if not ok: errors.append(message)
	if checker.is_valid(): checker.call(ok,message)
func command(s: ChapterFiveEncounter,a: String,skill: String,target: String): check(s.set_command(a,skill,target)=="","command "+skill)
func input(s: ChapterFiveEncounter,a: String,action: String,target: String=""):
	var value := {"actor_id":a,"action_id":action}
	if target!="": value.target=target
	check(s.apply_input(value).accepted,"input "+action)
func resolve(s: ChapterFiveEncounter): check(s.resolve_round(),"resolve round")
func b02(s: ChapterFiveEncounter):
	command(s,H,"observe",Y);command(s,L,"LYY_A03",Y);resolve(s)
	command(s,H,"CO_01",Y);resolve(s)
	while int(s.engine.state.objective.phase)==1 and s.engine.state.outcome=="" and int(s.engine.state.round)<15:
		command(s,H,"normal_attack",Y);command(s,L,"normal_attack",Y);resolve(s)
	for action in ["lure_second","break_second","lure_third","break_third"]:
		if s.engine.state.outcome!="": return
		input(s,H,action)
		if int(s.engine.state.round)%3==1: command(s,L,"LYY_A01",Y)
		elif int(s.engine.state.round)%3==2 and s.engine.validate_command(L,"LYY_A03",Y)=="": command(s,L,"LYY_A03",Y)
		else: command(s,L,"guard_ally",H)
		resolve(s)
	if s.engine.state.outcome!="": return
	input(s,H,"board_boat");input(s,L,"board_boat");resolve(s)
func b03(s: ChapterFiveEncounter):
	for r in [1,2]:
		input(s,H,"path_read")
		command(s,L,"LYY_A01" if r==1 else "guard_ally","lei_xingkong" if r==1 else H)
		resolve(s)
		if s.engine.state.outcome!="": return
	for gate in ["gate_east","gate_west"]:
		input(s,H,"mark_gate",gate);command(s,L,"normal_attack",gate);resolve(s)
		if s.engine.state.outcome!="": return
