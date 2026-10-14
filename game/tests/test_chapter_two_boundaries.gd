extends "res://tests/test_chapter_two.gd"
func clone(campaign: CampaignState) -> CampaignState:
	var copy:=Campaign.new(base)
	check(copy.restore(JSON.parse_string(JSON.stringify(campaign.export_save())))=="","boundary JSON restore succeeds")
	return copy
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var campaign:=Campaign.new(base)
	complete_prologue(campaign)
	campaign.enter_chapter_one()
	while not campaign.state.finished: act(campaign,0)
	var old:=campaign.export_save()
	var saves:=Saves.new("user://chapter_two_migration_boundary")
	check(saves.save_game(campaign)=="","v2 slot saved before upgrade")
	var original:=FileAccess.get_file_as_string(saves.directory+"/manual.json")
	campaign.enter_chapter_two()
	check(saves.save_game(campaign)=="","v3 slot saved after validated entry")
	check(FileAccess.get_file_as_string(saves.directory+"/manual.json.v2.bak")==original,"original v2 bytes preserved")
	check(Campaign.new(base).restore(old)=="","old v2 still independently valid")
	while campaign.current_event().op!="quest_window":
		check(act_two(campaign,false),"advance to optional window")
	campaign.state.position=[111,112]
	check(campaign.chapter_two.open_sidequest("ch02_r01"),"R01 accepts")
	while campaign.current_event().op!="puzzle": act_two(campaign,false)
	var token:=campaign.current_token()
	campaign.chapter_two.puzzle_input(token,{"type":"place_piece","slot":0,"piece":0})
	campaign=clone(campaign)
	check(campaign.chapter_two.make_puzzle().get_view().state.values[0]==0,"partial piece survives save/load")
	campaign.state.position=[210,211]
	check(campaign.chapter_two.pause_sidequest(),"unfinished side quest may leave")
	campaign=clone(campaign)
	check(campaign.current_event().op=="quest_window","unfinished side returns to main window")
	check(campaign.chapter_two.disposition("ch02_k01","deferred"),"other quest can defer independently")
	check(campaign.chapter_two.open_sidequest("ch02_r01"),"R01 resumes")
	check(campaign.current_token()==token and campaign.chapter_two.make_puzzle().get_view().state.values[0]==0,"same partial step restored after side return")
	check(campaign.chapter_two.pause_sidequest(),"can leave resumed puzzle")
	check(campaign.chapter_two.disposition("ch02_r01","declined"),"can decline without reward")
	check(campaign.chapter_two.close_window(campaign.current_token()),"mainline does not require optional completion")
	while not campaign.state.finished: check(act_two(campaign,false),"continue mainline without optional rewards")
	check(campaign.state.xp==1440,"partial/declined side quests do not pay")
	check(campaign.state.optional.ch02_r01.status=="missed" and campaign.state.optional.ch02_k01.status=="missed","deadline closes both unfinished quests")
	check(not campaign.chapter_two.open_sidequest("ch02_r01"),"closed window cannot reopen after time jump")
	check(not campaign.reward_ledger.has("reward_ch02_r01_once"),"no premature side ledger")
	var safe:=campaign.export_save()
	var broken:=safe.duplicate(true)
	broken.chapter_two.chronology.append({"kind":"complete","token":"","proof":{}})
	check(campaign.restore(broken)!="" and campaign.export_save()==safe,"trailing empty record rejected atomically")
	for key in safe:
		for value in [null,true,false,0,1,"bad",[],{}]:
			if EncounterSession.equivalent(safe[key],value): continue
			broken=safe.duplicate(true);broken[key]=value
			check(campaign.restore(broken)!="","invalid v3 envelope field "+key)
			check(campaign.export_save()==safe,"bad v3 restore leaves live state unchanged")
	# A world observation is not accepted merely because an objective ID is correct.
	var fresh:=Campaign.new(base);fresh.restore(old);fresh.enter_chapter_two()
	fresh.finish_dialogue(fresh.current_token())
	check(not fresh.complete_action(fresh.current_token(),fresh.current_event().id,{"index":3,"total":3,"complete":true}),"route without map/position evidence rejected")
	var exercise:=GuidedExercise.new();exercise.begin("jing_writing","type-fuzz")
	for value in [null,true,false,0,1,[],{}]: check(not exercise.apply_input({"type":value}).ok,"bad guided action type rejected")
	print("Chapter two boundaries: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
