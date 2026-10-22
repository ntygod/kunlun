class_name BattlePanel
extends VBoxContainer
## Read-only combat view. Commands are intents sent to the owning session.
signal command_requested(actor: String, skill: String, target: String, revision: int)
signal resolve_requested
signal retry_requested
signal leave_requested
signal continue_requested
var view: Dictionary
var selected_actor := ""
var last_can_resolve := false
var selected_skill := "normal_attack"
var selected_target := ""
var target_menu: OptionButton
# Presentation-only preferences, never added to the combat snapshot or save data.
var target_preferences: Dictionary = {}
var target_context := ""
var skills: Dictionary
const NAMES := {"normal_attack":"普通攻击","self_guard":"自守回气","sancai_counter":"三才归元掌","mirror_counter":"三才归元·镜心","guard_ally":"援护同伴"}
func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	add_child(button)
	return button
func render(snapshot: Dictionary, skill_data: Dictionary, can_resolve: bool) -> void:
	_remember_target()
	target_menu = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	view = snapshot.duplicate(true)
	skills = skill_data.duplicate(true)
	last_can_resolve = can_resolve
	var actor: Dictionary = {}
	for unit in view.actors:
		if unit.team == "party" and not unit.defeated:
			if actor.is_empty() or unit.id == selected_actor: actor = unit
	if not actor.is_empty(): selected_actor = actor.id
	_label("第 %d 回合 · 每位可行动角色先编排，再统一结算" % int(view.round))
	for unit in view.actors:
		_label("%s  气血 %d/%d  真气 %d/%d%s" % [unit.get("name",unit.id),unit.hp,unit.max_hp,unit.mp,unit.max_mp," · 气竭" if unit.defeated else ""])
	for intent in view.intents:
		if intent.get("executed",false): continue
		var enemy := _unit(intent.actor_id)
		var protected := int(enemy.get("protected_through",-1)) >= int(view.round)
		_label("意图：%s → %s · %s%s" % [enemy.get("name",intent.actor_id),_unit(intent.target_id).get("name",intent.target_id),intent.get("name","出手"),"（可诱导）" if "induce" in intent.get("tags",[]) and not protected else "（保护期/不可诱偏）"])
	if view.outcome != "":
		_label("这一战已结束。" if view.outcome == "victory" else "梁萧气竭。重试回到战前，不丢物品，不发经验。")
		if view.outcome == "victory": _button("收招，继续剧情",func(): continue_requested.emit())
		else: _button("从战前重试",func(): retry_requested.emit())
		_button("返回菜单",func(): leave_requested.emit())
		_render_log()
		return
	if actor.is_empty(): return
	var actor_menu := OptionButton.new()
	add_child(actor_menu)
	for unit in view.actors:
		if unit.team != "party" or unit.defeated: continue
		actor_menu.add_item(unit.get("name",unit.id))
		actor_menu.set_item_metadata(actor_menu.item_count-1,unit.id)
		if unit.id == actor.id: actor_menu.select(actor_menu.item_count-1)
	actor_menu.item_selected.connect(func(index: int):
		selected_actor = actor_menu.get_item_metadata(index)
		selected_skill = "normal_attack"
		render(view,skills,last_can_resolve))
	if actor.skills.is_empty():
		_label("当前没有可用武学。")
		_button("返回菜单（保留战前进度）",func(): leave_requested.emit())
		return
	if not selected_skill in actor.skills: selected_skill = actor.skills[0]
	_label("为 %s 选择武学" % actor.get("name",actor.id))
	for skill_id in actor.skills:
		var ready := int(view.round) >= int(actor.ready.get(skill_id,1))
		var cost := int(view.get("skill_costs",{}).get(actor.id,{}).get(skill_id,0))
		var enough := int(actor.mp) >= cost
		var marker := "已选 · " if selected_skill == skill_id else ""
		var button := _button(marker+_skill_name(skill_id)+" · 真气 %d" % cost+("（冷却）" if not ready else ("（真气不足）" if not enough else "")),_select_skill.bind(skill_id))
		button.disabled = not ready or not enough
		button.set_meta("skill_id",skill_id)
	target_menu = OptionButton.new()
	add_child(target_menu)
	_refresh_targets(actor)
	target_menu.item_selected.connect(_target_selected.bind(target_menu))
	var submit := _button("编排此行动",_submit.bind(str(actor.id)))
	submit.disabled = int(view.round) < int(actor.ready.get(selected_skill,1)) or int(actor.mp) < int(view.get("skill_costs",{}).get(actor.id,{}).get(selected_skill,0)) or target_menu.item_count == 0
	if view.commands.has(actor.id):
		var command: Dictionary = view.commands[actor.id]
		_label("已编排：%s → %s" % [_skill_name(command.skill_id),_unit(command.target_id).get("name",command.target_id)])
	var resolve := _button("结算本回合",func(): resolve_requested.emit())
	resolve.disabled = not can_resolve
	_button("返回菜单（保留战前进度）",func(): leave_requested.emit())
	_render_log()
func _skill_name(id: String) -> String:
	var display_name := str(skills.get(id,{}).get("name","")).strip_edges()
	return display_name if not display_name.is_empty() else str(NAMES.get(id,id))
func _select_skill(id: String) -> void:
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var restore_focus := focused != null and is_ancestor_of(focused)
	selected_skill = id
	# Redraw changes local selection only, never game state.
	render(view,skills,last_can_resolve)
	if restore_focus:
		for child in get_children():
			if child is Button and child.get_meta("skill_id","") == selected_skill and not child.disabled:
				child.grab_focus()
				break
func _remember_target() -> void:
	if not is_instance_valid(target_menu): return
	var index := target_menu.selected
	if index < 0 or index >= target_menu.item_count: return
	selected_target = str(target_menu.get_item_metadata(index))
	if not target_context.is_empty(): target_preferences[target_context] = selected_target
func _target_selected(index: int, menu: OptionButton) -> void:
	# A removed menu can survive until queue_free; ignore its stale signals.
	if menu != target_menu or index < 0 or index >= menu.item_count: return
	selected_target = str(menu.get_item_metadata(index))
	target_preferences[target_context] = selected_target
func _unit(id: String) -> Dictionary:
	for actor in view.actors:
		if actor.id == id: return actor
	return {}
func _refresh_targets(actor: Dictionary) -> void:
	var target_kind: String = skills.get(selected_skill,{}).get("target","enemy")
	target_context = str(actor.id)+":"+target_kind
	var preferred: String = target_preferences.get(target_context,selected_target)
	for unit in view.actors:
		if unit.defeated: continue
		var allowed := false
		match target_kind:
			"enemy": allowed = unit.team != actor.team
			"ally": allowed = unit.team == actor.team and unit.id != actor.id
			"self": allowed = unit.id == actor.id
		if not allowed: continue
		target_menu.add_item(unit.get("name",unit.id))
		target_menu.set_item_metadata(target_menu.item_count-1,unit.id)
		if unit.id == preferred: target_menu.select(target_menu.item_count-1)
	_remember_target()
func _submit(actor: String) -> void:
	if view.get("outcome","") != "" or actor != selected_actor: return
	if not is_instance_valid(target_menu): return
	if target_menu.selected < 0 or target_menu.selected >= target_menu.item_count: return
	var unit := _unit(actor)
	if unit.is_empty() or unit.get("defeated",false): return
	if not selected_skill in unit.get("skills",[]): return
	if int(view.round) < int(unit.get("ready",{}).get(selected_skill,1)): return
	if int(unit.mp) < int(view.get("skill_costs",{}).get(actor,{}).get(selected_skill,0)): return
	_remember_target()
	command_requested.emit(actor,selected_skill,selected_target,int(view.revision))
func _render_log() -> void:
	_label("最近交锋")
	var events: Array = view.events
	for i in range(maxi(0,events.size()-10),events.size()):
		var event: Dictionary = events[i]
		if event.type == "damage": _label("%s → %s：%d 气血" % [_unit(event.source).get("name",event.source),_unit(event.target).get("name",event.target),event.amount])
		elif event.type in ["break","induced","counter"]:
			var event_names := {"break":"破招","induced":"诱导成功","counter":"反击"}
			_label("观势拆招："+event_names[event.type])
