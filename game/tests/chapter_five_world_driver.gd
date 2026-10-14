extends RefCounted
## Returns a single legal input. Main must submit it through runtime chronology.
static func next_input(view: Dictionary) -> Dictionary:
	if view.get("state",{}).get("complete",false):return {}
	if view.state.get("captured",false):return {"type":"retry"}
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_five_maps.json"))
	var m: Dictionary=data.maps[view.world_state.map_id]
	var start:=Vector2(view.world_state.player_position[0],view.world_state.player_position[1])
	var raw: Array=view.world_state.get("target_position",m.anchors[view.world_state.target_anchor])
	var target:=Vector2(raw[0],raw[1])
	if start==target:return {"type":"interact"}
	var q:Array=[start];var prev:Dictionary={start:start};var index:=0
	while index<q.size():
		var p:Vector2=q[index];index+=1
		if p==target:
			while prev[p]!=start:p=prev[p]
			var delta:Vector2=(p-start)/16
			return {"type":"move","dx":int(delta.x),"dy":int(delta.y)}
		for d in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var n:Vector2=p+d*16
			var b:Array=m.walk_bounds
			if n.x<b[0] or n.y<b[1] or n.x>b[0]+b[2] or n.y>b[1]+b[3] or prev.has(n):continue
			var blocked:=false
			for r in m.solids+m.get("deep_water_rects",[]):
				if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(n):blocked=true;break
			if not blocked:prev[n]=p;q.append(n)
	return {}

static func preview_context(id: String) -> Dictionary:
	# Development preview creates prerequisites by legal inputs, never state mutation.
	var needed: String={"axue_capture_verified":"small_hat_dropped_verified","small_hat_recovered_verified":"small_hat_dropped_verified","pool_escape_verified":"axue_escape_verified","cave_refuge_verified":"pool_escape_verified"}.get(id,"")
	if needed.is_empty():return {}
	var c=load("res://scripts/world_actions/chapter_five_world_actions.gd").new()
	if not c.begin(needed,"preview_prerequisite",preview_context(needed)):return {}
	for i in range(160):
		if c.state.complete:break
		if not c.apply_input(next_input(c.get_view())).get("ok",false):return {}
	if not c.state.complete:return {}
	var result:Dictionary={"world_objects":{"ch05_spatial_state":c.receipt().world_state}}
	if id=="small_hat_recovered_verified":
		result.items={"item_ch04_small_willow_hat":{"owner":"ch05_thorn_hat","state":"placed","location":c.map_id,"position":c.receipt().world_state.hat_position}}
	return result
