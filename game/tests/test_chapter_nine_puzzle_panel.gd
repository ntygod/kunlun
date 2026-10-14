extends SceneTree
const R=preload("res://scripts/puzzles/chapter_nine_puzzle_resolver.gd")
const Fixtures=preload("res://tests/test_chapter_nine_puzzles.gd")
var resolver:RefCounted
const UI=preload("res://scripts/ui/chapter_nine_puzzle_panel.gd")
var checks:=0
var failures:=0
var actions:Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fixture(pine:bool=true) -> Dictionary:
	return {"puzzle_id":"pz_ch09_pine_needle" if pine else "pz_ch09_wood_bird","attempt_id":"test","token":"entry","title":"松针教学" if pine else "双人木鸟","instruction":"正式规则","hint_text":"提示","message":"","next_action":{"type":"move"},"calculation":{"mass":21,"torque":-1,"strength":2},"state":{"pins":{"start":[],"middle":[],"end":[]},"phase":0,"cursor":-1,"path":[],"hint":3,"complete":false} if pine else {"stage":"assembling","parts":{"body":"body","left_wing":"light","right_wing":"light","tail":"double","frame":"flexible","linkage":"linked"},"installed":[],"connections":[],"actors":{"char_liang_xiao":[0,5],"char_axue":[0,6]},"orders":{},"positions":{"char_liang_xiao":-1,"char_axue":-1},"wind":0,"cranks":0,"rail_index":0,"hint":3,"complete":false}}
func settle() -> void:
	await process_frame;await process_frame
func run() -> void:
	for pine in [true,false]:
		var panel:=UI.new();panel.theme=Theme.new();panel.theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");root.add_child(panel);panel.size=Vector2(568,290)
		var view:=fixture(pine);panel.render(view)
		panel.input_submitted.connect(func(action:Dictionary):actions.append(action.duplicate(true)))
		await settle()
		check(panel.get_combined_minimum_size().x<=568,"640 viewport width "+str(panel.get_combined_minimum_size()))
		check(panel.get_combined_minimum_size().y<=290,"640 viewport height "+str(panel.get_combined_minimum_size()))
		check(panel._labels.rules.get_parent()==panel and panel._labels.formula.get_parent()==panel,"rules and formula outside scroll")
		var old_width:float=panel._board.size.x;panel.size=Vector2(1000,520);await settle();check(panel._board.size.x>old_width,"adaptive board");panel.size=Vector2(568,290);await settle()
		if pine:
			panel._board.cell_chosen.emit(4,4);check(actions.back()=={"type":"place","pin":"start","x":4,"y":4},"stable pin click")
			panel._buttons["op:select:move"].pressed.emit();panel._board.cell_chosen.emit(4,3);check(actions.back()=={"type":"move","x":4,"y":3},"manual path click")
			panel._buttons["op:wait_window"].pressed.emit();check(actions.back()=={"type":"wait_window"},"formal timed wait")
		else:
			panel._board.cell_chosen.emit(0,6);check(panel._selected=="char_axue","select visible Axue")
			panel._board.cell_chosen.emit(5,2);check(actions.back()=={"type":"assign","actor":"char_axue","x":5,"y":2},"assign real work path")
			for key in ["op:select:body:body","op:select:left_wing:heavy","op:select:right_wing:light","op:select:tail:double","op:select:frame:flexible","op:select:linkage:linked","op:beat","op:connect:3","op:stand:char_axue:-1","op:wind","op:trial"]:check(panel._buttons.has(key),"manual wood control "+key)
		panel._buttons.demo.pressed.emit();panel._tick();check(actions.back()=={"type":"assist_step_v1"},"demo formal command only")
		panel._buttons.stop.pressed.emit();var count:int=actions.size();panel._tick();check(actions.size()==count,"stop cancels tick")
		panel._buttons.demo.pressed.emit();panel.hide();panel._tick();check(actions.size()==count and not panel._demo_running,"hide stops demo");panel.show()
		panel._buttons.demo.pressed.emit();var key:=InputEventKey.new();key.keycode=KEY_F9;key.pressed=true;panel._input(key);panel._tick();check(actions.size()==count,"F9 stops demo")
		var old_button:Button=panel._buttons.hint;var old_board:Control=panel._board;var old_timer:Timer=panel._timer
		view.token="new";panel.render(view);old_button.pressed.emit();old_board.cell_chosen.emit(0,0);old_timer.timeout.emit();check(actions.size()==count,"stale token callbacks blocked")
		if not pine:
			var old_op:Button=panel._buttons["op:trial"]
			view.state.stage="prepared";view.state.complete=true;panel.render(view);old_op.pressed.emit();check(actions.size()==count,"stale construction callback blocked")
			panel._buttons.demo.pressed.emit();panel._tick();check(actions.size()==count,"prepared cannot demo cross node")
			view.token="escape";view.state.complete=false;view.state.stage="cranking";panel.render(view)
			for action in ["crank","release","rail","advance"]:check(panel._buttons.has("op:"+action),"escape control "+action)
			panel._buttons.demo.pressed.emit();view.state.stage="drifted";panel.render(view);panel._tick();check(actions.size()==count,"drifted stops demo")
		panel.queue_free();await process_frame
	await real_replay()
	print("Chapter nine puzzle panel: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func real_replay() -> void:
	var assembly:Dictionary={}
	var assembly_context:Dictionary={}
	for mode in ["pine","assembly","flight"]:
		resolver=R.new()
		var id:String=R.IDS[0] if mode=="pine" else R.IDS[1]
		var context:Dictionary=Fixtures.fixture(id)
		if mode=="flight":
			context.scene_id="ch09_cloud_escape";context.current_token="flight"
			context.wood_bird_checkpoint=assembly;context.wood_bird_context=assembly_context
		check(resolver.begin(id,mode,context),"real UI begin "+mode)
		var panel:=UI.new();root.add_child(panel);panel.size=Vector2(568,290);panel.render(resolver.get_view())
		panel.input_submitted.connect(func(action:Dictionary):
			check(resolver.apply_input(action).ok,"real UI accepts "+str(action));panel.render(resolver.get_view()))
		for i in range(3):panel._buttons.hint.pressed.emit()
		panel._buttons.demo.pressed.emit()
		for i in range(150):
			if not panel._demo_running:break
			panel._tick()
		check(resolver.state.complete,"real UI completes "+mode)
		if mode!="pine":check("梁搬件：" in panel._labels.status.text and "雪搬件：" in panel._labels.status.text,"carrying ownership is visible")
		check(R.replay_receipt(resolver.receipt(),id,mode,context),"real UI proof replays "+mode)
		if mode=="assembly":
			check(resolver.state.stage=="prepared" and resolver.state.rail_index==0,"real UI stops at assembly boundary")
			assembly=resolver.snapshot();assembly_context=context.duplicate(true)
		if mode=="flight":check(resolver.state.stage=="drifted","real UI resumed flight reaches drifted")
		panel.queue_free();await process_frame
