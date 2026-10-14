class_name ChapterFiveCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## Chapter-specific deterministic objectives. Candidate timings are recorded in data.
const HERO := "char_liang_xiao"
const LIU := "char_liu_yingying"
const YUN := "char_yun_shu"
const DATA_PATH := "res://data/chapter_five_encounters.json"
const ACTION_NAMES := {"turn_helm":"拉动船舵","lure_second":"引入二连环","break_second":"拆二连环锁","lure_third":"引入三连环","break_third":"拆三连环锁","board_boat":"登轻舟","path_read":"辨析生门","mark_gate":"标出生门"}
var combo_executing := false

func _init(rule_data: Dictionary, runtime_data: Dictionary) -> void:
	super(rule_data,runtime_data)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	content.skills.merge(data.skills,true)


func _tick_pain() -> void:
	var o: Dictionary = state.objective
	if int(o.dot_round) == int(state.round): return
	o.dot_round = int(state.round)
	for target in state.actors:
		if not alive(target): continue
		for effect in target.statuses:
			if effect.kind == "luo_pain" and int(effect.starts) <= int(state.round) and int(effect.expires) >= int(state.round):
				var amount := int(floor(float(effect.value)))
				if target.get("boss",false): amount = mini(amount,int(floor(float(target.max_hp)*0.01)))
				var lost := _dot_damage(actor_by_id(effect.source),target,amount,"luo_pain")
				_event("pain_tick",effect.source,target.id,lost)


func _n01(actor: Dictionary) -> bool:
	return str(actor.get("internal_skill","")) == "LYY_N01" or "LYY_N01" in actor.get("passives",[])


func skill_cost(actor: Dictionary, skill: Dictionary) -> int:
	var cost := super.skill_cost(actor,skill)
	if int(state.get("round",1)) == 1 and "LYY_P01" in actor.get("passives",[]) and not actor.get("p01_spent",false): cost = int(ceil(float(cost)*0.5))
	return int(ceil(float(cost)*(1.0+_status_value(actor,"mana_cost_up"))))


func _pay(actor: Dictionary, skill_id: String, skill: Dictionary) -> void:
	super._pay(actor,skill_id,skill)
	if actor.id == LIU: actor.p01_spent = true


func _speed(actor: Dictionary, modifier: int, skill: Dictionary = {}) -> int:
	var result := super._speed(actor,modifier,skill)
	var generic_loss := _status_value(actor,"speed_down")
	var ice_loss := _status_value(actor,"a04_speed_down")
	if ice_loss>generic_loss:
		var gain := _status_value(actor,"speed_up")
		result += int(floor(float(actor.spd)*(1.0+gain-ice_loss)))-int(floor(float(actor.spd)*(1.0+gain-generic_loss)))
	if _n01(actor): result += int(floor(float(actor.spd)*0.1))
	if _status_value(actor,"imbalance") > 0: result -= 15
	if int(state.round) == 1 and "LYY_P01" in actor.get("passives",[]) and not skill.is_empty() and not skill.get("prepare",false): result += 1000000
	return result


func _reduction(actor: Dictionary) -> float:
	var result := super._reduction(actor)
	if actor.stance.get("kind","") == "liu_induce": result = maxf(result,0.35)
	if actor.get("n01_shield",false): result = maxf(result,0.1)
	return result


func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
	var original_def: float = float(target.def)
	target.def = int(floor(float(original_def)*(1.0-_status_value(target,"defense_down"))))
	var result := super._branch(source,target,raw,channel,action_id)
	target.def = original_def
	if result > 0 and target.get("n01_shield",false): target.n01_shield = false
	return result


func _view_choice(view: Dictionary,action: Dictionary,label: String) -> void:
	if input_error(action) != "": return
	action["revision"] = int(state.revision)
	view.objective.available_actions.append({"label":label,"input":action})


func _execute_command(actor: Dictionary, command: Dictionary) -> void:
	if actor.id==LIU and command.target_id==state.objective.marked_gate and command.skill_id in ["normal_attack","LYY_A03"] and command.target_id not in state.objective.gates:
		state.objective.gates.append(command.target_id)
		_event("gate_broken",actor.id,command.target_id,1)
	if command.skill_id == "LYY_A03":
		_pay(actor,command.skill_id,content.skills.LYY_A03)
		_event("action",actor.id,command.target_id,0,{"skill_id":command.skill_id})
		var critical := 1.0
		if _status_value(actor,"mingxin")>0:
			critical = 1.5
			actor.statuses = actor.statuses.filter(func(effect: Dictionary) -> bool: return effect.kind != "mingxin")
			_event("mingxin_consumed",actor.id,command.target_id)
		for target in state.actors:
			if target.team != "enemy" or not alive(target) or target.get("row","front") != "front": continue
			_damage_action(actor,target,1.25*critical,false,"normal",command.skill_id)
			if _n01(actor): target.statuses.append({"kind":"speed_down","value":0.1,"starts":int(state.round)+1,"expires":int(state.round)+1})
			_apply_status(target,"imbalance",1,2)
			_apply_status(target,"defense_down",0.2,2)
			for intent in state.intents:
				if intent.actor_id == target.id and not intent.executed and not intent.cancelled and ("disarm" in intent.tags or "interrupt" in intent.tags) and _break(actor,target,intent): intent.cancelled = true
		return
	if command.skill_id == "LYY_A04":
		var target := _legal_target(command.target_id,"enemy")
		if not alive(target): return
		_pay(actor,command.skill_id,content.skills.LYY_A04)
		_event("action",actor.id,target.id,0,{"skill_id":command.skill_id})
		var critical := 1.5 if _status_value(actor,"mingxin")>0 else 1.0
		actor.statuses=actor.statuses.filter(func(e): return e.kind != "mingxin")
		_damage_action(actor,target,1.60*critical,false,"normal",command.skill_id)
		for kind in ["a04_speed_down","mana_cost_up"]:
			if kind=="mana_cost_up" and target.get("boss",false): continue
			target.statuses=target.statuses.filter(func(e): return e.kind != kind)
			target.statuses.append({"kind":kind,"value":0.25 if kind=="a04_speed_down" else 0.5,"starts":int(state.round)+1,"expires":int(state.round)+2})
		for intent in state.intents:
			if intent.actor_id==target.id and not intent.executed and not intent.cancelled and ("internal" in intent.tags or "acupoint" in intent.tags):
				if _break(actor,target,intent): intent.cancelled=true
		return
	# Core retargets an enemy invalidated by the faster teammate. Apply skill
	# riders to that same living target, never the now-defeated original.
	if content.skills[command.skill_id].target == "enemy" and not alive(actor_by_id(command.target_id)):
		for candidate in state.actors:
			if candidate.team == "enemy" and alive(candidate):
				command = command.duplicate(true)
				command.target_id = candidate.id
				break
	super._execute_command(actor,command)
	if command.skill_id == "LYY_A02":
		var target := actor_by_id(command.target_id)
		if alive(target):
			_apply_status(target,"speed_down",0.15,2)
			var potency := float(actor.atk)*0.3
			for effect in target.statuses:
				if effect.kind == "luo_pain": potency = maxf(potency,float(effect.value))
			target.statuses = target.statuses.filter(func(effect: Dictionary) -> bool: return effect.kind != "luo_pain")
			# Explicit delayed-DOT ruling: next two round starts, refresh not stack.
			target.statuses.append({"kind":"luo_pain","value":potency,"starts":int(state.round)+1,"expires":int(state.round)+2,"source":actor.id})
			for intent in state.intents:
				if intent.actor_id == target.id and not intent.executed and not intent.cancelled and "internal" in intent.tags and _break(actor,target,intent): intent.cancelled = true
	if actor.id == LIU and _n01(actor) and command.skill_id in ["normal_attack","LYY_A02"]:
		var target := actor_by_id(command.target_id)
		if alive(target): target.statuses.append({"kind":"speed_down","value":0.1,"starts":int(state.round)+1,"expires":int(state.round)+1})


func begin_round() -> void:
	if state.mode not in ["new","round_end"] or state.outcome != "": return
	if not state.has("objective"):
		state.objective = {"phase":1,"phase_start":1,"pending":{},"cooperation":0,"reserved":0,"cooperation_round":0,"trial":false,"combo_refunded":false,"combo_used":false,"cable_cut":false,"helm_round":0,"lure":"","locks":[],"boarded":[],"path_reads":0,"path_rounds":[],"marked_gate":"","gates":[],"failure":"","dot_round":0,"enemy_actions":0,"fire_round":0}
		for actor in state.actors:
			if actor.id == LIU:
				actor["n01_shield"] = _n01(actor)
				actor["p01_spent"] = false
			if actor.team == "party" and "CO_01" not in actor.skills: actor.skills.append("CO_01")
		if state.encounter.kind == "b03":
			var h := actor_by_id(HERO)
			h.max_mp = 0; h.mp = 0; h.martial_disabled = true
	# Preparation stances expire with their round; persistent dated statuses remain.
	for actor in state.actors: actor.stance = {}
	_tick_pain()
	_tick_bleed()
	super.begin_round()
	_check_outcome()
	if state.outcome != "": state.mode="finished"; return
	state.objective.pending = {}
	state.objective.marked_gate = ""
	if state.encounter.kind == "b02" and int(state.round) >= 2 and not state.objective.trial:
		state.objective.trial = true
		state.objective.cooperation = maxi(2,int(state.objective.cooperation))
		_event("combo_trial",HERO,LIU,2)

func _tick_bleed() -> void:
	for actor in state.actors:
		for effect in actor.statuses:
			if effect.kind == "bleed" and int(effect.starts) <= int(state.round) and int(effect.expires) >= int(state.round):
				var lost := _dot_damage(actor_by_id(effect.source),actor,int(effect.value),"bleed")
				_event("bleed_tick",effect.source,actor.id,lost)

func _gain_cooperation(reason: String) -> void:
	var o: Dictionary = state.objective
	if combo_executing or int(o.cooperation_round) == int(state.round) or int(o.cooperation)+int(o.reserved) >= 3: return
	o.cooperation += 1; o.cooperation_round = int(state.round)
	_event("cooperation","","",1,{"reason":reason})

func _break(source: Dictionary,target: Dictionary,intent: Dictionary) -> bool:
	if source.id==LIU and target.id==YUN and "disarm" in intent.tags and not combo_executing and int(state.objective.helm_round)!=int(state.round): return false
	var result := super._break(source,target,intent)
	if result:
		_gain_cooperation("break")
		if source.id==LIU and target.id==YUN and "disarm" in intent.tags and int(state.objective.helm_round)==int(state.round): target.statuses = target.statuses.filter(func(e): return e.kind != "damage_reduction")
	return result

func gain_mana(actor: Dictionary,requested: int,reason: String) -> void:
	super.gain_mana(actor,requested,reason)
	if reason == "successful_guard": _gain_cooperation("guard")

func _combo_eligible() -> bool:
	if state.encounter.kind != "b02" or not (state.objective.trial or state.encounter.get("context",{}).get("combo_unlocked",false)): return false
	for id in [HERO,LIU]:
		var a := actor_by_id(id)
		if not alive(a) or not a.get("controllable",true) or a.get("martial_disabled",false) or _status_value(a,"stun")>0 or _status_value(a,"sealed")>0: return false
	return true

func validate_command(actor_id: String,skill_id: String,target_id: String) -> String:
	if skill_id == "CO_01":
		if state.mode != "commands" or actor_id not in [HERO,LIU] or not _combo_eligible(): return "combo_unavailable"
		if int(state.objective.cooperation)+int(state.objective.reserved)<2: return "insufficient_cooperation"
		var target := actor_by_id(target_id)
		return "" if alive(target) and target.team == "enemy" else "invalid_target"
	var error := super.validate_command(actor_id,skill_id,target_id)
	if error != "": return error
	if actor_id == HERO and state.encounter.kind == "b03" and skill_id not in ["observe","self_guard","objective_action"]: return "story_restricted"
	if skill_id == "objective_action" and not state.objective.pending.has(actor_id): return "objective_input_required"
	if skill_id.begins_with("LYY_") and actor_id != LIU: return "skill_owner_mismatch"
	if skill_id == "LYY_A03" and actor_by_id(target_id).get("row","front") != "front": return "front_row_required"
	return ""

func set_command(actor_id: String,skill_id: String,target_id: String,revision: int = -1) -> String:
	if revision != -1 and revision != int(state.revision): return "stale_revision"
	var error := validate_command(actor_id,skill_id,target_id)
	if error != "": return error
	var o: Dictionary = state.objective
	if skill_id == "CO_01":
		if int(o.reserved) == 0: o.cooperation -= 2; o.reserved = 2
		o.combo_refunded = false
		for id in [HERO,LIU]:
			state.commands[id] = {"actor_id":id,"skill_id":skill_id,"target_id":target_id}
			o.pending.erase(id)
		state.revision += 1
		return ""
	if int(o.reserved)>0:
		_refund_combo(false)
		state.commands.erase(HERO); state.commands.erase(LIU)
	return super.set_command(actor_id,skill_id,target_id,revision)

func _refund_combo(fallback: bool) -> void:
	var o: Dictionary = state.objective
	if int(o.reserved) == 0 or o.combo_refunded: return
	o.cooperation += o.reserved; o.reserved = 0; o.combo_refunded = true
	_event("combo_refund","","",2)
	if fallback:
		for id in [HERO,LIU]:
			var a := actor_by_id(id)
			if alive(a) and a.get("controllable",true) and _status_value(a,"stun")==0 and _status_value(a,"sealed")==0: a.stance = {"kind":"self_guard","target_id":id,"tokens":1,"skill_id":"self_guard"}

func input_error(action: Dictionary) -> String:
	if state.mode != "commands" or state.outcome != "": return "not_accepting_input"
	for key in action:
		if key not in ["actor_id","action_id","target","revision"]: return "unexpected_input_field"
	if action.has("revision") and (not _whole(action.revision) or int(action.revision)!=int(state.revision)): return "stale_revision"
	if not action.get("actor_id") is String or not action.get("action_id") is String: return "invalid_action"
	if action.has("target") and action.action_id != "mark_gate": return "unexpected_target"
	if action.actor_id not in [HERO,LIU] or not alive(actor_by_id(action.actor_id)) or not actor_by_id(action.actor_id).get("controllable",true): return "actor_unavailable"
	var o: Dictionary = state.objective
	if state.encounter.kind == "b03":
		if action.actor_id != HERO: return "liang_required"
		if action.action_id == "path_read": return "" if int(state.round)<=2 and int(state.round) not in o.path_rounds else "path_window_closed"
		if action.action_id == "mark_gate":
			if int(o.phase)!=2 or action.get("target","") not in ["gate_east","gate_west"] or action.target in o.gates: return "gate_unavailable"
			return ""
		return "invalid_action"
	match str(action.action_id):
		"turn_helm": return "" if action.actor_id == HERO else "liang_required"
		"lure_second": return "" if int(o.phase)==2 and o.lure == "" else "lure_unavailable"
		"break_second": return "" if int(o.phase)==2 and o.lure == "second" and "second" not in o.locks else "lock_not_exposed"
		"lure_third": return "" if int(o.phase)==2 and "second" in o.locks and o.lure == "second" else "lure_unavailable"
		"break_third": return "" if int(o.phase)==2 and o.lure == "third" and "third" not in o.locks else "lock_not_exposed"
		"board_boat": return "" if o.locks.size()==2 and o.cable_cut and action.actor_id not in o.boarded else "boat_not_ready"
	return "invalid_action"

func apply_input(action: Dictionary) -> Dictionary:
	var error := input_error(action)
	if error != "": return {"accepted":false,"error":error}
	var clean := action.duplicate(true); clean.erase("revision")
	var previous: Dictionary = state.objective.pending.duplicate(true)
	state.objective.pending[action.actor_id] = clean
	error = set_command(action.actor_id,"objective_action",action.actor_id)
	if error != "": state.objective.pending = previous
	return {"accepted":error == "","error":error}

func _objective_action(actor: Dictionary) -> void:
	var o: Dictionary = state.objective
	var action: Dictionary = o.pending.get(actor.id,{})
	_event("objective_input",actor.id,"",0,action)
	match str(action.get("action_id","")):
		"turn_helm": o.helm_round = int(state.round)
		"lure_second": o.lure = "second"
		"break_second":
			if "second" not in o.locks: o.locks.append("second")
		"lure_third": o.lure = "third"
		"break_third":
			if "third" not in o.locks: o.locks.append("third")
		"board_boat":
			if actor.id not in o.boarded: o.boarded.append(actor.id)
		"path_read":
			if int(state.round) not in o.path_rounds: o.path_reads += 1; o.path_rounds.append(int(state.round))
		"mark_gate": o.marked_gate = action.target

func _execute_combo(target_id: String) -> void:
	if not _combo_eligible(): _refund_combo(true); return
	var o: Dictionary = state.objective
	o.reserved = 0; o.combo_used = true; o.cable_cut = true
	combo_executing = true
	var h := actor_by_id(HERO); var l := actor_by_id(LIU)
	var raw := 2.85*(float(h.atk)+float(l.atk))/2.0
	_event("combo_executed",HERO,target_id,2)
	for a in [h,l]: _apply_status(a,"damage_reduction",0.2,1)
	for target in state.actors:
		if target.team != "enemy" or not alive(target): continue
		var defense := int(target.def)
		target.def = float(defense)*0.65
		var value := raw*(1.35 if target.id==target_id else 1.0)
		if int(target.vulnerable_through)>=int(state.round): value *= 1.0+minf(0.2+_status_value(target,"posuan"),float(rules.limits.vulnerability))
		_branch(h,target,value,"combo","CO_01")
		target.def = defense
		_apply_status(target,"defense_down",0.35,2)
		for intent in state.intents:
			if intent.actor_id==target.id and not intent.executed and not intent.cancelled and ("disarm" in intent.tags or "induce" in intent.tags):
				if _break(h,target,intent):
					intent.cancelled = true
					if "disarm" in intent.tags: target.statuses = target.statuses.filter(func(e): return e.kind != "damage_reduction")
	combo_executing = false

func _execute_intent(actor: Dictionary,intent: Dictionary) -> void:
	if intent.cancelled: intent.executed = true; return
	state.objective.enemy_actions += 1
	if actor.id in ["gate_east","gate_west"]:
		intent.hits = [0.35] if int(state.objective.fire_round)!=int(state.round) else []
		state.objective.fire_round=int(state.round)
	if intent.get("kind","") == "armor":
		intent.executed = true
		_apply_status(actor,"damage_reduction",0.4,2)
		_event("armor",actor.id,"",40)
		return
	var liu := actor_by_id(LIU)
	if alive(liu) and liu.stance.get("kind","")=="liu_induce" and liu.stance.target_id==actor.id and int(liu.stance.tokens)>0 and intent.get("redirectable",false) and not intent.get("aoe",false):
		intent.target_id = LIU; liu.stance.tokens = 0
		_event("redirected",LIU,actor.id)
		if "induce" in intent.tags and _break(liu,actor,intent):
			intent.executed = true; _event("induced_miss",LIU,actor.id)
			if _n01(liu): gain_mana(liu,4,"cold_river_induce")
			if int(liu.get("skill_ranks",{}).get("LYY_A01",1))>=2: _damage_action(liu,actor,1.1,false,"counter","LYY_A01")
			return
	if actor.id==YUN and intent.get("aoe",false):
		intent.executed=true
		_event("enemy_action",actor.id,"",0,{"target_row":"front"})
		for target in state.actors:
			if target.team!="party" or not alive(target) or target.get("row","front")!="front": continue
			for multiplier in intent.get("hits",[]): _damage_action(actor,target,float(multiplier)*(0.35 if intent.get("weakened",false) else 1.0),true,"enemy",intent.intent_id)
		return
	var before: Dictionary = {}
	for a in state.actors:
		if a.team=="party": before[a.id]=int(a.hp)
	super._execute_intent(actor,intent)
	if intent.get("bleed",false):
		for a in state.actors:
			if a.team=="party" and a.id==intent.get("target_id","") and alive(a) and int(a.hp)<int(before[a.id]):
				a.statuses = a.statuses.filter(func(e): return e.kind != "bleed")
				a.statuses.append({"kind":"bleed","value":int(floor(float(actor.atk)*0.15)),"source":actor.id,"starts":int(state.round)+1,"expires":int(state.round)+2})

func _lose_hp(source: Dictionary,target: Dictionary,amount: int) -> int:
	if target.id == YUN:
		# Phase transition and escape, never an HP-kill receipt.
		amount = mini(amount,maxi(0,int(target.hp)-(870 if int(state.objective.phase)==1 else 1)))
	return super._lose_hp(source,target,amount)

func _check_outcome() -> void:
	if state.outcome != "" or not state.has("objective"): return
	var o: Dictionary = state.objective
	if not alive(actor_by_id(HERO)) or not alive(actor_by_id(LIU)):
		_refund_combo(true)
		o.failure = "party_member_exhausted"; state.outcome = "defeat"
	elif state.mode == "round_end":
		if state.encounter.kind == "b02":
			if int(o.phase)==1 and int(actor_by_id(YUN).hp)<=870:
				o.phase = 2; o.phase_start = int(state.round)+1
				var y := actor_by_id(YUN)
				y.hp=1800; y.max_hp=1800; y.max_mp=180; y.atk=110; y.def=62; y.spd=32
				_event("phase_changed",YUN,"",2)
			elif int(o.phase)==2:
				if o.boarded.size()==2 and o.locks.size()==2 and o.cable_cut: state.outcome="victory"
				elif int(state.round)-int(o.phase_start)+1>=5: o.failure="sinking_deadline"; state.outcome="defeat"
			if int(state.round)>=int(state.encounter.max_rounds) and state.outcome=="": o.failure="time_expired"; state.outcome="defeat"
		else:
			if int(state.round)==2:
				if int(o.path_reads)!=2: o.failure="path_not_read"; state.outcome="defeat"
				else: _open_gates()
			if int(state.round)>=4:
				if o.gates.size()==2: state.outcome="victory"
				else: o.failure="gates_not_broken"; state.outcome="defeat"
	if state.outcome!="": _event("outcome","","",0,{"result":state.outcome,"reason":o.failure})

func _open_gates() -> void:
	state.objective.phase=2; state.objective.phase_start=3
	for a in state.actors:
		if a.team=="enemy": a.defeated=true
	for id in ["gate_east","gate_west"]:
		var gate := {"id":id,"name":"东生门" if id=="gate_east" else "西生门","team":"enemy","hp":1000,"max_hp":1000,"mp":0,"max_mp":0,"atk":115,"def":70,"spd":30,"protection_rounds":1,"boss":true,"row":"front","ready":{},"statuses":[],"mana_gained":0,"counter_count":0,"guard_rewarded":false,"break_rewarded":false,"last_break":-1,"protected_through":-1,"vulnerable_through":-1,"defeated":false,"stance":{},"passive_started":false,"rotation":[{"name":"两门共用地火·每轮合计候选0.35倍全体","hits":[0.35] if id=="gate_east" else [],"tags":[],"target_id":HERO,"aoe":true}]}
		state.actors.append(gate)
	_event("phase_changed","","",2)

func get_view() -> Dictionary:
	var view := super.get_view()
	view["skill_data"] = content.skills.duplicate(true)
	view["skill_costs"] = {}; view["legal_commands"] = {}
	view.objective["available_actions"] = []
	for a in state.actors:
		if a.team!="party": continue
		view.skill_costs[a.id]={}; view.legal_commands[a.id]=[]
		for skill_id in a.skills:
			if not content.skills.has(skill_id): continue
			view.skill_costs[a.id][skill_id]=skill_cost(a,content.skills[skill_id])
			for target in state.actors:
				if skill_id!="objective_action" and validate_command(a.id,skill_id,target.id)=="": view.legal_commands[a.id].append({"skill_id":skill_id,"target_id":target.id})
		for action_id in ACTION_NAMES:
			if action_id=="mark_gate":
				for gate in ["gate_east","gate_west"]: _view_choice(view,{"actor_id":a.id,"action_id":action_id,"target":gate},ACTION_NAMES[action_id]+gate)
			else: _view_choice(view,{"actor_id":a.id,"action_id":action_id},ACTION_NAMES[action_id])
	view.objective["summary"]="B02：第2轮前试用合招补协力至2；合招占双方行动，削断牵引缆。云殊60%血转二阶段；二阶段5轮依次引二环、拆二锁、引三环、拆三锁、双方登舟，每项占正常行动。云殊与两剑手面板、伤害不因机关输入降低。拉舵与柳破器同轮可拆罡气。\nB03：梁前两轮辨路，3/4轮标不同生门，柳同轮普攻或破器命中对应门；辨路/标门在准备层占正常行动。双方存活到第4轮末。梁MP上限0，禁武学/合招；观势不回超出上限的气。\n协力容量3，普通破招/援护每轮合计最多1；合招预留2仍占容量，取消只退一次，从取消时转自守。章5敌人未定义部分参数明确标候选，非原著定值。"
	return view

func resolve_round() -> bool:
	if not can_resolve(): return false
	state.mode = "preparation"
	var queue: Array = []
	for index in range(state.actors.size()):
		var actor: Dictionary = state.actors[index]
		if not alive(actor) or (actor.team == "party" and not actor.get("controllable", true)): continue
		if actor.team == "party":
			var command: Dictionary = state.commands[actor.id]
			var skill: Dictionary = content.skills[command.skill_id]
			if command.skill_id == "CO_01":
				if actor.id == HERO: queue.append({"actor_id":HERO,"command":command,"enemy":false,"combo":true,"speed":mini(_speed(actor_by_id(HERO),0),_speed(actor_by_id(LIU),0))+15,"order":index})
				continue
			if command.skill_id == "objective_action":
				_objective_action(actor)
				continue
			if skill.get("prepare", false):
				_pay(actor, command.skill_id, skill)
				actor.stance = {"kind": skill.kind, "target_id": command.target_id, "tokens": 1, "skill_id": command.skill_id}
				_event("prepared", actor.id, command.target_id)
				if skill.kind in ["self_guard", "guard"]: gain_mana(actor, int(rules.mana.guard_gain), "guard")
				if skill.kind != "counter": continue
			queue.append({"actor_id": actor.id, "command": command, "enemy": false, "speed": _speed(actor, int(skill.get("speed", 0)), skill), "order": index})
		else:
			for intent in state.intents:
				if intent.actor_id == actor.id:
					queue.append({"actor_id": actor.id, "command": intent, "enemy": true, "speed": _speed(actor, int(intent.get("speed", 0))), "order": index})
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.speed > b.speed if a.speed != b.speed else a.order < b.order)
	state.mode = "executing"
	for item in queue:
		var actor := actor_by_id(item.actor_id)
		if item.get("combo",false):
			_execute_combo(item.command.target_id)
			_check_outcome()
			if state.outcome != "": break
			continue
		if not alive(actor): continue
		if item.enemy:
			_execute_intent(actor, item.command)
		else:
			_execute_command(actor, item.command)
		_check_outcome()
		if state.outcome != "": break
	# A cancelled/defeated enemy must not leave a counter's reserved normal action stranded.
	if state.outcome == "":
		for actor in state.actors:
			if alive(actor) and actor.stance.get("kind", "") == "counter" and int(actor.stance.tokens) > 0:
				_counter(actor, actor_by_id(actor.stance.target_id), false)
	state.mode = "round_end"
	_event("round_ended")
	_check_outcome()
	state.round += 1
	if state.outcome == "": begin_round()
	else: state.mode = "finished"
	return true


func _damage_action(source: Dictionary,target: Dictionary,multiplier: float,aoe: bool,channel: String,action_id: String,guard: Dictionary = {}) -> void:
	var fixed := 0.0
	for intent in state.intents:
		if intent.intent_id==action_id: fixed=float(intent.get("fixed_raw",0))
	if fixed<=0:
		super._damage_action(source,target,multiplier,aoe,channel,action_id,guard)
		return
	var share := float(rules.guard.share) if not guard.is_empty() and alive(guard) and not aoe else 0.0
	_branch(source,target,fixed*(1.0-share),channel,action_id)
	if share>0:
		var loss := _branch(source,guard,fixed*share,"guard",action_id)
		if loss>0 and not guard.guard_rewarded:
			guard.guard_rewarded=true
			gain_mana(guard,int(rules.mana.successful_guard_gain),"successful_guard")

func _dot_damage(source: Dictionary,target: Dictionary,amount: int,kind: String) -> int:
	# DOT is already expressed damage, not a second ATK/DEF action. Its source
	# cap precedes the single highest protection; shields are consumed normally.
	if amount<=0 or not alive(target): return 0
	var damage := maxi(1,int(floor(float(amount)*(1.0-_reduction(target)))))
	var shield := mini(int(target.get("shield",0)),damage)
	target["shield"]=int(target.get("shield",0))-shield
	var lost := _lose_hp(source,target,damage-shield)
	_event("damage",source.id,target.id,lost,{"raw":amount,"damage":damage,"shield_loss":shield,"channel":"dot","action_id":kind})
	if damage>0 and target.get("n01_shield",false): target.n01_shield=false
	return lost
