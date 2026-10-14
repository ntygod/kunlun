extends SceneTree
const C=preload("res://scripts/world_actions/chapter_seven_world_actions.gd")
const D=preload("res://tests/chapter_seven_world_driver.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for id in C.IDS:
		var context:=D.preview_context(id);var c=C.new()
		check(c.begin(id,"test",context),id+" begin")
		var before:Dictionary=c.snapshot()
		check(not c.apply_input({"type":"interact","success":true}).get("ok",false),id+" reject injected success")
		check(C._encoded(before)==C._encoded(c.snapshot()),id+" injection atomic")
		var helper_steps:=0
		for n in range(200):
			if c.state.complete:break
			var action:=D.next_input(c.get_view())
			check(not action.is_empty(),id+" route exists")
			if action.is_empty():break
			var helper_before:Vector2=Vector2(c.state.actor_positions.npc_shi_futong[0],c.state.actor_positions.npc_shi_futong[1])
			check(c.apply_input(action).get("ok",false),id+" actual action")
			var helper_after:Vector2=Vector2(c.state.actor_positions.npc_shi_futong[0],c.state.actor_positions.npc_shi_futong[1])
			check(helper_before.distance_to(helper_after)<=16,id+" helper walks one physical step")
			if helper_before!=helper_after:helper_steps+=1
			check(action.type!="wait",id+" no forced waiting")
			var saved:Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()));var restored=C.new()
			check(restored.restore(saved,context),id+" JSON restore")
			check(C._encoded(restored.snapshot())==C._encoded(c.snapshot()),id+" exact replay")
		check(c.state.complete,id+" completed")
		check(helper_steps>0,id+" helper moved concurrently")
		check(not C.replay_receipt(c.receipt(),context).is_empty(),id+" receipt replay")
		var stable:=c.snapshot()
		for key in ["current_token","revision","phase","map_id","objective_id","control_actor_id","chapter"]:
			var bad:=context.duplicate(true);bad[key]="bad" if key!="revision" and key!="chapter" else -1
			check(C.replay_receipt(c.receipt(),bad).is_empty(),id+" reject context "+key)
			check(not c.restore(stable,bad),id+" restore rejects "+key)
			check(C._encoded(c.snapshot())==C._encoded(stable),id+" failed restore atomic")
		var proof:=c.receipt();proof.world_state.player_position=[-999,-999]
		check(C.replay_receipt(proof,context).is_empty(),id+" reject forged position")
		for position in [[-16,240],[161,240],[160],["bad",240]]:
			var polluted:=context.duplicate(true);polluted.world_objects.ch07_spatial_state={"map_id":c.map_id,"actor_positions":{"char_axue":position}}
			check(not c.begin(id,"bad",polluted),id+" invalid prior position")
		check(c.apply_input({"type":"retry"}).ok and not c.state.complete,id+" retry")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(C.MAP_PATH))
	for mid in data.maps:
		var m:Dictionary=data.maps[mid]
		for anchor in m.anchors:check(C._valid_point(m.anchors[anchor],m),mid+" anchor "+anchor)
		for actor in m.actors:check(C._valid_point(actor.position,m),mid+" actor "+actor.id)
		for id in m.actions:
			check(C._valid_point(m.actions[id].position,m),id+" physical entry")
			check(reachable(m,m.spawn,m.actions[id].position),id+" connected physical entry")
	var bridge:Dictionary=data.maps.map_ch07_yunxing_chain_bridge
	check(not reachable(bridge,bridge.anchors.west_bank,bridge.anchors.east_bank),"broken bridge separates banks")
	check(not C._valid_point([320,240],bridge),"deep chasm blocks free walking")
	var chapters:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven_runtime.json"))
	for scene in chapters.scenes:
		for action in runtime.scenes[scene.id]:check(data.maps[scene.map_id].actions.has(action.id),"runtime entry exists "+action.id)
	print("Chapter seven world: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
func reachable(m: Dictionary,from: Array,to: Array) -> bool:
	var q:Array=[Vector2(from[0],from[1])];var seen:Dictionary={q[0]:true};var index:=0
	while index<q.size():
		var p:Vector2=q[index];index+=1
		if p==Vector2(to[0],to[1]):return true
		for delta in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
			var next:Vector2=p+delta*16
			if not seen.has(next) and C._valid_point([next.x,next.y],m):seen[next]=true;q.append(next)
	return false
