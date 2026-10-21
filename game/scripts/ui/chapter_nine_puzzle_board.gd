extends Control
## Teaching schematic, not finished pixel artwork. The resolver owns all movement.
signal cell_chosen(x:int,y:int)
const PINE_PATH:=[[4,4],[4,3],[3,3],[3,2],[2,2],[2,1],[1,1],[1,0],[0,0]]
var view:Dictionary={}
var selected:="start"
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
func render(value:Dictionary,selection:String="") -> void:
	view=value.duplicate(true);selected=selection;queue_redraw()
func _pine() -> bool:return str(view.get("puzzle_id","")).contains("pine")
func _grid_rect() -> Rect2:
	var columns:int=5 if _pine() else 9
	var rows:int=5 if _pine() else 7
	var unit:float=maxf(1,minf((size.x-12)/columns,(size.y-42)/rows))
	return Rect2(Vector2((size.x-unit*columns)/2,23),Vector2(columns,rows)*unit)
func _gui_input(event:InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT or view.is_empty():return
	var rect:=_grid_rect()
	if rect.has_point(event.position):
		var unit:float=rect.size.x/(5 if _pine() else 9)
		cell_chosen.emit(int((event.position.x-rect.position.x)/unit),int((event.position.y-rect.position.y)/unit));accept_event()
func _text(at:Vector2,value:String,color:Color=Color("eee6ce"),font_size:int=12) -> void:
	draw_string(get_theme_default_font(),at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _center(point:Array,rect:Rect2,unit:float) -> Vector2:return rect.position+(Vector2(point[0],point[1])+Vector2.ONE*0.5)*unit
func _draw() -> void:
	if view.is_empty():return
	draw_rect(Rect2(Vector2.ZERO,size),Color("1b2d32"))
	var rect:=_grid_rect();var pine:bool=_pine();var columns:int=5 if pine else 9;var rows:int=5 if pine else 7;var unit:float=rect.size.x/columns
	var s:Dictionary=view.get("state",{})
	_text(Vector2(5,15),"松针教学盘 · 点格摆针/走一步" if pine else "施工教学图 · 点人物，再点目标",Color("eee6ce"),11)
	for x in range(columns):
		for y in range(rows):
			var cell:=Rect2(rect.position+Vector2(x,y)*unit,Vector2.ONE*unit)
			var open:bool=not pine or [x,y] in PINE_PATH
			draw_rect(cell,Color("42594b") if open else Color("333c40"));draw_rect(cell,Color("6d827c"),false,1)
			if not open:_text(cell.position+Vector2(2,unit-3),"旗",Color("8c9995"),11)
	if pine:
		for i in range(1,PINE_PATH.size()):draw_line(_center(PINE_PATH[i-1],rect,unit),_center(PINE_PATH[i],rect,unit),Color("9cba90"),2)
		for pin in ["start","middle","end"]:
			var point:Array={"start":[4,4],"middle":[2,2],"end":[0,0]}[pin]
			var center:=_center(point,rect,unit)
			draw_rect(Rect2(center-Vector2.ONE*unit*0.46,Vector2.ONE*unit*0.92),Color("e1c477"),false,2)
			_text(center+Vector2(-unit*0.43,-unit*0.18),{"start":"生0","middle":"景1","end":"眼2"}[pin],Color("ffdf8d"),11)
			var placed:Array=s.get("pins",{}).get(pin,[])
			if placed.size()==2:
				var at:=_center(placed,rect,unit)+Vector2(0,unit*0.20)
				draw_line(at+Vector2(-6,0),at+Vector2(6,0),Color("f3e6ac"),3)
				_text(at+Vector2(-6,11),{"start":"生","middle":"景","end":"眼"}[pin],Color.WHITE,10)
		var cursor:int=int(s.get("cursor",-1))
		if cursor>=0 and cursor<PINE_PATH.size():draw_circle(_center(PINE_PATH[cursor],rect,unit),4,Color("f49c70"))
		if cursor+1<PINE_PATH.size():draw_arc(_center(PINE_PATH[cursor+1],rect,unit),unit*0.4,0,TAU,24,Color("f2edbd"),2)
		_text(Vector2(5,rect.end.y+14),"黄框门窗 · 圆圈下一格 · 橙点领阵",Color("eee6ce"),11)
	else:
		var stations:Dictionary=view.get("stations",{"char_liang_xiao":[3,2],"char_axue":[5,2]})
		for actor in stations:
			var at:=_center(stations[actor],rect,unit)
			draw_rect(Rect2(at-Vector2.ONE*unit*0.45,Vector2.ONE*unit*0.9),Color("e2c77a"),false,2)
			_text(at+Vector2(-10,-unit*0.5-2),"翼轴" if actor=="char_liang_xiao" else "尾架",Color("e2c77a"),10)
		var rail:Array=view.get("rail",[[4,3],[5,3],[6,3],[7,3],[8,3]])
		for i in range(1,rail.size()):draw_line(_center(rail[i-1],rect,unit),_center(rail[i],rect,unit),Color("c49b6d"),4)
		for actor in s.get("actors",{}):
			var at:=_center(s.actors[actor],rect,unit)
			for point in s.get("orders",{}).get(actor,[]):
				var next:=_center(point,rect,unit);draw_line(at,next,Color("efdc9e"),2);at=next
			at=_center(s.actors[actor],rect,unit)
			if actor in s.get("passengers",[]):
				at=_center(rail[clampi(int(s.get("rail_index",0)),0,rail.size()-1)],rect,unit)+Vector2(-unit*0.22 if actor=="char_liang_xiao" else unit*0.22,-unit*0.35)
			draw_circle(at,unit*0.4,Color("efce8a") if actor==selected else Color("b9cddd"))
			_text(at+Vector2(-6,4),"梁" if actor=="char_liang_xiao" else "雪",Color("182b30"),12)
		if str(s.get("stage","")) not in ["collecting","assembling"]:
			var index:int=clampi(int(s.get("rail_index",0)),0,rail.size()-1)
			var at:=_center(rail[index],rect,unit)
			draw_line(at+Vector2(-unit,0),at+Vector2(unit,0),Color("e5ac67"),3);draw_circle(at,4,Color("f3d49b"))
		_text(Vector2(5,rect.end.y+14),"黄框工作位 · 线为待走路径/滑轨",Color("eee6ce"),11)
