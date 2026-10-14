extends SceneTree
const Resolver = preload("res://scripts/puzzles/chapter_puzzle_resolver.gd")
const Diagram = preload("res://scripts/puzzles/geometry_guide.gd")
const PuzzleUI = preload("res://scripts/ui/puzzle_panel.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func apply(r: RefCounted, action: Dictionary, expected: bool = true) -> void:
	var result: Dictionary = r.apply_input(action)
	check(result.ok == expected,"input " + str(action))
	var clone := Resolver.new()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(r.snapshot()))
	check(clone.restore(saved,r.context),"JSON replay after each operation")
	check(clone.state == r.state,"replayed board equals actual")

func run() -> void:
	# All 8 dihedral rotations/reflections are valid, not just one answer index.
	var board: Array = Resolver.LOSHU.duplicate()
	for reflection in range(2):
		for rotation in range(4):
			var r := Resolver.new("pz01_problem_01")
			for i in range(9):
				if i != 4: apply(r,{"type":"set","index":i,"value":board[i]})
			apply(r,{"type":"submit"})
			check(r.receipt().validation_results.eight_line_sums == [15,15,15,15,15,15,15,15],"all eight lines checked")
			check(Resolver.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id),"valid proof replay")
			board = [board[6],board[3],board[0],board[7],board[4],board[1],board[8],board[5],board[2]]
		board = [board[2],board[1],board[0],board[5],board[4],board[3],board[8],board[7],board[6]]
	var bad := Resolver.new("pz01_problem_01")
	for i in range(9):
		if i != 4: apply(bad,{"type":"set","index":i,"value":[2,9,4,3,5,7,8,1,6][i]})
	apply(bad,{"type":"submit"},false)
	check(bad.receipt().is_empty(),"source invalid Loshu not rewarded")
	apply(bad,{"type":"set","index":4,"value":6},false)
	apply(bad,{"type":"set","index":0,"value":5},false)
	check(bad.state.values[4] == 5,"fixed center cannot be stolen into another slot")
	apply(bad,{"type":"set","index":0,"value":1.5},false)
	# Every finite teaching fixture can be completed with explicit, stepwise assistance.
	for id in Resolver.problem_ids():
		var r := Resolver.new(id)
		apply(r,{"type":"submit"},false)
		check(r.receipt().is_empty(),"failure does not mint receipt")
		apply(r,{"type":"demo_next"},false)
		for level in range(3): apply(r,{"type":"hint"})
		var steps := 0
		while not r.state.complete and steps < 40:
			apply(r,{"type":"demo_next"})
			steps += 1
		check(r.state.complete and steps > 1,"assistance uses multiple legal operations " + id)
		check(r.receipt().assisted,"assistance tagged")
		check(Resolver.replay_receipt(r.receipt(),id,r.attempt_id),"assisted replay")
		var forged: Dictionary = r.receipt()
		forged.assisted = false
		check(not Resolver.replay_receipt(forged,id,r.attempt_id),"receipt tamper rejected")
		var snapshot: Dictionary = r.snapshot()
		snapshot.state.values[0] = 999
		var copy := Resolver.new()
		check(not copy.restore(snapshot),"saved state tamper rejected")
		check(not Resolver.replay_receipt(r.receipt(),id,"wrong_attempt"),"attempt binding enforced")
	# Binary controls must physically change ten bits, for all three targets.
	var binary := Resolver.new("pz01_problem_04")
	for target in [5,13,42]:
		for i in range(10):
			var bit := 1 if (target & Resolver.WEIGHTS[i]) else 0
			if binary.state.values[i] != bit: apply(binary,{"type":"toggle","index":i})
		apply(binary,{"type":"submit"})
	check(binary.state.proofs.size() == 3 and not binary.state.assisted,"manual binary three proofs")
	# Tenth is bounded and is an acceptance, never mathematical success.
	var tenth := Resolver.new("pz01_tenth")
	apply(tenth,{"type":"stop"},false)
	apply(tenth,{"type":"submit"},false)
	for i in range(20): apply(tenth,{"type":"extend"})
	check(tenth.state.tracks == 13 and not tenth.state.complete,"bounded divergence")
	check(tenth.get_receipts().size() == 1,"overload receipt only")
	apply(tenth,{"type":"stop"},false)
	tenth.set_context({"authorize_acceptance":true})
	apply(tenth,{"type":"stop"})
	check(tenth.receipt().validation_results.finite_solution == false,"acceptance is not solved tenth")
	check(Resolver.replay_receipt(tenth.receipt(),tenth.puzzle_id,tenth.attempt_id,tenth.context),"acceptance proof replay")
	# Nine identifiable paper fragments, no success from a branch button.
	for method in ["keep_all","keep_later"]:
		var r := Resolver.new("r01")
		apply(r,{"type":"method","value":method},false)
		apply(r,{"type":"select_segment","segment":"borrow_yin_to_balance_yang"},false)
		apply(r,{"type":"place_piece","slot":0,"piece":0})
		apply(r,{"type":"submit"},false)
		check(r.state.correct_highlight == 0,"only actually correct paper highlighted")
		apply(r,{"type":"place_piece","slot":1,"piece":0})
		check(r.state.values[0] == -1 and r.state.correct_highlight == -1,"moving correct fragment clears stale empty-slot highlight")
		apply(r,{"type":"submit"},false)
		check(r.state.correct_highlight == -1,"no false highlight when no fragment is correct")
		apply(r,{"type":"place_piece","slot":0,"piece":0})
		for i in range(1,9): apply(r,{"type":"place_piece","slot":i,"piece":i})
		apply(r,{"type":"submit"})
		apply(r,{"type":"select_segment","segment":"wrong_conclusion"},false)
		apply(r,{"type":"select_segment","segment":"borrow_yin_to_balance_yang"})
		apply(r,{"type":"method","value":method})
		apply(r,{"type":"bind","step":"title"},false)
		for step in ["paste_cover","thread","title"]: apply(r,{"type":"bind","step":step})
		check(r.receipt().choice_id == "ch02_r01_"+method,"stable paper choice ID")
		check(Resolver.replay_receipt(r.receipt(),"r01",r.attempt_id),"bound book proof replay")
	# Real observations required before formulas; both formulas yield 808 chi.
	for method in ["double_difference","similar_triangles"]:
		var r := Resolver.new("k01")
		apply(r,{"type":"observe","key":"front_rod"},false)
		apply(r,{"type":"method","value":method},false)
		r.set_context({"observed_measurements":Resolver.MEASURES})
		for key in Resolver.MEASURES: apply(r,{"type":"observe","key":key})
		apply(r,{"type":"method","value":method})
		var values := [600,8,8,12,18,4,404,10,808,8]
		for i in range(values.size()): apply(r,{"type":"set","index":i,"value":values[i]})
		apply(r,{"type":"formula","value":"baseline_over_sum"})
		apply(r,{"type":"submit"},false)
		apply(r,{"type":"formula","value":"rod_plus_baseline_over_difference" if method == "double_difference" else "shadow_ratio"})
		apply(r,{"type":"set","index":4,"value":12})
		apply(r,{"type":"submit"},false)
		apply(r,{"type":"set","index":4,"value":18})
		apply(r,{"type":"set","index":8,"value":8000})
		apply(r,{"type":"submit"},false)
		apply(r,{"type":"set","index":8,"value":808})
		apply(r,{"type":"submit"})
		check(r.receipt().validation_results.height_chi == 808,"both methods 808 chi")
		check(Resolver.replay_receipt(r.receipt(),"k01",r.attempt_id,r.context),"geometry proof with field evidence")
		check(not Resolver.replay_receipt(r.receipt(),"k01",r.attempt_id),"field evidence cannot be fabricated by receipt")
	# Panel creates real controls, constrained by an independent scroll container.
	var panel := PuzzleUI.new()
	root.add_child(panel)
	panel.size = Vector2(600,320)
	var ui_theme := Theme.new()
	ui_theme.default_font = load("res://assets/fonts/kunlun_ui.ttf")
	ui_theme.default_font_size = 20
	panel.theme = ui_theme
	for id in Resolver.problem_ids()+["pz01_tenth","r01","k01"]:
		var r := Resolver.new(id)
		panel.render(r.get_view())
		await process_frame
		check(panel.size.x <= 600,"panel width bounded " + id)
		check(panel._body.size.x <= 584,"body has no horizontal overflow " + id)
		check(panel._scroll.size.y <= 320,"vertical scroll stays in viewport " + id)
	var survey := Resolver.new("k01")
	survey.set_context({"observed_measurements":Resolver.MEASURES})
	for key in Resolver.MEASURES: survey.apply_input({"type":"observe","key":key})
	for method in ["double_difference","similar_triangles"]:
		survey.apply_input({"type":"method","value":method})
		survey.apply_input({"type":"hint"})
		panel.render(survey.get_view())
		await process_frame
		check(panel._body.size.x <= 584,"full geometry form fits with " + method)
		check(panel._scroll.size.y <= 320,"long survey scroll clipped safely")
	var reset := Resolver.new("pz01_problem_01")
	for level in range(3): reset.apply_input({"type":"hint"})
	reset.apply_input({"type":"demo_next"})
	apply(reset,{"type":"reset"})
	check(reset.state.assisted and reset.state.values == [0,0,0,0,5,0,0,0,0],"reset cannot erase assistance")
	for width in [240.0,568.0]:
		var peak := Vector2(width*0.06,35)
		for rod_x in [width*0.40,width*0.57]:
			var rod_top := Vector2(rod_x,105)
			var observer: Vector2 = Diagram.sight_observer(peak,rod_top,123)
			check(absf((rod_top-peak).cross(observer-peak)) < 0.01,"survey sight line is straight through rod top")
			check(is_equal_approx(observer.y,123) and observer.x > rod_x and observer.x < width,"observer lies behind rod on visible ground")
	# Earned assists are informational and replay-bound to campaign authority.
	var assisted := Resolver.new("pz01_problem_03")
	apply(assisted,{"type":"set","index":0,"value":6})
	apply(assisted,{"type":"submit"},false)
	check(assisted.get_view().reflection_highlight == -1,"no unearned reflection highlight")
	assisted.set_context({"assist_flags":["assist_ch02_trial_reflection"]})
	apply(assisted,{"type":"submit"},false)
	check(assisted.get_view().reflection_highlight == 0,"earned reflection highlights a verified value")
	check(assisted.receipt().is_empty() and not assisted.state.assisted,"reflection cannot solve or pretend story assistance")
	var no_authority := Resolver.new()
	check(not no_authority.restore(assisted.snapshot()),"saved assist flag cannot forge campaign ownership")
	apply(assisted,{"type":"set","index":0,"value":5})
	check(assisted.get_view().reflection_highlight == -1,"edited value clears reward highlight")
	apply(assisted,{"type":"submit"},false)
	check(assisted.get_view().reflection_highlight == -1,"no correct components means no highlight")
	var loshu_assist := Resolver.new("pz01_problem_01")
	loshu_assist.set_context({"assist_flags":["assist_ch02_trial_reflection"]})
	apply(loshu_assist,{"type":"submit"},false)
	check(loshu_assist.get_view().reflection_highlight == 4,"Lo Shu assist uses orientation-invariant center")
	for id in ["pz01_problem_06","pz01_problem_08","k01"]:
		var guided := Resolver.new(id)
		check(not guided.get_view().geometry_guides,"no unearned persistent geometry guides")
		guided.set_context({"assist_flags":["assist_ch02_geometry_guides"]})
		check(guided.get_view().geometry_guides and not guided.state.complete,"earned guides do not solve puzzle")
		panel.render(guided.get_view())
		await process_frame
		check(panel._body.size.x <= 584,"earned geometry guide fits viewport")
	# A same-instance refresh must preserve the selected slot and visible scroll,
	# even when the selected cell's text changes and Godot rebuilds focus nodes.
	var ui_board := Resolver.new("pz01_problem_01")
	panel.render(ui_board.get_view())
	await process_frame
	await process_frame
	panel._selection = 8
	panel.render(ui_board.get_view())
	await process_frame
	await process_frame
	panel._restore_focus("cell:8")
	await process_frame
	panel._scroll.scroll_vertical = 180
	var prior_scroll: int = panel._scroll.scroll_vertical
	ui_board.apply_input({"type":"set","index":8,"value":6})
	panel.render(ui_board.get_view())
	await process_frame
	await process_frame
	check(panel._selection == 8,"same panel refresh preserves selected Lo Shu cell")
	check(panel._scroll.scroll_vertical == prior_scroll,"same panel refresh preserves vertical scroll after layout")
	var owner := root.gui_get_focus_owner()
	check(owner != null and owner.get_meta("puzzle_focus", "") == "cell:8","changed cell label retains stable keyboard focus")
	panel.render(ui_board.get_view())
	panel.render(ui_board.get_view())
	await process_frame
	await process_frame
	check(panel._selection == 8 and panel._scroll.follow_focus,"rapid refresh uses latest layout and reenables keyboard scrolling")
	check(panel._scroll.scroll_vertical == prior_scroll,"rapid refresh does not overwrite preserved scroll")
	panel.queue_free()
	await process_frame
	print("CHAPTER PUZZLES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
