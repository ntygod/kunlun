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
		var trusted:Dictionary={"items":{"item_ch04_small_willow_hat":{"owner":"ch05_thorn_hat","state":"placed","location":"map_ch05_tree_hollow","position":[352,240]}}} if id=="small_hat_recovered_verified" else {}
		if id=="axue_capture_verified":
			var dropped=C.new();dropped.begin("small_hat_dropped_verified","prior",{});dropped.apply_input({"type":"interact"})
			trusted={"world_objects":{"ch05_spatial_state":dropped.receipt().world_state}}
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
		w.queue_free()
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
	var no_prior=C.new();check(not no_prior.begin("axue_capture_verified","invalid",{}),"capture requires genuine previous actor position")
	var missing_hat=C.new();missing_hat.begin("small_hat_recovered_verified","missing",{})
	for i in range(30):
		var action:Dictionary=D.next_input(missing_hat.get_view())
		if action.type=="interact":break
		missing_hat.apply_input(action)
	check(not missing_hat.apply_input({"type":"interact"}).ok,"no hat materialized from missing object")
	var patrol=C.new();patrol.begin("leigong_infiltration_verified","capture",{})
	var starting_hash:String=patrol._hash_state()
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
