extends SceneTree
const R=preload("res://scripts/puzzles/chapter_seven_puzzle_resolver.gd")
const F=preload("res://scripts/puzzles/chapter_seven_formation.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
static func fixture(id:String,method:String="joy") -> Dictionary:
	var actors:Dictionary={"char_liang_xiao":{"id":"char_liang_xiao","hp":911}}
	for unit in F.UNITS.slice(1):actors[unit]={"id":unit,"status":"alive","kind":"scene_support"}
	return {"chapter":7,"current_token":"chapter_seven:"+id,"revision":1,"phase":id,"scene_id":id,"objective_id":id,"scope":"ch07_qincha_drill" if id=="formation_ch07_drill" else "ch07_counter_ambush","method":method,"knowledge":["grain_dispatch_verified","grain_rations_verified","grain_loss_verified"],"actors":actors,"items":{},"world_objects":{},"choices":{},"inherited_choices":{},"fixed_level":31}
func act(r:RefCounted,a:Dictionary,expected:bool=true,replay:bool=true) -> void:
	check(r.apply_input(a).ok==expected,"input "+str(a))
	if replay:
		var copy:=R.new();check(copy.restore(JSON.parse_string(JSON.stringify(r.snapshot())),r.context),"JSON partial replay");check(copy.state==r.state,"partial exact")
func finish(r:RefCounted,assist:bool=false) -> void:
	for i in range(1800):
		if r.state.complete:break
		act(r,{"type":"assist_step_v1"} if assist else r.next_demo_action(),true,i%50==0)
	check(r.state.complete,"complete "+r.puzzle_id)
	check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context),"proof replays")
func run() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=7007
	for trial in range(250):
		var p:Array=[]
		while p.size()<6:
			var cell:Array=[rng.randi_range(-5,5),rng.randi_range(-5,5)]
			if cell not in p:p.append(cell)
		var target:Array=F.targets("R" if trial%2==0 else "S","E" if trial%3==0 else "N",[1,-1])
		var plan:Array=F.plan(p,target);check(not plan.is_empty(),"random board plan %d"%trial)
		for move in plan:
			check(F.path(p,move.unit,move.target)==move.path,"deterministic shortest route")
			for cell in move.path:
				check(abs(cell[0]-p[move.unit][0])+abs(cell[1]-p[move.unit][1])==1 and cell not in p,"every path step collision free")
				p[move.unit]=cell
		check(p==target,"random plan reaches target")
	for shape in ["R","S"]:
		for orientation in ["N","E","S","W"]:
			for center in [[0,0],[1,-2],[-2,1]]:
				var fit:Dictionary=F.fit(F.targets(shape,orientation,center),shape)
				check(fit=={"orientation":orientation,"center":center},"six-role rotation/translation fit")
	var dead:=fixture("formation_ch07_drill");dead.actors.npc_wang_ke.status="dead"
	check(not R.new().begin("formation_ch07_drill","dead",dead),"dead support cannot substitute")
	var missing_actor:=fixture("formation_ch07_drill");missing_actor.actors.erase("npc_tutuha")
	check(not R.new().begin("formation_ch07_drill","missing",missing_actor),"missing support denied")
	var duplicate_actor:=fixture("formation_ch07_drill");duplicate_actor.actors.npc_tutuha.id="npc_zhao_shan"
	check(not R.new().begin("formation_ch07_drill","duplicate",duplicate_actor),"Zhao cannot replace surviving friend")
	var enclosed:Array=[[0,0],[0,-1],[1,0],[0,1],[-1,0],[5,5]]
	check(F.path(enclosed,0,[3,3]).is_empty(),"surrounded unit cannot teleport")
	check(not F.plan(enclosed,F.targets("S","E",[0,0])).is_empty(),"planner clears surrounding units")
	for id in R.IDS:
		var r:=R.new();check(r.begin(id,"test:"+id,fixture(id)),"begin "+id)
		var original:Dictionary=r.snapshot();check(not r.apply_input({"type":"restart_after_limit","hint":0,"assisted":0,"failures":0,"discarded_log_hash":"0".repeat(64)}).ok,"no public reset injection");check(r.snapshot()==original,"atomic rejection")
		act(r,{"type":"assist_step_v1"},false)
		if id.begins_with("formation"):
			act(r,{"type":"shoot"},false)
			act(r,{"type":"move","unit":6,"x":0,"y":0},false)
			act(r,{"type":"move","unit":0,"x":-2,"y":2},false)
			act(r,{"type":"move","unit":0,"x":-3,"y":0})
			act(r,{"type":"horn"},false)
			act(r,{"type":"step_move"});act(r,{"type":"step_move"})
			act(r,{"type":"undo_move"});act(r,{"type":"undo_move"},false)
			check(r.state.positions==original.state.positions,"one transaction undo")
		else:act(r,{"type":"finish"},false)
		finish(r)
		var proof:Dictionary=r.receipt();proof.final_state.complete=false;check(not R.replay_receipt(proof,id,r.attempt_id,r.context),"forged final denied")
		var other:Dictionary=r.context.duplicate(true);other.current_token+="other";check(not R.replay_receipt(r.receipt(),id,r.attempt_id,other),"stale token denied")
		var saved:Dictionary=r.snapshot();saved.state.complete=false;var clean:=R.new();clean.begin(id,"test:"+id,fixture(id));var before:Dictionary=clean.snapshot();check(not clean.restore(saved,clean.context),"corrupt snapshot rejected");check(clean.snapshot()==before,"failed restore atomic")
		if id=="formation_ch07_drill":check(not R.replay_receipt(r.receipt(),"formation_ch07_regroup",r.attempt_id,fixture("formation_ch07_regroup")),"drill proof not regroup")
		var assisted:=R.new();assisted.begin(id,"assist:"+id,fixture(id,"truth"))
		for i in range(3):act(assisted,{"type":"hint"})
		finish(assisted,true);check(assisted.state.assisted,"assisted retained")
	var grain:=R.new();grain.begin("grain_ch07_accounts","grain",fixture("grain_ch07_accounts"))
	for bad in ["-1","1.5","abc","999999999999","40001",""]:
		act(grain,{"type":"value","column":"wet","value":bad},false)
	var missing:=fixture("grain_ch07_accounts");missing.knowledge.pop_back();check(not R.new().begin("grain_ch07_accounts","missing",missing),"three actual investigations required")
	# Bounded history: restart metadata is only emitted internally and marked unverified.
	for i in range(R.MAX_LOG-grain.input_log.size()):grain.apply_input({"type":"hint"})
	act(grain,{"type":"retry"});check(grain.state.history_reset and grain.state.hint==3,"rollover unverified history explicit");finish(grain)
	print("CHAPTER_SEVEN_PUZZLES ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
