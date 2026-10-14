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
	for child in get_children():
		remove_child(child)
		child.queue_free()
	view = snapshot.duplicate(true)
	skills = skill_data
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
	if not selected_skill in actor.skills: selected_skill = actor.skills[0]
	_label("为 %s 选择武学" % actor.get("name",actor.id))
	for skill_id in actor.skills:
		var ready := int(view.round) >= int(actor.ready.get(skill_id,1))
		var cost := int(view.get("skill_costs",{}).get(actor.id,{}).get(skill_id,0))
		var enough := int(actor.mp) >= cost
		var marker := "已选 · " if selected_skill == skill_id else ""
		var button := _button(marker+NAMES.get(skill_id,skill_id)+" · 真气 %d" % cost+("（冷却）" if not ready else ("（真气不足）" if not enough else "")),_select_skill.bind(skill_id))
		button.disabled = not ready or not enough
	target_menu = OptionButton.new()
	add_child(target_menu)
	_refresh_targets(actor)
	var submit := _button("编排此行动",_submit.bind(str(actor.id)))
	submit.disabled = int(view.round) < int(actor.ready.get(selected_skill,1)) or int(actor.mp) < int(view.get("skill_costs",{}).get(actor.id,{}).get(selected_skill,0)) or target_menu.item_count == 0
	if view.commands.has(actor.id):
		var command: Dictionary = view.commands[actor.id]
		_label("已编排：%s → %s" % [NAMES.get(command.skill_id,command.skill_id),_unit(command.target_id).get("name",command.target_id)])
	var resolve := _button("结算本回合",func(): resolve_requested.emit())
	resolve.disabled = not can_resolve
	_button("返回菜单（保留战前进度）",func(): leave_requested.emit())
	_render_log()
func _select_skill(id: String) -> void:
	selected_skill = id
	# Redraw changes local selection only, never game state.
	render(view,skills,last_can_resolve)
func _unit(id: String) -> Dictionary:
	for actor in view.actors:
		if actor.id == id: return actor
	return {}
func _refresh_targets(actor: Dictionary) -> void:
	var target_kind: String = skills.get(selected_skill,{}).get("target","enemy")
	for unit in view.actors:
		if unit.defeated: continue
		var allowed: bool = (unit.team != actor.team) if target_kind == "enemy" else ((unit.team == actor.team) if target_kind == "ally" else (unit.id == actor.id))
		if not allowed: continue
		target_menu.add_item(unit.get("name",unit.id))
		target_menu.set_item_metadata(target_menu.item_count-1,unit.id)
		if unit.id == selected_target: target_menu.select(target_menu.item_count-1)
func _submit(actor: String) -> void:
	if target_menu.item_count == 0: return
	selected_target = str(target_menu.get_item_metadata(target_menu.selected))
	command_requested.emit(actor,selected_skill,selected_target,int(view.revision))
func _render_log() -> void:
	_label("最近交锋")
	var events: Array = view.events
	for i in range(maxi(0,events.size()-10),events.size()):
		var event: Dictionary = events[i]
		if event.type == "damage": _label("%s → %s：%d 气血" % [_unit(event.source).get("name",event.source),_unit(event.target).get("name",event.target),event.amount])
		elif event.type in ["break","induced","counter"]: _label("观势拆招："+event.type)
