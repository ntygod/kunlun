extends SceneTree
## Isolated read-only UI contract and headless geometry tests. This does not
## claim natural graphical playthrough or final pixel-art acceptance.
const BattleUI = preload("res://scripts/ui/chapter_eight_battle_panel.gd")
const H := "char_liang_xiao"
var checks := 0
var failures := 0
var holder: Control
var modal: PanelContainer
var body: VBoxContainer
var panel: ChapterEightBattlePanel
var live: RefCounted

func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)

func fixture(phase: String = "phase_one") -> Dictionary:
	var target := "river_yunshu" if phase == "river_duel" else ("routed_pressure" if phase in ["phase_two", "completed"] else "ballista")
	var skills := {"normal_attack":{"target":"enemy"}, "self_guard":{"target":"self"}, "observe":{"target":"enemy"}, "sancai_counter":{"target":"enemy", "name":"三才归元掌"}, "LX_A03":{"target":"enemy", "name":"飞星九宫剑"}, "ch08_action":{"kind":"objective", "target":"self"}}
	var view := {"encounter":{"kind":"river_duel" if phase == "river_duel" else "b05", "name":"江心守台" if phase == "river_duel" else "襄樊攻防"}, "round":9, "revision":31, "outcome":"", "commands":{}, "events":[], "intents":[{"actor_id":target, "target_id":H, "name":"长篙蓄势" if phase == "river_duel" else "溃军乱斩", "executed":false}], "actors":[{"id":H, "team":"party", "name":"梁萧", "hp":604, "max_hp":1127, "mp":23, "max_mp":132, "skills":skills.keys(), "ready":{"sancai_counter":9, "LX_A03":11}, "passives":["LX_P01", "LX_P03"], "controllable":true, "defeated":false}, {"id":target, "team":"enemy", "name":"场景压力占位绝不显示气血", "hp":3800, "max_hp":3800, "defeated":false}], "skill_data":skills, "skill_costs":{H:{"normal_attack":0, "self_guard":0, "observe":5, "sancai_counter":14, "LX_A03":19}}, "legal_commands":{H:[{"skill_id":"self_guard", "target_id":H}, {"skill_id":"observe", "target_id":target}, {"skill_id":"sancai_counter", "target_id":target}, {"skill_id":"normal_attack", "target_id":target}]}, "objective":{"phase":phase, "phase_round":3, "pending":{}, "hubs":{"left_gear":1067, "center_pin":1067, "right_string":1066}, "calibrated":"", "bolts":3, "pressure":3800, "batch_index":0, "batches":[], "river_gaps":1, "p03_stacks":2, "p03_events":["break1", "break2"], "available_actions":[], "input_budget":{"command_remaining":5}, "summary":"公开目标规则。"}}
	for i in range(3): view.objective.batches.append({"id":"batch_%d" % (i + 1), "position":[2 if i == 0 else 0, i], "path":[[0,i],[1,i],[2,i]] if i == 0 else [[0,i]], "route":[[0,i],[1,i],[2,i],[3,i]], "protected":i == 0, "disarmed":false, "safe":false})
	for action in ["cancel", "retreat", "borrow_cover", "lead_batch", "escort_intercept"]:
		view.objective.available_actions.append({"input":{"actor_id":H, "action_id":action, "revision":31}, "label":action})
	for hub in ["left_gear", "center_pin", "right_string"]:
		view.objective.available_actions.append({"input":{"actor_id":H, "action_id":"inspect_hub", "value":hub, "revision":31}, "label":"校准"})
	return view

func setup() -> void:
	holder = Control.new(); root.add_child(holder)
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/kunlun_ui.ttf")
	theme.default_font_size = 20
	var style := StyleBoxFlat.new()
	style.content_margin_left = 24; style.content_margin_right = 24
	style.content_margin_top = 16; style.content_margin_bottom = 16
	theme.set_stylebox("panel", "PanelContainer", style)
	holder.theme = theme
	modal = PanelContainer.new(); holder.add_child(modal)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(scroll)
	body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	panel = BattleUI.new(); body.add_child(panel)

func resize_to(dimensions: Vector2i) -> void:
	root.size = dimensions; holder.size = dimensions
	modal.position = Vector2(20, 20)
	modal.size = Vector2(mini(850, dimensions.x - 40), mini(510, dimensions.y - 40))

func settle() -> void:
	for i in range(5): await process_frame

func select_skill(id: String) -> void:
	var options: OptionButton = panel.slots[H + "_skills"]
	for i in range(options.item_count):
		if options.get_item_metadata(i) == id:
			options.select(i); options.item_selected.emit(i); return
	check(false, "skill exists: " + id)

func check_bounds(phase: String) -> void:
	var content_rect := Rect2(modal.global_position + Vector2(24,16), modal.size - Vector2(48,32))
	for id in ["battle_heading", "hero_resources", "objective_summary", "public_intents", "objective_board", "battle_actions", "battle_feedback_scroll", "resolve", "continue", "leave"]:
		var control: Control = panel.slots[id]
		var rect := control.get_global_rect()
		check(content_rect.grow(1).encloses(rect), "%s/%s remains on-screen at %s: %s in %s" % [phase, id, root.size, rect, content_rect])
	for id in ["battle_heading", "hero_resources", "objective_summary"]:
		var label: Label = panel.slots[id]
		check(label.get_line_count() <= label.max_lines_visible, "%s objective text untruncated at %s (%d lines)" % [phase, root.size, label.get_line_count()])
	check(panel.action_scroll.get_v_scroll_bar().max_value > panel.action_scroll.size.y, "long controls scroll instead of displacing board/footer")
	check(panel.slots.battle_feedback is Label and panel.feedback_scroll.get_child(0) == panel.slots.battle_feedback, "bottom feedback remains fully scrollable")

func run() -> void:
	setup()
	for dimensions in [Vector2i(1280,720), Vector2i(640,360)]:
		resize_to(dimensions)
		for phase in ["river_duel", "phase_one", "intermission", "phase_two", "completed"]:
			var view := fixture(phase)
			if phase in ["intermission", "completed"]: view.outcome = "victory"
			var before := JSON.stringify(view)
			panel.render(view, {}, true); await settle()
			check_bounds(phase)
			check(JSON.stringify(view) == before, "render is read-only")
			check(panel.slots.public_intents is ScrollContainer and "溃军乱斩" in panel.intent_text.text or phase == "river_duel", "public engine intent preserved")
			check(panel.slots[H + "_skills"].item_count == 5, "objective action omitted from martial selector")
			check(panel.slots["continue"].disabled == (phase not in ["intermission", "completed"]), "continue only at intermission/completion")
			check(panel.slots.resolve.disabled == (phase in ["intermission", "completed"]), "intermission cannot advance battle time")
			check(("3800血" not in panel.intent_text.text or phase == "river_duel") and "场景压力占位" not in panel.intent_text.text, "scene pressure carrier never rendered as biological HP")
			if phase == "phase_two": check("普通攻击不能消除混乱度" in panel.slots.objective_summary.text, "nonlethal objective limitation stays visible")
			panel.show_details(); await settle()
			check(panel.details.visible and panel.details.size.x <= root.size.x and panel.details.size.y <= root.size.y, "rules/log popup fits viewport")
			check(panel.details_scroll.get_v_scroll_bar().max_value >= panel.details_scroll.size.y, "complete rules are scrollable")
			panel.slots.close_details.pressed.emit(); await settle()
			check(not panel.details.visible, "rules dismissal returns to battle")
	var view := fixture()
	panel.render(view, {}, true); await settle()
	var inputs: Array = []
	panel.input_submitted.connect(func(action: Dictionary): inputs.append(action))
	for hub in ["right_string", "left_gear", "center_pin"]:
		panel.slots["scene_inspect_hub_" + hub].pressed.emit()
		check(inputs[-1] == {"actor_id":H,"action_id":"inspect_hub","value":hub,"revision":31}, "hub button sends stable semantic ID: " + hub)
	check(panel.slots.scene_release_calibrated_shot_left_gear.disabled, "uncalibrated fire is visibly disabled")
	panel.slots.scene_release_calibrated_shot_left_gear.pressed.emit()
	check(inputs.size() == 3, "disabled scene action also guarded in callback")
	view.objective.calibrated = "left_gear"
	view.objective.available_actions.reverse()
	view.objective.available_actions.append({"input":{"actor_id":H,"action_id":"release_calibrated_shot","value":"left_gear"}})
	view.revision = 43
	panel.render(view, {}, true); await settle()
	panel.slots.scene_release_calibrated_shot_left_gear.pressed.emit()
	check(inputs[-1].value == "left_gear" and inputs[-1].revision == 43, "reorder/refresh keeps target identity and newest revision")
	view = fixture("phase_two")
	panel.render(view, {}, true); await settle()
	var commands: Array = []
	panel.command_requested.connect(func(actor: String, skill: String, target: String, revision: int): commands.append([actor,skill,target,revision]))
	select_skill("sancai_counter")
	check(not panel.slots[H + "_command"].disabled, "available three-talents can be compiled")
	panel.slots[H + "_command"].pressed.emit()
	check(commands == [[H,"sancai_counter","routed_pressure",31]], "three-talents explicitly targets non-biological pressure")
	select_skill("self_guard"); panel.slots[H + "_command"].pressed.emit()
	check(commands[-1] == [H,"self_guard",H,31], "self skills auto-target hero without emitting before compile")
	select_skill("LX_A03")
	check(panel.slots[H + "_command"].disabled, "real absolute cooldown disables unavailable skill")
	var options: OptionButton = panel.slots[H + "_skills"]
	check("19气" in options.get_item_text(options.selected) and "CD2" in options.get_item_text(options.selected), "cost and CD read runtime snapshot")
	view.actors[0].mp = 2
	view.skill_costs[H].sancai_counter = 17
	view.skill_data.sancai_counter.name = "当前三才"
	panel.render(view, {"sancai_counter":{"name":"过期三才"}}, true); await settle()
	select_skill("sancai_counter")
	options = panel.slots[H + "_skills"]
	check("当前三才" in options.get_item_text(options.selected) and "17气" in options.get_item_text(options.selected) and "气不足" in options.get_item_text(options.selected), "current engine skill metadata wins and insufficient MP explained")
	panel.slots[H + "_command"].pressed.emit()
	check(commands.size() == 2, "unavailable skill cannot emit a command even via callback")
	view = fixture("phase_two"); view.input_error = "错误目标。".repeat(80)
	view.intents[0].name = "公开威胁。".repeat(80)
	panel.render(view, {}, true); await settle()
	check(panel.feedback_scroll.get_v_scroll_bar().max_value > panel.feedback_scroll.size.y, "long error retained in bottom scroll")
	check(panel.intent_scroll.get_v_scroll_bar().max_value > panel.intent_scroll.size.y, "long public intent retained in scroll")
	var end := InputEventKey.new(); end.pressed = true; end.keycode = KEY_END
	panel._scroll_key(end, panel.intent_scroll); await settle()
	check(panel.intent_scroll.scroll_vertical > 0, "keyboard can reach end of public intent")
	panel._scroll_key(end, panel.action_scroll); await settle()
	check(panel.action_scroll.scroll_vertical > 0, "keyboard can reach all scene/martial controls")
	panel.intent_scroll.grab_focus()
	var scroll_before: int = panel.intent_scroll.scroll_vertical
	panel.render(view, {}, true); await settle()
	check(panel.intent_scroll.scroll_vertical == scroll_before, "rerender preserves public-intent scroll position")
	panel.show_details(); await settle()
	panel.slots.close_details.grab_focus()
	panel.slots.close_details.pressed.emit(); await settle()
	check(panel.get_viewport().gui_get_focus_owner() == panel.intent_scroll, "closing details restores visible battle focus")
	resize_to(Vector2i(1280,720)); await settle(); check_bounds("live_resize_large")
	resize_to(Vector2i(640,360)); await settle(); check_bounds("live_resize_small")
	view.objective.input_budget.command_remaining = 0
	panel.render(view, {}, true); await settle()
	select_skill("self_guard")
	check(panel.slots[H + "_command"].disabled and panel.slots.scene_lead_batch.disabled and not panel.slots.retry.disabled, "exhausted edit budget disables submissions and preserves checkpoint retry")
	check("编排次数已到上限" in panel._feedback() or view.input_error != "", "edit budget limitation explained")
	view = fixture("intermission"); view.outcome = "victory"
	panel.render(view, {}, false); await settle()
	check(not panel.slots["continue"].disabled and panel.slots["continue"].text == "返回世界", "intermission victory offers world return")
	view = fixture("phase_two"); view.round = 7; view.outcome = ""
	panel.render(view, {}, true); await settle()
	check(panel.slots["continue"].disabled and not panel.slots.resolve.disabled, "resumed same campaign clears victory controls")
	view.outcome = "defeat"
	panel.render(view, {}, false); await settle()
	check(not panel.slots.retry.disabled and panel.slots["continue"].disabled and panel.slots.resolve.disabled, "defeat offers checkpoint retry without victory")
	await real_engine_walkthrough()
	holder.queue_free(); await settle()
	print("CH08 battle panel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func real_engine_walkthrough() -> void:
	var session_script = load("res://scripts/combat/chapter_eight_encounter.gd")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_eight_encounters.json"))
	var hero := {"id":H,"name":"梁萧","team":"party","hp":1127,"max_hp":1127,"mp":7,"max_mp":132,"atk":178,"def":111,"spd":40,"skills":["normal_attack","self_guard","observe","sancai_counter","LX_A03"],"passives":["LX_P01","LX_P03"],"acquired_passives":["LX_P01","LX_P02","LX_P03"],"internal_skill":"","level":37,"xp":13050}
	panel.input_submitted.connect(_live_input)
	panel.command_requested.connect(_live_command)
	panel.resolve_requested.connect(_live_resolve)
	live = session_script.new(rules,runtime,data.encounters.enc_ch08_river_duel,[hero],"ui_real_river")
	for gap in range(3):
		await live_scene("scene_borrow_cover")
		await live_skill("self_guard")
	check(live.engine.state.outcome == "victory" and live.engine.state.objective.river_gaps == 3, "real UI river route completes three gaps")
	check(not panel.slots["continue"].disabled and panel.slots.scene_retreat.disabled, "actual river victory offers continuation, never a misleading retreat command")
	live = session_script.new(rules,runtime,data.encounters.enc_ch08_ballista_objective,[hero],"ui_real_b05")
	for hub in ["left_gear","center_pin","right_string"]:
		await live_scene("scene_inspect_hub_" + hub)
		await live_scene("scene_release_calibrated_shot_" + hub)
	check(live.engine.state.objective.phase == "intermission" and not panel.slots["continue"].disabled, "six real scene UI actions pause the same campaign")
	check(live.engine.state.objective.p03_stacks == 3 and "格物3/3层" in panel.slots.hero_resources.text, "actual equipped passive layers displayed")
	var mana: int = live.engine.actor_by_id(H).mp
	check(live.resume_phase_two({"fire_confirmed":true},"ui_phase_two"), "real same-campaign resume succeeds")
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check(live.engine.actor_by_id(H).mp == mana and panel.slots["continue"].disabled, "resume preserves mana and removes first-phase continuation")
	check(panel.board.objective.batches[0].route == [[0,0],[1,0],[2,0],[3,0]], "full public route available before first movement")
	for batch in range(3):
		await live_scene("scene_lead_batch")
		check(panel.board.objective.batches[batch].position == [2,batch], "board tracks real two-edge lead path")
		await live_scene("scene_escort_intercept")
		check(panel.board.objective.batches[batch].protected, "board carries current-batch actual protection")
		await live_skill("sancai_counter")
		check(panel.board.objective.batches[batch].safe and panel.board.objective.batches[batch].position == [3,batch], "actual counter moves batch to safe exit")
	check(live.engine.state.outcome == "victory" and live.engine.state.objective.pressure == 0, "three real UI escort cycles complete nonlethal objective")
	check("混乱度0/3800" in panel.slots.objective_summary.text and not panel.slots["continue"].disabled, "completed pressure and continuation match engine")
	panel.input_submitted.disconnect(_live_input)
	panel.command_requested.disconnect(_live_command)
	panel.resolve_requested.disconnect(_live_resolve)
	live = null

func _live_input(action: Dictionary) -> void:
	check(live.apply_input(action).accepted, "UI scene command accepted by live engine")
func _live_command(actor: String, skill: String, target: String, revision: int) -> void:
	check(live.set_command(actor,skill,target,revision) == "", "UI martial command accepted by live engine")
func _live_resolve() -> void:
	check(live.resolve_round(), "UI resolves a real complete round")
func live_scene(id: String) -> void:
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check(not panel.slots[id].disabled, "real scene button available: " + id)
	panel.slots[id].pressed.emit()
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check(not panel.slots.resolve.disabled, "real pending scene enables round resolution")
	panel.slots.resolve.pressed.emit()
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check_bounds("real_" + live.engine.state.objective.phase)
func live_skill(id: String) -> void:
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	select_skill(id)
	check(not panel.slots[H + "_command"].disabled, "real martial command available: " + id)
	panel.slots[H + "_command"].pressed.emit()
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check(not panel.slots.resolve.disabled, "real pending martial enables round resolution")
	panel.slots.resolve.pressed.emit()
	panel.render(live.get_view(), {}, live.can_resolve()); await settle()
	check_bounds("real_" + live.engine.state.objective.phase)
