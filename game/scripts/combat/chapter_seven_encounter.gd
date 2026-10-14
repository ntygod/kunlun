class_name ChapterSevenEncounter
extends RefCounted
## Replay is the only restore path. Untrusted state never mutates the live engine.
const Core = preload("res://scripts/combat/chapter_seven_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
const MAX_REPLAY_EVENTS := 32768
const MAX_EDITS := 128
var engine: ChapterSevenCombatEngine
var encounter: Dictionary
var initial_party: Array
var history: Array=[]
var attempt_id: String
var checkpoint_history_size := 0
var rules: Dictionary
var runtime: Dictionary

func _init(rule_data: Dictionary,combat_data: Dictionary,encounter_data: Dictionary,party: Array,attempt: String) -> void:
	rules=rule_data.duplicate(true);runtime=combat_data.duplicate(true)
	encounter=encounter_data.duplicate(true);initial_party=party.duplicate(true);attempt_id=attempt
	engine=Core.new(rules,runtime);engine.start(encounter,initial_party)

func _edits() -> int:
	var n:=0
	for i in range(history.size()-1,-1,-1):
		if history[i].op=="resolve":break
		n+=1
	return n

func get_view() -> Dictionary:
	var view:=engine.get_view()
	view.objective["input_budget"]={"command_remaining":MAX_EDITS-_edits()}
	return view

func apply_input(action: Variant) -> Dictionary:
	if not action is Dictionary:return {"accepted":false,"error":"invalid_input_type"}
	if _edits()>=MAX_EDITS or history.size()>=MAX_REPLAY_EVENTS-2:return {"accepted":false,"error":"edit_limit_retry_available"}
	var result:=engine.apply_input(action)
	if result.accepted:
		var clean: Dictionary=action.duplicate(true);clean.erase("revision")
		history.append({"op":"input","input":clean})
	return result

func set_command(actor: Variant,skill: Variant,target: Variant,revision: Variant=-1) -> String:
	if not actor is String or not skill is String or not target is String:return "invalid_command_type"
	if not revision is int or revision < -1:return "invalid_revision_type"
	if _edits()>=MAX_EDITS or history.size()>=MAX_REPLAY_EVENTS-2:return "edit_limit_retry_available"
	var error:=engine.set_command(actor,skill,target,revision)
	if error=="":history.append({"op":"command","actor_id":actor,"skill_id":skill,"target_id":target})
	return error

func can_resolve() -> bool:return engine.can_resolve()
func resolve_round() -> bool:
	var phase: int=engine.state.objective.phase
	if history.size()>=MAX_REPLAY_EVENTS-1:return false
	if not engine.resolve_round():return false
	history.append({"op":"resolve"})
	if int(engine.state.objective.phase)!=phase:checkpoint_history_size=history.size()
	return true

func retry() -> void:
	# The same immutable entrance, never a new party read or phase refill.
	var fresh:=ChapterSevenEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
	if not _replay_history(fresh,history.slice(0,checkpoint_history_size)):return
	engine=fresh.engine;history=fresh.history;checkpoint_history_size=fresh.checkpoint_history_size

func victory_receipt() -> Dictionary:
	if engine.state.outcome!="victory":return {}
	var evidence: Dictionary=engine.state.objective.duplicate(true);evidence.erase("pending")
	return {"encounter_id":encounter.id,"attempt_id":attempt_id,"result":encounter.result,"rules_version":rules.version,"content_version":runtime.version,"initial_party":initial_party.duplicate(true),"commands":history.duplicate(true),"final_actors":final_party(),"context":encounter.get("context",{}).duplicate(true),"objective_evidence":evidence,"events":engine.snapshot().events}
func receipt() -> Dictionary:return victory_receipt()
func snapshot() -> Dictionary:
	return {"version":1,"encounter_id":encounter.id,"attempt_id":attempt_id,"history":history.duplicate(true),"checkpoint_history_size":checkpoint_history_size,"state":engine.snapshot()}
func restore(data: Variant) -> bool:
	if not data is Dictionary:return false
	if data.size()!=6 or not engine._whole(data.get("version")) or data.get("version")!=1:return false
	if not data.get("encounter_id") is String or data.encounter_id!=encounter.id or not data.get("attempt_id") is String or data.attempt_id!=attempt_id:return false
	if not data.get("history") is Array or not data.get("state") is Dictionary or not engine._whole(data.get("checkpoint_history_size")):return false
	var fresh:=ChapterSevenEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
	if not _replay_history(fresh,data.history) or fresh.checkpoint_history_size!=int(data.checkpoint_history_size) or not Comparator.equivalent(fresh.engine.snapshot(),data.state):return false
	engine=fresh.engine;history=fresh.history;checkpoint_history_size=fresh.checkpoint_history_size;return true

static func _replay_history(session: ChapterSevenEncounter,steps: Array) -> bool:
	if steps.size()>MAX_REPLAY_EVENTS:return false
	for step in steps:
		if not step is Dictionary or not step.get("op") is String:return false
		match step.op:
			"input":
				if step.size()!=2 or not step.get("input") is Dictionary or step.input.has("revision"):return false
				if not session.apply_input(step.input).accepted:return false
			"command":
				if step.size()!=4:return false
				for key in ["actor_id","skill_id","target_id"]:
					if not step.get(key) is String:return false
				if session.set_command(step.actor_id,step.skill_id,step.target_id)!="":return false
			"resolve":
				if step.size()!=1 or not session.resolve_round():return false
			_:return false
	return true

static func replay_receipt(proof: Variant,rule_data: Dictionary,runtime_data: Dictionary,encounter_data: Dictionary,party: Array) -> Dictionary:
	if not proof is Dictionary or not proof.get("encounter_id") is String or not proof.get("result") is String:return {}
	if proof.encounter_id!=encounter_data.id or proof.result!=encounter_data.result or not proof.get("attempt_id") is String or not proof.get("commands") is Array:return {}
	var session:=ChapterSevenEncounter.new(rule_data,runtime_data,encounter_data,party,proof.attempt_id)
	if not _replay_history(session,proof.commands):return {}
	var verified:=session.receipt()
	return verified if not verified.is_empty() and Comparator.equivalent(verified,proof) else {}

func final_party() -> Array:
	var party: Array=[]
	for actor in initial_party:
		var current: Dictionary=engine.actor_by_id(actor.id)
		# Resource-only return, permanent panels and skills remain campaign-owned.
		party.append({"id":actor.id,"hp":current.hp if not current.is_empty() else actor.hp,"mp":current.mp if not current.is_empty() else actor.mp})
	return party
