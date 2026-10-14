class_name ThreeMoveTrial
extends RefCounted
## A circle-bound, three-exchange objective, not an HP boss or a success button.
const CLUES := [
	{"text":"左肩虚晃，右掌守中。向他的左侧虚位踏进，诱其回掌。","direction":"west","name":"踏向左侧虚位"},
	{"text":"掌风转向左侧，右肋一瞬露空。斜踏右侧，借来势回引。","direction":"east","name":"斜踏右侧借势"},
	{"text":"左右掌势合拢，唯有中路可叠三才。向前半步，三掌合一。","direction":"north","name":"中路进半步"}]
var moves := 0
var observed := false
var direction := ""
var failed := false
var trace: Array = []
func observe() -> String:
	if failed or moves >= 3: return ""
	observed = true
	return CLUES[moves].text
func step(value: String) -> bool:
	if failed or moves >= 3 or value not in ["west","east","north"]: return false
	direction = value
	return true
func strike() -> bool:
	if failed or moves >= 3 or not observed or direction == "": return false
	trace.append({"observed":observed,"direction":direction})
	if direction != CLUES[moves].direction:
		failed = true
		return false
	moves += 1
	observed = false
	direction = ""
	return true
func receipt() -> Dictionary:
	if failed or moves != 3: return {}
	return {"encounter_id":"enc_ch01_three_moves","result":"three_moves_exhausted_taiyin_planted","trace":trace.duplicate(true)}
static func valid_receipt(value: Variant) -> bool:
	if not value is Dictionary or not value.get("trace") is Array or value.trace.size() != 3: return false
	var trial := ThreeMoveTrial.new()
	for entry in value.trace:
		if not entry is Dictionary or not entry.get("observed") is bool or not entry.observed or not entry.get("direction") is String: return false
		trial.observe()
		trial.step(entry.direction)
		if not trial.strike(): return false
	return EncounterSession.equivalent(trial.receipt(),value)
