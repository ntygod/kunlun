extends SceneTree
const W = preload("res://scripts/world.gd")
const C = preload("res://scripts/world_actions/chapter_six_world_actions.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func find_path(world: KunlunWorld,start: Vector2,target: Vector2) -> Array:
	var q: Array = [start]; var prev := {start:start}; var n := 0
	while n<q.size():
		var p: Vector2 = q[n]; n+=1
		if p==target:
			var route: Array = []
			while p!=start: route.push_front(p);p=prev[p]
			return route
		for d in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next: Vector2 = p+d*16
			if not prev.has(next) and world.player.is_walkable(next):prev[next]=p;q.append(next)
	return []
func drive(world: KunlunWorld,target: Vector2) -> bool:
	for i in range(240):
		var delta := target-world.player.position
		if delta.length()<=3: return true
		var action: String = ("move_right" if delta.x>0 else "move_left") if absf(delta.x)>absf(delta.y) else ("move_down" if delta.y>0 else "move_up")
		Input.action_press(action)
		await physics_frame
		Input.action_release(action)
		world._update_paths()
	return false
func run() -> void:
	Engine.time_scale = 4
	for a in ["move_left","move_right","move_up","move_down","interact"]:
		if not InputMap.has_action(a): InputMap.add_action(a)
	var world := W.new();root.add_child(world)
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(C.MAP_PATH)).maps
	var signatures := {}
	for id in maps:
		world.configure({"id":"ch06_test","map_id":id,"cast":[]},Vector2.INF,{})
		await physics_frame
		world.set_runtime_context({"world_objects":{"ch06_spatial_state":{"map_id":id,"control_actor_id":"char_liang_xiao","player_position":[80,240],"actor_positions":{"char_liang_xiao":[80,240]}}}})
		await process_frame
		var signature := JSON.stringify(maps[id].solids)
		check(not signatures.has(signature),id+" distinct physical layout");signatures[signature]=true
		for actor in maps[id].actors:
			check(world.player.is_walkable(Vector2(actor.position[0],actor.position[1])),id+" actor feet walkable "+actor.id)
		for oid in maps[id].actions:
			var g := world.get_objective_geometry(oid)
			check(world.player.is_walkable(g.position),oid+" walkable endpoint")
			check(not find_path(world,world.default_spawn(),g.position).is_empty() or world.default_spawn()==g.position,oid+" reachable")
		for oid in maps[id].actions:
			if maps[id].sessions.has(oid):continue
			world.configure({"id":"ch06_test","map_id":id,"cast":[]},Vector2.INF,{"active_objectives":[{"id":oid,"name":oid,"type":"route"}]})
			await physics_frame
			var g := world.get_objective_geometry(oid)
			if not g.waypoints.is_empty():check(g.waypoints[-1]==g.position,oid+" last point is E endpoint")
			else:g.waypoints=[g.position]
			var previous := world.default_spawn()
			for waypoint in g.waypoints:
				var route := find_path(world,previous,waypoint)
				check(not route.is_empty() or previous==waypoint,oid+" route segment reachable")
				for p in route: check(await drive(world,p),oid+" real held direction reached "+str(p))
				world._update_paths();previous=waypoint
			Input.action_press("interact")
			check(Input.is_action_pressed("interact") and world.nearest().get("action_id","")==oid and (world.get_path_progress(oid).total==0 or world.get_path_progress(oid).complete),oid+" real E after walking endpoint")
			Input.action_release("interact")
	world.queue_free()
	print("CH06 ROUTES: %d checks / %d failures" % [checks,failures]);quit(1 if failures else 0)
