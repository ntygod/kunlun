class_name ChapterThreeCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## B01 augments the existing queue/skills/defense kernel. No separate combat clock.
const HERO := "char_liang_xiao"
const BOSS := "char_ming_sanqiu"
const POSITIONS := ["left", "center", "right"]
const POSITION_NAMES := {"left":"西把手", "center":"中央把手", "right":"东把手"}

func _init(rule_data: Dictionary, runtime_data: Dictionary) -> void:
	super(rule_data, runtime_data)
	content.skills.objective_action = {"name":"浑天仪借力", "kind":"objective", "target":"self", "hits":[], "speed":30, "mp_floor":0, "cooldown":0}

func start(encounter: Dictionary, party: Array) -> void:
	content.skills.objective_action.speed = int(encounter.mechanism_speed)
	super.start(encounter, party)
	# Encounter entry respects the trusted campaign's present MP as well as HP.
	for source in party:
		if source.has("mp"): actor_by_id(source.id).mp = clampi(int(source.mp), 0, int(source.max_mp))
	checkpoint = snapshot()

func begin_round() -> void:
	if not state.has("objective"):
		state.objective = {"kind":"b01_armillary", "phase":1, "phase_start_round":1,
			"shield_uses":0, "transition_pending":false, "transition_round":0, "pending":{}, "position":"center", "pointer":0,
			"charge_serial":0, "required_pointer":0, "required_handle":"left", "observed_intent":"", "charge_id":"",
			"interrupt_ids":[], "interrupt_count":0, "three_insights":false, "failure":"", "victory_route":"", "last_feedback":""}
	super.begin_round()
	if state.mode != "commands": return
	var o: Dictionary = state.objective
	o.pending = {}
	var schedule: Array = state.encounter.intent_schedule
	var beat: String = schedule[(int(state.round) - int(o.phase_start_round)) % schedule.size()]
	if beat == "shield" and int(o.shield_uses) >= int(state.encounter.shield_uses_per_phase): beat = "recovery"
	var intent: Dictionary = state.intents[0]
	intent["beat"] = beat
	intent["hits"] = []
	intent["tags"] = []
	intent["speed"] = 0
	if beat == "charge":
		o.charge_id = "b01:p%d:r%d" % [o.phase, state.round]
		o.observed_intent = ""
		o.required_pointer = int(o.charge_serial) % 3
		o.charge_serial += 1
		o.required_handle = POSITIONS[int(o.required_pointer)]
	intent.intent_id = o.charge_id if beat in ["charge", "release"] else "b01:p%d:r%d" % [o.phase,state.round]
	match beat:
		"charge":
			intent.name = "璇玑引星剑 · 本轮蓄力，下一轮1.80倍刺击；先观势，再到%s将铜环指针对准%s刻口" % [POSITION_NAMES[o.required_handle], POSITION_NAMES[POSITIONS[int(o.required_pointer)]]]
		"release":
			intent.name = "璇玑引星剑 · 即将释放1.80倍刺击；只有此意图的观势记录与正确机关对位可打断"
			intent.hits = [1.8]
			intent.tags = ["interrupt"]
		"thrust":
			intent.name = "天玑绝命刺 · 速度+10，1.35倍攻击；宜用三才归元掌准备虚实诱导"
			intent.hits = [1.35]
			intent.speed = 10
			intent.tags = ["induce"]
		"shield":
			intent.name = "浑天星罗盾 · 获得阶段最大气血20%护盾，护盾存续时反震20%来伤"
			intent.tags = ["insight"]
		"recovery":
			intent.name = "旧伤气机停顿 · 明三秋抚胸缓息，本轮不出剑，可抢攻或自守回气（星罗盾每阶段只结一次）"
	if int(o.interrupt_count) >= 2 or int(o.phase) == 2: o.three_insights = true

func input_error(action: Dictionary) -> String:
	if state.mode != "commands" or state.outcome != "": return "not_accepting_input"
	if not action.get("action_id") is String: return "invalid_action"
	var fields := {"move_handle":["destination"], "rotate_ring":["direction"], "armillary_release":["intent_id"], "wait":[]}
	if not fields.has(action.action_id): return "invalid_action"
	for key in action:
		if key not in ["action_id", "revision"] and key not in fields[action.action_id]: return "unexpected_input_field"
	for key in fields[action.action_id]:
		if not action.has(key): return "missing_input_field"
	if action.has("revision") and (not _whole(action.revision) or int(action.revision) != int(state.revision)): return "stale_revision"
	match action.action_id:
		"move_handle":
			if action.destination not in POSITIONS: return "invalid_handle"
			if absi(POSITIONS.find(action.destination) - POSITIONS.find(state.objective.position)) != 1: return "not_adjacent"
		"rotate_ring":
			if not action.direction is String or action.direction not in ["left", "right"]: return "invalid_rotation"
		"armillary_release":
			if not action.intent_id is String: return "invalid_intent"
	return ""

func apply_input(action: Dictionary) -> Dictionary:
	var error := input_error(action)
	if error != "": return {"accepted":false, "error":error}
	var o: Dictionary = state.objective
	var normalized := action.duplicate(true)
	normalized.erase("revision")
	match action.action_id:
		"move_handle":
			o.position = action.destination
			_event("handle_moved", HERO, "", 0, normalized)
			state.revision += 1
		"rotate_ring":
			o.pointer = posmod(int(o.pointer) + (-1 if action.direction == "left" else 1), 3)
			_event("ring_rotated", HERO, "", int(o.pointer), normalized)
			state.revision += 1
		_:
			var previous: Dictionary = o.pending
			o.pending = normalized
			error = set_command(HERO, "objective_action", HERO)
			if error != "":
				o.pending = previous
				return {"accepted":false,"error":error}
			if previous != normalized and not previous.is_empty(): state.revision += 1
	return {"accepted":true,"error":""}

func validate_command(actor_id: String, skill_id: String, target_id: String) -> String:
	var error := super.validate_command(actor_id, skill_id, target_id)
	if error != "": return error
	if skill_id == "objective_action" and state.objective.pending.is_empty(): return "objective_input_required"
	return ""

func _execute_command(actor: Dictionary, command: Dictionary) -> void:
	if command.skill_id != "objective_action":
		super._execute_command(actor, command)
		if command.skill_id == "observe" and command.target_id == BOSS:
			var intent: Dictionary = state.intents[0]
			if intent.beat == "charge" and not state.objective.transition_pending:
				state.objective.observed_intent = intent.intent_id
				_event("charge_observed", actor.id, BOSS, 0, {"intent_id":intent.intent_id})
		return
	_pay(actor, "objective_action", content.skills.objective_action)
	var o: Dictionary = state.objective
	var input: Dictionary = o.pending
	_event("objective_input", actor.id, BOSS, 0, input)
	if input.action_id == "wait": return
	var boss := actor_by_id(BOSS)
	var intent: Dictionary = state.intents[0]
	var error := ""
	if intent.beat != "release" or intent.executed or intent.cancelled: error = "release_window_closed"
	elif input.intent_id != intent.intent_id or o.observed_intent != intent.intent_id: error = "current_charge_not_observed"
	elif o.position != o.required_handle: error = "wrong_handle"
	elif int(o.pointer) != int(o.required_pointer): error = "ring_not_aligned"
	elif intent.intent_id in o.interrupt_ids: error = "already_interrupted"
	elif _protected(boss): error = "tenacity_protection"
	if error != "":
		o.last_feedback = error
		_event("armillary_failed", HERO, BOSS, 0, {"reason":error,"intent_id":intent.intent_id})
		return
	if not _break(actor, boss, intent): return
	intent.cancelled = true
	o.interrupt_ids.append(intent.intent_id)
	o.interrupt_count = o.interrupt_ids.size()
	o.last_feedback = "armillary_interrupted"
	var backlash := int(floor(float(boss.max_hp) * float(state.encounter.backlash_fraction)))
	_direct_loss(boss, boss, backlash, "internal_backlash", intent.intent_id)
	_event("armillary_interrupted", HERO, BOSS, backlash, {"intent_id":intent.intent_id,"count":o.interrupt_count})

func _execute_intent(actor: Dictionary, intent: Dictionary) -> void:
	if state.objective.transition_pending or intent.cancelled:
		intent.executed = true
		return
	if intent.beat == "shield":
		intent.executed = true
		state.objective.shield_uses += 1
		actor.shield = int(floor(float(actor.max_hp) * float(state.encounter.shield_fraction)))
		_event("star_shield", actor.id, actor.id, actor.shield, {"reflect_fraction":state.encounter.reflect_fraction})
		return
	super._execute_intent(actor, intent)

func _branch(source: Dictionary, target: Dictionary, raw: float, channel: String, action_id: String) -> int:
	if target.id == BOSS and state.objective.transition_pending: return 0
	var reflection: bool = target.id == BOSS and int(target.get("shield",0)) > 0 and source.id != target.id
	var loss := super._branch(source, target, raw, channel, action_id)
	if target.id == BOSS: _phase_threshold()
	if reflection and loss > 0:
		_direct_loss(target, source, int(floor(float(loss) * float(state.encounter.reflect_fraction))), "shield_reflection", action_id)
	return loss

func _direct_loss(source: Dictionary, target: Dictionary, amount: int, channel: String, action_id: String) -> void:
	if not alive(target) or amount <= 0 or (target.id == BOSS and state.objective.transition_pending): return
	var loss := _lose_hp(source, target, amount)
	_event("damage", source.id, target.id, loss, {"channel":channel, "action_id":action_id})
	if target.id == BOSS: _phase_threshold()

func _lose_hp(source: Dictionary, target: Dictionary, amount: int) -> int:
	if target.id == BOSS and int(state.objective.phase) == 1:
		if state.objective.transition_pending: return 0
		amount = mini(amount, maxi(0, int(target.hp) - int(state.encounter.phase_threshold)))
	var loss := super._lose_hp(source, target, amount)
	if target.id == BOSS: _phase_threshold()
	return loss

func _phase_threshold() -> void:
	var o: Dictionary = state.objective
	var boss := actor_by_id(BOSS)
	if int(o.phase) != 1 or int(boss.hp) > int(state.encounter.phase_threshold) or o.transition_pending: return
	boss.hp = int(state.encounter.phase_threshold)
	boss.defeated = false
	o.transition_pending = true
	for intent in state.intents: intent.cancelled = true
	_event("phase_threshold", BOSS, "", boss.hp, {"discard_overflow":true,"cancel_remaining_hits":true,"next_phase_starts_next_round":true})

func _transition_phase() -> void:
	var boss := actor_by_id(BOSS)
	var o: Dictionary = state.objective
	for key in state.encounter.phase_two: boss[key] = state.encounter.phase_two[key]
	boss.hp = int(boss.max_hp)
	boss.mp = int(boss.max_mp)
	boss.shield = 0
	boss.defeated = false
	o.shield_uses = 0
	o.phase = 2
	o.phase_start_round = int(state.round) + 1
	o.transition_round = int(state.round)
	o.transition_pending = false
	o.observed_intent = ""
	o.charge_id = ""
	o.three_insights = true
	_event("phase_transition", BOSS, "", boss.hp, {"player_preserved":true, "overflow_discarded":true,"message":"半血转场：明三秋催动剑煞，下一轮以850气血进入第二阶段；本次越过340的伤害及剩余连击不带入。梁萧气血、真气、冷却与破招记录保留。"})

func _check_outcome() -> void:
	if state.outcome != "" or not state.has("objective"): return
	var o: Dictionary = state.objective
	var boss := actor_by_id(BOSS)
	if not alive(actor_by_id(HERO)):
		o.failure = "liang_exhausted"
		state.outcome = "defeat"
	elif int(o.interrupt_count) >= 3:
		o.victory_route = "three_unique_interrupts"
		state.outcome = "victory"
	elif int(o.phase) == 2 and boss.defeated:
		o.victory_route = "phase_two_hp_depleted"
		state.outcome = "victory"
	elif state.mode == "round_end" and int(state.round) >= int(state.encounter.max_rounds):
		o.failure = "time_expired"
		state.outcome = "defeat"
	if state.outcome == "victory":
		boss.hp = maxi(1, int(boss.hp))
		boss.defeated = true
		_event("ming_nonlethal_withdrawal", BOSS, "", 0, {"route":o.victory_route})
	if state.outcome != "":
		_event("outcome", "", "", 0, {"result":state.outcome,"reason":o.failure})
	elif state.mode == "round_end" and o.transition_pending:
		_transition_phase()

func get_view() -> Dictionary:
	var view := super.get_view()
	var o: Dictionary = view.objective
	var boss := actor_by_id(BOSS)
	o["summary"] = "数值阶段%d/2 · 机关打断%d/3 · %s · 铜环指针：%s\n%s\n机关操作为战术位置模型：可沿相邻把手移动并逐格转环，不推进回合；借力占本轮行动（速度+30、0真气）。阶段一到340转场，第二阶段满850；溢伤及剩余连击不带入，梁萧状态保留。" % [o.phase,o.interrupt_count,POSITION_NAMES[o.position],POSITION_NAMES[POSITIONS[int(o.pointer)]], "韧性保护中，本轮不可破招" if _protected(boss) else "本轮可破招，仍需满足当前意图条件"]
	o.summary += "\n当前气流目标：%s，刻口：%s；本次蓄力%s。" % [POSITION_NAMES[o.required_handle],POSITION_NAMES[POSITIONS[int(o.required_pointer)]],"已观势" if o.observed_intent == state.intents[0].intent_id else "尚未观势"]
	o.summary += "\n公开十拍：蓄→释→刺→缓→缓→盾→缓→刺→缓→缓；每阶段只结盾一次，此后盾拍也缓息。"
	if o.last_feedback != "":
		var feedback := {"release_window_closed":"释放时窗已过或尚未开始", "current_charge_not_observed":"未观察这一次蓄力", "wrong_handle":"所在把手与气流方向不合", "ring_not_aligned":"铜环指针未对准刻口", "already_interrupted":"这一次意图已计过数", "tenacity_protection":"韧性保护阻止了本次破招", "armillary_interrupted":"铜环借力打断成功，内伤反噬已结算"}
		o.summary += "\n上次机关：" + feedback.get(o.last_feedback,o.last_feedback)
	o["available_actions"] = []
	if state.outcome == "":
		for position in POSITIONS:
			if absi(POSITIONS.find(position) - POSITIONS.find(o.position)) == 1:
				o.available_actions.append(_choice("走到" + POSITION_NAMES[position], {"action_id":"move_handle","destination":position}))
		o.available_actions.append(_choice("铜环向左转一格", {"action_id":"rotate_ring","direction":"left"}))
		o.available_actions.append(_choice("铜环向右转一格", {"action_id":"rotate_ring","direction":"right"}))
		o.available_actions.append(_choice("借力释放（编排本轮行动）", {"action_id":"armillary_release","intent_id":state.intents[0].intent_id}))
	view["skill_costs"] = {HERO:{}}
	for skill_id in actor_by_id(HERO).skills: view.skill_costs[HERO][skill_id] = skill_cost(actor_by_id(HERO),content.skills[skill_id])
	return view

func _choice(label: String, input: Dictionary) -> Dictionary:
	input["revision"] = int(state.revision)
	return {"label":label,"input":input}
