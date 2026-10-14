extends Control
## Diagrams only: authoritative geometry/graph transitions live in the resolver.
var view: Dictionary = {}
func _ready() -> void:
	custom_minimum_size = Vector2(250,190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func render(value: Dictionary) -> void:
	view = value.duplicate(true); queue_redraw()
func _draw() -> void:
	if view.is_empty(): return
	var s: Dictionary = view.state
	var font := get_theme_default_font()
	var ink := Color("e9e4d5"); var blue := Color("65c5df"); var gold := Color("f1c56b")
	draw_style_box(_background(),Rect2(Vector2.ZERO,size))
	match view.puzzle_id:
		"tile_ch04_intercept":
			var scale_x := (size.x-36.0)/12.0; var scale_y := 18.0
			var point := func(p: Array) -> Vector2: return Vector2(18+p[0]*scale_x,12+p[1]*scale_y)
			draw_rect(Rect2(18,12+4*scale_y,12*scale_x,3*scale_y),Color("225269"))
			for x in range(13): draw_line(point.call([x,0]),point.call([x,8]),Color(1,1,1,0.09))
			for y in range(9): draw_line(point.call([0,y]),point.call([12,y]),Color(1,1,1,0.09))
			var rope: Vector2 = point.call([10,5]); draw_line(rope-Vector2(0,15),rope+Vector2(0,15),Color("e47d68") if s.rope_cut else gold,3)
			var last: Vector2 = point.call([1,5]); draw_circle(last,4,ink)
			for i in range(s.contacts.size()):
				var target: Vector2 = point.call(s.contacts[i]); var curve := PackedVector2Array()
				for step in range(17):
					var t := step/16.0; curve.append(last.lerp(target,t)+Vector2(0,-sin(t*PI)*13))
				draw_polyline(curve,blue,2); draw_circle(target,4,blue)
				draw_string(font,target+Vector2(2,-5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink); last = target
			var center: Vector2 = point.call([9,6]); var hull := Vector2(34,10) if s.boat_angle==0 else Vector2(10,34)
			draw_rect(Rect2(center-hull/2,hull),Color("967b55")); draw_circle(center,4,Color("80c698") if s.landing!="" else gold)
			draw_string(font,Vector2(8,183),"水面4—6行；红/金线为缆索；黄/绿点为安全船尾",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
		"trial_ch04_staff":
			var center := Vector2(size.x/2,92); var radii := Vector2(maxf(70,size.x/2-27),68)
			var points: Array[Vector2] = []
			for i in range(45):
				var theta := -PI/2+i*TAU/45; points.append(center+Vector2(cos(theta)*radii.x,sin(theta)*radii.y))
			for i in range(45): draw_line(points[i],points[(i+1)%45],Color(0.6,0.65,0.7,0.5),1)
			for i in range(45):
				var color := ink if i in s.posts else Color("555964")
				if i==s.player: color = blue
				if i==s.rival: color = Color("e47d68")
				draw_circle(points[i],3,color)
				var theta := -PI/2+i*TAU/45
				var label := points[i]+Vector2(cos(theta)*11,sin(theta)*11)+Vector2(-4,4)
				draw_string(font,label,str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
			draw_string(font,center+Vector2(-65,-7),"蓝：梁萧%d  红：海雨%d" % [s.player,s.rival],HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			draw_string(font,center+Vector2(-65,13),"已过%d/3轮  %s" % [s.round,"全部棍毁" if s.collapsed else "相邻编号连边"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			draw_string(font,Vector2(8,183),"图论环，不代表真实世界跳跃距离；0与44也相连",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
		"r02":
			for i in range(6):
				var rect := Rect2(12+i*(size.x-24)/6,50,(size.x-24)/6-4,65)
				draw_rect(rect,Color("746743")); draw_rect(rect,ink,false)
				draw_string(font,rect.position+Vector2(8,20),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
				if s.slots[i]!="": draw_line(rect.position+Vector2(4,40),rect.end-Vector2(4,15),gold,4)
				draw_string(font,rect.position+Vector2(6,58),"上" if s.slots[i]=="over" else ("下" if s.slots[i]=="under" else "空"),HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
			draw_string(font,Vector2(12,150),"柳条1→槽1/2，柳条2→槽3/4，柳条3→槽5/6",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
		"l01":
			for i in range(3):
				var rect := Rect2(15+i*(size.x-30)/3,42,(size.x-30)/3-6,75)
				draw_rect(rect,Color("786850") if s.boards[i]!="" else Color("284454")); draw_rect(rect,blue if s.filler[i] else ink,false,3)
				draw_string(font,rect.position+Vector2(8,25),["船首 A","中段 B","船尾 C"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
				draw_string(font,rect.position+Vector2(8,50),"已封缝" if s.filler[i] else "未封缝",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			draw_string(font,Vector2(15,145),"潮汐 %d/3  进水 %d  载重 %d  %s" % [s.ticks,s.water,s.load,"船身水平" if s.level else "待扶正"],HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
func _background() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = Color("17242c"); return box
