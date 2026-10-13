class_name TrainingBattle
extends RefCounted
## Limited, deterministic teaching encounter. Not the complete combat engine.
var rules: Dictionary
var round_number := 1
var hp := 520
var mp := 80
var mirror_ready_round := 1
var read_count := 0
var finished := false
var log_text := "教学目标：成功两次镜心诱导；不是清空对手气血。"
func _init(data: Dictionary) -> void:
	rules = data

func mirror_cost() -> int:
	var skill: Dictionary = rules.skills.LWJ_S01
	return maxi(int(skill.mp_floor), int(ceil(80 * float(skill.mp_percent))))

func act(action: String) -> bool:
	if finished or hp <= 0 or action not in ["mirror", "guard", "attack"]:
		return false
	if action == "mirror" and (round_number < mirror_ready_round or mp < mirror_cost()):
		return false
	var damage := base_damage(68.0, 1.4, 55.0, 15.0)
	if action == "mirror":
		mp -= mirror_cost()
		mirror_ready_round = round_number + int(rules.skills.LWJ_S01.cooldown) + int(rules.timing.cooldown_ready_offset)
		read_count += 1
		log_text = "准备先于速度：读准点名攻势，踏步诱偏，伤害 0。镜心成功 %d / 2。" % read_count
	elif action == "guard":
		damage = int(floor(damage * 0.65))
		hp = maxi(0, hp-damage)
		mp = mini(80, mp + mini(int(rules.limits.mana_gain_per_actor_round), int(rules.mana.guard_gain)+int(rules.mana.successful_guard_gain)))
		log_text = "守住门户，承受 %d 点教学伤害；护卫回气，上限每轮 12。" % damage
	else:
		hp = maxi(0, hp-damage)
		mp = mini(80, mp+int(rules.mana.normal_attack_gain))
		log_text = "试探出掌，对手收势未乱。承受 %d 点教学伤害；须观察意图拆招。" % damage
	round_number += 1
	finished = read_count >= 2
	return true

static func base_damage(attack: float, multiplier: float, defense: float, level: float) -> int:
	var power_level := 1.0 + (level-1.0)*39.0/79.0
	var k := 100.0 + 4.0*(power_level-1.0)
	return maxi(1, int(floor(attack * multiplier * k/(k+maxf(0.0,defense)))))
