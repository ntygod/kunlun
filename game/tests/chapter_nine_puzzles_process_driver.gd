extends SceneTree
const R=preload("res://scripts/puzzles/chapter_nine_puzzle_resolver.gd")
const T=preload("res://tests/test_chapter_nine_puzzles.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:=OS.get_cmdline_user_args();var mode:String=args[0] if not args.is_empty() else "write"
	var path:String="user://chapter_nine_puzzle_partial.json"
	if mode=="write":
		var pine:=R.new();assert(pine.begin(R.IDS[0],"process-pine",T.fixture(R.IDS[0])))
		for i in range(7):assert(pine.apply_input(pine.next_demo_action()).ok)
		var bird:=R.new();assert(bird.begin(R.IDS[1],"process-bird",T.fixture(R.IDS[1])))
		for i in range(10):assert(bird.apply_input(bird.next_demo_action()).ok)
		var carrying:Dictionary={"snapshot":bird.snapshot(),"context":bird.context.duplicate(true)}
		while bird.state.installed.size()<4:assert(bird.apply_input(bird.next_demo_action()).ok)
		var assembly:Dictionary={"snapshot":bird.snapshot(),"context":bird.context.duplicate(true)}
		while not bird.state.complete:assert(bird.apply_input(bird.next_demo_action()).ok)
		var c:Dictionary=T.fixture(R.IDS[1]);c.scene_id="ch09_cloud_escape";c.current_token="escape-process";c.wood_bird_checkpoint=bird.snapshot();c.wood_bird_context=bird.context.duplicate(true)
		var flight:=R.new();assert(flight.begin(R.IDS[1],"process-flight",c))
		assert(flight.apply_input({"type":"crank"}).ok)
		var cranking:Dictionary={"snapshot":flight.snapshot(),"context":flight.context.duplicate(true)}
		assert(flight.apply_input({"type":"release"}).ok);assert(flight.apply_input({"type":"rail"}).ok)
		var payload:Dictionary={"pine":{"snapshot":pine.snapshot(),"context":pine.context},"carrying":carrying,"assembly":assembly,"cranking":cranking,"flight":{"snapshot":flight.snapshot(),"context":flight.context}}
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(payload));file.close()
		print("WROTE partial states: pine cursor=",pine.state.cursor," phase=",pine.state.phase," assembly installed=",assembly.snapshot.state.installed," flight stage=",flight.state.stage," rail=",flight.state.rail_index)
	else:
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path));assert(parsed is Dictionary)
		for key in parsed:
			var r:=R.new();assert(r.restore(parsed[key].snapshot,parsed[key].context));var before:Dictionary=r.snapshot()
			var corrupt:Dictionary=before.duplicate(true);corrupt.state.complete=true
			assert(not r.restore(corrupt,r.context));assert(r.snapshot()==before)
			while not r.state.complete:assert(r.apply_input(r.next_demo_action()).ok)
			assert(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context))
			print("RESTORED ",key," verified phase=",parsed[key].snapshot.state.get("phase",parsed[key].snapshot.state.get("stage"))," => ",r.state.get("stage","pine_complete"))
	print("CH09 PROCESS ",mode," PASS");quit()
