extends SceneTree
const R=preload("res://scripts/puzzles/chapter_nine_puzzle_resolver.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
static func fixture(id:String)->Dictionary:
	return {"chapter":9,"current_token":"nine:"+id,"revision":1,"scene_id":"ch09_wood_bird_assembly" if id==R.IDS[1] else "ch09_pine_needle_lesson","actors":{"char_liang_xiao":{"hp":10},"char_axue":{"hp":236,"kind":"scene_support","status":"alive"}},"authorizations":["evt_ch09_pine_harvest_authorized"],"choices":{"choice_ch09_pine_prayer":"ch09_prayer_life"},"material_receipt":{"id":"evt_ch09_pine_harvest_authorized","source":"living_pine_after_prayer","owner":"scene","quantity":1,"parts":["body","left_wing","right_wing","tail","frame","linkage"],"prayer":"ch09_prayer_life"}}
func act(r:RefCounted,a:Dictionary,expected:bool=true)->void:
	var before:Dictionary=r.snapshot()
	check(r.apply_input(a).ok==expected,"action "+str(a))
	if not expected:check(r.snapshot()==before,"rejected action atomic")
	var copy:=R.new();check(copy.restore(JSON.parse_string(JSON.stringify(r.snapshot())),r.context),"JSON partial restore")
	check(copy.state==r.state,"JSON exact state")
func finish(r:RefCounted,assist:bool=false)->void:
	for i in range(180):
		if r.state.complete:break
		act(r,{"type":"assist_step_v1"} if assist else r.next_demo_action())
	check(r.state.complete,"reachable complete")
	check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context),"complete proof replays")
func run()->void:
	for id in R.IDS:
		var r:=R.new();check(r.begin(id,"test",fixture(id)),"begin")
		for bad in [{},{"type":[]},{"type":"finish","success":true},{"type":"select","part":{},"value":"light"},{"type":"place","pin":"start","x":true,"y":4},{"type":"place","pin":"start","x":1.5,"y":4},{"type":"set_phase","value":"drifted"},{"type":"sync","complete":true}]:act(r,bad,false)
		act(r,{"type":"finish"},false);act(r,{"type":"assist_step_v1"},false)
		finish(r)
		var corrupted:Dictionary=r.snapshot();corrupted.state.complete=false
		check(not R.new().restore(corrupted,r.context),"corrupt state rejected")
		var wrong:Dictionary=r.context.duplicate(true);wrong.current_token="other"
		check(not R.new().restore(r.snapshot(),wrong),"wrong token rejected")
	var pine:=R.new();pine.begin(R.IDS[0],"waits",fixture(R.IDS[0]))
	for pin in R.PINS:act(pine,{"type":"place","pin":StringName(pin),"x":R.PINS[pin][0],"y":R.PINS[pin][1]})
	act(pine,{"type":&"wait"});act(pine,{"type":"move","x":4,"y":4},false)
	act(pine,{"type":"wait_window"});act(pine,{"type":"move","x":4,"y":4})
	act(pine,{"type":"move","x":3,"y":3},false);finish(pine)
	check(pine.state.path.size()==12,"three actual waits + nine cells")
	# Exhaust the finite (cursor, phase) transition graph independently, then
	# exercise every reachable timing state with formal model operations.
	var reached:Dictionary={"-1:0":true};var queue:Array=[[-1,0]]
	while not queue.is_empty():
		var s:Array=queue.pop_front()
		var successors:Array=[[s[0],(s[1]+1)%3]]
		var n:int=s[0]+1
		if n<9 and (not {0:0,4:1,8:2}.has(n) or s[1]=={0:0,4:1,8:2}[n]):successors.append([n,(s[1]+1)%3])
		for t in successors:
			if t[0]==8:continue
			var key:String=str(t[0])+":"+str(t[1])
			if not reached.has(key):reached[key]=true;queue.append(t)
	check(reached.size()==27,"all 9 unfinished positions x3 phases reachable")
	for waits in range(9):
		var p:=R.new();p.begin(R.IDS[0],"multi",fixture(R.IDS[0]))
		for i in range(waits):act(p,{"type":"wait"})
		finish(p);check(p.state.gates==[0,4,8],"gates proved")
	var valid_loads:=0
	for left in ["light","heavy"]:
		for right in ["light","heavy"]:
			for tail in ["single","double"]:
				for frame in ["straight","flexible"]:
					for lp in [-1,1]:
						for ap in [-1,1]:
							var load:=R.new();load.begin(R.IDS[1],"arithmetic",fixture(R.IDS[1]))
							for pv in [["left_wing",left],["right_wing",right],["tail",tail],["frame",frame]]:check(load.apply_input({"type":"select","part":pv[0],"value":pv[1]}).ok,"finite material selection")
							for av in [["char_liang_xiao",lp],["char_axue",ap]]:check(load.apply_input({"type":"stand","actor":av[0],"value":av[1]}).ok,"finite position selection")
							var calc:Dictionary=load.calculation()
							if calc.mass<=21 and calc.torque==-1 and calc.strength>=2 and calc.balanced:valid_loads+=1
	check(valid_loads==1,"64 finite load configurations have one valid solution")
	for field in ["quantity","owner","source","parts","prayer"]:
		var bad_material:Dictionary=fixture(R.IDS[1]);bad_material.material_receipt[field]=false
		check(not R.new().begin(R.IDS[1],"bad-material",bad_material),"invalid material source rejected "+field)
	var bird:=R.new();bird.begin(R.IDS[1],"bird",fixture(R.IDS[1]))
	check(bird.calculation().mass==21 and bird.calculation().torque==-1,"approved arithmetic21/-1")
	act(bird,{"type":"select","part":"left_wing","value":"heavy"});check(bird.calculation().mass==23 and not bird.calculation().balanced,"heavy imbalance")
	act(bird,{"type":"select","part":"right_wing","value":"heavy"});check(bird.calculation().mass==25,"heavy overload")
	act(bird,{"type":"select","part":"tail","value":"single"});check(bird.calculation().torque==-4,"single tail fails")
	act(bird,{"type":"stand","actor":"char_axue","value":1});check(bird.calculation().torque==2,"rear station torque")
	for i in range(3):act(bird,{"type":"hint"})
	act(bird,{"type":"assist_step_v1"});act(bird,{"type":"retry"});check(bird.assistance_status()=="assisted","reset cannot erase assistance")
	finish(bird,true)
	check(bird.state.stage=="prepared" and bird.state.rail_index==0,"prepare does not fly")
	check(bird.state.installed.size()==6 and bird.state.construction.size()==3,"six parts three parallel beats")
	for who in R.ACTORS:
		var path:Array=bird.state.actor_paths[who]
		for i in range(1,path.size()):check(abs(path[i][0]-path[i-1][0])+abs(path[i][1]-path[i-1][1])==1,"real actor edge")
	var c:Dictionary=fixture(R.IDS[1]);c.scene_id="ch09_cloud_escape";c.current_token="escape";c.wood_bird_checkpoint=bird.snapshot();c.wood_bird_context=bird.context.duplicate(true)
	var flight:=R.new();check(flight.begin(R.IDS[1],"flight",c),"trusted prepared resume")
	check(not flight.state.complete and flight.assistance_status()=="assisted","resume stage reset, history retained")
	act(flight,{"type":"advance"},false);act(flight,{"type":"release"},false)
	act(flight,{"type":"crank"});act(flight,{"type":"release"});act(flight,{"type":"select","part":"tail","value":"single"},false)
	act(flight,{"type":"rail"});act(flight,{"type":"advance"},false)
	finish(flight)
	check(flight.state.stage=="drifted" and flight.state.rail_path==R.RAIL,"complete rail to drifted")
	check(flight.state.flags.size()==9,"all unique stage flags")
	var forged:Dictionary=c.duplicate(true);forged.wood_bird_checkpoint.state.stage="drifted"
	check(not R.new().begin(R.IDS[1],"fake",forged),"forged prefix fails")
	var unknown:=R.new();var uc:Dictionary=fixture(R.IDS[0]);uc.assistance_status="unknown";unknown.begin(R.IDS[0],"unknown",uc);act(unknown,{"type":"retry"});finish(unknown);check(unknown.assistance_status()=="unknown","unknown inherited")
	var limited:=R.new();limited.begin(R.IDS[0],"limited",fixture(R.IDS[0]))
	for i in range(4):limited.apply_input(limited.next_demo_action())
	check(limited.state.cursor==0,"verified gate prefix")
	for i in range(R.SEGMENT_LIMIT):limited.apply_input({"type":"wait"})
	act(limited,{"type":"wait"},false);act(limited,{"type":"retry"})
	check(limited.state.cursor==0 and limited.state.gates==[0],"limit retains actual verified prefix")
	check(limited.assistance_status()=="unknown","discarded history not manual")
	act(limited,{"type":"reset_after_limit","hint":0,"assisted":0},false)
	finish(limited)
	var limit_assist:=R.new();limit_assist.begin(R.IDS[0],"limit-assisted",fixture(R.IDS[0]))
	for i in range(3):limit_assist.apply_input({"type":"hint"})
	limit_assist.apply_input({"type":"assist_step_v1"})
	for i in range(R.SEGMENT_LIMIT):limit_assist.apply_input({"type":"wait"})
	act(limit_assist,{"type":"retry"});check(limit_assist.assistance_status()=="assisted","limit retains assist without claiming hash authenticates it")
	finish(limit_assist)
	print("CHAPTER NINE PUZZLES %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
