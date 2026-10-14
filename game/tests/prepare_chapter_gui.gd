extends "res://tests/test_chapter_one.gd"
## Generates valid QA checkpoints by executing campaign events and real combat.
## Set XDG_DATA_HOME to a dedicated QA directory, never a player's data.
func run() -> void:
	base = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var campaign := Campaign.new(base)
	complete_prologue(campaign)
	var store := Saves.new("user://saves")
	check(store.save_game(campaign,"manual") == "","write completed prologue manual slot")
	campaign.enter_chapter_one()
	var directory := "user://qa_checkpoints"
	DirAccess.make_dir_recursive_absolute(directory)
	var previous := ""
	while not campaign.state.finished:
		var event := campaign.current_event()
		var scene_id: String = campaign.scene().id
		if previous != scene_id or event.op in ["battle","trial"]:
			var file := FileAccess.open(directory+"/"+campaign.current_token().replace(":","_")+".json",FileAccess.WRITE)
			file.store_string(JSON.stringify(campaign.export_save(),"\t"))
			file.close()
		previous = scene_id
		if not act(campaign,1):
			push_error("Cannot prepare "+campaign.current_token())
			quit(1)
			return
	print("QA checkpoints: "+ProjectSettings.globalize_path(directory))
	print("Entry slot: "+store.directory+"/manual.json")
	quit(1 if failures else 0)
