class_name KunlunWorld
extends Node2D
const TILE := 32
var scene_data: Dictionary
var player: KunlunPlayer
var camera: Camera2D
var actors: Node2D
var interactions: Array[Dictionary] = []
var elapsed := 0.0
var map_size := Vector2(1024, 576)
var weather: Node2D
var runtime_context: Dictionary = {}
var layout: Dictionary = {}
var chapter_maps: Dictionary = {}
var path_progress: Dictionary = {}
var cast_actors: Dictionary = {}
var solid_rects: Array[Rect2] = []
var movement_trail: Array[Vector2] = []
var candidate_tiles: Texture2D
var chapter_two_maps: Dictionary = {}
var chapter_three_maps: Dictionary = {}
var chapter_four_maps: Dictionary = {}
var chapter_five_maps: Dictionary = {}
var controlled_view: Dictionary = {}
var escape_view: Dictionary = {}
const CH02_NAMES := {"梁萧":"char_liang_xiao", "花晓霜":"char_hua_xiaoshuang", "秦伯符":"char_qin_bofu", "花清渊":"char_hua_qingyuan", "花慕容":"char_hua_murong", "凌霜君":"char_ling_shuangjun", "花无媸":"char_hua_wuchi", "吴常青":"char_wu_changqing", "明归":"char_ming_gui", "明三秋":"char_ming_sanqiu", "明三叠":"char_ming_sandie", "童铸":"char_tong_zhu", "修谷":"char_xiu_gu", "叶钊":"char_ye_zhao", "杨路":"char_yang_lu", "左元":"char_zuo_yuan", "九如":"char_jiuru", "花生":"char_huasheng", "梅影":"char_mei_ying", "何嵩阳":"char_he_songyang", "脱欢":"char_toghon", "火真人":"char_huo_zhenren", "白痴儿":"follower_baichier", "金灵儿":"follower_jinlinger"}

const CH04_NAMES := {"梁萧":"char_liang_xiao","柳莺莺":"char_liu_yingying","九如":"npc_jiu_ru","楚仙流":"npc_chu_xianliu","楚婉":"npc_chu_wan","释海雨":"npc_shi_haiyu","脱欢":"npc_tuo_huan","火真人":"npc_huo_zhenren","阿滩":"npc_atan","哈里斯":"npc_halis","老周":"npc_old_zhou","胭脂":"animal_yanzhi"}

const CH05_NAMES := {"梁萧":"char_liang_xiao","柳莺莺":"char_liu_yingying","阿雪":"char_axue","云殊":"char_yun_shu","颜人白":"npc_bayan","伯颜":"npc_bayan","楚仙流":"npc_chu_xianliu","韩凝紫":"npc_han_ningzi","明归":"char_ming_gui","胭脂":"animal_yanzhi"}

func default_spawn() -> Vector2:
	return _point(layout.get("spawn", [112, 116]))

func _point(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	return Vector2(float(value[0]), float(value[1]))

func _rect(value: Array) -> Rect2:
	return Rect2(value[0], value[1], value[2], value[3])

func get_objective_geometry(action_id: String) -> Dictionary:
	var actions: Dictionary = layout.get("actions", {})
	if not actions.has(action_id):
		return {}
	var points: Array[Vector2] = []
	for p in layout.get("paths", {}).get(action_id, []):
		points.append(_point(p))
	return {"map_id": scene_data.get("map_id", ""), "position": _point(actions[action_id].position), "radius": float(actions[action_id].get("radius", 24.0)), "waypoints": points, "hazards": solid_rects.duplicate(), "cells": actions[action_id].get("cells", []), "phases": actions[action_id].get("phases", []), "geometry_only": actions[action_id].get("geometry_only", false)}

func get_path_progress(action_id: String) -> Dictionary:
	var geometry := get_objective_geometry(action_id)
	var total: int = geometry.get("waypoints", []).size()
	var index: int = clampi(int(path_progress.get(action_id, 0)), 0, total)
	return {"index": index, "total": total, "complete": total > 0 and index == total}

func _update_paths() -> void:
	if not player or not player.enabled:
		return
	for objective in runtime_context.get("active_objectives", []):
		if not objective.get("enabled", true) or objective.get("type", "interact") != "route":
			continue
		var id: String = objective.id
		var geometry := get_objective_geometry(id)
		var points: Array = geometry.get("waypoints", [])
		var index: int = int(path_progress.get(id, 0))
		if index < points.size() and player.position.distance_to(points[index]) <= 20:
			path_progress[id] = index + 1

func set_runtime_context(context: Dictionary) -> void:
	runtime_context = context.duplicate(true)
	if layout.is_empty():
		return
	for id in context.get("path_progress", {}):
		var count: int = layout.get("paths", {}).get(id, []).size()
		path_progress[id] = clampi(int(context.path_progress[id]), 0, count)
	interactions.clear()
	for objective in context.get("active_objectives", []):
		if not objective.get("enabled", true):
			continue
		var geometry := get_objective_geometry(str(objective.id))
		if geometry.is_empty():
			continue
		interactions.append({"id": objective.id, "action_id": objective.id, "name": objective.get("name", layout.actions[objective.id].name), "position": geometry.position, "main": true, "type": objective.get("type", "interact")})
	var controller: String = context.get("controller_id", scene_data.get("controller", "char_liang_xiao"))
	player.actor_id = controller
	player.carried_by = context.get("carried_by", "")
	player.carrying_actor_id = context.get("carried_pair", context.get("carrying_pair",{})).get("passenger_id", "") if context.get("carried_pair", context.get("carrying_pair",{})).get("carrier_id", "") == controller else ""
	player.appearance = context.get("actor_appearances", {}).get(controller, "child_age_10" if controller in ["char_liang_xiao", "char_hua_xiaoshuang"] else "adult")
	player.water_penalty_removed = bool(context.get("water_penalty_removed", false)) or "l01_water_movement_no_slow" in context.get("exploration_unlocks", [])
	player.movement_multiplier = 0.7 if str(scene_data.get("map_id", "")).begins_with("map_ch05_") and not player.carrying_actor_id.is_empty() else 1.0
	player.refresh_appearance()
	player.visual.mounted_on = "animal_yanzhi" if context.get("mounted_on","") == "animal_yanzhi" or context.get("riding",false) else ""
	var sword: Dictionary = context.get("world_objects", {}).get("item_ch01_xuanyuan_sword", {})
	var sword_state: String = str(sword.get("state", ""))
	player.visual.sword_state = sword_state if sword.get("owner", "") == controller and sword_state in ["carried", "wrapped"] else ""
	_apply_item_visuals(player.visual,controller,context)
	var default_present: Array = cast_actors.keys()
	if str(scene_data.get("map_id", "")).begins_with("map_ch02_") or str(scene_data.get("map_id", "")).begins_with("map_ch03_") or str(scene_data.get("map_id", "")).begins_with("map_ch04_") or str(scene_data.get("map_id", "")).begins_with("map_ch05_"):
		default_present = []
		var names: Dictionary = CH05_NAMES if str(scene_data.get("map_id", "")).begins_with("map_ch05_") else CH04_NAMES if str(scene_data.get("map_id", "")).begins_with("map_ch04_") else CH02_NAMES
		for name in scene_data.get("cast", []):
			if names.has(name):
				default_present.append(names[name])
	var present: Array = context.get("present_actor_ids", default_present)
	var dead: Array = context.get("dead_actor_ids", [])
	var departed: Array = context.get("departed_actor_ids", [])
	for id in cast_actors:
		var actor: PixelActor = cast_actors[id]
		var local_body: bool = id == "char_liang_wenjing" and id in dead and scene_data.id in ["ch01_pursuit_last_words", "ch01_graveyard_dogs", "ch01_unfinished_tombstone"]
		actor.visible = (id in present or local_body) and id != controller and id != player.carried_by and (id not in departed or local_body)
		if player.visual.mounted_on == "animal_yanzhi" and id in ["char_liu_yingying","animal_yanzhi","char_liang_xiao"]: actor.visible = false
		if id == player.carrying_actor_id: actor.visible = false
		_apply_item_visuals(actor,id,context)
		actor.visible = actor.visible and id != player.carrying_actor_id
		actor.appearance = context.get("actor_appearances", {}).get(id, actor.appearance)
		actor.refresh_texture()
		actor.is_body = id in dead
		# A dead father remains a world body until burial, never a walking party member.
		if id == "char_liang_wenjing" and ("father_buried" in context.get("completed_actions", []) or context.get("world_objects", {}).get("father_grave", {}).get("state", "") == "buried" or scene_data.id == "ch01_eastbound_orphan"):
			actor.visible = false
		if str(scene_data.get("map_id", "")) == "map_ch03_forest_road":
			var occupants: Array = context.get("world_objects", {}).get("ch03_hidden_hollow", {}).get("occupants", [])
			if id in occupants:
				actor.position = _point(layout.anchors.hidden_hollow if id == "char_hua_xiaoshuang" else layout.anchors.safe_animal_recess)
				if id == "follower_baichier": actor.position += Vector2(-8,0)
				if id == "follower_jinlinger": actor.position += Vector2(8,0)
				actor.visible = scene_data.id != "ch03_valley_departure"
				actor.walking = false
	queue_redraw()

func _configure_chapter(data: Dictionary, spawn: Vector2, context: Dictionary) -> void:
	map_size = _point(layout.size)
	if ResourceLoader.exists("res://assets/pixel_candidate/pal01_tiles.png"):
		candidate_tiles = load("res://assets/pixel_candidate/pal01_tiles.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = KunlunPlayer.new()
	player.bounds = _rect(layout.walk_bounds)
	player.blocked_rects.clear()
	for water_rect in layout.get("water_rects", []): player.water_rects.append(_rect(water_rect))
	for r in layout.solids + (layout.get("deep_water_rects",[]) if str(data.get("map_id", "")).begins_with("map_ch05_") else []):
		var rect := _rect(r)
		solid_rects.append(rect)
		player.blocked_rects.append(rect)
		_add_obstacle(rect.get_center(), rect.size)
	player.position = spawn if spawn.is_finite() else default_spawn()
	if not player.is_walkable(player.position):
		player.position = default_spawn()
	actors.add_child(player)
	for entry in layout.actors:
		var actor := PixelActor.new()
		actor.actor_id = entry.id
		actor.appearance = "child_age_10" if entry.id in ["char_liang_xiao", "char_hua_xiaoshuang", "char_huasheng"] else "adult"
		actor.position = _point(entry.position)
		actors.add_child(actor)
		cast_actors[entry.id] = actor
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size.x)
	camera.limit_bottom = int(map_size.y)
	add_child(camera)
	set_runtime_context(context)
	camera.position = (player.position + Vector2(0, -16)).round()
	queue_redraw()

func configure(data: Dictionary, spawn: Vector2, context: Dictionary = {}) -> void:
	scene_data = data
	var tiles: Array = data.get("map_tiles", [16, 9])
	map_size = Vector2(tiles[0], tiles[1]) * TILE
	for child in get_children():
		remove_child(child)
		child.queue_free()
	interactions.clear()
	cast_actors.clear()
	solid_rects.clear()
	path_progress.clear()
	escape_view.clear()
	controlled_view.clear()
	movement_trail.clear()
	layout = {}
	if str(data.get("map_id", "")).begins_with("map_ch01_"):
		if chapter_maps.is_empty():
			chapter_maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_one_maps.json")).maps
		layout = chapter_maps.get(data.map_id, {})
	elif str(data.get("map_id", "")).begins_with("map_ch02_"):
		if chapter_two_maps.is_empty():
			chapter_two_maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_two_maps.json")).maps
		layout = chapter_two_maps.get(data.map_id, {})
	elif str(data.get("map_id", "")).begins_with("map_ch03_"):
		if chapter_three_maps.is_empty():
			chapter_three_maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_three_maps.json")).maps
		layout = chapter_three_maps.get(data.map_id, {})
	elif str(data.get("map_id", "")).begins_with("map_ch04_"):
		if chapter_four_maps.is_empty():
			chapter_four_maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_four_maps.json")).maps
		layout = chapter_four_maps.get(data.map_id, {})
	elif str(data.get("map_id", "")).begins_with("map_ch05_"):
		if chapter_five_maps.is_empty():
			chapter_five_maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/chapter_five_maps.json")).maps
		layout = chapter_five_maps.get(data.map_id,{})
	if not layout.is_empty():
		_configure_chapter(data, spawn, context)
		return
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = KunlunPlayer.new()
	player.position = spawn
	player.bounds = Rect2(24, 70, map_size.x - 48, 80)
	actors.add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(160,90)
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size.x)
	camera.limit_bottom = int(map_size.y)
	add_child(camera)
	var target := {"id":"main", "name":str(data.interaction), "position":Vector2(166,104), "main":true, "action_id":"main"}
	interactions.append(target)
	for i in range(data.cast.size()):
		var actor := PixelActor.new()
		actor.actor_id = {"梁文靖": "char_liang_wenjing", "梁天德": "char_liang_tiande", "萧玉翎": "char_xiao_yuling"}.get(str(data.cast[i]), "")
		actor.position = Vector2(166 + i * 40, 104 - (i % 2) * 10)
		actor.robe = [Color("887359"),Color("a55749"),Color("66787c"),Color("72686d")][i % 4]
		actors.add_child(actor)
		if i == 0 and data.id == "shenxian_crossing":
			actor.position = Vector2(178,89)
		_add_obstacle(actor.position, Vector2(12, 6))
	if data.id == "shenxian_crossing":
		for i in range(7):
			var body := PixelActor.new()
			body.is_body = true
			body.robe = Color("64516b") if i == 0 else Color("5d6061")
			body.position = Vector2(155+i*48, 108+(i%2)*20)
			actors.add_child(body)
	for i in range(data.objects.size()):
		var object: Dictionary = data.objects[i].duplicate()
		object.position = [Vector2(68,102),Vector2(244,132),Vector2(304,100)][i]
		object.main = false
		interactions.append(object)
	queue_redraw()

func _add_obstacle(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = dimensions
	shape.shape = rect
	body.add_child(shape)
	actors.add_child(body)

func nearest() -> Dictionary:
	var best: Dictionary = {}
	var distance := 31.0
	for point in interactions:
		var d := player.position.distance_to(point.position)
		if d < distance:
			best = point
			distance = d
	return best

func _process(delta: float) -> void:
	elapsed += delta
	_update_paths()
	_update_followers(delta)
	if player:
		# Actor feet remain ~106 logical pixels high, above the 48px dialogue band.
		camera.position = (player.position + Vector2(0, -16)).round()
		if controlled_view.get("objective_id","") in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"] or (str(scene_data.get("map_id", "")).begins_with("map_ch05_") and controlled_view.has("guard_position")):
			var guard := _point(controlled_view.guard_position)
			if absf(guard.y-player.position.y)<=128 and absf(guard.x-player.position.x)<=224: camera.position = ((guard+player.position)/2).round()
	queue_redraw()

func _update_followers(delta: float) -> void:
	if layout.is_empty() or not player or not escape_view.is_empty() or not controlled_view.is_empty():
		return
	if movement_trail.is_empty() or movement_trail[-1].distance_to(player.position) >= 6:
		movement_trail.append(player.position.round())
		if movement_trail.size() > 30:
			movement_trail.pop_front()
	var followed: Array[String] = []
	for id in runtime_context.get("follower_actor_ids", []):
		followed.append(str(id))
	if scene_data.id == "ch01_northbound_departure":
		followed = ["char_liang_wenjing", "char_xiao_yuling"]
	if not runtime_context.has("follower_actor_ids") and "puppy_adopted" in runtime_context.get("completed_actions", []) and "follower_baichier" not in followed:
		followed.append("follower_baichier")
	if str(scene_data.get("map_id", "")).begins_with("map_ch02_") and not runtime_context.has("follower_actor_ids"):
		for id in ["follower_baichier", "follower_jinlinger"]:
			if id == "follower_jinlinger" and "monkey_rescued" not in runtime_context.get("completed_actions", []):
				continue
			if cast_actors.has(id) and cast_actors[id].visible and id not in followed:
				followed.append(id)
	for i in range(followed.size()):
		var actor: PixelActor = cast_actors.get(followed[i])
		if not actor or not actor.visible or actor.is_body:
			continue
		var trailing_samples: int = 5 + i * 3
		if movement_trail.size() <= trailing_samples:
			actor.walking = false
			continue # Preserve distinct authored starting positions until a real trail exists.
		var trail_index: int = movement_trail.size() - trailing_samples
		var difference: Vector2 = movement_trail[trail_index] - actor.position
		actor.walking = difference.length() > 3
		if actor.walking:
			var direction := difference.normalized()
			var next := actor.position.move_toward(movement_trail[trail_index], 62 * delta)
			if player.is_walkable(next):
				actor.position = next
			actor.facing = Vector2(signf(direction.x), 0) if absf(direction.x) > absf(direction.y) else Vector2(0, signf(direction.y))
		# Keep subpixel simulation positions: rounding each frame freezes high-FPS followers.
		# PixelActor rounds only its rendered origin, never this movement state.

func _draw() -> void:
	if scene_data.is_empty():
		return
	if not layout.is_empty():
		_draw_chapter()
		return
	var style: String = scene_data.style
	draw_rect(Rect2(Vector2.ZERO,map_size),Color("1e262b"))
	if style in ["inn", "prison", "temple"]:
		_draw_interior(style)
	elif style == "wall":
		_draw_wall()
	elif style == "river":
		_draw_river()
	else:
		_draw_mountain()
	for point in interactions:
		if not point.main:
			var p: Vector2 = point.position
			draw_rect(Rect2(p-Vector2(9,7),Vector2(18,8)),Color("8c7355"))
			draw_rect(Rect2(p-Vector2(7,7),Vector2(14,3)),Color("b7ab83"))
	var close := nearest() if player else {}
	if not close.is_empty():
		var p: Vector2 = close.position
		draw_line(p+Vector2(-12,5),p+Vector2(12,5),Color("d8c48e"),1)
	if style == "mountain":
		for i in range(46):
			var x := fmod(i * 47.0 - elapsed * 32, map_size.x)
			var y := fmod(i * 29.0 + elapsed * 110, 210)
			draw_line(Vector2(floor(x),floor(y)),Vector2(floor(x)-2,floor(y)+5),Color("79898d"),1)

func _draw_mountain() -> void:
	for i in range(18):
		var x := i * 80
		draw_colored_polygon(PackedVector2Array([Vector2(x-90,200),Vector2(x+15,10+(i%3)*18),Vector2(x+155,220)]),Color("29373c"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-20,200),Vector2(x+15,10+(i%3)*18),Vector2(x+65,200)]),Color("35464b"))
	draw_rect(Rect2(0,65,map_size.x,90),Color("514f44"))
	for x in range(0,int(map_size.x),16):
		draw_rect(Rect2(x,68,15,83),Color("827359") if x%32 == 0 else Color("716650"))
		draw_line(Vector2(x+2,75),Vector2(x+2,146),Color("585446"))
	for x in range(0,int(map_size.x),32):
		draw_rect(Rect2(x,146,3,18),Color("292f30"))
		draw_rect(Rect2(x,54,3,17),Color("292f30"))
	draw_line(Vector2(0,57),Vector2(map_size.x,57),Color("99927c"),2)
	draw_line(Vector2(0,152),Vector2(map_size.x,152),Color("99927c"),2)
	for i in range(14):
		var x: float = floor(fmod(i*89 + elapsed*3,map_size.x))
		draw_rect(Rect2(x,179+(i%3)*20,70,3),Color("78878a"))

func _draw_interior(style: String) -> void:
	draw_rect(Rect2(0,34,map_size.x,150),Color("675d4c") if style == "inn" else Color("3c4549"))
	for x in range(0,int(map_size.x),32):
		for y in range(40,180,16):
			draw_rect(Rect2(x+(y%32)/2.0,y,30,14),Color("786a52") if style == "inn" else Color("4a565a"))
	draw_rect(Rect2(0,0,map_size.x,42),Color("242d30"))
	draw_rect(Rect2(0,37,map_size.x,6),Color("a08a60"))
	for x in range(24,int(map_size.x),112):
		draw_rect(Rect2(x,8,29,25),Color("162329"))
		draw_rect(Rect2(x+2,10,25,21),Color("5b7175"))
		draw_rect(Rect2(x+13,10,2,22),Color("252b2d"))
		draw_rect(Rect2(x+2,21,25,2),Color("252b2d"))
	if style == "prison":
		for x in range(132,222,10):
			draw_rect(Rect2(x,48,3,58),Color("141820"))
	else:
		for x in range(350,int(map_size.x),128):
			draw_rect(Rect2(x,72,42,20),Color("302f29"))
			draw_rect(Rect2(x,68,42,18),Color("9d8158"))
	for x in [30,290]:
		draw_rect(Rect2(x,43,5,12),Color("392f27"))
		draw_rect(Rect2(x+1,37,3,7),Color("e8b56a"))

func _draw_wall() -> void:
	draw_rect(Rect2(0,0,map_size.x,60),Color("713f35"))
	draw_rect(Rect2(0,60,map_size.x,100),Color("697071"))
	for x in range(0,int(map_size.x),32):
		for y in range(64,160,16):
			draw_rect(Rect2(x+(y%32)/2.0,y,30,14),Color("78807d"))
		draw_rect(Rect2(x,42,24,22),Color("414a4c"))
		draw_rect(Rect2(x,41,24,5),Color("94978a"))
		draw_rect(Rect2(x,160,28,32),Color("434d50"))
	for i in range(24):
		draw_rect(Rect2(i*55,24+(i%3)*8,6,9),Color("d58342"))

func _draw_river() -> void:
	draw_rect(Rect2(Vector2.ZERO,map_size),Color("385e63"))
	for i in range(120):
		var x: float = floor(fmod(i*43+elapsed*6,map_size.x))
		var y := 24+(i*23)%int(map_size.y-24)
		draw_rect(Rect2(x,y,13+(i%4)*5,1),Color("788e8a"))
	draw_rect(Rect2(0,62,map_size.x,93),Color("81765b"))
	for x in range(0,int(map_size.x),16):
		draw_rect(Rect2(x,66,14,84),Color("9a8966"))
	draw_rect(Rect2(240,142,65,16),Color("332e29"))
	draw_rect(Rect2(250,137,42,15),Color("676454"))

# Authored spatial layouts, development fallback dressing; not final chapter art.
func _draw_chapter() -> void:
	if str(scene_data.get("map_id", "")).begins_with("map_ch05_"):
		_draw_chapter_five()
		return
	if str(scene_data.get("map_id", "")).begins_with("map_ch04_"):
		_draw_chapter_four()
		return
	if str(scene_data.get("map_id", "")).begins_with("map_ch03_"):
		_draw_chapter_three()
		return
	if str(scene_data.get("map_id", "")).begins_with("map_ch02_"):
		_draw_chapter_two()
		return
	var style: String = layout.style
	var ground := Color("79755b")
	if style in ["graveyard", "pursuit"]:
		ground = Color("51565a")
	elif style in ["assembly", "temple_court"]:
		ground = Color("777873")
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("293c3b"))
	draw_rect(_rect(layout.walk_bounds).grow(12), ground.darkened(0.23))
	draw_rect(_rect(layout.walk_bounds), ground)
	if candidate_tiles:
		_draw_candidate_ground(Rect2(Vector2.ZERO, map_size), [Vector2(64, 0), Vector2(96, 0)])
		var cells: Array[Vector2] = [Vector2(128, 0)]
		if style in ["assembly", "temple_court", "graveyard"]:
			cells = [Vector2(0, 0), Vector2(32, 64), Vector2(0, 64)]
		_draw_candidate_ground(_rect(layout.walk_bounds), cells)
	for y in range(84, int(map_size.y) - 24, 16):
		for x in range(24, int(map_size.x) - 24, 32):
			draw_rect(Rect2(x + (y % 32), y, 5, 1), ground.lightened(0.1))
	if style == "courtyard":
		draw_rect(Rect2(24, 56, 368, 5), Color("bcb08a"))
	elif style == "teahouse":
		# The source is a sheltered tea shop opening onto the road on the right.
		# Keep all existing table/door clearances and physical geometry unchanged.
		draw_rect(Rect2(12, 32, 264, 176), Color("48453d"))
		draw_rect(Rect2(24, 72, 252, 120), Color("927a53"))
		if candidate_tiles:
			_draw_candidate_ground(Rect2(24, 72, 252, 120), [Vector2(32, 32), Vector2(64, 32)])
		else:
			for x in range(24, 276, 16):
				draw_line(Vector2(x, 72), Vector2(x, 192), Color("665940"))
		draw_rect(Rect2(24, 38, 252, 28), Color("9a8c67"))
		draw_rect(Rect2(24, 66, 252, 6), Color("554b3b"))
		draw_rect(Rect2(14, 72, 10, 120), Color("817358"))
		draw_rect(Rect2(24, 192, 252, 8), Color("625640"))
		# Open frontage/threshold leads to the actual walkable northbound road.
		draw_rect(Rect2(272, 72, 4, 120), Color("bcaa7c"))
		draw_rect(Rect2(276, 60, 116, 132), Color("a09067"))
		if candidate_tiles:
			_draw_candidate_ground(Rect2(276, 72, 116, 120), [Vector2(128, 0)])
	elif style == "assembly":
		draw_rect(Rect2(248, 14, 3, 54), Color("b4a67a"))
		draw_rect(Rect2(251, 16, 32, 18), Color("824d44"))
	elif style == "graveyard":
		for x in [48, 224, 384]:
			draw_rect(Rect2(x, 48, 14, 28), Color("404d50"))
	for entry in layout.decor:
		_draw_landmark(Rect2(entry[0], entry[1], entry[2], entry[3]), entry[4])
	if style == "graveyard":
		var completed: Array = runtime_context.get("completed_actions", [])
		var objects: Dictionary = runtime_context.get("world_objects", {})
		var buried: bool = "father_buried" in completed or objects.get("father_grave", {}).get("state", "") == "buried" or scene_data.id == "ch01_eastbound_orphan"
		if buried:
			draw_rect(Rect2(160, 125, 48, 20), Color("77715f"))
		if "obtain_wood_marker" in completed or objects.has("item_ch01_tomb_marker") or scene_data.id == "ch01_eastbound_orphan":
			draw_rect(Rect2(178, 106, 13, 31), Color("a6936d"))
			if "marker_liang_written" in completed or scene_data.id == "ch01_eastbound_orphan":
				draw_rect(Rect2(181, 111, 6, 2), Color("343939"))
			if "marker_wen_written" in completed or scene_data.id == "ch01_eastbound_orphan":
				draw_rect(Rect2(181, 118, 6, 2), Color("343939"))
		if objects.get("dog_grave", {}).get("state", "") == "buried" or "dogs_buried" in completed:
			draw_rect(Rect2(256, 157, 24, 12), Color("77715f"))
		else:
			draw_rect(Rect2(258, 151, 22, 7), Color("85887f"))
			draw_rect(Rect2(277, 149, 7, 7), Color("a0a395"))
		if objects.get("item_ch01_memorial_broken_blade", {}).get("state", "") == "placed":
			draw_rect(Rect2(199, 116, 2, 20), Color("aaaeb0"))
			draw_rect(Rect2(196, 132, 8, 2), Color("766a57"))
		# Last slot deliberately blank. The marker never writes 靖 automatically.
	for point in interactions:
		var p: Vector2 = point.position
		if point.get("type", "") == "route":
			var geometry := get_objective_geometry(point.action_id)
			var progress := get_path_progress(point.action_id)
			if progress.index < geometry.waypoints.size():
				p = geometry.waypoints[progress.index]
		draw_line(p + Vector2(-5, 2), p + Vector2(0, -2), Color("d8c48e"))
		draw_line(p + Vector2(0, -2), p + Vector2(5, 2), Color("d8c48e"))
	var close := nearest()
	if not close.is_empty():
		var p: Vector2 = close.position
		draw_line(p + Vector2(-10, 5), p + Vector2(10, 5), Color("eee3bc"))

func _draw_landmark(rect: Rect2, kind: String) -> void:
	var p := rect.position
	match kind:
		"house", "ruin":
			draw_rect(rect, Color("585e57"))
			draw_rect(Rect2(p, Vector2(rect.size.x, 10)), Color("353f40"))
			for x in range(int(p.x) + 3, int(rect.end.x) - 4, 16):
				draw_line(Vector2(x, p.y + 12), Vector2(x, rect.end.y - 2), Color("778079"))
		"table":
			draw_rect(rect.grow(2), Color("3c3931"))
			draw_rect(rect, Color("a08760"))
			draw_rect(Rect2(p + Vector2(8, 4), Vector2(5, 4)), Color("d0c2a2"))
		"rock", "old_grave":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, rect.size.y), p + Vector2(4, 8), p + Vector2(rect.size.x / 2, 0), p + Vector2(rect.size.x - 3, 9), rect.end]), Color("555f60"))
			draw_line(p + Vector2(7, 10), p + Vector2(rect.size.x - 8, 7), Color("91998c"))
		"tree":
			draw_rect(Rect2(rect.get_center().x - 3, p.y, 6, rect.size.y), Color("595247"))
			draw_rect(Rect2(p.x - 10, p.y - 20, rect.size.x + 20, 28), Color("354c48"))
		"platform":
			draw_rect(rect, Color("535e61"))
			for offset in [0, 5, 10]:
				draw_line(Vector2(p.x, rect.end.y - offset), Vector2(rect.end.x, rect.end.y - offset), Color("a3a492"), 2)
		"circle":
			draw_arc(rect.get_center().round(), 25, 0, TAU, 32, Color("c3bd9c"), 1)
		"crowd":
			for x in range(int(p.x) + 8, int(rect.end.x), 14):
				for y in range(int(p.y) + 14, int(rect.end.y) + 1, 18):
					draw_rect(Rect2(x - 4, y - 12, 8, 12), Color("424a4c"))
					draw_rect(Rect2(x - 3, y - 18, 6, 6), Color("858276"))
		"sand":
			draw_rect(rect, Color("b8a77c"))
			for i in range(2):
				draw_line(p + Vector2(5 + i * 14, 5), p + Vector2(12 + i * 14, 12), Color("6a6554"))
		"training":
			draw_rect(rect, Color("8c8865"), false, 1)

func _draw_candidate_ground(area: Rect2, cells: Array[Vector2]) -> void:
	for y in range(int(area.position.y), int(area.end.y), 32):
		for x in range(int(area.position.x), int(area.end.x), 32):
			var cell: Vector2 = cells[(x / 32 + y / 32 * 3) % cells.size()]
			var dimensions := Vector2(mini(32, int(area.end.x) - x), mini(32, int(area.end.y) - y))
			draw_texture_rect_region(candidate_tiles, Rect2(Vector2(x, y), dimensions), Rect2(cell, dimensions))

func _draw_chapter_two() -> void:
	var style: String = layout.style
	var bounds := _rect(layout.walk_bounds)
	var interior: bool = style in ["villa_interior", "study_interior", "crisis_interior"]
	var water: bool = style in ["lake_shore", "water_transit", "waterworks"]
	var background := Color("313e43") if interior else Color("3e5548")
	if water:
		background = Color("3c6268")
	draw_rect(Rect2(Vector2.ZERO, map_size), background)
	if water:
		for y in range(24, int(map_size.y), 19):
			for x in range(0, int(map_size.x), 48):
				draw_line(Vector2(x + (y % 31), y), Vector2(x + 22 + (y % 31), y), Color("78948c"))
	var floor_color := Color("9c8965")
	var cells: Array[Vector2] = [Vector2(128, 0)]
	if interior or style in ["water_transit", "pavilion"]:
		cells = [Vector2(32, 32), Vector2(64, 32)]
		floor_color = Color("927a53")
	elif style in ["statue_array", "survey_terrace", "waterworks", "lake_shore"]:
		cells = [Vector2(32, 64), Vector2(0, 64)]
		floor_color = Color("737c7c")
	draw_rect(bounds, floor_color)
	if candidate_tiles:
		_draw_candidate_ground(bounds, cells)
	if interior:
		draw_rect(Rect2(12, 30, map_size.x - 24, 44), Color("898d7e"))
		draw_rect(Rect2(12, 68, map_size.x - 24, 12), Color("4c4b40"))
		draw_rect(Rect2(12, 80, 12, bounds.size.y), Color("625e4e"))
		draw_rect(Rect2(bounds.end.x, 80, 12, bounds.size.y), Color("625e4e"))
		for x in range(48, int(map_size.x) - 48, 112):
			draw_rect(Rect2(x, 34, 40, 28), Color("31434c"))
			draw_line(Vector2(x + 20, 34), Vector2(x + 20, 62), Color("b2a779"), 2)
			draw_line(Vector2(x, 48), Vector2(x + 40, 48), Color("b2a779"), 2)
	elif style == "statue_array":
		for y in range(80, int(bounds.end.y), 32):
			for x in range(24, int(bounds.end.x), 32):
				if ((x - 24) / 32 + (y - 80) / 32) % 2 == 0:
					draw_rect(Rect2(x, y, 32, 32), Color("8c9690"))
	elif style == "pavilion":
		draw_rect(Rect2(132, 38, 208, 16), Color("626e67"))
		draw_rect(Rect2(144, 54, 184, 5), Color("a79c74"))
	elif style == "survey_terrace":
		for x in range(24, 488, 24):
			draw_rect(Rect2(x, 60, 4, 20), Color("aab0a3"))
		draw_line(Vector2(24, 64), Vector2(488, 64), Color("aab0a3"), 3)
		draw_line(Vector2(96, 144), Vector2(320, 144), Color("ddcd92"), 1)
		for x in range(96, 321, 16):
			draw_line(Vector2(x, 141), Vector2(x, 147), Color("ddcd92"), 1)
	for entry in layout.decor:
		_draw_chapter_two_prop(Rect2(entry[0], entry[1], entry[2], entry[3]), str(entry[4]))
	if style == "study_interior":
		_draw_study_state()
	if style == "statue_array":
		var geometry := get_objective_geometry("shadow_practice_verified")
		var phase: int = clampi(int(runtime_context.get("shadow_phase", 0)), 0, 2)
		for i in range(geometry.waypoints.size()):
			var point: Vector2 = geometry.waypoints[i]
			draw_rect(Rect2(point - Vector2(9, 5), Vector2(18, 10)), Color("c4c4a1") if i == phase else Color("536771"), false, 1)
			if i == phase:
				draw_rect(Rect2(point - Vector2(5, 2), Vector2(3, 5)), Color("d8cd9f"))
				draw_rect(Rect2(point + Vector2(2, -2), Vector2(3, 5)), Color("d8cd9f"))
	for point in interactions:
		var p: Vector2 = point.position
		if point.get("type", "") == "route":
			var geometry := get_objective_geometry(point.action_id)
			var progress := get_path_progress(point.action_id)
			if progress.index < geometry.waypoints.size():
				p = geometry.waypoints[progress.index]
		draw_line(p + Vector2(-5, 2), p + Vector2(0, -2), Color("e3d6a5"))
		draw_line(p + Vector2(0, -2), p + Vector2(5, 2), Color("e3d6a5"))
	var close := nearest()
	if not close.is_empty():
		draw_line(close.position + Vector2(-10, 5), close.position + Vector2(10, 5), Color("fff0b8"))

func _draw_study_state() -> void:
	var completed: Array = runtime_context.get("completed_actions", [])
	for i in range(1, 4):
		var id := "r01_page_" + str(i)
		if id not in completed:
			var p: Vector2 = get_objective_geometry(id).position
			draw_rect(Rect2(p - Vector2(7, 6), Vector2(14, 9)), Color("d4c9a6"))
			draw_line(p - Vector2(4, 3), p + Vector2(3, -3), Color("62655a"))
	var season: String = runtime_context.get("season", "winter" if scene_data.id == "ch02_lamp_lesson" else "spring")
	var seasonal_color: Color = {"spring": Color("8baf87"), "summer": Color("648a79"), "autumn": Color("b69d67"), "winter": Color("c4d3cf")}.get(season, Color("8baf87"))
	for x in range(56, 464, 112):
		draw_rect(Rect2(x, 52, 21, 5), seasonal_color)
	if season == "winter":
		for i in range(12):
			draw_rect(Rect2(52 + (i % 4) * 112 + (i * 3 % 16), 36 + (i % 3) * 5, 1, 2), seasonal_color)
	elif season == "autumn":
		for i in range(8):
			draw_rect(Rect2(374 + i * 7, 160 + i % 3 * 3, 3, 2), seasonal_color)
	elif season == "summer":
		for x in range(380, 430, 8):
			draw_rect(Rect2(x, 203, 5, 2), Color("7e9e9c"))
	var objects: Dictionary = runtime_context.get("world_objects", {})
	if objects.has("item_ch02_unclosed_workbook"):
		draw_rect(Rect2(164, 88, 18, 9), Color("acb29a"))
	if "qingxin_inkstone_received" not in completed:
		draw_rect(Rect2(218, 88, 10, 5), Color("3f514e"))

func _draw_chapter_two_prop(rect: Rect2, kind: String) -> void:
	var p := rect.position
	match kind:
		"water":
			draw_rect(rect, Color("3e6569"))
			for y in range(int(p.y) + 4, int(rect.end.y), 12):
				draw_line(Vector2(p.x + 4, y), Vector2(rect.end.x - 4, y), Color("76938d"))
		"desk", "bookshelf", "bed", "chess", "cart", "boat":
			draw_rect(rect, Color("594e3c"))
			draw_rect(rect.grow(-3), Color("a18d65"))
			if kind == "chess":
				for x in range(int(p.x) + 5, int(rect.end.x), 8):
					draw_line(Vector2(x, p.y + 3), Vector2(x, rect.end.y - 3), Color("4f5048"))
				for y in range(int(p.y) + 5, int(rect.end.y), 8):
					draw_line(Vector2(p.x + 3, y), Vector2(rect.end.x - 3, y), Color("4f5048"))
			elif kind == "bed":
				draw_rect(rect.grow(-6), Color("a9b5a4"))
			elif kind == "bookshelf":
				for y in range(int(p.y) + 4, int(rect.end.y), 12):
					draw_rect(Rect2(p.x + 4, y, rect.size.x - 8, 6), Color("bcb18f"))
			elif kind == "desk":
				draw_rect(Rect2(p + Vector2(10, 5), Vector2(24, 12)), Color("d2c7a5"))
				draw_rect(Rect2(rect.end.x - 13, p.y + 4, 5, 8), Color("dbc381"))
		"pillar", "statue", "gnomon":
			draw_rect(rect, Color("59666b"))
			draw_rect(Rect2(p.x + 4, p.y - 24, rect.size.x - 8, rect.size.y + 20), Color("89938a"))
			if kind == "statue":
				draw_rect(Rect2(p.x + 6, p.y - 38, rect.size.x - 12, 14), Color("a3a797"))
				draw_colored_polygon(PackedVector2Array([rect.get_center(), rect.end + Vector2(32, 18), rect.end + Vector2(10, 26)]), Color("354b58"))
			elif kind == "gnomon":
				draw_line(rect.get_center(), rect.get_center() + Vector2(42, 20), Color("354b58"), 3)
		"waterwheel":
			var center := rect.get_center()
			draw_circle(center, 26, Color("495b5f"))
			draw_arc(center, 24, 0, TAU, 24, Color("ad9a6b"), 3)
			for i in range(8):
				var angle: float = i * TAU / 8 + floor(elapsed * 3) * PI / 12
				draw_line(center, (center + Vector2(cos(angle), sin(angle)) * 24).round(), Color("b29c6a"), 2)
		"wood_ox":
			draw_rect(Rect2(p + Vector2(0, 8), Vector2(rect.size.x, 24)), Color("9b865b"))
			draw_rect(Rect2(p + Vector2(4, 28), Vector2(7, 18)), Color("706348"))
			draw_rect(Rect2(p + Vector2(32, 28), Vector2(7, 18)), Color("706348"))
		"stove":
			draw_rect(rect, Color("485456"))
			draw_rect(rect.grow(-6), Color("b37655"))
		"water_channel":
			draw_rect(rect, Color("5e6862"))
			draw_rect(rect.grow(-4), Color("7b9790"))
		"survey_model":
			draw_rect(rect, Color("a49773"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(4, 24), p + Vector2(18, -12), p + Vector2(30, 24)]), Color("626e67"))
			draw_line(p + Vector2(18, 24), p + Vector2(52, 26), Color("3d5158"), 2)
		"papers":
			for i in range(8):
				draw_rect(Rect2(p + Vector2((i * 13) % int(rect.size.x), (i * 11) % int(rect.size.y)), Vector2(12, 7)), Color("bfc0a7"))
		_:
			_draw_landmark(rect, kind)

# Discrete encounter mode owns simulation. Never run player physics and session movement together.
func sync_escape_view(view: Dictionary) -> void:
	escape_view = view.get("world_state", {}).duplicate(true)
	if escape_view.is_empty():
		set_runtime_context(runtime_context)
		return
	player.enabled = false
	player.position = _point(escape_view.player_position)
	player.velocity = Vector2.ZERO
	player.carrying_actor_id = "char_hua_xiaoshuang" if escape_view.get("carrying",false) else ""
	player.refresh_appearance()
	if cast_actors.has("char_ming_gui"):
		cast_actors.char_ming_gui.visible = true
		cast_actors.char_ming_gui.position = _point(escape_view.ming_position)
		cast_actors.char_ming_gui.facing = _point(escape_view.ming_facing)
	if cast_actors.has("char_hua_xiaoshuang"):
		var girl: PixelActor = cast_actors.char_hua_xiaoshuang
		girl.visible = not escape_view.get("carrying",false)
		girl.position = _point(layout.anchors.get("hidden_hollow",layout.anchors.get("zhuanzhu_shadow",[112,208])))
	for id in ["follower_baichier","follower_jinlinger"]:
		if cast_actors.has(id):
			cast_actors[id].visible = str(scene_data.map_id) == "map_ch03_forest_road"
			cast_actors[id].position = _point(layout.anchors.get("safe_animal_recess",[64,208])) + Vector2(-8 if id == "follower_baichier" else 8,0)
	queue_redraw()

func _draw_chapter_three() -> void:
	var style: String = layout.style
	var bounds := _rect(layout.walk_bounds)
	var interior := style == "medicine_pavilion"
	var forest := style == "forest_decoy"
	draw_rect(Rect2(Vector2.ZERO,map_size), Color("263c37") if forest else Color("34464a"))
	draw_rect(bounds,Color("826f51") if interior else (Color("637052") if forest else Color("747e7c")))
	if candidate_tiles:
		var cells: Array[Vector2] = []
		cells.assign([Vector2(32,32),Vector2(64,32)] if interior else ([Vector2(128,0)] if forest else [Vector2(32,64),Vector2(0,64)]))
		_draw_candidate_ground(bounds,cells)
	if interior:
		draw_rect(Rect2(112,48,368,40),Color("89917e"))
		for x in [152,264,376]:
			draw_rect(Rect2(x,56,40,24),Color("294c50"))
			draw_line(Vector2(x+20,56),Vector2(x+20,80),Color("b9a470"),2)
		# The herb approach is outside, the tea room is visibly wooden.
		draw_rect(Rect2(48,96,64,208),Color("607454"))
	elif style == "lingtai_court":
		for y in range(96,305,32): draw_line(Vector2(48,y),Vector2(592,y),Color("9a9e91"))
		draw_arc(Vector2(408,144),38,0,TAU,40,Color("cbb579"),2)
		draw_arc(Vector2(408,144),24,0,TAU,32,Color("b6a46e"),1)
		draw_line(Vector2(352,208),Vector2(464,208),Color("b7a77a"))
	elif forest:
		for i in range(30): draw_rect(Rect2(52+(i*79)%530,102+(i*43)%198,3,2),Color("8c9164"))
	for entry in layout.decor:
		_draw_chapter_two_prop(Rect2(entry[0],entry[1],entry[2],entry[3]),str(entry[4]))
	if forest:
		var hollow := _point(layout.anchors.hidden_hollow)
		draw_rect(Rect2(hollow-Vector2(16,14),Vector2(32,18)),Color("1f302b"))
		var branch := _point(layout.anchors.decoy_branch)
		draw_line(branch+Vector2(-10,4),branch+Vector2(10,-22),Color("a39268"),3)
	if not escape_view.is_empty():
		var ming := _point(escape_view.ming_position)
		var facing := _point(escape_view.ming_facing)
		draw_line(ming,ming+facing*30,Color("d5a16d"),2)
		draw_circle(_point(escape_view.last_visible),4,Color("c29d78"),false,1)
		for key in layout.anchors:
			var p := _point(layout.anchors[key])
			var shade := Color("e4d296") if escape_view.phase == "overlap" else Color("668089")
			draw_rect(Rect2(p-Vector2(8,4),Vector2(16,8)),shade,false,1)
		if escape_view.get("cloak_state","") == "branch":
			var cloak := _point(escape_view.cloak_position)
			draw_colored_polygon(PackedVector2Array([cloak+Vector2(0,-25),cloak+Vector2(-10,-6),cloak+Vector2(12,-4)]),Color("adbdab"))
	for point in interactions:
		var p: Vector2 = point.position
		if point.get("type","") == "route":
			var geometry := get_objective_geometry(point.action_id)
			var progress := get_path_progress(point.action_id)
			if progress.index < geometry.waypoints.size(): p = geometry.waypoints[progress.index]
		draw_line(p+Vector2(-5,2),p+Vector2(0,-2),Color("e3d6a5"))
		draw_line(p+Vector2(0,-2),p+Vector2(5,2),Color("e3d6a5"))

func sync_controlled_view(view: Dictionary) -> void:
	if str(scene_data.get("map_id", "")).begins_with("map_ch05_"):
		_sync_chapter_five_view(view)
		return
	controlled_view = view.get("world_state", {}).duplicate(true)
	if controlled_view.is_empty() or not player: return
	player.position = _point(controlled_view.player_position)
	player.carrying_actor_id = "char_liu_yingying" if controlled_view.get("carrying",false) else ""
	if not player.carrying_actor_id.is_empty(): player.visual.mounted_on = ""
	player.refresh_appearance()
	if cast_actors.has("char_liu_yingying"):
		cast_actors.char_liu_yingying.visible = not controlled_view.get("carrying",false) and player.actor_id != "char_liu_yingying"
		if controlled_view.has("liu_position"): cast_actors.char_liu_yingying.position = _point(controlled_view.liu_position)
	if cast_actors.has("npc_chu_wan") and controlled_view.get("objective_id","") in ["gate_encounter_verified","chu_wan_released"]:
		var chu: PixelActor = cast_actors.npc_chu_wan
		chu.visible = true
		chu.position = player.position+Vector2(16,0) if controlled_view.get("chu_wan_held",false) else _point(layout.anchors.chu_wan)
		if controlled_view.get("objective_id","") == "chu_wan_released" and controlled_view.get("complete",false): chu.position = _point(layout.anchors.release_point)+Vector2(24,0)
	if cast_actors.has("animal_yanzhi") and controlled_view.has("horse_position"):
		cast_actors.animal_yanzhi.position = _point(controlled_view.horse_position)
		cast_actors.animal_yanzhi.visible = scene_data.map_id in ["map_ch04_roof_alley","map_ch04_courtyard"]
	player.visual.mounted_on = str(controlled_view.get("mounted_on",""))
	if player.visual.mounted_on == "animal_yanzhi":
		for id in ["char_liu_yingying","char_liang_xiao","animal_yanzhi"]:
			if cast_actors.has(id): cast_actors[id].visible = false
	queue_redraw()

func _draw_chapter_four() -> void:
	var style: String = layout.style
	var palettes := {"gusu_street":["81958b","596d67"],"tavern":["7a6046","533e30"],"roof_alley":["4b5965","303e4b"],"courtyard":["85887b","586151"],"temple":["89908a","61675d"],"bell_interior":["675a3d","302d28"],"rain_gallery":["627877","485b59"],"fengqiao":["778879","495c53"]}
	var colors: Array = palettes.get(style,["777777","555555"])
	draw_rect(Rect2(Vector2.ZERO,map_size),Color(colors[1]))
	draw_rect(_rect(layout.walk_bounds),Color(colors[0]))
	var indoor := style in ["tavern","bell_interior"]
	for y in range(144,337,16 if indoor else 24):
		for x in range(48,593,32):
			draw_rect(Rect2(x+(8 if y%48==0 else 0),y,28,1),Color(colors[1]).lightened(0.15))
	for r in layout.get("water_rects",[]):
		draw_rect(_rect(r),Color("467b8a"))
		for y in range(r[1]+4,r[1]+r[3],8): draw_line(Vector2(r[0]+4,y),Vector2(r[0]+r[2]-4,y),Color("85b7b6"),1)
	for r in layout.solids:
		var rect := _rect(r)
		draw_rect(rect,Color("263d45") if style == "roof_alley" else Color("3c4845"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,8)),Color("9b8c6a") if indoor else Color("5f7970"))
		for y in range(r[1]+12,r[1]+r[3],8): draw_line(Vector2(r[0]+2,y),Vector2(r[0]+r[2]-2,y),Color("536463"),1)
	if style in ["gusu_street","rain_gallery"]:
		# Elevated eaves are a visible walk surface connected by the authored access.
		draw_rect(Rect2(248,148,184,28),Color("536a69"))
		for x in range(248,433,8): draw_line(Vector2(x,148),Vector2(x,174),Color("75908a"),1)
		for y in range(180,225,8): draw_line(Vector2(256,y),Vector2(288,y),Color("b4b3a0"),2)
	if style == "tavern":
		draw_rect(Rect2(152,188,48,24),Color("96754d")); draw_circle(Vector2(272,194),6,Color("ddb66c"))
	elif style == "bell_interior":
		draw_arc(Vector2(320,244),172,PI,TAU,32,Color("b19758"),5)
		for x in [384,432,480]: draw_rect(Rect2(x-5,216,10,12),Color("c2b184"),false,1)
	elif style == "temple":
		draw_circle(Vector2(272,204),20,Color("9f8e59")); draw_rect(Rect2(252,206,40,24),Color("958455"))
	elif style == "roof_alley":
		draw_circle(_point(layout.anchors.spring),14,Color("a1aaa0"))
		draw_circle(_point(layout.anchors.spring),10,Color("628e94"))
		var boat := _point(layout.anchors.empty_boat)
		draw_rect(Rect2(boat-Vector2(28,12),Vector2(56,24)),Color("70573e"))
		draw_arc(boat-Vector2(0,8),24,PI,TAU,16,Color("2a413f"),8)
		if controlled_view.get("screen_closed",runtime_context.get("world_objects",{}).get("ch04_spatial_state",{}).get("screen_closed",false)):
			draw_rect(Rect2(boat-Vector2(24,24),Vector2(48,6)),Color("9c9b7e"))
	elif style == "fengqiao":
		draw_rect(Rect2(208,260,144,16),Color("6e5944")); draw_arc(Vector2(288,258),28,PI,TAU,16,Color("34433f"),10)
	for point in interactions:
		var pos: Vector2 = point.position
		draw_circle(pos,5,Color("e5cc83"),false,1)
		var progress := get_path_progress(str(point.id))
		var path: Array = get_objective_geometry(str(point.id)).get("waypoints",[])
		if progress.index < path.size():
			var next: Vector2 = path[progress.index]
			draw_line(next+Vector2(-5,-9),next+Vector2(0,-3),Color("f6e4a3"),2)
			draw_line(next+Vector2(5,-9),next+Vector2(0,-3),Color("f6e4a3"),2)
	if not controlled_view.is_empty():
		if controlled_view.get("rope_attached",false) and layout.anchors.has("rope_anchor"):
			draw_line(_point(layout.anchors.rope_anchor)+Vector2(0,-24),_point(layout.anchors.window)+Vector2(0,-20),Color("d3bc86"),2)
		if controlled_view.get("pulses",0)>0:
			for n in range(int(controlled_view.pulses)): draw_arc(player.position,20+n*7,PI,TAU,16,Color("d5b86f"),1)
		var target: Array = layout.anchors.get(controlled_view.get("target_anchor",""),layout.spawn)
		draw_circle(_point(target),9,Color("ffe09b"),false,1)
		if controlled_view.has("guard_position"):
			var p := _point(controlled_view.guard_position)
			draw_rect(Rect2(p-Vector2(6,22),Vector2(12,20)),Color("a05b4b"))
			draw_rect(Rect2(p-Vector2(4,31),Vector2(8,9)),Color("c6ad8d"))
			draw_rect(Rect2(p-Vector2(5,33),Vector2(10,4)),Color("303c41"))
			draw_rect(Rect2(p+Vector2(_point(controlled_view.guard_facing).x*2,-28),Vector2(2,2)),Color("252b31"))
			draw_line(p+Vector2(9,-20),p+Vector2(9,0),Color("b7b1a2"),2)
			if controlled_view.get("guarded",false):
				draw_arc(player.position+Vector2(0,-12),17,PI/2,PI*1.5,12,Color("e9d58c"),2)
			for n in range(mini(2,int(controlled_view.get("approaches",0)))):
				draw_rect(Rect2(p+Vector2(-8+n*10,-39),Vector2(6,3)),Color("f0d180"))
			if controlled_view.get("objective_id","") in ["patrol_escape_verified","horse_release_verified","horse_calm_and_led"]:
				var base := _point(controlled_view.guard_facing).angle()
				for n in range(9):
					var ray := Vector2.from_angle(base-PI/2+PI*n/8)
					var end := p
					for distance in range(2,145,2):
						var point := p+ray*distance
						var blocked := false
						for rect in solid_rects:
							if rect.grow(2).has_point(point): blocked = true; break
						if blocked: break
						end = point
					draw_line(p,end,Color(0.74,0.5,0.42,0.28),1)

func _apply_item_visuals(actor: PixelActor,id: String,context: Dictionary) -> void:
	var objects: Dictionary = context.get("world_objects",{}).duplicate(true)
	var items: Variant = context.get("items",{})
	if items is Dictionary:
		for key in items:
			if items[key] is Dictionary: objects[key] = items[key]
	var sword: Dictionary = objects.get("item_ch01_xuanyuan_sword",{})
	actor.sword_state = str(sword.get("state","")) if sword.get("owner","")==id and sword.get("state","") in ["carried","wrapped"] else ""
	var pouch: Dictionary = objects.get("item_ch04_pouch",{})
	actor.pouch_visible = pouch.get("owner",pouch.get("holder",""))==id
	var inkstone: Dictionary = objects.get("item_ch02_qingxin_inkstone",{})
	actor.inkstone_form = str(inkstone.get("form","")) if inkstone.get("owner","")==id else ""

func _sync_chapter_five_view(view: Dictionary) -> void:
	controlled_view = view.get("world_state",{}).duplicate(true)
	if controlled_view.is_empty() or not player: return
	var next_direction := _point(controlled_view.player_position)-player.position
	player.position = _point(controlled_view.player_position)
	player.actor_id = controlled_view.control_actor_id
	if next_direction!=Vector2.ZERO:player.visual.facing=next_direction.normalized()
	player.appearance = runtime_context.get("actor_appearances",{}).get(player.actor_id,"youth_age_17" if player.actor_id=="char_liang_xiao" else "youth_age_16")
	var pair: Dictionary = controlled_view.get("carrying_pair",{})
	player.carrying_actor_id = pair.get("passenger_id","") if pair.get("carrier_id","")==player.actor_id else ""
	player.visual.mounted_on = ""
	player.refresh_appearance()
	_apply_item_visuals(player.visual,player.actor_id,runtime_context)
	for id in cast_actors:
		var actor: PixelActor = cast_actors[id]
		actor.visible = id in controlled_view.get("visible_actor_ids",[]) and id!=player.actor_id and id!=player.carrying_actor_id
		if controlled_view.get("actor_positions",{}).has(id): actor.position=_point(controlled_view.actor_positions[id])
		actor.appearance=runtime_context.get("actor_appearances",{}).get(id,"youth_age_17" if id=="char_liang_xiao" else "youth_age_16")
		actor.refresh_texture()
	queue_redraw()

func _draw_chapter_five() -> void:
	var style: String = layout.style
	var palette := {"canal_deck":"8b7754","canal_cabin":"765d45","mechanism_skiff":"866a47","leigong_outer":"7a8273","locks_vault":"706b63","fire_corridor":"77504a","eight_gates":"7c705b","wulong_trail":"64765e","tree_hollow":"4b6251","canhong_corridor":"66586c","round_room":"77716b","pool_escape":"4f777a","cave_refuge":"5c6873"}
	var base := Color(palette.get(style,"777777"))
	draw_rect(Rect2(Vector2.ZERO,map_size),base.darkened(0.5))
	draw_rect(_rect(layout.walk_bounds),base)
	var wood := style in ["canal_deck","canal_cabin","mechanism_skiff"]
	for y in range(112,352,16):
		for x in range(48,608,48 if wood else 32):
			draw_rect(Rect2(x,y,44 if wood else 28,1),base.darkened(0.18))
	for r in layout.get("water_rects",[])+layout.get("deep_water_rects",[]):
		draw_rect(_rect(r),Color("355c71") if r in layout.get("deep_water_rects",[]) else Color("57929c"))
		for y in range(r[1]+4,r[1]+r[3],8): draw_line(Vector2(r[0]+4,y),Vector2(r[0]+r[2]-4,y),Color("90b8b4"),1)
	for r in layout.solids:
		draw_rect(_rect(r),base.darkened(0.5));draw_rect(Rect2(r[0],r[1],r[2],8),base.lightened(0.15))
		if style in ["wulong_trail","tree_hollow"]: draw_circle(Vector2(r[0]+r[2]/2,r[1]+8),28,Color("344c3d"))
		if style=="fire_corridor":
			for x in range(r[0]+4,r[0]+r[2],12): draw_colored_polygon(PackedVector2Array([Vector2(x,r[1]),Vector2(x+6,r[1]-14),Vector2(x+12,r[1])]),Color("df8e49"))
	if style=="round_room": draw_arc(Vector2(320,224),128,PI,TAU,32,Color("b5aba0"),4)
	if style=="locks_vault":
		for i in range(6): draw_rect(Rect2(128+i*48,112,12,16),Color("bb9e56"),false,2)
	if style=="eight_gates":
		for i in range(8):
			var p:=Vector2(320,224)+Vector2.from_angle(i*TAU/8)*112
			draw_rect(Rect2(p-Vector2(8,18),Vector2(16,24)),Color("8a6554"))
	for point in interactions:
		draw_circle(point.position,6,Color("ecd294"),false,1)
		var path: Array=get_objective_geometry(str(point.id)).get("waypoints",[])
		var progress:=get_path_progress(str(point.id))
		if progress.index<path.size():draw_circle(path[progress.index],9,Color("f6e4a3"),false,1)
	if controlled_view.is_empty():return
	if layout.anchors.has(controlled_view.get("target_anchor","")):draw_circle(_point(layout.anchors[controlled_view.target_anchor]),9,Color("ffe09b"),false,2)
	if not controlled_view.get("hat_position",[]).is_empty() and not controlled_view.get("hat_recovered",false):
		var hat:=_point(controlled_view.hat_position);draw_line(hat-Vector2(6,2),hat+Vector2(6,2),Color("c7b478"),3)
	if controlled_view.get("submerged",false):draw_arc(player.position,13,0,PI,12,Color("bddad4"),2)
	if controlled_view.has("guard_position"):
		var guard:=_point(controlled_view.guard_position)
		draw_rect(Rect2(guard-Vector2(6,22),Vector2(12,20)),Color("a97165"));draw_rect(Rect2(guard-Vector2(4,31),Vector2(8,9)),Color("c6ad8d"))
		var base_angle:=_point(controlled_view.guard_facing).angle()
		for n in range(9):
			var direction:=Vector2.from_angle(base_angle-PI/2+n*PI/8)
			var end:=guard
			for step in range(2,129,2):
				var p:=guard+direction*step;var blocked:=false
				for r in layout.solids:
					if _rect(r).grow(2).has_point(p):blocked=true;break
				if blocked:break
				end=p
			draw_line(guard,end,Color(0.95,0.72,0.42,0.3),1)
	if controlled_view.get("restricted",false):
		# Obscure the world around the injured actor; no hidden conversation text is supplied.
		var pos:=player.position
		draw_rect(Rect2(pos-Vector2(320,180),Vector2(240,360)),Color(0.14,0.04,0.04,0.94))
		draw_rect(Rect2(pos+Vector2(80,-180),Vector2(240,360)),Color(0.14,0.04,0.04,0.94))
