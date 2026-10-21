extends SceneTree
const R=preload("res://scripts/puzzles/chapter_ten_puzzle_resolver.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
static func fixture(id:String)->Dictionary:return {"chapter":10,"current_token":"ch10:"+id,"scene_id":R.SCENES[R.IDS.find(id)],"actors":{"char_liang_xiao":{"id":"char_liang_xiao","hp":1404,"mp":122}}}
func act(r:RefCounted,a:Dictionary,want:bool=true)->void:
	var before:Dictionary=r.snapshot();var original:Dictionary=r.context.duplicate(true)
	check(r.apply_input(a).ok==want,"command "+str(a))
	if not want:check(r.snapshot()==before,"invalid command atomic")
	check(r.context==original,"resources/context untouched")
	var clone:=R.new();check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot())),original),"JSON replay")
	check(clone.state==r.state,"exact restored state")
func finish(r:RefCounted,assist:bool=false)->void:
	for i in range(30):
		if r.state.complete:break
		act(r,{"type":"assist_step_v1"} if assist else r.next_demo_action())
	check(r.state.complete,"reachable completed model")
	check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context),"real proof replay")
func run()->void:
	for id in R.IDS:
		var r:=R.new();check(r.begin(id,"manual",fixture(id)),"valid begin")
		for bad in [{},{"type":[]},{"type":"finish"},{"type":"step","complete":true},{"type":"stone","index":true,"row":1},{"type":"stone","index":1.5,"row":1},{"type":"axle","length":3.5},{"type":"reset_after_limit","hint":3,"assisted":0},{"type":"assist_step_v1"}]:act(r,bad,false)
		finish(r)
		act(r,{"type":"retry"},false)
		var fake:Dictionary=r.snapshot();fake.state.complete=false;check(not R.new().restore(fake,r.context),"forged completion rejected")
		fake=r.snapshot();fake.input_log.pop_back();check(not R.new().restore(fake,r.context),"missing command rejected")
		fake=r.snapshot();fake.version=true;check(not R.new().restore(fake,r.context),"bool version rejected")
		var c:Dictionary=r.context.duplicate(true);c.current_token="other";check(not R.new().restore(r.snapshot(),c),"other token rejected")
		var old:Dictionary=r.snapshot();check(not r.restore(fake,r.context) and r.snapshot()==old,"failed restore atomic")
		var proof:Dictionary=r.receipt();proof.assisted=true;check(not R.replay_receipt(proof,id,"manual",r.context),"proof flags checked")
		var assisted:=R.new();assisted.begin(id,"assist",fixture(id))
		for i in range(3):act(assisted,{"type":"hint"})
		act(assisted,{"type":"assist_step_v1"});act(assisted,{"type":"retry"});finish(assisted,true)
		check(assisted.assistance_status()=="assisted" and not assisted.receipt().manual_process_verified,"retry preserves assistance")
	var ox:=R.new();ox.begin(R.IDS[0],"jam",fixture(R.IDS[0]));act(ox,{"type":"step"});check(ox.state.jammed and ox.state.steps==0,"bad geometry visibly jams")
	act(ox,{"type":"cargo","bundle":"heavy","position":-3});finish(ox)
	var contexts:Dictionary=fixture(R.IDS[0]);contexts.actors.char_liang_xiao.hp=true;check(not R.new().begin(R.IDS[0],"bad",contexts),"boolean HP rejected")
	contexts=fixture(R.IDS[0]);contexts.actors.char_liang_xiao.id="char_axue";check(not R.new().begin(R.IDS[0],"bad",contexts),"actor substitution rejected")
	var stone:=R.new();stone.begin(R.IDS[1],"failed",fixture(R.IDS[1]));act(stone,{"type":"breathe"},false);act(stone,{"type":"pulse"});check(not stone.state.last_safe and stone.state.breaths==0,"unredirected force cannot grant breath")
	act(stone,{"type":"stone","index":0,"row":1},false);act(stone,{"type":"retry"});finish(stone)
	var equations:=0
	for left in [-3,-2,-1,1,2,3]:
		for right in [-3,-2,-1,1,2,3]:
			if left==right:continue
			var model:=R.new();model.begin(R.IDS[0],"balance",fixture(R.IDS[0]))
			# Use legal temporary positions so actual command order can reach all pairs.
			if left==model.state.cargo.heavy:model.apply_input({"type":"cargo","bundle":"heavy","position":-2})
			if right==model.state.cargo.light and left==model.state.cargo.light:model.apply_input({"type":"cargo","bundle":"light","position":3})
			if not model.apply_input({"type":"cargo","bundle":"light","position":left}).ok:
				model.apply_input({"type":"cargo","bundle":"heavy","position":3 if left!=3 else -3});model.apply_input({"type":"cargo","bundle":"light","position":left})
			check(model.apply_input({"type":"cargo","bundle":"heavy","position":right}).ok,"finite cargo assignment")
			model.apply_input({"type":"axle","length":3});model.apply_input({"type":"phase","side":"right","value":2})
			check(model.calculation().valid==(2*left+3*right==0),"independent balance equation")
			if model.calculation().valid:
				equations+=1
				for i in range(3):act(model,{"type":"step"})
				check(model.state.complete,"both balanced mirror configurations usable")
	check(equations==2,"two opposite-side balance solutions")
	var solutions:=0
	for a in range(5):
		for b in range(5):
			for c in range(5):
				for bits in range(8):
					var model:=R.new();model.begin(R.IDS[1],"solver",fixture(R.IDS[1]))
					for i in range(3):
						model.apply_input({"type":"stone","index":i,"row":[a,b,c][i]});model.apply_input({"type":"turn","index":i,"orientation":"/" if bits&(1<<i)==0 else "\\"})
					var safe:bool=true;var used:Array=[]
					for lane in [1,2,3]:
						var flow:Dictionary=model.trace(lane);safe=safe and flow.safe
						for index in flow.used:
							if index not in used:used.append(index)
					if safe and used.size()==3:
						solutions+=1
						for i in range(3):
							check(model.apply_input({"type":"pulse"}).ok and model.state.awaiting_breath,"solved force creates gap")
							check(not model.state.complete,"pulse alone does not grant breath")
							check(model.apply_input({"type":"breathe"}).ok,"gap consumed by breath")
						check(model.state.complete,"solver path completes")
	check(solutions>0,"finite stone arrangement actually solvable")
	var cap:=R.new();cap.begin(R.IDS[0],"cap",fixture(R.IDS[0]));cap.apply_input({"type":"hint"})
	for i in range(R.MAX_LOG-1):check(cap.apply_input({"type":"axle","length":2 if i%2==0 else 4}).ok,"bounded history actual actions")
	check(cap.apply_input({"type":"retry"}).ok,"full log escape")
	check(cap.input_log.size()==1 and cap.assistance_status()=="unknown" and cap.state.hint==1,"trimmed history honest")
	finish(cap);check(not cap.receipt().manual_process_verified,"trimmed history cannot claim manual")
	print("CH10 PUZZLES: %d checks, %d failures; %d valid stone arrangements"%[checks,failures,solutions]);quit(1 if failures else 0)
