extends SceneTree
const M=preload("res://scripts/world_actions/chapter_nine_world_actions.gd")
const D=preload("res://tests/chapter_nine_world_driver.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func context() -> Dictionary:return {"chapter":9,"current_token":"boundary-token","revision":1,"scene_id":"L05","phase":"L05","map_id":"map_ch09_west_temple","control_actor_id":"char_liang_xiao","objective_id":"rescue_ch09_l05","world_objects":{},"items":{},"actors":{},"choices":{},"inherited_choices":{},"knowledge":[]}
func named(value: Variant) -> Variant:
	if value is String:return StringName(value)
	if value is Array:
		var result:Array=[]
		for item in value:result.append(named(item))
		return result
	if value is Dictionary:
		var result:Dictionary={}
		for key in value:result[StringName(key) if key is String else key]=named(value[key])
		return result
	return value
func advance_to(m: RefCounted,method: String,flag: String) -> void:
	for i in range(500):
		if m.state[flag]:return
		var action:Dictionary=D.next_input(m,method);check(not action.is_empty() and m.apply_input(action).ok,"real route to "+flag)
	check(false,"could not reach "+flag)
func _initialize() -> void:
	var m=M.new();check(m.begin(&"rescue_ch09_l05",&"names",named(context())),"actual StringName begin")
	check(m.apply_input({&"type":&"interact"}).ok,"actual StringName input")
	var restored=M.new();check(restored.restore(named(m.snapshot()),named(context())),"actual nested StringName snapshot")
	check(M._encoded(m.snapshot())==M._encoded(restored.snapshot()),"StringName exact normalized snapshot")
	for bad in [{"type":true},{"type":"move","dx":0,"other":1},{"type":"lock","slot":false,"symbol":"leaf"},{"type":"method","value":true}]:
		var before:String=M._encoded(m.snapshot());check(not m.apply_input(bad).ok,"reject bad type or same-count missing key");check(before==M._encoded(m.snapshot()),"bad input atomic")
	for key in ["current_token","revision","map_id","scene_id","objective_id"]:
		var bad:=context();bad[key]=true;var before:String=M._encoded(m.snapshot())
		check(not m.begin("rescue_ch09_l05","bad",bad),"reject bool context "+key);check(before==M._encoded(m.snapshot()),"bad begin atomic")
	var missing:=context();missing.erase("revision");missing["extra"]=1;check(not m.begin("rescue_ch09_l05","missing",missing),"same-count context missing key")
	var bad_snapshot:Dictionary=m.snapshot();bad_snapshot.erase("state");bad_snapshot["other"]={};var before:String=M._encoded(m.snapshot());check(not m.restore(bad_snapshot,context()),"same-count snapshot missing state");check(before==M._encoded(m.snapshot()),"bad restore atomic")
	var lock=M.new();check(lock.begin("rescue_ch09_l05","lock",context()),"lock no-op begin")
	advance_to(lock,"A","inspected");before=M._encoded(lock.snapshot())
	var same:Dictionary=lock.apply_input({"type":"lock","slot":2,"symbol":"fruit"})
	check(same.ok and same.get("no_op",false),"already aligned slot explicit no-op")
	check(before==M._encoded(lock.snapshot()) and not lock.state.unlocked,"same slot cannot trigger unlock or any stage")
	var doctor=M.new();check(doctor.begin("rescue_ch09_l05","doctor",context()),"doctor wait begin")
	advance_to(doctor,"A","escorting")
	for i in range(100):
		if doctor._near("box"):break
		check(doctor.apply_input(D.next_input(doctor,"A")).ok,"doctor continuous return route")
	# Approach the chest from the south, leaving one real edge to the side station.
	for dy in [1,1,-1,-1]:check(doctor.apply_input({"type":"move","dx":0,"dy":dy}).ok,"escort southern approach")
	var doctor_before:Array=doctor.state.actor_positions.npc_ch09_physician.duplicate();var doctor_count:int=doctor.input_log.size()
	var doctor_wait:Dictionary=doctor.apply_input({"type":"wait"})
	check(doctor_wait.ok and not doctor_wait.get("no_op",false),"moving physician wait retained")
	check(doctor.input_log.size()==doctor_count+1 and doctor_before!=doctor.state.actor_positions.npc_ch09_physician,"physician advances to actual station")
	advance_to(m,"A","returned_box");check(m.state.returned_box,"doctor truly returned before idle stress")
	before=M._encoded(m.snapshot());var count:int=m.input_log.size()
	for i in range(4100):
		var result:Dictionary=m.apply_input({&"type":&"wait"});check(result.ok and result.get("no_op",false),"idle wait explicit no-op")
	check(m.input_log.size()==count and M._encoded(m.snapshot())==before,"4100 idle waits preserve exact prefix and rescued facts")
	check(m.apply_input({"type":"inspect"}).ok and M._encoded(m.snapshot())==before,"inspection consumes no action history")
	var reload=M.new();check(reload.restore(JSON.parse_string(JSON.stringify(m.snapshot())),context()),"idle-stress actual JSON restore")
	check(reload.apply_input(D.next_input(reload,"A")).ok,"real move still accepted after idle stress")
	for i in range(500):
		if reload.state.complete:break
		check(reload.apply_input(D.next_input(reload,"A")).ok,"complete after idle stress")
	check(reload.state.complete,"idle stress no side soft-lock")
	check(not M.replay_receipt(named(reload.receipt()),named(context())).is_empty(),"StringName full proof")
	# A retreat wait is not cosmetic: it changes the actual recorded NPC location.
	var active=M.new();check(active.begin("rescue_ch09_l05","active",context()),"active begin")
	advance_to(active,"B","patrol_lured")
	var old_position:Array=active.state.actor_positions.npc_ch09_patrol.duplicate();count=active.input_log.size()
	var result:Dictionary=active.apply_input({"type":"wait"})
	check(result.ok and not result.get("no_op",false),"moving patrol wait not deduplicated")
	check(active.input_log.size()==count+1 and old_position!=active.state.actor_positions.npc_ch09_patrol,"moving patrol physically advances and records input")
	for i in range(500):
		if active.state.looters.npc_ch09_raider_1.disarmed:break
		check(active.apply_input(D.next_input(active,"B")).ok,"B reach actual raider retreat")
	old_position=active.state.actor_positions.npc_ch09_raider_1.duplicate();count=active.input_log.size();result=active.apply_input({"type":"wait"})
	check(result.ok and not result.get("no_op",false),"moving raider wait not deduplicated")
	check(active.input_log.size()==count+1 and old_position!=active.state.actor_positions.npc_ch09_raider_1,"moving raider actual path retained")
	print("CH09 WORLD BOUNDARIES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
