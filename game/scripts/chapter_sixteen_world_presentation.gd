extends RefCounted
## Development map dressing, explicitly not final hand-crafted pixel assets.
static func draw(w:Node2D)->void:
 var style:String=w.layout.style
 var ground:=Color("9b8059");var shadow:=Color("594d3e");var edge:=Color("bfab7b")
 if style in ["river","source"]:ground=Color("657578");shadow=Color("263d47");edge=Color("abb29b")
 elif style in ["night","mourning"]:ground=Color("494741");shadow=Color("202e31");edge=Color("8d8a72")
 elif style in ["malaga","vault","library"]:ground=Color("8e7762");shadow=Color("3e4140");edge=Color("c6b88f")
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),shadow)
 w.draw_rect(w._rect(w.layout.walk_bounds).grow(8),ground.darkened(.25))
 w.draw_rect(w._rect(w.layout.walk_bounds),ground)
 for y in range(80,300,24):
  for x in range(40,440,32):w.draw_line(Vector2(x,y),Vector2(x+12,y),ground.lightened(.07),1)
 if style=="river":
  w.draw_rect(Rect2(0,36,480,30),Color("6b7f7c"))
  for x in range(8,470,32):w.draw_line(Vector2(x,48),Vector2(x+16,48),Color("a2b5a1"),2)
  for x in [144,240,336]:w.draw_rect(Rect2(x,52,8,30),Color("c0a475"))
  if w.runtime_context.world_objects.get("ch16_river",{}).get("complete",false):w.draw_rect(Rect2(252,56,168,5),Color("7bb4ae"))
 elif style=="source":
  for i in range(6):
   var at:=Vector2(32+i*76,96+(i%2)*32)
   w.draw_rect(Rect2(at,Vector2(32,10)),Color("7da6ab"))
   w.draw_line(at+Vector2(24,8),Vector2(240,156),Color("7da6ab"),2)
 elif style=="home":
  w.draw_rect(Rect2(150,134,28,24),Color("444943"))
  w.draw_rect(Rect2(158,146,12,10),Color("252d2d"))
  w.draw_rect(Rect2(308,148,16,3),Color("8b7151"))
 elif style in ["oasis","night"]:
  w.draw_rect(Rect2(184,88,112,36),Color("405f63") if style=="night" else Color("5c8982"))
  for x in [48,416]:
   w.draw_rect(Rect2(x,96,4,48),Color("6d513b"))
   for dx in [-16,-8,0,8,16]:w.draw_line(Vector2(x+2,96),Vector2(x+dx,86+abs(dx)/2),Color("496451"),3)
  if style=="night":
   for x in [88,366]:w.draw_rect(Rect2(x,92,6,14),Color("b87f4e"));w.draw_rect(Rect2(x+2,90,2,9),Color("dbc080"))
 elif style in ["vault","library","malaga"]:
  for x in range(48,440,64):
   w.draw_rect(Rect2(x,76,6,62),edge.darkened(.2));w.draw_line(Vector2(x,76),Vector2(x+32,64),edge,2);w.draw_line(Vector2(x+32,64),Vector2(x+64,76),edge,2)
  if style=="vault":w.draw_rect(Rect2(208,80,64,40),Color("b19b64"))
 elif style=="egypt":
  w.draw_rect(Rect2(232,78,32,72),Color("c8b88e"));w.draw_rect(Rect2(238,64,20,24),Color("c8b88e"))
 for decor in w.layout.decor:w._draw_landmark(Rect2(decor[0],decor[1],decor[2],decor[3]),decor[4])
 for point in w.interactions:
  var p:Vector2=point.position
  w.draw_line(p+Vector2(-5,2),p+Vector2(0,-2),Color("dbbc7b"));w.draw_line(p+Vector2(0,-2),p+Vector2(5,2),Color("dbbc7b"))
