class_name ChapterThreeEncounter
extends RefCounted
## Every accepted spatial input, command edit and round resolution is replayed.
## A retry keeps the verified prefix ending at this phase's start; never accepts a raw state.
const Core = preload("res://scripts/combat/chapter_three_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
const MAX_SPATIAL_EDITS_PER_ROUND := 24
const MAX_COMMAND_EDITS_PER_ROUND := 8
const MAX_REPLAY_EVENTS := 4096
# B01 has at most120 rounds: (24 spatial + 8 command + 1 resolve)*120=3960.
# Separate budgets always leave an action slot after spatial editing, and a resolve
# after command editing. No accepted input may make its own proof unreplayable.
var engine: ChapterThreeCombatEngine
var encounter: Dictionary
var initial_party: Array
var history: Array = []
var attempt_id := ""
var rules: Dictionary
var runtime: Dictionary
var checkpoint_history_size := 0

func _init(rule_data: Dictionary, combat_data: Dictionary, encounter_data: Dictionary, party: Array, attempt: String) -> void:
	rules = rule_data.duplicate(true)
	runtime = combat_data.duplicate(true)
	encounter = encounter_data.duplicate(true)
	initial_party = party.duplicate(true)
	for actor in initial_party:
		if actor.id == Core.HERO and "objective_action" not in actor.skills: actor.skills.append("objective_action")
	attempt_id = attempt
	engine = Core.new(rules,runtime)
	engine.start(encounter,initial_party)

func get_view() -> Dictionary:
	var view := engine.get_view()
	var budget := _round_budget()
	view.objective["input_budget"] = budget
	if int(budget.spatial_remaining) == 0 or int(budget.command_remaining) == 0:
		view.objective.summary += "\n本轮编排余量：位置/铜环%d次、行动%d次。已编排行动仍可结算，下一轮恢复编排额度。" % [budget.spatial_remaining,budget.command_remaining]
	view.objective.available_actions = view.objective.available_actions.filter(func(option: Dictionary) -> bool:
		return int(budget.spatial_remaining if option.input.action_id in ["move_handle","rotate_ring"] else budget.command_remaining) > 0)
	return view

func _round_budget() -> Dictionary:
	var spatial := 0
	var commands := 0
	for index in range(history.size()-1,-1,-1):
		var step: Dictionary = history[index]
		if step.op == "resolve": break
		if step.op == "input" and step.input.action_id in ["move_handle","rotate_ring"]: spatial += 1
		else: commands += 1
	return {"spatial_remaining":MAX_SPATIAL_EDITS_PER_ROUND-spatial,"command_remaining":MAX_COMMAND_EDITS_PER_ROUND-commands}


func apply_input(action: Dictionary) -> Dictionary:
	var error := engine.input_error(action)
	if error != "": return {"accepted":false,"error":error}
	var budget := _round_budget()
	var kind := "spatial_remaining" if action.action_id in ["move_handle","rotate_ring"] else "command_remaining"
	if int(budget[kind]) <= 0: return {"accepted":false,"error":"round_edit_limit_resolve_available"}
	var result := engine.apply_input(action)
	if result.accepted:
		var clean := action.duplicate(true)
		clean.erase("revision")
		history.append({"op":"input","input":clean})
	return result

func set_command(actor: String, skill: String, target: String, revision: int = -1) -> String:
	if skill == "objective_action": return "use_objective_input"
	if int(_round_budget().command_remaining) <= 0: return "round_edit_limit_resolve_available"
	var error := engine.set_command(actor,skill,target,revision)
	if error == "":
		if actor == Core.HERO: engine.state.objective.pending = {}
		history.append({"op":"command","actor_id":actor,"skill_id":skill,"target_id":target})
	return error

func can_resolve() -> bool:
	return engine.can_resolve()

func resolve_round() -> bool:
	var phase := int(engine.state.objective.phase)
	if not engine.resolve_round(): return false
	history.append({"op":"resolve"})
	if int(engine.state.objective.phase) != phase: checkpoint_history_size = history.size()
	return true

func retry() -> void:
	var fresh := ChapterThreeEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
	var prefix := history.slice(0,checkpoint_history_size)
	if not _replay_history(fresh,prefix): return
	engine = fresh.engine
	history = fresh.history
	checkpoint_history_size = fresh.checkpoint_history_size

func victory_receipt() -> Dictionary:
	if engine.state.outcome != "victory": return {}
	var evidence: Dictionary = engine.state.objective.duplicate(true)
	evidence.erase("pending")
	evidence["liang_surviving"] = engine.alive(engine.actor_by_id(Core.HERO))
	evidence["ming_alive_nonlethal"] = int(engine.actor_by_id(Core.BOSS).hp) > 0 and engine.actor_by_id(Core.BOSS).defeated
	return {"encounter_id":encounter.id,"attempt_id":attempt_id,"result":encounter.result,
		"rules_version":rules.version,"content_version":runtime.version,"initial_party":initial_party.duplicate(true),
		"commands":history.duplicate(true),"final_actors":engine.snapshot().actors,"objective_evidence":evidence,"events":engine.snapshot().events}

func receipt() -> Dictionary:
	return victory_receipt()

func snapshot() -> Dictionary:
	return {"version":1,"encounter_id":encounter.id,"attempt_id":attempt_id,
		"history":history.duplicate(true),"checkpoint_history_size":checkpoint_history_size,"state":engine.snapshot()}

func restore(data: Dictionary) -> bool:
	if data.size() != 6 or data.get("version",0) != 1 or data.get("encounter_id","") != encounter.id or data.get("attempt_id","") != attempt_id: return false
	if not data.get("history") is Array or not data.get("state") is Dictionary: return false
	if not engine._whole(data.get("checkpoint_history_size")): return false
	var fresh := ChapterThreeEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
	if not _replay_history(fresh,data.history): return false
	if fresh.checkpoint_history_size != int(data.checkpoint_history_size): return false
	if not Comparator.equivalent(fresh.engine.snapshot(),data.state): return false
	engine = fresh.engine
	history = fresh.history
	checkpoint_history_size = fresh.checkpoint_history_size
	return true

static func _replay_history(session: ChapterThreeEncounter, steps: Array) -> bool:
	if steps.size() > MAX_REPLAY_EVENTS: return false
	for step in steps:
		if not step is Dictionary or not step.get("op") is String: return false
		match step.op:
			"input":
				if step.size() != 2 or not step.get("input") is Dictionary or step.input.has("revision"): return false
				if not session.apply_input(step.input).accepted: return false
			"command":
				if step.size() != 4: return false
				for key in ["actor_id","skill_id","target_id"]:
					if not step.get(key) is String: return false
				if session.set_command(step.actor_id,step.skill_id,step.target_id) != "": return false
			"resolve":
				if step.size() != 1 or not session.resolve_round(): return false
			_: return false
	return true

static func replay_receipt(proof: Variant, rule_data: Dictionary, runtime_data: Dictionary, encounter_data: Dictionary, party: Array) -> Dictionary:
	if not proof is Dictionary or proof.get("encounter_id","") != encounter_data.id or proof.get("result","") != encounter_data.result: return {}
	if not proof.get("attempt_id") is String or not proof.get("commands") is Array: return {}
	var session := ChapterThreeEncounter.new(rule_data,runtime_data,encounter_data,party,proof.attempt_id)
	if not _replay_history(session,proof.commands): return {}
	var verified := session.victory_receipt()
	if verified.is_empty() or not Comparator.equivalent(verified,proof): return {}
	return verified
