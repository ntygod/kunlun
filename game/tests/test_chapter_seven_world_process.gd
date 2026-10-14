extends SceneTree
const C=preload("res://scripts/world_actions/chapter_seven_world_actions.gd")
const D=preload("res://tests/chapter_seven_world_driver.gd")
const PATH="user://chapter_seven_world_process.json"
func _initialize() -> void:
	var records:Array=[]
	if "--write" in OS.get_cmdline_user_args():
		for id in C.IDS:
			var c=C.new();var context:=D.preview_context(id)
			if not c.begin(id,"process",context):quit(1);return
			for i in range(8):
				if not c.state.complete:c.apply_input(D.next_input(c.get_view()))
			records.append({"snapshot":c.snapshot(),"context":context})
		var file:=FileAccess.open(PATH,FileAccess.WRITE);file.store_string(JSON.stringify(records));file.close()
		print("Chapter seven world process: wrote 4 partial snapshots");quit();return
	var decoded:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not decoded is Array or decoded.size()!=C.IDS.size():quit(1);return
	for record in decoded:
		var c=C.new()
		if not c.restore(record.snapshot,record.context):printerr("restore failed");quit(1);return
		for i in range(200):
			if c.state.complete:break
			if not c.apply_input(D.next_input(c.get_view())).get("ok",false):printerr("resume input failed");quit(1);return
		if not c.state.complete or C.replay_receipt(c.receipt(),record.context).is_empty():printerr("resumed proof failed");quit(1);return
	print("Chapter seven world process: restored and completed 4 partial snapshots");quit()
