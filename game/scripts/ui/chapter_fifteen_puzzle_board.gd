extends Control
## Readable development diagram, not a final pixel-art asset or medical guide.
signal slot_chosen(slot:int)
const FAMILIES:=[0,1,2,1,2,0,2,0,1]
var _view:Dictionary={}
var _selection:=-1
func render(view:Dictionary,selection:int=-1)->void:_view=view.duplicate(true);_selection=selection;queue_redraw()
func line(at:Vector2,text:String,font_size:int=12)->void:draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
func card_rect(i:int)->Rect2:
 var width:float=(size.x-24)/3
 return Rect2(Vector2(8+(i%3)*width,41+(i/3)*32),Vector2(width-4,29))
func _gui_input(event:InputEvent)->void:
 if _view.get("method")!="a":return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  for i in range(9):
   if card_rect(i).has_point(event.position):slot_chosen.emit(i);accept_event();return
func _draw()->void:
 if _view.is_empty():return
 var s:Dictionary=_view.state
 draw_rect(Rect2(Vector2.ZERO,size),Color("25333d"))
 line(Vector2(8,18),"草庐备办 · "+("图录留墙" if _view.method=="a" else "储备传承"))
 if _view.method=="a":
  line(Vector2(8,36),"甲圆 / 乙三角 / 丙方")
  for i in range(9):
   var rect:=card_rect(i);draw_rect(rect,Color("607e80") if i==_selection else Color("374b53"))
   var at:=rect.position+Vector2(13,12)
   if FAMILIES[i]==0:draw_circle(at,5,Color("ecd8a5"))
   elif FAMILIES[i]==1:draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(-6,5),at+Vector2(6,5)]),Color("ecd8a5"))
   else:draw_rect(Rect2(at-Vector2(5,5),Vector2(10,10)),Color("ecd8a5"))
   line(rect.position+Vector2(25,16),str(i+1))
   line(rect.position+Vector2(5,27),"→"+(["甲","乙","丙"][int(s.cards[str(i)])] if s.cards.has(str(i)) else "未放"),11)
  line(Vector2(8,153),"归栏%d/9 · %s"%[s.cards.size(),"核对完成" if s.atlas_checked else "待核对"])
 else:
  line(Vector2(8,37),"三坛须盖紧标明，不凭猜测")
  for i in range(3):
   var at:=Vector2(16+i*(size.x-32)/3,48)
   draw_rect(Rect2(at,Vector2(40,30)),Color("9c805e") if i in s.jars else Color("43565f"))
   draw_line(at+Vector2(-2,0),at+Vector2(42,0),Color("e0cfa7"),3)
   line(at+Vector2(9,24),str(i+1),14)
  line(Vector2(8,96),"已妥存 %d/3坛"%s.jars.size())
  line(Vector2(8,116),"图录上架 · 木人置案")
  line(Vector2(8,136),"针匣封存 · 已整理%d/3"%s.tools.size())

