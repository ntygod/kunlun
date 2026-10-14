extends SceneTree
const Session = preload("res://scripts/combat/chapter_five_encounter.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
const H := "char_liang_xiao"
const L := "char_liu_yingying"
var checks := 0
var failures := 0
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_five_encounters.json"))
func _initialize(): call_deferred("run")
func check(ok: bool,msg: String):
	checks+=1
	if not ok: failures+=1; push_error(msg)
func party(xp: int=5815,hp: int=-1) -> Array:
	var h := Growth.liang_panel(xp,{"max_hp":60,"max_mp":10,"atk":16,"def":10,"spd":2})
	h.merge({"id":H,"name":"梁萧","team":"party","hp":int(h.max_hp) if hp<0 else hp,"skills":["normal_attack","self_guard","guard_ally","observe","sancai_counter"],"passives":["LX_P01"],"skill_ranks":{"observe":2}},true)
	var l := Growth.actor_panel(L,xp,{"max_hp":50,"max_mp":10,"atk":15,"def":8,"spd":4})
	l.merge({"id":L,"name":"柳莺莺","team":"party","hp":int(l.max_hp),"skills":["normal_attack","self_guard","guard_ally","LYY_A01","LYY_A02","LYY_A03"],"passives":["LYY_P01"],"internal_skill":"LYY_N01","skill_ranks":{"LYY_A01":1,"LYY_A02":1}},true)
	return [h,l]
func make(b: String="b02",hp: int=-1):
	var id := "enc_ch05_mechanism_yun_shu" if b=="b02" else "enc_ch05_leigong_escape"
	var p := party(4850 if b=="b02" else 6540,hp)
	if b=="b03":
		for k in ["max_hp","hp","atk","def","spd"]: p[0][k]=int(floor(float(p[0][k])*0.5))
		p[0].max_mp=0;p[0].mp=0;p[0].skills=["observe","self_guard"]
	return Session.new(rules,runtime,data.encounters[id],p,"test")
func cmd(s,a,skill,t): check(s.set_command(a,skill,t)=="","cmd "+skill)
func inp(s,a,id,t=""):
	var v={"actor_id":a,"action_id":id}
	if t!="":v.target=t
	check(s.apply_input(v).accepted,"input "+id)
func step(s):
	check(s.resolve_round(),"resolve")
	print("round",s.engine.state.round-1," phase",s.engine.state.objective.phase," HP",s.engine.actor_by_id(H).hp,"/",s.engine.actor_by_id(L).hp," yun",s.engine.actor_by_id("char_yun_shu").get("hp",0)," outcome",s.engine.state.outcome)
	check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"round JSON replay")
func run():
	var s=make()
	cmd(s,H,"observe","char_yun_shu");cmd(s,L,"LYY_A03","char_yun_shu");step(s)
	cmd(s,H,"CO_01","char_yun_shu");step(s)
	while s.engine.state.objective.phase==1 and s.engine.state.outcome=="" and s.engine.state.round<15:
		cmd(s,H,"normal_attack","char_yun_shu")
		cmd(s,L,"normal_attack","char_yun_shu");step(s)
	if s.engine.state.outcome=="":
		for action in ["lure_second","break_second","lure_third","break_third"]:
			inp(s,H,action)
			if int(s.engine.state.round)%3==1: cmd(s,L,"LYY_A01","char_yun_shu")
			elif int(s.engine.state.round)%3==2: cmd(s,L,"LYY_A03","char_yun_shu")
			else: cmd(s,L,"guard_ally",H)
			step(s)
		inp(s,H,"board_boat");inp(s,L,"board_boat");step(s)
	check(s.engine.state.outcome=="victory","B02 victory")
	s=make("b03")
	for r in [1,2]:
		inp(s,H,"path_read");cmd(s,L,"LYY_A01" if r==1 else "guard_ally","lei_xingkong" if r==1 else H);step(s)
	for gate in ["gate_east","gate_west"]:
		inp(s,H,"mark_gate",gate);cmd(s,L,"normal_attack",gate);step(s)
	check(s.engine.state.outcome=="victory","B03 victory")
	print("CH05 combat ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
