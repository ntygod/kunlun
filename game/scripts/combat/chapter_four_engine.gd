class_name ChapterFourCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## Source multipliers stay in the shared deterministic core; chapter objectives
## consume the same two normal action slots, never a separate success button.
const HERO := "char_liang_xiao"
const LIU := "char_liu_yingying"
const DATA_PATH := "res://data/chapter_four_encounters.json"
const POINTS := {"table":Vector2i(1,1),"lamp":Vector2i(1,0),"jar":Vector2i(2,1),"side":Vector2i(2,2),"window":Vector2i(3,1),"fire":Vector2i(0,1),"fire_side":Vector2i(0,2)}
const EDGES := {"table":["lamp","jar","side"],"lamp":["table","window"],"jar":["table","window","side"],"side":["table","jar","window"],"window":["lamp","jar","side"],"fire":["fire_side","table"],"fire_side":["fire","table"]}
const NAMES := {"table":"桌后","lamp":"灯架","jar":"酒坛","side":"侧廊","window":"窗前/账箱","fire":"火筒西侧","fire_side":"火筒南侧"}
const ACTION_NAMES := {"drop_lamp":"击落油灯","spill_oil":"软索翻酒坛","clear_civilians":"引平民离火区","clear_window":"清理窗前阻物","cover":"掩护同伴","secure_anchor":"挂索突围","disarm":"近身夺械","take_documents":"取回治水原图"}

func _init(rule_data: Dictionary, runtime_data: Dictionary) -> void:
	super(rule_data,runtime_data)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	content.skills.merge(data.skills,true)

func begin_round() -> void:
	if not state.has("objective"):
		state.objective = {"pending":{},"positions":{HERO:"table",LIU:"table"},"movement":{},"environment_used":"","smoke_through":0,"oil_cells":[],"civilians_clear":false,"window_clear":false,"anchor_secured":false,"anchor_round":0,"cover_round":0,"enemy_actions":0,"documents_taken":false,"failure":"","dot_round":0,"distracted":{}}
		for actor in state.actors:
			if actor.team == "enemy": state.objective.positions[actor.id] = actor.get("position","window")
			if actor.id == LIU:
				actor["n01_shield"] = _n01(actor)
				actor["p01_spent"] = false
				if state.encounter.get("context",{}).get("initial_mingxin_on_liu",false): _apply_status(actor,"mingxin",1,99999999)
	_tick_pain()
	super.begin_round()
	if state.mode != "commands": return
	state.objective.pending = {}
	for intent in state.intents:
		if not actor_by_id(intent.actor_id).get("weapon",true): intent.name = "徒手拦挡：%.2f倍，仍沿通路追击（已夺械，不能拦截图纸）" % float(state.encounter.unarmed_multiplier)
		intent.name += "（位置：%s）" % NAMES.get(state.objective.positions[intent.actor_id],"")

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
				var lost := _lose_hp(actor_by_id(effect.source),target,amount)
				_event("pain_tick",effect.source,target.id,lost)

func _n01(actor: Dictionary) -> bool:
	return str(actor.get("internal_skill","")) == "LYY_N01" or "LYY_N01" in actor.get("passives",[])

func skill_cost(actor: Dictionary, skill: Dictionary) -> int:
	var cost := super.skill_cost(actor,skill)
	if int(state.get("round",1)) == 1 and "LYY_P01" in actor.get("passives",[]) and not actor.get("p01_spent",false): cost = int(ceil(float(cost)*0.5))
	return cost

func _pay(actor: Dictionary, skill_id: String, skill: Dictionary) -> void:
	super._pay(actor,skill_id,skill)
	if actor.id == LIU: actor.p01_spent = true

func _speed(actor: Dictionary, modifier: int, skill: Dictionary = {}) -> int:
	var result := super._speed(actor,modifier,skill)
	if _n01(actor): result += int(floor(float(actor.spd)*0.1))
	if _status_value(actor,"imbalance") > 0: result -= 15
	if int(state.round) == 1 and "LYY_P01" in actor.get("passives",[]) and not skill.is_empty() and not skill.get("prepare",false): result += 1000000
	return result

func input_error(action: Dictionary) -> String:
	if state.mode != "commands" or state.outcome != "": return "not_accepting_input"
	for key in action:
		if key not in ["actor_id","action_id","destination","target","revision"]: return "unexpected_input_field"
	if action.has("revision") and (not _whole(action.revision) or int(action.revision) != int(state.revision)): return "stale_revision"
	if not action.get("actor_id") is String or not action.get("action_id") is String: return "invalid_action"
	if action.has("destination") and action.action_id != "move": return "unexpected_destination"
	if action.has("target") and action.action_id != "disarm": return "unexpected_target"
	var actor := actor_by_id(action.actor_id)
	if not alive(actor) or actor.team != "party" or not actor.get("controllable",true): return "actor_unavailable"
	var o: Dictionary = state.objective
	var position: String = o.positions[actor.id]
	match str(action.action_id):
		"move":
			if action.get("destination","") not in EDGES.get(position,[]): return "not_adjacent"
			if action.destination in ["fire","fire_side"]: return "not_party_route"
		"drop_lamp":
			if state.encounter.kind != "tavern_escape" or actor.id != HERO or position != "lamp": return "lamp_position_required"
			if state.encounter.get("context",{}).get("environment_method","lamp") != "lamp": return "unchosen_environment"
			if o.environment_used != "": return "environment_already_used"
		"spill_oil":
			if state.encounter.kind != "tavern_escape" or actor.id != LIU or position != "jar": return "jar_position_required"
			if state.encounter.get("context",{}).get("environment_method","lamp") != "oil": return "unchosen_environment"
			if o.environment_used != "": return "environment_already_used"
		"clear_civilians":
			if state.encounter.kind != "tavern_escape" or position != "side" or o.civilians_clear: return "civilian_exit_required"
		"clear_window":
			if state.encounter.kind != "tavern_escape" or position != "window" or o.environment_used == "" or o.window_clear: return "window_access_required"
		"cover":
			if state.encounter.kind != "tavern_escape" or actor.id != HERO or position != "window": return "liang_at_window_required"
		"secure_anchor":
			if state.encounter.kind != "tavern_escape" or actor.id != LIU or position != "window" or not o.window_clear or not o.civilians_clear: return "anchor_not_ready"
		"disarm":
			if state.encounter.kind != "r02_reclaim": return "wrong_objective"
			var target := actor_by_id(str(action.get("target","")))
			if not alive(target) or target.team != "enemy" or not target.get("weapon",false): return "invalid_target"
			if _distance(position,o.positions[target.id]) > 1: return "not_in_reach"
		"take_documents":
			if state.encounter.kind != "r02_reclaim" or position != "window" or o.documents_taken: return "chest_position_required"
			if not _documents_safe(): return "guards_can_intercept"
		_: return "invalid_action"
	return ""

func apply_input(action: Dictionary) -> Dictionary:
	var error := input_error(action)
	if error != "": return {"accepted":false,"error":error}
	var normalized := action.duplicate(true)
	normalized.erase("revision")
	var actor: String = action.actor_id
	var previous: Dictionary = state.objective.pending.get(actor,{})
	state.objective.pending[actor] = normalized
	error = set_command(actor,"objective_action",actor)
	if error != "":
		state.objective.pending[actor] = previous
		return {"accepted":false,"error":error}
	if previous != normalized: state.revision += 1
	return {"accepted":true,"error":""}

func validate_command(actor_id: String, skill_id: String, target_id: String) -> String:
	var error := super.validate_command(actor_id,skill_id,target_id)
	if error != "": return error
	if skill_id == "objective_action" and not state.objective.pending.has(actor_id): return "objective_input_required"
	if skill_id.begins_with("LYY_") and actor_id != LIU: return "skill_owner_mismatch"
	if skill_id == "LYY_A03" and actor_by_id(target_id).get("row","front") != "front": return "front_row_required"
	return ""

func _distance(a: String,b: String) -> int:
	var delta: Vector2i = POINTS[a]-POINTS[b]
	return absi(delta.x)+absi(delta.y)

func _move(actor: Dictionary,destination: String) -> void:
	var o: Dictionary = state.objective
	var cost := 2 if destination in o.oil_cells else 1
	var movement: Dictionary = o.movement.get(actor.id,{"destination":"","spent":0})
	if movement.destination != destination: movement = {"destination":destination,"spent":0}
	movement.spent += 1
	if int(movement.spent) >= cost:
		o.positions[actor.id] = destination
		o.movement.erase(actor.id)
	else: o.movement[actor.id] = movement
	_event("movement",actor.id,"",1,{"destination":destination,"cost":cost,"arrived":int(movement.spent)>=cost})

func _execute_command(actor: Dictionary, command: Dictionary) -> void:
	if command.skill_id == "objective_action":
		_pay(actor,command.skill_id,content.skills.objective_action)
		var input: Dictionary = state.objective.pending.get(actor.id,{})
		var o: Dictionary = state.objective
		_event("objective_input",actor.id,"",0,input)
		match str(input.get("action_id","")):
			"move": _move(actor,input.destination)
			"drop_lamp":
				o.environment_used = "lamp"
				o.smoke_through = int(state.round)+1
				_event("smoke_created",actor.id,"",2,{"cells":["table","jar"],"through_round":o.smoke_through})
			"spill_oil":
				o.environment_used = "oil"
				o.oil_cells = ["jar"]
				_event("oil_created",actor.id,"",2,{"cells":["jar"],"alternate":"side","alternate_cost":1})
			"clear_civilians": o.civilians_clear = true
			"clear_window": o.window_clear = true
			"cover":
				o.cover_round = int(state.round)
				actor.stance = {"kind":"guard","target_id":LIU,"tokens":1,"skill_id":"guard_ally"}
			"secure_anchor":
				# Liu is faster; record her actual action, check Liang's cover at round end.
				o.anchor_secured = true
				o.anchor_round = int(state.round)
				_event("anchor_secured",actor.id)
			"disarm":
				var target := actor_by_id(str(input.get("target","")))
				if alive(target) and _distance(o.positions[actor.id],o.positions[target.id]) <= 1:
					target.weapon = false
					_event("weapon_removed",actor.id,target.id)
			"take_documents":
				if _documents_safe():
					o.documents_taken = true
					_event("documents_taken",actor.id,"",1,{"instance":"item_ch04_waterworks_drawing"})
		return
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

func _documents_safe() -> bool:
	for actor in state.actors:
		if actor.team == "enemy" and alive(actor) and actor.get("weapon",true) and int(state.objective.distracted.get(actor.id,0)) < int(state.round): return false
	return true

func _ray_smoked(origin: String,target: String) -> bool:
	if int(state.objective.smoke_through) < int(state.round): return false
	var a: Vector2i = POINTS[origin]
	var b: Vector2i = POINTS[target]
	var steps := maxi(absi(b.x-a.x),absi(b.y-a.y))
	for step in range(1,steps+1):
		var point := Vector2i(Vector2(a).lerp(Vector2(b),float(step)/maxi(1,steps)).round())
		if point in [POINTS.table,POINTS.jar]: return true
	return false

func _execute_intent(actor: Dictionary, intent: Dictionary) -> void:
	if intent.cancelled:
		intent.executed = true
		_event("intent_cancelled",actor.id)
		return
	var o: Dictionary = state.objective
	o.enemy_actions += 1
	var target := _legal_target(str(intent.get("target_id",HERO)),"party")
	if not alive(target): return
	var liu := actor_by_id(LIU)
	if alive(liu) and liu.stance.get("kind","") == "liu_induce" and liu.stance.target_id == actor.id and int(liu.stance.tokens) > 0 and intent.get("redirectable",false) and not intent.get("aoe",false):
		intent.target_id = LIU
		target = liu
		liu.stance.tokens = 0
		_event("redirected",LIU,actor.id)
		var in_reach: bool = intent.kind != "melee" or _distance(o.positions[actor.id],o.positions[LIU]) <= 1
		if in_reach and "induce" in intent.tags and _break(liu,actor,intent):
			intent.executed = true
			o.distracted[actor.id] = int(state.round)+1
			_event("enemy_action",actor.id,LIU,0,{"kind":"induced_miss"})
			_event("induced_miss",LIU,actor.id)
			if _n01(liu): gain_mana(liu,4,"cold_river_induce")
			if int(liu.get("skill_ranks",{}).get("LYY_A01",1)) >= 2: _damage_action(liu,actor,1.10,false,"counter","LYY_A01")
			return
	if intent.kind == "ranged" and _ray_smoked(o.positions[actor.id],o.positions[target.id]):
		intent.executed = true
		_event("enemy_action",actor.id,target.id,0,{"kind":"smoke_reposition"})
		o.positions[actor.id] = "fire_side" if o.positions[actor.id] == "fire" else "fire"
		_event("smoke_blocked_ray",actor.id,target.id,0,{"cells":["table","jar"]})
		return
	if intent.kind == "area":
		intent.executed = true
		_event("enemy_action",actor.id,"",0,{"kind":"sand_area","cells":["table","jar"]})
		for victim in state.actors:
			if victim.team == "party" and alive(victim) and o.positions[victim.id] in ["table","jar"]: _damage_action(actor,victim,0.9,true,"enemy",intent.intent_id)
		return
	if intent.kind == "melee" and _distance(o.positions[actor.id],o.positions[target.id]) > 1:
		intent.executed = true
		var best: String = o.positions[actor.id]
		var score := 100000
		for candidate in EDGES[best]:
			var candidate_score := _distance(candidate,o.positions[target.id])*2 + (2 if candidate in o.oil_cells else 1)
			if candidate_score < score:
				best = candidate
				score = candidate_score
		_event("enemy_action",actor.id,target.id,0,{"kind":"approach"})
		_move(actor,best)
		return
	if not actor.get("weapon",true):
		intent.hits = [float(state.encounter.unarmed_multiplier)]
		_event("unarmed_attack",actor.id,target.id,0,{"multiplier":state.encounter.unarmed_multiplier,"weapon_removed_before_execution":true})
	super._execute_intent(actor,intent)

func _reduction(actor: Dictionary) -> float:
	var result := super._reduction(actor)
	if actor.stance.get("kind","") == "liu_induce": result = maxf(result,0.35)
	if actor.get("n01_shield",false): result = maxf(result,0.1)
	return result

func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
	var original_def: int = int(target.def)
	target.def = int(floor(float(original_def)*(1.0-_status_value(target,"defense_down"))))
	var result := super._branch(source,target,raw,channel,action_id)
	target.def = original_def
	if result > 0 and target.get("n01_shield",false): target.n01_shield = false
	return result

func _check_outcome() -> void:
	if state.outcome != "" or not state.has("objective"): return
	var o: Dictionary = state.objective
	if not alive(actor_by_id(HERO)) or not alive(actor_by_id(LIU)):
		o.failure = "party_member_exhausted"
		state.outcome = "defeat"
	elif state.mode == "round_end":
		if state.encounter.kind == "tavern_escape" and int(o.enemy_actions) >= 2 and o.environment_used != "" and o.civilians_clear and o.window_clear and o.anchor_secured and int(o.cover_round) == int(state.round) and int(o.anchor_round) == int(state.round) and o.positions[HERO] == "window" and o.positions[LIU] == "window": state.outcome = "victory"
		elif state.encounter.kind == "r02_reclaim" and o.documents_taken: state.outcome = "victory"
		elif int(state.round) >= int(state.encounter.max_rounds):
			o.failure = "time_expired"
			state.outcome = "defeat"
	if state.outcome != "": _event("outcome","","",0,{"result":state.outcome,"reason":o.failure})

func get_view() -> Dictionary:
	var view := super.get_view()
	view["skill_data"] = content.skills.duplicate(true)
	view["skill_costs"] = {}
	view["legal_commands"] = {}
	view.objective["available_actions"] = []
	for actor in state.actors:
		if actor.team != "party": continue
		view.skill_costs[actor.id] = {}
		view.legal_commands[actor.id] = []
		for skill_id in actor.skills:
			if not content.skills.has(skill_id): continue
			view.skill_costs[actor.id][skill_id] = skill_cost(actor,content.skills[skill_id])
			for target in state.actors:
				if skill_id != "objective_action" and validate_command(actor.id,skill_id,target.id) == "": view.legal_commands[actor.id].append({"skill_id":skill_id,"target_id":target.id})
		for destination in ["table","lamp","jar","side","window"]: _view_choice(view,{"actor_id":actor.id,"action_id":"move","destination":destination},"到"+NAMES[destination])
		for action_id in ACTION_NAMES:
			if action_id == "disarm":
				for target in state.actors:
					if target.team == "enemy": _view_choice(view,{"actor_id":actor.id,"action_id":action_id,"target":target.id},"夺械·"+target.name)
			else: _view_choice(view,{"actor_id":actor.id,"action_id":action_id},ACTION_NAMES[action_id])
	var o: Dictionary = view.objective
	o["summary"] = "每人一项正常行动；移动/场景行动也占本轮。气血不足时：梁在灯架/窗路迂回引走护卫，柳先截脉火筒；可先非致命击退威胁再救人开窗。灯架↔窗前有直达窄檐；桌后↔侧廊、侧廊↔窗前均可绕酒坛。烟雾只遮桌后、酒坛两格射线，持续施放当轮与下一轮；近身/毒砂不失效。油洼酒坛格移动费2，侧廊绕行费1。\n梁在%s，柳在%s；环境%s，平民%s，窗路%s，挂索%s，敌动作%d。\n胜利：双方存活、清民清窗，柳挂索并梁在同轮掩护。R02：近身夺械或诱偏各活守卫后到窗前账箱取图，倒地守卫不再阻拦。" % [NAMES[o.positions[HERO]],NAMES[o.positions[LIU]],o.environment_used,"已撤" if o.civilians_clear else "未撤","已清" if o.window_clear else "未清","完成" if o.anchor_secured else "未挂",o.enemy_actions]
	if state.encounter.kind == "r02_reclaim":
		o.summary = "取图目标：每名活守卫须已夺械或受诱偏牵制（失战者不能拦截），然后到窗前账箱执行取回治水原图。移动、夺械、取图各耗该角色一次正常行动。\n不要求打空任何血条。夺械后仍可能徒手追击，先夺械后敌招执行时按0.40倍ATK，不额外取消其行动。\n梁可在灯架/窗前窄檐迂回牵制；柳近身夺械，再循酒坛到窗前。各控制一人独立编排。\n原图实例：item_ch04_waterworks_drawing；胜利战斗XP为0，R02归还后奖励由任务统一结算。"
	return view

func _view_choice(view: Dictionary,action: Dictionary,label: String) -> void:
	if input_error(action) != "": return
	action["revision"] = int(state.revision)
	view.objective.available_actions.append({"label":label,"input":action})
