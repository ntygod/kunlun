extends Control
## Read-only schematic; scene art remains separately tracked development work.
var view:Dictionary={}
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func render(value:Dictionary)->void:view=value.duplicate(true);queue_redraw()
func _text(at:Vector2,text:String,size_px:int=14)->void:
 draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,Color("e8dfc7"))
func _draw()->void:
 if view.is_empty():return
 var s:Dictionary=view.state
 var w:float=size.x;var h:float=size.y
 draw_rect(Rect2(Vector2.ZERO,size),Color("12272d"))
 match view.puzzle_id:
  "pz_ch16_river":
   _text(Vector2(12,24),"来水十成")
   draw_line(Vector2(w*.5,34),Vector2(w*.5,58),Color("76aaa6"),7)
   for i in range(3):
    var x:float=30+i*(w-60)/2
    draw_line(Vector2(w*.5,58),Vector2(x,h-50),Color("39696d"),6)
    draw_rect(Rect2(x-16,h-70,32,8),Color("bd9f68"))
    _text(Vector2(x-23,h-20),["北","中","南"][i]+" "+str(s.gates[i]))
   if s.overflow:draw_line(Vector2(w*.5,h-68),Vector2(w-10,h-82),Color("7fb8a0"),4)
   _text(Vector2(12,44),"旧渠："+("接通" if s.overflow else "未接"),12)
  "pz_ch16_scale":
   var y:float=h*.44
   draw_line(Vector2(w*.5,32),Vector2(w*.5,h-22),Color("bd9f68"),5)
   draw_line(Vector2(30,y),Vector2(w-30,y),Color("bd9f68"),3)
   for x in [40,w-40]:
    draw_line(Vector2(x,y),Vector2(x,y+24),Color("8a8067"),2)
    draw_rect(Rect2(x-24,y+24,48,5),Color("c4b58a"))
   _text(Vector2(16,h-34),"梁萧" if s.left!="" else "左盘",13)
   _text(Vector2(w-65,h-34),"兰娅" if s.right!="" else "右盘",13)
   _text(Vector2(12,24),"门已开" if s.complete else "人命与器物",14)
  "pz_ch16_study":
   _text(Vector2(12,24),"十二季 · 亲手记下")
   for i in range(12):
    var x:float=14+(i%4)*(w-28)/4;var y:float=42+int(i/4)*28
    draw_rect(Rect2(x,y,(w-40)/4,18),Color("648f81") if i<s.season_index else Color("31464a"))
   var angle:float=-PI*.8+float(s.instrument)*PI*.15
   var center:=Vector2(w*.5,h-25)
   draw_arc(center,27,-PI,0,24,Color("bd9f68"),1)
   draw_line(center,center+Vector2(cos(angle),sin(angle))*27,Color("e8dfc7"),2)
