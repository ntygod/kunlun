extends SceneTree
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
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
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three.json"))
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_three_maps.json")).maps
	var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three_runtime.json"))
	var world := World.new()
	root.add_child(world)
	check(maps.size() == 4, "four semantic maps")
	var signatures := {}
	for id in maps:
		var scene := {"id": "map_test", "map_id": id, "cast": []}
		world.configure(scene, Vector2.INF, {})
		await physics_frame
		check(world.player.is_walkable(world.default_spawn()), id + " spawn valid")
		check(world.actors.y_sort_enabled, id + " Y-sort enabled")
		check(not world.player.is_walkable(Vector2(-1, -1)), id + " outer bounds")
		var signature := JSON.stringify(maps[id].solids)
		check(not signatures.has(signature), id + " distinct obstacle layout")
		signatures[signature] = true
		for action_id in maps[id].actions:
			var g := world.get_objective_geometry(action_id)
			check(world.player.is_walkable(g.position), action_id + " point outside solids")
			check(reachable(world, world.default_spawn(), g.position), action_id + " reachable")
			var previous := world.default_spawn()
			for p in g.waypoints:
				check(world.player.is_walkable(p), action_id + " waypoint outside solids")
				check(reachable(world, previous, p), action_id + " segment reachable")
				previous = p
			var kind := "interact" if g.waypoints.is_empty() or g.geometry_only else "route"
			world.set_runtime_context({"active_objectives": [{"id": action_id, "name": action_id, "type": kind}]})
			world.player.position = g.position
			check(world.nearest().get("action_id", "") == action_id, "nearest " + action_id)
			if kind == "route":
				world._update_paths()
				check(not world.get_path_progress(action_id).complete, action_id + " endpoint cannot bypass route")
				for p in g.waypoints:
					world.player.position = p
					world._update_paths()
				check(world.get_path_progress(action_id).complete, action_id + " ordered traversal")
		world.set_runtime_context({"active_objectives": []})
		check(world.nearest().is_empty(), "stage deactivates all action points")
		world.player.enabled = false
		var solid: Rect2 = world.solid_rects[0]
		world.player.position = Vector2(solid.position.x - 20, solid.get_center().y)
		await physics_frame
		check(world.player.move_and_collide(Vector2(40, 0)) != null, id + " real physics collision")
	# Every runtime action/puzzle entry maps to authored geometry in its actual scene.
	for scene in content.scenes:
		world.configure(scene, Vector2.INF, {})
		var steps: Array = runtime.get("scenes", {}).get(scene.id, runtime.get("side_quests", {}).get(scene.id, []))
		for step in steps:
			if step.op in ["action", "puzzle", "world_puzzle"]:
				var action_id: String = step.get("entry_id", step.id)
				check(not world.get_objective_geometry(action_id).is_empty(), scene.id + " runtime binding " + action_id)
				if step.get("kind", "") == "route":
					var geometry := world.get_objective_geometry(action_id)
					check(not geometry.waypoints.is_empty() and geometry.waypoints[-1] == geometry.position, action_id + " route endpoint is interaction point")
					world.set_runtime_context({"active_objectives": [{"id": action_id, "name": action_id, "type": "route"}]})
					world.path_progress[action_id] = geometry.waypoints.size()
					world.player.position = geometry.waypoints[-1]
					check(world.get_path_progress(action_id).complete and world.nearest().get("action_id", "") == action_id, action_id + " restored completed route can interact at endpoint")
	var forest := {"id":"ch03_blood_cloak_decoy","map_id":"map_ch03_forest_road","cast":["梁萧","花晓霜","明归","金灵儿","白痴儿"]}
	var context := {"controller_id":"char_liang_xiao","actor_appearances":{"char_liang_xiao":"youth_age_16","char_hua_xiaoshuang":"youth_age_15"},"follower_actor_ids":[],"completed_actions":["puppy_adopted"],"world_objects":{"ch03_hidden_hollow":{"state":"concealed","occupants":["char_hua_xiaoshuang","follower_baichier","follower_jinlinger"]},"item_ch01_xuanyuan_sword":{"owner":"char_liang_xiao","state":"wrapped"}}}
	world.configure(forest,Vector2.INF,context)
	check(world.player.appearance=="youth_age_16","inherited sixteen-year candidate")
	check(world.cast_actors.char_hua_xiaoshuang.appearance=="youth_age_15","inherited fifteen-year candidate")
	check(world.player.visual.sword_state=="wrapped","sword follows real owner")
	check(world.cast_actors.char_hua_xiaoshuang.position==Vector2(224,112),"girl in hollow")
	var dog: Vector2 = world.cast_actors.follower_baichier.position
	world.player.position=Vector2(560,208)
	for i in range(100):world._update_followers(0.01)
	check(world.cast_actors.follower_baichier.position==dog,"explicit empty followers prevents old puppy tag pursuit")
	var escape = preload("res://scripts/world_actions/shadow_escape.gd").new()
	escape.begin(escape.DECOY,"world",context)
	world.sync_escape_view(escape.get_view())
	check(not world.player.enabled and world.player.position==Vector2(224,112),"controller owns actual world location")
	check(world.cast_actors.char_ming_gui.position==Vector2(48,240),"actual pursuit actor location")
	check(world.player.carrying_actor_id.is_empty() and world.cast_actors.char_hua_xiaoshuang.visible,"single sheltered girl")
	world.sync_escape_view({})
	check(world.escape_view.is_empty(),"session presentation cleared")
	context.controller_id="char_hua_qingyuan"
	world.set_runtime_context(context)
	check(world.player.visual.sword_state.is_empty(),"limited control never steals Liang sword")
	forest.id="ch03_valley_departure"
	forest.cast=["梁萧"]
	context.controller_id="char_liang_xiao"
	world.configure(forest,Vector2.INF,context)
	check(not world.cast_actors.char_hua_xiaoshuang.visible and not world.cast_actors.follower_baichier.visible and not world.cast_actors.follower_jinlinger.visible,"departure alone; shelter companions off camera")
	world.queue_free()
	print("CHAPTER THREE WORLD: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
