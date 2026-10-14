class_name ChapterFourEncounter
extends RefCounted
## Every accepted spatial input, command edit and round resolution is replayed.
## Retry rebuilds the trusted prebattle party: no refill of lost HP or reward.
const Core = preload("res://scripts/combat/chapter_four_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
const MAX_COMMAND_EDITS_PER_ACTOR := 4
const MAX_COMMAND_EDITS_PER_ROUND := 8
const MAX_REPLAY_EVENTS := 4096
# Separate actor budgets always reserve the other actor's normal action slot.
var engine: ChapterFourCombatEngine
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
		if actor.team == "party" and "objective_action" not in actor.skills: actor.skills.append("objective_action")
	attempt_id = attempt
	engine = Core.new(rules,runtime)
	engine.start(encounter,initial_party)

func get_view() -> Dictionary:
	var view := engine.get_view()
	view.objective["input_budget"] = {"command_remaining":MAX_COMMAND_EDITS_PER_ROUND-_edits(),"actor_remaining":{Core.HERO:MAX_COMMAND_EDITS_PER_ACTOR-_edits(Core.HERO),Core.LIU:MAX_COMMAND_EDITS_PER_ACTOR-_edits(Core.LIU)}}
	for actor in [Core.HERO,Core.LIU]:
		if _edits(actor) >= MAX_COMMAND_EDITS_PER_ACTOR: view.legal_commands[actor] = []
	view.objective.available_actions = view.objective.available_actions.filter(func(option: Dictionary) -> bool: return _edits(option.input.actor_id)<MAX_COMMAND_EDITS_PER_ACTOR)
	return view

func _edits(actor: String = "") -> int:
	var count := 0
	for index in range(history.size()-1,-1,-1):
		if history[index].op == "resolve": break
		var step: Dictionary = history[index]
		var owner: String = str(step.get("actor_id",step.get("input",{}).get("actor_id","")))
		if actor == "" or owner == actor: count += 1
	return count

func apply_input(action: Dictionary) -> Dictionary:
	var error := engine.input_error(action)
	if error != "": return {"accepted":false,"error":error}
	if _edits(str(action.actor_id)) >= MAX_COMMAND_EDITS_PER_ACTOR: return {"accepted":false,"error":"round_edit_limit_resolve_available"}
	var result := engine.apply_input(action)
	if result.accepted:
		var clean := action.duplicate(true)
		clean.erase("revision")
		history.append({"op":"input","input":clean})
	return result

func set_command(actor: String, skill: String, target: String, revision: int = -1) -> String:
	if skill == "objective_action": return "use_objective_input"
	if _edits(actor) >= MAX_COMMAND_EDITS_PER_ACTOR: return "round_edit_limit_resolve_available"
	var error := engine.set_command(actor,skill,target,revision)
	if error == "":
		engine.state.objective.pending.erase(actor)
		history.append({"op":"command","actor_id":actor,"skill_id":skill,"target_id":target})
	return error

func can_resolve() -> bool:
	return engine.can_resolve()

func resolve_round() -> bool:
	if not engine.resolve_round(): return false
	history.append({"op":"resolve"})
	return true

func retry() -> void:
	var fresh := ChapterFourEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
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
	evidence["liu_surviving"] = engine.alive(engine.actor_by_id(Core.LIU))
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
	var fresh := ChapterFourEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
	if not _replay_history(fresh,data.history): return false
	if fresh.checkpoint_history_size != int(data.checkpoint_history_size): return false
	if not Comparator.equivalent(fresh.engine.snapshot(),data.state): return false
	engine = fresh.engine
	history = fresh.history
	checkpoint_history_size = fresh.checkpoint_history_size
	return true

static func _replay_history(session: ChapterFourEncounter, steps: Array) -> bool:
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
	var session := ChapterFourEncounter.new(rule_data,runtime_data,encounter_data,party,proof.attempt_id)
	if not _replay_history(session,proof.commands): return {}
	var verified := session.victory_receipt()
	if verified.is_empty() or not Comparator.equivalent(verified,proof): return {}
	return verified
