extends SceneTree
const C=preload("res://scripts/world_actions/chapter_six_world_actions.gd")
const D=preload("res://tests/chapter_six_world_driver.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for id in C.IDS:
		var context:Dictionary=D.preview_context(id);var c=C.new()
		check(c.begin(id,"test",context),id+" begin")
		var before:Dictionary=c.snapshot()
		check(not c.apply_input({"type":"interact","success":true}).get("ok",false),id+" injected success")
		check(C._encoded(before)==C._encoded(c.snapshot()),id+" injection atomic")
		for n in range(200):
			if c.state.complete:break
			var action:Dictionary=D.next_input(c.get_view())
			check(not action.is_empty(),id+" route exists")
			check(c.apply_input(action).get("ok",false),id+" actual input")
			var saved:Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()));var restored=C.new()
			check(restored.restore(saved,context),id+" JSON restore")
			check(C._encoded(restored.snapshot())==C._encoded(c.snapshot()),id+" exact state")
		check(c.state.complete,id+" completed")
		check(not C.replay_receipt(c.receipt(),context).is_empty(),id+" replay")
		if not c.state.complete:continue
		var proof:Dictionary=c.receipt();proof.world_state.player_position=[-999,-999]
		check(C.replay_receipt(proof,context).is_empty(),id+" forged proof")
		var stable:=c.snapshot();var bad:=stable.duplicate(true);bad.state.stage=999
		check(not c.restore(bad,context),id+" forged snapshot")
		check(C._encoded(stable)==C._encoded(c.snapshot()),id+" restore atomic")
		var wall:Array=c.layout.solids[0]
		for value in [[-16,240],[161,240],[wall[0]+16,wall[1]+16],[160],["bad",240]]:
			var polluted:=context.duplicate(true);polluted.world_objects={"ch06_spatial_state":{"map_id":c.map_id,"actor_positions":{"char_axue":value}}}
			check(not c.begin(id,"polluted",polluted),id+" invalid coordinate")
			check(C._encoded(stable)==C._encoded(c.snapshot()),id+" begin atomic")
		check(c.apply_input({"type":"retry"}).get("ok",false),id+" retry")
		check(not c.state.complete,id+" retry reset")
	# Investigations are genuinely unordered: walk to bowl first, then plane, then door.
	var free=C.new();check(free.begin("old_home_three_objects_verified","unordered",{}),"unordered begin")
	for target in [Vector2(320,240),Vector2(240,240),Vector2(160,240)]:
		while Vector2(free.state.position[0],free.state.position[1])!=target:
			var dx:int=1 if target.x>free.state.position[0] else -1
			check(free.apply_input({"type":"move","dx":dx,"dy":0}).ok,"unordered actual move")
		check(free.apply_input({"type":"interact"}).ok,"unordered E")
	check(free.state.complete and free.state.visited==["old_bowl","old_plane","door_marks"],"unordered exact investigation")
	check(not C.replay_receipt(free.receipt(),{}).is_empty(),"unordered replay")
	# Saturated logs remain recoverable through a real retry input, never edited state.
	var full=C.new();check(full.begin("bamboo_gathered_verified","full",{}),"log begin")
	for i in range(C.LIMIT):full.apply_input({"type":"wait"})
	check(not full.apply_input({"type":"wait"}).ok,"log bounded")
	check(full.apply_input({"type":"retry"}).ok,"full log retry")
	check(full.input_log.size()==1 and full.state.stage==0,"full log fresh trusted start")
	for i in range(100):
		if full.state.complete:break
		check(full.apply_input(D.next_input(full.get_view())).ok,"retry real completion")
	check(not C.replay_receipt(full.receipt(),{}).is_empty(),"full log retry proof")
	# Source-role and unique-object prerequisites are not created by input.
	for id in ["sword_reclaimed_ch06","borrowed_body_recovery","r03_soak_verified"]:check(not C.new().begin(id,"missing",{}),id+" missing item rejected")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(C.MAP_PATH))
	for mid in data.maps:
		var m:Dictionary=data.maps[mid]
		for anchor in m.anchors:check(C._valid_point(m.anchors[anchor],m),mid+" anchor "+anchor)
		for actor in m.actors:check(C._valid_point(actor.position,m),mid+" actor "+actor.id)
		for id in m.paths:check(m.paths[id].back()==m.actions[id].position,id+" route ends at E")
	print("Chapter six world: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
