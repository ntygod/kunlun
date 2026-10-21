class_name ChapterThirteenEncounter
extends RefCounted
const Core = preload("res://scripts/combat/chapter_thirteen_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
const MAX_HISTORY := 4096
var engine: ChapterThirteenCombatEngine
var encounter: Dictionary
var initial_party: Array
var history: Array = []
var attempt_id: String
var rules: Dictionary
var runtime: Dictionary
func _init(r: Dictionary, c: Dictionary, config: Dictionary, party: Array, attempt: String) -> void:
 rules=r.duplicate(true); runtime=c.duplicate(true); encounter=config.duplicate(true)
 initial_party=party.duplicate(true); attempt_id=attempt
 engine=Core.new(rules,runtime); engine.start(encounter,initial_party)
 if attempt.is_empty() or not config.get("context") is Dictionary or str(config.context.get("current_token","")) != attempt:
  engine.entry_error="invalid_attempt"; engine.state.outcome="invalid"; engine.state.mode="finished"
func get_view() -> Dictionary: return engine.get_view()
func can_resolve() -> bool: return engine.can_resolve()
func apply_input(action: Variant) -> Dictionary:
 if history.size() >= MAX_HISTORY - 1: return {"accepted":false,"error":"history_limit_retry_available"}
 var result := engine.apply_input(action)
 if result.accepted:
  var clean: Dictionary=action.duplicate(true); clean.erase("revision")
  history.append({"op":"input","input":clean})
 return result
func set_command(actor: Variant, skill: Variant, target: Variant, revision: Variant = -1) -> String:
 if history.size()>=MAX_HISTORY-1:return "history_limit_retry_available"
 var result:=engine.set_command(actor,skill,target,revision)
 if result=="":history.append({"op":"command","actor_id":actor,"skill_id":skill,"target_id":target})
 return result
func resolve_round() -> bool:
 if history.size() >= MAX_HISTORY or not engine.resolve_round(): return false
 history.append({"op":"resolve"}); return true
func retry() -> void:
 # Rebuild from the original encounter entry, never the current campaign party.
 var fresh:=ChapterThirteenEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
 engine=fresh.engine; history=[]
func final_party() -> Array:
 var result:Array=[]
 for original in initial_party:
  var actor:=engine.actor_by_id(str(original.id))
  if not actor.is_empty():result.append({"id":actor.id,"hp":actor.hp,"mp":actor.mp})
 return result
func receipt() -> Dictionary:
 if engine.state.outcome != "victory": return {}
 return {"encounter_id":encounter.id,"attempt_id":attempt_id,"result":encounter.result,"rules_version":rules.version,"content_version":runtime.version,"initial_party":initial_party.duplicate(true),"commands":history.duplicate(true),"final_actors":final_party(),"context":encounter.context.duplicate(true),"objective_evidence":engine.state.objective.duplicate(true),"events":engine.state.events.duplicate(true)}
func victory_receipt() -> Dictionary: return receipt()
func snapshot() -> Dictionary:
 return {"version":1,"encounter_id":encounter.get("id",""),"attempt_id":attempt_id,"history":history.duplicate(true),"state":engine.snapshot(),"initial_party":initial_party.duplicate(true),"initial_encounter":encounter.duplicate(true)}
func restore(data: Variant) -> bool:
 if engine.entry_error!="": return false
 if not data is Dictionary or data.size()!=7 or not data.has_all(["version","encounter_id","attempt_id","history","state","initial_party","initial_encounter"]): return false
 if not _whole(data.version,1,1) or not _text(data.encounter_id) or data.encounter_id!=encounter.id or not _text(data.attempt_id) or data.attempt_id!=attempt_id: return false
 if not data.history is Array or not data.state is Dictionary or not data.initial_party is Array or not data.initial_encounter is Dictionary: return false
 if not Comparator.equivalent(initial_party,data.initial_party) or not Comparator.equivalent(encounter,data.initial_encounter): return false
 var fresh := ChapterThirteenEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
 if fresh.engine.entry_error != "" or not _replay(fresh,data.history): return false
 if not Comparator.equivalent(fresh.snapshot(),data): return false
 engine=fresh.engine; history=fresh.history; return true
static func _replay(session: ChapterThirteenEncounter, steps: Array) -> bool:
 if steps.size()>MAX_HISTORY: return false
 for step in steps:
  if not step is Dictionary or not _text(step.get("op")): return false
  match step.op:
   "input":
    if step.size()!=2 or not step.has_all(["op","input"]) or not step.input is Dictionary or step.input.has("revision"): return false
    var action:Dictionary=step.input.duplicate(true);action.revision=session.engine.state.revision
    if not session.apply_input(action).accepted: return false
   "command":
    if step.size()!=4 or not step.has_all(["op","actor_id","skill_id","target_id"]):return false
    if session.set_command(step.actor_id,step.skill_id,step.target_id)!="":return false
   "resolve":
    if step.size()!=1 or not session.resolve_round(): return false
   _: return false
 return true
static func from_snapshot(data: Variant,r: Dictionary,c: Dictionary) -> ChapterThirteenEncounter:
 if not data is Dictionary or not data.get("initial_party") is Array or not data.get("initial_encounter") is Dictionary or not _text(data.get("attempt_id")): return null
 var session := ChapterThirteenEncounter.new(r,c,data.initial_encounter,data.initial_party,str(data.attempt_id))
 return session if session.engine.entry_error=="" and session.restore(data) else null
static func replay_receipt(proof: Variant,r: Dictionary,c: Dictionary,config: Dictionary,party: Array) -> Dictionary:
 if not proof is Dictionary or not _text(proof.get("attempt_id")) or not proof.get("commands") is Array: return {}
 var session := ChapterThirteenEncounter.new(r,c,config,party,str(proof.attempt_id))
 if session.engine.entry_error!="" or not _replay(session,proof.commands): return {}
 var verified := session.receipt()
 return verified if not verified.is_empty() and Comparator.equivalent(verified,proof) else {}

static func _text(value: Variant) -> bool:return value is String or value is StringName

static func _whole(v: Variant,minimum: int,maximum: int) -> bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=minimum and v<=maximum
