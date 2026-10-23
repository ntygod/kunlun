extends Control
## Read-only task schematic, not finished world art. Geometry never submits progress.
const Ink=preload("res://scripts/ui/ink_theme.gd")
var view:Dictionary={}
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func render(value:Dictionary)->void:
 view=value.duplicate(true);queue_redraw()
func _text(at:Vector2,value:String,width:float=180,color:Color=Ink.TEXT)->void:
 draw_string(get_theme_default_font(),at,value,HORIZONTAL_ALIGNMENT_CENTER,width,15,color)
func _draw()->void:
 if view.is_empty():return
 draw_style_box(Ink.box(Ink.INK,Ink.EDGE,0),Rect2(Vector2.ZERO,size))
 var s:Dictionary=view.state
 if view.puzzle_id=="pz_ch17_evidence":
  var target:=Vector2(size.x*.5,size.y*.51)
  for index in range(6):
   var left:bool=index<3
   var pos:=Vector2(18 if left else size.x-218,20+(index%3)*(size.y-66)/2)
   var key:String=view.evidence[index]
   var linked:=false
   for link in s.links:
    if key in link.clues:linked=true
   var selected:bool=key in s.selected
   var tone:Color=Ink.JADE if linked else (Ink.GOLD if selected else Ink.EDGE)
   var endpoint:=Vector2(pos.x+200 if left else pos.x,pos.y+23)
   draw_line(endpoint,target,tone,2 if selected or linked else 1)
   draw_style_box(Ink.box(Ink.RAISED if selected else Ink.SURFACE,tone,0),Rect2(pos,Vector2(200,46)))
   _text(pos+Vector2(8,29),view.labels[key],184,Ink.TEXT if selected or linked else Ink.MUTED)
  draw_circle(target,46,Ink.SURFACE)
  draw_arc(target,46,0,TAU,64,Ink.GOLD,2)
  _text(target+Vector2(-42,-4),"狼皮替身" if s.claim=="double" else "真凶阿莫",84)
  _text(target+Vector2(-42,20),"%d / 2"%s.links.size(),84,Ink.JADE)
 else:
  var left:float=size.x*.22;var right:float=size.x*.68
  var ground:float=size.y-32;var eaves:float=size.y*.48;var peak:=Vector2(size.x*.45,32)
  draw_line(Vector2(28,ground),Vector2(size.x-28,ground),Ink.EDGE,1)
  var completed:Dictionary={}
  for work in s.work:completed[work.part]=true
  var wall_tone:Color=Ink.GOLD if completed.has("wall") or completed.has("beam") else Ink.EDGE
  var joint_tone:Color=Ink.JADE if completed.has("joint") or completed.has("brace") else Ink.EDGE
  for x in [left,right]:draw_line(Vector2(x,ground),Vector2(x,eaves),wall_tone,5)
  draw_line(Vector2(left,eaves),peak,wall_tone,5);draw_line(peak,Vector2(right,eaves),wall_tone,5)
  draw_line(Vector2(left,eaves),Vector2(right,eaves),joint_tone,4)
  draw_line(Vector2(left,ground),Vector2(right,eaves),joint_tone,2)
  if completed.has("wall"):
   for n in range(5):draw_line(Vector2(left,ground-14-n*16),Vector2(right,ground-14-n*16),Ink.GOLD,3)
  if completed.has("wedge"):
   for x in [left,right]:draw_rect(Rect2(x-6,eaves-5,12,10),Ink.JADE)
  if completed.has("reeds"):
   for n in range(14):
    var t:float=float(n)/13
    var edge:=Vector2(left,eaves).lerp(Vector2(right,eaves),t)
    draw_line(edge,peak,Ink.JADE,2)
  _text(Vector2(30,29),"按分工建屋 · 当前结构",230,Ink.MUTED)
  _text(Vector2(size.x-258,ground-60),"%d / %d 工序"%[s.stage,view.steps.size()],225,Ink.GOLD)
  _text(Vector2(size.x-258,ground-30),"柳莺莺主事 · 师徒相助",225,Ink.MUTED)
