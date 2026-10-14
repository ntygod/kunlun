extends SceneTree
const Campaign = preload("res://scripts/campaign/campaign_state.gd")
const Trial = preload("res://scripts/campaign/three_move_trial.gd")
const Glyph = preload("res://scripts/ui/glyph_board.gd")
const Saves = preload("res://scripts/save_store.gd")
var checks := 0
var failures := 0
var base: Dictionary
func _initialize() -> void: call_deferred("run")
func check(value: bool, note: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: "+note)
func complete_prologue(campaign: CampaignState) -> void:
	while not campaign.state.finished:
		var entry := campaign.scene()
		for object in entry.objects: campaign.observe(object.id)
		if entry.get("mode", "dialogue") != "dialogue": campaign.solve_puzzle(entry.mode)
		check(campaign.commit_choice(entry.id,0),"legacy prologue completes before chapter entry")
func win(session: EncounterSession) -> void:
	var rounds := 0
	while session.get_view().outcome == "" and rounds < 40:
		var view := session.get_view()
		var actor := session.engine.actor_by_id("char_liang_xiao")
		var enemy: Dictionary = {}
		for unit in view.actors:
			if unit.team == "enemy" and not unit.defeated:
				enemy = unit
				break
		var skill := "sancai_counter"
		if session.engine.validate_command(actor.id,skill,enemy.id) != "": skill = "normal_attack"
		check(session.set_command(actor.id,skill,enemy.id,int(view.revision)) == "","real battle command accepted")
		check(session.resolve_round(),"real round resolves")
		rounds += 1
	check(session.get_view().outcome == "victory","level1 encounter can actually be won")
func act(campaign: CampaignState, branch: int) -> bool:
	var event := campaign.current_event()
	var token := campaign.current_token()
	match event.op:
		"dialogue":
			check(not campaign.dialogue_lines().is_empty(),"typed dialogue slice has content")
			return campaign.finish_dialogue(token)
		"action":
			var proof := {}
			match event.kind:
				"glyph": proof = {"glyph":event.glyph,"strokes":11 if event.glyph == "梁" else 4}
				"work": proof = {"count":event.count}
				"route":
					var total: int = campaign.maps[campaign.scene().map_id].paths[event.id].size()
					proof = {"index":total,"total":total,"complete":true}
			return campaign.complete_action(token,event.id,proof)
		"choice":
			var choices := campaign.available_choices()
			check(not choices.is_empty(),"conditional choice always has an eligible path")
			return campaign.choose(token,choices[mini(branch,choices.size()-1)].id)
		"battle":
			var session := campaign.make_encounter()
			check(session.victory_receipt().is_empty(),"fresh battle has no victory receipt")
			var before := campaign.export_save()
			check(not campaign.finish_encounter(token,session),"battle cannot be skipped by UI completion")
			check(campaign.export_save() == before,"rejected battle receipt is atomic")
			# Actually lose by self-guarding, then retry the exact prebattle snapshot.
			var attempts := 0
			while session.get_view().outcome == "" and attempts < 80:
				var view := session.get_view()
				session.set_command("char_liang_xiao","self_guard","char_liang_xiao",int(view.revision))
				session.resolve_round()
				attempts += 1
			check(session.get_view().outcome == "defeat","encounter has a real defeat state")
			check(not campaign.finish_encounter(token,session),"defeat awards nothing")
			check(campaign.export_save() == before,"defeat preserves chapter checkpoint")
			session.retry()
			check(session.get_view().round == 1 and session.history.is_empty(),"retry clears trace and returns to round1")
			win(session)
			var receipt := session.victory_receipt()
			var forged := receipt.duplicate(true)
			forged.commands = []
			check(not campaign._accept_battle(token,forged),"victory text without battle trace rejected")
			var ok := campaign.finish_encounter(token,session)
			check(not campaign.finish_encounter(token,session),"duplicate victory cannot pay twice")
			return ok
		"trial":
			var trial := Trial.new()
			check(not campaign.finish_trial(token,trial),"three moves cannot bypass objective")
			trial.observe()
			trial.step("east")
			check(not trial.strike() and trial.failed,"incorrect feint produces a retry state")
			trial = Trial.new()
			for direction in ["west","east","north"]:
				trial.observe()
				trial.step(direction)
				check(trial.strike(),"ordered observed move is executed")
			return campaign.finish_trial(token,trial)
	return false
func run() -> void:
	base = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	for branch in [0,1]:
		var campaign := Campaign.new(base)
		check(not campaign.enter_chapter_one(),"cannot skip prologue completion")
		complete_prologue(campaign)
		var legacy_save := campaign.prologue.state.duplicate(true)
		check(campaign.enter_chapter_one(),"chapter transition is explicit")
		check(not campaign.enter_chapter_one(),"chapter transition initializes once")
		check(campaign.actors.char_liang_xiao.level == 1 and campaign.actors.char_liang_xiao.max_hp == 160,"child has correct bare plus equipment panel")
		check(campaign.actors.char_liang_wenjing.level == 15 and campaign.state.xp == 0,"fixed father account never leaks prologue XP")
		var step_count := 0
		while not campaign.state.finished and step_count < 100:
			var token := campaign.current_token()
			check(not campaign.complete_action("stale", "fake"),"stale or wrong world action rejected")
			check(act(campaign,branch),"event advances: "+token)
			var saved := campaign.export_save()
			var restored := Campaign.new(base)
			var error := restored.restore(JSON.parse_string(JSON.stringify(saved)))
			check(error == "","mid-step save/load: "+token+" "+error)
			check(JSON.stringify(restored.export_save()) == JSON.stringify(saved),"roundtrip derived state identical")
			step_count += 1
		check(campaign.state.finished,"chapter1 has a complete implemented flow")
		check(campaign.state.xp == 345 and campaign.actors.char_liang_xiao.level == 4,"30+30+285 reaches exactly level4")
		check(campaign.reward_ledger.size() == 3,"three unique XP transactions")
		check(campaign.actors.char_liang_wenjing.status == "dead" and campaign.actors.char_xiao_yuling.status == "taken_north","death and living departure remain distinct")
		check(campaign.actors.follower_baichier.status == "follower","puppy is adopted outside combat")
		check("LX_A01" in campaign.actors.char_liang_xiao.skills,"observation learned only after chapter self-reflection")
		check(campaign.items.item_ch01_xuanyuan_sword.state == "carried" and campaign.items.item_ch01_xuanyuan_sword.owner == "char_liang_xiao","main sword survives grave vow")
		check(campaign.world_objects.item_ch01_xuanyuan_sword.state == "wrapped","main sword wrapped at departure")
		check(campaign.world_objects.item_ch01_tomb_marker.text == "梁文","tombstone deliberately lacks Jing")
		if campaign.state.choices.ch01_unfinished_tombstone == "ch01_04_choice_b":
			check(campaign.items.item_ch01_memorial_broken_blade.state == "placed" and not "item_ch01_memorial_broken_blade" in campaign.state.inventory,"vow consumes separate broken blade")
		if campaign.items.has("item_ch01_unfinished_paper"):
			check(campaign.items.item_ch01_unfinished_paper.owner == "char_liang_xiao","father's paper transferred after death")
		var safe := campaign.export_save()
		var extra_event := safe.duplicate(true)
		extra_event.chapter_one.events.append({"step_id":"","proof":{}})
		check(campaign.restore(extra_event) != "","trailing empty event after ending rejected without script error")
		check(campaign.export_save() == safe,"trailing event restore remains atomic")
		for mutation in [{"version":true},{"version":99},{"active_chapter":"bad"},{"actors":{}},{"reward_ledger":{"cheat":1000}},{"chapter_one":[]}]:
			var broken := safe.duplicate(true)
			broken.merge(mutation,true)
			check(campaign.restore(broken) != "","malformed v2 save rejected")
			check(campaign.export_save() == safe,"malformed restore is atomic")
		var saves := Saves.new("user://chapter_one_tests_%d" % branch)
		var old := StoryState.new(base)
		old.restore(legacy_save)
		check(saves.save_game(old) == "","save old v1 slot")
		check(saves.save_game(campaign) == "","upgrade slot to v2")
		check(FileAccess.file_exists(saves.directory.path_join("manual.json.v1.bak")),"v1 file preserved during upgrade")
		var migrated := Campaign.new(base)
		check(migrated.restore(legacy_save) == "" and migrated.state.finished,"v1 migrates to completed prologue not skipped chapter1")
	# Guided input, not a generic solved checkbox.
	var board := Glyph.new()
	root.add_child(board)
	board.size = Vector2(300,200)
	board.setup("梁")
	board.size = Vector2(802,170)
	check(is_equal_approx(board.point([1,0]).x-board.point([0,0]).x,board.point([0,1]).y-board.point([0,0]).y),"wide glyph board preserves square aspect")
	check(not board.tap(Vector2.ZERO),"wrong glyph point does not complete stroke")
	for i in range(11):
		check(board.tap(board.current_start()),"stroke begins at authored start")
		check(board.tap(board.current_end()),"stroke ends at authored end")
	check(board.done and board.stroke_index == 11,"all guided Liang strokes required")
	board.queue_free()
	await process_frame
	print("Chapter one tests: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
