extends SceneTree
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func path_to(w: Node,target: Vector2) -> Array:
	var start:Vector2=w.default_spawn();var q:Array=[start];var previous:Dictionary={start:start};var i:=0
	while i<q.size():
		var at:Vector2=q[i];i+=1
		if at==target:
			var result:Array=[]
			while at!=start:result.push_front(at);at=previous[at]
			return result
		for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next:Vector2=at+direction*16
			if not previous.has(next) and w.player.is_walkable(next):previous[next]=at;q.append(next)
	return []
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_nine_maps.json")).maps
	for map_id in maps:
		var w=World.new();root.add_child(w);w.configure({"id":"physics","map_id":map_id,"cast":[]},Vector2(INF,INF),{})
		w.player.enabled=false
		await physics_frame;await physics_frame
		var targets:Array=[]
		for action in w.layout.actions.values():
			if action.position not in targets:targets.append(action.position)
		for point in w.layout.anchors.values():
			if point not in targets:targets.append(point)
		for target_array in targets:
			w.player.position=w.default_spawn()
			var target:Vector2=w._point(target_array);var path:=path_to(w,target)
			check(target==w.default_spawn() or not path.is_empty(),"real physics path exists")
			for next in path:
				var delta:Vector2=next-w.player.position
				var collision:KinematicCollision2D=w.player.move_and_collide(delta)
				check(collision==null,"continuous move_and_collide clear "+map_id+" "+str(next))
				check(w.player.position.distance_to(next)<0.1,"actual body reaches next grid foot")
			check(w.player.position.distance_to(target)<0.1,"actual body reaches objective")
		w.queue_free();await process_frame
	# Retired soldiers walk their recorded path visually before vanishing; reload never replays this.
	var w=World.new();root.add_child(w);w.configure({"id":"well","map_id":"map_ch09_changzhou_street","cast":[]},Vector2(INF,INF),{})
	var base:Dictionary={"map_id":"map_ch09_changzhou_street","objective_id":"enc_ch09_well_disarm","control_actor_id":"char_liang_xiao","player_position":[432,256],"actor_positions":{"well_soldier_1":[400,224],"well_soldier_2":[464,224]},"visible_actor_ids":["well_soldier_1","well_soldier_2"],"actor_paths":{}}
	w.sync_controlled_view({"world_state":base});check(w.cast_actors.well_soldier_1.visible,"threat initially visible")
	var retired:Dictionary=base.duplicate(true);retired.actor_positions.well_soldier_1=[432,240];retired.visible_actor_ids.erase("well_soldier_1");retired.actor_paths.well_soldier_1=[[400,224],[400,240],[416,240],[432,240]]
	w.sync_controlled_view({"world_state":retired});check(w.cast_actors.well_soldier_1.visible,"retreat not remote disappearance")
	await create_timer(0.35).timeout
	check(not w.cast_actors.well_soldier_1.visible,"hidden only after traversing actual path")
	check(w.cast_actors.well_soldier_1.position==Vector2(432,240),"retreat reaches exit")
	w.configure({"id":"well","map_id":"map_ch09_changzhou_street","cast":[]},Vector2(INF,INF),{})
	w.sync_controlled_view({"world_state":retired});check(not w.cast_actors.well_soldier_1.visible,"restored retired actor not resurrected for replay")
	w.queue_free();await process_frame
	print("CH09 WORLD PHYSICS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
