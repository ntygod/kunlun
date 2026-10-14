extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_eight_world_actions.gd")
var failures:=0
var checks:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)
func context(id: String) -> Dictionary:
	var names:Dictionary={"route_ch08_hanshui":["ch08_hanshui_approach","hanshui_chain_waterway"],"repair_ch08_ballista":["ch08_ballista_repair","island_platform"],"rescue_ch08_l04":["L04","xiangyang_rescue_alley"]}
	return {"chapter":8,"current_token":"chapter8:test:1","revision":1,"scene_id":names[id][0],"phase":names[id][0],"map_id":"map_ch08_"+names[id][1],"control_actor_id":"char_liang_xiao","objective_id":id,"world_objects":{},"items":{},"actors":{},"choices":{},"inherited_choices":{},"knowledge":[]}
func go(model: RefCounted,anchor: String) -> void:
	var target:Vector2=model._p(model._anchor(anchor))
	var count:=0
	while model._p(model.state.position)!=target and count<200:
		var at:Vector2=model._p(model.state.position)
		var next:Vector2=model._path_step(at,target)
		if at==next:check(false,"reachable "+anchor+" from "+str(at));return
		var d:Vector2=(next-at)/16
		check(model.apply_input({"type":"move","dx":int(d.x),"dy":int(d.y)}).ok,"legal step to "+anchor)
		count+=1
	check(model._near(anchor),"arrived "+anchor)
func run_input(model: RefCounted,action: Dictionary) -> void:check(model.apply_input(action).ok,"input "+str(action))
func save_check(model: RefCounted) -> void:
	var other=Model.new()
	check(other.restore(model.snapshot(),context(model.puzzle_id)),"mid-route restore")
	check(Model._encoded(other.snapshot())==Model._encoded(model.snapshot()),"restored exact NPC and history")
	var corrupt:Dictionary=model.snapshot();corrupt.state.complete=not corrupt.state.complete
	check(not other.restore(corrupt,context(model.puzzle_id)),"reject mutated state")
func rescue(method: String,cancel: bool) -> void:
	var m=Model.new();check(m.begin("rescue_ch08_l04","test",context("rescue_ch08_l04")),"begin rescue")
	check(not m.apply_input({"type":"finish"}).ok,"no remote success")
	for a in ["beam","oil","passage"]:go(m,a);run_input(m,{"type":"interact"})
	run_input(m,{"type":"method","value":method})
	if method=="A":
		go(m,"beam");run_input(m,{"type":"support"})
		check(m._p(m.state.actor_positions.char_liang_xiao)==m._p(m._anchor("beam")),"Liang locked on support")
		if cancel:
			go(m,"child");run_input(m,{"type":"interact"});run_input(m,{"type":"cancel_support"})
			var before:Array=m.state.position.duplicate()
			check(m.state.position==before and m.state.supporting,"cancel no teleport or drop beam")
			save_check(m)
			while m.state.retreating and m.input_log.size()<1000:run_input(m,{"type":"wait"})
			check(m.state.control_actor_id==Model.H and not m.state.supporting,"safe stop then transfer control")
			go(m,"beam");run_input(m,{"type":"support"})
	else:
		check(not m.apply_input({"type":"open_stone"}).ok,"stone before fire denied")
		run_input(m,{"type":"pad"});go(m,"sand");run_input(m,{"type":"sand"});go(m,"oil");run_input(m,{"type":"extinguish"});go(m,"passage");run_input(m,{"type":"open_stone"})
		check(m.state.pad_ready and m.state.fire_out,"parallel snow station and fire")
	for victim in ["child","grandmother"]:
		if m._victim_id(victim) in m.state.rescued:continue
		go(m,victim);run_input(m,{"type":"interact"});go(m,"safe")
		save_check(m)
	if method=="A":
		run_input(m,{"type":"cancel_support"});run_input(m,{"type":"wait"})
	check(m.state.rescued.size()==2,"two actual rescue paths")
	for kind in ["spear","sabre"]:
		check(not m.apply_input({"type":"disarm","move":"redirect_spear"}).ok,"remote disarm denied")
		go(m,kind+"_intercept");run_input(m,{"type":"interact"})
		var right:String="redirect_spear" if kind=="spear" else "lower_sabre"
		check(not m.apply_input({"type":"disarm","move":"lower_sabre" if kind=="spear" else "redirect_spear"}).ok,"wrong angle remains threat")
		run_input(m,{"type":"disarm","move":right})
		check(not m.state.looters["npc_ch08_looter_"+kind].departed,"disarm not instant departure")
	while not m._all_departed() and m.input_log.size()<1000:run_input(m,{"type":"wait"})
	go(m,"safe");run_input(m,{"type":"escort"});go(m,"shelter")
	while not m._at_shelter() and m.input_log.size()<1000:run_input(m,{"type":"wait"})
	run_input(m,{"type":"shelter"});run_input(m,{"type":"talk"});run_input(m,{"type":"finish"})
	check(m.state.complete,"rescue complete "+method)
	check(not Model.replay_receipt(m.receipt(),context(m.puzzle_id)).is_empty(),"full proof replay "+method)
	check(not m.apply_input({"type":"finish"}).ok,"no duplicate archive")
	for path in m.state.victim_paths.values():
		for i in range(1,path.size()):
			var d:Vector2=m._p(path[i])-m._p(path[i-1]);check(absf(d.x)+absf(d.y)<=16,"victim continuous four-neighbour movement")
func _initialize() -> void:
	var m=Model.new()
	check(m.begin("route_ch08_hanshui","test",context("route_ch08_hanshui")),"begin boat chain")
	check(not m.apply_input({"type":"interact"}).ok,"remote boat rejected")
	check(not m.is_walkable(Vector2(192,208)),"deep water blocked")
	for a in ["boat_one","boat_two","boat_three","platform"]:go(m,a);run_input(m,{"type":"interact"})
	check(m.state.complete,"chain reaches platform")
	save_check(m)
	check(not Model.replay_receipt(m.receipt(),context(m.puzzle_id)).is_empty(),"route proof replay")
	m=Model.new();check(m.begin("repair_ch08_ballista","test",context("repair_ch08_ballista")),"begin repair")
	for pair in [["rivet","square"],["groove","long"],["wheel","round"]]:
		go(m,pair[0]);check(not m.apply_input({"type":"fit","part":pair[1]}).ok,"inspect before fit");run_input(m,{"type":"interact"});check(not m.apply_input({"type":"fit","part":"bad"}).ok,"reject wrong shape");run_input(m,{"type":"fit","part":pair[1]})
	go(m,"winch");run_input(m,{"type":"interact"});check(m.state.complete,"physical repair complete")
	rescue("A",false);rescue("A",true);rescue("B",false)
	var bad:=context("route_ch08_hanshui");bad.revision=NAN
	check(not m.begin("route_ch08_hanshui","test",bad),"reject NaN context atomically")
	print("CH08 WORLD: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
