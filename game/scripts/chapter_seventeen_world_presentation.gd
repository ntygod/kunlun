extends RefCounted
## Read-only regional development dressing. Final tiles/character actions remain separate work.
static func draw(w:Node2D)->void:
 var style:String=w.layout.style
 var snow:=Color("acb6b4");var rock:=Color("38464b");var wood:=Color("6c5d4c")
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),rock)
 w.draw_rect(w._rect(w.layout.walk_bounds).grow(8),Color("718083"))
 w.draw_rect(w._rect(w.layout.walk_bounds),Color("9c8767") if style=="sand" else snow)
 for y in range(80,296,24):
  for x in range(40,444,32):w.draw_line(Vector2(x,y),Vector2(x+12,y),Color("b6a280") if style=="sand" else Color("c4cdca"),1)
 # A stepped mountain horizon stays on the world pixel grid, not the high-res text layer.
 for n in range(6):
  var x:int=n*80
  w.draw_rect(Rect2(x,32+(n%2)*12,80,40),Color("596e73"));w.draw_rect(Rect2(x+16,28+(n%2)*12,32,8),Color("c0ccca"))
 if style in ["village","roof"]:
  for x in range(32,448,20):w.draw_rect(Rect2(x,70,3,14),wood)
  w.draw_line(Vector2(32,78),Vector2(448,78),wood,2)
  for x in [54,416]:w.draw_rect(Rect2(x,142,4,22),wood);w.draw_rect(Rect2(x-1,140,6,8),Color("d3ab68"))
 if style=="roof":
  var built:bool=w.runtime_context.world_objects.get("ch17_roof",{}).get("built",false)
  w.draw_rect(Rect2(200,80,64,40),wood if built else Color("748185"))
  w.draw_line(Vector2(194,82),Vector2(230,62),wood,3);w.draw_line(Vector2(230,62),Vector2(270,82),wood,3)
  if built:
   w.draw_line(Vector2(196,79),Vector2(230,62),Color("d5dcd3"),3);w.draw_line(Vector2(230,62),Vector2(268,79),Color("d5dcd3"),3)
   w.draw_rect(Rect2(224,102,14,18),Color("293638"));w.draw_rect(Rect2(207,94,10,10),Color("d4b780"))
  else:
   for x in [200,230,262]:w.draw_rect(Rect2(x,80,2,40),wood)
 elif style=="lake":
  w.draw_rect(Rect2(20,20,440,44),Color("637f83"))
  for x in range(30,444,32):w.draw_line(Vector2(x,45),Vector2(x+18,45),Color("a4bdbb"),1)
  for decor in w.layout.decor:w._draw_landmark(Rect2(decor[0],decor[1],decor[2],decor[3]),decor[4])
 else:
  for decor in w.layout.decor:w._draw_landmark(Rect2(decor[0],decor[1],decor[2],decor[3]),decor[4])
 for point in w.interactions:
  var p:Vector2=point.position
  w.draw_line(p+Vector2(-5,2),p+Vector2(0,-2),Color("9f6b36"));w.draw_line(p+Vector2(0,-2),p+Vector2(5,2),Color("9f6b36"))
