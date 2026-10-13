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

func configure(data: Dictionary, spawn: Vector2) -> void:
	scene_data = data
	map_size = Vector2(data.map_tiles[0], data.map_tiles[1]) * TILE
	for child in get_children():
		remove_child(child)
		child.queue_free()
	interactions.clear()
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
	var target := {"id":"main", "name":str(data.interaction), "position":Vector2(166,104), "main":true}
	interactions.append(target)
	for i in range(data.cast.size()):
		var actor := PixelActor.new()
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
	if player:
		# Actor feet remain ~106 logical pixels high, above the 48px dialogue band.
		camera.position = (player.position + Vector2(0, -16)).round()
	queue_redraw()

func _draw() -> void:
	if scene_data.is_empty():
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
