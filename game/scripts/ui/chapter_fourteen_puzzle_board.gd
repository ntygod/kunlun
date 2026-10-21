extends Control
## Development diagram, not a final pixel asset or historical observation dataset.
signal slot_chosen(slot:int)
var _view:Dictionary={}
func render(view:Dictionary,_selection:int=-1)->void:_view=view.duplicate(true);queue_redraw()
func line(at:Vector2,text:String,font_size:int=13)->void:draw_string(get_theme_default_font(),at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
func _draw()->void:
 if _view.is_empty():return
 var s:Dictionary=_view.state
 draw_rect(Rect2(Vector2.ZERO,size),Color("25333d"))
 if _view.puzzle_id=="pz_ch14_calendar":
  line(Vector2(8,18),"四十尺表 · 景符定影")
  var x:float=12+(size.x-24)*float(s.position-1400)/100
  draw_line(Vector2(12,70),Vector2(size.x-12,70),Color("cfc19e"),2)
  var target:float=12+(size.x-24)*0.62
  draw_line(Vector2(target,46),Vector2(target,89),Color("b8dbe0"),1)
  draw_circle(Vector2(x,70+(s.beam-3)*4),5,Color("f6e1a0"))
  draw_line(Vector2(x-12,70),Vector2(x+12,70),Color("17232b"),2)
  line(Vector2(8,39),"1462寸 · 偏移0为准心",12)
  line(Vector2(8,106),"读数"+("已锁" if s.locked else "未锁")+" · 资料%d/27所"%(s.groups.size()*9),12)
  line(Vector2(8,128),"示意一差 1、1、7",12)
  line(Vector2(8,148),"二差 0、6 → 三差%d"%s.third_difference,12)
  line(Vector2(8,170),"岁实 %d.%04d日"%[s.days,s.fraction],12)
 else:
  line(Vector2(8,22),"辩难 %d/3 · 不伤一人"%s.debate_stage)
  var center:=Vector2(size.x/2,94)
  for i in range(6):
   var p:=center+Vector2.from_angle(i*TAU/6)*23
   draw_circle(p,15,Color("87a8af") if s.debate_stage<2 else Color("526b77"))
  draw_circle(center,12,Color("b5d4cd"))
  line(Vector2(8,149),["反问归一之本源","追问具体生命","收起争胜，迎回幼帝","国师合十，依约放还"][s.debate_stage],12)
