class_name CombatEngine
extends RefCounted
## Deterministic combat core slice. No scene tree, random numbers or animation clocks.
const SNAPSHOT_VERSION := 1
var rules: Dictionary
var content: Dictionary
var state: Dictionary = {}
var checkpoint: Dictionary = {}

func _init(rule_data: Dictionary, runtime_data: Dictionary) -> void:
	rules = rule_data.duplicate(true)
	content = runtime_data.duplicate(true)

func start(encounter: Dictionary, party: Array) -> void:
	state = {"version": SNAPSHOT_VERSION, "rules_version": rules.version, "content_version": content.version,
		"encounter": encounter.duplicate(true), "round": 1, "mode": "new", "revision": 0,
		"actors": [], "commands": {}, "intents": [], "events": [], "event_sequence": 0,
		"break_count": 0, "outcome": "", "k": float(rules.defense.k_base) + float(rules.defense.k_per_power_level) * (float(encounter.level) - 1.0) * 39.0 / 79.0}
	for source in party + encounter.enemies:
		var actor: Dictionary = source.duplicate(true)
		actor["hp"] = int(actor.get("hp", actor.max_hp))
		actor["mp"] = int(actor.max_mp)
		actor["ready"] = {}
		actor["statuses"] = []
		actor["mana_gained"] = 0
		actor["counter_count"] = 0
		actor["guard_rewarded"] = false
		actor["break_rewarded"] = false
		actor["last_break"] = -1
		actor["protected_through"] = -1
		actor["vulnerable_through"] = -1
		actor["defeated"] = false
		actor["stance"] = {}
		state.actors.append(actor)
	begin_round()
	checkpoint = snapshot()

func actor_by_id(id: String) -> Dictionary:
	for actor in state.get("actors", []):
		if actor.id == id:
			return actor
	return {}

func alive(actor: Dictionary) -> bool:
	return not actor.is_empty() and int(actor.hp) > 0 and not actor.defeated

func _event(kind: String, source: String = "", target: String = "", amount: int = 0, detail: Dictionary = {}) -> void:
	state.event_sequence += 1
	state.events.append({"id": state.event_sequence, "round": state.round, "type": kind,
		"source": source, "target": target, "amount": amount, "detail": detail.duplicate(true)})

func begin_round() -> void:
	if state.mode not in ["new", "round_end"] or state.outcome != "":
		return
	state.commands = {}
	state.intents = []
	for actor in state.actors:
		actor.mana_gained = 0
		actor.counter_count = 0
		actor.guard_rewarded = false
		actor.break_rewarded = false
		actor.stance = {}
		var kept: Array = []
		for effect in actor.statuses:
			if int(effect.expires) >= int(state.round):
				kept.append(effect)
		actor.statuses = kept
		if actor.team == "enemy" and alive(actor):
			var rotation: Array = actor.rotation
			var intent: Dictionary = rotation[(int(state.round) - 1) % rotation.size()].duplicate(true)
			intent["actor_id"] = actor.id
			intent["intent_id"] = "%s:%d" % [actor.id, state.round]
			intent["executed"] = false
			intent["cancelled"] = false
			if not intent.get("aoe", false):
				var target := _legal_target(str(intent.get("target_id", "")), "party")
				if not target.is_empty(): intent.target_id = target.id
			state.intents.append(intent)
	state.mode = "commands"
	state.revision += 1
	_event("round_started")

func skill_cost(actor: Dictionary, skill: Dictionary) -> int:
	var source: Dictionary = rules.skills.get(skill.get("source_id", ""), {})
	var base := maxf(float(source.get("mp_floor", skill.get("mp_floor", 0))), float(actor.max_mp) * float(source.get("mp_percent", skill.get("mp_percent", 0.0))))
	return int(ceil(base * (1.0 - clampf(float(actor.get("discount", 0.0)), 0.0, float(rules.mana.maximum_discount)))))

func _cooldown(skill: Dictionary) -> int:
	return int(rules.skills.get(skill.get("source_id", ""), {}).get("cooldown", skill.get("cooldown", 0)))

func validate_command(actor_id: String, skill_id: String, target_id: String) -> String:
	if state.mode != "commands": return "not_accepting_commands"
	var actor := actor_by_id(actor_id)
	if not alive(actor) or actor.team != "party": return "actor_unavailable"
	if not content.skills.has(skill_id) or skill_id not in actor.skills: return "skill_unavailable"
	var skill: Dictionary = content.skills[skill_id]
	if actor.get("martial_disabled", false) and skill.get("martial", false): return "martial_disabled"
	if int(state.round) < int(actor.ready.get(skill_id, 1)): return "cooldown"
	if int(actor.mp) < skill_cost(actor, skill): return "insufficient_mp"
	var target := actor_by_id(target_id)
	if not alive(target): return "invalid_target"
	var target_kind: String = skill.target
	if target_kind == "self" and target.id != actor.id: return "invalid_target"
	if target_kind == "enemy" and target.team == actor.team: return "invalid_target"
	if target_kind == "ally" and (target.team != actor.team or target.id == actor.id): return "invalid_target"
	if skill.kind == "guard":
		for other_id in state.commands:
			var command: Dictionary = state.commands[other_id]
			if other_id != actor_id and command.target_id == target_id and content.skills[command.skill_id].kind == "guard":
				return "guard_conflict"
	return ""

func set_command(actor_id: String, skill_id: String, target_id: String, revision: int = -1) -> String:
	if revision != -1 and revision != int(state.revision): return "stale_revision"
	var error := validate_command(actor_id, skill_id, target_id)
	if error != "": return error
	var command := {"actor_id": actor_id, "skill_id": skill_id, "target_id": target_id}
	if state.commands.get(actor_id, {}) == command: return ""
	state.commands[actor_id] = command
	state.revision += 1
	return ""

func can_resolve() -> bool:
	if state.mode != "commands": return false
	for actor in state.actors:
		if actor.team == "party" and alive(actor) and not state.commands.has(actor.id): return false
	return true

func _pay(actor: Dictionary, skill_id: String, skill: Dictionary) -> void:
	var cost := skill_cost(actor, skill)
	actor.mp -= cost
	actor.ready[skill_id] = int(state.round) + _cooldown(skill) + int(rules.timing.cooldown_ready_offset)
	_event("skill_paid", actor.id, "", cost, {"skill_id": skill_id, "ready_round": actor.ready[skill_id]})

func gain_mana(actor: Dictionary, requested: int, reason: String) -> void:
	var amount := mini(maxi(0, requested), mini(int(rules.limits.mana_gain_per_actor_round) - int(actor.mana_gained), int(actor.max_mp) - int(actor.mp)))
	if amount <= 0: return
	actor.mp += amount
	actor.mana_gained += amount
	_event("mana", actor.id, actor.id, amount, {"reason": reason})

func _speed(actor: Dictionary, modifier: int) -> int:
	var gain := 0.0
	var loss := 0.0
	for effect in actor.statuses:
		if int(effect.starts) <= int(state.round) and int(effect.expires) >= int(state.round):
			if effect.kind == "speed_up": gain = maxf(gain, effect.value)
			if effect.kind == "speed_down": loss = maxf(loss, effect.value)
	return int(floor(float(actor.spd) * (1.0 + gain - loss))) + modifier

func resolve_round() -> bool:
	if not can_resolve(): return false
	state.mode = "preparation"
	var queue: Array = []
	for index in range(state.actors.size()):
		var actor: Dictionary = state.actors[index]
		if not alive(actor): continue
		if actor.team == "party":
			var command: Dictionary = state.commands[actor.id]
			var skill: Dictionary = content.skills[command.skill_id]
			if skill.get("prepare", false):
				_pay(actor, command.skill_id, skill)
				actor.stance = {"kind": skill.kind, "target_id": command.target_id, "tokens": 1, "skill_id": command.skill_id}
				_event("prepared", actor.id, command.target_id)
				if skill.kind in ["self_guard", "guard"]: gain_mana(actor, int(rules.mana.guard_gain), "guard")
				if skill.kind != "counter": continue
			queue.append({"actor_id": actor.id, "command": command, "enemy": false, "speed": _speed(actor, int(skill.get("speed", 0))), "order": index})
		else:
			for intent in state.intents:
				if intent.actor_id == actor.id:
					queue.append({"actor_id": actor.id, "command": intent, "enemy": true, "speed": _speed(actor, int(intent.get("speed", 0))), "order": index})
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.speed > b.speed if a.speed != b.speed else a.order < b.order)
	state.mode = "executing"
	for item in queue:
		var actor := actor_by_id(item.actor_id)
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

func _execute_command(actor: Dictionary, command: Dictionary) -> void:
	var skill: Dictionary = content.skills[command.skill_id]
	if skill.kind == "counter":
		if int(actor.stance.get("tokens", 0)) == 0: return
		for intent in state.intents:
			if intent.actor_id == command.target_id and not intent.executed and not intent.cancelled and intent.get("target_id", "") == actor.id:
				return
		_counter(actor, actor_by_id(command.target_id), false)
		return
	var target := actor_by_id(command.target_id)
	if not alive(target):
		for candidate in state.actors:
			if alive(candidate) and candidate.team != actor.team:
				target = candidate
				break
	if not alive(target):
		_event("command_invalidated", actor.id)
		return
	_pay(actor, command.skill_id, skill)
	_event("action", actor.id, target.id, 0, {"skill_id": command.skill_id})
	for multiplier in skill.get("hits", [1.0]):
		_damage_action(actor, target, float(multiplier), false, "normal", command.skill_id)
	if skill.kind == "attack": gain_mana(actor, int(rules.mana.normal_attack_gain), "normal_attack")
	if skill.has("break_tag"):
		for intent in state.intents:
			if intent.actor_id == target.id and not intent.executed and not intent.cancelled and skill.break_tag in intent.get("tags", []):
				if _break(actor, target, intent):
					if skill.break_tag == "interrupt": intent["weakened"] = true
					else: intent.cancelled = true
		if skill.has("speed_down"):
			target.statuses.append({"kind": "speed_down", "value": skill.speed_down, "starts": int(state.round) + 1, "expires": int(state.round) + 1})

func _protected(target: Dictionary) -> bool:
	return int(target.last_break) == int(state.round) or int(target.protected_through) >= int(state.round)

func _break(source: Dictionary, target: Dictionary, intent: Dictionary) -> bool:
	if not alive(source) or not alive(target) or _protected(target): return false
	target.last_break = int(state.round)
	target.protected_through = int(state.round) + int(target.get("protection_rounds", 0))
	target.vulnerable_through = int(state.round) + int(rules.timing.break_vulnerability_extra_rounds)
	state.break_count += 1
	_event("break", source.id, target.id, 0, {"intent_id": intent.intent_id})
	if not source.break_rewarded:
		source.break_rewarded = true
		gain_mana(source, int(rules.mana.break_gain), "break")
	return true

func _legal_target(target_id: String, team: String) -> Dictionary:
	var original := actor_by_id(target_id)
	if alive(original) and original.team == team: return original
	for candidate in state.actors:
		if alive(candidate) and candidate.team == team: return candidate
	return {}

func _execute_intent(actor: Dictionary, intent: Dictionary) -> void:
	intent.executed = true
	if intent.cancelled: return
	_event("enemy_action", actor.id, intent.get("target_id", ""))
	var targets: Array = []
	if intent.get("aoe", false):
		for target in state.actors:
			if target.team == "party" and alive(target): targets.append(target)
	else:
		var target := _legal_target(str(intent.target_id), "party")
		if alive(target):
			if target.id != intent.target_id:
				_event("retargeted", actor.id, target.id, 0, {"previous_target": intent.target_id})
				intent.target_id = target.id
			targets.append(target)
	for target in targets:
		var counter: bool = target.stance.get("kind", "") == "counter" and int(target.stance.get("tokens", 0)) > 0 and target.stance.target_id == actor.id
		if counter and not intent.get("aoe", false) and "induce" in intent.get("tags", []) and _break(target, actor, intent):
			_event("induced_miss", target.id, actor.id)
			_counter(target, actor, true)
			continue
		var guard: Dictionary = {}
		if not intent.get("aoe", false):
			for candidate in state.actors:
				if alive(candidate) and candidate.stance.get("kind", "") == "guard" and candidate.stance.target_id == target.id and int(candidate.stance.tokens) > 0:
					guard = candidate
					break
		for multiplier in intent.get("hits", [1.0]):
			var scale := float(multiplier) * (0.35 if intent.get("weakened", false) else 1.0)
			_damage_action(actor, target, scale, bool(intent.get("aoe", false)), "enemy", intent.intent_id, guard)
		if not guard.is_empty(): guard.stance.tokens = 0
		if counter and alive(target): _counter(target, actor, false)

func _counter(actor: Dictionary, target: Dictionary, induced: bool) -> void:
	if int(actor.stance.get("tokens", 0)) == 0: return
	actor.stance.tokens = 0
	if not alive(actor) or not alive(target) or int(actor.counter_count) >= int(rules.limits.counter_per_actor_round): return
	actor.counter_count += 1
	var skill: Dictionary = content.skills[actor.stance.skill_id]
	_event("counter", actor.id, target.id)
	_damage_action(actor, target, float(skill.counter_multiplier if induced else skill.multiplier), false, "counter", actor.stance.skill_id)
	if skill.has("next_round_attack_down") and alive(target):
		target.statuses.append({"kind": "attack_down", "value": float(skill.next_round_attack_down), "starts": int(state.round) + 1, "expires": int(state.round) + 1})

func _reduction(actor: Dictionary) -> float:
	var reduction := float(actor.get("reduction", 0.0))
	var kind: String = actor.stance.get("kind", "")
	if kind in ["self_guard", "counter"]: reduction = maxf(reduction, 0.35)
	if kind == "guard": reduction = maxf(reduction, float(rules.guard.extra_reduction))
	return clampf(reduction, 0.0, float(rules.limits.extra_damage_reduction))

func _damage_action(source: Dictionary, target: Dictionary, multiplier: float, _aoe: bool, channel: String, action_id: String, guard: Dictionary = {}) -> void:
	if not alive(target): return
	var attack := float(source.atk)
	var attack_down := 0.0
	for effect in source.statuses:
		if effect.kind == "attack_down" and int(effect.starts) <= int(state.round) and int(effect.expires) >= int(state.round):
			attack_down = maxf(attack_down, float(effect.value))
	attack = floor(attack * (1.0 - minf(attack_down, float(rules.limits.attack_debuff))))
	var raw := maxf(1.0, attack) * multiplier
	if int(target.vulnerable_through) >= int(state.round): raw *= 1.2
	var share := float(rules.guard.share) if not guard.is_empty() and alive(guard) else 0.0
	_branch(source, target, raw * (1.0 - share), channel, action_id)
	if share > 0.0:
		var loss := _branch(source, guard, raw * share, "guard", action_id)
		if loss > 0 and not guard.guard_rewarded:
			guard.guard_rewarded = true
			gain_mana(guard, int(rules.mana.successful_guard_gain), "successful_guard")

func _branch(source: Dictionary, target: Dictionary, raw: float, channel: String, action_id: String) -> int:
	if raw <= 0 or not alive(target): return 0
	var damage := maxi(1, int(floor(raw * float(state.k) / (float(state.k) + maxf(0.0, float(target.def))) * (1.0 - _reduction(target)))))
	var shield := mini(int(target.get("shield", 0)), damage)
	target["shield"] = int(target.get("shield", 0)) - shield
	var hp_loss := mini(int(target.hp), damage - shield)
	target.hp -= hp_loss
	if int(target.hp) <= 0: target.defeated = true
	_event("damage", source.id, target.id, hp_loss, {"raw": raw, "damage": damage, "shield_loss": shield, "channel": channel, "action_id": action_id})
	return hp_loss + shield

func _check_outcome() -> void:
	if state.outcome != "": return
	var party_alive := false
	var enemy_alive := false
	for actor in state.actors:
		if alive(actor):
			if actor.team == "party": party_alive = true
			else: enemy_alive = true
	if not party_alive: state.outcome = "defeat"
	elif int(state.encounter.get("required_breaks", 0)) > 0:
		if int(state.break_count) >= int(state.encounter.required_breaks): state.outcome = "victory"
	elif not enemy_alive: state.outcome = "victory"
	if state.outcome != "": _event("outcome", "", "", 0, {"result": state.outcome})

func snapshot() -> Dictionary:
	return state.duplicate(true)

func get_view() -> Dictionary:
	return snapshot()

func _whole(value: Variant, minimum: int = 0, maximum: int = 1000000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

func restore(data: Dictionary) -> bool:
	# Round-boundary checkpoints only; rejection must not partially mutate live state.
	if not _whole(data.get("version")) or int(data.version) != SNAPSHOT_VERSION: return false
	if data.get("rules_version", "") != rules.version or data.get("content_version", "") != content.version: return false
	if data.get("mode", "") not in ["commands", "finished"]: return false
	for key in ["round", "revision", "event_sequence", "break_count"]:
		if not _whole(data.get(key)): return false
	if int(data.round) < 1 or data.get("outcome", null) not in ["", "victory", "defeat"]: return false
	if (data.mode == "commands" and data.outcome != "") or (data.mode == "finished" and data.outcome == ""): return false
	if not (data.get("k") is float or data.get("k") is int) or not is_finite(float(data.k)) or float(data.k) <= 0: return false
	if not data.get("actors") is Array or not data.get("events") is Array or not data.get("encounter") is Dictionary: return false
	if data.encounter.has("required_breaks") and not _whole(data.encounter.required_breaks): return false
	if not data.get("commands") is Dictionary or not data.get("intents") is Array: return false
	var ids: Array = []
	for actor in data.actors:
		if not actor is Dictionary or not actor.get("id") is String or actor.id == "" or actor.id in ids: return false
		if actor.get("team", "") not in ["party", "enemy"]: return false
		for key in ["hp", "max_hp", "mp", "max_mp", "atk", "def", "spd", "mana_gained", "counter_count"]:
			if not _whole(actor.get(key)): return false
		for key in ["last_break", "protected_through", "vulnerable_through"]:
			if not _whole(actor.get(key), -1): return false
		for key in ["defeated", "guard_rewarded", "break_rewarded"]:
			if not actor.get(key) is bool: return false
		for key in ["shield", "protection_rounds"]:
			if actor.has(key) and not _whole(actor[key]): return false
		for key in ["reduction", "discount"]:
			if actor.has(key) and (not (actor[key] is int or actor[key] is float) or not is_finite(float(actor[key])) or float(actor[key]) < 0): return false
		if actor.has("martial_disabled") and not actor.martial_disabled is bool: return false
		if int(actor.hp) > int(actor.max_hp) or int(actor.mp) > int(actor.max_mp): return false
		if not actor.get("ready") is Dictionary or not actor.get("stance") is Dictionary or not actor.get("statuses") is Array: return false
		if not actor.stance.is_empty():
			if actor.stance.get("kind", "") not in ["self_guard", "guard", "counter"] or not actor.stance.get("target_id") is String: return false
			if not _whole(actor.stance.get("tokens"), 0, 1) or not content.skills.has(actor.stance.get("skill_id", "")): return false
		for skill_id in actor.ready:
			if not content.skills.has(skill_id) or not _whole(actor.ready[skill_id], 1): return false
		for effect in actor.statuses:
			if not effect is Dictionary or effect.get("kind", "") not in ["speed_up", "speed_down", "attack_down"]: return false
			if not _whole(effect.get("starts"), 1) or not _whole(effect.get("expires"), 1): return false
			if not (effect.get("value") is float or effect.get("value") is int) or not is_finite(float(effect.value)): return false
		if actor.team == "party":
			if not actor.get("skills") is Array: return false
			for skill_id in actor.skills:
				if not content.skills.has(skill_id): return false
		else:
			if not actor.get("rotation") is Array or actor.rotation.is_empty(): return false
			for intent in actor.rotation:
				if not _valid_intent(intent): return false
		ids.append(actor.id)
	for actor in data.actors:
		if not actor.stance.is_empty() and actor.stance.target_id not in ids: return false
		if actor.team == "enemy":
			for intent in actor.rotation:
				if intent.target_id not in ids: return false
	for id in data.commands:
		var command: Variant = data.commands[id]
		if id not in ids or not command is Dictionary: return false
		if command.get("actor_id", "") != id or command.get("target_id", "") not in ids or not content.skills.has(command.get("skill_id", "")): return false
	var intent_actors: Array = []
	var intent_ids: Array = []
	for intent in data.intents:
		if not _valid_intent(intent) or intent.get("actor_id", "") not in ids or not intent.get("intent_id") is String: return false
		if not intent.get("executed") is bool or not intent.get("cancelled") is bool: return false
		if data.mode == "commands" and (intent.executed or intent.cancelled): return false
		if intent.actor_id in intent_actors or intent.intent_id in intent_ids: return false
		var owner_is_enemy := false
		for actor in data.actors:
			if actor.id == intent.actor_id and actor.team == "enemy": owner_is_enemy = true
		if not owner_is_enemy: return false
		intent_actors.append(intent.actor_id)
		intent_ids.append(intent.intent_id)
	if data.mode == "commands":
		for actor in data.actors:
			if not actor.stance.is_empty(): return false
			if actor.team == "enemy" and alive(actor) and actor.id not in intent_actors: return false
	var previous_id := 0
	for event in data.events:
		if not event is Dictionary or not _whole(event.get("id"), 1) or int(event.id) <= previous_id: return false
		if not event.get("type") is String or not event.get("detail") is Dictionary or not _whole(event.get("round"), 1): return false
		previous_id = int(event.id)
	if previous_id != int(data.event_sequence): return false
	var previous_state := state
	state = data.duplicate(true)
	if state.mode == "commands":
		for id in state.commands:
			var command: Dictionary = state.commands[id]
			if validate_command(id, command.skill_id, command.target_id) != "":
				state = previous_state
				return false
	return true

func _valid_intent(value: Variant) -> bool:
	if not value is Dictionary or not value.get("target_id") is String: return false
	if not value.get("hits", []) is Array or not value.get("tags", []) is Array: return false
	if value.has("speed") and not _whole(value.speed, -1000000, 1000000): return false
	for key in ["aoe", "weakened"]:
		if value.has(key) and not value[key] is bool: return false
	for tag in value.get("tags", []):
		if not tag is String: return false
	for multiplier in value.get("hits", [1.0]):
		if not (multiplier is int or multiplier is float) or not is_finite(float(multiplier)) or float(multiplier) < 0: return false
	return true

func retry_checkpoint() -> bool:
	return restore(checkpoint)
