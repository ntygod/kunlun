class_name ChapterEightEncounter
extends RefCounted
## Replay is the only restore path. Untrusted state never mutates the live engine.
const Core = preload("res://scripts/combat/chapter_eight_engine.gd")
const Comparator = preload("res://scripts/campaign/encounter_session.gd")
const MAX_REPLAY_EVENTS := 32768
const MAX_EDITS := 128
var engine: ChapterEightCombatEngine
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
  if history[i].op in ["resolve","resume"]:break
  if history[i].op in ["input","command"]:n+=1
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
 if history.size()>=MAX_REPLAY_EVENTS-1:return false
 if not engine.resolve_round():return false
 history.append({"op":"resolve"})

 return true

func retry() -> void:
 # The same immutable entrance, never a new party read or phase refill.
 var fresh:=ChapterEightEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
 if not _replay_history(fresh,history.slice(0,checkpoint_history_size)):return
 engine=fresh.engine;history=fresh.history;checkpoint_history_size=fresh.checkpoint_history_size

func victory_receipt() -> Dictionary:
 if engine.state.outcome!="victory":return {}
 var evidence: Dictionary=engine.state.objective.duplicate(true);evidence.erase("pending")
 return {"encounter_id":engine.state.encounter.id,"attempt_id":attempt_id,"phase_attempt_id":engine.state.objective.get("phase_attempt_id",attempt_id),"result":engine.state.encounter.result,"rules_version":rules.version,"content_version":runtime.version,"initial_party":initial_party.duplicate(true),"commands":history.duplicate(true),"final_actors":final_party(),"context":encounter.get("context",{}).duplicate(true),"objective_evidence":evidence,"events":engine.snapshot().events,"campaign_snapshot":snapshot()}
func receipt() -> Dictionary:return victory_receipt()
func snapshot() -> Dictionary:
 return {"version":1,"encounter_id":encounter.id,"attempt_id":attempt_id,"history":history.duplicate(true),"checkpoint_history_size":checkpoint_history_size,"state":engine.snapshot(),"initial_party":initial_party.duplicate(true),"initial_encounter":encounter.duplicate(true)}
func restore(data: Variant) -> bool:
 if not data is Dictionary:return false
 if data.size()!=8 or not data.has_all(["version","encounter_id","attempt_id","history","checkpoint_history_size","state","initial_party","initial_encounter"]):return false
 if not data.initial_party is Array or not data.initial_encounter is Dictionary:return false
 if not engine._whole(data.get("version")) or data.get("version")!=1:return false
 if not data.get("encounter_id") is String or data.encounter_id!=encounter.id or not data.get("attempt_id") is String or data.attempt_id!=attempt_id:return false
 if not data.get("history") is Array or not data.get("state") is Dictionary or not engine._whole(data.get("checkpoint_history_size")):return false
 if not Comparator.equivalent(data.initial_party,initial_party) or not Comparator.equivalent(data.initial_encounter,encounter):return false
 var fresh:=ChapterEightEncounter.new(rules,runtime,encounter,initial_party,attempt_id)
 if not _replay_history(fresh,data.history) or fresh.checkpoint_history_size!=int(data.checkpoint_history_size) or not Comparator.equivalent(fresh.engine.snapshot(),data.state) or not Comparator.equivalent(fresh.history,data.history):return false
 engine=fresh.engine;history=fresh.history;checkpoint_history_size=fresh.checkpoint_history_size;return true

static func _replay_history(session: ChapterEightEncounter,steps: Array) -> bool:
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
   "sync":
    if step.size()!=2 or not step.get("actor") is Dictionary or not session.sync_campaign_actor(step.actor):return false
   "context":
    if step.size()!=2 or not step.get("context") is Dictionary or not session.sync_campaign_context(step.context):return false
   "resume":
    if step.size()!=3 or not step.get("context") is Dictionary or not step.get("attempt") is String or not session.resume_phase_two(step.context,step.attempt):return false
   _:return false
 return true

static func replay_receipt(proof: Variant,rule_data: Dictionary,runtime_data: Dictionary,encounter_data: Dictionary,party: Array) -> Dictionary:
 if not proof is Dictionary or not proof.get("encounter_id") is String or not proof.get("result") is String:return {}
 if proof.encounter_id!=encounter_data.id or proof.result!=encounter_data.result or not proof.get("attempt_id") is String or not proof.get("commands") is Array:return {}
 var session: ChapterEightEncounter
 var prefix:=0
 if encounter_data.id=="enc_ch08_civilian_escort":
  var trusted: Variant=encounter_data.get("context",{}).get("campaign_checkpoint")
  session=from_snapshot(trusted,rule_data,runtime_data)
  if session==null or session.engine.state.objective.phase!="phase_two":return {}
  prefix=session.history.size()
  if proof.commands.size()<prefix or not Comparator.equivalent(proof.commands.slice(0,prefix),session.history):return {}
 else:
  session=ChapterEightEncounter.new(rule_data,runtime_data,encounter_data,party,proof.attempt_id)
 for step in proof.commands.slice(prefix):
  if not step is Dictionary or step.get("op") not in ["input","command","resolve"]:return {}
 if not _replay_history(session,proof.commands.slice(prefix)):return {}
 var verified:=session.receipt()
 return verified if not verified.is_empty() and Comparator.equivalent(verified,proof) else {}

static func from_snapshot(data: Variant,rule_data: Dictionary,runtime_data: Dictionary) -> ChapterEightEncounter:
 if not data is Dictionary or not data.get("initial_party") is Array or not data.get("initial_encounter") is Dictionary or not data.get("attempt_id") is String:return null
 var session:=ChapterEightEncounter.new(rule_data,runtime_data,data.initial_encounter,data.initial_party,data.attempt_id)
 if session.engine.entry_error!="" or not session.restore(data):return null
 return session

func sync_campaign_actor(actor: Variant) -> bool:
 if not actor is Dictionary or history.size()>=MAX_REPLAY_EVENTS-2:return false
 if not engine.sync_campaign_actor(actor):return false
 history.append({"op":"sync","actor":actor.duplicate(true)});return true

func resume_phase_two(context: Variant,attempt: Variant) -> bool:
 if not context is Dictionary or not attempt is String or attempt.is_empty() or history.size()>=MAX_REPLAY_EVENTS-2:return false
 if not engine.resume_phase_two(context):return false
 engine.state.objective.phase_attempt_id=attempt
 # The campaign identity and original attempt stay stable; phase-specific caller
 # attempt is recorded, not used to silently reset the campaign entrance.
 history.append({"op":"resume","context":context.duplicate(true),"attempt":attempt})
 checkpoint_history_size=history.size();return true

func final_party() -> Array:
 var party: Array=[]
 for actor in initial_party:
  var current: Dictionary=engine.actor_by_id(actor.id)
  # Resource-only return, permanent panels and skills remain campaign-owned.
  party.append({"id":actor.id,"hp":current.hp if not current.is_empty() else actor.hp,"mp":current.mp if not current.is_empty() else actor.mp})
 return party

func sync_campaign_context(context: Variant) -> bool:
 if not context is Dictionary or history.size()>=MAX_REPLAY_EVENTS-2:return false
 var before: Dictionary=engine.snapshot()
 if not engine.sync_campaign_context(context):return false
 if not Comparator.equivalent(before,engine.snapshot()):
  engine.state.revision+=1
  history.append({"op":"context","context":context.duplicate(true)})
 return true
