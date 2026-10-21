extends SceneTree
const R=preload("res://scripts/puzzles/chapter_twelve_puzzle_resolver.gd")
const Fixtures=preload("res://tests/test_chapter_twelve_puzzles.gd")
const PuzzlePanel=preload("res://scripts/ui/chapter_twelve_puzzle_panel.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(v:bool,label:String)->void:
	checks+=1
	if not v:failures+=1;push_error(label)
func mouse(at:Vector2,pressed:bool)->void:
	var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
	var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;event.pressed=pressed;Input.parse_input_event(event)
func click(at:Vector2)->void:
	mouse(at,true);await process_frame;mouse(at,false);await process_frame
func enter()->void:
	for pressed in [true,false]:
		var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.physical_keycode=KEY_ENTER;key.pressed=pressed;Input.parse_input_event(key);await process_frame
func run()->void:
	for dimensions in [Vector2i(640,360),Vector2i(1280,720)]:
		root.size=dimensions
		for id in R.IDS:
			var r:=R.new();r.begin(id,"input",Fixtures.fixture(id,"b"));var panel:=PuzzlePanel.new();root.add_child(panel);panel.position=Vector2(20,20);panel.size=Vector2(dimensions)-Vector2(40,70)
			panel.input_submitted.connect(func(action:Dictionary):r.apply_input(action);panel.render(r.get_view()))
			panel.render(r.get_view());await process_frame;await process_frame
			check(panel.get_combined_minimum_size().x<=panel.size.x,"width fits")
			check(panel.get_combined_minimum_size().y<=panel.size.y,"height fits")
			await click(panel._buttons.hint.get_global_rect().get_center());check(r.state.hint==1,"actual mouse hint routing")
			panel._buttons.hint.grab_focus();await enter();check(r.state.hint==2,"actual Return routing")
			await enter();check(r.state.hint==3,"third hint keyboard")
			if id==R.IDS[2]:
				for target in r.observations():r.apply_input({"type":"observe","target":target})
				panel.render(r.get_view());await process_frame
				var before:Array=r.state.slots.duplicate()
				await click(panel._board.global_position+panel._board.point(0));await click(panel._board.global_position+panel._board.point(1))
				check(r.state.slots[0]==before[1] and r.state.slots[1]==before[0],"actual board clicks swap slots")
			panel._buttons.demo.grab_focus();await enter();check(panel._demo_running,"Return starts legal demo")
			panel.hide();check(not panel._demo_running,"hide cancels timer")
			panel.show();await process_frame;panel._buttons.demo.grab_focus();await enter()
			for i in range(60):
				if r.state.complete:break
				panel._tick()
			check(r.state.complete and r.proof().assisted,"demo uses actual legal sequence")
			check(R.replay_receipt(r.proof(),id,"input",r.context),"UI proof replays")
			panel.queue_free();await process_frame
	print("CH12 PUZZLE INPUT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
