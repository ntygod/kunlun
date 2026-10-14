extends "res://tests/test_chapter_three.gd"
const Summary = preload("res://scripts/campaign/completed_chapter_summary.gd")
var natural_entries: Array = []

func continuity(campaign: CampaignState) -> Dictionary:
	var result := {"actors":campaign.actors.duplicate(true),"items":campaign.items.duplicate(true),
		"reward_ledger":campaign.reward_ledger.duplicate(true),"world_objects":campaign.world_objects.duplicate(true),"codex":campaign.codex.duplicate()}
	for key in ["chapter","quest_id","quest_phase","scene_index","step","finished","xp","memories","inventory","choices","observed","puzzles","optional","knowledge","assists","coins","currency_ledger","liang_age","xiaoshuang_age","inherited_choices","inherited_optional","padding"]:
		if campaign.state.has(key): result[key] = campaign.state[key].duplicate(true) if campaign.state[key] is Dictionary or campaign.state[key] is Array else campaign.state[key]
	return result

func candidate_before(chapter: int) -> CampaignState:
	var campaign := Campaign.new(base)
	for index in range(chapter):
		var error: String = Summary.apply(campaign,natural_entries[index])
		check(error == "","valid prior summary "+str(index)+": "+error)
	return campaign

func reject_summary(entry: Dictionary, label: String) -> void:
	var chapter: int = int(entry.get("chapter",0)) if Summary._whole(entry.get("chapter")) and int(entry.chapter) in [0,1,2,3] else 0
	var candidate := candidate_before(chapter)
	check(Summary.apply(candidate,entry) != "",label)
	check(not candidate._restoring_summary,label+" restores internal guard")

func run() -> void:
	base = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var fixture := ProjectSettings.globalize_path("res://").path_join("../output/cache/chapter_three_gui/manual_natural_final.json")
	var third: Dictionary
	if FileAccess.file_exists(fixture) and OS.get_environment("KUNLUN_SUMMARY_GENERATED_FIXTURE") != "1":
		third = JSON.parse_string(FileAccess.get_file_as_string(fixture))
		print("Summary source: actual natural GUI chapter-three ending")
	else:
		# The large manual QA save is intentionally not a required repository asset.
		# A clean checkout still exercises real model inputs through all chapters.
		var generated := chapter_two_ending(true,1)
		check(generated.enter_chapter_three(),"generated source enters chapter three")
		var steps := 0
		while not generated.state.finished and steps < 120:
			check(act_three(generated,1),"generated source performs actual chapter-three event")
			steps += 1
		check(generated.state.finished,"generated full source reaches actual ending")
		if not generated.state.finished: quit(1); return
		third = generated.export_legacy_save()
		print("Summary source: complete real-input model route (manual GUI fixture unavailable or fallback requested)")
	var second: Dictionary = third.prior_campaign
	var first: Dictionary = second.prior_campaign
	var historical := [first.prologue,first,second,third]
	var rebuilt := Campaign.new(base)
	for chapter in range(4):
		var original := Campaign.new(base)
		var error: String = original.restore(historical[chapter])
		check(error == "","strict natural legacy validation "+str(chapter)+": "+error)
		if error != "": quit(1); return
		var entry: Dictionary = Summary.pack(original,chapter)
		natural_entries.append(entry)
		check(not entry.is_empty(),"natural completed summary "+str(chapter))
		check(JSON.stringify(entry).to_utf8_buffer().size()<16000,"chapter summary has content-bounded size "+str(chapter))
		error = Summary.apply(rebuilt,JSON.parse_string(JSON.stringify(entry)))
		check(error == "","natural summary reduction "+str(chapter)+": "+error)
		if error != "": quit(1); return
		check(Summary._same(continuity(original),continuity(rebuilt)),"natural continuity preserved "+str(chapter))
		check(Summary._same(Summary.pack(rebuilt,chapter),entry),"summary repack stable "+str(chapter))
		if chapter == 1: check(rebuilt.progress.events.is_empty(),"completed chapter-one inputs absent")
		if chapter >= 2:
			check(rebuilt.state.chronology.is_empty() and rebuilt.state.puzzle_records.is_empty(),"completed input replay payload absent "+str(chapter))
		check(rebuilt.prior_campaign.is_empty(),"no recursive legacy payload "+str(chapter))
		for key in entry:
			var bad := entry.duplicate(true); bad.erase(key)
			reject_summary(bad,"missing summary field "+str(chapter)+"/"+key)
		for change in [{"unexpected":1},{"summary_version":999},{"choices":[]},{"milestones":{}},{"boundary_vitals":[]},{"chapter":true}]:
			var bad := entry.duplicate(true); bad.merge(change,true)
			reject_summary(bad,"invalid summary shape "+str(chapter)+str(change))
		var duplicate := entry.duplicate(true); duplicate.milestones.append(duplicate.milestones[0])
		reject_summary(duplicate,"duplicate milestone "+str(chapter))
		var missing := entry.duplicate(true); missing.milestones.remove_at(0)
		reject_summary(missing,"missing required milestone "+str(chapter))
		var extra := entry.duplicate(true); extra.milestones.append("receipt:future:unearned")
		reject_summary(extra,"unknown future milestone "+str(chapter))
		var choice := entry.duplicate(true); choice.choices["future_choice"] = 0 if chapter == 0 else "future"
		reject_summary(choice,"unregistered choice "+str(chapter))
		if chapter > 0:
			for vitals in [{"hp":1,"mp":0},{"hp":true,"mp":0},{"hp":1.5,"mp":0},{"hp":999999,"mp":0},{"hp":entry.boundary_vitals.hp,"mp":9999},{"hp":entry.boundary_vitals.hp,"mp":0,"future_skill":"LX_A04"}]:
				var bad := entry.duplicate(true); bad.boundary_vitals=vitals
				reject_summary(bad,"invalid boundary vitals "+str(chapter)+str(vitals))
	# Completed result methods are not normal gameplay completion authority.
	var guarded := candidate_before(1); guarded.enter_chapter_one()
	var before := continuity(guarded)
	check(not guarded.commit_archived_result({}),"chapter-one archive entry gated")
	check(Summary._same(before,continuity(guarded)),"blocked archive entry unchanged")
	guarded = candidate_before(2); guarded.enter_chapter_two()
	before = continuity(guarded)
	check(not guarded.chapter_two.commit_archived_result({}),"chapter-two archive entry gated")
	check(Summary._same(before,continuity(guarded)),"blocked runtime archive entry unchanged")
	# Exact dependencies: the paper-only tomb choice cannot be attached to no-paper history.
	var invalid_choice: Dictionary = natural_entries[1].duplicate(true)
	invalid_choice.choices.ch01_yicheng_inn = "ch01_01_choice_a"
	invalid_choice.choices.ch01_unfinished_tombstone = "ch01_04_choice_a"
	reject_summary(invalid_choice,"tomb paper choice requires inherited paper")
	for change in [{"optional_commits":[]},{"optional_dispositions":{"ch02_r01":"completed","ch02_k01":"unknown"}}]:
		var bad: Dictionary = natural_entries[2].duplicate(true); bad.merge(change,true)
		reject_summary(bad,"inconsistent optional outcome")
	var double: Dictionary = natural_entries[2].duplicate(true)
	double.optional_commits.append(double.optional_commits[0].duplicate(true))
	reject_summary(double,"duplicate optional result cannot mint reward")
	_prologue_observations()
	_partial_optional(first)
	_interleaved_optional(first)
	_chapter_three_outcome_matrix()
	print("Completed chapter summaries: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _partial_optional(first: Dictionary) -> void:
	var original := Campaign.new(base)
	check(original.restore(first)=="","partial-side prior legacy valid")
	check(original.enter_chapter_two(),"partial-side chapter entry")
	while original.current_event().op != "quest_window": check(act_two(original,false,1),"partial-side main advance")
	for id in ["ch02_r01","ch02_k01"]:
		check(original.chapter_two.open_sidequest(id),"partial-side open "+id)
		while original.current_event().op != "puzzle": check(act_two(original,false,1),"partial-side observations")
		check(act_two(original,false,1),"partial-side actual puzzle solved")
		check(original.chapter_two.pause_sidequest(),"solved-side can leave before aftermath")
	check(original.chapter_two.disposition("ch02_r01","declined"),"solved R01 may be declined")
	check(original.chapter_two.close_window(original.current_token()),"skip unarchived side aftermath")
	while not original.state.finished: check(act_two(original,false,1),"partial-side mainline completion")
	check(original.state.xp==1440 and original.state.optional.ch02_r01.disposition=="declined","partial-side no rewards")
	check(original.items.item_ch02_first_wrong_page.owner=="char_hua_xiaoshuang","partial R01 first page already transferred")
	check(not original.items.has("item_ch02_unclosed_workbook") and not original.items.has("item_ch02_shadow_measurement_notes"),"partial results are not archived rewards")
	var entry: Dictionary = Summary.pack(original,2)
	check(entry.optional_commits.size()==2,"only solved semantic commits retained")
	var rebuilt := candidate_before(2)
	var error: String = Summary.apply(rebuilt,entry)
	check(error=="","partial-side summary reduced: "+error)
	check(Summary._same(continuity(original),continuity(rebuilt)),"partial-side choices/page/dispositions preserved")
	check(rebuilt.state.assists.is_empty() and not "LX_A04_future_upgrade_eligible" in rebuilt.state.knowledge,"partial K01 grants no future eligibility")
	var bad := entry.duplicate(true)
	bad.optional_dispositions.ch02_r01="completed"
	reject_summary(bad,"solved-only cannot claim archived reward")
	bad = entry.duplicate(true)
	bad.optional_commits = [{"kind":"r01_archived"}]
	reject_summary(bad,"archive cannot precede solved")

func _interleaved_optional(first: Dictionary) -> void:
	var original := Campaign.new(base)
	check(original.restore(first)=="","interleaved legacy base")
	original.enter_chapter_two()
	while original.current_event().op != "quest_window": check(act_two(original,false,1),"interleaved main advance")
	check(original.chapter_two.open_sidequest("ch02_r01"),"interleaved R01 begin")
	while original.current_event().op != "puzzle": check(act_two(original,false,1),"interleaved R01 prelude")
	check(act_two(original,false,1),"interleaved R01 actually solved")
	check(original.chapter_two.pause_sidequest(),"interleaved R01 pause after solve")
	check(original.chapter_two.open_sidequest("ch02_k01"),"interleaved K01 begin")
	while original.state.scope != "main": check(act_two(original,false,1),"interleaved K01 through archive")
	check(original.chapter_two.open_sidequest("ch02_r01"),"interleaved R01 resume")
	while original.state.scope != "main": check(act_two(original,false,1),"interleaved R01 aftermath archive")
	original.chapter_two.close_window(original.current_token())
	while not original.state.finished: check(act_two(original,false,1),"interleaved finish chapter")
	var entry: Dictionary = Summary.pack(original,2)
	var kinds: Array = []
	for record in entry.optional_commits: kinds.append(record.kind)
	check(kinds==["r01_puzzle_solved","k01_puzzle_solved","k01_archived","r01_archived"],"four semantic commits preserve actual interleaving")
	var rebuilt := candidate_before(2)
	var error: String = Summary.apply(rebuilt,entry)
	check(error=="","interleaved summary reduced: "+error)
	check(Summary._same(continuity(original),continuity(rebuilt)),"interleaved memories/inventory/knowledge/assists preserve order")
	check(rebuilt.state.xp==2090 and rebuilt.state.coins==250,"interleaved rewards each once")

func _chapter_three_outcome_matrix() -> void:
	var branches := {
		"ch03_deception_exposed":["choice_ch03_denounce_deception","choice_ch03_shield_friends"],
		"ch03_public_reckoning":["choice_ch03_tease_ming","choice_ch03_explain_symbols"],
		"ch03_throne_refusal:reason":["choice_ch03_kind_leader","choice_ch03_seek_jianghu"],
		"ch03_throne_refusal:after":["choice_ch03_own_wrapped_sword","choice_ch03_warn_ming"],
		"ch03_hostage_confession":["choice_ch03_padding_inkstone","choice_ch03_padding_abacus"],
		"ch03_forest_shelter":["choice_ch03_monkey_guard","choice_ch03_hold_keepsake"]}
	for mask in range(64):
		var entry: Dictionary = natural_entries[3].duplicate(true)
		var index := 0
		for key in branches:
			entry.choices[key] = branches[key][(mask >> index) & 1]
			index += 1
		var rebuilt := candidate_before(3)
		var error: String = Summary.apply(rebuilt,entry)
		check(error=="","chapter-three legal completed outcome combination "+str(mask)+": "+error)
		if error != "": continue
		var inkstone: bool = entry.choices.ch03_hostage_confession=="choice_ch03_padding_inkstone"
		check(rebuilt.items.item_ch02_qingxin_inkstone.form==("broken_fragment" if inkstone else "intact"),"only reserved padding transforms")
		check(rebuilt.items.item_ch03_copper_abacus.state==("carried" if inkstone else "destroyed"),"abacus loan/damage matches padding choice")
		check(rebuilt.items.item_ch03_copper_abacus.loan_from=="天机宫论算案" and not rebuilt.items.item_ch03_copper_abacus.returned,"loan obligation retained")
		check(rebuilt.actors.char_hua_xiaoshuang.status=="separated_not_dead" and rebuilt.actors.follower_jinlinger.status=="sheltered_with_xiaoshuang","story separation does not become death")
		check(rebuilt.state.xp==3120 and rebuilt.state.coins==550,"chapter-three fixed rewards once")
		check(rebuilt.state.chronology.is_empty() and rebuilt.state.escape_receipts.is_empty(),"declarative outcome does not invent historical escape proof")

func _prologue_observations() -> void:
	var original := Campaign.new(base)
	while not original.state.finished:
		var scene: Dictionary = original.scene()
		var objects: Array = scene.objects.duplicate()
		objects.reverse()
		for object in objects: check(original.observe(object.id),"observe all optional objects in reverse order")
		if scene.get("mode","dialogue") != "dialogue": original.solve_puzzle(scene.mode)
		check(original.commit_choice(scene.id,0),"observed prologue completes normally")
	check(original.state.observed.shenxian_crossing.has("fallen_banner") and original.state.observed.shenxian_crossing.has("blade_mark"),"optional crossing discoveries actually recorded")
	var entry: Dictionary = Summary.pack(original,0)
	var rebuilt := Campaign.new(base)
	check(Summary.apply(rebuilt,entry)=="","all optional observations summarize and restore")
	check(Summary._same(original.state.observed,rebuilt.state.observed),"all registered optional observations and per-scene order preserved")
	check(Summary._same(continuity(original),continuity(rebuilt)),"observed prologue continuity exact")
	var bad := entry.duplicate(true); bad.observed.erase("bashan_inn")
	reject_summary(bad,"missing required observations rejected")
	bad = entry.duplicate(true); bad.observed.shenxian_crossing.append("unregistered_object")
	reject_summary(bad,"unknown optional observation rejected")
	bad = entry.duplicate(true); bad.observed["future_scene"]=[]
	reject_summary(bad,"unknown observation scene rejected even when empty")
	bad = entry.duplicate(true); bad.observed.shenxian_crossing.append(bad.observed.shenxian_crossing[0])
	reject_summary(bad,"duplicate observation rejected")
	for value in [[],true,0,null,"objects"]:
		bad = entry.duplicate(true); bad.observed=value
		reject_summary(bad,"invalid observed root type")
	for value in [{},true,0,null,"objects"]:
		bad = entry.duplicate(true); bad.observed.shenxian_crossing=value
		reject_summary(bad,"invalid observation list type")
	for value in [{},true,0,null,[]]:
		bad = entry.duplicate(true); bad.observed.shenxian_crossing=[value]
		reject_summary(bad,"invalid observed object type")
	bad = natural_entries[1].duplicate(true); bad["observed"]={}
	reject_summary(bad,"observation summary field restricted to prologue")
