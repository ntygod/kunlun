extends Control
var _view:Dictionary={}
func render(view:Dictionary,_selection:int=0)->void:_view=view.duplicate(true);queue_redraw()
func _draw()->void:
	if _view.is_empty():return
	var font:=get_theme_default_font();var s:Dictionary=_view.state
	draw_style_box(get_theme_stylebox("panel","Panel"),Rect2(Vector2.ZERO,size))
	if _view.puzzle_id=="pz_ch11_meridian_channels":
		var unit:float=minf((size.x-30)/4,(size.y-50)/3);var origin:=Vector2(15,30)
		for x in range(4):
			for y in range(3):draw_rect(Rect2(origin+Vector2(x,y)*unit,Vector2.ONE*unit),Color("49676a"),false)
		var nodes:Array=[Vector2(1,1),Vector2(1,0),Vector2(2,0)]
		for i in range(3):
			var at:Vector2=origin+(nodes[i]+Vector2.ONE*0.5)*unit
			draw_circle(at,unit*0.3,Color("a9d9e1") if s.polarity[i]==0 else Color("e9b767"))
			draw_string(font,at+Vector2(-8,5),["—","/","\\"][s.rotations[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.BLACK)
		var path:Array=s.flow if not s.flow.is_empty() else _view.preview.path
		for i in range(1,path.size()):draw_line(origin+(Vector2(path[i-1][0],path[i-1][1])+Vector2.ONE*0.5)*unit,origin+(Vector2(path[i][0],path[i][1])+Vector2.ONE*0.5)*unit,Color("76db98"),3)
		draw_string(font,Vector2(10,18),"阴入 → 三节 → 阳出",HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	else:
		var y:float=25
		var index:=0
		for target in _view.observations:
			var seen:bool=target in s.observed
			draw_circle(Vector2(20,y-4),6,Color("76db98") if seen else Color("596e78"))
			draw_string(font,Vector2(33,y),_view.labels[index],HORIZONTAL_ALIGNMENT_LEFT,-1,13)
			y+=26;index+=1
		var total:int=maxi(1,_view.progress_total)
		for i in range(total):draw_rect(Rect2(12+i*minf(20,(size.x-24)/total),115,15,12),Color("e9b767") if i<s.stage else Color("334b53"))
		draw_string(font,Vector2(12,150),"晓霜主诊 · 梁萧依嘱",HORIZONTAL_ALIGNMENT_LEFT,-1,13)
