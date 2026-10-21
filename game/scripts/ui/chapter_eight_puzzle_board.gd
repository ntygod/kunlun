extends Control
## Always visible teaching diagrams; all commands still go through the resolver.
signal cell_chosen(x:int,y:int)
signal day_chosen(day:int)
signal pool_chosen(pool:int)
var view:Dictionary={}
var _display_day:=0.0
var selected:="char_liang_xiao"
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
func render(value:Dictionary,selection:String="") -> void:
	view=value.duplicate(true);selected=selection;queue_redraw()
func _process(delta:float) -> void:
	if view.is_empty() or view.puzzle_id!="numbers_ch08_ranya" or view.state.problem!=0 or not is_visible_in_tree():return
	var target:float=float(view.state.day)
	if not is_equal_approx(_display_day,target):
		_display_day=move_toward(_display_day,target,delta*24.0);queue_redraw()
func _text(at:Vector2,text:String,color:Color=Color("eee6ce"),font_size:int=12) -> void:
	draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _grid_rect() -> Rect2:
	var unit:float=minf((size.x-8.0)/11.0,(size.y-83.0)/6.0)
	return Rect2(4,18,unit*11,unit*6)
func _gui_input(event:InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT or view.is_empty():return
	if view.puzzle_id=="dam_ch08_submerged":
		var rect:=_grid_rect()
		if rect.has_point(event.position):
			var unit:float=rect.size.x/11.0
			cell_chosen.emit(int((event.position.x-rect.position.x)/unit)-3,int((event.position.y-rect.position.y)/unit));accept_event()
	elif view.puzzle_id=="numbers_ch08_ranya":
		if view.state.problem==0 and event.position.y>=size.y-40:
			day_chosen.emit(clampi(roundi((event.position.x-10)/(size.x-20)*12),0,12));accept_event()
		elif view.state.problem==1:
			pool_chosen.emit(clampi(int(event.position.x/(size.x/3)),0,2));accept_event()
func _draw() -> void:
	if view.is_empty():return
	draw_style_box(get_theme_stylebox("panel","Panel"),Rect2(Vector2.ZERO,size))
	if view.puzzle_id=="dam_ch08_submerged":_dam()
	elif view.puzzle_id=="numbers_ch08_ranya":_numbers()
	else:_cannon()
func _dam() -> void:
	var rect:=_grid_rect();var unit:float=rect.size.x/11.0;var s:Dictionary=view.state
	_text(Vector2(4,12),"岸上工位 │ 浅滩0–3 │ 主流4–7",Color("eee6ce"),11)
	for x in range(-3,8):
		for y in range(6):
			var cell:=Rect2(rect.position+Vector2((x+3)*unit,y*unit),Vector2.ONE*unit)
			draw_rect(cell,Color("455b4b") if x<0 else (Color("3b6979") if x<4 else Color("28516d")))
			draw_rect(cell,Color("71939c"),false,0.5)
			if [x,y] in [[-2,1],[-2,4]]:draw_rect(cell.grow(-2),Color("333438"))
			if x==4:draw_line(cell.get_center()+Vector2(0,-4),cell.get_center()+Vector2(0,4),Color("a9d9ed"),1)
	for actor in view.stations:
		var point:Array=view.stations[actor];var pos:=rect.position+Vector2((point[0]+3)*unit,point[1]*unit)
		draw_rect(Rect2(pos+Vector2.ONE,Vector2.ONE*(unit-2)),Color("ebca75"),false,2)
	for boat in view.boat_targets:
		var target:Array=view.boat_targets[boat];var pos:=rect.position+Vector2((target[0]+3)*unit,target[1]*unit)
		var width:int=2 if boat=="wide" else 1
		draw_rect(Rect2(pos+Vector2.ONE,Vector2(unit*width-2,unit-2)),Color("d7c78d"),false,1.5)
		_text(pos+Vector2(2,unit-3),{"left":"左","middle":"中","wide":"宽位"}[boat],Color("d7c78d"),10)
	for kind in ["orders","boat_orders"]:
		for who in s[kind]:
			var start:Array=s.actors[who] if kind=="orders" else s.boats[who]
			var previous:=rect.position+Vector2((start[0]+3.5)*unit,(start[1]+0.5)*unit)
			for cell in s[kind][who]:
				var next:=rect.position+Vector2((cell[0]+3.5)*unit,(cell[1]+0.5)*unit)
				draw_line(previous,next,Color("f4d794"),1.5);previous=next
	for boat in s.boats:
		var point:Array=s.boats[boat];var pos:=rect.position+Vector2((point[0]+3)*unit,point[1]*unit)
		var width:int=2 if boat=="wide" else 1
		draw_rect(Rect2(pos+Vector2.ONE*2,Vector2(unit*width-4,unit-4)),Color("67594d") if s.sunk else Color("c39b62"))
		_text(pos+Vector2(3,unit-4),{"left":"左","middle":"中","wide":"宽"}[boat],Color.WHITE,11)
		if selected==boat:draw_rect(Rect2(pos,Vector2(unit*width,unit)),Color("fff4a2"),false,2)
	for actor in s.actors:
		var point:Array=s.actors[actor];var pos:=rect.position+Vector2((point[0]+3.5)*unit,(point[1]+0.5)*unit)
		draw_circle(pos,unit*0.40,Color("d9ba83") if actor==selected else Color("b99576"))
		_text(pos+Vector2(-6,4),{"char_liang_xiao":"梁","npc_ranya":"兰","npc_guo_shoujing":"郭"}[actor],Color("17262a"),12)
	if not s.wood.is_empty():
		var point:Array=s.wood;var pos:=rect.position+Vector2((point[0]+3.5)*unit,(point[1]+0.5)*unit)
		draw_circle(pos,4,Color("efb976"))
	var bottom:float=rect.end.y+14
	_text(Vector2(4,bottom),"宽%d格 / 流%d级 · 木深%d尺"%[view.width,view.velocity,view.depth],Color("eee6ce"),12)
	var y0:float=bottom+9;var scale:float=maxf(3,(size.y-y0-14)/8.0)
	draw_rect(Rect2(4,y0,size.x-8,8*scale),Color("213f55"))
	draw_rect(Rect2(4,y0,(size.x-8)*0.6,5*scale),Color(0.7,0.65,0.4,0.35))
	draw_line(Vector2(4,y0+5*scale),Vector2(size.x-4,y0+5*scale),Color("e3bb68"),1)
	draw_line(Vector2(4,y0+8*scale),Vector2(size.x-4,y0+8*scale),Color("999082"),2)
	draw_circle(Vector2(size.x*0.65,y0+int(view.depth)*scale),4,Color("fff0a6"))
	_text(Vector2(7,y0+11),"水面0 / 网底5 / 江底8尺",Color.WHITE,11)
func _numbers() -> void:
	var s:Dictionary=view.state;var problem:int=mini(s.problem,2)
	if problem==0:
		_text(Vector2(8,16),"七珠共同起点↑ · 当前%d日"%s.day)
		var center:=Vector2(size.x/2,(size.y-40)/2+10);var radius:float=minf(size.x/2-20,(size.y-65)/2)
		draw_arc(center,radius,0,TAU,48,Color("7093ab"),1)
		for i in range(7):
			var period:int=view.periods[i];var angle:float=fposmod(_display_day,float(period))/period*TAU-PI/2
			var at:Vector2=center+Vector2(cos(angle),sin(angle))*(radius-i*5)
			draw_circle(at,4,Color.from_hsv(float(i)/7,0.55,1))
		_text(center+Vector2(-30,5),"2 3 4 2 3 4 6",Color.WHITE,11)
		for day in range(13):
			var x:float=10+(size.x-20)*day/12.0
			draw_line(Vector2(x,size.y-28),Vector2(x,size.y-20),Color.WHITE)
			_text(Vector2(x-4,size.y-5),str(day),Color("ffe69a") if day==s.day else Color.WHITE,11)
	elif problem==1:
		_text(Vector2(8,16),"三池等容4筹 · 总水6筹")
		for i in range(3):
			var rect:=Rect2(i*size.x/3+10,35,size.x/3-20,size.y-65)
			draw_rect(rect,Color("66828c"),false,2)
			var fill:=rect;fill.size.y=rect.size.y*s.pools[i]/4.0;fill.position.y=rect.end.y-fill.size.y
			draw_rect(fill,Color("4198b8"))
			_text(Vector2(rect.position.x,rect.end.y+18),["A","B","C"][i]+"：%d筹"%s.pools[i])
	else:
		_text(Vector2(8,16),"12尺木料：两腿 + 四根1尺档")
		var x1:float=size.x*0.28;var x2:float=size.x*0.68;var y0:float=35;var h:float=(size.y-65)*s.leg/6.0
		for x in [x1,x2]:draw_line(Vector2(x,y0),Vector2(x,y0+h),Color("d2a064"),5)
		for i in range(4):draw_line(Vector2(x1,y0+h*(i+1)/5),Vector2(x2,y0+h*(i+1)/5),Color("d2a064"),3)
		_text(Vector2(8,size.y-12),"腿各%d尺 · 余料%d尺"%[s.leg,8-2*s.leg],Color("ffac94") if s.leg>4 else Color.WHITE)
func _cannon() -> void:
	var p:Dictionary=view.plan;var y:float=size.y-35;var scale:float=(size.x-28)/31.0
	_text(Vector2(8,16),"模拟靶板 · "+("已试" if not view.state.trials.is_empty() else "参数预览"))
	draw_line(Vector2(12,y),Vector2(size.x-8,y),Color("a8b3ad"),2)
	draw_line(Vector2(12,y+8),Vector2(12+21*scale,y+8),Color("c9847f"),2)
	_text(Vector2(12,y+23),"敌弩射程21 / 靶22格",Color("f3c3ba"),11)
	for mark in [0,10,22]:
		var x:float=12+mark*scale;draw_line(Vector2(x,y-7),Vector2(x,y+3),Color.WHITE,2)
		_text(Vector2(x-5,y-10),str(mark))
	var origin:=Vector2(12+p.origin*scale,y-6);var end:=Vector2(12+p.landing*scale,y-6)
	var last:Vector2=origin
	for i in range(1,25):
		var t:float=i/24.0;var point:Vector2=origin.lerp(end,t)+Vector2(0,-sin(t*PI)*(size.y-95))
		draw_line(last,point,Color("e2c884"),2);last=point
	draw_circle(end,4,Color("ffe99e"))
	_text(Vector2(8,34),"%s弹 / 配重%d / %d°"%["轻3" if p.ammo=="light" else "重5",p.weight,p.angle])
	_text(Vector2(8,51),"射程%d + 炮位%d = 落点%d"%[p.range,p.origin,p.landing])
