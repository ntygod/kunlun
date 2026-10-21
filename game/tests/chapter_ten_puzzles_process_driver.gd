extends SceneTree
const R=preload("res://scripts/puzzles/chapter_ten_puzzle_resolver.gd")
const Tests=preload("res://tests/test_chapter_ten_puzzles.gd")
const SAVE="user://chapter_ten_puzzles_process.json"
var failures:=0
var checks:=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run()->void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1 or args[0] not in ["write","read"]:
		push_error("Use -- write or -- read in separate processes");quit(1);return
	if args[0]=="write":
		var records:Array=[]
		for id in R.IDS:
			var model:=R.new();var context:Dictionary=Tests.fixture(id)
			check(model.begin(id,"process",context),"begin")
			for step in range(12):
				if (id==R.IDS[0] and model.state.steps==1) or (id==R.IDS[1] and model.state.awaiting_breath):break
				check(model.apply_input(model.next_demo_action()).ok,"real partial action")
			check(not model.state.complete,"partial only")
			records.append({"context":context,"snapshot":model.snapshot()})
		var file:=FileAccess.open(SAVE,FileAccess.WRITE)
		check(file!=null,"write file")
		if file:file.store_string(JSON.stringify(records));file.close()
	else:
		var records:Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		check(records is Array and records.size()==2,"read real file")
		if records is Array:
			for record in records:
				var model:=R.new()
				check(model.restore(record.snapshot,record.context),"new process replay partial")
				if model.state.is_empty():continue
				check(model.state.steps==1 if model.puzzle_id==R.IDS[0] else model.state.awaiting_breath,"exact partial point")
				for step in range(12):
					if model.state.complete:break
					check(model.apply_input(model.next_demo_action()).ok,"resume legal action")
				check(model.state.complete,"finish after new process")
				check(R.replay_receipt(model.receipt(),model.puzzle_id,model.attempt_id,record.context),"proof replay")
	print("CH10 PUZZLE PROCESS %s: %d checks, %d failures"%[args[0],checks,failures]);quit(1 if failures else 0)
