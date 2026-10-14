extends SceneTree
## Headless presentation contract checks, not a graphical/manual acceptance gate.
const R = preload("res://scripts/puzzles/chapter_seven_puzzle_resolver.gd")
const UI = preload("res://scripts/ui/chapter_seven_puzzle_panel.gd")
const Fixtures = preload("res://tests/test_chapter_seven_puzzles.gd")
var checks := 0
var failures := 0
var actions: Array = []
var main_cases := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func create_resolver(id: String, method: String = "joy") -> RefCounted:
	var resolver := R.new()
	check(resolver.begin(id,"ui:"+id+":"+method,Fixtures.fixture(id,method)),"begin "+id+" "+method)
	return resolver

func create_panel(resolver: RefCounted) -> Control:
	var panel := UI.new()
	panel.theme = Theme.new()
	panel.theme.default_font = load("res://assets/fonts/kunlun_ui.ttf")
	check(panel.theme.default_font != null,"real Chinese UI font exists")
	root.add_child(panel)
	panel.size = Vector2(568,300)
	panel.render(resolver.get_view())
	panel.input_submitted.connect(func(action: Dictionary):
		actions.append(action.duplicate(true))
		check(resolver.apply_input(action).ok,"UI action accepted: "+str(action))
		panel.render(resolver.get_view()))
	return panel

func settle_layout() -> void:
	await process_frame
	await process_frame

func check_layout(panel: Control, label: String) -> void:
	var minimum := panel.get_combined_minimum_size()
	check(minimum.x <= 568,"568px width: "+label)
	check(minimum.y <= 300,"300px body height: "+label+" "+str(minimum))
	check(panel._labels.rules.visible,"mandatory rules always visible: "+label)
	var confirmation: Button=panel._buttons.get("horn",panel._buttons.finish)
	check(confirmation.visible,"confirmation visible: "+label)
	print("CH07_PANEL_LAYOUT ",label," minimum=",minimum)

func test_grain() -> void:
	var resolver := create_resolver("grain_ch07_accounts")
	var panel := create_panel(resolver)
	await settle_layout()
	check_layout(panel,"grain")
	var field: LineEdit = panel._fields.value
	field.text = "800"
	field.grab_focus()
	panel._selects.value_column.select(1)
	panel.render(resolver.get_view())
	await settle_layout()
	check(field == panel._fields.value,"same-id render retains field instance")
	check(field.text == "800","same-id render retains unsubmitted input")
	check(field.has_focus(),"same-id render retains focus")
	check(panel._selects.value_column.selected == 1,"same-id render retains selection")
	for i in range(3):
		panel._selects.paper.select(i)
		panel._selects.column.select(i)
		panel._buttons.paper.pressed.emit()
	panel._buttons.difference.pressed.emit()
	panel._buttons.equation.pressed.emit()
	for i in range(3):
		panel._selects.value_column.select(i)
		panel._fields.value.text = ["1600","800","1300"][i]
		panel._buttons.value.pressed.emit()
	panel._buttons.finish.pressed.emit()
	check(resolver.state.complete,"grain solved through actual controls")
	panel.queue_free()
	await process_frame

func test_formation(id: String) -> void:
	var resolver := create_resolver(id)
	var panel := create_panel(resolver)
	await settle_layout()
	check_layout(panel,id)
	check(panel._board.targets == resolver.get_view().target_positions,"board shows actual role template")
	check(panel._board.center == resolver.state.center,"board shows actual reference center")
	panel._buttons.turn_E.pressed.emit()
	check(actions[-1] == {"type":"turn","unit":0,"direction":"E"},"turn stays independent of movement")
	panel._choose_cell(-2,2)
	check(panel._selected == 1 and panel._selects.unit.selected == 1,"occupied-cell click selects matching unit")
	panel._choose_cell(-3,2)
	check(panel._selected == 0,"leader can be reselected")
	panel._choose_cell(-3,0)
	check(not resolver.state.moving.is_empty(),"target click starts real path transaction")
	check(panel._buttons.horn.disabled and panel._selects.unit.disabled,"moving locks command and selection inputs")
	check(not panel._buttons.close.disabled,"moving still permits pause/close")
	var count := actions.size()
	panel._send({"type":"horn"})
	check(actions.size() == count,"busy dispatcher blocks extra commands")
	panel.hide()
	await create_timer(0.3).timeout
	check(actions.size() == count,"hidden panel emits no Timer steps")
	check(resolver.state.positions[0] == [-3,2],"hidden pause preserves validated current cell")
	panel.show()
	await create_timer(0.5).timeout
	check(resolver.state.positions[0] == [-3,0],"shown panel resumes Timer to target")
	check(resolver.state.moving.is_empty(),"Timer finishes transaction")
	var steps := 0
	for i in range(count,actions.size()):
		if actions[i].type == "step_move": steps += 1
	check(steps == 2,"two-cell route emits exactly two actual step commands")
	check(not panel._buttons.horn.disabled,"movement unlocks on completion")
	check(not panel._buttons.undo.disabled,"completed move enables one undo")
	panel._buttons.undo.pressed.emit()
	check(resolver.state.positions[0] == [-3,2],"undo restores pre-move position")
	check(panel._buttons.undo.disabled,"undo cannot repeat without a new move")
	panel.queue_free()
	await process_frame

func test_letters(method: String) -> void:
	var resolver := create_resolver("letters_ch07_l03",method)
	var panel := create_panel(resolver)
	panel._selects.content.select(0 if method == "joy" else 1)
	for person in range(3):
		panel._selects.person.select(person)
		panel._refresh_letter_preview()
		await settle_layout()
		var id: String = UI.PEOPLE[person]
		var body: String = resolver.get_view().letter_texts[method][id]
		check(not body.is_empty(),"actual source-backed letter body exists: "+method+" "+id)
		check(body in panel._labels.letter_preview.text,"full selected letter appears in preview: "+method+" "+id)
		check_layout(panel,"letter "+method+" "+id)
		panel._buttons.write.pressed.emit()
		check(actions[-1] == {"type":"write_letter","person":id,"content":method+":"+id},"selected readable letter maps to correct content ID")
		panel._buttons.seal.pressed.emit()
		panel._buttons.return.pressed.emit()
		check(resolver.state.letters[id].written and resolver.state.letters[id].sealed and resolver.state.letters[id].returned,"letter physically written, sealed and returned")
	panel._buttons.finish.pressed.emit()
	check(resolver.state.complete,"three letters complete via actual buttons: "+method)
	panel.queue_free()
	await process_frame

func test_main_small_window() -> void:
	# Real main scene, theme, modal and signal routing; only campaign fixture is
	# synthetic. No screenshot, mouse automation, personal save or GUI acceptance.
	root.size=Vector2i(640,360)
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await settle_layout()
	main._layout()
	main.story.actors["char_liang_xiao"]={"xp":0}
	main.story.progress={"memories":[],"inventory":[]}
	var runtime=load("res://scripts/campaign/chapter_runtime.gd").new(main.story,7)
	main.story.active_chapter=7
	main.story.registered_chapters[7]=runtime
	for id in R.IDS:
		var resolver := create_resolver(id)
		runtime.content={"scenes":[{"id":"panel_fixture","title":"UI fixture","map_id":"caizhou_supply_camp"}]}
		runtime.runtime={"scenes":{"panel_fixture":[{"op":"puzzle","id":id,"step_id":"ui:"+id,"name":"UI fixture"}]}}
		runtime.state.scene_index=0
		runtime.state.step=0
		runtime.puzzle_session=resolver
		main._show_registered_puzzle()
		await settle_layout()
		var panel: Control=main.registered_puzzle_panel
		var scroll: ScrollContainer=main.modal_content.get_parent()
		var body: Rect2=panel.get_global_rect()
		var visible_area: Rect2=scroll.get_global_rect()
		check(main.mode=="chapter_puzzle","real main enters puzzle modal: "+id)
		check(panel.input_submitted.is_connected(main._registered_puzzle_input),"real main input signal connected: "+id)
		check(panel.close_requested.is_connected(main._return_from_puzzle),"real main pause signal connected: "+id)
		check(visible_area.encloses(body),"main 640x360 body fits without scrolling: "+id+" body="+str(body)+" viewport="+str(visible_area))
		check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(main.modal.get_global_rect()),"main modal stays in 640x360 window")
		var confirmation: Button=panel._buttons.get("horn",panel._buttons.finish)
		check(visible_area.encloses(confirmation.get_global_rect()),"main confirmation not clipped: "+id)
		check(visible_area.encloses(panel._labels.rules.get_global_rect()),"main mandatory rules not clipped: "+id)
		print("CH07_MAIN_LAYOUT ",id," body=",body," viewport=",visible_area)
		panel._buttons.hint.pressed.emit()
		check(resolver.state.hint==1,"real main signal routes hint to authoritative resolver")
		main_cases+=1
	main.queue_free()
	await process_frame

func run() -> void:
	await test_grain()
	await test_formation("formation_ch07_drill")
	await test_formation("formation_ch07_regroup")
	await test_letters("joy")
	await test_letters("truth")
	await test_main_small_window()
	check(main_cases==4,"all four main fixture cases reached completion")
	print("CHAPTER_SEVEN_PUZZLE_PANEL ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
