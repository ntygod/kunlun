extends "res://tests/test_chapter_three.gd"
## Regression for dynamic main→B01 panel replacement and script-resource release.
## Run as its own process and inspect exit logs as well as this assertion count.
func run() -> void:
	base = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.saves = Saves.new("user://b01_lifecycle_test")
	app.story = chapter_two_ending(true)
	app._enter_chapter_three()
	while app.story.current_event().op != "objective_battle":
		if not act_three(app.story): break
	app._load_chapter_scene()
	await process_frame
	check(app.mode == "chapter_battle","real main dynamically constructs B01 panel")
	var panel = app.modal_content.get_child(0)
	panel.slots.ring_right.grab_focus()
	await process_frame
	check(app.modal_content.get_meta("b01_focus_slot","") == "ring_right","stable host stores only the last focus slot string")
	var popup: WeakRef = weakref(panel.details)
	panel._show_details()
	await process_frame
	panel.details.hide()
	app._show_chapter_battle()
	await process_frame
	panel = app.modal_content.get_child(0)
	check(popup.get_ref() == null,"old panel replacement frees its popup")
	check(root.gui_get_focus_owner() == panel.slots.details,"focus survives actual main panel reconstruction")
	for index in range(4):
		app._show_chapter_battle()
		await process_frame
	check(app.encounter_session.history.is_empty(),"presentation rebuild never changes encounter evidence")
	app._show_menu()
	await process_frame
	check(app.mode == "menu","menu teardown leaves no battle input owner")
	app.queue_free()
	await process_frame
	print("Chapter three battle lifecycle: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
