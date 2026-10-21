extends Control
## Visible teaching geometry; never a completion controller or world-physics claim.
const Optics=preload("res://scripts/puzzles/chapter_five_optics.gd")
var view: Dictionary={}
func _ready() -> void:
	custom_minimum_size=Vector2(250,220); mouse_filter=Control.MOUSE_FILTER_IGNORE
func render(value: Dictionary) -> void: view=value.duplicate(true); queue_redraw()
func _draw() -> void:
	if view.is_empty(): return
	var s: Dictionary=view.state
	var font:=get_theme_default_font(); var ink:=Color("e8e3ce"); var blue:=Color("6bd2e3"); var gold:=Color("edc66a")
	draw_rect(Rect2(Vector2.ZERO,size),Color("17242c"))
	var scale_value:=minf((size.x-16)/320.0,(size.y-25)/180.0)
	var offset:=Vector2((size.x-320*scale_value)/2,5)
	var p:=func(v:Vector2)->Vector2: return offset+v*scale_value
	match view.puzzle_id:
		"chain_ch05_linkage":
			var nodes: Array[Vector2]=[Vector2(30,90),Vector2(95,50),Vector2(165,50),Vector2(220,125),Vector2(290,90)]
			for i in range(4):
				var target: int=s.links[i]
				if target>=0:
					var a: Vector2=p.call(nodes[i]); var b: Vector2=p.call(nodes[target]); var d: Vector2=(b-a).normalized()
					draw_line(a,b,blue,2); draw_line(b-d*12,b-d*18+d.orthogonal()*5,blue,2); draw_line(b-d*12,b-d*18-d.orthogonal()*5,blue,2)
			for i in range(5):
				var pos: Vector2=p.call(nodes[i]); var color:=gold if i in s.trace else ink
				if i==3 and not s.third_installed: color=Color("68717c")
				draw_circle(pos,11,color); draw_string(font,pos+Vector2(-4,4),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("17242c"))
				draw_string(font,pos+Vector2(-13,28),["踏板","翻板","锁闩","配重","出口"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
		"bagua_ch05_reverse":
			var center: Vector2=p.call(Vector2(160,90)); draw_arc(center,64*scale_value,0,TAU,64,Color("7f8c93"),1)
			draw_string(font,p.call(Vector2(154,14)),"北",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			draw_string(font,p.call(Vector2(238,94)),"东",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			if s.light_observed:
				draw_line(p.call(Vector2(32,90)),p.call(Vector2(96,90)),gold,3); draw_circle(p.call(Vector2(96,90)),5,gold)
			for i in range(8):
				var angle:=PI+i*TAU/8; var pos: Vector2=p.call(Vector2(160,90)+Vector2(cos(angle),sin(angle))*64)
				var text_value: String=str(i)+":"+(["乾","兑","离","震","巽","坎","艮","坤"][s.slots[i]] if s.slots[i]>=0 else "空")
				draw_string(font,pos+Vector2(-13,-8),text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,13,blue if i in s.checks else ink)
			draw_string(font,center+Vector2(-44,5),"西沿0／反向读",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
		"box_ch05_light":
			if not s.ray.is_empty():
				for segment in s.ray.segments:
					var a:=Vector2(segment.from[0],segment.from[1])/1000.0; var b:=Vector2(segment.to[0],segment.to[1])/1000.0
					draw_line(p.call(a),p.call(b),gold,2)
			draw_circle(p.call(Vector2(160,16)),4,gold)
			draw_string(font,p.call(Vector2(170,20)),"顶光↓",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			for i in range(3):
				var t:=Optics.tangent(s.angles[i])*sqrt(128.0); var c: Vector2=Optics.CENTERS[i]
				draw_line(p.call(c-t),p.call(c+t),blue if s.mounted[i] else Color("68717c"),4)
				draw_string(font,p.call(c)+Vector2(9,-9),"M%d %d°" % [i+1,s.angles[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
			var center: Vector2=p.call(Vector2(128,128)); draw_arc(center,16*scale_value,0,TAU,32,ink,2)
			var axis:=Optics.tangent(s.ring*45)
			for sign_value in [-1,1]: draw_circle(p.call(Vector2(128,128)+axis*16*sign_value),3,blue)
			draw_line(p.call(Vector2(224,110)),p.call(Vector2(224,148)),ink,2)
			draw_string(font,p.call(Vector2(230,125)),"接收面",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
			if not s.ray.is_empty() and not s.ray.glyphs.is_empty():
				for glyph in s.ray.glyphs:
					var world_point:=Vector2(glyph.position[0],glyph.position[1])/1000.0
					var up:=Vector2(glyph.up[0],glyph.up[1])/1000.0
					var glyph_angle:=Vector2(-up.y,up.x).angle()
					draw_set_transform(p.call(world_point),glyph_angle)
					draw_string(font,Vector2(-5,4),glyph.glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,11,gold)
					draw_set_transform(Vector2.ZERO)
				draw_string(font,p.call(Vector2(170,168)),"实际字模方向：正立" if s.ray.projected else "实际字模方向：偏转/倒置",HORIZONTAL_ALIGNMENT_LEFT,-1,11,gold)
	draw_string(font,Vector2(8,size.y-7),"有限教学示意；黄色为实际试动/光路，操作仍由规则层核验。",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
