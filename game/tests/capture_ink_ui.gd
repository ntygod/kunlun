extends SceneTree
## Native render harness. Combat gallery is a labelled synthetic snapshot.
const BattleView = preload("res://scripts/ui/battle_panel.gd")
const Vitals = preload("res://scripts/ui/ink_vitals.gd")
var output := ""
var problems: Array[String] = []
var captures: Array = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	output = OS.get_environment("KUNLUN_UI_CAPTURE")
	if output.is_empty():
		push_error("KUNLUN_UI_CAPTURE must name an isolated output directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.ink_reduced_motion = true
	for resolution in [Vector2i(640,360), Vector2i(1280,720)]:
		root.size = resolution
		await process_frame
		await process_frame
		app._show_menu(true)
		await capture(app, "title", resolution)
		app._cancel_choice()
		await capture(app, "explore", resolution)
		app._start_lines(app.story.scene().dialogue, true)
		await capture(app, "dialogue", resolution)
		app._show_choices()
		await capture(app, "choice", resolution)
		app._show_menu(false)
		await capture(app, "pause", resolution)
		app._show_journal()
		for page in range(4):
			app.ink_journal_view.tabs.current_tab = page
			await capture(app, "journal_%d" % page, resolution)
		app._show_ink_settings()
		await capture(app, "settings", resolution)
		app._show_calibration()
		await capture(app, "calibration", resolution)
		app.battle = load("res://scripts/training_battle.gd").new(app.rules)
		app._show_battle()
		await capture(app, "training", resolution)
		app.mode = "chapter_battle"
		app._modal_title("交锋 · 界面校验", "以下为测试快照，用于检查排版，不是自然通章证据。")
		var snapshot := battle_snapshot()
		if resolution.x >= 900:
			var strip := Vitals.new()
			app.modal_content.add_child(strip)
			strip.render(snapshot)
		var panel := BattleView.new()
		app.modal_content.add_child(panel)
		panel.render(snapshot, {"normal_attack":{"target":"enemy"}, "observe":{"name":"观势察机", "target":"enemy"}, "self_guard":{"target":"self"}, "guard_ally":{"target":"ally"}}, false)
		await capture(app, "battle", resolution)
	var report := {"captures":captures, "problems":problems, "scope":"Native-render harness; not natural campaign input, all tactical configurations or release QA."}
	var file := FileAccess.open(output+"/capture-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("Native UI capture: %d images, %d layout problems" % [captures.size(), problems.size()])
	for problem in problems: push_error(problem)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if not problems.is_empty() else 0)
func capture(app, label: String, resolution: Vector2i) -> void:
	app._layout()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var filename := "%dx%d_%s.png" % [resolution.x,resolution.y,label]
	var error := image.save_png(output+"/"+filename)
	if error != OK: problems.append("could not save "+filename)
	var bounds: Dictionary = {}
	for pair in [["modal", app.modal], ["dialogue", app.dialogue_panel]]:
		var control: Control = pair[1]
		if not control.visible: continue
		var rect := control.get_global_rect()
		bounds[pair[0]] = {"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y}
		if rect.position.x < -1 or rect.position.y < -1 or rect.end.x > resolution.x+1 or rect.end.y > resolution.y+1:
			problems.append(filename+" / "+str(pair[0])+" exceeds window: "+str(rect))
	captures.append({"file":filename,"bounds":bounds})
	if resolution.x == 1280 and label in ["title", "dialogue", "battle"]:
		image.resize(640,360,Image.INTERPOLATE_LANCZOS)
		var preview := image.save_jpg_to_buffer(0.45)
		print("INK_PREVIEW "+label+" "+Marshalls.raw_to_base64(preview))
func battle_snapshot() -> Dictionary:
	return {"round":3,"revision":7,"outcome":"","commands":{},"intents":[{"actor_id":"enemy_a","target_id":"hero","name":"横刀压进","tags":["induce"]}],
		"events":[{"type":"damage","source":"hero","target":"enemy_a","amount":32},{"type":"induced","source":"hero","target":"enemy_a","amount":0}],
		"skill_costs":{"hero":{"normal_attack":0,"observe":4,"self_guard":0,"guard_ally":0}},
		"actors":[{"id":"hero","name":"梁萧","team":"party","defeated":false,"hp":224,"max_hp":350,"mp":32,"max_mp":48,"ready":{},"skills":["normal_attack","observe","self_guard","guard_ally"]},
		{"id":"ally","name":"柳莺莺","team":"party","defeated":false,"hp":210,"max_hp":280,"mp":40,"max_mp":52,"ready":{},"skills":["normal_attack","self_guard"]},
		{"id":"enemy_a","name":"持刀客","team":"enemy","defeated":false,"hp":168,"max_hp":200,"mp":0,"max_mp":0},
		{"id":"enemy_b","name":"执棍客","team":"enemy","defeated":false,"hp":180,"max_hp":180,"mp":0,"max_mp":0}]}
