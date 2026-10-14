extends SceneTree
const C=preload("res://scripts/world_actions/chapter_five_world_actions.gd")
const D=preload("res://tests/chapter_five_world_driver.gd")
const W=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	for id in C.IDS:
		var trusted:Dictionary=D.preview_context(id)
		var c=C.new();check(c.begin(id,"test",trusted),id+" begin")
		check(not c.apply_input({"type":"interact","success":true}).get("ok",true),"reject success")
		check(not c.apply_input({"type":"move","dx":1,"dy":0,"position":[80,240]}).get("ok",true),"reject arbitrary position")
		for i in range(100):
			if c.state.complete:break
			var action:Dictionary=D.next_input(c.get_view())
			check(not action.is_empty(),id+" reachable target")
			check(c.apply_input(action).get("ok",false),id+" real step or E")
			if i%5==0:
				var restored=C.new()
				check(restored.restore(JSON.parse_string(JSON.stringify(c.snapshot())),c.context),id+" mid session JSON replay")
				check(restored._hash_state()==c._hash_state(),"no state drift")
		check(c.state.complete,id+" complete")
		if id=="leigong_infiltration_verified":check(c._p(c.state.actor_positions.char_liang_xiao)==c._p(c.state.position) and c.state.gate_unlatched,"Liang joins at actual opened gate before control transfer")
		if id in ["canal_rescue_verified","chuxianliu_rescue_verified"]:
			var guest: String="npc_bayan" if id=="canal_rescue_verified" else "npc_chu_xianliu"
			check(c._p(c.state.actor_positions[guest]).distance_to(c._p(c.state.position))<=24,"same rescued guest physically arrives")
		check(not C.replay_receipt(c.receipt(),c.context).is_empty(),id+" valid receipt")
		if not c.state.complete:continue
		var forged:Dictionary=c.receipt().duplicate(true);forged.world_state.player_position=[48,48]
		check(C.replay_receipt(forged,c.context).is_empty(),"reject final position forgery")
		var bad:Dictionary=c.snapshot().duplicate(true);bad.input_log.append({"type":"success"})
		check(not C.new().restore(bad,c.context),"reject ignored appended command")
		var w=W.new();root.add_child(w)
		w.configure({"id":"preview","map_id":c.map_id},Vector2.INF,{})
		w.sync_controlled_view(c.get_view())
		check(w.player.actor_id==c.config.control_actor_id,"canonical control actor")
		check(w.player.position==c._p(c.state.position),"world renders verified position")
		if id=="chuxianliu_rescue_verified":check(not w.cast_actors.npc_chu_xianliu.resting and c.state.actor_postures.npc_chu_xianliu=="guarding","Chu remains standing rescuer providing cover")
		if id=="wulong_hide_verified":
			check(w.cast_actors.char_liang_xiao.resting and w.cast_actors.char_liang_xiao.screened,"laid down Liang rests visibly behind leaves")
		if id=="small_hat_recovered_verified":check(w.player.visual.small_hat_visible,"same recovered small hat visible apart from back hat")
		if id=="cave_refuge_verified":check(w.cast_actors.char_axue.resting,"Axue rests on dry ledge")
		if id=="small_hat_dropped_verified":check(w.player.visual.resting,"limited injured Liang no standing sword pose")
		check(c.get_view().body.find(c._next_anchor())==-1,"HUD translates current anchor")
		if id=="wulong_hide_verified":
			w.configure({"id":"post_dialogue","map_id":c.map_id},c._p(c.state.position),{"controller_id":"char_liu_yingying","present_actor_ids":["char_liang_xiao"],"world_objects":{"ch05_spatial_state":c.receipt().world_state}})
			check(w.cast_actors.char_liang_xiao.resting and w.cast_actors.char_liang_xiao.screened,"resting pose survives controlled exit and dialogue redraw")
		w.queue_free()
	var gate_join=C.new();gate_join.begin("leigong_infiltration_verified","gate_join",{})
	for i in range(40):
		if gate_join.state.stage==1 and gate_join._p(gate_join.state.position)==Vector2(320,240):break
		gate_join.apply_input(D.next_input(gate_join.get_view()))
	check(not gate_join.apply_input({"type":"move","dx":1,"dy":0}).ok,"cannot cross closed gate")
	gate_join.apply_input({"type":"wait"})
	check(gate_join._p(gate_join.state.actor_positions.char_liang_xiao)==Vector2(304,240),"Liang waits outside unopened gate")
	gate_join.apply_input({"type":"interact"})
	for i in range(40):
		if gate_join.state.complete:break
		var before:Vector2=gate_join._p(gate_join.state.actor_positions.char_liang_xiao)
		gate_join.apply_input(D.next_input(gate_join.get_view()))
		var after:Vector2=gate_join._p(gate_join.state.actor_positions.char_liang_xiao)
		check(before.distance_to(after)<=16 and gate_join.is_walkable(after),"Liang follows opened traversable path at most one cell")
	check(gate_join.state.complete,"both enter only after actual meeting")
	var leaves=C.new();leaves.begin("wulong_hide_verified","leaf_ray",{})
	check(leaves.line_visible(Vector2(192,144),Vector2(192,240)),"open hollow initially visible")
	for i in range(30):
		if leaves.state.concealed:break
		leaves.apply_input(D.next_input(leaves.get_view()))
	check(not leaves.line_visible(Vector2(192,144),Vector2(192,240)),"actual placed leaf screen clips ray")
	var chain_context := {"world_objects":{}}
	for id in ["axue_escape_verified","pool_escape_verified"]:
		var segment=C.new();check(segment.begin(id,"chain",chain_context),"continuous escape begins")
		if id=="pool_escape_verified":
			check(segment.state.carrying_pair.get("passenger_id","")=="char_axue","same injured Axue carried into pool")
		for i in range(80):
			if segment.state.complete:break
			check(segment.apply_input(D.next_input(segment.get_view())).ok,"escape real legal step")
		check(segment.state.complete,"escape segment complete")
		chain_context.world_objects.ch05_spatial_state=segment.receipt().world_state
	var bank=C.new();bank.begin("axue_escape_verified","physical_assist",{})
	check(bank._p(bank.state.actor_positions.char_axue)==Vector2(160,240),"assist target follows Axue original authored feet without relocation")
	check(not bank.apply_input({"type":"interact"}).ok,"cannot lift Axue from entry across distance")
	var positioned=C.new();positioned.begin("axue_escape_verified","inherited",{"world_objects":{"ch05_spatial_state":{"map_id":"map_ch05_pool_escape","control_actor_id":"char_liang_xiao","player_position":[80,240],"actor_positions":{"char_axue":[224,240]}}}})
	check(positioned._p(positioned._anchor("axue_bank"))==Vector2(224,240),"marker follows same-map trusted Axue position")
	check(positioned.get_view().world_state.actor_positions.char_axue==positioned.get_view().world_state.target_position,"visible body and interact target share exact source")
	var foreign=C.new();foreign.begin("axue_escape_verified","transfer",{"world_objects":{"ch05_spatial_state":{"map_id":"map_ch05_round_room","actor_positions":{"char_axue":[544,240]}}}})
	check(foreign._p(foreign._anchor("axue_bank"))==Vector2(160,240),"different-map actor coordinates are not transplanted")
	check(not C.new().begin("pool_escape_verified","missing",{}),"pool requires actual carried pair receipt")
	check(not C.new().begin("cave_refuge_verified","missing",{}),"cave requires actual pool escape receipt")
	var mismatched:Dictionary=D.preview_context("pool_escape_verified")
	mismatched.world_objects.ch05_spatial_state.actor_positions.char_axue=[80,240]
	check(not C.new().begin("pool_escape_verified","remote",mismatched),"reject passenger left behind at previous map position")
	var no_prior=C.new();check(not no_prior.begin("axue_capture_verified","invalid",{}),"capture requires genuine previous actor position")
	var missing_hat=C.new();missing_hat.begin("small_hat_recovered_verified","missing",{})
	for i in range(30):
		var action:Dictionary=D.next_input(missing_hat.get_view())
		if action.type=="interact":break
		missing_hat.apply_input(action)
	check(not missing_hat.apply_input({"type":"interact"}).ok,"no hat materialized from missing object")
	var patrol=C.new();patrol.begin("leigong_infiltration_verified","capture",{})
	var starting_hash:String=patrol._hash_state()
	for i in range(40):
		if patrol.state.gate_unlatched:break
		patrol.apply_input(D.next_input(patrol.get_view()))
	for i in range(90):
		if patrol.state.captured:break
		var view:Dictionary=patrol.get_view();view.world_state.target_position=[448,144]
		var action:Dictionary=D.next_input(view)
		if action.get("type","")=="interact":action={"type":"wait"}
		patrol.apply_input(action)
	check(patrol.state.captured,"actual movement into guard ray is discovered")
	check(not patrol.apply_input({"type":"interact"}).ok,"discovered cannot finish")
	check(patrol.apply_input({"type":"retry"}).ok and patrol._hash_state()==starting_hash,"retry restores original trusted state")
	var player=KunlunPlayer.new();player.carrying_actor_id="char_liang_xiao";player.movement_multiplier=0.7
	check(player.speed*player.movement_multiplier==45.5,"carrying modifier preserves 65 base speed")
	player.free()
	for target_id in ["pool_escape_verified","cave_refuge_verified"]:
		for mutation in ["foreign_map","wrong_control","illegal_coordinates","not_complete","wrong_stage","empty_pair"]:
			var ctx:Dictionary=D.preview_context(target_id)
			var prior:Dictionary=ctx.world_objects.ch05_spatial_state
			match mutation:
				"foreign_map":prior.map_id="map_ch05_round_room"
				"wrong_control":prior.control_actor_id="char_axue"
				"illegal_coordinates":prior.player_position=[-999,-999];prior.actor_positions.char_axue=[-999,-999]
				"not_complete":prior.complete=false
				"wrong_stage":prior.stage=0
				"empty_pair":prior.carrying_pair={}
			var existing=C.new();existing.begin("porridge_delivered_verified","preserved",{})
			var unchanged:String=C._encoded(existing.snapshot())
			check(not existing.begin(target_id,"tampered",ctx),target_id+" rejects "+mutation)
			check(C._encoded(existing.snapshot())==unchanged,"failed begin leaves existing session intact")
	for position in [[-16,240],[161,240],[224,160],[160],["bad",240],[NAN,240],[INF,240]]:
		var ctx:Dictionary={"world_objects":{"ch05_spatial_state":{"map_id":"map_ch05_pool_escape","control_actor_id":"char_liang_xiao","player_position":[80,240],"actor_positions":{"char_axue":position}}}}
		check(not C.new().begin("axue_escape_verified","bad_actor",ctx),"malformed or blocked actual NPC coordinate rejected")
	var restore_atomic=C.new();restore_atomic.begin("porridge_delivered_verified","keep",{});restore_atomic.apply_input({"type":"move","dx":1,"dy":0})
	var unchanged:String=C._encoded(restore_atomic.snapshot())
	var fake:Dictionary=restore_atomic.snapshot().duplicate(true);fake.state.position=[496,240]
	check(not restore_atomic.restore(fake,{}),"reject forged restore")
	check(C._encoded(restore_atomic.snapshot())==unchanged,"failed restore is atomic")
	var wrong=C.new();check(not wrong.begin("axue_capture_verified","wrong",{"control_actor_id":"char_liu_yingying"}),"cannot swap controlled identity")
	check(C.swept_contact(Vector2(0,0),Vector2(16,0),Vector2(16,0),Vector2(0,0)),"same beat swaps captured")
	var limited=C.new();limited.begin("small_hat_dropped_verified","limited",{})
	check(not limited.apply_input({"type":"move","dx":1,"dy":0}).ok,"injured viewpoint cannot roam")
	check(limited.get_view().world_state.visible_actor_ids==["char_liang_xiao"],"limited viewpoint excludes unseen truth actors")
	var full=C.new();full.begin("porridge_delivered_verified","full",{})
	for i in range(C.LIMIT):full.apply_input({"type":"wait"})
	check(not full.apply_input({"type":"wait"}).ok,"bounded log")
	check(full.apply_input({"type":"retry"}).ok and full.input_log.size()==1,"full log retry recoverable")
	print("CH05 WORLD: %d checks / %d failures" % [checks,failures]);quit(1 if failures else 0)
