extends Control
## Diagram of a finite mechanic, not final world or character art.
signal cell_chosen(x:int,y:int)
var view:Dictionary={}
var selected:=0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;resized.connect(queue_redraw)
func render(value:Dictionary,selection:int=0)->void:view=value.duplicate(true);selected=selection;queue_redraw()
func _ox()->bool:return view.get("puzzle_id","")=="pz_ch10_wooden_ox"
func grid_rect()->Rect2:
	var unit:float=maxf(1,minf((size.x-12)/7,(size.y-48)/5))
	return Rect2(Vector2((size.x-unit*7)/2,24),Vector2(7,5)*unit)
func _center(cell:Array,r:Rect2)->Vector2:return r.position+(Vector2(cell[0],cell[1])+Vector2.ONE*0.5)*(r.size.x/7)
func _text(at:Vector2,text:String,color:Color=Color("eee6ce"),font_size:int=12)->void:draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not view.is_empty():
		var r:Rect2=grid_rect()
		if r.has_point(event.position):
			cell_chosen.emit(int((event.position.x-r.position.x)/(r.size.x/7)),int((event.position.y-r.position.y)/(r.size.x/7)));accept_event()
func _draw()->void:
	if view.is_empty():return
	draw_rect(Rect2(Vector2.ZERO,size),Color("192c30"));var s:Dictionary=view.state;var r:Rect2=grid_rect();var unit:float=r.size.x/7
	if _ox():
		_text(Vector2(6,15),"木牛负载示意 · 两包守恒",Color("e7d0a2"),11)
		var axle:=Vector2(r.get_center().x,r.position.y+unit*2)
		draw_line(axle-Vector2(unit*3,0),axle+Vector2(unit*3,0),Color("b28a5b"),6)
		draw_colored_polygon(PackedVector2Array([axle,axle+Vector2(-10,22),axle+Vector2(10,22)]),Color("c9bd96"))
		for position in [-3,-2,-1,1,2,3]:
			var at:=axle+Vector2(position*unit,0);draw_line(at+Vector2(0,-4),at+Vector2(0,6),Color("f5dfb3"),1);_text(at+Vector2(-5,18),str(position),Color("d4d8c7"),10)
		for bundle in ["light","heavy"]:
			var at:=axle+Vector2(s.cargo[bundle]*unit,-15)
			draw_rect(Rect2(at-Vector2(9,9),Vector2(18,18)),Color("85a9a1") if bundle=="light" else Color("d4ae71"))
			_text(at+Vector2(-4,4),"2" if bundle=="light" else "3",Color("18292d"),12)
		for side in ["left","right"]:
			var at:=Vector2(r.position.x+unit*(1.5 if side=="left" else 5.5),r.end.y-unit*0.7)
			draw_arc(at,unit*0.55,0,TAU,24,Color("9bb1aa"),2)
			var angle:float=float(s[side+"_phase"])*PI/2-PI/2
			draw_line(at,at+Vector2(cos(angle),sin(angle))*unit*0.5,Color("f0ca81"),3)
			_text(at+Vector2(-10,unit*0.85),"左" if side=="left" else "右",Color("d3dfd5"),11)
		for i in range(3):draw_rect(Rect2(Vector2(axle.x+(i-1)*16,r.end.y-unit),Vector2(10,15)),Color("b7d5a6") if i<s.steps else Color("405259"))
		_text(Vector2(6,r.end.y+18),"黄针曲柄 · 中轴配重 · 下方三步",Color("cad3ca"),10)
	else:
		_text(Vector2(6,15),"石阵引势图 · 点格移选中阵石",Color("e7d0a2"),11)
		for x in range(7):
			for y in range(5):
				var cell:=Rect2(r.position+Vector2(x,y)*unit,Vector2.ONE*unit)
				draw_rect(cell,Color("3e534b") if x==6 else Color("293b40"));draw_rect(cell,Color("51676a"),false,1)
		for lane in [1,2,3]:_text(_center([0,lane],r)+Vector2(-unit*0.35,4),str(lane)+"→",Color("d8bc89"),10)
		var path:Array=view.get("preview",{}).get("path",[])
		for i in range(1,path.size()):draw_line(_center(path[i-1],r),_center(path[i],r),Color("71b8be"),2)
		if s.awaiting_breath or s.complete:
			path=s.last_trace
			for i in range(1,path.size()):draw_line(_center(path[i-1],r),_center(path[i],r),Color("eac979"),3)
		for i in range(3):
			var at:=_center([i+2,s.rows[i]],r);var d:=unit*0.31
			draw_circle(at,unit*0.42,Color("9b997e") if i==selected else Color("67766d"))
			draw_line(at+Vector2(-d,d if s.turns[i]=="/" else -d),at+Vector2(d,-d if s.turns[i]=="/" else d),Color("f3e5c7"),3)
			_text(at+Vector2(-4,-unit*0.43),["甲","乙","丙"][i],Color("f3e5c7"),11)
		_text(_center([6,2],r)+Vector2(-unit*0.42,4),"调息",Color("bfd1a7"),10)
		_text(Vector2(6,r.end.y+18),"青线预演 · 金线实势 · 右岸须避开",Color("cad3ca"),10)
