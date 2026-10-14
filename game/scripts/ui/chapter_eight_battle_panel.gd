class_name ChapterEightBattlePanel
extends "res://scripts/ui/objective_battle_panel.gd"
## Read-only presentation of the chapter-eight encounter. Commands carry stable
## target IDs and the rendered revision; neither widgets nor paths award progress.
const HERO := "char_liang_xiao"
const HUBS := ["left_gear", "center_pin", "right_string"]
const HUB_NAMES := {"left_gear":"左齿轮", "center_pin":"中承销", "right_string":"右牵弦"}
const BATCH_NAMES := ["母子", "伤者搀行", "老弱同行"]
const PASSIVE_NAMES := {"LX_P01":"九算天资", "LX_P02":"折弓血誓", "LX_P03":"格物致知"}

var slots: Dictionary = {}
var controls: Array[Control] = []
var labels: Array[Label] = []
var skill_data_local: Dictionary = {}
var selections: Dictionary = {}
var saved_scroll: Dictionary = {}
var intent_scroll: ScrollContainer
var intent_text: Label
var action_scroll: ScrollContainer
var action_body: VBoxContainer
var feedback_scroll: ScrollContainer
var details: PopupPanel
var details_scroll: ScrollContainer
var details_text: Label
var board: ObjectiveBoard

func _ready() -> void:
	if not get_viewport().size_changed.is_connected(_metrics):
		get_viewport().size_changed.connect(_metrics)

func render(snapshot: Dictionary, skill_data: Dictionary, can_resolve: bool) -> void:
	# Capture before replacement controls emit their initial scrollbar values.
	saved_scroll.clear()
	if get_parent() != null:
		for id in ["public_intents", "battle_actions", "battle_feedback_scroll"]:
			saved_scroll[id] = int(get_parent().get_meta("ch08_scroll_" + id, 0))
	for child in get_children():
		remove_child(child)
		child.queue_free()
	slots.clear(); controls.clear(); labels.clear()
	view = snapshot.duplicate(true)
	skill_data_local = view.get("skill_data", skill_data).duplicate(true)
	if get_parent() != null:
		selections = get_parent().get_meta("ch08_selections", {}).duplicate(true)
	add_theme_constant_override("separation", 2)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var phase_name: String = {"river_duel":"江心交锋", "phase_one":"第一段·毁弩", "intermission":"世界中场", "phase_two":"第二段·护民", "completed":"护民完成"}.get(_phase(), "襄樊攻防")
	_line(self, "battle_heading", "%s · 第%d轮 · %s" % [view.get("encounter", {}).get("name", "襄樊攻防"), int(view.get("round", 1)), phase_name])
	var hero := _actor(HERO)
	_line(self, "hero_resources", "梁萧 %d/%d血 · %d/%d气 · 格物%d/3层 · %s" % [hero.get("hp", 0), hero.get("max_hp", 0), hero.get("mp", 0), hero.get("max_mp", 0), _objective().get("p03_stacks", 0), _pending_name()])
	_line(self, "objective_summary", _objective_text(), 2)
	intent_scroll = _scroll(self, "public_intents")
	intent_text = _line(intent_scroll, "complete_intent_text", _intents_text(), 0)
	board = ObjectiveBoard.new()
	board.name = "objective_board"
	board.phase = _phase()
	board.objective = _objective().duplicate(true)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.tooltip_text = "路径示意：仅显示已验证位置及公开路线。金点为当前批，绿框为安全口；不以点击棋盘代替真实行动。"
	add_child(board); slots[board.name] = board
	action_scroll = _scroll(self, "battle_actions")
	action_body = VBoxContainer.new()
	action_body.name = "battle_action_body"
	action_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_body.add_theme_constant_override("separation", 3)
	action_scroll.add_child(action_body)
	_build_scene_actions()
	_build_skill_controls()
	_line(action_body, "resource_policy", _resource_policy(), 0)
	_line(action_body, "passive_status", _passive_text(), 0)
	if _phase() in ["phase_two", "completed"]:
		for index in range(_objective().get("batches", []).size()):
			_line(action_body, "batch_path_%d" % index, _batch_text(index), 0)
	feedback_scroll = _scroll(self, "battle_feedback_scroll")
	_line(feedback_scroll, "battle_feedback", _feedback(), 0)
	var footer := HBoxContainer.new()
	footer.name = "battle_footer"
	footer.add_theme_constant_override("separation", 3)
	add_child(footer)
	_button_id(footer, "resolve", "结算回合", func(): resolve_requested.emit(), not can_resolve or not _active())
	_button_id(footer, "retry", "原资源重试", func(): retry_requested.emit(), _can_continue())
	_button_id(footer, "continue", "返回世界" if _phase() == "intermission" else "继续剧情", func(): continue_requested.emit(), not _can_continue())
	_button_id(footer, "details", "规则/日志", show_details, false)
	_button_id(footer, "leave", "暂歇", func(): leave_requested.emit(), false)
	_build_details()
	_metrics()
	call_deferred("_restore_scroll_and_focus")

func _objective() -> Dictionary:
	return view.get("objective", {})

func _phase() -> String:
	return str(_objective().get("phase", "river_duel" if view.get("encounter", {}).get("kind", "") == "river_duel" else "phase_one"))

func _active() -> bool:
	return view.get("outcome", "") == "" and _phase() not in ["intermission", "completed"]

func _can_continue() -> bool:
	return view.get("outcome", "") == "victory" or (_phase() == "intermission" and view.get("outcome", "") != "defeat")

func _actor(id: String) -> Dictionary:
	for actor in view.get("actors", []):
		if actor.get("id", "") == id: return actor
	return {}

func _target_id() -> String:
	return "river_yunshu" if _phase() == "river_duel" else ("routed_pressure" if _phase() in ["phase_two", "completed"] else "ballista")

func _target_name(id: String) -> String:
	if id == "routed_pressure": return "乱兵阵势（场景）"
	if id == "ballista": return "同一弩台"
	if id == "river_yunshu": return "云殊"
	return str(_actor(id).get("name", "梁萧" if id == HERO else id))

func _objective_text() -> String:
	var o := _objective()
	match _phase():
		"river_duel":
			return "目标：三次压开空隙，再退至床弩位（%d/3）。\n三才诱偏／蓄势窗飞星／借石移步；云殊存活。" % _count(o.get("river_gaps", 0))
		"phase_one":
			return "目标：逐处校准→次轮发射，三枢纽全毁。任务弹%d/3。\n近战距离不可及；校准不等于毁弩，三处各耗两行动。" % int(o.get("bolts", 3))
		"intermission":
			return "同一弩台已毁，战役暂停。可返回世界处理巷道救援。\n中场不流逝回合、不补满资源；火攻确认后续战。"
		"phase_two", "completed":
			return "目标：护送三批＋三才引偏卸刃；混乱度%d/3800。\n普通攻击不能消除混乱度；民众不是战斗同伴。" % int(o.get("pressure", 3800))
	return str(o.get("summary", "依公开意图编排行动。"))

func _count(value: Variant) -> int:
	if value is Array or value is Dictionary: return value.size()
	return int(value)

func _intents_text() -> String:
	var lines: Array[String] = []
	for intent in view.get("intents", []):
		var actor_id := str(intent.get("actor_id", intent.get("source", "")))
		var name := _target_name(actor_id)
		var actor := _actor(actor_id)
		if actor_id == "river_yunshu": name += " %d血" % int(actor.get("hp", 0))
		elif actor_id == "ballista": name += " %d结构" % int(actor.get("hp", 0))
		var tell := "%s：%s" % [name, intent.get("name", "戒备")]
		if intent.get("executed", false): tell += "（已执行）"
		var target := str(intent.get("target_id", ""))
		if target != "": tell += " → " + _target_name(target)
		lines.append(tell)
	return "公开威胁（可滚动）：" + ("；".join(lines) if not lines.is_empty() else ("中场暂停" if _phase() == "intermission" else "暂无待执行意图"))

func _pending_name() -> String:
	var pending: Dictionary = _objective().get("pending", {})
	if not pending.is_empty(): return "已编排：" + _action_label(pending)
	var command: Dictionary = view.get("commands", {}).get(HERO, {})
	if not command.is_empty(): return "已编排：" + _skill_name(str(command.get("skill_id", "")))
	return "尚未编排"

func _resource_policy() -> String:
	if _phase() == "river_duel":
		return "江心入口仅梁萧一次免费整备HP；独立开场MP满一次。借石0气，算一次正常行动；每两轮的空隙须在偶数轮结束提交。退战重试回本场入口。"
	return "B05首次入场仅梁萧一次整备HP、独立开场MP满一次。中场／第二段不补满，保留真实HP/MP、冷却、状态、药份及格物层；第二段失败回本阶段入口。"

func _passive_text() -> String:
	var actor := _actor(HERO)
	var passives: Array = actor.get("equipped_passives", actor.get("passives", []))
	var names: Array[String] = []
	for passive in passives: names.append(str(PASSIVE_NAMES.get(passive, passive)))
	return "被动两槽：%s（战内及中场锁定）。格物仅已装备生效，破器／有效打断加层；第二段诱偏不加层。单人护民不触发护短。" % ("、".join(names) if not names.is_empty() else "空槽")

func _batch_text(index: int) -> String:
	var batches: Array = _objective().get("batches", [])
	var batch: Dictionary = batches[index]
	var path_parts: Array[String] = []
	for point in batch.get("route", batch.get("path", [])): path_parts.append(str(point))
	return "第%d批 %s：位置%s；路径%s；%s／%s／%s" % [index + 1, BATCH_NAMES[mini(index, 2)], str(batch.get("position", "待核实")), " → ".join(path_parts), "本拍已护卫" if batch.get("protected", false) else "待护卫", "已卸刃" if batch.get("disarmed", false) else "兵刃尚在", "已到安全口" if batch.get("safe", false) else "尚未撤出"]

func _feedback() -> String:
	var error := str(view.get("input_error", ""))
	if error != "":
		return "反馈：" + str({"protection_wait":"枢纽受保护，本轮可校准，请等保护结束再发射。", "calibrate_first":"先校准同一枢纽，再于后续轮发射。", "invalid_hub":"请选择未毁的稳定枢纽标识。", "structure_out_of_reach":"近战距离不可及，不消耗行动。请使用现场校准与发射。", "scene_target_incompatible":"该武学不适用于场景压力，不消耗行动。", "cooldown":"此招仍在调息。", "insufficient_mp":"真气不足，请选自守或观势等合法回气路线。", "stale_revision":"局面已改变，请重新编排行动。", "invalid_revision":"局面已改变，请重新编排行动。"}.get(error, error))
	if int(_objective().get("input_budget", {}).get("command_remaining", 1)) <= 0:
		return "本轮编排次数已到上限；可结算已编排的行动，或原资源重试。"
	if view.get("outcome", "") == "defeat":
		return "本次未完成：%s。重试恢复本阶段入口，不播放民众死亡，不重发奖励。" % str({"hero_exhausted":"梁萧气竭", "escort_retry":"当前批护送失守", "retreated":"主动败退"}.get(_objective().get("failure", ""), "梁萧气竭或护送失守"))
	if _phase() == "intermission": return "第一段已完成；点击返回世界。中场成长按真实事务同步，第二段不会覆盖为旧面板。"
	if view.get("outcome", "") == "victory": return "目标已经实际完成。资源按实保留，继续剧情；这次救援不抹去城中灾难。" if _phase() != "river_duel" else "三次空隙与退离已完成；云殊仍存活，继续修弩。"
	if not _objective().get("pending", {}).is_empty() or view.get("commands", {}).has(HERO):
		return _pending_name() + "。点击结算回合才执行；可取消编排。"
	match _phase():
		"river_duel": return "借石是0气路线：奇数蓄势轮先移步，偶数攻击落空后记空隙；三次后沿路线退至弩位。"
		"phase_one": return "每次破器后的下一轮受保护：可校准，暂不可发射。等保护结束再射；错选不耗任务弹。"
		"phase_two": return "第%d拍：引民过街→全拦截护卫→三才诱偏。保护期三才只减伤、不卸刃；等下一合法窗口。" % (((int(_objective().get("phase_round", 1)) - 1) % 3) + 1)
	return "选择后编排，再结算回合。"

func _build_scene_actions() -> void:
	var phase := _phase()
	if phase in ["phase_one", "intermission"]:
		var row := HBoxContainer.new(); action_body.add_child(row)
		for hub in HUBS:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_theme_constant_override("separation", 2)
			row.add_child(column)
			_scene_button(column, "inspect_hub", "校准" + HUB_NAMES[hub], hub)
			_scene_button(column, "release_calibrated_shot", "发射→" + HUB_NAMES[hub], hub)
	elif phase in ["phase_two", "completed"]:
		var row := HBoxContainer.new(); action_body.add_child(row)
		_scene_button(row, "lead_batch", "引本批过街 · 0气")
		_scene_button(row, "escort_intercept", "全拦截护卫 · 0气")
		_line(action_body, "escort_rule", "护卫：整包转向梁萧，再结算自身防御与25%护体；只护当前批本次。三才成功卸刃后才走最后一格。", 0)
	else:
		var row := HBoxContainer.new(); action_body.add_child(row)
		_scene_button(row, "borrow_cover", "借矢石移步 · 0气")
	var utility := HBoxContainer.new(); action_body.add_child(utility)
	_scene_button(utility, "cancel", "取消本轮编排")
	_scene_button(utility, "retreat", "败退（原入口重试）")

func _scene_button(parent: Node, action_id: String, title: String, value: String = "") -> void:
	var input := {"actor_id":HERO, "action_id":action_id}
	if value != "": input["value"] = value
	var id := "scene_" + action_id + ("_" + value if value != "" else "")
	var button := _button_id(parent, id, title, _scene_submit.bind(input), not _available(input))
	button.set_meta("input", input.duplicate(true))
	button.tooltip_text = title + "。编排一正常行动，随后结算回合。" if action_id not in ["cancel", "retreat"] else title
	if button.disabled: button.tooltip_text += " 当前阶段、保护、目标状态或编排次数不允许。"

func _available(action: Dictionary) -> bool:
	if not _active() or int(_objective().get("input_budget", {}).get("command_remaining", 1)) <= 0: return false
	for option in _objective().get("available_actions", []):
		var input: Dictionary = option.get("input", {}).duplicate(true)
		input.erase("revision")
		if input == action: return not option.get("disabled", false)
	return false

func _scene_submit(action: Dictionary) -> void:
	if not _available(action): return
	var input := action.duplicate(true)
	input["revision"] = int(view.get("revision", 0))
	input_submitted.emit(input)

func _action_label(action: Dictionary) -> String:
	var kind := str(action.get("action_id", ""))
	var name: String = {"inspect_hub":"校准", "release_calibrated_shot":"发射", "lead_batch":"引民过街", "escort_intercept":"全拦截护卫", "borrow_cover":"借矢石移步", "retreat":"退离", "cancel":"取消编排"}.get(kind, "场景行动")
	if action.has("value"): name += " " + str(HUB_NAMES.get(action.value, action.value))
	return name

func _skill_name(id: String) -> String:
	return str(skill_data_local.get(id, {}).get("name", SKILL_NAMES.get(id, "飞星九宫剑" if id == "LX_A03" else id)))

func _build_skill_controls() -> void:
	var hero := _actor(HERO)
	var row := HBoxContainer.new()
	row.name = HERO + "_command_row"
	row.add_theme_constant_override("separation", 3)
	action_body.add_child(row)
	var skills := OptionButton.new()
	skills.name = HERO + "_skills"
	skills.fit_to_longest_item = false
	skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for skill_id in hero.get("skills", []):
		if skill_data_local.get(skill_id, {}).get("kind", "") == "objective" or skill_id in ["objective_action", "ch08_action"]: continue
		var cost: int = int(view.get("skill_costs", {}).get(HERO, {}).get(skill_id, -1))
		var cooldown := maxi(0, int(hero.get("ready", {}).get(skill_id, 1)) - int(view.get("round", 1)))
		var text := "%s · %s气" % [_skill_name(skill_id), str(cost) if cost >= 0 else "?"]
		if cooldown > 0: text += " · CD%d" % cooldown
		elif cost >= 0 and int(hero.get("mp", 0)) < cost: text += " · 气不足"
		skills.add_item(text)
		skills.set_item_metadata(skills.item_count - 1, skill_id)
		skills.set_item_disabled(skills.item_count - 1, not _skill_available(skill_id))
	row.add_child(skills); _register_control(skills)
	if skills.item_count > 0:
		skills.select(_metadata_index(skills, selections.get("skill_id", "self_guard")))
	var targets := OptionButton.new()
	targets.name = HERO + "_targets"
	targets.fit_to_longest_item = false
	targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in [HERO, _target_id()]:
		targets.add_item(_target_name(id)); targets.set_item_metadata(targets.item_count - 1, id)
	row.add_child(targets); _register_control(targets)
	_button_id(row, HERO + "_command", "编排武学", _submit_selected_skill, true)
	skills.item_selected.connect(func(_index: int): _refresh_skill_targets())
	targets.item_selected.connect(func(_index: int): _refresh_skill_targets())
	_line(action_body, "selected_skill_details", "", 0)
	_refresh_skill_targets()
	_line(action_body, "skill_rule", "武学费用来自当前实装，CD按绝对回合显示。三才目标：" + _target_name(_target_id()) + "。" + ("普通攻击只牵制，不扣混乱度、不回气、无击杀收益；飞星不适用于场景压力。" if _phase() in ["phase_two", "completed"] else "每轮仅梁萧一次正常行动。"), 0)

func _metadata_index(options: OptionButton, value: Variant) -> int:
	for index in range(options.item_count):
		if options.get_item_metadata(index) == value: return index
	return 0

func _skill_available(skill_id: String) -> bool:
	var hero := _actor(HERO)
	if not _active() or int(_objective().get("input_budget", {}).get("command_remaining", 1)) <= 0 or hero.get("defeated", false) or not hero.get("controllable", true): return false
	if skill_id not in hero.get("skills", []): return false
	var cost := int(view.get("skill_costs", {}).get(HERO, {}).get(skill_id, -1))
	if cost < 0 or int(hero.get("mp", 0)) < cost: return false
	if int(hero.get("ready", {}).get(skill_id, 1)) > int(view.get("round", 1)): return false
	for command in view.get("legal_commands", {}).get(HERO, []):
		if command.get("skill_id", "") == skill_id: return true
	return false

func _legal_target(skill_id: String, target_id: String) -> bool:
	if not _skill_available(skill_id): return false
	for command in view.get("legal_commands", {}).get(HERO, []):
		if command.get("skill_id", "") == skill_id and command.get("target_id", "") == target_id: return true
	return false

func _refresh_skill_targets() -> void:
	var skills: OptionButton = slots.get(HERO + "_skills")
	var targets: OptionButton = slots.get(HERO + "_targets")
	var submit: Button = slots.get(HERO + "_command")
	if skills == null or skills.selected < 0:
		submit.disabled = true
		return
	var skill := str(skills.get_item_metadata(skills.selected))
	var chosen := -1
	for index in range(targets.item_count):
		var legal := _legal_target(skill, str(targets.get_item_metadata(index)))
		targets.set_item_disabled(index, not legal)
		if legal and chosen < 0: chosen = index
	targets.select(chosen)
	submit.disabled = chosen < 0
	var explanation: Label = slots.get("selected_skill_details")
	if explanation != null:
		explanation.text = "所选：" + skills.get_item_text(skills.selected) + (" → " + _target_name(str(targets.get_item_metadata(chosen))) if chosen >= 0 else "；当前不可用（阶段、目标、真气或冷却限制）。")
	selections["skill_id"] = skill
	if get_parent() != null: get_parent().set_meta("ch08_selections", selections.duplicate(true))

func _submit_selected_skill() -> void:
	var skills: OptionButton = slots.get(HERO + "_skills")
	var targets: OptionButton = slots.get(HERO + "_targets")
	if skills == null or targets == null or skills.selected < 0 or targets.selected < 0: return
	var skill := str(skills.get_item_metadata(skills.selected))
	var target := str(targets.get_item_metadata(targets.selected))
	if _legal_target(skill, target): command_requested.emit(HERO, skill, target, int(view.get("revision", 0)))

func _line(parent: Node, id: String, text: String, lines: int = 1) -> Label:
	var label := Label.new()
	label.name = id; label.text = text; label.tooltip_text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	# A zero line count lives in a ScrollContainer and retains all text.
	label.set_meta("lines", lines)
	if lines > 0: label.max_lines_visible = lines
	parent.add_child(label); labels.append(label); slots[id] = label
	return label

func _button_id(parent: Node, id: String, text: String, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.name = id; button.text = text; button.tooltip_text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = disabled
	button.pressed.connect(callback)
	parent.add_child(button); _register_control(button)
	return button

func _register_control(control: Control) -> void:
	controls.append(control); slots[control.name] = control
	control.focus_entered.connect(_remember_focus.bind(str(control.name)))

func _scroll(parent: Node, id: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	parent.add_child(scroll); slots[id] = scroll
	scroll.focus_entered.connect(_remember_focus.bind(id))
	scroll.gui_input.connect(_scroll_key.bind(scroll))
	scroll.get_v_scroll_bar().value_changed.connect(func(value: float):
		if get_parent() != null: get_parent().set_meta("ch08_scroll_" + id, int(value)))
	return scroll

func _scroll_key(event: InputEvent, scroll: ScrollContainer) -> void:
	if not event is InputEventKey or not event.pressed: return
	match event.keycode:
		KEY_DOWN: scroll.scroll_vertical += 20
		KEY_UP: scroll.scroll_vertical -= 20
		KEY_PAGEDOWN: scroll.scroll_vertical += int(scroll.size.y)
		KEY_PAGEUP: scroll.scroll_vertical -= int(scroll.size.y)
		KEY_HOME: scroll.scroll_vertical = 0
		KEY_END: scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		_: return
	scroll.accept_event()

func _remember_focus(id: String) -> void:
	if id in ["close_details", "rules_log_scroll"]: return
	if get_parent() != null: get_parent().set_meta("ch08_focus", id)

func _restore_scroll_and_focus() -> void:
	if not is_inside_tree(): return
	if get_parent() != null:
		for id in ["public_intents", "battle_actions", "battle_feedback_scroll"]:
			var scroll: ScrollContainer = slots[id]
			scroll.scroll_vertical = int(saved_scroll.get(id, 0))
	_restore_focus()

func _restore_focus() -> void:
	if not is_inside_tree(): return
	var id := str(get_parent().get_meta("ch08_focus", "public_intents")) if get_parent() != null else "public_intents"
	var target: Control = slots.get(id, slots.get("details"))
	if target != null and (not target.is_visible_in_tree() or (target is Button and target.disabled)): target = slots.get("details")
	if target != null: target.grab_focus()

func _metrics() -> void:
	var small := get_viewport_rect().size.y <= 440
	for label in labels:
		if not is_instance_valid(label): continue
		label.add_theme_font_size_override("font_size", 12 if small else 17)
		label.add_theme_constant_override("line_spacing", 0)
		var lines := int(label.get_meta("lines", 0))
		if lines > 0: label.custom_minimum_size.y = (16 if small else 24) * lines
	for control in controls:
		if not is_instance_valid(control): continue
		control.add_theme_font_size_override("font_size", 12 if small else 16)
		control.custom_minimum_size.y = 23 if small else 32
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("17282d") if state == "disabled" else Color("294049")
			style.border_color = Color("e3c58b") if state == "focus" else Color("647a75")
			style.set_border_width_all(1)
			style.content_margin_left = 4; style.content_margin_right = 4
			style.content_margin_top = 1; style.content_margin_bottom = 1
			control.add_theme_stylebox_override(state, style)
	if is_instance_valid(board):
		board.custom_minimum_size.y = 68 if small else 105
		board.small = small; board.queue_redraw()
	if is_instance_valid(intent_scroll): intent_scroll.custom_minimum_size.y = 28 if small else 48
	if is_instance_valid(action_scroll): action_scroll.custom_minimum_size.y = 50 if small else 120
	if is_instance_valid(feedback_scroll): feedback_scroll.custom_minimum_size.y = 32 if small else 48

func _build_details() -> void:
	details = PopupPanel.new(); details.name = "ch08_rules_log"
	details.transient = true; details.exclusive = true
	add_child(details)
	var column := VBoxContainer.new(); details.add_child(column)
	details_scroll = _scroll(column, "rules_log_scroll")
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var text := _objective_text() + "\n\n" + str(_objective().get("summary", "")) + "\n\n" + _resource_policy() + "\n\n" + _passive_text()
	text += "\n\n" + str(view.get("save_policy", "编排中可F5保存、F9读档；重试不重复奖励。"))
	text += "\n\n第二段三才：保护期只有自守式35%减伤，不取消敌动作、不卸刃。三批均安全、三刃全卸、混乱度归零且梁萧存活才完成。"
	text += "\n\n最近战斗日志："
	var events: Array = view.get("events", [])
	for event in events.slice(maxi(0, events.size() - 60)):
		text += "\n第%d轮 %s %s→%s %s %s" % [int(event.get("round", 0)), str(event.get("type", "")), _target_name(str(event.get("source", ""))), _target_name(str(event.get("target", ""))), str(event.get("amount", "")), str(event.get("detail", ""))]
	details_text = _line(details_scroll, "rules_log_text", text, 0)
	var close := _button_id(column, "close_details", "返回交锋（Esc）", func(): details.hide(); _restore_focus(), false)
	var key := InputEventKey.new(); key.keycode = KEY_ESCAPE
	var shortcut := Shortcut.new(); shortcut.events = [key]; close.shortcut = shortcut
	details.popup_hide.connect(_restore_focus)

func show_details() -> void:
	var viewport_size := get_viewport_rect().size
	details_scroll.custom_minimum_size = Vector2(minf(740, viewport_size.x - 90), minf(340, viewport_size.y - 110))
	details.popup_centered(Vector2i(mini(800, int(viewport_size.x) - 60), mini(440, int(viewport_size.y) - 60)))

class ObjectiveBoard extends Control:
	var objective: Dictionary = {}
	var phase := "phase_one"
	var small := false
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("12252b"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("647a75"), false, 1)
		if phase in ["phase_two", "completed"]: _draw_batches()
		elif phase == "river_duel": _draw_river()
		else: _draw_hubs()
	func _text(point: Vector2, text: String, color := Color("e2dfd0")) -> void:
		draw_string(get_theme_font("font", "Label"), point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12 if small else 17, color)
	func _draw_hubs() -> void:
		var width := (size.x - 24) / 3.0
		for index in range(3):
			var id: String = ChapterEightBattlePanel.HUBS[index]
			var remaining := int(objective.get("hubs", {}).get(id, 0))
			var x := 8 + index * width
			var rect := Rect2(x, 6, width - 4, size.y - 12)
			var color := Color("62b89d") if remaining == 0 else Color("c1a06d")
			draw_rect(rect, color, false, 1)
			_text(Vector2(x + 6, 23 if small else 31), ChapterEightBattlePanel.HUB_NAMES[id])
			_text(Vector2(x + 6, 43 if small else 62), "已毁" if remaining == 0 else "结构 %d" % remaining, color)
			if str(objective.get("calibrated", "")) == id:
				_text(Vector2(x + 6, size.y - 9), "已校准", Color("ffd281"))
	func _draw_river() -> void:
		var value: Variant = objective.get("river_gaps", 0)
		var count: int = value.size() if value is Array or value is Dictionary else int(value)
		var y := size.y * 0.58
		var left := 28.0; var right := size.x - 115
		draw_line(Vector2(left, y), Vector2(right, y), Color("647a75"), 2)
		for index in range(3):
			var x := lerpf(left, right, float(index) / 2.0)
			draw_circle(Vector2(x, y), 5, Color("62b89d") if count > index else Color("c1a06d"))
			_text(Vector2(x - 15, y - 10), "%d/3" % (index + 1))
		_text(Vector2(size.x - 100, y + 5), "→ 床弩操作位")
		_text(Vector2(8, size.y - 5), "空隙进度示意；每两轮结算一次，三次后沿已验证路线退离。", Color("b8c2b8"))
	func _draw_batches() -> void:
		var batches: Array = objective.get("batches", [])
		if batches.is_empty():
			_text(Vector2(8, 25), "等待已验证的护送路径")
			return
		# Every point comes from the engine. Each row keeps its own four-neighbour
		# shape, including bends; labels identify batches without pretending NPCs
		# are HP-bearing actors or moving them to unverified coordinates.
		var row_height := (size.y - 8) / maxf(3, batches.size())
		for index in range(batches.size()):
			var batch: Dictionary = batches[index]
			var points: Array = batch.get("route", batch.get("path", []))
			var y := 4 + row_height * index
			_text(Vector2(7, y + row_height * 0.72), "%d %s" % [index + 1, ChapterEightBattlePanel.BATCH_NAMES[mini(index, 2)]])
			if points.is_empty(): continue
			var minimum := Vector2(INF, INF); var maximum := Vector2(-INF, -INF)
			for point in points:
				var p := _vector(point)
				minimum = minimum.min(p); maximum = maximum.max(p)
			var area := Rect2(115 if small else 155, y + 3, maxf(20, size.x - (220 if small else 300)), row_height - 6)
			for step in range(points.size()):
				var p := _map(_vector(points[step]), minimum, maximum, area)
				if step > 0: draw_line(_map(_vector(points[step - 1]), minimum, maximum, area), p, Color("647a75"), 2)
				draw_circle(p, 3, Color("b8c2b8"))
				if step == points.size() - 1: draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color("62b89d"), false, 2)
			var position: Variant = batch.get("position", points[0])
			var current := _map(_vector(position), minimum, maximum, area)
			draw_circle(current, 4, Color("62b89d") if batch.get("safe", false) else Color("ffd281"))
			var status := "已到安全口" if batch.get("safe", false) else ("已护/待卸" if batch.get("protected", false) else "待护送")
			_text(Vector2(size.x - (96 if small else 135), y + row_height * 0.72), status)
	func _vector(point: Variant) -> Vector2:
		if point is Array and point.size() >= 2: return Vector2(float(point[0]), float(point[1]))
		if point is Vector2 or point is Vector2i: return Vector2(point)
		return Vector2.ZERO
	func _map(point: Vector2, minimum: Vector2, maximum: Vector2, area: Rect2) -> Vector2:
		return area.position + Vector2((point.x - minimum.x) / maxf(1, maximum.x - minimum.x) * area.size.x, (point.y - minimum.y) / maxf(1, maximum.y - minimum.y) * area.size.y if maximum.y != minimum.y else area.size.y / 2)
