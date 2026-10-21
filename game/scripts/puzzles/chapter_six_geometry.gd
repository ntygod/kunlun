extends Control
## Diagrams explain the finite models; no world collision or state mutation.
const R=preload("res://scripts/puzzles/chapter_six_puzzle_resolver.gd")
var view:Dictionary={}
func _ready() -> void:
	custom_minimum_size=Vector2(260,225);mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func render(v:Dictionary) -> void:view=v.duplicate(true);queue_redraw()
func _text(p:Vector2,t:String,color:Color=Color("#e6ddbf"),font_size:int=14) -> void:
	draw_string(get_theme_default_font(),p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw() -> void:
	if view.is_empty():return
	draw_style_box(get_theme_stylebox("panel","Panel"),Rect2(Vector2.ZERO,size))
	var s:Dictionary=view.state
	match view.puzzle_id:
		"stars_ch06_sword":
			var center:=Vector2(size.x/2,110);var scale:=32.0
			draw_circle(center,64,Color("#536780"),false,2)
			draw_line(center+Vector2(-90,0),center+Vector2(90,0),Color("#7a8b90"))
			draw_line(center+Vector2(0,-90),center+Vector2(0,90),Color("#7a8b90"))
			for i in range(3):
				var point:=center+Vector2(R.STARS[i][0],-R.STARS[i][1])*scale
				draw_circle(point,5,Color("#edca62"));_text(point+Vector2(7,-5),"%d拍 %s" % [i+1,str(R.STARS[i])])
				if i<s.sword_vectors.size():
					var v:Array=s.sword_vectors[i];var target:=point+Vector2(v[0],-v[1])*22
					draw_line(point,target,Color("#7ae1aa"),3);draw_circle(target,4,Color("#7ae1aa"))
			_text(Vector2(10,218),"图上x向右、y向上；圆周逆时针，绿线为已验剑向。")
		"array_ch06_steps":
			var left:=Vector2(maxf(4,(size.x-224)/2),10)
			for i in range(16):
				var p:=left+Vector2(i%4,i/4)*48
				draw_rect(Rect2(p,Vector2(46,46)),Color("#668f87") if s.position==i else Color("#293c48"))
				_text(p+Vector2(5,13),str(i),Color("#a5b8bf"),11);_text(p+Vector2(15,35),str(R.SQUARE[i]),Color("#ffe1a3"),19)
			var n:int=mini(9,s.steps.size());var line:Array=R.LINES[n]
			for i in range(3):
				var a:=left+Vector2(line[i]%4,line[i]/4)*48+Vector2(23,23)
				var b:=left+Vector2(line[i+1]%4,line[i+1]/4)*48+Vector2(23,23)
				draw_line(a,b,Color(0.8,0.5,0.2,0.5),3)
			_text(Vector2(6,218),"小字是格号，大字是数；亮线%d末格%d为本步目标。" % [n,line[3]])
		"basket_ch06_weave","r03":
			var left:=Vector2(maxf(8,(size.x-240)/2),12)
			for row in range(6):
				for col in range(6):
					var p:=left+Vector2(col*38,row*29)
					var woven:bool=row<s.patterns.size()
					var over:bool=woven and (int(s.patterns[row])&(1<<col))!=0
					draw_rect(Rect2(p,Vector2(32,24)),Color("#c2a46c") if over else (Color("#735536") if woven else Color("#34464d")))
					if woven:_text(p+Vector2(10,17),"上" if over else "下",Color("#ffffff"),12)
			_text(Vector2(8,213),"编入%d/6行：亮格跨经上，暗格穿经下，相邻行反扣。" % s.woven.size())
		"l02":
			_text(Vector2(10,24),"原料去向：两松木 → 四件柄料 → 两副犁柄")
			for i in range(2):
				var y:=55+i*40
				draw_rect(Rect2(Vector2(18,y),Vector2(160,22)),Color("#997953"))
				if i in s.cut:draw_line(Vector2(98,y-2),Vector2(98,y+24),Color("#fff3ce"),3)
				_text(Vector2(188,y+17),"已切2+2" if i in s.cut else "原长4")
			for i in range(3):
				var job:String=["waterwheel","cart","plough"][i];var name:String=["水车","推车","犁柄"][i]
				_text(Vector2(14+i*maxf(82,size.x/3),160),name)
				_text(Vector2(14+i*maxf(82,size.x/3),185),"实测%d/3" % s.tests.get(job,0),Color("#a8dfba"))
			_text(Vector2(8,218),"水车复套管/铁箍；推车复柳销/牛皮；松木不作新轴。")
