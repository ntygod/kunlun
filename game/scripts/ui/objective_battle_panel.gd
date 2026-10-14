class_name ObjectiveBattlePanel
extends VBoxContainer
## No mutable engine reference or success switch. Every button submits a replayable input.
signal input_submitted(action: Dictionary)
signal command_requested(actor: String, skill: String, target: String, revision: int)
signal resolve_requested
signal retry_requested
signal continue_requested
signal leave_requested
const SKILL_NAMES := {"normal_attack":"普通攻击", "self_guard":"自守回气", "sancai_counter":"三才归元掌", "mirror_counter":"镜心反制", "guard_ally":"援护同伴", "observe":"观势察机"}
const FAILURES := {"qin_hit_by_chain":"铁索击中了负伤的秦伯符", "liang_exhausted":"梁萧气竭", "time_expired":"错过脱困时机", "cover_blown":"假投诚已被识破", "wrong_antidote":"取错了药瓶", "antidote_wasted":"解药没有交给花清渊", "qingyuan_poison_worsened":"花清渊的毒伤恶化", "pursuers_caught_family":"追兵已赶上众人", "exchange_partner_incapacitated":"谈判对象失去行动能力，无法交换解药"}
const EVENT_NAMES := {"chain_resolved":"铁索行动已结算", "jiuru_counter_chain":"九如接索解围", "nonlethal_restraint":"已制住脱欢，未伤性命", "antidote_exchanged":"解药交换成立", "qingyuan_treated":"花清渊已服解药", "escort_moved":"护送队伍已转移"}
var view: Dictionary
func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	add_child(button)
func render(snapshot: Dictionary, skill_data: Dictionary, can_resolve: bool) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	view = snapshot.duplicate(true)
	_label("%s · 第%d轮" % [view.encounter.name, view.round])
	_label(view.objective.summary)
	for actor in view.actors:
		_label("%s 气血%d/%d%s" % [actor.get("name", actor.id), actor.hp, actor.max_hp, "（受保护伤者，不占指令槽）" if not actor.get("controllable", true) else ""])
	for intent in view.intents:
		if not intent.executed: _label("公开意图：" + intent.get("name", "戒备"))
	if view.outcome != "":
		if view.outcome == "victory":
			_label("目标已由实际行动达成；收招后继续剧情。")
			_button("继续剧情", func(): continue_requested.emit())
		else:
			_label("目标失败：%s。重试不发奖励。" % FAILURES.get(view.objective.failure, "脱困未能完成"))
			_button("从战前重试", func(): retry_requested.emit())
	else:
		for option in view.objective.available_actions:
			_button(option.label, _submit_input.bind(option.input.duplicate(true)))
		for actor in view.actors:
			if actor.team != "party" or not actor.get("controllable", true) or actor.defeated: continue
			for skill_id in actor.skills:
				if skill_id == "objective_action": continue
				var skill: Dictionary = skill_data[skill_id]
				var cost := int(view.skill_costs.get(actor.id, {}).get(skill_id, 0))
				if int(view.round) < int(actor.ready.get(skill_id, 1)) or int(actor.mp) < cost: continue
				for target in view.actors:
					if target.defeated: continue
					var legal: bool = (skill.target == "self" and target.id == actor.id) or (skill.target == "enemy" and target.team != actor.team) or (skill.target == "ally" and target.team == actor.team and target.id != actor.id)
					if legal: _button("武学：%s → %s（%d真气）" % [skill.get("name", SKILL_NAMES.get(skill_id,skill_id)), target.get("name", target.id), cost], _submit_command.bind(actor.id, skill_id, target.id, int(view.revision)))
		if not view.objective.pending.is_empty():
			var pending_label := "场景行动"
			for option in view.objective.available_actions:
				var action: Dictionary = option.input.duplicate(true)
				action.erase("revision")
				if action == view.objective.pending: pending_label = option.label
			_label("已编排：" + pending_label)
		elif view.commands.has("char_liang_xiao"): _label("已编排武学：" + SKILL_NAMES.get(view.commands.char_liang_xiao.skill_id, view.commands.char_liang_xiao.skill_id))
		var button := Button.new()
		button.text = "结算本回合"
		button.disabled = not can_resolve
		button.pressed.connect(func(): resolve_requested.emit())
		add_child(button)
	_button("返回菜单（保留战前进度）", func(): leave_requested.emit())
	for index in range(maxi(0, view.events.size() - 5), view.events.size()):
		var event: Dictionary = view.events[index]
		if event.type == "damage": _label("交锋：%s 承受%d气血损失" % [_actor_name(event.target), event.amount])
		elif event.type in ["chain_resolved", "jiuru_counter_chain", "nonlethal_restraint", "antidote_exchanged", "qingyuan_treated", "escort_moved"]: _label("目标记录：" + EVENT_NAMES.get(event.type,event.type))
func _submit_input(action: Dictionary) -> void:
	input_submitted.emit(action)
func _submit_command(actor: String, skill: String, target: String, revision: int) -> void:
	command_requested.emit(actor, skill, target, revision)

func _actor_name(id: String) -> String:
	for actor in view.actors:
		if actor.id == id: return actor.get("name",id)
	return id
