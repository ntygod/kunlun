class_name GeometryGuide
extends Control
## Hand-authored instructional line diagram, not a scale map or finished pixel art.
var method := "double_difference"
func _ready() -> void:
	custom_minimum_size = Vector2(240,150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var ink := Color("dacda3")
	var guide := Color("7ebbc0")
	var ground := size.y-27.0
	var width := maxf(240,size.x)
	var font := get_theme_default_font()
	draw_string(font,Vector2(5,17),"几何参考线（示意，不按比例）",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	if method == "volume":
		var a := Vector2(width*0.22,ground-20)
		var b := Vector2(width*0.64,ground-20)
		var c := Vector2(width*0.64,ground-55)
		var d := Vector2(width*0.22,ground-55)
		var offset := Vector2(width*0.12,-20)
		for edge in [[a,b],[b,c],[c,d],[d,a],[d,d+offset],[c,c+offset],[b,b+offset],[d+offset,c+offset],[c+offset,b+offset]]: draw_line(edge[0],edge[1],guide,2)
		draw_dashed_line(a,a+offset,guide,1,4)
		draw_dashed_line(a+offset,b+offset,guide,1,4)
		draw_string(font,Vector2(width*0.22,ground+5),"长12尺 × 宽3尺 × 深2尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	elif method == "scale":
		var center := Vector2(width*0.3,ground-38)
		draw_arc(center,36,0,TAU,48,guide,2)
		draw_line(center,center+Vector2(36,0),ink,2)
		draw_line(center,center+Vector2(36,0).rotated(-PI/6),ink,2)
		draw_string(font,Vector2(width*0.49,65),"模型：3度 ↔ 300里",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,Vector2(width*0.49,89),"同一比例延至360度",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	elif method == "similar_triangles":
		var a := Vector2(width*0.08,ground)
		var b := Vector2(width*0.08,ground-45)
		var c := Vector2(width*0.35,ground)
		var d := Vector2(width*0.52,ground)
		var e := Vector2(width*0.52,ground-76)
		var f := Vector2(width*0.94,ground)
		for pair in [[a,b],[a,c],[b,c],[d,e],[d,f],[e,f]]: draw_line(pair[0],pair[1],guide,2)
		draw_string(font,b+Vector2(3,-5),"表高8尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,a+Vector2(0,20),"杆影4尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,e+Vector2(3,-5),"同一峰高H",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,d+Vector2(0,20),"标定模型峰影404尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	else:
		var peak := Vector2(width*0.06,35)
		var front := Vector2(width*0.40,ground)
		var rear := Vector2(width*0.57,ground)
		var front_top := front-Vector2(0,18)
		var rear_top := rear-Vector2(0,18)
		draw_line(Vector2(width*0.06,ground),Vector2(width*0.96,ground),ink,2)
		draw_line(Vector2(peak.x,ground),peak,ink,2)
		draw_line(front,front_top,ink,3); draw_line(rear,rear_top,ink,3)
		# Extend each peak-to-rod-top ray to the same ground plane.
		# The schematic may compress scale, but a sight line must never bend.
		var front_observer := sight_observer(peak,front_top,ground)
		var rear_observer := sight_observer(peak,rear_top,ground)
		draw_dashed_line(peak,front_observer,guide,1,5)
		draw_dashed_line(peak,rear_observer,guide,1,5)
		draw_circle(front_observer,3,guide)
		draw_circle(rear_observer,3,guide)
		draw_string(font,peak+Vector2(4,0),"峰高H",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,front_top+Vector2(-12,-6),"8尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,rear_top+Vector2(-12,-6),"8尺",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
		draw_string(font,Vector2(width*0.38,ground+20),"间距600尺；退距12 / 18尺",HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)

static func sight_observer(peak: Vector2, rod_top: Vector2, ground_y: float) -> Vector2:
	var ray := rod_top-peak
	if is_zero_approx(ray.y): return Vector2(rod_top.x,ground_y)
	return peak+ray*((ground_y-peak.y)/ray.y)
