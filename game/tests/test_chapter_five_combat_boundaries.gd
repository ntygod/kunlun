extends SceneTree
const Session = preload("res://scripts/combat/chapter_five_encounter.gd")
const Driver = preload("res://tests/chapter_five_battle_driver.gd")
const UI = preload("res://scripts/ui/chapter_five_battle_panel.gd")
const Growth = preload("res://scripts/campaign/progression.gd")
const H := "char_liang_xiao"
const L := "char_liu_yingying"
const Y := "char_yun_shu"
var checks:=0
var failures:=0
var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_five_encounters.json"))
func _initialize():call_deferred("run")
func check(ok:bool,msg:String):
	checks+=1
	if not ok:failures+=1;push_error(msg)
func json(v):return JSON.parse_string(JSON.stringify(v))
func make(b="b02"):
	# Fixed synthetic panels below are exclusively unit fixtures, not playability evidence.
	var h={"id":H,"name":"梁萧","team":"party","max_hp":1000,"hp":1000,"max_mp":100,"atk":160,"def":70,"spd":45,"skills":["normal_attack","observe","self_guard","guard_ally","sancai_counter"]}
	var l={"id":L,"name":"柳莺莺","team":"party","max_hp":1000,"hp":1000,"max_mp":100,"atk":140,"def":60,"spd":50,"skills":["normal_attack","LYY_A01","LYY_A02","LYY_A03","self_guard","guard_ally"]}
	return Session.new(rules,runtime,data.encounters["enc_ch05_mechanism_yun_shu" if b=="b02" else "enc_ch05_leigong_escape"],[h,l],"boundary")
func round_guard(s):
	check(s.set_command(H,"self_guard",H)=="","guardH")
	check(s.set_command(L,"self_guard",L)=="","guardL")
	check(s.resolve_round(),"resolve")
func event_count(s,kind):
	return s.engine.state.events.filter(func(e):return e.type==kind).size()
func run():
	var s=make()
	check(s.set_command(H,"CO_01",Y)=="combo_unavailable","trial unavailable r1")
	for input in [{},{"actor_id":H,"action_id":"solved"},{"actor_id":H,"action_id":"board_boat"},{"actor_id":H,"action_id":"turn_helm","solved":true},{"actor_id":H,"action_id":"turn_helm","target":Y},{"actor_id":H,"action_id":"turn_helm","revision":999},{"actor_id":L,"action_id":"path_read"}]:
		var snap=s.snapshot();check(not s.apply_input(input).accepted,"bad input rejected");check(s.snapshot()==snap,"bad input atomic")
	check(s.receipt().is_empty(),"no forged win receipt")
	round_guard(s)
	check(s.engine.state.objective.trial and s.engine.state.objective.cooperation==2,"r2 trial and topup")
	check(s.set_command(H,"CO_01",Y)=="","reserve combo")
	check(s.can_resolve() and s.engine.state.commands.size()==2,"combo owns both actions")
	check(s.engine.state.objective.cooperation==0 and s.engine.state.objective.reserved==2,"reserved resource")
	check(s.restore(json(s.snapshot())),"reserved JSON replay")
	s.engine._gain_cooperation("test");s.engine._gain_cooperation("test")
	check(s.engine.state.objective.cooperation==1,"reservation capacity and per-round cap")
	check(s.set_command(L,"self_guard",L)=="","replace combo")
	check(s.engine.state.objective.cooperation==3 and s.engine.state.objective.reserved==0,"refund at capacity")
	check(not s.can_resolve(),"cancel clears both slots")
	s.engine._refund_combo(true)
	check(event_count(s,"combo_refund")==1,"refund once")
	s=make();round_guard(s);s.set_command(H,"CO_01",Y)
	s.engine.actor_by_id(L).statuses.append({"kind":"stun","value":1,"starts":2,"expires":2})
	s.engine._execute_combo(Y)
	check(s.engine.state.objective.reserved==0 and s.engine.state.objective.cooperation==2,"controlled partner cancels")
	check(s.engine.actor_by_id(H).stance.kind=="self_guard","survivor guard from cancellation")
	check(s.engine.actor_by_id(L).stance.is_empty(),"controlled partner receives no fallback guard")
	check(event_count(s,"combo_executed")==0,"cancel no attack")
	s=make();round_guard(s);s.set_command(H,"CO_01",Y)
	var before_coop=s.engine.state.objective.cooperation
	check(s.resolve_round(),"combo resolve")
	check(s.engine.state.objective.cooperation==before_coop,"combo no cooperation reward")
	check(event_count(s,"combo_executed")==1,"one combo execution")
	check(s.engine.state.objective.cable_cut,"actual combo cuts cable")
	check(s.restore(json(s.snapshot())),"combo result JSON replay")
	var bad=json(s.snapshot());bad.state.objective.cooperation=3
	var live=s.snapshot();check(not s.restore(bad),"fake coop rejected");check(s.snapshot()==live,"restore atomic")
	s=make();s.engine.actor_by_id(H).atk=99999;s.engine.actor_by_id(L).atk=99999
	s.set_command(H,"normal_attack",Y);s.set_command(L,"normal_attack",Y);s.resolve_round()
	check(s.engine.state.objective.phase==2 and s.engine.state.objective.trial,"high damage first round trial fallback")
	check(s.engine.actor_by_id(Y).hp==1800 and s.engine.actor_by_id(Y).mp==140,"phase HP pool but no MP refill")
	check(s.engine.state.objective.cooperation==2,"fallback trial once")
	s=make();Driver.new(check).b02(s)
	check(s.engine.state.outcome=="victory","synthetic objective route")
	check(s.engine.actor_by_id(Y).hp>0,"nonkill YUN")
	check(s.checkpoint_history_size>0,"phase checkpoint recorded")
	var proof=s.receipt();check(not Session.replay_receipt(json(proof),rules,runtime,s.encounter,s.initial_party).is_empty(),"receipt replay")
	for key in ["result","attempt_id","initial_party","commands","final_actors","objective_evidence","events"]:
		var forged=json(proof);forged[key]={}
		check(Session.replay_receipt(forged,rules,runtime,s.encounter,s.initial_party).is_empty(),"receipt field rejected "+key)
	var phase_snapshot=s.snapshot();s.retry()
	check(s.engine.state.objective.phase==2 and s.engine.state.outcome=="","retry phase checkpoint")
	check(s.history.size()==s.checkpoint_history_size,"retry exact prefix")
	check(s.restore(json(s.snapshot())),"retry JSON")
	s=make("b03")
	check(s.engine.actor_by_id(H).max_mp==0 and s.engine.actor_by_id(H).mp==0,"B03 new fight no MP reset bypass")
	check(s.set_command(H,"normal_attack","lei_xingkong")=="story_restricted","B03 no normal attack")
	check(s.set_command(H,"CO_01","lei_xingkong")=="combo_unavailable","B03 combo prohibited")
	check(not s.apply_input({"actor_id":H,"action_id":"mark_gate","target":"gate_east"}).accepted,"gate premature")
	Driver.new(check).b03(s)
	check(s.engine.state.outcome=="victory" and s.engine.state.round==5,"B03 four rounds")
	check(s.engine.actor_by_id("lei_xingkong").hp==1600 and s.engine.actor_by_id("lei_zhen").hp==900,"no boss HP requirement")
	check(s.engine.actor_by_id(H).mp==0,"B03 zero MP throughout")
	check(s.restore(json(s.snapshot())),"B03 JSON replay")
	var raw_sum:=0.0
	for e in s.engine.state.events:
		if e.type=="damage" and e.round==2 and str(e.detail.action_id).begins_with("lei_xingkong"):
			raw_sum+=float(e.detail.raw)
	check(is_equal_approx(raw_sum,300),"hammer raw split sums exactly300")
	s=make("b03");round_guard(s);round_guard(s)
	check(s.engine.state.outcome=="defeat","missing path cannot progress")
	s=make();round_guard(s);s.engine.actor_by_id(H).statuses.append({"kind":"bleed","value":1000,"source":Y,"starts":3,"expires":3});round_guard(s)
	check(s.engine.state.outcome=="defeat" and s.engine.state.mode=="finished","start-round DOT defeat finalizes")
	s=make();round_guard(s);s.engine.actor_by_id(L).controllable=false
	var previous=s.snapshot();check(s.set_command(H,"CO_01",Y)=="combo_unavailable","noncontrollable partner cannot combo");check(previous==s.snapshot(),"combo rejection atomic")
	s=make();check(s.apply_input({"actor_id":H,"action_id":"turn_helm"}).accepted,"helm pending")
	s.engine.actor_by_id(H).controllable=false;previous=s.snapshot()
	check(not s.apply_input({"actor_id":H,"action_id":"turn_helm"}).accepted,"noncontrollable objective rejected");check(previous==s.snapshot(),"rejected objective preserves pending")
	for helm in [false,true]:
		s=make();round_guard(s);round_guard(s)
		if helm: check(s.apply_input({"actor_id":H,"action_id":"turn_helm"}).accepted,"helm with A03")
		else: check(s.set_command(H,"self_guard",H)=="","no helm guard")
		check(s.set_command(L,"LYY_A03",Y)=="","A03 armor window");check(s.resolve_round(),"armor resolve")
		check(event_count(s,"armor")== (0 if helm else 1),"A03 armor requires actual same-round helm")
	s=make();s.engine.actor_by_id(L).skills.append("LYY_A04")
	check(s.set_command(H,"self_guard",H)=="","ice companion guard")
	check(s.set_command(L,"LYY_A04","swordsman_1")=="","A04 owned command");check(s.resolve_round(),"ice resolve")
	var sword=s.engine.actor_by_id("swordsman_1")
	check(s.engine._status_value(sword,"a04_speed_down")==0.25,"ice next-round speed25")
	check(s.engine._status_value(sword,"mana_cost_up")==0.5,"ordinary enemy mana50")
	check(s.engine.skill_cost(sword,{"mp_floor":10})==15,"ordinary cost multiplier")
	check(s.set_command(L,"LYY_A04",Y)=="cooldown","ice CD1 means unavailable T+1")
	check(sword.statuses.filter(func(e):return e.kind=="a04_speed_down")[0].expires==3,"ice lasts T+1 and T+2")
	s=make();s.engine.actor_by_id(L).skills.append("LYY_A04");s.set_command(H,"self_guard",H);s.set_command(L,"LYY_A04",Y);s.resolve_round()
	check(s.engine._status_value(s.engine.actor_by_id(Y),"mana_cost_up")==0,"boss no ordinary MP cost debuff")
	# Render and release all resources at three supported sizes.
	for dimensions in [Vector2i(1280,720),Vector2i(640,360),Vector2i(639,359)]:
		root.size=dimensions
		s=make();var host=VBoxContainer.new();root.add_child(host)
		var panel=UI.new();host.add_child(panel);panel.render(s.get_view(),s.engine.content.skills,s.can_resolve())
		await process_frame
		check(panel.slots.has(H+"_slot")==false and panel.slots.has(H+"_skills") and panel.slots.has(L+"_skills"),"two permanent actor control slots")
		check(panel.intent_text.autowrap_mode!=TextServer.AUTOWRAP_OFF,"intent wrap")
		check(panel.slots[H+"_targets"].item_count==5,"all real actors target list")
		panel.show_details();await process_frame;panel.details.hide();host.queue_free();await process_frame
	print("CH05 boundaries ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
