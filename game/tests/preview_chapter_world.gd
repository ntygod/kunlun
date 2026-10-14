extends SceneTree
## Visual-only QA harness. Does not create saves, receipts, rewards, or campaign changes.
## godot --path game --script res://tests/preview_chapter_world.gd -- 0
## Scene index 0..9. Arrows/WASD move. Escape closes. Candidate art, not final.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var keys := {"move_left": [KEY_LEFT, KEY_A], "move_right": [KEY_RIGHT, KEY_D], "move_up": [KEY_UP, KEY_W], "move_down": [KEY_DOWN, KEY_S]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_one.json"))
	var args := OS.get_cmdline_user_args()
	var index := clampi(int(args[0]) if args.size() else 0, 0, 9)
	var scene: Dictionary = chapter.scenes[index]
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(320, 180)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var world := KunlunWorld.new()
	root.add_child(world)
	world.configure(scene, Vector2.INF, {})
	var active: Array = []
	for id in world.layout.actions:
		var geometry := world.get_objective_geometry(id)
		active.append({"id": id, "name": world.layout.actions[id].name, "type": "route" if not geometry.waypoints.is_empty() else "interact"})
	var context := {"controller_id": scene.controller, "active_objectives": active}
	if index == 6:
		context.carried_by = "char_liang_wenjing"
	if index >= 7:
		context.dead_actor_ids = ["char_liang_wenjing"]
	if index == 9:
		context.completed_actions = ["father_buried", "dogs_buried", "obtain_wood_marker", "marker_liang_written", "marker_wen_written", "puppy_adopted"]
		context.world_objects = {"item_ch01_xuanyuan_sword": {"state": "wrapped", "owner": "char_liang_xiao"}}
	world.set_runtime_context(context)
	root.title = "Kunlun map QA - " + scene.id + " - candidate art"
func _process(_delta: float) -> bool:
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		quit()
	return false
