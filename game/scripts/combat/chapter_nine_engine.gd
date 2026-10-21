class_name ChapterNineEncounterEngine
extends RefCounted
## A scene controller, deliberately not a CombatEngine subclass. No battle start,
## mana refill, stance, passive, cooldown, kill or item machinery is invoked.
const HERO := "char_liang_xiao"
const IDS := ["well_soldier_1", "well_soldier_2"]
const DATA_PATH := "res://data/chapter_nine_encounters.json"
const K := 100.0 + 4.0 * 39.0 * 39.0 / 79.0
var state: Dictionary = {}
var entry_error := ""
var rules: Dictionary
var content: Dictionary

func _init(r: Dictionary, c: Dictionary) -> void:
 rules = r.duplicate(true); content = c.duplicate(true)

static func _whole(v: Variant, minimum: int = 0, maximum: int = 2147483647) -> bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v) == floor(float(v)) and v >= minimum and v <= maximum

static func _text(v: Variant) -> bool:
 return v is String or v is StringName

func start(config: Dictionary, party: Array) -> void:
 entry_error = ""
 var canonical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)).encounters.enc_ch09_well_disarm
 if not config.has_all(canonical.keys()): entry_error = "invalid_encounter"
 for key in canonical:
  if config.get(key) != canonical[key]: entry_error = "invalid_encounter"
 for key in config:
  if key not in canonical and key != "context": entry_error = "invalid_encounter"
 if not _valid_context(config.get("context")): entry_error = "invalid_context"
 if party.size() != 1 or not party[0] is Dictionary:
  entry_error = "solo_hero_required"
 else:
  var a: Dictionary = party[0]
  if not _text(a.get("id")) or a.id != HERO or a.get("team") != "party": entry_error = "solo_hero_required"
  for key in ["hp", "mp", "max_hp", "max_mp", "atk", "def", "spd"]:
   if not _whole(a.get(key), 1 if key in ["hp", "max_hp"] else 0): entry_error = "invalid_actor_number"
  if entry_error == "" and (a.hp > a.max_hp or a.mp > a.max_mp): entry_error = "invalid_resources"
  if not a.get("skills") is Array or not a.get("passives", []) is Array: entry_error = "invalid_slots"
 state = {"encounter":config.duplicate(true), "actors":party.duplicate(true), "round":1, "revision":0, "mode":"commands", "outcome":"", "commands":{}, "intents":[], "events":[], "k":K, "objective":{"phase":"ch09_blood_well", "pressure":2, "current_target":IDS[0], "observed":"", "pending":{}, "failure":"", "retired":[], "soldiers":[]}}
 if entry_error != "":
  state.mode = "finished"; state.outcome = "invalid"; state.objective.failure = entry_error
  return
 for index in range(2):
  state.objective.soldiers.append({"id":IDS[index], "name":"乱兵一" if index == 0 else "乱兵二", "retired":false, "position":config.retreat_routes[IDS[index]][0].duplicate(), "path":[config.retreat_routes[IDS[index]][0].duplicate()], "exit_route":config.retreat_routes[IDS[index]].duplicate(true)})
 _intent()

func _valid_context(c: Variant) -> bool:
 if not c is Dictionary: return false
 if not c.has_all(["chapter","current_token","revision","phase","scope","scene_id","map_id","objective_id","actors","items","world_objects","choices","authorizations","completed_receipts","leader_id","control_actor_id","rest_receipts"]): return false
 if not _whole(c.chapter, 9, 9) or not _whole(c.revision, 1): return false
 for key in ["current_token","phase","scope","scene_id","map_id","objective_id","leader_id","control_actor_id"]:
  if not _text(c[key]) or str(c[key]).is_empty(): return false
 if c.phase != "ch09_blood_well" or c.scene_id != "ch09_blood_well" or c.scope != "ch09_blood_well" or c.objective_id != "enc_ch09_well_disarm": return false
 if c.map_id != "map_ch09_changzhou_street": return false
 if c.leader_id != HERO or c.control_actor_id != HERO: return false
 for key in ["actors","items","world_objects","choices","completed_receipts"]:
  if not c[key] is Dictionary: return false
 for key in ["authorizations","rest_receipts"]:
  if not c[key] is Array: return false
 return "evt_ch09_blood_well_rest" in c.rest_receipts

func beat() -> int: return (int(state.round) - 1) % 2 + 1
func actor_by_id(id: String) -> Dictionary:
 for actor in state.actors:
  if actor.id == id: return actor
 return {}
func skill_cost(_actor: Dictionary, _skill: Dictionary) -> int: return 0
func snapshot() -> Dictionary: return state.duplicate(true)
func get_view() -> Dictionary:
 var result := snapshot()
 for actor in result.actors:
  if actor is Dictionary: actor.skills = []
 var positions: Dictionary={HERO:state.encounter.get("hero_position",[432,256]).duplicate()}
 var visible: Array=[HERO]
 var paths: Dictionary={}
 for soldier in state.objective.soldiers:
  positions[soldier.id]=soldier.position.duplicate()
  paths[soldier.id]=soldier.path.duplicate(true)
  if not soldier.retired: visible.append(soldier.id)
 result["world_state"]={"map_id":"map_ch09_changzhou_street","objective_id":"enc_ch09_well_disarm","player_position":positions[HERO].duplicate(),"control_actor_id":HERO,"actor_positions":positions,"visible_actor_ids":visible,"actor_paths":paths,"complete":state.outcome=="victory"}
 result.objective["summary"] = "威胁%d/2；奇数拍察兵刃，偶数拍对已观察的同一兵架刃推离。每次0气、一行动。" % state.objective.pressure
 return result
func _intent() -> void:
 state.intents = []
 if state.outcome != "": return
 state.intents.append({"actor_id":state.objective.current_target,"target_id":HERO,"intent_id":"well:%d" % state.round,"name":"举刀蓄势（0伤）；此拍察兵刃" if beat() == 1 else "落刀 130×1.30；架刃推离可取消", "executed":false,"cancelled":false})

func apply_input(action: Variant) -> Dictionary:
 if not action is Dictionary: return {"accepted":false,"error":"invalid_input_type"}
 if state.outcome != "": return {"accepted":false,"error":"not_accepting_input"}
 if not action.has_all(["actor_id","action_id"]): return {"accepted":false,"error":"missing_input_field"}
 for key in action:
  if key not in ["actor_id","action_id","value","revision","execute"]: return {"accepted":false,"error":"unexpected_field"}
 if not _text(action.actor_id) or not _text(action.action_id) or action.actor_id != HERO: return {"accepted":false,"error":"invalid_actor"}
 if action.has("execute") and (not action.execute is bool or action.action_id not in ["observe","disarm","wait"]): return {"accepted":false,"error":"invalid_execute"}
 if action.has("revision") and (not action.revision is int or action.revision != state.revision): return {"accepted":false,"error":"invalid_revision"}
 if action.action_id in ["cancel","retreat"]:
  if action.has("value"): return {"accepted":false,"error":"unexpected_value"}
  state.objective.pending = {}; state.commands = {}
  if action.action_id == "retreat": state.outcome = "defeat"; state.mode = "finished"; state.objective.failure = "retreated"
 elif action.action_id in ["observe","disarm","wait"]:
  if not _text(action.get("value")) or action.value not in IDS: return {"accepted":false,"error":"invalid_target"}
  if action.value in state.objective.retired: return {"accepted":false,"error":"retired_target"}
  # A wrong active target/timing is a real committed action, not a free guard.
  state.objective.pending = {"actor_id":HERO,"action_id":str(action.action_id),"value":str(action.value)}
 else: return {"accepted":false,"error":"scene_actions_only"}
 state.revision += 1
 if action.get("execute",false): resolve_round()
 return {"accepted":true}

func set_command(_actor: Variant, _skill: Variant, _target: Variant, _revision: Variant = -1) -> String:
 return "scene_actions_only"
func can_resolve() -> bool: return state.outcome == "" and not state.objective.pending.is_empty()
func resolve_round() -> bool:
 if not can_resolve(): return false
 var o: Dictionary = state.objective
 var action: Dictionary = o.pending
 var target: String = o.current_target
 var hit := beat() == 2
 if beat() == 1:
  o.observed = target if action.action_id == "observe" and action.value == target else ""
  _event("observed" if o.observed != "" else "missed_observation", target, 0)
 elif action.action_id == "disarm" and action.value == target and o.observed == target:
  var soldier: Dictionary = o.soldiers[IDS.find(target)]
  for point in soldier.exit_route.slice(1):
   soldier.position = point.duplicate(); soldier.path.append(point.duplicate())
   _event("retreat_step",target,0,{"position":point.duplicate()})
  soldier.retired = true; o.retired.append(target); o.pressure -= 1; hit = false
  state.intents[0].cancelled = true
  _event("nonlethal_retirement",target,0)
  if o.pressure == 0: state.outcome = "victory"; state.mode = "finished"
  else: o.current_target = IDS[1]
 if beat() == 2:
  o.observed = ""
  if hit:
   var hero := actor_by_id(HERO)
   var amount := maxi(1,int(floor(130.0 * 1.30 * K / (K + float(hero.def)))))
   var loss := mini(int(hero.hp),amount)
   hero.hp -= loss
   _event("damage",target,loss,{"raw":169.0,"damage":amount,"k":K,"def":hero.def})
   if hero.hp == 0: state.outcome = "defeat"; state.mode = "finished"; o.failure = "liang_fallen"
 state.intents[0].executed = true
 o.pending = {}; state.commands = {}; state.round += 1; state.revision += 1
 _intent()
 return true
func _event(kind: String, target: String, amount: int, detail: Dictionary = {}) -> void:
 state.events.append({"round":state.round,"type":kind,"source":HERO if kind != "damage" else target,"target":target if kind != "damage" else HERO,"amount":amount,"detail":detail})
