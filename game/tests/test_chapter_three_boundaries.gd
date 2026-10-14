extends "res://tests/test_chapter_three.gd"
const Canonical = preload("res://scripts/campaign/encounter_session.gd")
func clone_campaign(snapshot: Dictionary) -> CampaignState:
	var c:=Campaign.new(base)
	check(c.restore(JSON.parse_string(JSON.stringify(snapshot)))=="","boundary fixture valid")
	return c
func rejection(candidate: Variant, stable: CampaignState, label: String) -> void:
	var before:=stable.export_save()
	check(stable.restore(candidate)!="",label+" rejected")
	check(Canonical.equivalent(stable.export_save(),before),label+" atomic")
func until_op(c: CampaignState, op: String) -> void:
	var budget:=0
	while c.current_event().get("op","")!=op and budget<100:
		check(act_three(c),"boundary advance");budget+=1
func bcommand(s: RefCounted, skill: String) -> void:
	check(s.set_command("char_liang_xiao",skill,"char_liang_xiao" if skill=="self_guard" else "char_ming_sanqiu")=="","boundary battle command")
	check(s.resolve_round(),"boundary battle round")
func run() -> void:
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var c:=chapter_two_ending(true)
	var prior:=c.export_save()
	check(c.enter_chapter_three(),"boundary chapter3 entry")
	var initial:=c.export_save()
	check(not c.enter_chapter_three(),"repeat transition rejected")
	check(not c.chapter_three.complete(c.current_token(),{}),"bare route completion rejected")
	check(Canonical.equivalent(c.export_save(),initial),"bare route failure atomic")
	for value in [null,false,true,0,1,"",[],{}]: rejection(value,c,"top value")
	for key in initial:
		for value in [null,false,0,"",[],{}]:
			if Canonical.equivalent(initial[key],value): continue
			var bad:=initial.duplicate(true);bad[key]=value
			rejection(bad,c,"top field "+key)
	var bad:=initial.duplicate(true);bad.version=4;rejection(bad,c,"future version")
	bad=initial.duplicate(true);bad["unknown"]=1;rejection(bad,c,"unknown root")
	bad=initial.duplicate(true);bad.prior_campaign=initial.duplicate(true);rejection(bad,c,"same-version recursive base")
	bad=initial.duplicate(true);bad.chapter_three.xp+=100;rejection(bad,c,"unearned xp")
	bad=initial.duplicate(true);bad.chapter_three.liang_age=17;rejection(bad,c,"premature next-year age")
	bad=initial.duplicate(true);bad.items.item_ch02_qingxin_inkstone.form="broken_fragment";rejection(bad,c,"unearned fragment")
	bad=initial.duplicate(true);bad.chapter_three.position=[99999,0];rejection(bad,c,"outside map")
	bad=initial.duplicate(true);bad.chapter_three.chronology=[{"kind":"complete","token":c.current_token(),"proof":{"won":true}}];rejection(bad,c,"fabricated first route")
	until_op(c,"puzzle")
	var token:=c.current_token()
	check(c.chapter_three.puzzle_input(token,JSON.parse_string('{"type":"tea_transfer","cup":0,"amount":1}')).ok,"JSON numeric action supported")
	var partial:=c.export_save();var resumed:=clone_campaign(partial)
	check(resumed.chapter_three.make_puzzle().get_view().state.cups==[1,0,0],"partial tea restores")
	bad=partial.duplicate(true);bad.chapter_three.puzzle_snapshot.state.complete=true;rejection(bad,c,"forged partial puzzle state")
	for action in [{"type":"tea_transfer","cup":1,"amount":1},{"type":"tea_transfer","cup":2,"amount":1},{"type":"submit"}]: resumed.chapter_three.puzzle_input(token,action)
	check(resumed.current_token()!=token,"partial tea resumes to actual completion")
	check(not resumed.chapter_three.puzzle_input(token,{"type":"submit"}).ok,"stale puzzle token rejected")
	until_op(resumed,"objective_battle")
	var before_battle:=resumed.export_save()
	var s:=resumed.chapter_three.make_objective_encounter()
	bcommand(s,"observe")
	check(s.apply_input({"action_id":"rotate_ring","direction":"right"}).accepted,"unresolved ring input")
	resumed.chapter_three.save_objective_checkpoint(s)
	var battle_saved:=resumed.export_save();var battle_loaded:=clone_campaign(battle_saved)
	var copied:=battle_loaded.chapter_three.make_objective_encounter()
	check(copied!=null and Canonical.equivalent(copied.snapshot(),s.snapshot()),"partial commands/ring/round snapshot restored")
	bad=battle_saved.duplicate(true);bad.chapter_three.objective_snapshot.state.actors[0].hp+=100;rejection(bad,resumed,"forged boss HP")
	bad=battle_saved.duplicate(true);bad.chapter_three.objective_snapshot.checkpoint_history_size=10000;rejection(bad,resumed,"forged boss checkpoint")
	var phase_campaign:=clone_campaign(before_battle);s=phase_campaign.chapter_three.make_objective_encounter()
	for i in range(70):
		if int(s.engine.state.objective.phase)==2 or s.get_view().outcome!="":break
		var beat: String=s.engine.state.intents[0].beat
		bcommand(s,"self_guard" if beat=="release" else ("sancai_counter" if beat=="thrust" else "normal_attack"))
	check(int(s.engine.state.objective.phase)==2,"actual phase2 reached")
	var phase_snapshot: Dictionary=s.snapshot()
	phase_campaign.chapter_three.save_objective_checkpoint(s)
	var restored_phase:=clone_campaign(phase_campaign.export_save())
	var session2:=restored_phase.chapter_three.make_objective_encounter()
	check(Canonical.equivalent(session2.snapshot(),phase_snapshot),"phase2 disk form exact")
	bcommand(session2,"self_guard");session2.retry()
	check(Canonical.equivalent(session2.snapshot(),phase_snapshot),"retry returns exact real phase2 checkpoint")
	check(restored_phase.state.xp==2325,"checkpoint does not issue B01 XP")
	var store:=Saves.new("user://chapter_three_boundary_slots")
	check(store.save_game(restored_phase)=="","phase disk save")
	var disk:=Campaign.new(base)
	check(store.load_game(disk)=="" and disk.active_chapter==3,"independent campaign reads phase save")
	var malformed:=restored_phase.export_save();malformed.current["fake_success"]=true
	rejection(malformed,restored_phase,"unknown chapter field")
	var old:=Campaign.new(base);check(old.restore(prior)=="" and old.active_chapter==2,"prior v3 remains chapter2")
	print("Chapter three boundaries: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
