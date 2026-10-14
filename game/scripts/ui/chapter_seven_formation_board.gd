extends Control
## Presentation only: ghost positions never mutate the authoritative formation.
signal cell_chosen(x: int, y: int)
const NAMES := ["梁", "土", "囊", "李", "杨", "王"]
const VECTORS := {"N": Vector2(0,-1), "E": Vector2(1,0), "S": Vector2(0,1), "W": Vector2(-1,0)}
var positions: Array = []
var directions: Array = []
var targets: Array = []
var center: Array = [0,0]
var selected := 0
var locked := false
var cursor := Vector2i.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(198,198)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

func render(view: Dictionary, selection: int, busy: bool) -> void:
	var state: Dictionary = view.get("state",{})
	positions = state.get("positions",[])
	directions = state.get("directions",[])
	targets = view.get("target_positions",[])
	center = state.get("center",[0,0])
	selected = selection
	locked = busy
	queue_redraw()

func _cell_size() -> float:
	return minf(size.x,size.y)/11.0

func _point(p: Array) -> Vector2:
	return Vector2(float(p[0])+5.5,float(p[1])+5.5)*_cell_size()

func _draw() -> void:
	var step := _cell_size()
	var extent := step*11
	draw_rect(Rect2(Vector2.ZERO,Vector2(extent,extent)),Color("17242b"))
	for i in range(12):
		draw_line(Vector2(i*step,0),Vector2(i*step,extent),Color("40525a"))
		draw_line(Vector2(0,i*step),Vector2(extent,i*step),Color("40525a"))
	var font := get_theme_default_font()
	for i in range(targets.size()):
		var p := _point(targets[i])
		draw_rect(Rect2(p-Vector2.ONE*step*0.42,Vector2.ONE*step*0.84),Color("8d9b75"),false,1)
		if targets[i] not in positions:
			var ghost_font:=clampi(int(step*0.55),9,18)
			draw_string(font,p+Vector2(-ghost_font*0.5,ghost_font*0.35),NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,ghost_font,Color("a8b68b"))
	var middle := _point(center)
	draw_line(middle-Vector2(4,0),middle+Vector2(4,0),Color("efc367"),2)
	draw_line(middle-Vector2(0,4),middle+Vector2(0,4),Color("efc367"),2)
	for i in range(positions.size()):
		var p := _point(positions[i])
		draw_circle(p,step*0.43,Color("d9ac60") if i==selected else Color("79adb3"))
		var token_font:=clampi(int(step*0.45),8,16)
		draw_string(font,p+Vector2(-step*0.39,step*0.35),NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,token_font,Color("102127"))
		if i<directions.size():
			var direction: Vector2 = VECTORS.get(directions[i],Vector2.ZERO)
			# Name occupies the lower-left; a small compass occupies upper-right.
			# Their rectangles remain disjoint even at the 18px compact cell size.
			var compass:=p+Vector2(step*0.28,-step*0.28)
			var arrow_length:=step*0.16
			var tip := compass+direction*arrow_length
			draw_line(compass-direction*arrow_length,tip,Color("102127"),1.5)
			draw_line(tip,tip-direction.rotated(0.65)*arrow_length,Color("102127"),1.5)
			draw_line(tip,tip-direction.rotated(-0.65)*arrow_length,Color("102127"),1.5)
	if has_focus():
		draw_rect(Rect2(_point([cursor.x,cursor.y])-Vector2.ONE*step*0.48,Vector2.ONE*step*0.96),Color.WHITE,false,1)

func _gui_input(event: InputEvent) -> void:
	if locked: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p: Vector2 = event.position/_cell_size()
		if p.x>=0 and p.y>=0 and p.x<11 and p.y<11:
			cursor=Vector2i(int(p.x)-5,int(p.y)-5)
			grab_focus()
			cell_chosen.emit(cursor.x,cursor.y)
			accept_event()
	if event is InputEventKey and event.pressed:
		var handled := true
		match event.keycode:
			KEY_UP: cursor.y=maxi(-5,cursor.y-1)
			KEY_RIGHT: cursor.x=mini(5,cursor.x+1)
			KEY_DOWN: cursor.y=mini(5,cursor.y+1)
			KEY_LEFT: cursor.x=maxi(-5,cursor.x-1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: cell_chosen.emit(cursor.x,cursor.y)
			_: handled=false
		if handled:
			queue_redraw()
			accept_event()

func _get_tooltip(at_position: Vector2) -> String:
	var cell:=Vector2i(at_position/_cell_size())-Vector2i(5,5)
	var coordinate:Array=[cell.x,cell.y]
	var occupant:=positions.find(coordinate)
	var target:=targets.find(coordinate)
	return "(%d,%d) %s%s" % [cell.x,cell.y,(NAMES[occupant]+" 面"+str(directions[occupant])) if occupant>=0 else "空格",("；目标位："+NAMES[target]) if target>=0 else ""]
