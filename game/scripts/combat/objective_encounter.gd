class_name ObjectiveEncounter
extends RefCounted
## Proof-carrying objective session: receipts and snapshots are reproduced from inputs.
const ObjectiveCore = preload("res://scripts/combat/objective_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
var engine: ObjectiveCombatEngine
var encounter: Dictionary
var initial_party: Array
var history: Array = []
var attempt_id := ""
var rules: Dictionary
var runtime: Dictionary

func _init(rule_data: Dictionary, combat_data: Dictionary, encounter_data: Dictionary, party: Array, attempt: String) -> void:
	rules = rule_data.duplicate(true)
	runtime = combat_data.duplicate(true)
	encounter = encounter_data.duplicate(true)
	initial_party = party.duplicate(true)
	for actor in initial_party:
		if actor.id == ObjectiveCore.HERO and "objective_action" not in actor.skills: actor.skills.append("objective_action")
	attempt_id = attempt
	engine = ObjectiveCore.new(rules, runtime)
	engine.start(encounter, initial_party + encounter.get("protected_actors", []))

func get_view() -> Dictionary:
	return engine.get_view()

func apply_input(action: Dictionary) -> Dictionary:
	return engine.apply_input(action)

func set_command(actor: String, skill: String, target: String, revision: int) -> String:
	if skill == "objective_action": return "use_objective_input"
	var error := engine.set_command(actor, skill, target, revision)
	if error == "" and actor == ObjectiveCore.HERO: engine.state.objective.pending = {}
	return error

func can_resolve() -> bool:
	return engine.can_resolve()

func resolve_round() -> bool:
	if not can_resolve(): return false
	var commands: Array = []
	for actor in engine.state.actors:
		if engine.state.commands.has(actor.id): commands.append(engine.state.commands[actor.id].duplicate(true))
	var input: Dictionary = engine.state.objective.pending.duplicate(true)
	if not engine.resolve_round(): return false
	history.append({"commands": commands, "input": input})
	return true

func retry() -> void:
	engine.start(encounter, initial_party + encounter.get("protected_actors", []))
	history.clear()

func victory_receipt() -> Dictionary:
	if engine.state.outcome != "victory": return {}
	var o: Dictionary = engine.state.objective.duplicate(true)
	o.erase("pending")
	o["liang_surviving"] = engine.alive(engine.actor_by_id(ObjectiveCore.HERO))
	if encounter.kind == "protect_qin":
		o["two_resolved_chain_intents"] = int(o.chain_count) >= 2
		o["qin_not_struck_during_required_window"] = not o.qin_struck
		o["jiuru_support_resolved"] = o.jiuru_resolved
	else:
		o["intel_used"] = o.intel
		o["restraint_window_resolved"] = o.restrained
		o["valid_antidote_exchange"] = o.exchanged
		o["qingyuan_treated"] = o.treated
		o["no_human_deaths"] = true
		for actor in engine.state.actors:
			if int(actor.hp) <= 0: o.no_human_deaths = false
		o["escape_route_complete"] = o.position == "exit"
	return {"encounter_id": encounter.id, "attempt_id": attempt_id, "result": encounter.result,
		"rules_version": rules.version, "content_version": runtime.version, "initial_party": initial_party.duplicate(true),
		"commands": history.duplicate(true), "final_actors": engine.snapshot().actors,
		"objective_evidence": o, "events": engine.snapshot().events}

func receipt() -> Dictionary:
	return victory_receipt()

func snapshot() -> Dictionary:
	return {"version": 1, "encounter_id": encounter.id, "attempt_id": attempt_id,
		"history": history.duplicate(true), "pending_input": engine.state.objective.pending.duplicate(true),
		"commands": engine.state.commands.duplicate(true), "state": engine.snapshot()}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) != 1 or data.get("encounter_id", "") != encounter.id or data.get("attempt_id", "") != attempt_id: return false
	if not data.get("history") is Array or not data.get("pending_input") is Dictionary or not data.get("commands") is Dictionary or not data.get("state") is Dictionary: return false
	var fresh := ObjectiveEncounter.new(rules, runtime, encounter, initial_party, attempt_id)
	if not _replay_history(fresh, data.history): return false
	if fresh.engine.state.mode == "finished":
		if not Comparator.equivalent(fresh.engine.state.objective.pending, data.pending_input) or not Comparator.equivalent(fresh.engine.state.commands, data.commands): return false
	elif not data.pending_input.is_empty():
		if not fresh.apply_input(data.pending_input).accepted: return false
	for actor_id in data.commands:
		if fresh.engine.state.mode == "finished": break
		var command: Variant = data.commands[actor_id]
		if not _valid_command(command) or command.actor_id != actor_id: return false
		if command.skill_id == "objective_action":
			if data.pending_input.is_empty() or actor_id != ObjectiveCore.HERO: return false
		else:
			if fresh.set_command(command.actor_id, command.skill_id, command.target_id, int(fresh.engine.state.revision)) != "": return false
	# Revisions also count harmless edit choices. Persisted state must match all gameplay fields;
	# revision is restored only as a validated non-negative integer cursor.
	if not fresh.engine._whole(data.state.get("revision")): return false
	fresh.engine.state.revision = int(data.state.revision)
	if not Comparator.equivalent(fresh.engine.snapshot(), data.state): return false
	engine = fresh.engine
	history = fresh.history
	return true

static func _valid_command(command: Variant) -> bool:
	if not command is Dictionary or command.size() != 3: return false
	for key in ["actor_id", "skill_id", "target_id"]:
		if not command.get(key) is String: return false
	return true

static func _replay_history(session: ObjectiveEncounter, steps: Array) -> bool:
	if steps.size() > 128: return false
	for step in steps:
		if not step is Dictionary or step.size() != 2 or not step.get("commands") is Array or not step.get("input") is Dictionary: return false
		if step.commands.is_empty() or step.commands.size() > session.initial_party.size(): return false
		if not step.input.is_empty() and not session.apply_input(step.input).accepted: return false
		var seen: Array = []
		for command in step.commands:
			if not _valid_command(command) or command.actor_id in seen: return false
			seen.append(command.actor_id)
			if command.skill_id == "objective_action":
				if step.input.is_empty() or command.actor_id != ObjectiveCore.HERO or command.target_id != ObjectiveCore.HERO: return false
			else:
				if not step.input.is_empty() and command.actor_id == ObjectiveCore.HERO: return false
				if session.set_command(command.actor_id, command.skill_id, command.target_id, int(session.engine.state.revision)) != "": return false
		if not session.resolve_round(): return false
	return true

static func replay_receipt(receipt_data: Variant, rules_data: Dictionary, runtime_data: Dictionary, encounter_data: Dictionary, party: Array) -> Dictionary:
	if not receipt_data is Dictionary or receipt_data.get("encounter_id", "") != encounter_data.id: return {}
	if not receipt_data.get("attempt_id") is String or not receipt_data.get("commands") is Array or receipt_data.get("result", "") != encounter_data.result: return {}
	var session := ObjectiveEncounter.new(rules_data, runtime_data, encounter_data, party, receipt_data.attempt_id)
	if not _replay_history(session, receipt_data.commands): return {}
	var validated := session.victory_receipt()
	if validated.is_empty() or not Comparator.equivalent(validated, receipt_data): return {}
	return validated
