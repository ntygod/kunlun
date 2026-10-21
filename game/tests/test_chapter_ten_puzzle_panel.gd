extends SceneTree
const R=preload("res://scripts/puzzles/chapter_ten_puzzle_resolver.gd")
const T=preload("res://tests/test_chapter_ten_puzzles.gd")
const UI=preload("res://scripts/ui/chapter_ten_puzzle_panel.gd")
var checks:=0
var failures:=0
var sent:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func settle()->void:await process_frame;await process_frame;await process_frame
func run()->void:
	for id in R.IDS:
		for dimensions in [Vector2(568,290),Vector2(1100,570)]:
			var r:=R.new();check(r.begin(id,"panel",T.fixture(id)),"panel real begin")
			var panel:=UI.new();panel.theme=Theme.new();panel.theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");root.add_child(panel);panel.size=dimensions;panel.render(r.get_view());await settle()
			panel.input_submitted.connect(func(a:Dictionary):sent+=1;check(r.apply_input(a).ok,"real panel command "+str(a));panel.render(r.get_view()))
			check(panel.get_combined_minimum_size().x<=dimensions.x,"viewport width "+str(panel.get_combined_minimum_size()))
			check(panel.get_combined_minimum_size().y<=dimensions.y,"viewport height "+str(panel.get_combined_minimum_size()))
			check(panel._scroll.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED,"no sideways controls")
			for key in ["hint","assist","demo","stop","retry","close"]:check(Rect2(Vector2.ZERO,dimensions).encloses(panel._buttons[key].get_global_rect()),"footer visible "+key)
			if id==R.IDS[0]:
				for key in ["axle:3","phase:right:2","cargo:light:-3","cargo:heavy:2"]:panel._buttons[key].pressed.emit()
				panel._buttons.step.pressed.emit();check(r.state.steps==1,"manual gait first step")
				var saved:Dictionary=r.snapshot();var restored:=R.new();check(restored.restore(saved,T.fixture(id)),"partial actual gait restore")
			else:
				for i in range(3):panel._board.cell_chosen.emit(i+2,i+1)
				panel._buttons.pulse.pressed.emit();check(r.state.awaiting_breath and r.state.breaths==0,"manual reflected force")
				panel._buttons.breathe.pressed.emit();check(r.state.breaths==1,"separate manual breath")
			for i in range(3):panel._buttons.hint.pressed.emit()
			panel._buttons.demo.pressed.emit();var count:int=sent;panel.hide();panel._tick();check(sent==count and not panel._demo_running,"hide cancels demonstration");panel.show()
			panel._buttons.demo.pressed.emit();var event:=InputEventKey.new();event.keycode=KEY_F9;event.pressed=true;panel._input(event);panel._tick();check(sent==count,"load hotkey cancels demo")
			panel._buttons.demo.pressed.emit();panel._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT);panel._tick();check(sent==count,"focus loss cancels demo")
			panel._buttons.demo.pressed.emit()
			for i in range(32):
				if not panel._demo_running:break
				panel._tick()
			check(r.state.complete,"manual partial then legal assisted finish")
			check(R.replay_receipt(r.receipt(),id,"panel",r.context),"UI completion proof")
			var old_button:Button=panel._buttons.hint;var old_board:Control=panel._board;var old_timer:Timer=panel._timer;count=sent
			var view:Dictionary=r.get_view();view.token="new token";panel.render(view)
			old_button.pressed.emit();old_board.cell_chosen.emit(2,2);old_timer.timeout.emit();check(sent==count,"old token rejects callbacks")
			panel.queue_free();await settle()
	print("CH10 PUZZLE PANEL: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
