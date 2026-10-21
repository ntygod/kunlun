extends SceneTree
const R=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
const F=preload("res://tests/test_chapter_eight_puzzles.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	var mode:String=args[0] if not args.is_empty() else "write"
	var path:String="user://chapter_eight_puzzle_process.json"
	if mode=="write":
		var entries:Array=[]
		for id in R.IDS:
			var r:=R.new();r.begin(id,"process:"+id,F.fixture(id))
			for i in range(3):r.apply_input({"type":"hint"})
			for i in range(5):r.apply_input({"type":"assist_step_v1"})
			entries.append({"context":r.context,"snapshot":r.snapshot()})
		var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(entries));file.close()
		print("CH08_PROCESS_WRITE partial real input snapshots ",entries.size());quit();return
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null:push_error("missing independent process file");quit(1);return
	var entries:Variant=JSON.parse_string(file.get_as_text());file.close()
	for entry in entries:
		var r:=R.new()
		if not r.restore(entry.snapshot,entry.context):push_error("independent restore failed");quit(1);return
		if not r.state.assisted:push_error("assisted lost across process");quit(1);return
		for i in range(90):
			if r.state.complete:break
			if not r.apply_input({"type":"assist_step_v1"}).ok:push_error("post-restore legal action failed");quit(1);return
		if not r.state.complete or not R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,entry.context):push_error("post-process proof failed");quit(1);return
	print("CH08_PROCESS_READ all 3 restored and finished with exact proofs");quit()
