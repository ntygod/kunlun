extends "res://tests/test_chapter_three.gd"
## Dedicated isolated QA data only. Optional user argument: a real chapter2 terminal save.
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var campaign: CampaignState
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		campaign=Campaign.new(base)
		var error:=campaign.restore(JSON.parse_string(FileAccess.get_file_as_string(args[0])))
		if error!="": push_error(error);quit(1);return
	else: campaign=chapter_two_ending(true)
	var store:=Saves.new("user://saves")
	check(store.save_game(campaign)=="","valid chapter2 QA start saved")
	check(campaign.enter_chapter_three(),"chapter3 entered normally")
	var directory:="user://chapter_three_checkpoints"
	DirAccess.make_dir_recursive_absolute(directory)
	var previous:=""
	while not campaign.state.finished:
		var event:=campaign.current_event()
		if previous!=campaign.scene().id or event.op in ["puzzle","world_puzzle","objective_battle","choice"]:
			var file:=FileAccess.open(directory+"/"+campaign.current_token().replace(":","_")+".json",FileAccess.WRITE)
			file.store_string(JSON.stringify(campaign.export_save(),"\t"));file.close()
		previous=campaign.scene().id
		if not act_three(campaign,0): push_error("Failed to prepare "+campaign.current_token());quit(1);return
	print("Chapter3 valid QA checkpoints: "+ProjectSettings.globalize_path(directory))
	quit(1 if failures else 0)
