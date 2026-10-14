extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_eight_world_actions.gd")
const Driver=preload("res://tests/chapter_eight_world_driver.gd")
func context() -> Dictionary:return {"chapter":8,"current_token":"8:L04:process","revision":1,"scene_id":"L04","phase":"L04","map_id":"map_ch08_xiangyang_rescue_alley","control_actor_id":Model.H,"objective_id":"rescue_ch08_l04"}
func _initialize() -> void:
	var mode:String=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "write"
	var path:String="user://ch08_world_process.json"
	var fixtures:Array=[]
	if mode=="write":
		for method in ["body","sand"]:
			var m=Model.new()
			if not m.begin("rescue_ch08_l04","process",context()):quit(1);return
			var n:=0
			while n<200 and not ((method=="body" and m.state.carrying!="") or (method=="sand" and m.state.fire_out)):
				if not m.apply_input(Driver.next_input(m,method)).ok:quit(2);return
				n+=1
			if method=="body":m.apply_input({"type":"cancel_support"});m.apply_input({"type":"wait"})
			fixtures.append({"method":method,"snapshot":m.snapshot(),"context":context()})
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(fixtures));file.close()
		print("CH08 WORLD PROCESS: wrote two unfinished legal scenes");quit(0);return
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Array:quit(3);return
	fixtures=parsed
	for fixture in fixtures:
		var m=Model.new()
		if not m.restore(fixture.snapshot,fixture.context):quit(4);return
		if Model._encoded(m.snapshot())!=Model._encoded(fixture.snapshot):quit(5);return
		var n:=0
		while not m.state.complete and n<300:
			if not m.apply_input(Driver.next_input(m,fixture.method)).ok:quit(6);return
			n+=1
		if not m.state.complete or Model.replay_receipt(m.receipt(),fixture.context).is_empty():quit(7);return
	print("CH08 WORLD PROCESS: exact replay and complete both methods in fresh process");quit(0)
