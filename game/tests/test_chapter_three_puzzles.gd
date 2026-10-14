extends SceneTree
const Resolver = preload("res://scripts/puzzles/chapter_three_puzzle_resolver.gd")
const PuzzleUI = preload("res://scripts/ui/puzzle_panel.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func apply(r: RefCounted, action: Dictionary, expected: bool = true) -> void:
	check(r.apply_input(action).ok == expected,"action " + str(action))
	var copy := Resolver.new()
	check(copy.restore(JSON.parse_string(JSON.stringify(r.snapshot()))),"every-step JSON restore")
	check(copy.state == r.state,"every-step state equality")
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three.json"))
	for model in data.interaction_contracts.math_boards:
		var r := Resolver.new(model.id)
		var n: int = model.variables.size()
		for i in range(n):
			for j in range(n): check(r.state.matrix[i][j] == [int(model.matrix[i][j]),1],"frozen coefficients match contract")
			check(r.state.matrix[i][n] == [int(model.rhs[i]),1],"frozen rhs")
		apply(r,{"type":"submit"},false)
		apply(r,{"type":"solved","value":1},false)
		apply(r,{"type":"enter_value","symbol":0,"numerator":1,"denominator":1},false)
		apply(r,{"type":"demo_next"},false)
		for i in range(n): apply(r,{"type":"assign_symbol_to_column","symbol":i,"column":n-1-i})
		apply(r,{"type":"scale_row","row":0,"numerator":1,"denominator":0},false)
		apply(r,{"type":"subtract_known_row","row":0,"source":0,"numerator":1,"denominator":1},false)
		apply(r,{"type":"scale_row","row":0,"numerator":1,"denominator":2})
		check(r.state.matrix[0][0] == [1,2],"exact fractions")
		apply(r,{"type":"undo"})
		check(r.state.matrix[0][0] == [1,1],"undo fractions")
		apply(r,{"type":"swap_rows","row":0,"source":1})
		apply(r,{"type":"swap_rows","row":0,"source":1})
		for i in range(n-2,-1,-1): apply(r,{"type":"subtract_known_row","row":i,"source":i+1,"numerator":1,"denominator":1})
		for i in range(n): apply(r,{"type":"enter_value","symbol":i,"numerator":i+1,"denominator":1})
		apply(r,{"type":"submit"},false)
		apply(r,{"type":"enter_value","symbol":0,"numerator":-1,"denominator":1})
		apply(r,{"type":"substitute_back","row":0},false)
		apply(r,{"type":"enter_value","symbol":0,"numerator":1,"denominator":1})
		for i in range(n): apply(r,{"type":"substitute_back","row":i})
		apply(r,{"type":"submit"})
		check(not r.receipt().assisted,"manual process unassisted")
		check(Resolver.replay_receipt(JSON.parse_string(JSON.stringify(r.receipt())),r.puzzle_id,r.attempt_id),"receipt exact replay")
		var forged: Dictionary = r.receipt(); forged.final_state.complete = false
		check(not Resolver.replay_receipt(forged,r.puzzle_id,r.attempt_id),"forged receipt rejected")
		var assisted := Resolver.new(model.id)
		for h in range(3):
			var before: Dictionary = assisted.state.duplicate(true)
			apply(assisted,{"type":"hint"})
			check(assisted.state.matrix == before.matrix and not assisted.state.assisted,"hints never operate")
		var steps := 0
		while not assisted.state.complete and steps < 250:
			apply(assisted,{"type":"demo_next"}); steps += 1
		check(assisted.state.complete and assisted.state.assisted and steps > n*3,"explicit granular assistance")
		check(Resolver.replay_receipt(assisted.receipt(),assisted.puzzle_id,assisted.attempt_id),"assisted replay")
	var tea := Resolver.new("interaction_ch03_tea")
	apply(tea,{"type":"tea_transfer","cup":0,"amount":1})
	apply(tea,{"type":"tea_transfer","cup":0,"amount":1})
	apply(tea,{"type":"submit"},false)
	apply(tea,{"type":"tea_transfer","cup":0,"amount":-1})
	for i in [1,2]: apply(tea,{"type":"tea_transfer","cup":i,"amount":1})
	apply(tea,{"type":"submit"})
	check(tea.receipt().objective_id == "tea_shared","tea proof")
	var trial := Resolver.new("trial_ch03_qingyuan")
	apply(trial,{"type":"yield_and_withdraw"},false)
	for step in Resolver.TRIAL: apply(trial,{"type":step})
	check(trial.receipt().objective_id == "qingyuan_trial","trial proof")
	check(Resolver.rational(1,0).is_empty(),"zero divisor rejected")
	check(Resolver.rational(2,-4) == [-1,2],"negative denominator canonical")
	check(Resolver.rational(0,19) == [0,1],"zero canonical")
	var partial := Resolver.new("board_ch03_six")
	apply(partial,{"type":"assign_symbol_to_column","symbol":5,"column":0})
	check(partial.get_view().equations[0].contains("x1") and partial.get_view().equations[0].contains("x2"),"partly assigned columns never hide original terms")
	apply(partial,{"type":"assign_symbol_to_column","symbol":5,"column":1})
	check(partial.state.columns[0] == -1,"duplicate symbol moves instead of copying")
	apply(partial,{"type":"subtract_known_row","row":0,"source":1,"numerator":1,"denominator":1},false)
	var tampered: Dictionary = partial.snapshot(); tampered.state.complete = true
	check(not Resolver.new().restore(tampered),"bare saved success rejected")
	tampered = partial.snapshot(); tampered.version = 999
	check(not Resolver.new().restore(tampered),"future snapshot rejected")
	var overflow := Resolver.new("board_ch03_six")
	for i in range(6): apply(overflow,{"type":"assign_symbol_to_column","symbol":i,"column":i})
	apply(overflow,{"type":"scale_row","row":0,"numerator":1000000,"denominator":1},false)
	check(overflow.state.matrix[0][0] == [1,1],"overflow atomic no mutation")
	optimized_assistance_tests()
	legacy_assistance_compatibility()
	boundary_test()
	direct_json_actions()
	await ui_test()
	await actual_ui_inputs()
	await explained_ui_inputs()
	print("Chapter-three puzzles: %d checks, %d failures" % [checks,failures]); quit(1 if failures else 0)
func ui_test() -> void:
	root.size = Vector2i(640,360)
	var r := Resolver.new("board_ch03_twelve")
	var p := PuzzleUI.new(); root.add_child(p); p.position = Vector2(8,8); p.size = Vector2(624,344)
	p.render(r.get_view())
	await process_frame; await process_frame
	check(p.size.x <= 624,"small-window panel fits")
	check(p._scroll.get_h_scroll_bar().max_value <= p._scroll.size.x+1,"no twelve-column horizontal overflow")
	var stable = p._chapter_three_panel
	var selector = stable._selectors.row
	selector.grab_focus(); p._scroll.scroll_vertical = 700
	await process_frame
	var previous: int = p._scroll.scroll_vertical
	r.apply_input({"type":"hint"}); p.render(r.get_view())
	await process_frame; await process_frame
	check(p._chapter_three_panel == stable and stable._selectors.row == selector,"stable controls retained")
	check(root.gui_get_focus_owner() == selector,"focus retained")
	check(p._scroll.scroll_vertical == previous,"scroll retained")
	p.queue_free(); await process_frame

func press_text(node: Node, prefix: String) -> void:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix):
			child.pressed.emit()
			return
	check(false,"missing UI button " + prefix)

func actual_ui_inputs() -> void:
	var r := Resolver.new("board_ch03_six")
	var p := PuzzleUI.new(); root.add_child(p); p.size = Vector2(624,344)
	p.input_submitted.connect(func(a: Dictionary): r.apply_input(a); p.render(r.get_view()))
	p.render(r.get_view())
	await process_frame
	var panel = p._chapter_three_panel
	for i in range(6):
		panel._selectors.symbol.select(i); panel._selectors.column.select(i)
		press_text(panel,"把所选符号")
	for i in range(4,-1,-1):
		panel._selectors.row.select(i); panel._selectors.source.select(i+1)
		press_text(panel,"目标行 −")
	for i in range(6):
		panel._selectors.value_symbol.select(i); panel._numbers.value_n.value = i+1
		press_text(panel,"记录这个")
	for i in range(6): press_text(panel,"把填值代回第%d原式" % (i+1))
	press_text(panel,"检查全部过程")
	check(r.state.complete and not r.state.assisted,"actual manual UI inputs complete all gates")
	check(Resolver.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id),"UI generates verified receipt only")
	p.queue_free(); await process_frame
	var tea := Resolver.new("interaction_ch03_tea")
	p = PuzzleUI.new(); root.add_child(p); p.size = Vector2(624,344)
	p.input_submitted.connect(func(a: Dictionary): tea.apply_input(a); p.render(tea.get_view()))
	p.render(tea.get_view()); panel = p._chapter_three_panel
	press_text(panel,"第1盏：放入"); press_text(panel,"第1盏：放入")
	press_text(panel,"检查全部过程")
	check(not tea.state.complete,"wrong UI tea remains retryable")
	press_text(panel,"第1盏：取回")
	press_text(panel,"第2盏：放入"); press_text(panel,"第3盏：放入")
	press_text(panel,"检查全部过程")
	check(tea.state.complete,"actual tea inputs return excess and finish")
	p.queue_free(); await process_frame

func boundary_test() -> void:
	var r := Resolver.new("interaction_ch03_tea")
	for i in range(3): r.apply_input({"type":"hint"})
	r.apply_input({"type":"demo_next"})
	while r.input_log.size() < Resolver.MAX_LOG: r.apply_input({"type":"hint"})
	check(r.state.assisted,"assistance exists before exhausted round")
	check(not r.apply_input({"type":"tea_transfer","cup":1,"amount":1}).ok,"exhausted round stays bounded")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(r.snapshot()))
	var restored := Resolver.new()
	check(restored.restore(saved),"full log remains restorable")
	check(restored.apply_input({"type":"reset"}).ok,"full log reset allowed after reload")
	check(restored.input_log.size() == 1 and restored.input_log[0].type == "restart_after_limit","reset starts bounded explicit genesis")
	check(restored.state.assisted and restored.state.hint == 3 and not restored.state.complete,"restart preserves assistance but no solved state")
	check(restored.state.cups == [0,0,0] and restored.state.tray == 3,"restart resets actual tea board")
	var restart_clone := Resolver.new()
	check(restart_clone.restore(JSON.parse_string(JSON.stringify(restored.snapshot()))),"genesis snapshot replay")
	apply(restored,{"type":"submit"},false)
	for i in range(3): apply(restored,{"type":"tea_transfer","cup":i,"amount":1})
	apply(restored,{"type":"submit"})
	check(restored.receipt().assisted,"restart does not launder assisted receipt")
	check(Resolver.replay_receipt(JSON.parse_string(JSON.stringify(restored.receipt())),restored.puzzle_id,restored.attempt_id),"post-limit full receipt replay")
	var forged := Resolver.new("interaction_ch03_tea")
	var root_action: Dictionary = restored.input_log[0].duplicate(true)
	root_action.complete = 1
	check(not forged.apply_input(root_action).ok and forged.receipt().is_empty(),"restart cannot supply completion")
	forged = Resolver.new("interaction_ch03_tea")
	forged.apply_input({"type":"hint"})
	check(not forged.apply_input(restored.input_log[0]).ok,"genesis cannot erase an active round")

func direct_json_actions() -> void:
	for id in Resolver.IDS:
		var reference := Resolver.new(id)
		var replay := Resolver.new(id)
		var actions: Array = []
		for h in range(3): actions.append({"type":"hint"})
		for a in actions:
			reference.apply_input(a)
			check(replay.apply_input(JSON.parse_string(JSON.stringify(a))).ok,"JSON action accepted directly")
		var count := 0
		while not reference.state.complete and count < 250:
			var a: Dictionary = reference.next_demo_action()
			check(reference.apply_input(a).ok,"ordinary action oracle")
			check(replay.apply_input(JSON.parse_string(JSON.stringify(a))).ok,"direct JSON action normalized")
			check(replay.state == reference.state,"direct JSON chronology state equality")
			count += 1
		check(reference.state.complete and replay.receipt() == reference.receipt(),"JSON action receipt identical")

func optimized_assistance_tests() -> void:
	for id in ["board_ch03_six","board_ch03_seven","board_ch03_twelve"]:
		var n: int = Resolver.SIZES[id]
		for mode in range(4):
			var r := Resolver.new(id)
			apply(r,{"type":"demo_next_explained"},false)
			for h in range(3): apply(r,{"type":"hint"})
			if mode in [1,3]:
				for i in range(n): apply(r,{"type":"assign_symbol_to_column","symbol":i,"column":i})
				# Remove the initial singleton, swap rows and add a fractional scale.
				# This requires a genuine general elimination fallback, not n-1 assumptions.
				apply(r,{"type":"subtract_known_row","row":n-1,"source":0,"numerator":-1,"denominator":1})
				apply(r,{"type":"swap_rows","row":0,"source":2})
				apply(r,{"type":"scale_row","row":1,"numerator":3,"denominator":2})
				if mode == 3:
					for j in range(n): apply(r,{"type":"subtract_known_row","row":j,"source":(j+2)%n,"numerator":1 if j%2 == 0 else -1,"denominator":2})
			if mode == 2:
				for j in range(n+4): apply(r,{"type":"demo_next"})
			var steps := 0
			var limit: int = 4*n if mode == 0 else 2*n*n+5*n
			while not r.state.complete and steps < limit:
				var next: Dictionary = r.next_demo_action()
				var matrix_before: Array = r.state.matrix.duplicate(true)
				apply(r,{"type":"demo_next_explained"})
				if next.get("type","") in ["subtract_known_row","swap_rows","scale_row"]:
					var explanation: String = r.get_view().last_row_change
					check(explanation.contains("变换前：") and explanation.contains("变换后："),"visible before/after equation explanation")
					check(explanation.contains(r._equation(matrix_before[next.row])),"explanation uses actual previous row")
					check(explanation.contains(r._equation(r.state.matrix[next.row])),"explanation uses actual validated result")
					if next.type != "scale_row": check(explanation.contains("来源行："),"source row visible")
				steps += 1
			check(r.state.complete and r.state.assisted,"new assistance completes initial/mixed/midlegacy board")
			check(steps <= limit,"reasonable bounded step count")
			if mode == 0:
				check(steps == 4*n and r.state.eliminations == n-1,"triangular teaching model uses n-1 eliminations and 4n actions")
				print("Optimized ",id,": ",steps," actions; ",r.state.eliminations," row eliminations")
			check(Resolver.replay_receipt(r.receipt(),id,r.attempt_id),"new/mixed assistance receipt replay")

func legacy_assistance_compatibility() -> void:
	# Captured with the pre-optimization implementation. These are immutable
	# snapshots/proof digests, not values regenerated by the new implementation.
	var old := {
		"board_ch03_six":["948c54af9ab4552de3b424214a2ce8dbf37b378cfb97673ea2c9e09b16455821","07bacb456b463b5541a341f05a8312638e0c4ecf55b5e5fc07e8f090e673dd2c",34],
		"board_ch03_seven":["ace6031b790dc93b0b83e596af7a0704d0b6403465c5a216d96198d8f100cda1","d6924a9f18cad4bb757dd39b6a2e3e0b609fa7daf2f185f8ab3c9d7c66359bed",43],
		"board_ch03_twelve":["85b716a31c0f1192151a4fe3188b1743570f854cde20dfe2a9904a43be511057","76a147bd9be3dfac63639798d4cc1a086b56e15da150fcfc886c7396194135c7",103]}
	for id in old:
		var r := Resolver.new(id)
		for h in range(3): r.apply_input({"type":"hint"})
		var steps := 0
		while not r.state.complete and steps < 150:
			r.apply_input({"type":"demo_next"}); steps += 1
			if steps == 20:
				check(Resolver._hash(r.snapshot()) == old[id][0],"legacy partial snapshot byte-equivalent")
				var clone := Resolver.new()
				check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot()))),"legacy partial save restores")
		check(steps == old[id][2],"legacy demo action meaning unchanged")
		check(Resolver._hash(r.receipt()) == old[id][1],"legacy final receipt byte-equivalent")

func explained_ui_inputs() -> void:
	var r := Resolver.new("board_ch03_twelve")
	var p := PuzzleUI.new(); root.add_child(p); p.size = Vector2(624,344)
	p.input_submitted.connect(func(a: Dictionary): r.apply_input(a); p.render(r.get_view()))
	p.render(r.get_view())
	var panel = p._chapter_three_panel
	for h in range(3): press_text(panel,"提示 ")
	for i in range(12): press_text(panel,"同意协助：")
	await process_frame; await process_frame
	panel._demo.grab_focus()
	press_text(panel,"同意协助：")
	await process_frame; await process_frame
	check(r.input_log[-1].type == "demo_next_explained","live UI uses new explicit assistance action")
	check(panel._labels.operation.visible,"equation explanation visible by assistance button")
	check(panel._labels.operation.text.contains("x11 + x12 = 23") and panel._labels.operation.text.contains("x12 = 12") and panel._labels.operation.text.contains("x11 = 11"),"UI shows true before/source/after of first reverse step")
	check(root.gui_get_focus_owner() == panel._demo,"explanation refresh retains assistant button focus")
	check(p._scroll.get_h_scroll_bar().max_value <= p._scroll.size.x+1,"explained equations wrap at 640x360")
	var clone := Resolver.new()
	check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot()))),"new assisted UI snapshot restores")
	check(clone.get_view().last_row_change == r.get_view().last_row_change,"last equation explanation rebuilt by replay")
	var steps := 13
	while not r.state.complete and steps < 48:
		press_text(panel,"同意协助："); steps += 1
	check(r.state.complete and steps == 48,"actual 12-variable assisted UI finishes in 48 operations")
	p.queue_free(); await process_frame
