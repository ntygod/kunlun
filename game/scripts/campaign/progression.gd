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
const COEFFICIENTS := {
	"char_liang_xiao":{"max_hp":[150.0,38.0,0.45],"max_mp":[45.0,3.8,0.0],"atk":[24.0,5.6,0.06],"def":[14.0,3.4,0.04],"spd":[14.0,1.25,0.0]},
	"char_hua_xiaoshuang":{"max_hp":[125.0,30.0,0.35],"max_mp":[55.0,4.5,0.0],"atk":[18.0,4.2,0.04],"def":[12.0,3.0,0.03],"spd":[13.0,1.15,0.0]},
	"char_huasheng":{"max_hp":[190.0,52.0,0.65],"max_mp":[35.0,2.8,0.0],"atk":[26.0,5.8,0.06],"def":[18.0,4.6,0.055],"spd":[10.0,0.85,0.0]},
	"char_liu_yingying":{"max_hp":[135.0,33.0,0.38],"max_mp":[40.0,3.4,0.0],"atk":[23.0,5.3,0.055],"def":[11.0,2.8,0.03],"spd":[17.0,1.55,0.0]}}
static func liang_panel(xp: int, equipment: Dictionary = {}) -> Dictionary:
	return actor_panel("char_liang_xiao",xp,equipment)
static func actor_panel(actor_id: String, xp: int, equipment: Dictionary = {}) -> Dictionary:
	if not COEFFICIENTS.has(actor_id): return {}
	var level := level_from_xp(xp)
	var x := 39.0*float(level-1)/79.0
	var bare := {}
	for key in COEFFICIENTS[actor_id]:
		var terms: Array=COEFFICIENTS[actor_id][key]
		bare[key]=int(floor(float(terms[0])+float(terms[1])*x+float(terms[2])*x*x))
	var panel := bare.duplicate()
	for key in bare: panel[key] += int(equipment.get(key,0))
	panel["bare"] = bare
	panel["equipment"] = equipment.duplicate()
	panel["level"] = level
	panel["xp"] = xp
	return panel
