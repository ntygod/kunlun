extends "res://tests/test_chapter_six_combat.gd"
## Explicitly synthetic state probes use the real natural party as their baseline.
func run():
	var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
	check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json")))=="","natural boundary fixture")
	natural_party=c.current_chapter_runtime().combat_party()
	var s=make();var d=Driver.new(check)
	d.input(s,H,"gua","qian_li");d.input(s,H,"step","qian");d.command(s,H,"normal_attack","gongyang_plum")
	var before=s.snapshot()
	check(s.restore(JSON.parse_string(JSON.stringify(before))),"partial compiled restore")
	check(Compare.equivalent(before,s.snapshot()),"partial no resource reset")
	for field in ["encounter_id","attempt_id","version","history","state"]:
		var bad=before.duplicate(true);bad[field]=true
		check(not s.restore(bad) and Compare.equivalent(before,s.snapshot()),"restore type atomic "+field)
	for op in [{"op":"command","actor_id":true,"skill_id":"normal_attack","target_id":"gongyang_plum"},{"op":"input","input":{"actor_id":H,"action_id":"gua","value":5}},{"op":"resolve","success":true}]:
		var bad=before.duplicate(true);bad.history.append(op)
		check(not s.restore(bad) and Compare.equivalent(before,s.snapshot()),"replay type atomic")
	check(s.set_command(H,"normal_attack",H)!="" and Compare.equivalent(before,s.snapshot()),"enemy command rejects self atomically")
	check(s.set_command(H,"self_guard","gongyang_plum")!="" and Compare.equivalent(before,s.snapshot()),"self command rejects enemy atomically")
	check(s.set_command("char_liu_yingying","normal_attack","gongyang_plum")!="" and Compare.equivalent(before,s.snapshot()),"absent Liu cannot act")
	d.input(s,H,"cancel")
	check(s.engine.state.commands.is_empty() and s.engine.state.objective.pending.is_empty() and not s.can_resolve(),"cancel clears complete compiled exchange")
	check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"cancel replay")
	# MP already spent remains spent across intermediate restore and round changes.
	var p=natural_party.duplicate(true);p[0].skills.append("LX_A03");p[0].skill_ranks.LX_A03=1
	s=make("white_plum",p)
	d.input(s,H,"gua","qian_li");d.input(s,H,"step","qian");d.command(s,H,"LX_A03","gongyang_plum");d.resolve(s)
	var h=s.engine.actor_by_id(H);var after_mp=int(h.mp)
	check(after_mp<int(h.max_mp) and int(h.jiugong_speed_round)==2,"A03 spends source mana and schedules next-round speed")
	check(s.engine._speed(h,0)==int(h.spd)+10,"jiugong speed next round only")
	check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))) and int(s.engine.actor_by_id(H).mp)==after_mp,"mid-exchange save never refills")
	check(s.set_command(H,"LX_A03","gongyang_plum")!="","A03 CD1 cannot repeat second round")
	# Two genuine unguarded carry inputs lose the basket; no success flag.
	s=make("basket_guard")
	for i in range(2):
		d.input(s,H,"carry");d.command(s,A,"self_guard",A);d.resolve(s)
	check(s.engine.state.outcome=="defeat" and s.engine.state.objective.misses==2,"two unguarded carries fail")
	check(s.receipt().is_empty(),"failed objective no proof")
	s=make("basket_guard");before=s.snapshot()
	check(not s.apply_input({"actor_id":A,"action_id":"carry"}).accepted and Compare.equivalent(before,s.snapshot()),"wrong carrier atomic")
	d.input(s,H,"carry");d.command(s,A,"guard_ally",H)
	check(s.set_command(A,"guard_ally","yard_partner")!="","guard enemy invalid")
	check(s.set_command(A,"guard_ally",A)!="","guard self invalid")
	before=s.snapshot();d.resolve(s)
	var damage=[]
	for e in s.engine.state.events:
		if e.type=="damage":damage.append(e)
	check(damage.size()==2 and damage[0].target==H and damage[1].target==A,"guard splits unique action across carrier and guardian")
	check(float(damage[0].detail.raw)==27.5 and float(damage[1].detail.raw)==27.5,"guard shares raw once before independent DEF")
	check(s.engine.state.objective.distance==1,"guarded carrier advances")
	check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"guard round replay")
	# Synthetic control and DOT gates: no state forge is accepted as a receipt.
	s=make("basket_guard");var a=s.engine.actor_by_id(A);a.controllable=false
	before=s.snapshot()
	check(s.set_command(A,"guard_ally",H)!="" and not s.apply_input({"actor_id":A,"action_id":"cancel"}).accepted and Compare.equivalent(before,s.snapshot()),"uncontrollable rejects every edit")
	s=make("basket_guard");h=s.engine.actor_by_id(H);h.hp=10;h.shield=4
	h.statuses=[{"kind":"damage_reduction","value":0.5,"starts":1,"expires":3}]
	var lost=s.engine._dot_damage(s.engine.actor_by_id("yard_partner"),h,20,"bleed")
	check(lost==6 and h.hp==4 and h.shield==0,"DOT takes highest protection once, consumes shield, no second DEF")
	s.engine._dot_damage(s.engine.actor_by_id("yard_partner"),h,20,"bleed")
	check(h.hp==1 and s.engine.state.outcome=="defeat","DOT nonlethal stop uses shared loss gate")
	# Finite editing with an always-available original-entry retry.
	s=make();before=s.snapshot()
	for i in range(32):check(s.apply_input({"actor_id":H,"action_id":"gua","value":"qian_li"}).accepted,"bounded edit")
	check(not s.apply_input({"actor_id":H,"action_id":"step","value":"qian"}).accepted,"edit cap finite")
	s.retry();check(Compare.equivalent(before,s.snapshot()),"edit cap cannot trap player; retry exact")
	print("CH06 boundaries ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
