extends SceneTree
const C = preload("res://scripts/world_actions/chapter_four_world_actions.gd")
const Driver = preload("res://tests/chapter_four_world_driver.gd")
const W = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func path(c, target: Vector2) -> Array:
	var start: Vector2 = c._p(c.state.position)
	var q: Array = [start]; var prev := {start:start}; var n := 0
	while n < q.size():
		var p: Vector2 = q[n]; n += 1
		if p == target:
			var result: Array = []
			while p != start: result.push_front(p-prev[p]); p = prev[p]
			return result
		for d in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next: Vector2 = p+d*16
			if not prev.has(next) and c.is_walkable(next): prev[next] = p; q.append(next)
	return []
func walk(c, anchor: String) -> void:
	var target: Vector2 = c._p(c._anchor(anchor))
	var route := path(c,target)
	check(not route.is_empty() or c._p(c.state.position)==target,c.puzzle_id+" reachable "+anchor)
	var step := 0
	for d in route:
		step += 1
		check(c.apply_input({"type":"move","dx":int(d.x/16),"dy":int(d.y/16)}).ok,c.puzzle_id+" actual input walk")
		if step%7 == 0:
			var resume = C.new()
			check(resume.restore(JSON.parse_string(JSON.stringify(c.snapshot())),c.context),"mid-route F5/F9 replay")
			check(resume._hash_state()==c._hash_state(),"mid-route state unchanged")
	check(c._p(c.state.position)==target,c.puzzle_id+" reached exact endpoint")
func finish(c) -> void:
	if c.puzzle_id == "gate_encounter_verified":
		walk(c,"gate_guard"); check(c.apply_input({"type":"inspect"}).ok,"inspect at gate")
		for i in range(2): check(c.apply_input({"type":"guard"}).ok,"real guarded approach")
	for i in range(12):
		if c.state.complete: break
		walk(c,c._next_anchor())
		if c.puzzle_id == "bell_response_verified" and c._inscription():
			check(c.apply_input({"type":"choose_fragment","value":c.state.fragments.size()}).ok,"ordered fragment")
		else:
			var result: Dictionary = c.apply_input({"type":"interact"})
			if c.puzzle_id == "horse_call_and_arrival" and not c.state.horse_arrived:
				for t in range(8): c.apply_input({"type":"wait"})
			else: check(result.ok,c.puzzle_id+" E at actual endpoint")
	check(c.state.complete,c.puzzle_id+" completed")
	check(not C.replay_receipt(c.receipt(),c.context).is_empty(),c.puzzle_id+" exact receipt replay")
	var other = C.new(); check(other.restore(JSON.parse_string(JSON.stringify(c.snapshot())),c.context),c.puzzle_id+" JSON restore")
	var bad_snapshot: Dictionary = c.snapshot().duplicate(true)
	bad_snapshot.input_log.append({"type":"success"})
	check(not other.restore(bad_snapshot,c.context),c.puzzle_id+" unknown input in snapshot rejected")
	var bad: Dictionary = c.receipt().duplicate(true); bad.after_state_hash = "fake"
	check(C.replay_receipt(bad,c.context).is_empty(),c.puzzle_id+" tamper rejected")
func run() -> void:
	var window = C.new(); window.begin("window_anchor_verified","horse_chain",{})
	check(window._p(window.state.horse_position) == Vector2(48,240),"same horse waits at initial anchor before rope")
	finish(window)
	check(window._p(window.state.horse_position) == Vector2(48,240),"window work leaves horse at real waiting position")
	var horse_context := {"world_objects":{"ch04_spatial_state":window.receipt().world_state}}
	var called = C.new(); called.begin("horse_call_and_arrival","horse_chain",horse_context)
	check(called.state.horse_position == window.state.horse_position,"call inherits same horse without reset")
	check(called.apply_input({"type":"interact"}).ok,"whistle from actual cleared window")
	for phase in range(6):
		check(called.state.horse_position == [64+phase*16,240],"horse advances exactly one cell each phase")
		check(called.state.horse_arrived == (phase == 5),"arrival only on sixth real phase")
		var resumed = C.new()
		check(resumed.restore(JSON.parse_string(JSON.stringify(called.snapshot())),horse_context),"every horse phase JSON save/replay")
		check(resumed._hash_state() == called._hash_state(),"horse phase position survives restore")
		if phase < 5: check(called.apply_input({"type":"wait"}).ok,"bounded real horse wait")
	check(called.apply_input({"type":"interact"}).ok and called.state.complete,"jump reaches arrived same horse")
	check(called.state.position == called.state.horse_position,"mounted leader and horse share landing")
	check(not C.replay_receipt(called.receipt(),horse_context).is_empty(),"continuous window and horse receipt replay")
	for id in C.IDS:
		var c = C.new(); check(c.begin(id,"test",{}),id+" begins")
		check(not c.apply_input({"type":"interact","success":true}).get("ok",true),"no forged success")
		check(not c.apply_input({"type":"move","dx":1,"dy":0,"position":[100,100]}).get("ok",true),"no forged position")
		finish(c)
	for method in ["boat","spring"]:
		var context := {"shelter_method":method,"world_objects":{}}
		for id in ["liu_carried_not_combat","shelter_route_verified","shelter_care_performed","patrol_escape_verified","horse_release_verified","horse_calm_and_led"]:
			var c = C.new(); c.begin(id,"chain",context); finish(c)
			context.world_objects.ch04_spatial_state = c.receipt().get("world_state",{})
	var boat = C.new(); boat.begin("shelter_care_performed","screen",{"shelter_method":"boat"})
	check(boat.line_visible(Vector2(400,240),Vector2(400,304)),"open boat screen allows ray")
	check(boat.apply_input({"type":"interact"}).ok,"actual boat screen closes at boat")
	check(not boat.line_visible(Vector2(400,240),Vector2(400,304)),"closed opaque screen blocks actual ray")
	var bell = C.new(); bell.begin("bell_response_verified","inscription",{"choices":{"bell_attention":"ch04_bell_inscription"}}); finish(bell)
	check(C.swept_contact(Vector2(0,0),Vector2(16,0),Vector2(16,0),Vector2(0,0)),"swapped-cell collision")
	check(C.swept_contact(Vector2(0,0),Vector2(16,16),Vector2(16,0),Vector2(0,16)),"crossing-segment collision")
	var full = C.new(); full.begin("moor_and_sit","full",{})
	for i in range(C.LIMIT): full.apply_input({"type":"wait"})
	check(not full.apply_input({"type":"wait"}).get("ok",true),"bounded log")
	check(full.apply_input({"type":"retry"}).ok,"full log can recover"); finish(full)
	for id in C.IDS:
		var driven = C.new();driven.begin(id,"shared_driver",{})
		for step in range(160):
			if driven.state.complete:break
			var action: Dictionary=Driver.next_input(driven.get_view())
			check(not action.is_empty() and driven.apply_input(action).get("ok",false),id+" shared real-input driver")
		check(driven.state.complete,id+" driver complete")
	var caught = C.new(); caught.begin("patrol_escape_verified","capture",{})
	for d in path(caught,Vector2(208,144)):
		caught.apply_input({"type":"move","dx":int(d.x/16),"dy":int(d.y/16)})
		if caught.state.captured: break
	for tick in range(6):
		if caught.state.captured: break
		caught.apply_input({"type":"wait"})
	check(caught.state.captured,"real patrol ray captures legal movement")
	check(not caught.apply_input({"type":"interact"}).ok,"capture prevents completion")
	check(caught.apply_input({"type":"retry"}).ok and not caught.state.captured,"capture retry restores segment")
	var gate = C.new(); gate.begin("gate_encounter_verified","early",{})
	check(not gate.apply_input({"type":"guard"}).ok,"guard outside position rejected")
	walk(gate,"chu_wan")
	check(not gate.apply_input({"type":"interact"}).ok,"restraint before real approaches rejected")
	var wrong = C.new(); check(not wrong.begin("gate_encounter_verified","wrong",{"objective_id":"chu_wan_released"}),"scope mismatch rejected")
	var player = KunlunPlayer.new(); player.water_rects.append(Rect2(0,0,32,32))
	check(player.terrain_speed_multiplier(Vector2(16,16))==0.5,"shallow water penalty")
	player.water_penalty_removed = true
	check(player.terrain_speed_multiplier(Vector2(16,16))==1.0 and player.speed==65,"L01 removes penalty only")
	player.free()
	print("CH04 WORLD: %d checks / %d failures" % [checks,failures]); quit(1 if failures else 0)
