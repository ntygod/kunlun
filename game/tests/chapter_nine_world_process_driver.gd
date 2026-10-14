extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_nine_world_actions.gd")
const Driver=preload("res://tests/chapter_nine_world_driver.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func context() -> Dictionary:return {"chapter":9,"current_token":"chapter9:process:1","revision":1,"scene_id":"L05","phase":"L05","map_id":"map_ch09_west_temple","control_actor_id":"char_liang_xiao","objective_id":"rescue_ch09_l05","world_objects":{},"items":{},"actors":{},"choices":{},"inherited_choices":{},"knowledge":[]}
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=3:printerr("Expected write/read A/B path");quit(2);return
	var mode:String=args[0];var method:String=args[1];var path:String=args[2];var m=Model.new()
	if mode=="write":
		check(m.begin("rescue_ch09_l05","process",context()),"begin")
		for i in range(500):
			var ready:bool=(method=="A" and m.state.escorting and m.state.actor_paths.npc_ch09_physician.size()>3) or (method=="B" and m.state.decoys and not m.state.patrol_lured)
			if ready:break
			var action:Dictionary=Driver.next_input(m,method);check(not action.is_empty() and m.apply_input(action).ok,"real partial input")
		check(not m.state.complete,"actually partial")
		var file:=FileAccess.open(path,FileAccess.WRITE);check(file!=null,"disk open")
		if file:file.store_string(JSON.stringify({"context":context(),"snapshot":m.snapshot(),"method":method}));file.close()
	else:
		var saved:Variant=JSON.parse_string(FileAccess.get_file_as_string(path));check(saved is Dictionary,"read actual file")
		if saved is Dictionary:
			check(m.restore(saved.snapshot,saved.context),"independent process restore")
			check(not m.state.complete,"restored actual partial")
			for i in range(500):
				if m.state.complete:break
				var action:Dictionary=Driver.next_input(m,method);check(not action.is_empty() and m.apply_input(action).ok,"continue genuine input")
			check(m.state.complete,"finish after reload")
			check(not Model.replay_receipt(JSON.parse_string(JSON.stringify(m.receipt())),context()).is_empty(),"full disk proof valid")
			check(m.state.returned_box==(method=="A"),"branch truthful physician")
	print("CH09 WORLD PROCESS %s %s: %d checks, %d failures"%[mode,method,checks,failures]);quit(1 if failures else 0)
