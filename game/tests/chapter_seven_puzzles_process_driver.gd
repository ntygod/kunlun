extends SceneTree
const R=preload("res://scripts/puzzles/chapter_seven_puzzle_resolver.gd")
const Fixtures=preload("res://tests/test_chapter_seven_puzzles.gd")
const FILE="user://chapter_seven_puzzle_parts.json"
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():quit(2);return
	if args[0]=="write":
		var saved:Dictionary={}
		for id in R.IDS:
			var r:=R.new();r.begin(id,"process:"+id,Fixtures.fixture(id))
			for i in range(5):r.apply_input(r.next_demo_action())
			if id.begins_with("formation") and r.state.moving.is_empty():r.apply_input(r.next_demo_action())
			saved[id]=r.snapshot()
		var file:=FileAccess.open(FILE,FileAccess.WRITE);file.store_string(JSON.stringify(saved));print("CH07_PUZZLE_PROCESS_WRITE ",saved.size());quit()
	elif args[0]=="read":
		var saved:Variant=JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if not saved is Dictionary:quit(2);return
		for id in R.IDS:
			var r:=R.new()
			if not r.restore(saved[id],Fixtures.fixture(id)):push_error("Independent restore "+id);quit(1);return
			for i in range(1800):
				if r.state.complete:break
				if not r.apply_input(r.next_demo_action()).ok:push_error("Independent resume "+id);quit(1);return
			if not r.state.complete or not R.replay_receipt(r.receipt(),id,r.attempt_id,r.context):push_error("Independent proof "+id);quit(1);return
		print("CH07_PUZZLE_PROCESS_READ 4 partial sessions resumed and verified");quit()
	else:quit(2)
