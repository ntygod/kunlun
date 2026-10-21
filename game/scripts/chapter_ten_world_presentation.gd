class_name ChapterTenWorldPresentation
extends RefCounted
## Authored PAL-06 development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧":"char_liang_xiao","阿雪":"char_axue","楚婉":"npc_chu_wan","益王":"npc_zhao_shi","广王":"npc_zhao_bing","伯颜":"npc_bayan","疯老人":"npc_shi_tianfeng"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch10_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch10_spatial_state",{})
 if s.get("map_id","")==w.scene_data.get("map_id",""):sync(w,{"world_state":s},false)
 w.player.movement_multiplier=1.0
static func sync(w:Node2D,view:Dictionary,apply_player_position:bool=true)->void:
 var s:Dictionary=view.get("world_state",{}).duplicate(true)
 if s.is_empty() or not w.player:return
 if s.get("map_id","")!=w.scene_data.get("map_id",""):w.controlled_view.clear();return
 w.controlled_view=s
 var id:String=s.get("control_actor_id","char_liang_xiao")
 w.player.actor_id=id;w.player.appearance="youth_age_18" if id=="char_liang_xiao" else "adult"
 # Historical receipts dress the scene; only a live controlled view owns movement.
 # configure/restore already chose the validated free-navigation position.
 if apply_player_position and s.has("player_position"):
  var movement:Vector2=p(s.player_position)-w.player.position;w.player.position=p(s.player_position)
  if movement!=Vector2.ZERO:w.player.visual.facing=movement.normalized()
 w.player.carrying_actor_id=s.get("carrying_actor_id","");w.player.refresh_appearance()
 for actor_id in w.cast_actors:
  var actor=w.cast_actors[actor_id]
  actor.visible=actor_id in s.get("visible_actor_ids",[]) and actor_id!=id and actor_id!=s.get("carrying_actor_id","")
  if s.get("actor_positions",{}).has(actor_id):actor.position=p(s.actor_positions[actor_id])
  actor.resting=s.get("actor_postures",{}).get(actor_id,"") in ["resting","wounded","remembering"]
  actor.is_body=actor_id in w.runtime_context.get("dead_actor_ids",[])
  actor.refresh_texture()
 w.queue_redraw()
static func rock(w:Node2D,at:Vector2,size:Vector2)->void:
 w.draw_rect(Rect2(at,size),Color("42474d"));w.draw_rect(Rect2(at+Vector2(2,-2),Vector2(size.x-4,4)),Color("879397"))
 w.draw_line(at+Vector2(4,5),at+Vector2(size.x-7,5),Color("647075"),1)
static func reed(w:Node2D,at:Vector2,bent:bool=false)->void:
 for dx in [-5,0,5]:
  var tip:=at+Vector2(dx+8 if bent else dx-2,-18+absi(dx))
  w.draw_line(at+Vector2(dx,0),tip,Color("857d68"),1)
  w.draw_line(tip,tip+Vector2(2,-5),Color("b0aa91"),2)
static func tree(w:Node2D,at:Vector2,hidden:bool=false)->void:
 w.draw_rect(Rect2(at+Vector2(-5,-38),Vector2(10,38)),Color("514d48"))
 w.draw_rect(Rect2(at+Vector2(-3,-36),Vector2(2,36)),Color("82796a"))
 for branch in [-1,1]:w.draw_line(at+Vector2(0,-20),at+Vector2(branch*20,-42),Color("514d48"),3)
 for q in [Vector2(-23,-53),Vector2(-12,-64),Vector2(6,-51)]:w.draw_rect(Rect2(at+q,Vector2(25,15)),Color("4d5e59"))
 if hidden:w.draw_rect(Rect2(at+Vector2(-4,-43),Vector2(8,3)),Color("b3b2a6"))
static func cart(w:Node2D,at:Vector2)->void:
 w.draw_rect(Rect2(at+Vector2(-18,-22),Vector2(36,16)),Color("927a56"))
 for x in [-20,16]:
  w.draw_rect(Rect2(at+Vector2(x,-8),Vector2(5,12)),Color("51483a"));w.draw_rect(Rect2(at+Vector2(x+1,-6),Vector2(3,7)),Color("b8a077"))
 w.draw_line(at+Vector2(18,-10),at+Vector2(35,-4),Color("a78c60"),2)
 w.draw_rect(Rect2(at+Vector2(-14,-21),Vector2(28,3)),Color("c4b58d"))
static func draw(w:Node2D)->void:
 var m:Dictionary=w.layout;var s:=spatial(w);var style:String=m.get("style","")
 var sand:=Color("727a7b") if style in ["qililong_shore","qililong_stones"] else Color("515c60")
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("29343b"));w.draw_rect(r(m.walk_bounds),sand)
 # Fixed authored footpath and sparse integer highlights; no random texture/no generated art.
 w.draw_rect(Rect2(32,248,416,16),sand.lightened(0.15))
 for q in [Vector2(76,252),Vector2(124,257),Vector2(212,251),Vector2(316,258),Vector2(396,252)]:w.draw_rect(Rect2(q,Vector2(8,1)),Color("a4aca7"))
 for solid in m.solids:rock(w,Vector2(solid[0],solid[1]),Vector2(solid[2],solid[3]))
 if style in ["qililong_shore","qililong_levee","qililong_stones"]:
  w.draw_rect(Rect2(0,0,w.map_size.x,60),Color("435e69"))
  for y in [16,32,48]:
   for x in range(0,int(w.map_size.x),48):w.draw_rect(Rect2(x+y%7,y,34,2),Color("9faeb4"))
 match style:
  "qililong_pass":
   w.draw_rect(Rect2(86,130,100,40),Color("474c49"));w.draw_rect(Rect2(80,126,112,5),Color("8b8c7e"))
   for x in [92,178]:w.draw_rect(Rect2(x,132,4,44),Color("7d6d58"))
   cart(w,Vector2(224,192))
   w.draw_line(Vector2(336,220),Vector2(370,220),Color("bea56e"),2)
  "qililong_forest":
   rock(w,Vector2(332,220),Vector2(40,8))
   for x in [332,368]:w.draw_rect(Rect2(x,228,4,16),Color("647075"))
   for i in range(1,6):
    var anchor:="friend_"+str(i)
    tree(w,p(m.anchors[anchor])-Vector2(0,8),anchor in s.get("safe_friends",[]))
   w.draw_line(Vector2(380,244),Vector2(416,244),Color("ac9870"),1)
   w.draw_rect(Rect2(397,232,6,10),Color("cca052"))
  "qililong_reeds":
   for at in [Vector2(64,108),Vector2(112,224),Vector2(240,96),Vector2(336,208),Vector2(400,224)]:reed(w,at,at.x==112)
   for at in [Vector2(220,174),Vector2(228,178),Vector2(236,169)]:w.draw_arc(at,3,0,PI,5,Color("2c373c"),1)
   w.draw_line(Vector2(308,212),Vector2(330,212),Color("685c4d"),2);w.draw_rect(Rect2(318,212,7,9),Color("c3c5b9"))
  "qililong_levee":
   for at in [Vector2(208,208),Vector2(240,208),Vector2(280,240)]:reed(w,at,true)
   rock(w,Vector2(224,192),Vector2(24,16))
   if s.get("stage",0)>0:w.draw_rect(Rect2(220,226,10,2),Color("b8242c"))
   w.draw_rect(Rect2(312,64,136,144),Color("435e69"))
  "qililong_shore":
   for at in [Vector2(96,192),Vector2(192,208),Vector2(352,176)]:w.draw_line(at,at+Vector2(18,-2),Color("a4aca7"),1)
  "qililong_stones":
   for at in [Vector2(176,192),Vector2(240,176),Vector2(304,208)]:rock(w,at-Vector2(8,12),Vector2(16,12))
   w.draw_rect(Rect2(103,208,18,12),Color("42474d"));w.draw_rect(Rect2(107,210,10,4),Color("1a1819"))
 if s.get("recollection",false):w.draw_rect(Rect2(p(s.player_position)+Vector2(-2,-29),Vector2(4,2)),Color("857d68"))
 # No target marker, UI prompt or completion flash in the farewell/shore silence.
 if not s.get("silent",false) and s.get("target_position") is Array:w.draw_circle(p(s.target_position),5,Color("cca052"),false,1)
