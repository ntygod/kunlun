extends SceneTree
const World=preload("res://scripts/world.gd")
const Model=preload("res://scripts/world_actions/chapter_eight_world_actions.gd")
const Driver=preload("res://tests/chapter_eight_world_driver.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func reachable(world: Node,target: Vector2) -> bool:
	var start:Vector2=world.default_spawn()
	var q:Array=[start];var seen:Dictionary={start:true};var i:=0
	while i<q.size():
		var p:Vector2=q[i];i+=1
		if p==target:return true
		for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next:Vector2=p+direction*16
			if not seen.has(next) and world.player.is_walkable(next):seen[next]=true;q.append(next)
	return false
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_eight.json"))
	var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_eight_maps.json")).maps
	for scene in content.scenes:
		var world=World.new();root.add_child(world)
		world.configure(scene,Vector2(INF,INF),{"items":{},"world_objects":{},"actor_appearances":{"char_liang_xiao":"youth_age_18"}})
		check(not world.layout.is_empty(),scene.id+" semantic map loads")
		check(world.player.is_walkable(world.player.position),scene.id+" physical entry reachable")
		for id in world.layout.actions:check(reachable(world,world._point(world.layout.actions[id].position)),scene.id+" physical action "+id)
		check(not world.chapter_eight_presentation().ballista_destroyed,"no false destruction from scene ID")
		check(not world.chapter_eight_presentation().fire_spread,"no false fire from entering city")
		world.set_runtime_context({"items":{},"world_objects":{"ch08_ballista":{"state":"destroyed"},"ch08_fire":{"spread":"uncontrolled_civilian_district"}}})
		check(world.chapter_eight_presentation().ballista_destroyed,"same real ballista projection")
		check(world.chapter_eight_presentation().fire_spread,"real fire delta projection")
		await process_frame
		world.queue_free();await process_frame
	check(maps.map_ch08_fancheng_outer_battery.name!=maps.map_ch08_xiangyang_north_battery.name,"two cities distinct")
	check(maps.map_ch08_fancheng_outer_battery.exits[0].target_map_id=="map_ch08_xiangyang_north_battery","river transition explicit")
	for id in Model.IDS:
		var scene_id:String="ch08_hanshui_approach" if id=="route_ch08_hanshui" else "ch08_ballista_repair" if id=="repair_ch08_ballista" else "L04"
		var map_id:String="map_ch08_hanshui_chain_waterway" if id=="route_ch08_hanshui" else "map_ch08_island_platform" if id=="repair_ch08_ballista" else "map_ch08_xiangyang_rescue_alley"
		for method in (["body","sand"] if id=="rescue_ch08_l04" else ["body"]):
			var context:Dictionary={"chapter":8,"current_token":"8:projection:1","revision":1,"scene_id":scene_id,"phase":scene_id,"map_id":map_id,"control_actor_id":Model.H,"objective_id":id}
			var model=Model.new();check(model.begin(id,"projection",context),"driver begin "+id)
			var n:=0
			while not model.state.complete and n<300:
				var action:Dictionary=Driver.next_input(model,method)
				if action.is_empty():break
				check(model.apply_input(action).ok,"driver legal "+id);n+=1
			check(model.state.complete,"real command driver completes "+id+method)
			var next_context:Dictionary=context.duplicate(true);next_context.world_objects={"ch08_spatial_state":model.receipt().get("world_state",{})}
			check(Model.new().begin(id,"prior",next_context),"self-produced positions remain valid "+id)
			var world=World.new();root.add_child(world)
			world.configure({"id":scene_id,"map_id":map_id,"cast":[]},Vector2(INF,INF),{})
			world.sync_controlled_view(model.get_view())
			check(world.player.position==model._p(model.state.position),"controlled actor actual position")
			if id=="rescue_ch08_l04":
				check(not world.cast_actors.npc_ch08_looter_spear.visible and not world.cast_actors.npc_ch08_looter_sabre.visible,"departed soldiers absent")
				check(world.cast_actors.npc_ch08_l04_grandmother.position==model._p(model._anchor("shelter")),"grandmother physically at shelter")
			await process_frame;world.queue_free();await process_frame
	print("CH08 WORLD PROJECTION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
