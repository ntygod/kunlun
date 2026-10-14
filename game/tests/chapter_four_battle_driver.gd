extends RefCounted
## Reusable public-input battle routes. No state writes, fake outcomes or rewards.
## Use .errors to inspect failures, or provide a check(bool, message) callback.
const H := "char_liang_xiao"
const L := "char_liu_yingying"
const F := "char_huo_zhenren"
var errors: Array[String] = []
var checker: Callable
func _init(check_callback: Callable = Callable()) -> void:
	checker = check_callback
func check(ok: bool, message: String) -> void:
	if not ok: errors.append(message)
	if checker.is_valid(): checker.call(ok,message)
func inp(s: ChapterFourEncounter,actor: String,action: String,destination: String = "") -> void:
	var input := {"actor_id":actor,"action_id":action}
	if destination != "": input["destination" if action == "move" else "target"] = destination
	var result := s.apply_input(input)
	check(result.accepted,"input %s %s: %s" % [actor,action,result])
func cmd(s: ChapterFourEncounter,actor: String,skill: String,target: String) -> void: check(s.set_command(actor,skill,target)=="","command "+skill)
func resolve(s: ChapterFourEncounter) -> void:
	check(s.resolve_round(),"resolve")
func lamp(s: ChapterFourEncounter) -> void:
	inp(s,H,"move","lamp");cmd(s,L,"LYY_A02",F);resolve(s)
	inp(s,H,"drop_lamp");inp(s,L,"move","side");resolve(s)
	inp(s,H,"move","window");inp(s,L,"clear_civilians");resolve(s)
	inp(s,H,"clear_window");inp(s,L,"move","window");resolve(s)
	inp(s,H,"cover");inp(s,L,"secure_anchor");resolve(s)
func oil(s: ChapterFourEncounter) -> void:
	inp(s,H,"move","side");inp(s,L,"move","jar");resolve(s)
	inp(s,H,"clear_civilians");inp(s,L,"spill_oil");resolve(s)
	inp(s,H,"move","window");cmd(s,L,"LYY_A02",F);resolve(s)
	inp(s,H,"clear_window");inp(s,L,"move","window");resolve(s)
	inp(s,H,"cover");inp(s,L,"secure_anchor");resolve(s)
func low_route(s: ChapterFourEncounter) -> void:
	# Read the flame/area tells and kite the pursuing guard via the lamp-window
	# escape anchors. Both units spend one normal action each round.
	while s.engine.alive(s.engine.actor_by_id(F)) and s.engine.state.outcome == "":
		inp(s,H,"move","lamp" if s.engine.state.objective.positions[H] == "window" or s.engine.state.objective.positions[H] == "table" else "window")
		cmd(s,L,"LYY_A02",F);resolve(s)
	while s.engine.alive(s.engine.actor_by_id("ch04_guard")) and s.engine.state.outcome == "":
		inp(s,H,"move","lamp" if s.engine.state.objective.positions[H] == "window" else "window")
		cmd(s,L,"LYY_A02" if int(s.engine.actor_by_id(L).mp)>=12 else "normal_attack","ch04_guard");resolve(s)
	if s.encounter.context.environment_method == "lamp":
		if s.engine.state.objective.positions[H] != "lamp":
			inp(s,H,"move","lamp");inp(s,L,"move","side");resolve(s)
		else:
			cmd(s,H,"self_guard",H);inp(s,L,"move","side");resolve(s)
		inp(s,H,"drop_lamp");inp(s,L,"clear_civilians");resolve(s)
		inp(s,H,"move","window");inp(s,L,"move","window");resolve(s)
	else:
		inp(s,H,"move","side" if s.engine.state.objective.positions[H] == "window" else "table");inp(s,L,"move","jar");resolve(s)
		if s.engine.state.objective.positions[H] != "side":
			inp(s,H,"move","side");cmd(s,L,"self_guard",L);resolve(s)
		inp(s,H,"clear_civilians");inp(s,L,"spill_oil");resolve(s)
		inp(s,H,"move","window");inp(s,L,"move","window");resolve(s)
		cmd(s,H,"self_guard",H);cmd(s,L,"self_guard",L);resolve(s)
	# Clearing the latch and hanging the rope remain separate actions after combat.
	inp(s,H,"clear_window");cmd(s,L,"self_guard",L);resolve(s)
	inp(s,H,"cover");inp(s,L,"secure_anchor");resolve(s)

func r02(s: ChapterFourEncounter) -> void:
	inp(s,H,"move","lamp");cmd(s,L,"LYY_A02","r02_guard_west");resolve(s)
	cmd(s,H,"self_guard",H);cmd(s,L,"LYY_A01","r02_guard_east");resolve(s)
	for enemy in ["r02_guard_west","r02_guard_east"]:
		while s.engine.alive(s.engine.actor_by_id(enemy)) and s.engine.state.outcome == "":
			inp(s,H,"move","lamp" if s.engine.state.objective.positions[H] in ["table","window"] else "window")
			cmd(s,L,"LYY_A02" if int(s.engine.actor_by_id(L).mp)>=12 else "normal_attack",enemy);resolve(s)
	if s.engine.state.outcome != "": return
	for destination in ["jar","window"]:
		cmd(s,H,"self_guard",H);inp(s,L,"move",destination);resolve(s)
	cmd(s,H,"self_guard",H);inp(s,L,"take_documents");resolve(s)

func r02_disarm(s: ChapterFourEncounter) -> void:
	# Five-round nonlethal retrieval: both guards retain full HP and lose weapons.
	inp(s,H,"move","lamp");inp(s,L,"disarm","r02_guard_west");resolve(s)
	inp(s,H,"move","window");inp(s,L,"move","jar");resolve(s)
	inp(s,H,"move","lamp");inp(s,L,"disarm","r02_guard_east");resolve(s)
	inp(s,H,"move","window");inp(s,L,"move","window");resolve(s)
	inp(s,H,"move","lamp");inp(s,L,"take_documents");resolve(s)
