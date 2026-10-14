extends SceneTree
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func reachable(world: KunlunWorld, from: Vector2, target: Vector2) -> bool:
	var start := (from / 4).round() * 4
	var frontier: Array[Vector2] = [start]
	var visited := {start: true}
	var index := 0
	while index < frontier.size():
		var p: Vector2 = frontier[index]
		index += 1
		if p.distance_to(target) <= 8:
			return true
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var next: Vector2 = p + direction * 4
			if not visited.has(next) and world.player.is_walkable(next):
				visited[next] = true
				frontier.append(next)
	return false
func run() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_one.json"))
	var world := World.new()
	root.add_child(world)
	for scene in data.scenes:
		world.configure(scene, Vector2.INF, {"active_objectives": []})
		await physics_frame
		check(world.player.is_walkable(world.default_spawn()), scene.id + " valid spawn")
		check(world.actors.y_sort_enabled, "Y sort")
		check(not world.player.is_walkable(Vector2(-1, -1)), "bounds reject outside")
		for id in world.layout.actions:
			var g := world.get_objective_geometry(id)
			check(not g.is_empty(), id + " geometry exists")
			check(world.player.is_walkable(g.position), id + " endpoint outside solids")
			check(reachable(world, world.default_spawn(), g.position), id + " endpoint reachable")
			var previous := world.default_spawn()
			for p in g.waypoints:
				check(world.player.is_walkable(p), id + " waypoint outside solids")
				check(reachable(world, previous, p), id + " waypoint reachable")
				previous = p
			world.set_runtime_context({"active_objectives": [{"id": id, "name": id, "type": "route" if not g.waypoints.is_empty() else "interact", "enabled": true}]})
			world.player.position = g.position
			check(world.nearest().get("action_id", "") == id, id + " exact endpoint nearest")
			if not g.waypoints.is_empty():
				world._update_paths()
				check(not world.get_path_progress(id).complete, id + " endpoint cannot bypass route")
				for p in g.waypoints:
					world.player.position = p
					world._update_paths()
				check(world.get_path_progress(id).complete, id + " ordered route completes")
				world.set_runtime_context({"active_objectives": [], "path_progress": {id: 999}})
				check(world.get_path_progress(id).index == g.waypoints.size(), "path restore clamped")
		world.set_runtime_context({"active_objectives": []})
		check(world.nearest().is_empty(), "inactive stage has no interaction")
		# Real physics collision, not just geometry assertions.
		var wall: Rect2 = world.solid_rects[0]
		world.player.position = Vector2(wall.position.x - 20, wall.get_center().y)
		world.player.enabled = false
		await physics_frame
		var hit := world.player.move_and_collide(Vector2(30, 0))
		check(hit != null, scene.id + " real solid blocks body")
		world.player.position = Vector2(-100, -100)
		world.player._physics_process(0.016)
		check(world.player.position.x >= world.player.bounds.position.x, "left boundary clamped")
		check(world.player.position.y >= world.player.bounds.position.y, "top boundary clamped")
	world.configure(data.scenes[6], Vector2.INF, {"controller_id": "char_liang_xiao", "carried_by": "char_liang_wenjing", "present_actor_ids": ["char_liang_wenjing", "char_liang_xiao"]})
	check(world.player.visual.appearance == "carrying_child", "father and child composite")
	check(not world.cast_actors.char_liang_wenjing.visible, "father not trailing his carried child")
	world.set_runtime_context({"controller_id": "char_liang_xiao", "present_actor_ids": ["char_liang_wenjing"], "dead_actor_ids": ["char_liang_wenjing"]})
	check(world.cast_actors.char_liang_wenjing.is_body, "dead father becomes body")
	world.set_runtime_context({"present_actor_ids": ["char_liang_wenjing"], "dead_actor_ids": ["char_liang_wenjing"], "completed_actions": ["father_buried"]})
	check(not world.cast_actors.char_liang_wenjing.visible, "buried father disappears")
	# At 1000 FPS the 0.062-pixel steps must accumulate rather than round to zero.
	world.configure(data.scenes[1], Vector2.INF, {"present_actor_ids": ["char_liang_wenjing", "char_xiao_yuling"]})
	world.player.position = Vector2(100, 160)
	var father_before: Vector2 = world.cast_actors.char_liang_wenjing.position
	var mother_before: Vector2 = world.cast_actors.char_xiao_yuling.position
	for frame in range(120):
		world._update_followers(1.0 / 60.0)
	check(world.cast_actors.char_liang_wenjing.position == father_before, "stationary entrance preserves father position")
	check(world.cast_actors.char_xiao_yuling.position == mother_before, "stationary entrance preserves mother position")
	for step in range(10):
		world.player.position = Vector2(100 + step * 8, 160)
		world._update_followers(0.0)
	for frame in range(200):
		world._update_followers(0.001)
	check(world.cast_actors.char_liang_wenjing.position.distance_to(father_before) > 10, "father moves at 1000 FPS")
	check(world.cast_actors.char_xiao_yuling.position.distance_to(mother_before) > 10, "mother moves at 1000 FPS")
	world.configure(data.scenes[9], Vector2.INF, {"completed_actions": ["puppy_adopted"], "present_actor_ids": ["follower_baichier"]})
	world.player.position = Vector2(288, 192)
	var puppy_before: Vector2 = world.cast_actors.follower_baichier.position
	for frame in range(120):
		world._update_followers(1.0 / 60.0)
	check(world.cast_actors.follower_baichier.position == puppy_before, "stationary entrance preserves puppy position")
	for step in range(10):
		world.player.position = Vector2(288 + step * 8, 192)
		world._update_followers(0.0)
	for frame in range(200):
		world._update_followers(0.001)
	check(world.cast_actors.follower_baichier.position.distance_to(puppy_before) > 10, "adopted puppy moves at 1000 FPS")
	check(world.player.is_walkable(world.cast_actors.follower_baichier.position), "puppy movement preserves traversable position")
	var prologue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	for scene in prologue.scenes:
		world.configure(scene, Vector2(112, 116))
		check(world.layout.is_empty(), "prologue compatibility")
		check(not world.interactions.is_empty(), "prologue main retained")
	world.queue_free()
	await process_frame
	print("CHAPTER WORLD: %s checks, %s failures" % [checks, failures])
	quit(1 if failures else 0)
