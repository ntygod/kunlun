extends SceneTree
const World=preload("res://scripts/world.gd")
const Model=preload("res://scripts/world_actions/chapter_nine_world_actions.gd")
const Driver=preload("res://tests/chapter_nine_world_driver.gd")
const Presentation=preload("res://scripts/chapter_nine_world_presentation.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func reachable(w: Node,target: Vector2) -> bool:
	var start:Vector2=w.default_spawn();var q:Array=[start];var seen:Dictionary={start:true};var i:=0
	while i<q.size():
		var at:Vector2=q[i];i+=1
		if at==target:return true
		for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next:Vector2=at+direction*16
			if not seen.has(next) and w.player.is_walkable(next):seen[next]=true;q.append(next)
	return false
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_nine.json"))
	for scene in content.scenes:
		var w=World.new();root.add_child(w);w.configure(scene,Vector2(INF,INF),{"items":{},"world_objects":{}})
		check(not w.layout.is_empty(),scene.id+" map registered")
		check(w.player.is_walkable(w.player.position),"actual player entry collision")
		for id in w.layout.actions:check(reachable(w,w._point(w.layout.actions[id].position)),scene.id+" actual player BFS "+id)
		for id in w.layout.anchors:check(reachable(w,w._point(w.layout.anchors[id])),scene.id+" actual anchor BFS "+id)
		var m=Model.new();m.layout=w.layout
		for y in range(int(w.player.bounds.position.y),int(w.player.bounds.end.y)+1,16):
			for x in range(int(w.player.bounds.position.x),int(w.player.bounds.end.x)+1,16):check(m.is_walkable(Vector2(x,y))==w.player.is_walkable(Vector2(x,y)),"controller collision equals physical player")
		await process_frame;w.queue_free();await process_frame
	for id in Model.IDS:
		for method in (["A","B"] if id=="rescue_ch09_l05" else ["A"]):
			var scene_id:String="ch09_shigong_confrontation" if id==Model.IDS[0] else "ch09_mountain_pursuit" if id==Model.IDS[1] else "L05"
			var map_id:String="map_ch09_shigong_platform" if id==Model.IDS[0] else "map_ch09_pine_terrace" if id==Model.IDS[1] else "map_ch09_west_temple"
			var context:Dictionary={"chapter":9,"current_token":"9:projection:1","revision":1,"scene_id":scene_id,"phase":scene_id,"map_id":map_id,"control_actor_id":Model.H,"objective_id":id}
			var model=Model.new();check(model.begin(id,"projection",context),"driver begin "+id)
			var w=World.new();root.add_child(w);w.configure({"id":scene_id,"map_id":map_id,"cast":[]},Vector2(INF,INF),{})
			for n in range(400):
				w.sync_controlled_view(model.get_view());check(w.player.position==model._p(model.state.position),"actual controlled footpoint")
				for actor in model.state.actor_positions:
					if actor!=model.state.control_actor_id:check(w.cast_actors[actor].position==model._p(model.state.actor_positions[actor]),"actual scene NPC location")
				if model.state.complete:break
				var action:Dictionary=Driver.next_input(model,method)
				if action.is_empty():break
				check(model.apply_input(action).ok,"driver accepted legal action")
			check(model.state.complete,"driver completes "+id+method)
			if id=="rescue_ch09_l05":
				for i in range(1,4):check(not w.cast_actors["npc_ch09_raider_%d"%i].visible,"real departed raider hidden")
				check(model._p(model.state.actor_positions.npc_ch09_physician)==(model._p(model._anchor("doctor_station")) if method=="A" else model._p(model._anchor("physician"))),"A/B truthful doctor location")
			var next_context:Dictionary=context.duplicate(true);next_context.world_objects={"ch09_spatial_state":model.receipt().world_state}
			check(Model.new().begin(id,"again",next_context),"produced spatial projection valid for later session")
			await process_frame;w.queue_free();await process_frame
	# Pure drawing projection does not mutate authoritative inventory or medical resources.
	var w=World.new();root.add_child(w);var scene:Dictionary=content.scenes[-1]
	var items:Dictionary={"item_ch09_general_seal":{"owner":"camp","location":"linan_tent_rack"},"item_ch09_wang_hammer":{"owner":"char_liang_xiao"},"item_ch09_serpent_diamond":{"owner":"char_liang_xiao"}}
	w.configure(scene,Vector2(INF,INF),{"items":items,"world_objects":{}});var before:String=JSON.stringify(w.runtime_context)
	await process_frame;check(JSON.stringify(w.runtime_context)==before,"render cannot mutate resources");w.queue_free();await process_frame
	print("CH09 WORLD PROJECTION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
