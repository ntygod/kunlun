extends SceneTree
const R=preload("res://scripts/puzzles/chapter_six_puzzle_resolver.gd")
const UI=preload("res://scripts/ui/chapter_six_puzzle_panel.gd")
const Preview=preload("res://tests/preview_chapter_six_puzzles.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fixture(id:String,method:String="") -> Dictionary:return Preview.fixture(id,method)
func create(id:String,method:String="") -> RefCounted:
	var r:=R.new();check(r.begin(id,id+":test",fixture(id,method)),"begin "+id);return r
func conservation(r:RefCounted) -> void:
	var s:Dictionary=r.state
	if r.puzzle_id=="basket_ch06_weave":
		check(s.raw.size()*3+s.loose.size()+s.woven.size()==6,"ordinary bamboo unit conservation")
		var ids:Array=s.loose+s.woven
		var unique:Dictionary={}
		for n in ids:unique[n]=true
		check(ids.size()==unique.size(),"ordinary strips never duplicate")
	if r.puzzle_id=="r03":
		check(s.bundle*6+s.loose.size()+s.woven.size()==6,"single fine bundle conservation")
		check(s.product in ["",s.method],"one selected product only")
	if r.puzzle_id=="l02":
		check(s.raw.size()*4+s.pieces.size()*2+s.installed_pieces.size()*2==8,"both pine lengths conserved")
		check(s.locations.size()==4,"four actual reusable/borrowed components")
		check(s.resin_left+s.resined.size()==3,"three resin coats conserved")
		for key in s.locations:check(s.locations[key] in ["site","table","waterwheel","cart"],"component has one location")
func act(r:RefCounted,a:Dictionary,expected:bool=true) -> void:
	check(r.apply_input(a).ok==expected,"action "+str(a))
	conservation(r)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(r.snapshot()));var copy:=R.new()
	check(copy.restore(saved,r.context),"JSON input replay")
	check(copy.state==r.state,"exact partial state")
	if r.state.complete:check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context),"strict proof replay")
func finish(r:RefCounted,assist:bool=false) -> void:
	for i in range(120):
		if r.state.complete:break
		act(r,{"type":"assist_step_v1"} if assist else r.next_demo_action())
	check(r.state.complete,"complete "+r.puzzle_id)
func manual_ui(panel:Control,a:Dictionary) -> void:
	var button:String=""
	match a.type:
		"read_note":panel._selects.note.select(a.note);button="note"
		"observe_star","observe_line":
			if a.type=="observe_line":panel._selects.line.select(a.line)
			button="observe"
		"predict_star","sword_vector":
			panel._numbers.x.value=a.x;panel._numbers.y.value=a.y;button="predict" if a.type=="predict_star" else "vector"
		"read_principle":button="principle"
		"verify_line":panel._selects.line.select(a.line);panel._numbers.sum.value=a.sum;button="verify"
		"step_line":panel._selects.line.select(a.line);panel._numbers.endpoint.value=a.endpoint;button="step"
		"split_bamboo":panel._selects.bamboo.select(a.bamboo);button="split"
		"split_fine":button="split"
		"weave_row":panel._selects.strip.select(a.strip);panel._selects.pattern.select(0 if a.pattern==21 else 1);button="weave"
		"bind_rim":button="rim"
		"load_test","test_product":button="test"
		"set_heat":panel._selects.heat.select(a.level);button="heat"
		"bake_tick":button="bake"
		"fit_part":panel._selects.part.select(0 if a.part in ["reed","inner"] else 1);button="part"
		"inspect_reuse","recover_reuse","repair_reuse":
			panel._selects.reuse.select(0 if a.part=="sleeve" else 1);button={"inspect_reuse":"inspect","recover_reuse":"recover","repair_reuse":"repair"}[a.type]
		"cut_pine":panel._selects.pine.select(a.log);panel._numbers.cut.value=a.length;button="cut"
		"join","resin","lift","test_repair":
			panel._selects.job.select(["waterwheel","cart","plough"].find(a.job));button="test" if a.type=="test_repair" else a.type
			if a.type=="join":panel._numbers.fit.value=a.fit
		"finish":button="finish"
	check(not button.is_empty(),"manual real control exists "+a.type)
	if not button.is_empty():panel._buttons[button].pressed.emit()
func run() -> void:
	var variants:Array=[["stars_ch06_sword",""],["array_ch06_steps",""],["basket_ch06_weave",""],["r03","bird"],["r03","box"],["l02","waterwheel"],["l02","cart"]]
	for v in variants:
		var r:=create(v[0],v[1]);var original:Dictionary=r.context.duplicate(true)
		var untouched:Dictionary=r.snapshot()
		check(not r.apply_input({"type":"restart_after_limit","hint":3,"assisted":0,"failures":999,"discarded_log_hash":"0".repeat(64)}).ok,"internal rollover cannot be public input")
		check(r.snapshot()==untouched,"rollover injection rejects atomically")
		act(r,{"type":"finish"},false);act(r,{"type":"assist_step_v1"},false)
		for bad in [null,true,INF,NAN,[],{},1.25]:
			var before:Dictionary=r.snapshot()
			check(not r.apply_input({"type":"read_note","note":bad}).ok,"invalid typed field")
			check(r.snapshot()==before,"malformed field rejects atomically")
		finish(r)
		check(not r.state.assisted and r.context==original,"manual no assistance no external mutation")
		check(r.receipt().materials_used==R.MATERIALS.get(v[0],{}),"exact recipe consumption proposal")
		act(r,{"type":"retry"},false)
		var proof:Dictionary=r.receipt();proof.product="forged"
		check(not R.replay_receipt(proof,r.puzzle_id,r.attempt_id,r.context),"forged product denied")
		var a:=create(v[0],v[1])
		for i in range(3):act(a,{"type":"hint"})
		act(a,{"type":"assist_step_v1"});act(a,{"type":"undo"});act(a,{"type":"retry"})
		check(a.state.hint==3 and a.state.assisted,"hint and assisted cumulative across undo/retry")
		finish(a,true)
		var invalid:=create(v[0],v[1]);act(invalid,invalid.next_demo_action())
		for key in ["version","puzzle_id","attempt_id","context_hash","input_log","state"]:
			for bad in [null,true,INF,NAN,[],{},-4]:
				var snapshot:Dictionary=invalid.snapshot();snapshot[key]=bad;var prior:Dictionary=invalid.snapshot()
				check(not invalid.restore(snapshot,invalid.context),"malformed snapshot field "+key)
				check(prior==invalid.snapshot(),"restore refusal atomic")
		var deep:Dictionary={};deep["cycle"]=deep
		check(not invalid.restore(deep,invalid.context),"cyclic tree bounded");deep.clear()
		var capped:=create(v[0],v[1])
		for i in range(R.MAX_LOG):capped.apply_input({"type":"hint"})
		act(capped,{"type":"retry"});check(capped.input_log.size()==1 and capped.state.hint==3,"limit retry recoverable")
		check(capped.state.history_reset,"history reset explicitly marked")
		act(capped,capped.next_demo_action());act(capped,{"type":"undo"});act(capped,{"type":"retry"})
		check(capped.state.history_reset,"undo retry retain old-history boundary")
		finish(capped)
		check(capped.receipt().previous_attempt_history_unverified,"proof declares old history unverified")
	# Trusted materials, authorization, and method cannot be replaced mid-session.
	for id in R.MATERIALS:
		check(not R.new().begin(id,"missing"),"missing materials refused")
		for item in R.MATERIALS[id]:
			var c:=fixture(id);c.items[item].quantity=R.MATERIALS[id][item]-1
			check(not R.new().begin(id,"short",c),"short recipe rejected")
			c=fixture(id);c.items[item].state="spent";check(not R.new().begin(id,"spent",c),"spent item rejected")
	for id in R.AUTH:
		var r:=create(id);var c:=fixture(id);c.authorizations=[];check(not r.set_context(c),"missing authorization denied")
		c=fixture(id,"box" if id=="r03" else "cart")
		check(not r.set_context(c),"branch cannot switch within custody")
		for i in range(6):act(r,r.next_demo_action())
		act(r,{"type":"retry"});check(r.state.method==("bird" if id=="r03" else "waterwheel"),"retry keeps actual choice")
	# Star vector rejection, not a success flag.
	var stars:=create("stars_ch06_sword")
	for i in range(3):act(stars,{"type":"read_note","note":i})
	act(stars,{"type":"observe_star","time":0});act(stars,{"type":"predict_star","x":0,"y":-2},false)
	act(stars,{"type":"predict_star","x":0,"y":2});act(stars,{"type":"sword_vector","x":2,"y":0},false)
	act(stars,{"type":"sword_vector","x":0,"y":2});finish(stars)
	# Independently sum the published fixed square, not arbitrary four cells.
	var unique:Dictionary={}
	for n in R.SQUARE:unique[n]=true
	check(unique.size()==16,"normal square values unique")
	for line in R.LINES:
		var sum:=0
		for cell in line:sum+=R.SQUARE[cell]
		check(sum==34,"ten actual line sums")
	check(R.SQUARE[0]+R.SQUARE[1]+R.SQUARE[2]+R.SQUARE[4]!=34,"arbitrary four NOT universally34")
	var array:=create("array_ch06_steps");act(array,{"type":"read_principle"});act(array,{"type":"observe_line","line":0})
	act(array,{"type":"verify_line","line":0,"sum":35},false);act(array,{"type":"verify_line","line":0,"sum":34})
	act(array,{"type":"step_line","line":0,"endpoint":0},false);finish(array)
	# Incorrect/repeated material operations and partial branch interleaving.
	var bird:=create("r03","bird");var box:=create("r03","box");var l02:=create("l02","cart")
	for i in range(5):
		for r in [bird,box,l02]:act(r,r.next_demo_action())
	for r in [bird,box]:
		act(r,{"type":"split_fine"},false);act(r,{"type":"weave_row","strip":5,"pattern":0},false)
		act(r,{"type":"set_heat","level":2});act(r,{"type":"bake_tick"},false)
		finish(r);check(r.receipt().product==r.state.method,"exclusive branch product")
	act(l02,{"type":"cut_pine","log":0,"length":1},false);act(l02,{"type":"join","job":"waterwheel","fit":2},false)
	finish(l02);check(l02.state.locations=={"sleeve":"waterwheel","pin":"cart","hoop":"waterwheel","hide":"cart"},"reused and borrowed materials installed exactly once")
	# Both shell sizes, real signals, stable controls and close with pending anchor.
	for dimensions in [Vector2(616,335),Vector2(1200,650)]:
		for v in variants:
			var shell:=PanelContainer.new();shell.size=dimensions
			var theme:=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=16;shell.theme=theme;root.add_child(shell)
			var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;shell.add_child(scroll)
			var panel:=UI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
			var model:=create(v[0],v[1]);var closes:Array=[]
			panel.close_requested.connect(func():closes.append(true))
			panel.input_submitted.connect(func(a:Dictionary):model.apply_input(a);panel.render(model.get_view()))
			panel.render(model.get_view());await process_frame;await process_frame
			check(not panel._labels.instruction.visible,"long rules collapse by default")
			panel._buttons.rules.pressed.emit();check(panel._labels.instruction.visible,"rules available without model input")
			if v[0] in ["basket_ch06_weave","r03"]:
				check(panel._buttons.weave.position.y-panel._selects.strip.position.y<180,"weave selector and action adjacent")
			if v[0]=="l02":check(panel._buttons.test.position.y-panel._selects.job.position.y<260,"repair selectors and repeated actions adjacent")
			for i in range(120):
				if model.state.complete:break
				manual_ui(panel,model.next_demo_action())
			await process_frame;await process_frame
			check(model.state.complete and not model.state.assisted,"actual UI manual controls complete")
			check(panel.size.x<=shell.size.x and scroll.size.y>=100,"small layout scroll body retained")
			check(closes.is_empty(),"operations never close")
			panel._buttons.close.grab_focus();panel.render(model.get_view())
			shell.queue_free();await process_frame;await process_frame
	print("Chapter six puzzles: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
