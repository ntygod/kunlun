extends Control
signal slot_chosen(slot:int)
var _view:Dictionary={}
var _selected:=-1
func render(view:Dictionary,selection:int=-1)->void:_view=view.duplicate(true);_selected=selection;queue_redraw()
func point(slot:int)->Vector2:return size*0.5+Vector2.from_angle(-PI/2+slot*TAU/5)*minf(size.x,size.y)*0.32
func _gui_input(event:InputEvent)->void:
	if _view.get("puzzle_id","")!="pz_ch12_reverse_five_phases":return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		for i in range(5):
			if event.position.distance_to(point(i))<22:slot_chosen.emit(i);accept_event();return
func _draw()->void:
	if _view.is_empty():return
	var font:=get_theme_default_font();var s:Dictionary=_view.state
	draw_rect(Rect2(Vector2.ZERO,size),Color("20383c"))
	match _view.puzzle_id:
		"pz_ch12_reverse_five_phases":
			for i in range(5):
				draw_line(point(i),point((i+1)%5),Color("557475"),2)
				draw_circle(point(i),19,Color("dda959") if i==_selected else Color("43696e"))
				draw_string(font,point(i)+Vector2(-12,5),["木","火","土","金","水"][s.slots[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
			var path:Array=s.flow if not s.flow.is_empty() else _view.preview.path
			for i in range(1,path.size()):draw_line(point(path[i-1]),point(path[i]),Color("86dfbe"),4)
			draw_string(font,Vector2(8,18),"%s · 已引%d/3股"%["逆向" if s.reverse else "顺向",s.pulses],HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		"pz_ch12_r05_rescue":
			var unit:float=(size.x-30)/5
			draw_rect(Rect2(10,size.y-25,size.x-40,15),Color("71674c"))
			draw_rect(Rect2(size.x-30,size.y-70,25,70),Color("101a25"))
			var height:float=size.y-75-s.height*22
			draw_rect(Rect2(30,height,size.x-85,28),Color("8b9198"))
			draw_line(Vector2(15+s.support*unit,size.y-25),Vector2(15+s.support*unit,height+28),Color("e5bb7a"),9)
			draw_circle(Vector2(size.x*0.45,size.y-36),8,Color("81cea9") if s.rescued else Color("d28d70"))
			draw_string(font,Vector2(8,18),"抬高%d/2 · %s"%[s.height,"刀已折" if s.blade_broken else "只护人"],HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		"pz_ch12_care_visits":
			draw_string(font,Vector2(12,25),"第%d日 · 四次探视"%_view.day,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
			for i in range(4):
				var at:=Vector2(24+i*(size.x-48)/3,65)
				draw_circle(at,10,Color("87ceb1") if [1,14,30,60][i] in s.visits else Color("546e74"))
				draw_string(font,at+Vector2(-8,30),str([1,14,30,60][i]),HORIZONTAL_ALIGNMENT_LEFT,-1,13)
			draw_string(font,Vector2(12,130),"本日照护 %d/3 · 非免费恢复"%s.care.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,12)
		_:
			var y:=30
			for item in ["water","blanket","cloth"]:
				draw_string(font,Vector2(12,y),"%s 剩余%d"%[{"water":"水","blanket":"毯","cloth":"布"}[item],s.supplies[item]],HORIZONTAL_ALIGNMENT_LEFT,-1,16);y+=35
			draw_string(font,Vector2(12,y),"已按需分配 %d/4"%s.stage,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
