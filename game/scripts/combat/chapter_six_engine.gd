class_name ChapterSixCombatEngine
extends "res://scripts/combat/combat_engine.gd"
## Nonlethal, deterministic chapter-six exercises. No rewards or permanent writes.
const HERO := "char_liang_xiao"
const AXUE := "char_axue"
const DATA_PATH := "res://data/chapter_six_encounters.json"
const GUAS := ["qian_li", "kun_zhen", "kun_zhen"]
const STEPS := ["qian", "kun", "center"]
const LABELS := {"qian_li":"乾上离下·同人", "kun_zhen":"坤上震下·复", "qian":"步入乾位", "kun":"步入坤位", "center":"回旋归中"}
var entry_error := ""

func _init(rule_data: Dictionary, runtime_data: Dictionary) -> void:
	super(rule_data,runtime_data)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	content.skills.merge(data.skills,true)

func start(encounter: Dictionary, party: Array) -> void:
	var clean := party.duplicate(true)
	var ids: Array = []
	for actor in clean:
		if not actor is Dictionary or actor.get("id","") not in [HERO,AXUE] or actor.get("team") != "party" or actor.get("id") in ids:
			entry_error = "invalid_party"; break
		ids.append(actor.id)
		if not _whole(actor.get("hp"),1) or int(actor.hp)>int(actor.get("max_hp",0)) or not actor.get("controllable",true): entry_error = "living_controllable_party_required"; break
		if not actor.get("skills") is Array: entry_error = "invalid_skills"; break
		if actor.get("internal_skill","")=="LX_N01":
			actor.atk=int(floor(float(actor.atk)*1.08))
			actor.spd=int(actor.spd)+5
		for skill in ["ch06_punch","ch06_carry"]:
			if skill not in actor.skills: actor.skills.append(skill)
	if HERO not in ids or (encounter.kind=="basket_guard" and AXUE not in ids): entry_error = "required_party_missing"
	if encounter.kind!="basket_guard" and ids.size()!=1: entry_error = "solo_exercise_required"
	if entry_error!="":
		state={"outcome":"invalid","mode":"finished","actors":[],"commands":{},"revision":0,"round":1,"intents":[],"events":[],"encounter":encounter.duplicate(true),"objective":{"failure":entry_error}}
		return
	super.start(encounter,clean)

func begin_round() -> void:
	if state.mode not in ["new","round_end"] or state.outcome!="": return
	if not state.has("objective"):
		state.objective={"pending":{},"exchanges":[],"hits":0,"caught":false,"distance":0,"misses":0,"failure":"","dot_round":0}
	state.mode="new"
	for actor in state.actors: actor.stance={}
	_tick_dot()
	_check_outcome()
	if state.outcome!="": state.mode="finished";return
	super.begin_round()
	for actor in state.actors:
		if alive(actor) and actor.get("internal_skill","")=="LX_N01": gain_mana(actor,3,"mirror_breath")
	state.objective.pending={}
	if state.encounter.kind=="basket_guard":
		for intent in state.intents:
			intent.target_id = carrier()
			intent.name = "%s搬筐，另一人援护；试探拳1.00倍" % actor_by_id(carrier()).name

func carrier() -> String:
	return HERO if int(state.objective.distance)%2==0 else AXUE

func input_error(action: Dictionary) -> String:
	if state.mode!="commands" or state.outcome!="": return "not_accepting_input"
	for key in action:
		if key not in ["actor_id","action_id","value","revision"]: return "unexpected_field"
	if not action.get("actor_id") is String or not action.get("action_id") is String: return "invalid_input_type"
	if action.has("revision") and (not _whole(action.revision) or int(action.revision)!=int(state.revision)): return "stale_revision"
	var actor := actor_by_id(action.actor_id)
	if not alive(actor) or actor.team!="party" or not actor.get("controllable",true) or _status_value(actor,"stun")>0: return "actor_unavailable"
	if action.action_id=="cancel": return "" if not action.has("value") else "unexpected_value"
	if state.encounter.kind=="white_plum":
		if actor.id!=HERO or not action.get("value") is String: return "invalid_choice"
		if action.action_id=="gua" and action.value in ["qian_li","kun_zhen"]: return ""
		if action.action_id=="step" and action.value in ["qian","kun","center"]: return ""
	if state.encounter.kind=="basket_guard" and action.action_id=="carry" and not action.has("value"):
		return "" if actor.id==carrier() else "wrong_carrier"
	return "invalid_action"

func apply_input(action: Dictionary) -> Dictionary:
	var error := input_error(action)
	if error!="": return {"accepted":false,"error":error}
	var id: String = action.actor_id
	if action.action_id=="cancel":
		state.commands.erase(id);state.objective.pending.erase(id)
	elif action.action_id=="carry":
		state.commands[id]={"actor_id":id,"skill_id":"ch06_carry","target_id":id}
		state.objective.pending[id]={"carry":true}
	else:
		if not state.objective.pending.has(id): state.objective.pending[id]={}
		state.objective.pending[id][action.action_id]=action.value
	state.revision+=1
	return {"accepted":true}

func validate_command(actor_id: String,skill_id: String,target_id: String) -> String:
	var error := super.validate_command(actor_id,skill_id,target_id)
	if error!="": return error
	var actor := actor_by_id(actor_id)
	if _status_value(actor,"stun")>0: return "actor_unavailable"
	if _status_value(actor,"sealed")>0 and content.skills[skill_id].get("martial",false): return "martial_sealed"
	if skill_id=="ch06_carry": return "use_scene_input"
	if state.encounter.kind=="tutuha_spar" and skill_id not in ["ch06_punch","self_guard","observe","sancai_counter"]: return "fists_only"
	if state.encounter.kind=="white_plum" and skill_id not in ["normal_attack","LX_A03","self_guard","observe"]: return "sword_exercise"
	if state.encounter.kind=="basket_guard" and skill_id not in ["self_guard","guard_ally","observe"]: return "protect_the_basket"
	return ""

func set_command(actor_id: String,skill_id: String,target_id: String,revision: int=-1) -> String:
	var error := super.set_command(actor_id,skill_id,target_id,revision)
	if error=="" and state.encounter.kind=="basket_guard": state.objective.pending.erase(actor_id)
	return error

func can_resolve() -> bool:
	if not super.can_resolve(): return false
	if state.encounter.kind=="white_plum":
		var p: Dictionary = state.objective.pending.get(HERO,{})
		return p.has("gua") and p.has("step")
	return true

func _execute_command(actor: Dictionary,command: Dictionary) -> void:
	if command.skill_id=="ch06_carry":
		_event("carry_attempt",actor.id,"basket");return
	if state.encounter.kind=="white_plum" and actor.id==HERO:
		var i := int(state.round)-1
		var p: Dictionary = state.objective.pending.get(HERO,{})
		if p.get("gua")!=GUAS[i] or p.get("step")!=STEPS[i] or command.skill_id not in ["normal_attack","LX_A03"]:
			_fail("white_plum_lost_step");return
		super._execute_command(actor,command)
		_after_skill(actor,command)
		state.objective.exchanges.append({"round":state.round,"gua":p.gua,"step":p.step,"skill":command.skill_id})
		_event("sword_exchange",actor.id,"gongyang_plum",1,p)
		return
	var before := int(actor_by_id(command.target_id).hp)
	super._execute_command(actor,command)
	_after_skill(actor,command)
	if state.encounter.kind=="tutuha_spar" and command.skill_id=="ch06_punch" and int(actor_by_id(command.target_id).hp)<before: state.objective.hits+=1

func _after_skill(actor: Dictionary,command: Dictionary) -> void:
	if command.skill_id=="LX_A03":
		actor["jiugong_through"]=int(state.round)
		actor["jiugong_speed_round"]=int(state.round)+1
		_event("jiugong_step",actor.id,actor.id)
	if command.skill_id=="observe" and actor.get("internal_skill","")=="LX_N01": actor["mirror_strike"]=true

func _speed(actor: Dictionary,modifier: int,skill: Dictionary={}) -> int:
	return super._speed(actor,modifier,skill)+(10 if int(actor.get("jiugong_speed_round",-1))==int(state.round) else 0)

func _reduction(actor: Dictionary) -> float:
	return maxf(super._reduction(actor),0.2 if int(actor.get("jiugong_through",-1))>=int(state.round) else 0.0)

func _branch(source: Dictionary,target: Dictionary,raw: float,channel: String,action_id: String) -> int:
	var result:=super._branch(source,target,raw,channel,action_id)
	if raw>0 and int(target.get("jiugong_through",-1))>=int(state.round): target.jiugong_through=-1
	return result

func _damage_action(source: Dictionary,target: Dictionary,multiplier: float,aoe: bool,channel: String,action_id: String,guard: Dictionary={}) -> void:
	if action_id in ["normal_attack","ch06_punch"] and source.get("mirror_strike",false):
		multiplier*=1.1;source.mirror_strike=false
	super._damage_action(source,target,multiplier,aoe,channel,action_id,guard)

func _counter(actor: Dictionary,target: Dictionary,induced: bool) -> void:
	var before:=int(actor.counter_count)
	super._counter(actor,target,induced)
	if int(actor.counter_count)==before:return
	var rank:=int(actor.get("skill_ranks",{}).get("LX_A02",actor.get("skill_ranks",{}).get("sancai_counter",1)))
	if actor.id==HERO and rank>=2 and induced:
		var gain:=mini(int(actor.max_hp)-int(actor.hp),int(floor(float(actor.max_hp)*0.02)))
		actor.hp+=gain;_event("sancai_heal",actor.id,actor.id,gain)
	if actor.id==HERO and rank>=3 and alive(target):_apply_status(target,"attack_down",0.15,2)

func _execute_intent(actor: Dictionary,intent: Dictionary) -> void:
	if state.encounter.kind=="white_plum":
		intent.executed=true
		_event("teaching_sword_line",actor.id,HERO)
		return
	if state.encounter.kind=="tutuha_spar" and int(state.round)==2 and actor_by_id(HERO).stance.get("kind","")=="self_guard":
		state.objective.caught=true
		_event("grapple_received",HERO,actor.id)
	super._execute_intent(actor,intent)
	for member in state.actors:
		if member.team=="party" and member.stance.get("kind","") in ["guard","self_guard"] and member.get("internal_skill","")=="LX_N01":member["mirror_strike"]=true

func _lose_hp(source: Dictionary,target: Dictionary,amount: int) -> int:
	if not alive(target) or amount<=0:return 0
	var loss := mini(maxi(0,int(target.hp)-1),amount)
	target.hp-=loss
	if int(target.hp)<=1 and target.team=="party": _fail("nonlethal_stop")
	return loss

func _dot_damage(source: Dictionary,target: Dictionary,amount: int,kind: String) -> int:
	if amount<=0 or not alive(target):return 0
	var damage := maxi(1,int(floor(float(amount)*(1.0-_reduction(target)))))
	var shield := mini(int(target.get("shield",0)),damage)
	target["shield"]=int(target.get("shield",0))-shield
	var loss := _lose_hp(source,target,damage-shield)
	_event("damage",source.get("id",""),target.id,loss,{"channel":"dot","action_id":kind,"shield_loss":shield})
	return loss

func _tick_dot() -> void:
	if int(state.objective.dot_round)==int(state.round):return
	state.objective.dot_round=state.round
	for actor in state.actors:
		for effect in actor.statuses:
			if effect.kind in ["bleed","luo_pain","cold_poison"] and int(effect.starts)<=int(state.round) and int(effect.expires)>=int(state.round):
				_dot_damage(actor_by_id(effect.get("source","")),actor,int(effect.value),effect.kind)

func _fail(reason: String) -> void:
	if state.outcome!="":return
	state.objective.failure=reason;state.outcome="defeat"
	_event("exercise_stopped","","",0,{"reason":reason})

func _check_outcome() -> void:
	if state.outcome!="":return
	for actor in state.actors:
		if actor.team=="party" and not alive(actor):_fail("participant_unavailable");return
	if state.mode!="round_end":return
	var o: Dictionary=state.objective
	match state.encounter.kind:
		"white_plum":
			if o.exchanges.size()==3: state.outcome="victory"
		"tutuha_spar":
			if int(o.hits)>=2 and o.caught:state.outcome="victory"
		"basket_guard":
			var c := carrier()
			var g := AXUE if c==HERO else HERO
			var carry: Dictionary=state.commands.get(c,{})
			var guard: Dictionary=state.commands.get(g,{})
			if carry.get("skill_id")=="ch06_carry" and guard.get("skill_id")=="guard_ally" and guard.get("target_id")==c:
				o.distance+=1;_event("basket_advanced",c,"basket",1)
			else:
				o.misses+=1;_event("basket_uncovered",c,"basket",1)
			if int(o.distance)>=3:state.outcome="victory"
			elif int(o.misses)>=2:_fail("basket_two_misses")
	if state.outcome=="" and int(state.round)>=int(state.encounter.max_rounds):_fail("exercise_time_expired")
	if state.outcome=="victory":_event("outcome","","",0,{"result":"victory"})

func get_view() -> Dictionary:
	var v := snapshot()
	v["skill_data"]=content.skills.duplicate(true);v["skill_costs"]={};v["legal_commands"]={}
	v.objective["available_actions"]=[]
	v.objective["summary"]="白梅：三轮依提示选上/下卦、落步、出剑，正确零受伤；错误止练不扣血。切磋：三轮内拳脚命中两次，第2轮自守接摔。护筐：梁雪交替搬三格，另一人援护，失守两次止练。所有交锋非致命，低至1血即止练；重试还原本次入场，不发奖。独立开战真气依规则初始化，阶段不补满。"
	for actor in state.actors:
		if actor.team!="party":continue
		v.skill_costs[actor.id]={};v.legal_commands[actor.id]=[]
		for skill in actor.skills:
			if not content.skills.has(skill):continue
			v.skill_costs[actor.id][skill]=skill_cost(actor,content.skills[skill])
			for target in state.actors:
				if validate_command(actor.id,skill,target.id)=="":v.legal_commands[actor.id].append({"skill_id":skill,"target_id":target.id})
		for action in [{"actor_id":actor.id,"action_id":"cancel"},{"actor_id":actor.id,"action_id":"carry"}]:_choice(v,action,"取消本轮编排" if action.action_id=="cancel" else "搬筐前进一步")
		for value in ["qian_li","kun_zhen"]:_choice(v,{"actor_id":actor.id,"action_id":"gua","value":value},LABELS[value])
		for value in ["qian","kun","center"]:_choice(v,{"actor_id":actor.id,"action_id":"step","value":value},LABELS[value])
	return v

func _choice(v: Dictionary,action: Dictionary,label: String) -> void:
	if input_error(action)!="":return
	action.revision=state.revision
	v.objective.available_actions.append({"label":label,"input":action})
