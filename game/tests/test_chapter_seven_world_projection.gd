extends SceneTree
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven.json"))
	for scene in content.scenes:
		var world=World.new();root.add_child(world)
		var context:Dictionary={"present_actor_ids":["char_liang_xiao","char_axue","npc_zhao_shan","npc_wang_ke","npc_haiya"],"actor_appearances":{"char_liang_xiao":"youth_age_18"},"items":{},"world_objects":{}}
		world.configure(scene,Vector2(INF,INF),context)
		check(not world.layout.is_empty(),scene.id+" map loads")
		check(world.player.is_walkable(world.player.position),scene.id+" walkable spawn")
		check(world.layout.style in ["supply","pass","cliff","prison","bridge","drill","outer","tent"],scene.id+" distinct visual style")
		context.world_objects={"ch07_six_friends":{"npc_zhao_shan":"dead","npc_wang_ke":"wounded"},"ch07_captives":{"char_axue":"bound","npc_haiya":"bound"}}
		world.set_runtime_context(context)
		check(not world.cast_actors.npc_zhao_shan.visible or scene.id=="ch07_fire_ox_ambush",scene.id+" Zhao cannot revive")
		check(world.cast_actors.npc_wang_ke.resting,scene.id+" Wang wounded")
		check(not world.cast_actors.char_axue.visible or scene.map_id=="map_ch07_yunxing_prison",scene.id+" captive location")
		context.world_objects.ch07_six_friends.npc_wang_ke="recovering_mobile"
		context.world_objects.ch07_captives={"char_axue":"safe_bank","npc_haiya":"safe_bank"}
		context.world_objects.ch07_bridge={"state":"broken","safe_bank":"west"}
		world.set_runtime_context(context)
		check(not world.cast_actors.npc_wang_ke.resting,scene.id+" Wang mobile before training")
		if scene.map_id=="map_ch07_yunxing_chain_bridge":
			check(world.cast_actors.char_axue.position.x<272 and world.cast_actors.npc_haiya.position.x<272,"rescued actors safe bank")
			check(not world.player.is_walkable(Vector2(320,240)),"real player cannot cross broken bridge")
		context.items={"item_ch06_father_book":{"owner":"char_axue","state":"entrusted","location":"ch06_home"},"item_ch06_entrusted_coins":{"owner":"char_axue","state":"entrusted","location":"ch06_home"},"item_ch06_wind_bird":{"owner":"ch06_home","state":"placed","location":"eaves"}}
		world.set_runtime_context(context)
		var props:Dictionary=world.chapter_seven_visible_props()
		check(not props.entrusted_book and not props.entrusted_money and not props.eaves_bird,"custody does not teleport with nominal owner")
		check(not props.broken_bow,"no duplicate unearned broken bow")
		await process_frame
		world.queue_free();await process_frame
	print("Chapter seven world projection: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
