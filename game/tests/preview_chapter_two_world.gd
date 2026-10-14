extends SceneTree
## Visual-only map harness, no campaign writes or receipts.
## User args: 0..18 main scene, 19 terrace; optional spring/summer/autumn/winter.
var world: KunlunWorld
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
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_two.json"))
	var args := OS.get_cmdline_user_args()
	var index := clampi(int(args[0]) if args.size() else 0, 0, 19)
	var scene: Dictionary = chapter.scenes[index] if index < 19 else chapter.side_quests[1]
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(320, 180)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	world = KunlunWorld.new()
	root.add_child(world)
	world.configure(scene, Vector2.INF, {})
	var active: Array = []
	for id in world.layout.actions:
		var geometry := world.get_objective_geometry(id)
		active.append({"id": id, "name": world.layout.actions[id].name, "type": "route" if not geometry.waypoints.is_empty() and not geometry.geometry_only else "interact"})
	var context := {"controller_id": scene.controller, "active_objectives": active, "actor_appearances": {"char_liang_xiao": "youth_age_16" if index >= 16 else "child_age_12", "char_hua_xiaoshuang": "youth_age_15" if index >= 16 else "child_age_10"}, "season": args[1] if args.size() > 1 else "winter", "completed_actions": ["puppy_adopted", "monkey_rescued"]}
	if index == 4:
		context.carried_pair = {"carrier_id": "char_liang_xiao", "passenger_id": "char_hua_xiaoshuang"}
	world.set_runtime_context(context)
	root.title = "Kunlun chapter two QA - " + scene.id + " - development candidate"
func _process(_delta: float) -> bool:
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		quit()
	if world and world.layout.style == "statue_array":
		world.runtime_context.shadow_phase = int(world.elapsed / 2) % 3
	return false
