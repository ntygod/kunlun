extends RefCounted
## Test-only controller: submits the same legal single-cell commands as the player.
static func next_input(m: RefCounted,method: String="A") -> Dictionary:
	if m.state.complete:return {}
	if m.puzzle_id!="rescue_ch09_l05":return toward(m,m._target_anchor(),{"type":"interact"})
	var s:Dictionary=m.state
	if not s.accepted:return toward(m,"entry",{"type":"interact"})
	if not s.inspected:return toward(m,"box",{"type":"interact"})
	if not s.unlocked:
		for i in range(3):
			if s.lock_slots[i]!=["leaf","flower","fruit"][i]:return toward(m,"box",{"type":"lock","slot":i,"symbol":["leaf","flower","fruit"][i]})
		return toward(m,"box",{"type":"unlock"})
	if s.method=="":return toward(m,"box",{"type":"method","value":method})
	if s.method=="A" and not s.returned_box:
		if not s.questioned:return toward(m,"wounded",{"type":"interact"})
		if not s.found_physician:return toward(m,"physician",{"type":"interact"})
		if not s.escorting:return toward(m,"physician",{"type":"escort"})
		if not m._near("box"):return toward(m,"box",{})
		return {"type":"return_box"} if m._p(s.actor_positions.npc_ch09_physician)==m._p(m._anchor("doctor_station")) else {"type":"wait"}
	if s.method=="B" and not s.distributed:
		if s.sorted.size()<3:
			if s.control_actor_id!=m.A:return {"type":"switch"}
			for label in ["leaf","flower","fruit"]:
				if label not in s.sorted:return toward(m,"sort",{"type":"sort","label":label})
		if s.control_actor_id!=m.H:return {"type":"switch"}
		if not s.decoys:return toward(m,"decoy",{"type":"decoy"})
		if not s.patrol_lured:return toward(m,"patrol_lure",{"type":"lure"})
		if not s.patrol_departed:return {"type":"wait"}
		return toward(m,"box",{"type":"distribute"})
	for raider in s.looters.values():
		if raider.departed:continue
		if raider.disarmed:return {"type":"wait"}
		if not raider.observed:return toward(m,"raider_%d_observe"%raider.index,{"type":"interact"})
		return toward(m,"raider_%d_flank"%raider.index,{"type":"disarm"})
	if not s.treated:return toward(m,"box",{"type":"treat"})
	if not s.talked:return toward(m,"aftermath",{"type":"talk"})
	return toward(m,"aftermath",{"type":"finish"})
static func toward(m: RefCounted,anchor: String,at_target: Dictionary) -> Dictionary:
	var start:Vector2=m._p(m.state.position);var target:Vector2=m._p(m._anchor(anchor))
	if start==target:return at_target
	var q:Array=[start];var previous:Dictionary={start:start};var index:=0
	while index<q.size():
		var at:Vector2=q[index];index+=1
		if at==target:
			while previous[at]!=start:at=previous[at]
			var delta:Vector2=(at-start)/16
			return {"type":"move","dx":int(delta.x),"dy":int(delta.y)}
		for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next:Vector2=at+direction*16;var blocked:=false
			for id in m.state.looters:
				if not m.state.looters[id].departed and m._p(m.state.actor_positions[id])==next:blocked=true
			if m.is_walkable(next) and not blocked and not previous.has(next):previous[next]=at;q.append(next)
	return {}
