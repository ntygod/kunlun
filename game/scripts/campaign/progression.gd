class_name Progression
extends RefCounted
const CAP := 80
static func threshold(level: int) -> int:
	var n := clampi(level, 1, CAP)-1
	return 100*n + int(15*n*(n-1)/2)
static func level_from_xp(xp: int) -> int:
	var level := 1
	while level < CAP and xp >= threshold(level+1): level += 1
	return level
static func liang_panel(xp: int, equipment: Dictionary = {}) -> Dictionary:
	var level := level_from_xp(xp)
	var x := 39.0*float(level-1)/79.0
	var bare := {"max_hp":int(floor(150+38*x+0.45*x*x)),"max_mp":int(floor(45+3.8*x)),
		"atk":int(floor(24+5.6*x+0.06*x*x)),"def":int(floor(14+3.4*x+0.04*x*x)),"spd":int(floor(14+1.25*x))}
	var panel := bare.duplicate()
	for key in bare: panel[key] += int(equipment.get(key,0))
	panel["bare"] = bare
	panel["equipment"] = equipment.duplicate()
	panel["level"] = level
	panel["xp"] = xp
	return panel
