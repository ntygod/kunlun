class_name EncounterSession
extends RefCounted
## Owns the engine and its command trace. Views cannot issue victory receipts.
const Core = preload("res://scripts/combat/combat_engine.gd")
var engine: CombatEngine
var encounter: Dictionary
var initial_party: Array
var history: Array = []
var attempt_id := ""
var rules: Dictionary
var runtime: Dictionary
func _init(rule_data: Dictionary, combat_data: Dictionary, encounter_data: Dictionary, party: Array, attempt: String) -> void:
	rules = rule_data
	runtime = combat_data
	encounter = encounter_data.duplicate(true)
	initial_party = party.duplicate(true)
	attempt_id = attempt
	engine = Core.new(rules,runtime)
	engine.start(encounter, initial_party)
func get_view() -> Dictionary:
	return engine.get_view()
func set_command(actor: String, skill: String, target: String, revision: int) -> String:
	return engine.set_command(actor,skill,target,revision)
func can_resolve() -> bool:
	return engine.can_resolve()
func resolve_round() -> bool:
	if not can_resolve(): return false
	var commands: Array = []
	for id in engine.state.commands: commands.append(engine.state.commands[id].duplicate())
	if not engine.resolve_round(): return false
	history.append(commands)
	return true
func retry() -> void:
	engine.start(encounter,initial_party)
	history.clear()
func victory_receipt() -> Dictionary:
	if engine.state.outcome != "victory": return {}
	return {"encounter_id":encounter.id,"attempt_id":attempt_id,"result":encounter.result,
		"commands":history.duplicate(true),"final_actors":engine.get_view().actors}
static func replay_receipt(receipt: Variant, rules_data: Dictionary, runtime_data: Dictionary, encounter_data: Dictionary, party: Array) -> Dictionary:
	if not receipt is Dictionary or not receipt.get("encounter_id") is String or receipt.encounter_id != encounter_data.id: return {}
	if not receipt.get("attempt_id") is String or not receipt.get("commands") is Array or not receipt.get("result") is String: return {}
	if receipt.commands.is_empty() or receipt.commands.size() > 128 or receipt.result != encounter_data.result: return {}
	var session := EncounterSession.new(rules_data,runtime_data,encounter_data,party,receipt.attempt_id)
	for round_commands in receipt.commands:
		if not round_commands is Array or round_commands.size() > party.size(): return {}
		for command in round_commands:
			if not command is Dictionary: return {}
			for key in ["actor_id","skill_id","target_id"]:
				if not command.get(key) is String: return {}
			if session.set_command(command.actor_id,command.skill_id,command.target_id,int(session.engine.state.revision)) != "": return {}
		if not session.resolve_round(): return {}
	var validated := session.victory_receipt()
	if validated.is_empty() or not equivalent(validated,receipt): return {}
	return validated

static func equivalent(a: Variant,b: Variant) -> bool:
	# JSON numbers become floats on read; compare canonical serialized values.
	return JSON.stringify(JSON.parse_string(JSON.stringify(a))) == JSON.stringify(JSON.parse_string(JSON.stringify(b)))
