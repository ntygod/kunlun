extends SceneTree
const R=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
const UI=preload("res://scripts/ui/chapter_eight_puzzle_panel.gd")
const Fixtures=preload("res://tests/test_chapter_eight_puzzles.gd")
var checks:=0
var failures:=0
var actions:Array=[]
var resolver:RefCounted
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func panel_for(id:String) -> Control:
	resolver=R.new();resolver.begin(id,"panel",Fixtures.fixture(id))
	var panel:=UI.new();panel.theme=Theme.new();panel.theme.default_font=load("res://assets/fonts/kunlun_ui.ttf")
	root.add_child(panel);panel.size=Vector2(568,290);panel.render(resolver.get_view())
	panel.input_submitted.connect(func(action:Dictionary):
		actions.append(action.duplicate(true));check(resolver.apply_input(action).ok,"real UI input accepted "+str(action));panel.render(resolver.get_view()))
	return panel
func settle() -> void:
	await process_frame;await process_frame
func run() -> void:
	for id in R.IDS:
		var panel:=panel_for(id);await settle()
		check(panel.get_combined_minimum_size().x<=568,"small width "+id+str(panel.get_combined_minimum_size()))
		check(panel.get_combined_minimum_size().y<=300,"small height "+id+str(panel.get_combined_minimum_size()))
		check(panel._labels.rules.text==resolver.instruction(),"full rules normally visible without hint")
		check(panel._board.visible,"diagram visible separate from scroll")
		check(panel._scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED,"no clipped horizontal rules")
		var initial_width:float=panel._board.size.x
		panel.size=Vector2(1000,520);await settle();check(panel._board.size.x>initial_width,"large adaptive board")
		panel.size=Vector2(568,290);await settle()
		for i in range(3):panel._buttons.hint.pressed.emit()
		panel._buttons.demo.pressed.emit();panel._tick();check(resolver.state.assisted,"demo true action marked assisted")
		panel._buttons.stop.pressed.emit();var count:int=actions.size();panel._tick();check(actions.size()==count,"stop really stops")
		panel._buttons.demo.pressed.emit();panel.hide();panel._tick();check(actions.size()==count,"hidden cannot keep moving");panel.show()
		for stage in range(3):
			if resolver.state.complete:break
			panel._buttons.demo.pressed.emit()
			for i in range(90):
				if not panel._demo_running:break
				panel._tick()
		check(resolver.state.complete,"whole model via stoppable UI demo "+id)
		check(R.replay_receipt(resolver.receipt(),id,"panel",resolver.context),"UI real receipt replay")
		# A still-referenced old button and old board event cannot mutate the next token.
		var old_button:Button=panel._buttons.hint;var old_board:Control=panel._board;var old_timer:Timer=panel._timer
		resolver=R.new();var c:Dictionary=Fixtures.fixture(id);c.current_token+="new";resolver.begin(id,"next",c);panel.render(resolver.get_view())
		var before:Dictionary=resolver.snapshot();old_button.pressed.emit();old_board.day_chosen.emit(12);old_timer.timeout.emit()
		check(before==resolver.snapshot(),"stale button/board/timer blocked new token")
		panel.queue_free();await process_frame
	var panel:=panel_for(R.IDS[0]);await settle()
	var old_day:Button=panel._buttons["op:day:12"];old_day.pressed.emit();panel._buttons.finish.pressed.emit()
	var before:Dictionary=resolver.snapshot();old_day.pressed.emit();check(before==resolver.snapshot(),"old problem day callback blocked")
	panel._board.pool_chosen.emit(0);panel._board.pool_chosen.emit(1);check(resolver.state.pools==[3,3,0],"click source then adjacent pool")
	panel.queue_free();await process_frame
	panel=panel_for(R.IDS[1]);await settle()
	panel._choose_cell(-3,0);check(panel._selected=="npc_ranya","select real actor by cell")
	panel._choose_cell(-1,0);check(resolver.state.orders.has("npc_ranya"),"target click schedules legal path")
	panel._buttons.stop.pressed.emit();var position:Array=resolver.state.actors.npc_ranya.duplicate();panel._tick();check(position==resolver.state.actors.npc_ranya,"stop freezes manual move at current edge")
	panel._buttons["op:beat"].pressed.emit();check(resolver.state.actors.npc_ranya==[-2,0],"manual single construction beat")
	panel.queue_free();await process_frame
	print("Chapter eight puzzle panel: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
