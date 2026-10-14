class_name ObjectiveCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## Scenario objectives share the core's action queue, damage, MP, CD and snapshots.
const HERO := "char_liang_xiao"

func begin_round() -> void:
	if not state.has("objective"):
		state.objective = {"kind": state.encounter.kind, "stage": "protect" if state.encounter.kind == "protect_qin" else "listen",
			"pending": {}, "qin_lane": "left", "decoy_lane": "", "chain_count": 0, "qin_struck": false,
			"jiuru_resolved": false, "intel": false, "window_round": 0, "restrained": false,
			"identified": false, "has_antidote": false, "exchanged": false, "treated": false,
			"delay_resolved": false, "delay_remaining": 0, "position": "inner", "alarm": 0, "failure": ""}
	super.begin_round()
	if state.mode != "commands": return
	state.objective.pending = {}
	state.objective.decoy_lane = ""
	for intent in state.intents:
		if state.encounter.kind == "antidote_escape":
			if intent.actor_id == "char_huo_zhenren":
				intent.name = _guard_intent_text()

func _guard_intent_text() -> String:
	var o: Dictionary = state.objective
	match o.stage:
		"listen": return "西侧巡查：口令『投诚者从东侧近前』，尚未识破梁萧"
		"approach": return "护卫注视西路；东路暂空，可假意投诚"
		"near": return "一轮制住窗口：第%d轮结束前脱欢会退回护卫身后" % int(o.window_round)
		"exchange": return "药瓶置石凳：青瓶与红瓶，先核对瓶签再交换"
		"administer": return "暂不敢逼近，花清渊尚待解毒"
		"delay": return "追兵将从栈道追来，须短暂阻追再护送"
		"escape": return "追兵受阻尚余%d轮；内庭→侧径/栈桥→出口" % int(o.delay_remaining)
	return "保持戒备"

func input_error(action: Dictionary) -> String:
	if state.mode != "commands" or state.outcome != "": return "not_accepting_input"
	if not action.get("action_id") is String: return "invalid_action"
	for key in action:
		if key not in ["action_id", "lane", "target", "item", "destination", "revision"]: return "unexpected_input_field"
	if action.has("revision") and (not _whole(action.revision) or int(action.revision) != int(state.revision)): return "stale_revision"
	var o: Dictionary = state.objective
	var id: String = action.action_id
	if id == "wait": return ""
	if state.encounter.kind == "protect_qin":
		if id not in ["move_qin", "decoy_chain"]: return "wrong_objective"
		if action.get("lane", "") not in ["left", "right"]: return "invalid_lane"
		return ""
	match id:
		"listen":
			if o.stage != "listen": return "intel_already_heard"
		"feign_surrender":
			if o.stage != "approach" or not o.intel: return "intel_required"
			if action.get("lane", "") not in ["east", "west"]: return "invalid_lane"
		"restrain":
			if o.stage != "near" or int(state.round) != int(o.window_round): return "restraint_window_closed"
			if action.get("target", "") != "char_toghon": return "invalid_restraint_target"
		"inspect_antidote":
			if o.stage != "exchange" or not o.restrained: return "restraint_required"
		"exchange":
			if o.stage != "exchange" or not o.identified or not o.restrained: return "identify_antidote_first"
			if action.get("item", "") not in ["blue_antidote", "red_bottle"]: return "invalid_item"
		"administer":
			if o.stage != "administer" or not o.has_antidote: return "antidote_required"
			if action.get("target", "") not in ["char_hua_qingyuan", HERO]: return "invalid_patient"
		"delay_pursuit":
			if o.stage != "delay" or not o.treated: return "treatment_required"
			if action.get("lane", "") not in ["bridge", "courtyard"]: return "invalid_lane"
		"escort_move":
			if o.stage != "escape" or not o.treated or not o.delay_resolved: return "escape_not_ready"
			var routes := {"inner": ["side", "bridge"], "side": ["inner", "bridge"], "bridge": ["inner", "exit"]}
			if action.get("destination", "") not in routes.get(o.position, []): return "not_adjacent"
		_: return "invalid_action"
	return ""

func apply_input(action: Dictionary) -> Dictionary:
	var error := input_error(action)
	if error != "": return {"accepted": false, "error": error}
	var normalized := action.duplicate(true)
	normalized.erase("revision")
	if state.objective.pending == normalized and state.commands.get(HERO, {}).get("skill_id", "") == "objective_action":
		return {"accepted": true, "error": ""}
	var previous: Dictionary = state.objective.pending
	state.objective.pending = normalized
	error = set_command(HERO, "objective_action", HERO)
	if error != "":
		state.objective.pending = previous
		return {"accepted": false, "error": error}
	# Changing the payload of the same core command is also a state revision.
	if previous != normalized and previous != {}: state.revision += 1
	return {"accepted": true, "error": ""}

func validate_command(actor_id: String, skill_id: String, target_id: String) -> String:
	var error := super.validate_command(actor_id, skill_id, target_id)
	if error != "": return error
	if skill_id == "objective_action" and state.objective.pending.is_empty(): return "objective_input_required"
	return ""

func _execute_command(actor: Dictionary, command: Dictionary) -> void:
	if command.skill_id != "objective_action":
		super._execute_command(actor, command)
		return
	_pay(actor, command.skill_id, content.skills.objective_action)
	var input: Dictionary = state.objective.pending
	_event("objective_input", actor.id, "", 0, input)
	var o: Dictionary = state.objective
	match str(input.get("action_id", "")):
		"move_qin": o.qin_lane = input.lane
		"decoy_chain": o.decoy_lane = input.lane
		"listen":
			o.intel = true
			o.stage = "approach"
			_event("intel_used", HERO, "char_huo_zhenren")
		"feign_surrender":
			if input.lane == "east":
				o.window_round = int(state.round) + 1
				o.stage = "near"
				_event("approach_window_opened", HERO, "char_toghon", o.window_round)
			else: o.alarm += 1
		"restrain":
			o.restrained = true
			o.stage = "exchange"
			_event("nonlethal_restraint", HERO, "char_toghon")
		"inspect_antidote":
			o.identified = true
			_event("antidote_identified", HERO, "", 0, {"valid_item": "blue_antidote", "exchange_point": "stone_bench"})
		"exchange":
			if input.item == "blue_antidote":
				o.exchanged = true
				o.has_antidote = true
				o.stage = "administer"
				_event("antidote_exchanged", HERO, "char_toghon", 0, {"item": input.item, "exchange_point": "stone_bench"})
			else: o.failure = "wrong_antidote"
		"administer":
			o.has_antidote = false
			if input.target == "char_hua_qingyuan":
				o.treated = true
				o.stage = "delay"
				_event("qingyuan_treated", HERO, "char_hua_qingyuan")
			else: o.failure = "antidote_wasted"
		"delay_pursuit":
			if input.lane == "bridge":
				o.delay_resolved = true
				o.delay_remaining = 4
				o.stage = "escape"
				_event("pursuit_delayed_offscreen", HERO, "", 0, {"presentation": "brief_source_directed_cutaway_no_animal_target"})
			else: o.alarm += 1
		"escort_move":
			o.position = input.destination
			_event("escort_moved", HERO, "", 0, {"position": o.position})
		"wait": pass

func _execute_intent(actor: Dictionary, intent: Dictionary) -> void:
	var o: Dictionary = state.objective
	if state.encounter.kind == "protect_qin":
		var lane: String = intent.get("lane", "left")
		if o.decoy_lane == lane:
			intent.target_id = HERO
			super._execute_intent(actor, intent)
		elif o.qin_lane != lane:
			intent.executed = true
			_event("enemy_action", actor.id, "char_qin_bofu", 0, {"lane": lane})
			_event("chain_struck_empty_lane", actor.id, "", 0, {"lane": lane})
		else:
			super._execute_intent(actor, intent)
			o.qin_struck = true
			o.failure = "qin_hit_by_chain"
		o.chain_count += 1
		_event("chain_resolved", actor.id, "char_qin_bofu", int(o.chain_count), {"safe": not o.qin_struck})
		if o.chain_count >= 2 and not o.qin_struck and alive(actor_by_id(HERO)):
			o.jiuru_resolved = true
			_event("jiuru_counter_chain", "char_jiuru", actor.id)
		return
	if actor.id == "char_toghon":
		intent.executed = true
		_event("enemy_action", actor.id, HERO, 0, {"kind": "hostage_standoff" if o.restrained else "guarded_watch"})
		return
	# Guards respond to exposure and pursuit, not an infinite compulsory damage loop.
	var punish := false
	if o.stage == "near" and int(state.round) >= int(o.window_round):
		o.stage = "approach"
		o.window_round = 0
		o.alarm += 1
		punish = true
		_event("restraint_window_missed", actor.id, HERO)
	if o.stage == "escape":
		o.delay_remaining -= 1
		if o.delay_remaining <= 0: o.failure = "pursuers_caught_family"
	if not o.restrained and state.commands.get(HERO, {}).get("skill_id", "") != "objective_action": punish = true
	if o.alarm > 0 and o.stage in ["approach", "delay"]: punish = true
	if punish:
		super._execute_intent(actor, intent)
	else:
		intent.executed = true
		_event("enemy_action", actor.id, HERO, 0, {"kind": "watch_or_standoff", "stage": o.stage})

func _check_outcome() -> void:
	if state.outcome != "" or not state.has("objective"): return
	var o: Dictionary = state.objective
	if not alive(actor_by_id(HERO)): o.failure = "liang_exhausted"
	if int(state.round) > int(state.encounter.max_rounds) or (state.mode == "round_end" and int(state.round) == int(state.encounter.max_rounds)): o.failure = "time_expired"
	if state.encounter.kind == "antidote_escape":
		if o.alarm >= 3: o.failure = "cover_blown"
		if int(state.round) >= 13 and not o.treated: o.failure = "qingyuan_poison_worsened"
		for actor in state.actors:
			if actor.team == "enemy" and actor.defeated: o.failure = "exchange_partner_incapacitated"
	if o.failure != "": state.outcome = "defeat"
	elif state.encounter.kind == "protect_qin" and o.jiuru_resolved and not o.qin_struck: state.outcome = "victory"
	elif state.encounter.kind == "antidote_escape" and o.position == "exit" and o.treated and o.exchanged and o.delay_resolved: state.outcome = "victory"
	if state.outcome != "": _event("outcome", "", "", 0, {"result": state.outcome, "reason": o.failure})

func get_view() -> Dictionary:
	var view := super.get_view()
	view.objective["summary"] = _summary()
	view.objective["available_actions"] = _available_actions()
	view["skill_costs"] = {}
	for actor in state.actors:
		if actor.team != "party" or not actor.get("controllable", true): continue
		view.skill_costs[actor.id] = {}
		for skill_id in actor.skills: view.skill_costs[actor.id][skill_id] = skill_cost(actor, content.skills[skill_id])
	return view

func _summary() -> String:
	var o: Dictionary = state.objective
	if state.encounter.kind == "protect_qin":
		return "秦伯符在%s侧；已化解%d/2次铁索。任何铁索击中秦伯符即失败；不能靠打空气血通关。" % ["左" if o.qin_lane == "left" else "右", o.chain_count]
	var stages := {"listen":"侦听", "approach":"假意接近", "near":"制住窗口", "exchange":"核药交换", "administer":"救治花清渊", "delay":"阻止追兵", "escape":"护送撤离"}
	var positions := {"inner":"内庭", "side":"侧径", "bridge":"栈桥", "exit":"安全出口"}
	return "阶段：%s · 警觉%d/3 · 花清渊%s · 位置%s\n%s" % [stages.get(o.stage,o.stage), o.alarm, "已服解药" if o.treated else "尚中毒", positions.get(o.position,o.position), _guard_intent_text()]

func _choice(label: String, input: Dictionary) -> Dictionary:
	input["revision"] = int(state.revision)
	return {"label": label, "input": input}

func _available_actions() -> Array:
	if state.outcome != "": return []
	var out: Array = []
	var o: Dictionary = state.objective
	if state.encounter.kind == "protect_qin":
		for lane in ["left", "right"]:
			var word := "左" if lane == "left" else "右"
			out.append(_choice("扶秦伯符移到%s侧掩体" % word, {"action_id": "move_qin", "lane": lane}))
			out.append(_choice("站到%s侧引走铁索（梁萧代受）" % word, {"action_id": "decoy_chain", "lane": lane}))
	else:
		match o.stage:
			"listen": out.append(_choice("侦听蒙语口令", {"action_id": "listen"}))
			"approach":
				out.append(_choice("循东侧假投诚接近", {"action_id": "feign_surrender", "lane": "east"}))
				out.append(_choice("从西侧直接靠近", {"action_id": "feign_surrender", "lane": "west"}))
			"near": out.append(_choice("趁本轮空隙制住脱欢（不伤性命）", {"action_id": "restrain", "target": "char_toghon"}))
			"exchange":
				out.append(_choice("核对石凳上药瓶与花清渊所中之毒", {"action_id": "inspect_antidote"}))
				if o.identified:
					out.append(_choice("以青瓶解药交换退让", {"action_id": "exchange", "item": "blue_antidote"}))
					out.append(_choice("取红瓶交换（与核对结果不符）", {"action_id": "exchange", "item": "red_bottle"}))
			"administer": out.append(_choice("将解药喂给花清渊", {"action_id": "administer", "target": "char_hua_qingyuan"}))
			"delay":
				out.append(_choice("在栈道阻追（短促离镜演出）", {"action_id": "delay_pursuit", "lane": "bridge"}))
				out.append(_choice("在无人内庭设阻", {"action_id": "delay_pursuit", "lane": "courtyard"}))
			"escape":
				var routes := {"inner": ["side", "bridge"], "side": ["inner", "bridge"], "bridge": ["inner", "exit"]}
				var names := {"inner": "内庭", "side": "侧径", "bridge": "栈桥", "exit": "安全出口"}
				for destination in routes.get(o.position, []): out.append(_choice("护送一家到" + names[destination], {"action_id": "escort_move", "destination": destination}))
	out.append(_choice("观察等待一轮", {"action_id": "wait"}))
	return out
