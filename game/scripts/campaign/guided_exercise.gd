class_name GuidedExercise
extends RefCounted
## Small authored writing / stepping exercises; presentation submits concrete input.
var id := ""
var attempt := ""
var state: Dictionary
var input_log: Array = []
var context: Dictionary
func begin(exercise: String, token: String, geometry: Dictionary = {}) -> bool:
	id = exercise
	attempt = token
	context = geometry.duplicate(true)
	state = {"index":0,"observed":false,"complete":false}
	return id in ["jing_writing","name_practice","shadow_practice","breath_practice","burn_practice","step_practice"]
func glyphs() -> Array:
	return ["梁","文","靖","梁","文","靖","梁","文","靖"] if id == "name_practice" else ["靖"]
func apply_input(action: Dictionary) -> Dictionary:
	if state.complete or not action.get("type") is String: return {"ok":false}
	var accepted := false
	if id in ["jing_writing","name_practice"]:
		var glyph: String = glyphs()[int(state.index)]
		accepted = action.get("type") == "glyph" and action.get("glyph") is String and action.glyph == glyph and ChapterRuntime._integer(action.get("strokes")) and int(action.strokes) == {"梁":11,"文":4,"靖":13}[glyph]
		if accepted: accepted = _trace_valid(glyph,action.get("points"))
		if accepted: state.index += 1
		state.complete = int(state.index) == glyphs().size()
	elif action.get("type") == "observe":
		state.observed = true
		accepted = true
	elif state.observed and action.get("type") == "perform" and action.get("value") is String:
		var expected: Array = ["抬肘","旋腕","弓步"] if id in ["shadow_practice","step_practice"] else (["吸气","静息","呼气"] if id == "breath_practice" else ["选取本题散页","投入火盆","饮下参汤"])
		accepted = action.value == expected[int(state.index)]
		if id == "shadow_practice":
			var points: Array = context.get("waypoints",[])
			var position: Variant = action.get("position")
			accepted = accepted and points.size() == 3 and CampaignState._position_valid(position)
			if accepted:
				var point: Array = points[int(state.index)]
				accepted = Vector2(position[0],position[1]).distance_to(Vector2(point[0],point[1])) <= 14
		if accepted:
			state.index += 1
			state.observed = false
			state.complete = int(state.index) == 3
	if accepted: input_log.append(action.duplicate(true))
	return {"ok":accepted,"receipt":receipt(),"view":get_view()}
func get_view() -> Dictionary:
	return {"puzzle_id":id,"state":state.duplicate(true),"glyph":glyphs()[mini(int(state.index),glyphs().size()-1)] if id in ["jing_writing","name_practice"] else ""}
func receipt() -> Dictionary:
	return {"puzzle_id":id,"attempt_id":attempt,"input_log":input_log.duplicate(true),"final_state":state.duplicate(true)} if state.complete else {}
func snapshot() -> Dictionary: return {"puzzle_id":id,"attempt_id":attempt,"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved: Variant, trusted_context: Dictionary = {}) -> bool:
	if not saved is Dictionary or not saved.get("puzzle_id") is String or not saved.get("attempt_id") is String or not saved.get("input_log") is Array or saved.input_log.size()>300: return false
	var replay := GuidedExercise.new()
	if not replay.begin(saved.puzzle_id,saved.attempt_id,trusted_context): return false
	for action in saved.input_log:
		if not action is Dictionary or not replay.apply_input(action).ok: return false
	if not EncounterSession.equivalent(replay.snapshot(),saved): return false
	id=replay.id;attempt=replay.attempt;state=replay.state;input_log=replay.input_log;context=replay.context
	return true

func _trace_valid(glyph: String, points: Variant) -> bool:
	if not points is Array: return false
	var board := GlyphBoard.new()
	board.setup(glyph)
	var valid: bool = points.size() == board.strokes.size()*2
	if valid:
		for i in range(board.strokes.size()):
			for end in range(2):
				var point: Variant = points[i*2+end]
				var expected: Array = board.strokes[i][0 if end == 0 else -1]
				if not CampaignState._position_valid(point) or Vector2(point[0],point[1]).distance_to(Vector2(expected[0],expected[1]))>0.12: valid=false;break
	board.free()
	return valid
