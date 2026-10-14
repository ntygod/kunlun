class_name ChapterSevenBattlePanel
extends "res://scripts/ui/objective_battle_panel.gd"
## Two permanent actor slots, including unavailable/defeated actors. All commands
## carry revisions; presentation cannot mutate the combat or fabricate receipts.
const HERO := "char_liang_xiao"
const AXUE := "char_axue"

var slots: Dictionary = {}
var details: PopupPanel
var details_text: Label
var details_scroll: ScrollContainer
var controls: Array[Control] = []
var skill_data_local: Dictionary
var selections: Dictionary = {}
var labels: Array[Label] = []
var intent_scroll: ScrollContainer
var intent_text: Label

func _ready() -> void:
	if not get_viewport().size_changed.is_connected(_metrics): get_viewport().size_changed.connect(_metrics)

func render(snapshot: Dictionary, skill_data: Dictionary, can_resolve: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	controls.clear(); labels.clear(); slots.clear()
	view = snapshot.duplicate(true)
	skill_data_local = view.get("skill_data",skill_data)
	if get_parent() != null: selections = get_parent().get_meta("ch07_selections",{}).duplicate(true)
	add_theme_constant_override("separation",2)
	line("%s · 第%d轮 · %s" % [view.encounter.name,view.round,{"":"编排双方行动","victory":"护撤完成","defeat":"脱困失败"}.get(view.outcome,view.outcome)])
	for id in _party_ids():
		var actor := _actor(id)
		var command: Dictionary = view.commands.get(id,{})
		var name: String = skill_data_local.get(command.get("skill_id",""),{}).get("name",SKILL_NAMES.get(command.get("skill_id",""),"未编排"))
		if id==HERO and not view.objective.pending.is_empty(): name += " / " + _action_name(view.objective.pending)
		line("%s %d/%d血 %d/%d气 · %s · %s%s" % [actor.name,actor.hp,actor.max_hp,actor.mp,actor.max_mp,"实际资源",name,"（不可操控）" if not actor.get("controllable",true) or actor.defeated else ""])
	var tells: Array[String] = []
	for intent in view.intents:
		var enemy := _actor(intent.actor_id)
		tells.append("%s %d血：%s" % [enemy.name,enemy.hp,intent.name])
	intent_scroll = ScrollContainer.new()
	intent_scroll.name = "public_intents"
	intent_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	intent_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	intent_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_scroll.focus_mode = Control.FOCUS_ALL
	intent_scroll.follow_focus = true
	intent_scroll.tooltip_text = "公开意图完整保留，可用滚轮或聚焦后方向键上下查看。"
	add_child(intent_scroll)
	slots["public_intents"] = intent_scroll
	intent_scroll.focus_entered.connect(_remember_focus.bind("public_intents"))
	intent_scroll.gui_input.connect(_scroll_intent_key)
	intent_text = Label.new()
	intent_text.name = "complete_intent_text"
	intent_text.text = "公开意图（可滚动）\n"+"\n".join(tells)
	intent_text.tooltip_text = intent_text.text
	intent_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intent_text.mouse_filter = Control.MOUSE_FILTER_PASS
	intent_scroll.add_child(intent_text)
	var o: Dictionary = view.objective
	if view.encounter.kind == "fire_ox":
		line("避险 %d/3 · 所在(%d,%d) · 首次失误%d/3" % [o.covered.size(),o.position[0],o.position[1],o.mistakes.size()])
		if int(o.hazard_index)<3:line("火牛向%s冲来，走至%s侧避险位后掩护。" % [["右","左","右"][int(o.hazard_index)],["左","右","左"][int(o.hazard_index)]])
	elif int(o.phase)==1:
		line("阶段一：靳飞%s · 阿雪%s · 海牙%s" % ["已压退" if o.jin_repelled else "需压至1400血", "已解绑" if o.snow_freed else "待解救", "已交接" if o.haiya_handed else "待交接"])
	else:
		line("阶段二 %d轮 · 已完成%d/至少5轮 · A:%d B:%d C:%d · 弩矢%d" % [o.phase_round,o.completed_rounds,o.supports.A,o.supports.B,o.supports.C,o.bolts])
		line("标识 A左斜梁 / B中横木 / C右绞盘 · 当前校准：%s" % (o.calibrated if o.calibrated!="" else "无"))
	if view.encounter.kind=="b04":line("新开交锋梁真气补满；转阶段不补，阿雪沿用原真气。")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	add_child(row)
	for id in _party_ids(): _actor_slot(row,id)
	var feedback := str(view.get("input_error",""))
	if feedback == "": feedback = "选择不提交；点击编排才生效，场景选项可取消。" if view.outcome == "" else ("资源按实保留；继续剧情。" if view.outcome == "victory" else "重试回当前阶段入口资源；不重复首段或获得额外恢复。")
	line(feedback)
	var footer := HBoxContainer.new()
	add_child(footer)
	button(footer,"resolve","结算回合",func(): resolve_requested.emit(),not can_resolve or view.outcome != "")
	button(footer,"retry","原资源重试",func(): retry_requested.emit(),view.outcome == "victory")
	button(footer,"continue","继续剧情",func(): continue_requested.emit(),view.outcome != "victory")
	button(footer,"details","规则/日志",show_details,false)
	button(footer,"leave","暂歇",func(): leave_requested.emit(),false)
	_build_details()
	_metrics()
	for control in controls: control.focus_entered.connect(_remember_focus.bind(str(control.name)))
	call_deferred("_restore_focus")

func _scroll_intent_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	match event.keycode:
		KEY_DOWN: intent_scroll.scroll_vertical += 20
		KEY_UP: intent_scroll.scroll_vertical -= 20
		KEY_PAGEDOWN: intent_scroll.scroll_vertical += int(intent_scroll.size.y)
		KEY_PAGEUP: intent_scroll.scroll_vertical -= int(intent_scroll.size.y)
		KEY_HOME: intent_scroll.scroll_vertical = 0
		KEY_END: intent_scroll.scroll_vertical = int(intent_scroll.get_v_scroll_bar().max_value)
		_: return
	intent_scroll.accept_event()

func _remember_focus(id: String) -> void:
	if get_parent() != null: get_parent().set_meta("ch07_focus",id)

func _restore_focus() -> void:
	if not is_inside_tree(): return
	var id := str(get_parent().get_meta("ch07_focus",HERO+"_skills")) if get_parent() != null else HERO+"_skills"
	var target: Control = slots.get(id,slots.get("details"))
	if target is Button and target.disabled: target = slots.get("details")
	if target != null: target.grab_focus()

func _actor(id: String) -> Dictionary:
	for actor in view.actors:
		if actor.id == id: return actor
	return {}

func line(text: String,count: int = 1) -> Label:
	var label := Label.new()
	label.text = text
	label.tooltip_text = text
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if count > 1 else TextServer.AUTOWRAP_OFF
	label.max_lines_visible = count
	label.set_meta("lines",count)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.append(label)
	add_child(label)
	return label

func button(parent: Node,id: String,text: String,callback: Callable,disabled: bool) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = disabled
	b.pressed.connect(callback)
	parent.add_child(b)
	slots[id] = b
	controls.append(b)
	return b

func _actor_slot(parent: HBoxContainer,id: String) -> void:
	var box := VBoxContainer.new()
	box.name = id+"_slot"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",2)
	parent.add_child(box)
	var actor := _actor(id)
	var skill := OptionButton.new()
	skill.name = id+"_skills"
	skill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill.fit_to_longest_item = false
	var skill_ids: Array = actor.skills.filter(func(s): return s not in ["objective_action","ch07_action"])
	for skill_id in skill_ids:
		var cost := int(view.skill_costs.get(id,{}).get(skill_id,0))
		var text: String = skill_data_local.get(skill_id,{}).get("name",SKILL_NAMES.get(skill_id,skill_id))
		var ready := maxi(0,int(actor.ready.get(skill_id,1))-int(view.round))
		skill.add_item("%s · %d气%s" % [text,cost," CD%d" % ready if ready>0 else ""])
		skill.set_item_metadata(skill.item_count-1,skill_id)
		var available := false
		for legal in view.legal_commands.get(id,[]):
			if legal.skill_id == skill_id: available = true
		skill.set_item_disabled(skill.item_count-1,not available or skill_id not in actor.skills or ready>0 or int(actor.mp)<cost or actor.defeated or not actor.get("controllable",true) or view.outcome != "")
	skill.select(clampi(int(selections.get(id+"_skill",0)),0,skill.item_count-1))
	box.add_child(skill);controls.append(skill);slots[id+"_skills"] = skill
	var target := OptionButton.new()
	target.name = id+"_targets"
	target.fit_to_longest_item = false
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for candidate in view.actors:
		target.add_item(candidate.name)
		target.set_item_metadata(target.item_count-1,candidate.id)
	target.select(clampi(int(selections.get(id+"_target",2)),0,target.item_count-1))
	box.add_child(target);controls.append(target);slots[id+"_targets"] = target
	var submit := button(box,id+"_command","编排"+actor.name+"行动",func(): command_requested.emit(id,skill.get_item_metadata(skill.selected),target.get_item_metadata(target.selected),int(view.revision)),true)
	var refresh := func():
		var selected_skill: String = str(skill.get_item_metadata(skill.selected))
		var kind: String = str(skill_data_local.get(selected_skill,{}).get("target",""))
		var valid_indices: Array[int] = []
		for index in range(target.item_count):
			var valid := false
			for command in view.legal_commands.get(id,[]):
				if command.skill_id == selected_skill and command.target_id == target.get_item_metadata(index): valid = true
			target.set_item_disabled(index,not valid)
			if valid: valid_indices.append(index)
		# This changes the visible unsubmitted selection only. No command signal
		# is emitted until the player presses the explicit compilation button.
		if kind == "self":
			for index in range(target.item_count):
				if target.get_item_metadata(index) == id: target.select(index)
		elif target.selected not in valid_indices:
			if kind == "enemy" and not valid_indices.is_empty(): target.select(valid_indices[0])
			elif kind == "ally" and valid_indices.size() == 1: target.select(valid_indices[0])
			elif kind == "ally": target.select(-1)
		submit.disabled = target.selected not in valid_indices or int(view.objective.get("input_budget",{}).get("command_remaining",1))<=0 or view.outcome != ""
		target.tooltip_text = "自身技能："+actor.name if kind == "self" else ("请选择合法同伴" if kind == "ally" else "选择敌方目标")
		save_selection(id+"_skill",skill.selected);save_selection(id+"_target",target.selected)
	skill.item_selected.connect(func(_index: int): refresh.call())
	target.item_selected.connect(func(_index: int): refresh.call())
	refresh.call()
	var action := OptionButton.new()
	action.name = id+"_actions"
	action.fit_to_longest_item = false
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inputs: Array = []
	for option in view.objective.available_actions:
		if option.input.actor_id == id:
			var input: Dictionary = option.input.duplicate(true)
			input.erase("revision")
			inputs.append(input)
	if inputs.is_empty(): inputs.append({"actor_id":id,"action_id":"cancel"})
	for input in inputs:
		action.add_item(_action_name(input))
		action.set_item_metadata(action.item_count-1,input)
		action.set_item_disabled(action.item_count-1,not _available(input))
	action.select(clampi(int(selections.get(id+"_action",0)),0,action.item_count-1))
	box.add_child(action);controls.append(action);slots[id+"_actions"] = action
	var submit_action := button(box,id+"_input","编排"+actor.name+"场景",func():
		var input: Dictionary = action.get_item_metadata(action.selected).duplicate(true)
		input["revision"] = int(view.revision)
		input_submitted.emit(input),not _available(action.get_item_metadata(action.selected)))
	action.item_selected.connect(func(index: int):
		save_selection(id+"_action",index)
		submit_action.disabled = not _available(action.get_item_metadata(index)))

func save_selection(key: String,value: int) -> void:
	selections[key] = value
	if get_parent() != null: get_parent().set_meta("ch07_selections",selections.duplicate(true))

func _pending_name(pending: Dictionary) -> String:
	var labels: Array[String]=[]
	for key in pending:
		labels.append(_action_name({"action_id":"carry" if key=="carry" else key,"value":pending[key]}) if key!="carry" else "搬筐")
	return "、".join(labels)

func _party_ids() -> Array:
	var ids: Array = []
	for actor in view.actors:
		if actor.team == "party": ids.append(actor.id)
	return ids

func _action_name(input: Dictionary) -> String:
	for option in view.objective.available_actions:
		var clean: Dictionary=option.input.duplicate(true)
		clean.erase("revision")
		if clean==input:return option.label
	var names := {"cancel":"取消编排","free_axue":"解开阿雪拘束","handoff_haiya":"开锁并交接海牙","cover":"掩护友军","move":"移步","calibrate":"校准弩机","fire":"射断承重点"}
	return names.get(input.get("action_id",""),"场景行动")

func _available(action: Dictionary) -> bool:
	if view.outcome != "" or int(view.objective.get("input_budget",{}).get("command_remaining",1)) <= 0: return false
	for option in view.objective.available_actions:
		var input: Dictionary = option.input.duplicate(true)
		input.erase("revision")
		if input == action: return true
	return false

func _metrics() -> void:
	var small := get_viewport_rect().size.y <= 440
	if is_instance_valid(intent_scroll): intent_scroll.custom_minimum_size.y = 32 if small else 50
	if is_instance_valid(intent_text): intent_text.add_theme_font_size_override("font_size",12 if small else 18)
	for label in labels:
		label.add_theme_font_size_override("font_size",12 if small else 18)
		label.custom_minimum_size.y = (16 if small else 25)*int(label.get_meta("lines",1))
	for control in controls:
		control.add_theme_font_size_override("font_size",12 if small else 17)
		control.custom_minimum_size.y = 23 if small else 32
		for key in ["normal","hover","pressed","disabled","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("18272c") if key == "disabled" else Color("294049")
			style.border_color = Color("d7c191") if key == "focus" else Color("647a75")
			style.set_border_width_all(1)
			style.content_margin_top = 1;style.content_margin_bottom = 1
			style.content_margin_left = 4;style.content_margin_right = 4
			control.add_theme_stylebox_override(key,style)

func _build_details() -> void:
	details = PopupPanel.new()
	details.name = "ch07_rules_log"
	details.transient = true; details.exclusive = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c23")
	style.draw_center = true
	style.content_margin_left = 12;style.content_margin_right = 12
	style.content_margin_top = 8;style.content_margin_bottom = 8
	details.add_theme_stylebox_override("panel",style)
	add_child(details)
	var column := VBoxContainer.new();details.add_child(column)
	details_scroll = ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(details_scroll)
	details_text = Label.new()
	details_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_text.text = view.objective.summary+"\n\n当前格/完整规则与最近战斗日志："
	for event in view.events.slice(maxi(0,view.events.size()-40)):
		details_text.text += "\n%d轮 %s %s→%s %d %s" % [event.round,event.type,_actor_name(event.source),_actor_name(event.target),event.amount,str(event.detail)]
	details_scroll.add_child(details_text)
	var close := Button.new();close.text = "返回交锋（Esc）"
	var key := InputEventKey.new();key.keycode = KEY_ESCAPE
	var shortcut := Shortcut.new();shortcut.events = [key];close.shortcut = shortcut
	close.pressed.connect(func(): details.hide(); _restore_focus())
	details.popup_hide.connect(_restore_focus)
	column.add_child(close)

func show_details() -> void:
	var size := get_viewport_rect().size
	details_scroll.custom_minimum_size = Vector2(minf(750,size.x-100),minf(330,size.y-130))
	details.popup_centered(Vector2i(mini(800,int(size.x)-60),mini(460,int(size.y)-60)))
