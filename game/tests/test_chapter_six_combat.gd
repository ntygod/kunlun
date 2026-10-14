extends SceneTree
const Session=preload("res://scripts/combat/chapter_six_encounter.gd")
const Driver=preload("res://tests/chapter_six_battle_driver.gd")
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Compare=preload("res://scripts/campaign/encounter_session.gd")
const H="char_liang_xiao"
const A="char_axue"
var checks:=0
var failures:=0
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
var runtime: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_six_encounters.json"))
var natural_party: Array=[]
func _initialize():call_deferred("run")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures+=1;push_error(msg)
func make(kind="white_plum",party: Array=[]):
	var p=natural_party.duplicate(true) if party.is_empty() else party.duplicate(true)
	if kind!="basket_guard":p=p.filter(func(a):return a.id==H)
	return Session.new(rules,runtime,data.encounters["enc_ch06_"+kind],p,"test")
func run():
	var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
	var source="res://../output/cache/chapter_five_gui/manual_natural_final.json"
	check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","frozen natural ch5 restore")
	natural_party=c.current_chapter_runtime().combat_party()
	check(natural_party.size()==2,"actual ch5 H/A only")
	for kind in ["white_plum","tutuha_spar","basket_guard"]:
		var s=make(kind)
		check(s.engine.entry_error=="","valid natural entry")
		for actor in s.engine.state.actors:
			if actor.team=="party":check(actor.mp==actor.max_mp,"independent entry source MP ratio1")
		var driver=Driver.new(check);driver.run(s)
		check(s.engine.state.outcome=="victory","natural end party route "+kind)
		check(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),"JSON exact replay "+kind)
		check(not Session.replay_receipt(s.receipt(),rules,runtime,s.encounter,s.initial_party).is_empty(),"receipt replay "+kind)
		var proof=s.receipt();proof.objective_evidence["success"]=true
		check(Session.replay_receipt(proof,rules,runtime,s.encounter,s.initial_party).is_empty(),"forged success rejected")
		print("CH06 NATURAL ",kind," end ",s.engine.actor_by_id(H).hp,"/",s.engine.actor_by_id(H).mp)
		var before=s.snapshot();var bad=s.snapshot();bad.state.actors[0].hp+=1
		check(not s.restore(bad) and Compare.equivalent(before,s.snapshot()),"tamper atomic")
	var low=natural_party.duplicate(true);low[0].hp=1;low[0].mp=0
	var s=make("white_plum",low)
	var first=s.snapshot()
	var d=Driver.new(check);d.run(s)
	check(s.engine.state.outcome=="victory" and s.engine.actor_by_id(H).hp==1,"synthetic 1HP boundary, no damage/refill")
	s.retry();check(Compare.equivalent(first,s.snapshot()),"retry immutable entrance exact")
	var before=s.snapshot()
	for bad in [{"success":true},{"actor_id":H,"action_id":"gua","value":true},{"actor_id":H,"action_id":"step","value":[]},{"actor_id":A,"action_id":"gua","value":"qian_li"},{"actor_id":H,"action_id":"step","value":"qian","revision":true}]:
		check(not s.apply_input(bad).accepted and Compare.equivalent(before,s.snapshot()),"bad input atomic")
	d.input(s,H,"gua","kun_zhen");d.input(s,H,"step","qian");d.command(s,H,"normal_attack","gongyang_plum");d.resolve(s)
	check(s.engine.state.outcome=="defeat" and s.engine.actor_by_id(H).hp==1,"wrong gua fails without injury")
	s.retry();check(Compare.equivalent(first,s.snapshot()),"failed attempt retry exact")
	low[0].hp=0;s=make("white_plum",low)
	check(s.engine.entry_error!="" and not s.resolve_round() and s.receipt().is_empty(),"dead entry denied")
	print("CH06 combat ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
