extends SceneTree
const R=preload("res://scripts/puzzles/chapter_twelve_puzzle_resolver.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(v:bool,label:String)->void:
	checks+=1
	if not v:failures+=1;push_error(label)
static func fixture(id:String,method:String="a")->Dictionary:return {"chapter":12,"scene_id":R.SCENES[R.IDS.find(id)],"current_token":"test:"+id,"r05_method":method,"actors":{"char_liang_xiao":{"hp":100},"char_hua_xiaoshuang":{"hp":100},"char_huasheng":{"hp":100}}}
func advance(r:RefCounted,a:Dictionary,want:bool=true)->void:
	var before:Dictionary=r.snapshot();var context:Dictionary=r.context.duplicate(true)
	check(r.apply_input(a).ok==want,"command "+str(a))
	if not want:check(before==r.snapshot(),"bad command atomic")
	check(context==r.context,"context unchanged")
	var clone:=R.new();check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot())),context),"JSON replay")
func finish(r:RefCounted,assisted:bool=false)->void:
	for i in range(60):
		if r.state.complete:break
		advance(r,{"type":"assist_step_v1"} if assisted else r.next_demo_action())
	check(r.state.complete,"finite solvable")
	check(R.replay_receipt(r.proof(),r.puzzle_id,r.attempt_id,r.context),"exact proof")
func observe(r:RefCounted)->void:
	for target in r.observations():advance(r,{"type":"observe","target":target})
func permutations(items:Array)->Array:
	if items.is_empty():return [[]]
	var out:Array=[]
	for i in range(items.size()):
		var rest:Array=items.duplicate();rest.remove_at(i)
		for suffix in permutations(rest):out.append([items[i]]+suffix)
	return out
func run()->void:
	for id in R.IDS:
		for method in ["a","b"]:
			var r:=R.new();check(r.begin(id,"manual",fixture(id,method)),"begin")
			for bad in [{"type":[]},{"type":"finish"},{"type":"act","action":"doctor_review"},{"type":"swap","left":true,"right":1},{"type":"assist_step_v1"},{"type":"reset_after_limit","hint":3,"assisted":0}]:advance(r,bad,false)
			finish(r)
			var fake:Dictionary=r.snapshot();fake.state.complete=false;var before:Dictionary=r.snapshot()
			check(not r.restore(fake,r.context) and before==r.snapshot(),"forged restore atomic")
			var wrong:Dictionary=r.context.duplicate(true);wrong.current_token="stale";check(not R.new().restore(r.snapshot(),wrong),"stale rejected")
			var assisted:=R.new();assisted.begin(id,"assist",fixture(id,method))
			for n in range(3):advance(assisted,{"type":"hint"})
			advance(assisted,{"type":"assist_step_v1"});advance(assisted,{"type":"retry"});finish(assisted,true)
			check(assisted.proof().assisted and not assisted.proof().manual_process_verified,"assistance retained")
	var care:=R.new();care.begin(R.IDS[0],"care",fixture(R.IDS[0]));observe(care)
	advance(care,{"type":"act","action":"later_visit"},false);advance(care,{"type":"act","action":"bring_water"});advance(care,{"type":"act","action":"bring_water"},false)
	finish(care);check(care.state.visits==[1,14,30,60],"four distinct dated visits")
	var supply:=R.new();supply.begin(R.IDS[1],"supply",fixture(R.IDS[1]));observe(supply)
	advance(supply,{"type":"supply","patient":"child","item":"water"},false);finish(supply);check(supply.state.supplies=={"water":0,"blanket":0,"cloth":0},"finite stock conserved")
	for method in ["a","b"]:
		var rescue:=R.new();rescue.begin(R.IDS[3],"rescue",fixture(R.IDS[3],method));observe(rescue)
		advance(rescue,{"type":"act","action":"pull_shaft"},false);advance(rescue,{"type":"lift"},false);advance(rescue,{"type":"support","position":2})
		if method=="b":advance(rescue,{"type":"lift"},false)
		advance(rescue,{"type":"act","action":"rescue_elder"},false);finish(rescue)
		check(rescue.state.blade_broken==(method=="b"),"distinct safe rescue methods")
	var valid:=0
	for layout in permutations([0,1,2,3,4]):
		for reverse in [0,1]:
			var r:=R.new();r.begin(R.IDS[2],"grid",fixture(R.IDS[2]));observe(r)
			for i in range(5):
				if r.state.slots[i]!=layout[i]:r.apply_input({"type":"swap","left":i,"right":r.state.slots.find(layout[i])})
			r.apply_input({"type":"direction","reverse":reverse});r.apply_input({"type":"pulse"})
			var expected:bool=layout==([0,1,2,3,4] if reverse==1 else [0,4,3,2,1])
			check((r.state.pulses==1)==expected,"independent240layout-direction cases")
			if expected:
				valid+=1;advance(r,{"type":"swap","left":1,"right":2},false);finish(r);check(r.state.complete,"three actual pulses including alternate demo continuation")
	check(valid==2,"two geometrically reversed layouts")
	print("CH12 PUZZLES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
