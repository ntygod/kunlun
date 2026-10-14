extends RefCounted
## Test-only legal commands. It never modifies the session or constructs a success proof.
static func next_input(session: RefCounted,method: String="body") -> Dictionary:
	var s:Dictionary=session.state
	if s.complete:return {}
	if s.retreating:return {"type":"wait"}
	var target:String=session._target_anchor()
	if session.puzzle_id=="rescue_ch08_l04":
		if s.observed.size()==3 and s.method=="":return {"type":"method","value":"B" if method in ["sand","B"] else "A"}
		if s.method=="B" and not s.pad_assigned:return {"type":"pad"}
		if s.supporting and s.rescued.size()==2:return {"type":"cancel_support"}
	var at:Vector2=session._p(s.position)
	var destination:Vector2=session._p(session._anchor(target))
	if at!=destination:
		var next:Vector2=session._path_step(at,destination)
		if next==at:return {}
		var delta:Vector2=(next-at)/16
		return {"type":"move","dx":int(delta.x),"dy":int(delta.y)}
	if session.puzzle_id=="route_ch08_hanshui":return {"type":"interact"}
	if session.puzzle_id=="repair_ch08_ballista":
		if target=="winch" or target not in s.observed:return {"type":"interact"}
		return {"type":"fit","part":{"rivet":"square","groove":"long","wheel":"round"}[target]}
	if s.observed.size()<3:return {"type":"interact"}
	if s.method=="A" and not s.supporting and s.rescued.size()<2:return {"type":"support"}
	if s.method=="B":
		if not s.fire_out:return {"type":"extinguish" if s.sand else "sand"}
		if not s.stone_open:return {"type":"open_stone"}
	if s.rescued.size()<2:return {"type":"interact"}
	if not session._all_departed():
		var spear:bool=target=="spear_intercept"
		var id:String="npc_ch08_looter_spear" if spear else "npc_ch08_looter_sabre"
		if not s.looters[id].observed:return {"type":"interact"}
		if not s.looters[id].disarmed:return {"type":"disarm","move":"redirect_spear" if spear else "lower_sabre"}
		return {"type":"wait"}
	if not s.escorting:return {"type":"escort"}
	if not session._at_shelter():return {"type":"wait"}
	if not s.sheltered:return {"type":"shelter"}
	if not s.talked:return {"type":"talk"}
	return {"type":"finish"}
