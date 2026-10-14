extends SceneTree
const Resolver = preload("res://scripts/puzzles/chapter_four_puzzle_resolver.gd")
const PuzzleUI = preload("res://scripts/ui/puzzle_panel.gd")
# Model-v2 assist_stage_v1 receipt fingerprints prevent accidental changes to saved action semantics.
const ASSIST_V1_HASHES := {
	"tile_ch04_intercept":"1cf1436146161f59fab5ed3df50cc38d2f44feb5601664210502eaf8dbc98350",
	"board_ch04_wood":"ccf0031a2bb1d8217f970553be5ab1a96f86a4259242b69af0410c8a35fbfa66",
	"trial_ch04_staff":"8c3dd7cf87140c8b63ef2e755a974481048dbafc1bc87f45d8cdaf9862023ddd",
	"r02":"f48152b71b4d7676324c48bdb306265685d1eb5fba718f651293236833329f38",
	"l01":"b7ef874a53de2d46568eee26cc6910553bfbafa32dc20350bb091915ce2f6f15",
	"ledger_ch04_r02":"1e639f91c84b40467d5f00b88a2d9d6645457b6b10e3433843ba1b97e7afcbc6"
}
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func act(r: RefCounted, a: Dictionary, expected: bool = true) -> void:
	check(r.apply_input(a).ok == expected,"operation "+str(a))
	var clone := Resolver.new()
	check(clone.restore(JSON.parse_string(JSON.stringify(r.snapshot()))),"every-step JSON restores "+str(a))
	check(clone.state==r.state,"every-step state equal")
	for proof in r.get_receipts(): check(Resolver.replay_receipt(proof,r.puzzle_id,r.attempt_id),"phase receipt replays")
func finish(r: RefCounted) -> void:
	for i in range(100):
		if r.state.complete: break
		var next: Dictionary = r.next_demo_action()
		check(not next.is_empty(),"next valid action exists")
		if next.is_empty(): break
		act(r,next)
	check(r.state.complete,"puzzle completed "+r.puzzle_id)
func run() -> void:
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_four.json"))
	check(Resolver._normalize(contract.interaction_contracts.wood_count.expected_counts)==Resolver.COUNTS,"six powers match authored contract")
	var layout: Dictionary = contract.interaction_contracts.staff_trial.layout
	check(layout.slots.size()==45 and layout.player_start==0 and layout.rival_start==Resolver.STAFF_RIVAL_START,"staff count/start match contract")
	var unique: Dictionary = {}
	for slot in layout.slots: unique[slot.id]=true
	check(unique.size()==45,"45 authored slots are unique")
	for id in Resolver.IDS:
		var r := Resolver.new(id)
		act(r,{"type":"won","value":1},false)
		act(r,{"type":"assist_stage_v1"},false)
		check(not r.apply_input({"type":"x","value":INF}).ok,"reject infinity")
		check(not r.apply_input({"type":"x","value":true}).ok,"reject bool numeric")
		check(not r.apply_input({"type":"x","value":[]}).ok,"reject nested")
		finish(r)
		check(not r.state.assisted,"ordinary actions not assisted")
		var snapshot: Dictionary = r.snapshot(); snapshot.state.failures += 1
		var clone := Resolver.new()
		check(not clone.restore(snapshot),"tampered state rejected")
		for proof in r.get_receipts():
			check(Resolver.replay_receipt(JSON.parse_string(JSON.stringify(proof)),id,r.attempt_id),"JSON receipt")
			var bad: Dictionary = proof.duplicate(true); bad.assisted=true
			check(not Resolver.replay_receipt(bad,id,r.attempt_id),"forged receipt metadata")
			check(not Resolver.replay_receipt(proof,id,"other_attempt"),"cross attempt denied")
		act(r,{"type":"submit"},false)
		var assisted := Resolver.new(id)
		for i in range(3): act(assisted,{"type":"hint"})
		for i in range(100):
			if assisted.state.complete: break
			act(assisted,{"type":"assist_stage_v1"})
		check(assisted.state.complete and assisted.state.assisted,"assisted replay uses same validators")
		check(Resolver._hash(assisted.receipt())==ASSIST_V1_HASHES[id],"frozen assist v1 receipt semantics")
	# Model v2 accepts both action names; only assist_stage_v2 stops at this row boundary.
	for done_groups in range(4):
		var partial := Resolver.new("board_ch04_wood")
		act(partial,{"type":"observe_cut","cut":1})
		for i in range(done_groups): act(partial,{"type":"split_group","group":i})
		for i in range(3): act(partial,{"type":"hint"})
		act(partial,{"type":"assist_stage_v2"})
		check(partial.state.rows.size()==1 and partial.state.observations==[1] and partial.state.groups.is_empty(),"v2 assistance stops at current row end")
	var t := Resolver.new(Resolver.IDS[0])
	act(t,{"type":"land","x":9,"y":6},false)
	act(t,{"type":"observe_current"}); act(t,{"type":"set_launch","vx":3,"dy":0}); act(t,{"type":"launch"})
	check(t.state.missed and not t.state.rope_cut,"water geometry misses")
	act(t,{"type":"current_tick"},false)
	act(t,{"type":"undo"})
	check(not t.state.launched,"undo real launch")
	act(t,{"type":"set_launch","vx":2,"dy":0}); act(t,{"type":"launch"})
	check(t.state.contacts==[[4,5],[7,5],[10,5]],"exact three contacts")
	act(t,{"type":"land","x":9,"y":6},false); act(t,{"type":"current_tick"})
	act(t,{"type":"land","x":10,"y":5},false); act(t,{"type":"land","x":9,"y":6})
	var w := Resolver.new(Resolver.IDS[1])
	act(w,{"type":"multiply_row","prior":243,"factor":3,"result":729},false)
	act(w,{"type":"observe_cut","cut":0},false)
	act(w,{"type":"observe_cut","cut":1}); act(w,{"type":"observe_cut","cut":1},false)
	for i in range(3): act(w,{"type":"split_group","group":i})
	act(w,{"type":"multiply_row","prior":1,"factor":3,"result":4},false)
	act(w,{"type":"multiply_row","prior":1,"factor":3,"result":3}); finish(w)
	check(w.state.rows.size()==6 and w.state.observations==[1,2,3,4,5,6],"six distinct cuts")
	for i in range(6): check(w.state.rows[i].result==Resolver.COUNTS[i],"exact power "+str(i))
	var s := Resolver.new(Resolver.IDS[2])
	act(s,{"type":"check_supports"},false)
	act(s,{"type":"place_batch","batch":0}); act(s,{"type":"place_batch","batch":0},false)
	check(s.state.posts.size()==5,"duplicate batch not counted")
	while not s.state.collapsed: act(s,s.next_demo_action())
	check(s.state.posts.is_empty() and s.state.trace.size()==3,"all posts collapse after three evasion rounds")
	for step in s.state.trace:
		check(step.player_path.size()>=1 and step.player_path.size()<=3,"player stride")
		check(step.rival_path.size()==4,"rival takes all intermediate four steps")
	act(s,{"type":"support_landing","ground":"marked_ground","support":"hands"},false)
	act(s,{"type":"observe_collapse"}); act(s,{"type":"support_landing","ground":"marked_ground","support":"feet"})
	act(s,{"type":"submit"},false); act(s,{"type":"retry"}); check(s.get_receipts().is_empty(),"retry invalidates own phase receipts")
	finish(s); check(s.state.landing=="hands" and not s.state.feet_ground,"legal hand support resolves not skip")
	check(Resolver.rival_route(0,2)==[1,2,3,4],"capture must detect target on intermediate step")
	check(Resolver.ring_route(44,3,1)==[0,1,2],"ring wrap is explicit graph edge")
	# Independent step-by-step oracle, all 6^3 authored choices, no direct state patch.
	var baseline := Resolver.new("trial_ch04_staff")
	for i in range(9): baseline.apply_input({"type":"place_batch","batch":i})
	for a in ["check_supports","read_rules","owner_consent"]: baseline.apply_input({"type":a})
	var start_snapshot: Dictionary = baseline.snapshot()
	var old_checkpoint: Dictionary = start_snapshot.duplicate(true); old_checkpoint.version=1
	check(not Resolver.new().restore(old_checkpoint),"reject obsolete chapter-four development model v1")
	var wins := 0; var losses := 0; var second_round := 0; var third_round := 0
	var options := [-3,-2,-1,1,2,3]
	for first in options:
		for second in options:
			for third in options:
				var trial := Resolver.new(); check(trial.restore(start_snapshot),"exhaustive setup replay")
				var player := 0; var rival := 12; var caught := false; var round_index := 0
				for signed_stride in [first,second,third]:
					round_index += 1
					var direction := 1 if signed_stride>0 else -1
					for hop in range(absi(signed_stride)):
						player = posmod(player+direction,45)
						if player==rival: caught=true
					if not caught:
						var pursuit_direction := 1 if posmod(player-rival,45)<=22 else -1
						for hop in range(4):
							rival=posmod(rival+pursuit_direction,45)
							if rival==player: caught=true; break
					trial.apply_input({"type":"read_intent"})
					trial.apply_input({"type":"move_posts","direction":direction,"stride":absi(signed_stride)})
					check(trial.state.player==player and trial.state.rival==rival and trial.state.captured==caught,"real engine equals independent oracle each round")
					if caught: break
				if caught:
					losses += 1
					if round_index==2: second_round += 1
					if round_index==3: third_round += 1
					check(not trial.state.complete,"captured route does not issue victory")
					trial.apply_input({"type":"retry"}); check(trial.state.player==0 and trial.state.rival==12 and trial.get_receipts().is_empty(),"captured retry restores fresh attempt")
				else: wins += 1
	check(wins==99 and losses==117 and second_round==36 and third_round==81,"0/12 produces 99 viable and 117 captured routes")
	var h := Resolver.new("r02")
	act(h,{"type":"rain_test"},false); act(h,{"type":"weave_slot","slot":0,"pattern":"over"},false)
	act(h,{"type":"collect_willow","material":0}); act(h,{"type":"collect_willow","material":0},false)
	act(h,{"type":"weave_slot","slot":0,"pattern":"under"}); act(h,{"type":"check_weave"},false)
	finish(h); check(h.state.rain.size()==6,"rain independently covers every slot")
	var b := Resolver.new("l01")
	act(b,{"type":"tide_tick"},false); act(b,{"type":"level_hull"},false)
	act(b,{"type":"collect_stores"}); act(b,{"type":"seat_board","slot":0,"board":1},false)
	act(b,{"type":"attach_winch","anchor":"unverified_tree"},false)
	while not b.state.released: act(b,b.next_demo_action())
	check(not b.state.complete,"level hull not enough")
	act(b,{"type":"tide_tick"}); act(b,{"type":"tide_tick"})
	check(not b.state.complete,"two ticks not three")
	act(b,{"type":"tide_tick"}); check(b.state.tide_log.size()==3 and b.state.water==0,"three zero-delta samples")
	var ledger := Resolver.new("ledger_ch04_r02")
	act(ledger,{"type":"compare_account","demand":15,"legal":12,"excess":3},false)
	act(ledger,{"type":"submit"},false)
	act(ledger,{"type":"inspect_account","field":"principal"})
	act(ledger,{"type":"inspect_account","field":"principal"},false)
	act(ledger,{"type":"inspect_account","field":"interest"})
	act(ledger,{"type":"sum_account","principal":10,"interest":2,"total":12},false)
	act(ledger,{"type":"inspect_account","field":"demand"})
	act(ledger,{"type":"sum_account","principal":10,"interest":2,"total":15},false)
	act(ledger,{"type":"sum_account","principal":10,"interest":2,"total":12})
	act(ledger,{"type":"compare_account","demand":15,"legal":12,"excess":2},false)
	act(ledger,{"type":"compare_account","demand":15,"legal":12,"excess":3})
	act(ledger,{"type":"undo"}); check(not ledger.state.difference_checked,"ledger undo invalidates subtraction")
	finish(ledger); check(ledger.receipt().objective_id=="r02_ledger_verified","ledger only issues its evidence objective")
	# A bounded full log can ALWAYS reset; genesis contains no solving state.
	var cap := Resolver.new("r02")
	for i in range(Resolver.MAX_LOG): cap.apply_input({"type":"hint"})
	check(not cap.apply_input({"type":"collect_willow","material":0}).ok,"log cap blocks more work")
	act(cap,{"type":"retry"}); check(cap.input_log.size()==1 and cap.state.hint==3,"bounded restart genesis")
	finish(cap)
	# Exhaust every allowed trajectory combination against the exact board contract.
	for vx in [1,2,3]:
		for dy in [-1,0,1]:
			var projectile := Resolver.new(Resolver.IDS[0])
			projectile.apply_input({"type":"observe_current"})
			projectile.apply_input({"type":"set_launch","vx":vx,"dy":dy})
			projectile.apply_input({"type":"launch"})
			check(projectile.state.rope_cut == (vx==2 and dy==0),"unique geometry solution")
	# All model logs remain bounded and independently recoverable after exhaustion.
	for id in Resolver.IDS:
		var limited := Resolver.new(id)
		for i in range(Resolver.MAX_LOG): limited.apply_input({"type":"hint"})
		act(limited,{"type":"reset"})
		check(limited.input_log.size()==1 and limited.state.hint==3,"all models reset after cap")
		finish(limited)
	# Stable actual UI controls emit resolver inputs, preserve focus/scroll across refresh.
	var ui_theme := Theme.new(); ui_theme.default_font=load("res://assets/fonts/kunlun_ui.ttf"); ui_theme.default_font_size=16
	var ui := PuzzleUI.new(); ui.theme=ui_theme; root.add_child(ui); ui.size=Vector2(600,300)
	var received: Array = []; ui.input_submitted.connect(func(a: Dictionary): received.append(a))
	var ui_r := Resolver.new("board_ch04_wood"); ui.render(ui_r.get_view()); await process_frame
	var panel: VBoxContainer = ui._chapter_four_panel
	var button: Button = panel._buttons.observe; button.grab_focus(); button.pressed.emit()
	check(received==[{"type":"observe_cut","cut":1}],"actual observe button emits authoritative input")
	ui_r.apply_input(received.back()); ui.render(ui_r.get_view()); await process_frame
	check(panel._buttons.observe==button and button.has_focus(),"stable focus across state update")
	ui._scroll.scroll_vertical=100; await process_frame
	var scroll: int = ui._scroll.scroll_vertical
	ui.render(ui_r.get_view()); await process_frame
	check(ui._scroll.scroll_vertical==scroll,"stable scroll on unchanged refresh")
	check(panel.size.x<=ui.size.x and ui._scroll.size.y>100,"small layout scrolls instead of clipping body")
	ui.queue_free(); await process_frame
	for dimensions in [Vector2(616,336),Vector2(1200,650)]:
		for id in Resolver.IDS:
			var shell := PuzzleUI.new(); shell.theme=ui_theme; root.add_child(shell); shell.size=dimensions
			var model := Resolver.new(id)
			shell.input_submitted.connect(func(a: Dictionary):
				model.apply_input(a)
				shell.render(model.get_view()))
			shell.render(model.get_view()); await process_frame
			var inner: VBoxContainer = shell._chapter_four_panel
			for i in range(3): inner._buttons.hint.pressed.emit()
			check(model.state.hint==3 and inner._buttons.assist.visible,"real UI reveals voluntary assistance")
			if id=="trial_ch04_staff":
				# A taller response above a focused action must not move its screen anchor.
				for i in range(9): model.apply_input({"type":"place_batch","batch":i})
				for a in ["check_supports","read_rules","owner_consent"]: model.apply_input({"type":a})
				shell.render(model.get_view()); await process_frame; await process_frame
				var intent_button: Button = inner._buttons.intent
				intent_button.grab_focus(); await process_frame
				shell._scroll.scroll_vertical += int(intent_button.global_position.y-shell.global_position.y)-100
				await process_frame
				var old_y := intent_button.global_position.y
				intent_button.pressed.emit(); await process_frame; await process_frame
				check(absf(intent_button.global_position.y-old_y)<=1.0,"focus stays at same visual y after multiline feedback")
				check(inner._labels.staff_intent_local.text.contains("12") and inner._labels.staff_intent_local.text.contains("追4"),"intent feedback is next to move controls")
			var iterations := 0
			while not model.state.complete and iterations<100:
				inner._buttons.assist.pressed.emit(); iterations += 1
			check(model.state.complete and model.state.assisted,"real UI reaches verified final state")
			await process_frame
			check(inner.size.x<=shell.size.x,"all boards fit responsive width")
			check(shell._scroll.size.y>=100,"body remains scrollable at both sizes")
			check(inner._buttons.assist.disabled and not inner._buttons.close.disabled,"completed controls locked but close available")
			shell.queue_free(); await process_frame
	# Reproduce the manual L01 button sequence, specifically checking that repair
	# controls never emit close_requested (a standalone preview closes on that signal).
	var boat_ui := PuzzleUI.new(); boat_ui.theme=ui_theme; root.add_child(boat_ui); boat_ui.size=Vector2(616,336)
	var boat_model := Resolver.new("l01"); var closes: Array = []
	boat_ui.close_requested.connect(func(): closes.append(true))
	boat_ui.input_submitted.connect(func(a: Dictionary): boat_model.apply_input(a); boat_ui.render(boat_model.get_view()))
	boat_ui.render(boat_model.get_view()); await process_frame
	var boat_inner: VBoxContainer = boat_ui._chapter_four_panel
	for key in ["stores","unload"]:
		boat_inner._buttons[key].grab_focus(); boat_inner._buttons[key].pressed.emit(); await process_frame; await process_frame
	for slot in range(3):
		boat_inner._selects.slot.select(slot); boat_inner._selects.board.select(slot)
		for key in ["seat","fill"]:
			boat_inner._buttons[key].grab_focus(); boat_inner._buttons[key].pressed.emit(); await process_frame; await process_frame
	for key in ["anchor","level","release","tide","tide","tide"]:
		boat_inner._buttons[key].grab_focus(); boat_inner._buttons[key].pressed.emit(); await process_frame; await process_frame
		check(closes.is_empty(),"manual boat repair button never closes preview")
	check(boat_model.state.complete and boat_model.state.ticks==3 and not boat_model.state.assisted,"manual L01 real UI finishes three tides")
	boat_ui.queue_free(); await process_frame
	print("Chapter four puzzles: %d checks, %d failures" % [checks,failures]); quit(1 if failures else 0)
