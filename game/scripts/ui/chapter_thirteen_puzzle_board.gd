extends Control
## Development diagrams, not final pixel scenery or historical instruments.
signal slot_chosen(slot:int)
var _view:Dictionary={}
func render(view:Dictionary,_selection:int=-1)->void:_view=view.duplicate(true);queue_redraw()
func line(at:Vector2,text:String,font_size:int=14)->void:draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
func _draw()->void:
 if _view.is_empty():return
 var s:Dictionary=_view.state
 draw_rect(Rect2(Vector2.ZERO,size),Color("20383c"))
 match _view.puzzle_id:
  "pz_ch13_water_watch":
   line(Vector2(8,22),"余水%d筒 · 守过%d/3夜"%[s.water,s.night])
   for i in range(2):draw_rect(Rect2(22+i*50,38,30,42),Color("79b7c4") if i<s.water else Color("445b63"))
   for i in range(3):
    var x:float=12+i*(size.x-24)/3
    draw_rect(Rect2(x,105,(size.x-30)/3,30),Color("d7b378") if i==s.watch else Color("4b6570"))
    line(Vector2(x+4,125),["前舱","中舱","后舱"][i],12)
  "pz_ch13_whale_breath":
   var inhale:int=1+s.segment%3
   line(Vector2(8,22),"鲸歌 %d/13段"%s.segment)
   line(Vector2(8,46),"吸%d → 停1 → 吐%d"%[inhale,inhale+1])
   line(Vector2(8,70),"当前："+(["吸","停","吐"][s.phase] if not s.complete else "十三段合一"))
   for i in range(13):draw_rect(Rect2(10+i*(size.x-20)/13,90,(size.x-24)/13,20),Color("92d5b0") if i<s.segment else Color("456e79"))
   for i in range(32):
    var x:float=8+i*(size.x-16)/31
    var x2:float=8+(i+1)*(size.x-16)/31
    if i<31:draw_line(Vector2(x,140-sin(i*0.4)*12),Vector2(x2,140-sin((i+1)*0.4)*12),Color("a9d8dd"),2)
  "pz_ch13_decoy_ship":
   line(Vector2(8,22),"第%d/4日 · 潮声%d"%[mini(s.day+1,4),s.tide])
   line(Vector2(8,46),"伪木%d / 真木%d"%[s.timber_fake,s.timber_real])
   line(Vector2(8,70),"轮轴 %d : %d"%[s.wheel_front,s.wheel_rear])
   draw_rect(Rect2(8,91,size.x-16,40),Color("766548"))
   for i in range(5):
    var x:float=10+i*(size.x-20)/5
    draw_rect(Rect2(x,95,(size.x-24)/5,32),Color("87bba2") if i in s.bulkheads else Color("414f50"))
    line(Vector2(x+4,115),str(i),12)
   line(Vector2(8,154),"暗销："+("已抽去" if s.pin_removed else "未抽去"),12)
  _:
   var center:=Vector2(size.x*0.5,92);var radius:=minf(size.x*0.32,55)
   draw_circle(center,radius,Color("385c65"))
   for i in range(8):
    var p:=center+Vector2.from_angle(-PI/2+i*TAU/8)*radius
    line(p+Vector2(-4,4),str(i),12)
   draw_line(center,center+Vector2.from_angle(-PI/2+s.heading*TAU/8)*(radius-8),Color("e6c27d"),3)
   line(Vector2(8,20),"晨影%d / 夕影%d"%[s.shadow_morning,s.shadow_evening])
   line(Vector2(8,42),"北线%d · 星高%d指"%[s.north,s.star],12)
   line(Vector2(8,160),"已校准" if s.calibrated else "尚待昼夜互校",12)
