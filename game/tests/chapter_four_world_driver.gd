class_name ChapterFourWorldDriver
extends RefCounted
## QA driver returns one legal intent; callers MUST submit through runtime.puzzle_input.
## Never sets player/controller state or teleports to anchors.
const MAP_PATH := "res://data/maps/chapter_four_maps.json"
static func next_input(view: Dictionary) -> Dictionary:
	var s: Dictionary = view.get("world_state",{})
	if s.is_empty() or s.get("complete",false): return {}
	if s.get("captured",false): return {"type":"retry"}
	var id: String = view.id
	var anchor: String = s.target_anchor
	if id == "gate_encounter_verified" and s.approaches<2: anchor = "gate_guard"
	var pos := Vector2(s.player_position[0],s.player_position[1])
	var target := Vector2(s.anchors[anchor][0],s.anchors[anchor][1])
	if pos.distance_to(target)>8:
		return _move(s.map_id,pos,target)
	if id == "gate_encounter_verified" and s.approaches<2:
		return {"type":"inspect"} if not s.observed else {"type":"guard"}
	if id == "horse_call_and_arrival" and s.horse_called and not s.horse_arrived: return {"type":"wait"}
	if id == "horse_release_verified" and Vector2(s.horse_position[0],s.horse_position[1]).distance_to(pos)>8: return {"type":"wait"}
	if id == "bell_response_verified" and anchor.begins_with("inscription"): return {"type":"choose_fragment","value":s.fragments.size()}
	return {"type":"interact"}
static func _move(map_id: String,start: Vector2,target: Vector2) -> Dictionary:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)).maps[map_id]
	var q: Array = [start]; var prev := {start:start}; var n := 0
	while n<q.size():
		var p: Vector2=q[n];n+=1
		if p.distance_to(target)<=8:
			while prev[p] != start: p=prev[p]
			var delta: Vector2=p-start
			return {"type":"move","dx":int(signf(delta.x)) if absf(delta.x)>absf(delta.y) else 0,"dy":int(signf(delta.y)) if absf(delta.y)>=absf(delta.x) else 0}
		for d in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
			var next := Vector2(int(p.x+d.x*16),int(p.y+d.y*16))
			if not prev.has(next) and _walkable(layout,next): prev[next]=p;q.append(next)
	return {}
static func _walkable(layout: Dictionary,p: Vector2) -> bool:
	var b: Array=layout.walk_bounds
	if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]: return false
	for r in layout.solids:
		if Rect2(r[0]-8,r[1]-4,r[2]+16,r[3]+8).has_point(p):return false
	return true
