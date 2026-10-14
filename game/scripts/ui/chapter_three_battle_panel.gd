class_name ChapterThreeBattlePanel
extends "res://scripts/ui/objective_battle_panel.gd"
## Fixed read-only B01 controls. The parent owns the modal lifecycle; this panel
## owns its detail popup. No world/input/replay semantics live in this presentation.
const HERO := "char_liang_xiao"
const BOSS := "char_ming_sanqiu"
const POSITION_NAMES := {"left":"西", "center":"中", "right":"东"}
const POSITIONS := ["left","center","right"]
var last_focus_slot := "observe"
var slots: Dictionary = {}
var status_labels: Array[Label] = []
var action_grid: GridContainer
var footer_grid: GridContainer
var details: PopupPanel
var details_scroll: ScrollContainer
var details_text: Label
var pending_label: Label
var _can_resolve := false
var _skill_data: Dictionary = {}

func _ready() -> void:
	# The modal content node survives panel replacement. Store only a string there,
	# avoiding GDScript static storage retaining dynamic script dependencies.
	if get_parent() != null: last_focus_slot = str(get_parent().get_meta("b01_focus_slot","observe"))
	if not get_viewport().size_changed.is_connected(_refresh_metrics):
		get_viewport().size_changed.connect(_refresh_metrics)

func render(snapshot: Dictionary, skill_data: Dictionary, can_resolve: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	slots.clear()
	status_labels.clear()
	view = snapshot.duplicate(true)
	_skill_data = skill_data.duplicate(true)
	_can_resolve = can_resolve
	add_theme_constant_override("separation",1)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var o: Dictionary = view.objective
	var hero := _actor(HERO)
	var boss := _actor(BOSS)
	var intent: Dictionary = view.intents[0]
	_fixed_label("灵台论剑 · 第%d轮 · 阶段%d/2 · 机关%d/3" % [view.round,o.phase,o.interrupt_count],"heading")
	_fixed_label("梁萧 %d/%d气血  %d/%d真气  ｜ 明三秋 %d/%d  盾%d" % [hero.hp,hero.max_hp,hero.mp,hero.max_mp,boss.hp,boss.max_hp,boss.get("shield",0)],"vitals")
	var tells := {"charge":"蓄力：本轮不出剑；先观势，下轮借力打断或自守。", "release":"释放：1.80倍刺击；借力须当次观势、把手与环位正确。", "thrust":"快刺：速度+10、1.35倍；三才掌可诱偏，韧性期例外。", "shield":"结盾：本阶段最大气血20%护盾，护盾存在时反震20%。", "recovery":"缓息：明三秋抚胸调息，本轮不出剑；可抢攻或回气。"}
	var protection := "韧性保护中" if int(boss.protected_through) >= int(view.round) or int(boss.last_break) == int(view.round) else "可破招"
	_fixed_label("公开意图 · " + tells.get(intent.beat,intent.get("name","")) + "\n" + protection + "；气血到340转场，P2满850，溢伤不带入。", "intent",2)
	_fixed_label("位置%s → 目标%s  ｜ 环针%s → 刻口%s  ｜ 当次%s" % [POSITION_NAMES[o.position],POSITION_NAMES[o.required_handle],POSITION_NAMES[POSITIONS[int(o.pointer)]],POSITION_NAMES[POSITIONS[int(o.required_pointer)]],"已观势" if o.observed_intent == intent.intent_id else "未观势"],"mechanism")
	var feedback := {"release_window_closed":"机关：不在释放前窗口。", "current_charge_not_observed":"机关：尚未观察这一次蓄力。", "wrong_handle":"机关：请先移动到目标把手。", "ring_not_aligned":"机关：环针尚未对准刻口。", "already_interrupted":"机关：这次意图已经计数。", "tenacity_protection":"机关：本轮受韧性保护。", "armillary_interrupted":"机关：打断成功，内伤反噬已结算。"}
	var hint: String = feedback.get(o.last_feedback,"移动/转环只编排；借力占本轮行动，速度+30、0真气。")
	if o.phase == 2: hint = "P2已开始，梁萧状态与机关计数继承。 " + feedback.get(o.last_feedback,"")
	if view.outcome == "victory": hint = "明三秋非致命失战。可继续剧情。"
	elif view.outcome == "defeat": hint = "梁萧无力再战。可从本阶段真实开场重试，不发奖励。"
	var budget: Dictionary = o.get("input_budget",{})
	if int(budget.get("spatial_remaining",1)) == 0 or int(budget.get("command_remaining",1)) == 0:
		hint = "本轮编辑额度已尽；可结算已编排行动，下轮恢复额度。"
	if str(view.get("input_error","")) != "": hint = str(view.input_error)
	_fixed_label(hint,"feedback")
	action_grid = _grid()
	for position in POSITIONS:
		var action := {"action_id":"move_handle","destination":position,"revision":int(view.revision)}
		_slot(action_grid,"move_"+position,"到"+POSITION_NAMES[position]+"把手",_input_pressed.bind("move_"+position,action),not _input_available(action))
	for direction in ["left","right"]:
		var action := {"action_id":"rotate_ring","direction":direction,"revision":int(view.revision)}
		_slot(action_grid,"ring_"+direction,"环针"+("←" if direction == "left" else "→")+"一格",_input_pressed.bind("ring_"+direction,action),not _input_available(action))
	var release := {"action_id":"armillary_release","intent_id":intent.intent_id,"revision":int(view.revision)}
	_slot(action_grid,"release","借力释放",_input_pressed.bind("release",release),not _input_available(release))
	_skill_slot("observe", "观势察机", hero, boss)
	_skill_slot("sancai_counter", "三才归元掌", hero, boss)
	_skill_slot("self_guard", "自守回气", hero, hero)
	_skill_slot("normal_attack", "普通攻击", hero, boss)
	_slot(action_grid,"details","规则 / 日志",_show_details,false)
	_slot(action_grid,"leave","返回菜单",func(): leave_requested.emit(),false)
	var pending := "未选择"
	if not o.pending.is_empty(): pending = "浑天仪借力" if o.pending.action_id == "armillary_release" else "等待"
	elif view.commands.has(HERO): pending = SKILL_NAMES.get(view.commands[HERO].skill_id,view.commands[HERO].skill_id)
	var save_hint := " ｜ 结算/暂歇自动存 · F5存/F9读" if str(view.get("save_policy","")) != "" else ""
	pending_label = _fixed_label("编排："+pending+save_hint,"pending")
	if save_hint != "": pending_label.tooltip_text += "\n"+str(view.save_policy)
	footer_grid = _grid()
	_slot(footer_grid,"resolve","结算本回合",func(): resolve_requested.emit(),not can_resolve or view.outcome != "")
	_slot(footer_grid,"retry","本阶段重试",func(): retry_requested.emit(),view.outcome != "defeat")
	_slot(footer_grid,"continue","继续剧情",func(): continue_requested.emit(),view.outcome != "victory")
	_build_details()
	_refresh_metrics()
	call_deferred("_restore_focus")

func _actor(id: String) -> Dictionary:
	for actor in view.actors:
		if actor.id == id: return actor
	return {}

func _fixed_label(text: String, id: String, lines: int = 1) -> Label:
	var label := Label.new()
	label.name = id
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if lines > 1 else TextServer.AUTOWRAP_OFF
	label.max_lines_visible = lines
	label.set_meta("reserved_lines",lines)
	label.tooltip_text = text
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_labels.append(label)
	add_child(label)
	return label

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",4)
	grid.add_theme_constant_override("v_separation",2)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	return grid

func _slot(parent: GridContainer, id: String, text: String, action: Callable, disabled: bool) -> void:
	var button := Button.new()
	button.name = id
	button.text = text
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(_remember_focus.bind(id))
	button.pressed.connect(action)
	parent.add_child(button)
	slots[id] = button

func _input_available(action: Dictionary) -> bool:
	if view.outcome != "": return false
	var clean := action.duplicate(true)
	clean.erase("revision")
	for option in view.objective.available_actions:
		var input: Dictionary = option.input.duplicate(true)
		input.erase("revision")
		if input == clean: return true
	return false

func _skill_slot(skill_id: String, label: String, actor: Dictionary, target: Dictionary) -> void:
	var cost := int(view.skill_costs.get(HERO,{}).get(skill_id,0))
	var blocked: bool = view.outcome != "" or skill_id not in actor.skills or actor.defeated or target.defeated
	blocked = blocked or int(view.round) < int(actor.ready.get(skill_id,1)) or int(actor.mp) < cost
	blocked = blocked or int(view.objective.get("input_budget",{}).get("command_remaining",1)) == 0
	var caption := label + (" · %d气" % cost if cost > 0 else "")
	_slot(action_grid,skill_id,caption,_command_pressed.bind(skill_id,target.id),blocked)
	var button: Button = slots[skill_id]
	button.tooltip_text = "%s：%d真气。%s" % [label,cost,"冷却中" if int(view.round)<int(actor.ready.get(skill_id,1)) else ("真气不足" if int(actor.mp)<cost else "编排本轮行动，按结算执行")]

func _input_pressed(slot: String, action: Dictionary) -> void:
	_remember_focus(slot)
	input_submitted.emit(action.duplicate(true))

func _command_pressed(skill: String, target: String) -> void:
	_remember_focus(skill)
	command_requested.emit(HERO,skill,target,int(view.revision))

func _remember_focus(slot: String) -> void:
	last_focus_slot = slot
	if get_parent() != null: get_parent().set_meta("b01_focus_slot",slot)

func _restore_focus() -> void:
	if not is_inside_tree(): return
	var target: Button = slots.get(last_focus_slot,slots.get("observe"))
	if target == null or target.disabled: target = slots.get("resolve")
	if target == null or target.disabled:
		for slot in slots.values():
			if not slot.disabled:
				target = slot
				break
	if target != null: target.grab_focus()

func _refresh_metrics() -> void:
	if slots.is_empty() or not is_inside_tree(): return
	var compact := get_viewport_rect().size.y <= 440
	var font_size := 13 if compact else 18
	var line_height := 18 if compact else 27
	for label in status_labels:
		label.add_theme_font_size_override("font_size",font_size)
		label.add_theme_constant_override("line_spacing",0)
		label.custom_minimum_size.y = line_height * int(label.get_meta("reserved_lines",1))
	for button in slots.values():
		button.add_theme_font_size_override("font_size",font_size)
		button.custom_minimum_size.y = 23 if compact else 34
		for style_name in ["normal","hover","pressed","disabled","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("22353b") if style_name != "disabled" else Color("17242a")
			style.border_color = Color("ccb879") if style_name in ["focus","hover"] else Color("637365")
			style.set_border_width_all(1)
			style.content_margin_left = 4
			style.content_margin_right = 4
			style.content_margin_top = 1
			style.content_margin_bottom = 1
			button.add_theme_stylebox_override(style_name,style)
	if details_text != null: details_text.add_theme_font_size_override("font_size",font_size)

func _build_details() -> void:
	details = PopupPanel.new()
	details.name = "battle_details"
	details.transient = true
	details.exclusive = true
	# PopupPanel does not inherit the host's PanelContainer style. Explicitly
	# paint its center opaque so battle controls never bleed through the text.
	var background := StyleBoxFlat.new()
	background.bg_color = Color("101c23")
	background.draw_center = true
	background.border_color = Color("8e8664")
	background.set_border_width_all(1)
	background.content_margin_left = 12
	background.content_margin_right = 12
	background.content_margin_top = 8
	background.content_margin_bottom = 8
	details.add_theme_stylebox_override("panel",background)
	add_child(details)
	var column := VBoxContainer.new()
	details.add_child(column)
	details_scroll = ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.follow_focus = true
	details_scroll.focus_mode = Control.FOCUS_ALL
	column.add_child(details_scroll)
	details_text = Label.new()
	details_text.add_theme_color_override("font_color",Color("e0ded0"))
	details_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text: String = view.objective.summary
	if str(view.get("save_policy","")) != "": text = "保存："+str(view.save_policy)+"\n\n"+text
	if str(view.get("input_error","")) != "": text = str(view.input_error)+"\n\n"+text
	if view.objective.three_insights: text += "\n三识：观其气门，辨其来势，借浑天仪。三才掌仍是准备诱导，不是蓄力打断。"
	text += "\n\n最近交锋记录："
	for index in range(maxi(0,view.events.size()-30),view.events.size()):
		var event: Dictionary = view.events[index]
		if event.type == "damage": text += "\n第%d轮 %s损失%d气血" % [event.round,_actor_name(event.target),event.amount]
		elif event.type == "phase_transition": text += "\n"+str(event.detail.message)
		elif event.type == "armillary_interrupted": text += "\n第%d轮 浑天仪打断成功" % event.round
		elif event.type == "induced_miss": text += "\n第%d轮 三才掌诱偏来剑" % event.round
	details_text.text = text
	details_scroll.add_child(details_text)
	var close := Button.new()
	close.text = "返回交锋（Esc）"
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	var shortcut := Shortcut.new()
	shortcut.events = [escape]
	close.shortcut = shortcut
	close.pressed.connect(func(): details.hide(); _restore_focus())
	column.add_child(close)
	details.popup_hide.connect(_restore_focus)

func _show_details() -> void:
	_remember_focus("details")
	var viewport_size := get_viewport_rect().size
	details_scroll.custom_minimum_size = Vector2(minf(700,viewport_size.x-100),minf(320,viewport_size.y-140))
	details.popup_centered(Vector2i(mini(780,int(viewport_size.x)-60),mini(450,int(viewport_size.y)-60)))
	details_scroll.grab_focus()
