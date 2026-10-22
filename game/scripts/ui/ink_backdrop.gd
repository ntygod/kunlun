extends Control
## Original vector title ornament, not final pixel scenery. No random noise or moving text.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _ridge(points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in points: polygon.append(Vector2(float(point[0])*size.x, float(point[1])*size.y))
	draw_colored_polygon(polygon, color)
func _draw() -> void:
	if size.x < 1 or size.y < 1: return
	draw_rect(Rect2(Vector2.ZERO, size), Color("101f25"))
	var moon := Vector2(size.x*0.34, size.y*0.26)
	draw_circle(moon, minf(size.x, size.y)*0.075, Color("cfbf92"))
	draw_circle(moon, minf(size.x, size.y)*0.066, Color("d6caa8"))
	_ridge([[0,0.55],[0.09,0.48],[0.18,0.54],[0.28,0.34],[0.33,0.4],[0.38,0.37],[0.48,0.57],[0.55,0.47],[0.67,0.6],[0.78,0.4],[0.88,0.53],[1,0.45],[1,1],[0,1]],Color("2b4145"))
	_ridge([[0,0.67],[0.07,0.56],[0.14,0.61],[0.24,0.49],[0.31,0.55],[0.36,0.54],[0.46,0.69],[0.57,0.55],[0.66,0.63],[0.8,0.5],[0.9,0.61],[1,0.58],[1,1],[0,1]],Color("23393d"))
	_ridge([[0,0.78],[0.13,0.68],[0.21,0.75],[0.3,0.69],[0.4,0.79],[0.54,0.67],[0.63,0.72],[0.75,0.65],[0.86,0.72],[1,0.69],[1,1],[0,1]],Color("1b3035"))
	_ridge([[0,0.93],[0.13,0.84],[0.2,0.88],[0.33,0.82],[0.46,0.92],[0.61,0.8],[0.76,0.89],[0.88,0.82],[1,0.86],[1,1],[0,1]],Color("14262c"))
	for line in [[0.12,0.78,0.28],[0.18,0.81,0.36],[0.09,0.84,0.24],[0.27,0.87,0.43]]:
		draw_line(Vector2(size.x*line[0],size.y*line[1]),Vector2(size.x*line[2],size.y*line[1]),Color("405452"),1)
	var inset := 14.0 if size.x < 900 else 28.0
	draw_rect(Rect2(Vector2(inset,inset),size-Vector2.ONE*inset*2),Color("667260"),false,1)
	for x in [inset, size.x-inset]:
		var direction := 1.0 if x == inset else -1.0
		draw_line(Vector2(x,inset),Vector2(x+28*direction,inset),Color("c5ac74"),2)
		draw_line(Vector2(x,size.y-inset),Vector2(x+28*direction,size.y-inset),Color("c5ac74"),2)
