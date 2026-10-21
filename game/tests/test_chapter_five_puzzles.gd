extends SceneTree
const R=preload("res://scripts/puzzles/chapter_five_puzzle_resolver.gd")
const Optics=preload("res://scripts/puzzles/chapter_five_optics.gd")
const UI=preload("res://scripts/ui/chapter_five_puzzle_panel.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func fixture(id:String) -> Dictionary:
	return {"scene_id":"test_"+id,"box_instance":R.BOX,"items":{R.BOX:{"owner":"char_liang_xiao","form":"opened" if id=="box_ch05_reseal" else "sealed","state":"carried"}}}
func create(id:String) -> RefCounted:
	var r:=R.new();check(r.begin(id,id+":test",fixture(id)),"begin "+id);return r
func act(r:RefCounted,a:Dictionary,expected:bool=true) -> void:
	check(r.apply_input(a).ok==expected,"action "+str(a))
	var saved: Dictionary=JSON.parse_string(JSON.stringify(r.snapshot()));var clone:=R.new()
	check(clone.restore(saved,fixture(r.puzzle_id)),"every input JSON restore")
	check(clone.state==r.state,"every input exact state")
	if r.state.complete: check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,fixture(r.puzzle_id)),"receipt strict replay")
func finish(r:RefCounted,assisted:bool=false) -> void:
	for i in range(120):
		if r.state.complete:break
		var next: Dictionary={"type":"assist_step_v1"} if assisted else r.next_demo_action()
		check(not next.is_empty(),"next legal action exists")
		if next.is_empty():break
		act(r,next)
	check(r.state.complete,"complete "+r.puzzle_id)
func run() -> void:
	for id in R.IDS:
		var r:=create(id)
		act(r,{"type":"won","value":1},false);act(r,{"type":"assist_step_v1"},false)
		for value in [INF,NAN,true,[],{},1.25]:check(not r.apply_input({"type":"bogus","value":value}).ok,"reject malformed scalar")
		finish(r)
		check(not r.state.assisted,"manual flow remains unassisted")
		var saved: Dictionary=r.snapshot();saved.state.complete=false
		var target:=create(id);var before: Dictionary=target.snapshot()
		check(not target.restore(saved,fixture(id)) and target.snapshot()==before,"tampered restore is atomic")
		var proof: Dictionary=r.receipt();proof.final_state.hint=99
		check(not R.replay_receipt(proof,id,r.attempt_id,fixture(id)),"tampered proof rejected")
		check(not R.replay_receipt(r.receipt(),id,"wrong-attempt",fixture(id)),"attempt binding")
		var assisted:=create(id)
		for i in range(3):act(assisted,{"type":"hint"})
		act(assisted,{"type":"assist_step_v1"});act(assisted,{"type":"undo"})
		check(assisted.state.assisted,"undo never erases assistance")
		act(assisted,{"type":"retry"});check(assisted.state.assisted,"retry never erases assistance")
		finish(assisted,true)
		var limited:=create(id)
		for i in range(R.MAX_LOG):limited.apply_input({"type":"hint"})
		check(not limited.apply_input({"type":"won"}).ok,"full log blocks arbitrary inputs")
		act(limited,{"type":"retry"});check(limited.input_log.size()==1 and limited.state.hint==3,"full log can always recover")
		finish(limited)
	# Adversarial envelopes: strict types and bounded trees, with atomic rejection.
	var hostile_values: Array=[null,{},[],INF,NAN,true,false,7,1.5,"wrong"]
	for id in R.IDS:
		var guard:=create(id); guard.apply_input({"type":"hint"}); var clean: Dictionary=guard.snapshot()
		for key in ["version","puzzle_id","attempt_id","context_hash","input_log","state"]:
			for value in hostile_values:
				# Arbitrary nonempty attempt strings are legal identifiers.
				if key=="attempt_id" and value is String: continue
				var bad: Dictionary=clean.duplicate(true);bad[key]=value
				check(not guard.restore(bad,fixture(id)),"reject bad save field type/value "+key)
				check(guard.snapshot()==clean,"bad save leaves target untouched")
		var deep: Dictionary={};var cursor: Dictionary=deep
		for i in range(30):cursor["nested"]={};cursor=cursor.nested
		var deep_save: Dictionary=clean.duplicate(true);deep_save.state=deep
		check(not guard.restore(deep_save,fixture(id)) and guard.snapshot()==clean,"deep save rejected before recursion")
		var cyclic: Dictionary={};cyclic.loop=cyclic
		check(not R._bounded_tree(cyclic),"cyclic Variant rejected by depth budget")
		cyclic.clear()
		var giant: Dictionary=clean.duplicate(true);giant.input_log.resize(R.MAX_LOG+1)
		check(not guard.restore(giant,fixture(id)),"oversized history rejected")
	for id in ["box_ch05_light","box_ch05_reseal"]:
		var guard:=create(id);var original: Dictionary=guard.context.duplicate(true);var clean: Dictionary=guard.snapshot()
		for key in ["items","box_instance"]:
			for value in hostile_values:
				var bad: Dictionary=fixture(id);bad[key]=value
				check(not guard.set_context(bad) and guard.context==original and guard.snapshot()==clean,"invalid context shape rejected atomically")
		for key in ["form","owner"]:
			for value in hostile_values:
				if key=="owner" and value is String: continue
				var bad: Dictionary=fixture(id);bad.items[R.BOX][key]=value
				check(not guard.set_context(bad) and guard.context==original,"invalid box metadata rejected atomically")
	var typed:=create("lock_ch05_six");var untouched: Dictionary=typed.snapshot()
	for action in [{"type":"inspect_lock","lock":"bad"},{"type":"inspect_lock","lock":true},{"type":"set_probe","depth":[],"direction":1},{"type":"set_probe","depth":2,"direction":"east"},{"type":"inspect_lock"},{"type":"hint","unexpected":1},{"type":"set_bagua_anchor","direction":-1}]:
		check(not typed.apply_input(action).ok and typed.snapshot()==untouched,"bad action schema rejected before logging")
	# Two-link real simulation precedes installing the third link.
	var chain:=create("chain_ch05_linkage")
	act(chain,{"type":"install_third"},false);act(chain,{"type":"inspect_chain"})
	act(chain,{"type":"test_chain"},false)
	act(chain,{"type":"connect_link","source":0,"target":1});act(chain,{"type":"connect_link","source":1,"target":0})
	act(chain,{"type":"test_chain"},false);check(chain.state.trace==[0,1,0],"actual directed cycle trace")
	act(chain,{"type":"connect_link","source":0,"target":4});act(chain,{"type":"test_chain"},false)
	check(chain.state.trace==[0,4] and not chain.state.double_tested,"bypass cannot count two-link test")
	finish(chain);check(chain.state.trace==[0,1,2,3,4] and chain.state.double_tested,"all three actual mechanisms traversed")
	# Six independent locks cannot reuse prior depth/direction.
	var locks:=create("lock_ch05_six")
	act(locks,{"type":"set_probe","depth":2,"direction":1},false)
	act(locks,{"type":"inspect_lock","lock":0});act(locks,{"type":"set_probe","depth":2,"direction":-1})
	act(locks,{"type":"turn_lock"},false);act(locks,{"type":"set_probe","depth":2,"direction":1});act(locks,{"type":"turn_lock"})
	act(locks,{"type":"turn_lock"},false);finish(locks)
	check(locks.state.open_locks==[0,1,2,3,4,5] and not locks.state.has("opened"),"only six outer locks, no box opened")
	var bagua:=create("bagua_ch05_reverse")
	act(bagua,{"type":"inspect_bagua_sequence"},false);act(bagua,{"type":"observe_bagua_light"})
	act(bagua,{"type":"set_bagua_anchor","direction":"east"},false)
	act(bagua,{"type":"set_bagua_anchor","direction":"west"});act(bagua,{"type":"inspect_bagua_sequence"})
	act(bagua,{"type":"place_trigram","slot":0,"trigram":0});act(bagua,{"type":"place_trigram","slot":1,"trigram":0})
	check(bagua.state.slots.count(0)==1 and bagua.state.slots[0]==-1,"unique trigram moved, never duplicated")
	act(bagua,{"type":"verify_reverse_pair","slot":1},false);finish(bagua)
	check(not bagua.state.has("opened"),"cabinet proof is not opening box")
	# Every positive integer solution, not just the original 6/10/84.
	var solutions:Array=[]
	for x in range(1,100):
		for y in range(1,100-x):
			var z:=100-x-y
			if 21*x+9*y+z==300:solutions.append([x,y,z])
	check(solutions==[[2,20,78],[4,15,81],[6,10,84],[8,5,87]],"independent exact Diophantine enumeration")
	for solution in solutions:
		var r:=create("oranges_ch05_hundred")
		for i in range(3):act(r,{"type":"inspect_price","fruit":i})
		act(r,{"type":"set_oranges","warm":solution[0],"green":solution[1],"flat":solution[2]})
		act(r,{"type":"check_orange_count"});act(r,{"type":"check_orange_cost"});act(r,{"type":"submit"})
		check(r.state.triple_cost==300,"exact price units")
	var oranges:=create("oranges_ch05_hundred")
	for i in range(3):act(oranges,{"type":"inspect_price","fruit":i})
	act(oranges,{"type":"set_oranges","warm":0,"green":25,"flat":75},false)
	act(oranges,{"type":"set_oranges","warm":5,"green":10,"flat":85})
	act(oranges,{"type":"check_orange_count"});act(oranges,{"type":"check_orange_cost"},false);act(oranges,{"type":"submit"},false)
	# Real optical intersections: exhaustive 12^3 mirror settings and all eight rings.
	var optical_solutions:Array=[]
	for a in range(0,180,15):
		for b in range(0,180,15):
			for c in range(0,180,15):
				for ring in range(8):
					var ray: Dictionary=Optics.trace([true,true,true],[a,b,c],ring)
					if ray.projected: optical_solutions.append([a,b,c,ring])
	check(optical_solutions==[[135,135,45,0]],"all discrete ray angles/rings have only actual geometric solution")
	for absent in range(3):
		var mounted: Array=[true,true,true];mounted[absent]=false
		check(not Optics.trace(mounted,[135,135,45],0).projected,"every mirror physically necessary")
	check(not Optics.trace([true,true,true],[135,135,30],0).projected,"third mirror30 really misses")
	var normal: Dictionary=Optics.trace([true,true,true],[135,135,45],0)
	check(normal.mirrors==[0,1,2] and normal.holes==[0,1],"all actual surfaces hit in sequence")
	var points:Array=[]
	for segment in normal.segments:points.append(segment.to)
	check(points==[[160000,64000],[64000,64000],[64000,128000],[112000,128000],[144000,128000],[224000,128000]],"exact expected ray intersections milli-pixels")
	var inverted: Dictionary=Optics.trace([true,true,true],[135,135,45],4)
	check(inverted.holes==[1,0] and not inverted.projected and inverted.glyphs.size()==4,"180 ring passes both holes but fails glyphs")
	check(inverted.glyphs[0].up==[0,1000] and normal.glyphs[0].up==[0,-1000],"actual glyph orientation reverses")
	var light:=create("box_ch05_light")
	act(light,{"type":"open_original_box"},false)
	act(light,{"type":"inspect_light_room"})
	for i in range(3):act(light,{"type":"mount_mirror","mirror":i})
	for a in [{"type":"rotate_mirror","mirror":0,"step":1},{"type":"rotate_mirror","mirror":0,"step":1},{"type":"rotate_mirror","mirror":1,"step":-1},{"type":"rotate_mirror","mirror":2,"step":1}]:act(light,a)
	act(light,{"type":"trace_light"});check(light.state.ray.projected and not light.state.projected,"lit candle hides otherwise correct image")
	act(light,{"type":"open_original_box"},false);act(light,{"type":"extinguish_candle"});act(light,{"type":"trace_light"})
	act(light,{"type":"rotate_box_ring","step":1});check(not light.state.projected and light.state.ray.is_empty(),"geometry change invalidates prior proof")
	finish(light)
	check(light.state.box_instance==R.BOX and not light.state.has("taken_balls"),"opening not taking balls")
	check(not R.new().begin("box_ch05_light","forged",{}),"missing original box denies begin")
	check(not R.new().begin("box_ch05_reseal","forged",fixture("box_ch05_light")),"sealed item cannot enter reseal")
	var mismatch: Dictionary=fixture("box_ch05_light");mismatch.items[R.BOX].owner="different_owner"
	check(not R.new().restore(light.snapshot(),mismatch),"trusted unique item owner bound to snapshot")
	# Actual original panels and contents move between two finite compartments.
	var seal:=create("box_ch05_reseal")
	act(seal,{"type":"seal_original_box"},false);act(seal,{"type":"rub_page","page":0},false)
	act(seal,{"type":"remove_panel","page":0,"box":"fake_box"},false)
	act(seal,{"type":"remove_panel","page":0});check(seal.state.box_contents.panels.size()==11 and seal.state.table_contents.panels==[0],"original panel physically transferred")
	act(seal,{"type":"rub_page","page":0});act(seal,{"type":"rub_page","page":0},false)
	act(seal,{"type":"take_ball","ball":"yin"});act(seal,{"type":"take_ball","ball":"yin"},false)
	act(seal,{"type":"collect_stone","stone":0});act(seal,{"type":"load_stone","stone":0},false)
	act(seal,{"type":"undo"});check(seal.state.stones.is_empty(),"stone collection undo restores source")
	finish(seal)
	check(seal.state.box_contents.balls.is_empty() and seal.state.box_contents.stones.size()==2 and seal.state.box_contents.panels.size()==12,"same box contains two stones and all originals")
	check(seal.state.table_contents.balls.size()==2 and seal.state.table_contents.copies.size()==12 and seal.state.table_contents.panels.is_empty() and seal.state.table_contents.stones.is_empty(),"bundle exactly two balls and twelve rubbings; no originals duplicated")
	check(fixture("box_ch05_reseal").items[R.BOX].form=="opened","resolver never mutates campaign context")
	# Partial custody, reset, and forged replacement containers never duplicate items.
	var partial:=create("box_ch05_reseal")
	for action in [{"type":"remove_panel","page":0},{"type":"rub_page","page":0},{"type":"take_ball","ball":"yin"},{"type":"collect_stone","stone":0}]:act(partial,action)
	var forged: Dictionary=partial.snapshot();forged.state.box_contents=forged.state.table_contents.duplicate(true)
	var receiver:=create("box_ch05_reseal");var before_receiver: Dictionary=receiver.snapshot()
	check(not receiver.restore(forged,fixture("box_ch05_reseal")) and receiver.snapshot()==before_receiver,"container substitution rejected atomically")
	act(partial,{"type":"retry"})
	check(partial.state.box_contents.balls==["yin","yang"] and partial.state.box_contents.panels.size()==12 and partial.state.table_contents.balls.is_empty() and partial.state.table_contents.copies.is_empty() and partial.state.stones.is_empty(),"partial retry returns same originals and erases uncommitted copies/stones")
	act(partial,{"type":"refit_panel","page":11},false);act(partial,{"type":"remove_panel","page":12},false)

	# Direct real controls, both widths; no shared panel/main change needed.
	for dimensions in [Vector2(616,336),Vector2(1200,650)]:
		for id in R.IDS:
			var shell:=PanelContainer.new();shell.size=dimensions
			var theme:=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=16;shell.theme=theme;root.add_child(shell)
			var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;shell.add_child(scroll)
			var panel:=UI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
			var model:=create(id);var closes:Array=[]
			panel.close_requested.connect(func():closes.append(true))
			panel.input_submitted.connect(func(a:Dictionary):model.apply_input(a);panel.render(model.get_view()))
			panel.render(model.get_view());await process_frame
			for i in range(3):panel._buttons.hint.pressed.emit()
			check(panel._buttons.assist.visible and model.state.hint==3,"real controls reveal voluntary assistance")
			for i in range(120):
				if model.state.complete:break
				panel._buttons.assist.pressed.emit()
			await process_frame;await process_frame
			check(model.state.complete and model.state.assisted,"real UI signals complete valid process")
			check(panel.size.x<=shell.size.x and scroll.size.y>=100,"small UI retains scrollable body")
			check(closes.is_empty() and not panel._buttons.close.disabled,"puzzle operations never close UI")
			shell.queue_free();await process_frame
	# Refit regression: the selected original and all three board operations stay
	# together at both GUI sizes; accepted real signals complete the same proof.
	for dimensions in [Vector2(616,335),Vector2(1200,650)]:
		var model:=create("box_ch05_reseal")
		while model.next_demo_action().type!="refit_panel": act(model,model.next_demo_action())
		var checkpoint: Dictionary=JSON.parse_string(JSON.stringify(model.snapshot()))
		check(model.restore(checkpoint,fixture("box_ch05_reseal")),"refit checkpoint replays")
		var shell:=PanelContainer.new();shell.size=dimensions
		var theme:=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=16;shell.theme=theme;root.add_child(shell)
		var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;shell.add_child(scroll)
		var panel:=UI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
		var actions:Array=[];var closes:Array=[]
		panel.close_requested.connect(func():closes.append(true))
		panel.input_submitted.connect(func(a:Dictionary):actions.append(a);model.apply_input(a);panel.render(model.get_view()))
		panel.render(model.get_view());await process_frame;await process_frame
		check(panel._buttons.refit.position.y-panel._selects.page.position.y<150,"page selector and refit fit one compact region")
		check(panel._buttons.refit.get_index()==panel._buttons.rub.get_index()+1,"remove rub refit consecutive controls")
		scroll.ensure_control_visible(panel._buttons.refit);await process_frame
		for page in range(12):
			panel._selects.page.select(page)
			panel._buttons.refit.grab_focus()
			var before_y:float=panel._buttons.refit.global_position.y
			panel._buttons.refit.pressed.emit();await process_frame;await process_frame;await process_frame
			check(actions.back()=={"type":"refit_panel","page":page},"refit reads adjacent selection unchanged")
			check(model.state.refitted_panels.size()==page+1,"one actual original refitted per click")
			check(absf(panel._buttons.refit.global_position.y-before_y)<=2,"refit focus screen anchor stable")
			check(panel._buttons.refit.has_focus(),"refit control retains focus")
		panel._buttons.seal.pressed.emit()
		check(model.state.complete and not model.state.assisted,"manual local refit completes without assistance")
		check(R.replay_receipt(model.receipt(),model.puzzle_id,model.attempt_id,fixture(model.puzzle_id)),"refit UI proof unchanged and replayable")
		check(closes.is_empty(),"refit never closes panel")
		# Free with deferred anchor restoration pending: no stale control access.
		shell.queue_free();await process_frame;await process_frame
	print("Chapter five puzzles: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
