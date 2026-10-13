extends SceneTree
const Story = preload("res://scripts/story_state.gd")
const Saves = preload("res://scripts/save_store.gd")
const Battle = preload("res://scripts/training_battle.gd")
var failures := 0
var checks := 0
var data: Dictionary

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func run() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	check(data.character.name == "梁文靖" and data.character.level == 15,"canonical prologue actor")
	for branch in [0,1]:
		var story := Story.new(data)
		for entry in data.scenes:
			var before := story.state.duplicate(true)
			check(not story.commit_choice("stale_scene",0),"reject stale UI callback")
			check(story.state == before,"stale callback leaves state unchanged")
			if entry.has("requires_objects"):
				check(not story.can_interact(),"clues gate main dialogue")
				check(not story.commit_choice(entry.id,0),"cannot bypass missing clues")
			for object in entry.objects:
				check(story.observe(object.id),"observe existing object")
				check(story.observe(object.id),"repeat observe harmless")
			check(not story.observe("unknown"),"unknown object rejected")
			check(story.begin_dialogue(),"start authorized dialogue")
			if entry.get("mode","dialogue") != "dialogue":
				check(not story.commit_choice(entry.id,0),"puzzle required before scene transaction")
				check(story.solve_puzzle(entry.mode),"solve current puzzle")
			var choice := mini(branch,entry.choices.size()-1)
			check(story.commit_choice(entry.id,choice),"commit scene " + entry.id)
			check(not story.commit_choice(entry.id,choice),"repeat scene commit rejected")
			check(story.state.xp == 0,"no XP leakage")
			var clone := Story.new(data)
			check(clone.restore(JSON.parse_string(JSON.stringify(story.state))) == "","JSON roundtrip after " + entry.id)
			check(clone.state == story.state,"roundtrip identical")
		check(story.state.finished,"end is reached")
		check(not "item_nine_dragon_token" in story.state.inventory,"token removed once at ending")
		check(data.completion_memory in story.state.memories,"canonical mercy memory")
		var saves := Saves.new("user://test_saves")
		check(saves.save_game(story) == "","atomic disk save")
		var restored := Story.new(data)
		check(saves.load_game(restored) == "","disk load")
		check(restored.state == story.state,"disk roundtrip")
		var safe := restored.state.duplicate(true)
		for mutation in [{"version":99},{"scene_index":999},{"position":["x",0]},{"completed":[]},{"choices":[]},{"xp":1},{"finished":false}]:
			var broken := safe.duplicate(true)
			broken.merge(mutation,true)
			check(not restored.restore(broken).is_empty(),"invalid save rejected " + str(mutation))
			check(restored.state == safe,"failed restore never mutates")
		var previous_bytes := FileAccess.get_file_as_bytes("user://test_saves/manual.json")
		DirAccess.make_dir_recursive_absolute("user://test_saves/manual.json.tmp")
		check(not saves.save_game(restored).is_empty(),"unwritable temporary save reports error")
		check(FileAccess.get_file_as_bytes("user://test_saves/manual.json") == previous_bytes,"failed write preserves previous save bytes")
		DirAccess.remove_absolute("user://test_saves/manual.json.tmp")
		var file := FileAccess.open("user://test_saves/manual.json",FileAccess.WRITE)
		file.store_string("{broken json")
		file.close()
		check(not saves.load_game(restored).is_empty(),"corrupt disk file rejected")
		check(restored.state == safe,"corrupt file leaves session intact")
	# Adversarial nested save payloads must return errors, not throw script errors.
	var early := Story.new(data)
	var untouched := early.state.duplicate(true)
	for mutation in [{"puzzles":{"sancai_lesson":true}}, {"puzzles":{"shenxian_crossing":7}}, {"observed":{"shenxian_crossing":7}}, {"observed":{"shenxian_crossing":["unknown"]}}, {"quest_phase":"ARCHIVED_ECHO"}, {"extra":1}]:
		var malformed := untouched.duplicate(true)
		malformed.merge(mutation,true)
		check(not early.restore(malformed).is_empty(),"nested malformed payload rejected")
		check(early.state == untouched,"nested malformed payload leaves session untouched")
	for field in ["version", "chapter", "scene_index", "xp", "quest_id", "quest_phase", "completed", "choices", "observed", "puzzles", "memories", "inventory", "position", "finished"]:
		for value in [null, true, false, "bad", 7, 1.5, [], {}, [7], {"bad":7}]:
			var malformed := untouched.duplicate(true)
			malformed[field] = value
			var result: String = early.restore(malformed)
			if result.is_empty():
				# Some canonical defaults (empty collections/false) are valid.
				check(early.state == untouched,"only equivalent field mutation accepted: " + field)
			else:
				check(early.state == untouched,"typed failure is atomic: " + field)
	check(early.restore(untouched) == "","unknown key cannot poison future loads")
	check(early.commit_choice("shenxian_crossing",0),"first scene prerequisite fixture")
	var no_token := early.state.duplicate(true)
	no_token.inventory.clear()
	check(not early.restore(no_token).is_empty(),"missing quest token rejected")
	for object in early.scene().objects:
		early.observe(object.id)
	early.commit_choice("bashan_inn",0)
	for observed in [{}, {"bashan_inn":7}, {"bashan_inn":["ink_painting","old_bow","rain_tracks","unknown"]}]:
		var malformed := early.state.duplicate(true)
		malformed.observed = observed
		check(not early.restore(malformed).is_empty(),"completed inn requires valid clue evidence")
	var battle := Battle.new(rules)
	check(battle.mirror_cost() == 10,"mirror floor and percentage cost")
	check(battle.act("mirror"),"preparation works")
	check(battle.hp == 520 and battle.mp == 76,"induced miss deals zero, pays10 MP and earns6 on valid break")
	check(not battle.act("mirror"),"cooldown blocks consecutive preparation")
	check(battle.act("guard"),"guard restores MP")
	check(battle.mp == 80,"MP capped at maximum")
	check(battle.act("mirror") and battle.finished,"second preparation wins nonlethally")
	check(not battle.act("attack"),"cannot act after battle ends")
	# Real scene-tree integration; no renderer required.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.saves = Saves.new("user://test_ui_saves")
	await process_frame
	await process_frame
	check(main.viewport.size == Vector2i(320,180),"independent world viewport")
	main.size = Vector2(1366,768)
	main._layout()
	check(main.display.size == Vector2(1280,720),"1366 display uses 4x integer scale")
	check(main.display.position == Vector2(43,24),"letterbox centered")
	main._cancel_choice()
	check(main.world.player.enabled,"menu closes and restores movement")
	main.world.player.position = Vector2(145,116)
	main._interact()
	check(main.mode == "dialogue" and not main.world.player.enabled,"interaction locks movement")
	await process_frame
	check(main.actions.get_child(0).size.x > 80 and main.actions.get_child(0).size.y < 60,"dialogue buttons retain natural width")
	check(main.dialogue_panel.size.y <= 192,"dialogue respects four-times 48px band")
	main.size = Vector2(640,360)
	main._layout()
	await process_frame
	check(main.dialogue_panel.size.y <= 96,"small-window dialogue stays inside 48px logical band")
	check(main.dialogue_scroll.size.y >= 36,"small-window dialogue exposes a readable scrolling text area")
	main.size = Vector2(1366,768)
	main._layout()
	main._finish_lines()
	check(main.mode == "choice","skip stops at player choice")
	check(main.story.state.completed.is_empty(),"skip cannot grant item or advance")
	main._cancel_choice()
	check(main.world.player.enabled,"cancel choice restores controls")
	main._interact()
	main._finish_lines()
	main._choose("shenxian_crossing",1)
	main._commit("shenxian_crossing",1)
	await process_frame
	check(main.story.scene().id == "bashan_inn","actual UI scene transition")
	check("item_nine_dragon_token" in main.story.state.inventory,"item applied exactly once")
	main._commit("shenxian_crossing",1)
	check(main.story.state.completed.size() == 1,"double UI commit harmless")
	# Drive the real presentation controller through every remaining scene.
	while not main.story.state.finished:
		var entry: Dictionary = main.story.scene()
		for object in entry.objects:
			main.story.observe(object.id)
		main.world.player.position = Vector2(145,116)
		main._interact()
		check(main.mode == "dialogue","UI dialogue reachable: " + entry.id)
		main._finish_lines()
		if entry.get("mode", "") == "lesson":
			main._battle_action("mirror")
			main._battle_action("guard")
			main._battle_action("mirror")
			check(main.battle.finished,"UI teaching battle closes")
			main._show_choices()
		elif entry.get("mode", "") == "calibration":
			main._calibrate()
			check(main.engine_index == 0,"wrong calibration cannot progress")
			for i in range(3):
				main.tension = 8
				main.elevation = 3
				main._calibrate()
			check(main.mode == "choice","three calibrated engines reach choice")
		main._choose(entry.id,0)
		main._commit(entry.id,0)
		await process_frame
	check(main.mode == "ending" and not main.world.player.enabled,"ending locks exploration")
	main._show_journal()
	main._cancel_choice()
	check(main.mode == "ending" and not main.world.player.enabled,"journal returns to ending without input leak")
	main._show_menu(true)
	main._cancel_choice()
	check(main.mode == "ending" and not main.world.player.enabled,"title cannot reopen completed exploration")
	main.queue_free()
	await process_frame
	print("Kunlun tests: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
