extends SceneTree
## Controller/world integration; GUI mouse/keyboard verification is a separate gate.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.saves = SaveStore.new("user://chapter_main_integration")
	while not main.story.state.finished:
		var scene: Dictionary = main.story.scene()
		for object in scene.objects: main.story.observe(object.id)
		if scene.get("mode","dialogue") != "dialogue": main.story.solve_puzzle(scene.mode)
		main.story.commit_choice(scene.id,0)
	main._enter_chapter_one()
	var count := 0
	while not main.story.state.finished and count < 110:
		var token: String = main.story.current_token()
		var event: Dictionary = main.story.current_event()
		match event.op:
			"dialogue":
				check(main.mode == "chapter_dialogue","dialogue routed")
				while main.story.current_token() == token: main._next_line()
			"choice":
				main._chapter_choose(main.story.available_choices()[0].id,token)
				check(main.mode == "chapter_feedback","choice feedback appears")
				main._commit_chapter_choice(token,main.story.available_choices()[0].id)
			"action":
				var geometry: Dictionary = main.world.get_objective_geometry(event.id)
				check(not geometry.is_empty(),"world registers "+event.id)
				if geometry.is_empty(): break
				if event.kind == "route":
					for point in geometry.waypoints:
						main.world.player.position = point
						main.world._update_paths()
					check(main.world.get_path_progress(event.id).complete,"actual ordered waypoint proximity completes route")
				main.world.player.position = geometry.position
				main._interact()
				if event.kind == "glyph":
					var board: GlyphBoard
					for child in main.modal_content.get_children():
						if child is GlyphBoard: board = child
					check(board != null,"actual glyph control appears")
					await process_frame
					while not board.done:
						board.tap(board.current_start())
						board.tap(board.current_end())
				elif event.kind == "work":
					for i in range(int(event.count)-1): main._interact()
				elif event.kind == "projectile": await create_timer(0.5).timeout
			"battle":
				check(main.mode == "chapter_battle","battle panel routed")
				var rounds := 0
				while main.encounter_session.get_view().outcome == "" and rounds < 40:
					var view: Dictionary = main.encounter_session.get_view()
					var target := ""
					for actor in view.actors:
						if actor.team == "enemy" and not actor.defeated:
							target = actor.id
							break
					var skill := "sancai_counter"
					if main.encounter_session.engine.validate_command("char_liang_xiao",skill,target) != "": skill = "normal_attack"
					main._chapter_command("char_liang_xiao",skill,target,int(view.revision))
					main._chapter_resolve()
					rounds += 1
				check(main.encounter_session.get_view().outcome == "victory","controller battle actually won")
				main._chapter_battle_finish()
			"trial":
				for direction in ["west","east","north"]:
					main._trial_observe()
					main._trial_step(direction)
					main._trial_strike()
		check(main.story.current_token() != token or main.story.state.finished,"controller advances "+token)
		if main.story.current_token() == token and not main.story.state.finished: break
		await process_frame
		count += 1
	check(main.story.state.finished and main.story.state.xp == 345,"main reaches chapter ending and exact XP")
	check(main.mode == "ending" and not main.world.player.enabled,"ending locks movement")
	main.queue_free()
	await process_frame
	print("Chapter main integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
