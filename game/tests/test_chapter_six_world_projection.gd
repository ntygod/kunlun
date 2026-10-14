extends SceneTree
const W=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var world=W.new();root.add_child(world)
	var cases:Array=[{}, {"world_objects":{"ch06_roof":{"state":"repaired"},"ch06_hearth":{"fire":"lit","bowl":"item_ch06_old_bowl","tended_by":"char_axue"}},"items":{"item_ch06_bucket":{"owner":"ch06_home","state":"placed","location":"well","form":"watertight"},"item_ch06_wind_bird":{"owner":"ch06_home","state":"placed","location":"eaves"}}}, {"items":{"item_ch06_letter_box":{"owner":"npc_zhao_shan","state":"delivered","location":"family_letter"}}}]
	for i in range(cases.size()):
		var context:Dictionary=cases[i];var before:=JSON.stringify(context)
		world.configure({"id":"ch06_projection","map_id":"map_ch06_old_home","cast":[]},Vector2.INF,context)
		await process_frame
		var props:Dictionary=world.chapter_six_visible_props()
		check(props.roof_repaired==(i==1),"roof verified only")
		check(props.bucket_made==(i==1),"bucket verified only")
		check(props.hearth_lit==(i==1),"hearth verified only")
		check(props.wind_bird==(i==1),"eave bird choice")
		check(props.letter_box==(i==2),"delivered box choice")
		check(not (props.wind_bird and props.letter_box),"exclusive source choice")
		world.configure({"id":"ch06_other","map_id":"map_ch06_threshing_ground","cast":[]},Vector2.INF,context)
		await process_frame
		world.configure({"id":"ch06_return","map_id":"map_ch06_old_home","cast":[]},Vector2.INF,JSON.parse_string(JSON.stringify(context)))
		await process_frame
		check(world.chapter_six_visible_props()==props,"revisit JSON load stable")
		check(JSON.stringify(context)==before,"presentation never mutates items")
	world.queue_free();print("CH06 PROJECTION: %d checks / %d failures"%[checks,failures]);quit(1 if failures else 0)
