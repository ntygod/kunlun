extends SceneTree
const Flow=preload("res://tests/chapter_eight_campaign_driver.gd")
const R=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	await process_frame;await process_frame;await process_frame
func run() -> void:
	root.size=Vector2i(640,360)
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await settle();main._layout()
	check(main.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json")))=="","real chapter7 fixture")
	check(main.story.enter_registered_chapter(8),"real chapter8 admission")
	var visited:Array=[]
	for i in range(100):
		var event:Dictionary=main.story.current_event()
		if event.get("id","") in R.IDS:
			var session:RefCounted=main.story.current_chapter_runtime().make_puzzle()
			main._show_registered_puzzle();await settle()
			var panel:Control=main.registered_puzzle_panel
			var scroll:ScrollContainer=main.modal_content.get_parent()
			var body:Rect2=panel.get_global_rect();var area:Rect2=scroll.get_global_rect()
			check(main.mode=="chapter_puzzle","registered modal entered")
			check(area.encloses(body),"640 body fully visible: "+event.id+" body="+str(body)+" area="+str(area))
			check(area.encloses(panel._board.get_global_rect()),"always-visible actual diagram: "+event.id)
			check(area.encloses(panel._buttons.close.get_global_rect()),"pause not clipped: "+event.id)
			check(area.encloses(panel._buttons.hint.get_global_rect()),"hint not clipped: "+event.id)
			check(panel._labels.rules.text==session.instruction(),"full unhidden rules in normal body")
			check(panel.input_submitted.get_connections().size()==1,"main signal exactly once")
			check(panel.close_requested.is_connected(main._return_from_puzzle),"main close wired")
			var before:int=session.state.hint;panel._buttons.hint.pressed.emit()
			check(session.state.hint==before+1,"main action routed to authoritative session")
			for j in range(2):panel._buttons.hint.pressed.emit()
			panel._buttons.demo.pressed.emit();check(panel._demo_running,"demo started")
			main._stop_registered_puzzle_demonstration();check(not panel._demo_running,"main menu/save-load hook stops demo")
			var state_before:Dictionary=session.snapshot();panel._tick();check(state_before==session.snapshot(),"stopped hook emits no more proof input")
			main.modal.hide();visited.append(event.id)
		if visited.size()==3:break
		if not Flow.advance(main.story,false):check(false,"real flow blocked "+str(event));break
	check(visited==R.IDS,"all three real registered panels tested")
	main.queue_free();await process_frame
	print("Chapter eight main puzzle: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
