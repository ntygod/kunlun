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
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_two.json"))
	var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_two_maps.json")).maps
	var runtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_two_runtime.json"))
	var world := World.new()
	root.add_child(world)
	check(maps.size() == 11, "eleven semantic maps")
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
	for scene in content.scenes + content.side_quests:
		world.configure(scene, Vector2.INF, {})
		var steps: Array = runtime.get("scenes", {}).get(scene.id, runtime.get("side_quests", {}).get(scene.id, []))
		for step in steps:
			if step.op in ["action", "puzzle"]:
				var action_id: String = step.get("entry_id", step.id)
				check(not world.get_objective_geometry(action_id).is_empty(), scene.id + " runtime binding " + action_id)
	# Carrying is a single player composite, not a girl NPC running behind him.
	world.configure(content.scenes[4], Vector2.INF, {"controller_id": "char_liang_xiao", "carried_pair": {"carrier_id": "char_liang_xiao", "passenger_id": "char_hua_xiaoshuang"}, "present_actor_ids": ["char_liang_xiao", "char_hua_xiaoshuang", "follower_jinlinger"]})
	check(world.player.carrying_actor_id == "char_hua_xiaoshuang", "girl attached to player")
	check(not world.cast_actors.char_hua_xiaoshuang.visible, "no duplicate carried girl")
	check(world.cast_actors.follower_jinlinger.actor_id == "follower_jinlinger", "monkey retains animal identity")
	world.set_runtime_context({"controller_id": "char_hua_xiaoshuang", "actor_appearances": {"char_hua_xiaoshuang": "child_age_10"}})
	check(world.player.actor_id == "char_hua_xiaoshuang", "short exploration viewpoint")
	check(world.player.carrying_actor_id.is_empty(), "carry clears on control restore")
	world.set_runtime_context({"controller_id": "char_liang_xiao", "actor_appearances": {"char_liang_xiao": "youth_age_16"}})
	check(world.player.visual.appearance == "youth_age_16", "story age updates visual")
	check(world.player.visual.texture != null and world.player.visual.texture.resource_path.ends_with("liang_xiao_tianji_16.png"), "sixteen-year-old uses approved Tianji candidate")
	for age in ["child_age_10", "child_age_11", "child_age_12"]:
		world.set_runtime_context({"controller_id": "char_liang_xiao", "actor_appearances": {"char_liang_xiao": age, "char_hua_xiaoshuang": "child_age_11"}})
		check(world.player.visual.texture.resource_path.ends_with("liang_xiao_young.png"), age + " Liang does not age up early")
		check(world.cast_actors.char_hua_xiaoshuang.texture.resource_path.ends_with("hua_xiaoshuang_child.png"), "early Xiaoshuang NPC uses child sheet")
	for age in ["child_age_10", "child_age_11", "youth_age_15"]:
		world.set_runtime_context({"controller_id": "char_hua_xiaoshuang", "actor_appearances": {"char_hua_xiaoshuang": age}})
		var expected := "hua_xiaoshuang_tianji_15.png" if age == "youth_age_15" else "hua_xiaoshuang_child.png"
		check(world.player.visual.texture.resource_path.ends_with(expected), age + " Xiaoshuang controlled appearance")
	world.set_runtime_context({"controller_id": "char_liang_xiao", "actor_appearances": {"char_liang_xiao": "youth_age_16", "char_hua_xiaoshuang": "youth_age_15"}})
	check(world.player.visual.texture.resource_path.ends_with("liang_xiao_tianji_16.png"), "fifth-year Liang switches to 16")
	check(world.cast_actors.char_hua_xiaoshuang.texture.resource_path.ends_with("hua_xiaoshuang_tianji_15.png"), "fifth-year Xiaoshuang NPC switches to 15")
	world.set_runtime_context({"controller_id": "char_liang_xiao", "carried_pair": {"carrier_id": "char_liang_xiao", "passenger_id": "char_hua_xiaoshuang"}, "actor_appearances": {"char_liang_xiao": "child_age_11", "char_hua_xiaoshuang": "child_age_10"}})
	check(world.player.visual.carrying_actor_id == "char_hua_xiaoshuang" and not world.cast_actors.char_hua_xiaoshuang.visible, "early carry retains approved composite without second standing girl")
	var sword_context := {"world_objects": {"item_ch01_xuanyuan_sword": {"state": "wrapped", "owner": "char_liang_xiao"}}, "controller_id": "char_hua_xiaoshuang"}
	world.set_runtime_context(sword_context)
	check(world.player.visual.sword_state.is_empty(), "Xiaoshuang never borrows Liang's sword layer during short control")
	sword_context.controller_id = "char_liang_xiao"
	world.set_runtime_context(sword_context)
	check(world.player.visual.sword_state == "wrapped", "restoring Liang restores his wrapped sword")
	check(not world.cast_actors.char_liang_xiao.visible, "restoring Liang has no duplicate NPC sword carrier")
	sword_context.world_objects.item_ch01_xuanyuan_sword.state = "carried"
	world.set_runtime_context(sword_context)
	check(world.player.visual.sword_state == "carried", "owned carried sword renders")
	sword_context.world_objects.item_ch01_xuanyuan_sword.state = "placed"
	world.set_runtime_context(sword_context)
	check(world.player.visual.sword_state.is_empty(), "placed sword not attached to player")
	sword_context.world_objects.item_ch01_xuanyuan_sword = {"state": "wrapped"}
	world.set_runtime_context(sword_context)
	check(world.player.visual.sword_state.is_empty(), "unknown ownership does not assign sword")
	world.queue_free()
	await process_frame
	print("CHAPTER TWO WORLD: %s checks, %s failures" % [checks, failures])
	quit(1 if failures else 0)
