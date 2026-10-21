extends SceneTree
const R=preload("res://scripts/puzzles/chapter_eleven_puzzle_resolver.gd")
const PuzzlePanel=preload("res://scripts/ui/chapter_eleven_puzzle_panel.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(v:bool,label:String)->void:
	checks+=1
	if not v:failures+=1;push_error(label)
static func fixture(id:String,method:String="a")->Dictionary:return {"chapter":11,"scene_id":R.SCENES[R.IDS.find(id)],"current_token":"test:"+id,"r04_method":method,"actors":{"char_liang_xiao":{"hp":100},"char_hua_xiaoshuang":{"hp":100}}}
func advance(r:RefCounted,a:Dictionary,want:bool=true)->void:
	var before:Dictionary=r.snapshot();var context:Dictionary=r.context.duplicate(true)
	check(r.apply_input(a).ok==want,"command "+str(a))
	if not want:check(before==r.snapshot(),"bad command atomic")
	check(context==r.context,"context unchanged")
	var clone:=R.new();check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot())),context),"JSON replay")
func finish(r:RefCounted,assisted:bool=false)->void:
	for i in range(40):
		if r.state.complete:break
		advance(r,{"type":"assist_step_v1"} if assisted else r.next_demo_action())
	check(r.state.complete,"finite solvable")
	check(R.replay_receipt(r.proof(),r.puzzle_id,r.attempt_id,r.context),"exact proof")
func run()->void:
	for id in R.IDS:
		for method in ["a","b"]:
			var r:=R.new();check(r.begin(id,"manual",fixture(id,method)),"begin")
			for bad in [{"type":[]},{"type":"finish"},{"type":"act","action":"recheck"},{"type":"rotate","index":true,"value":1},{"type":"assist_step_v1"},{"type":"reset_after_limit","hint":3,"assisted":0}]:advance(r,bad,false)
			finish(r)
			var fake:Dictionary=r.snapshot();fake.state.complete=false;var before:Dictionary=r.snapshot()
			check(not r.restore(fake,r.context) and before==r.snapshot(),"forged restore atomic")
			var wrong:Dictionary=r.context.duplicate(true);wrong.current_token="stale";check(not R.new().restore(r.snapshot(),wrong),"stale rejected")
			var assisted:=R.new();assisted.begin(id,"assist",fixture(id,method))
			for n in range(3):advance(assisted,{"type":"hint"})
			advance(assisted,{"type":"assist_step_v1"});advance(assisted,{"type":"retry"});finish(assisted,true)
			check(assisted.proof().assisted and not assisted.proof().manual_process_verified,"assistance retained")
	var needle:=R.new();needle.begin(R.IDS[0],"needle",fixture(R.IDS[0]))
	advance(needle,{"type":"act","action":"locate_chest"},false)
	for target in needle.observations():advance(needle,{"type":"observe","target":target})
	advance(needle,{"type":"act","action":"locate_arm"});check(needle.state.stage==0,"wrong zone noninjury")
	for method in ["a","b"]:
		var triage:=R.new();triage.begin(R.IDS[3],"triage",fixture(R.IDS[3],method))
		for target in triage.observations():advance(triage,{"type":"observe","target":target})
		advance(triage,{"type":"act","action":"hold_constable" if method=="b" else "porridge_farmer"},false)
		finish(triage)
	var medicine:=R.new();medicine.begin(R.IDS[4],"medicine",fixture(R.IDS[4]))
	for target in medicine.observations():advance(medicine,{"type":"observe","target":target})
	advance(medicine,{"type":"act","action":"doctor_order"});advance(medicine,{"type":"act","action":"liang_chop"})
	advance(medicine,{"type":"act","action":"simmer"},false)
	advance(medicine,{"type":"heat","value":3});advance(medicine,{"type":"act","action":"simmer"},false)
	advance(medicine,{"type":"act","action":"doctor_bind"},false);finish(medicine)
	var yaer:=R.new();yaer.begin(R.IDS[2],"yaer",fixture(R.IDS[2]))
	for target in yaer.observations():advance(yaer,{"type":"observe","target":target})
	advance(yaer,{"type":"act","action":"doctor_needle"});advance(yaer,{"type":"act","action":"doctor_medicine"})
	advance(yaer,{"type":"act","action":"practice"},false);advance(yaer,{"type":"act","action":"later_visit"});advance(yaer,{"type":"act","action":"practice"})
	advance(yaer,{"type":"act","action":"practice"},false);check(not yaer.state.complete,"one visit cannot instant cure");finish(yaer)
	var valid:=0
	for a in range(3):
		for b in range(3):
			for c in range(3):
				for polarity in range(8):
					var r:=R.new();r.begin(R.IDS[1],"grid",fixture(R.IDS[1]))
					for target in r.observations():r.apply_input({"type":"observe","target":target})
					for i in range(3):
						r.apply_input({"type":"rotate","index":i,"value":[a,b,c][i]});r.apply_input({"type":"polarity","index":i,"value":(polarity>>i)&1})
					r.apply_input({"type":"flow"})
					var expected:bool=a==1 and b==1 and c==0 and polarity==2
					check(r.state.complete==expected,"independent route/polarity enumeration")
					if r.state.complete:valid+=1
	check(valid==1,"exact single route solution among216")
	for id in R.IDS:
		for dimensions in [Vector2(568,290),Vector2(1100,570)]:
			var r:=R.new();r.begin(id,"panel",fixture(id));var panel:=PuzzlePanel.new();root.add_child(panel);panel.size=dimensions
			panel.input_submitted.connect(func(action:Dictionary):r.apply_input(action);panel.render(r.get_view()))
			panel.render(r.get_view());await process_frame;await process_frame
			check(panel.get_combined_minimum_size().x<=dimensions.x,"panel width")
			check(panel.get_combined_minimum_size().y<=dimensions.y,"panel height")
			for i in range(3):panel._buttons.hint.pressed.emit()
			panel._toggle_demo()
			for i in range(40):
				if r.state.complete:break
				panel._tick()
			check(r.state.complete and r.proof().assisted,"panel real assisted command sequence")
			panel.hide();check(not panel._demo_running,"hide stops")
			panel.queue_free();await process_frame
	print("CH11 PUZZLES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
