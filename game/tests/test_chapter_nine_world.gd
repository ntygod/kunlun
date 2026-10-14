extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_nine_world_actions.gd")
var failures:=0
var checks:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)
func context(id: String) -> Dictionary:
	var names:Dictionary={"scene_ch09_three_masters":["ch09_shigong_confrontation","shigong_platform"],"scene_ch09_four_instruments":["ch09_mountain_pursuit","pine_terrace"],"rescue_ch09_l05":["L05","west_temple"]}
	return {"chapter":9,"current_token":"chapter9:test:1","revision":1,"scene_id":names[id][0],"phase":names[id][0],"map_id":"map_ch09_"+names[id][1],"control_actor_id":"char_liang_xiao","objective_id":id,"world_objects":{},"items":{},"actors":{},"choices":{},"inherited_choices":{},"knowledge":[]}
func route(m: RefCounted,target: Vector2) -> Array:
	var start:Vector2=m._p(m.state.position);var q:Array=[start];var prior:Dictionary={start:start};var idx:=0
	while idx<q.size():
		var p:Vector2=q[idx];idx+=1
		if p==target:
			var path:Array=[]
			while p!=start:path.push_front(p);p=prior[p]
			return path
		for dir in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var n:Vector2=p+dir*16;var blocked:=false
			for id in m.state.looters:
				if not m.state.looters[id].departed and m._p(m.state.actor_positions[id])==n:blocked=true
			if not prior.has(n) and m.is_walkable(n) and not blocked:prior[n]=p;q.append(n)
	return []
func go(m: RefCounted,anchor: String) -> void:
	var path:=route(m,m._p(m._anchor(anchor)))
	for next in path:
		var d:Vector2=(next-m._p(m.state.position))/16
		check(m.apply_input({"type":"move","dx":int(d.x),"dy":int(d.y)}).ok,"walk "+anchor)
	check(m._near(anchor),"arrived "+anchor)
func act(m: RefCounted,action: Dictionary) -> void:check(m.apply_input(action).ok,"input "+str(action))
func save_check(m: RefCounted) -> void:
	var other=Model.new();var bytes:String=JSON.stringify(m.snapshot());var parsed:Dictionary=JSON.parse_string(bytes)
	check(other.restore(parsed,context(m.puzzle_id)),"JSON mid-route restore")
	check(Model._encoded(other.snapshot())==Model._encoded(m.snapshot()),"exact NPC/history restore")
	var before:String=Model._encoded(other.snapshot());var bad:Dictionary=m.snapshot();bad.state.complete=not bad.state.complete
	check(not other.restore(bad,context(m.puzzle_id)),"fake completion rejected")
	check(Model._encoded(other.snapshot())==before,"failed restore atomic")
func reject(m: RefCounted,action: Dictionary,label: String) -> void:
	var before:String=Model._encoded(m.snapshot())
	check(not m.apply_input(action).ok,label)
	check(Model._encoded(m.snapshot())==before,label+" atomic")
func rescue(method: String) -> RefCounted:
	var m=Model.new();check(m.begin("rescue_ch09_l05","test",context("rescue_ch09_l05")),"begin L05 "+method)
	reject(m,{"type":"finish"},"no remote completion")
	act(m,{"type":"interact"});go(m,"box");act(m,{"type":"interact"})
	reject(m,{"type":"unlock"},"wrong lock rejected")
	for i in range(3):act(m,{"type":"lock","slot":i,"symbol":["leaf","flower","fruit"][i]})
	act(m,{"type":"unlock"});act(m,{"type":"method","value":method});save_check(m)
	if method=="A":
		reject(m,{"type":"return_box"},"doctor not teleported")
		go(m,"wounded");act(m,{"type":"interact"});go(m,"physician");act(m,{"type":"interact"});act(m,{"type":"escort"})
		go(m,"decoy");save_check(m);go(m,"box")
		for i in range(100):
			if m._p(m.state.actor_positions.npc_ch09_physician)==m._p(m._anchor("doctor_station")):break
			act(m,{"type":"wait"})
		act(m,{"type":"return_box"});check(m.state.returned_box,"A actual doctor returned")
	else:
		reject(m,{"type":"sort","label":"leaf"},"Liang cannot impersonate snow")
		act(m,{"type":"switch"});go(m,"sort")
		for label in ["leaf","flower","fruit"]:act(m,{"type":"sort","label":label})
		reject(m,{"type":"sort","label":"fruit"},"cannot duplicate medicine")
		act(m,{"type":"switch"});go(m,"decoy");act(m,{"type":"decoy"});save_check(m)
		go(m,"patrol_lure");act(m,{"type":"lure"})
		check(not m.state.patrol_departed,"patrol cannot disappear remotely")
		go(m,"box")
		for i in range(100):
			if m.state.patrol_departed:break
			act(m,{"type":"wait"})
		act(m,{"type":"distribute"});check(not m.state.found_physician and not m.state.returned_box,"B never claims rescued doctor")
	for i in range(1,4):
		reject(m,{"type":"disarm"},"no remote disarm")
		go(m,"raider_%d_observe"%i);act(m,{"type":"interact"});go(m,"raider_%d_flank"%i);act(m,{"type":"disarm"})
		check(not m.state.looters["npc_ch09_raider_%d"%i].departed,"raider not instantly removed")
		if i==2:save_check(m)
	for i in range(100):
		if m._all_departed():break
		act(m,{"type":"wait"})
	go(m,"box");act(m,{"type":"treat"});go(m,"aftermath");act(m,{"type":"talk"});act(m,{"type":"finish"})
	check(m.state.complete,"L05 complete "+method)
	check(not Model.replay_receipt(m.receipt(),context(m.puzzle_id)).is_empty(),"proof exact replay "+method)
	reject(m,{"type":"finish"},"no repeated archive")
	for id in m.state.actor_paths:
		var path:Array=m.state.actor_paths[id]
		for j in range(1,path.size()):
			var d:Vector2=m._p(path[j])-m._p(path[j-1]);check(absf(d.x)+absf(d.y)==16,"NPC actual four-neighbour path "+id)
	for receipt in ["side_ch09_l05_accept","side_ch09_l05_inspect_box","side_ch09_l05_unlock_box","side_ch09_l05_disarm_raiders","side_ch09_l05_finish_treatment","side_ch09_l05_aftermath","side_ch09_l05_archive"]:check(receipt in m.state.stage_receipts,"contract stage "+receipt)
	check(m.get_view().world_state.medicine_owner==("npc_ch09_physician" if method=="A" else "npc_ch09_xixizi"),"medical ownership unchanged")
	return m
func maps_check() -> void:
	var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Model.MAP_PATH)).maps
	check(maps.size()==8,"eight semantic maps")
	for mid in maps:
		var layout:Dictionary=maps[mid];var m=Model.new();m.layout=layout;m.state={"position":layout.spawn,"looters":{}}
		for anchor in layout.anchors:
			check(m.is_walkable(m._p(layout.anchors[anchor])),"anchor physical collision clear "+mid+":"+anchor)
			check(layout.anchors[anchor]==layout.spawn or not route(m,m._p(layout.anchors[anchor])).is_empty(),"BFS anchor connected "+mid+":"+anchor)
		for action in layout.actions:
			check(m.is_walkable(m._p(layout.actions[action].position)),"objective physical clear "+action)
			check(layout.actions[action].position==layout.spawn or not route(m,m._p(layout.actions[action].position)).is_empty(),"BFS objective connected "+action)
func _initialize() -> void:
	maps_check()
	for id in ["scene_ch09_three_masters","scene_ch09_four_instruments"]:
		var m=Model.new();check(m.begin(id,"test",context(id)),"begin interactive scene")
		reject(m,{"type":"interact"},"no remote scene completion")
		for step in m.config.steps:go(m,step.anchor);act(m,{"type":"interact"});save_check(m)
		check(m.state.complete and not Model.replay_receipt(m.receipt(),context(id)).is_empty(),"scene completion proof")
	var a=rescue("A");rescue("B")
	for bad in [{"type":"move","dx":true,"dy":0},{"type":"move","dx":INF,"dy":0},{"type":"lock","slot":true,"symbol":"leaf"},{"type":"sync","state":{"complete":true}},{"type":"finish","reward":300}]:reject(a,bad,"malformed input")
	var before:String=Model._encoded(a.snapshot());var bad_context:=context("rescue_ch09_l05");bad_context.revision=NAN
	check(not a.begin("rescue_ch09_l05","test",bad_context),"NaN context rejected")
	check(Model._encoded(a.snapshot())==before,"failed begin atomic")
	print("CH09 WORLD: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
