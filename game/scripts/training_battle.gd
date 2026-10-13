class_name TrainingBattle
extends RefCounted
## Presentation adapter: teaching goal on the shared combat core, not a full encounter.
const Combat = preload("res://scripts/combat/combat_engine.gd")
var rules: Dictionary
var engine: CombatEngine
var round_number := 1
var hp := 520
var mp := 80
var mirror_ready_round := 1
var read_count := 0
var finished := false
var log_text := "教学目标：成功两次镜心诱导；不是清空对手气血。"

func _init(data: Dictionary) -> void:
	rules = data
	var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	engine = Combat.new(rules, runtime)
	engine.start(runtime.prologue_lesson, [runtime.liang_wenjing])

func mirror_cost() -> int:
	return engine.skill_cost(engine.actor_by_id("liang_wenjing"), engine.content.skills.mirror_counter)

func act(action: String) -> bool:
	if finished or hp <= 0 or action not in ["mirror", "guard", "attack"]: return false
	var commands := {"mirror": "mirror_counter", "guard": "self_guard", "attack": "normal_attack"}
	var target := "liang_wenjing" if action == "guard" else "lesson_partner"
	var previous_hp := hp
	if engine.set_command("liang_wenjing", commands[action], target) != "": return false
	if not engine.resolve_round(): return false
	var actor := engine.actor_by_id("liang_wenjing")
	hp = int(actor.hp)
	mp = int(actor.mp)
	round_number = int(engine.state.round)
	mirror_ready_round = int(actor.ready.get("mirror_counter", 1))
	read_count = int(engine.state.break_count)
	finished = engine.state.outcome == "victory"
	if action == "mirror":
		log_text = "共享战斗结算：镜心反制，承受 %d 伤害；有效破招 %d / 2。" % [previous_hp - hp, read_count]
	elif action == "guard":
		log_text = "准备自守，承受 %d 伤害；自守回气8，所有回气每轮上限12。" % (previous_hp - hp)
	else:
		log_text = "普通掌与敌意图按速度结算，承受 %d 伤害；普通攻击回气4。" % (previous_hp - hp)
	return true

static func base_damage(attack: float, multiplier: float, defense: float, level: float) -> int:
	var k := 100.0 + 4.0 * (level - 1.0) * 39.0 / 79.0
	return maxi(1, int(floor(attack * multiplier * k / (k + maxf(0.0, defense)))))
