extends "res://tests/test_chapter_two.gd"
## Dedicated QA directory only; no production menu jump path.
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var campaign:=Campaign.new(base)
	complete_prologue(campaign)
	campaign.enter_chapter_one()
	while not campaign.state.finished: act(campaign,0)
	var store:=Saves.new("user://saves")
	check(store.save_game(campaign)=="","legitimate chapter1 ending QA slot")
	campaign.enter_chapter_two()
	var directory:="user://chapter_two_checkpoints"
	DirAccess.make_dir_recursive_absolute(directory)
	var previous:=""
	while not campaign.state.finished:
		var scene_id: String=campaign.scene().id
		var event:=campaign.current_event()
		if previous!=scene_id or event.op in ["objective_battle","puzzle","quest_window"]:
			var file:=FileAccess.open(directory+"/"+campaign.current_token().replace(":","_")+".json",FileAccess.WRITE)
			file.store_string(JSON.stringify(campaign.export_save(),"\t"));file.close()
		previous=scene_id
		if not act_two(campaign,true,0): push_error("Failed to prepare "+campaign.current_token());quit(1);return
	print("Chapter2 valid QA checkpoints: "+ProjectSettings.globalize_path(directory))
	quit(1 if failures else 0)
