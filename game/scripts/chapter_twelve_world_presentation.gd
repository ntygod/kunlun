class_name ChapterTwelveWorldPresentation
extends RefCounted
## Authored PAL07 development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧":"char_liang_xiao","花晓霜":"char_hua_xiaoshuang","晓霜":"char_hua_xiaoshuang","柳莺莺":"char_liu_yingying","花生":"char_huasheng","骆明绮":"npc_luo_mingqi","楚仙流":"npc_chu_xianliu","楚羽":"npc_chu_yu","韩凝紫":"npc_han_ningzi","雷行空":"npc_lei_xingkong","快雪":"animal_kuaixue","白痴儿":"follower_baichier","金灵儿":"follower_jinlinger"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch12_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") and saved.get("phase","")==w.scene_data.get("id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch12_spatial_state",{})
 if s.get("map_id","")==w.scene_data.get("map_id","") and s.get("phase","")==w.scene_data.get("id",""):sync(w,{"world_state":s},false)
 w.player.movement_multiplier=1.0
static func sync(w:Node2D,view:Dictionary,apply_player_position:bool=true)->void:
 var s:Dictionary=view.get("world_state",{}).duplicate(true)
 if s.is_empty() or not w.player:return
 if s.get("map_id","")!=w.scene_data.get("map_id",""):w.controlled_view.clear();return
 w.controlled_view=s
 var id:String=s.get("control_actor_id","char_liang_xiao")
 if apply_player_position:
  w.player.actor_id=id;w.player.appearance="youth_age_18" if id=="char_liang_xiao" else "adult"
 # Historical receipts dress the scene; only a live controlled view owns movement.
 # configure/restore already chose the validated free-navigation position.
 if apply_player_position and s.has("player_position"):
  var movement:Vector2=p(s.player_position)-w.player.position;w.player.position=p(s.player_position)
  if movement!=Vector2.ZERO:w.player.visual.facing=movement.normalized()
 if apply_player_position:w.player.carrying_actor_id=s.get("carrying_actor_id","");w.player.refresh_appearance()
 for actor_id in w.cast_actors:
  var actor=w.cast_actors[actor_id]
  actor.visible=actor_id in s.get("visible_actor_ids",[]) and actor_id!=w.player.actor_id and actor_id!=w.player.carrying_actor_id and actor_id not in w.runtime_context.get("dead_actor_ids",[])
  if s.get("actor_positions",{}).has(actor_id):actor.position=p(s.actor_positions[actor_id])
  actor.resting=s.get("actor_postures",{}).get(actor_id,"") in ["resting","wounded","incapacitated","bandaged_incapacitated","guided_incapacitated"]
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
 var forest:bool=style in ["medical_meiling_path","medical_chiyou_clearing","medical_forest_exit"]
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("1e2d24") if forest else Color("56664e"))
 w.draw_rect(r(m.walk_bounds),Color("536053") if forest else Color("a19c87"))
 w.draw_rect(Rect2(32,248,416,16),Color("78836b") if forest else Color("c1b497"))
 for solid in m.solids:rock(w,Vector2(solid[0],solid[1]),Vector2(solid[2],solid[3]))
 match style:
  "medical_road":
   cart(w,Vector2(144,240))
   for i in range(1,4):
    var id:="stone_"+str(i)
    if id in s.get("road_stones",[]):rock(w,Vector2(336+i*12,272),Vector2(12,10))
    elif s.get("carried_object","")!=id:rock(w,p(m.anchors[id])-Vector2(7,10),Vector2(14,10))
   if not s.get("carried_object","").is_empty():rock(w,p(s.player_position)-Vector2(7,28),Vector2(14,10))
  "medical_manor_gate":
   w.draw_rect(Rect2(336,128,80,6),Color("d4cfc4"));w.draw_rect(Rect2(344,134,8,36),Color("b0a68f"));w.draw_rect(Rect2(400,134,8,36),Color("b0a68f"))
   for i in range(1,4):
    var id:="weapon_"+str(i);var at:=p(m.anchors[id])-Vector2(0,16)
    if s.get("weapons_released",false):at+=Vector2(8,16)
    w.draw_line(at-Vector2(4,8),at+Vector2(4,8),Color("d4cfc4"),2)
    if id in s.get("tethered_weapons",[]):w.draw_line(p(s.player_position)-Vector2(0,15),at,Color("c99e44"),1)
  "medical_arena":
   w.draw_circle(Vector2(240,216),64,Color("d4cfc4"),false,2)
   for x in [128,352]:w.draw_rect(Rect2(x,200,4,24),Color("715841"));w.draw_rect(Rect2(x-1,196,6,5),Color("c99e44"))
  "medical_care_room":
   for at in [Vector2(224,224),Vector2(320,224)]:
    w.draw_rect(Rect2(at-Vector2(14,14),Vector2(28,16)),Color("765e4a"));w.draw_rect(Rect2(at-Vector2(12,12),Vector2(24,10)),Color("d4cfc4"))
   w.draw_circle(Vector2(112,224),7,Color("758c8a"),false,2)
  "medical_jiangxi_clinic":
   w.draw_rect(Rect2(208,160,144,8),Color("c3b89a"))
   for x in [216,344]:w.draw_rect(Rect2(x,168,4,60),Color("806b49"))
   w.draw_rect(Rect2(216,212,20,8),Color("694f39"))
  "medical_meiling_path":
   for i in range(1,4):
    var id:="herb_"+str(i)
    if id not in s.get("herbs",[]):
     var at:=p(m.anchors[id]);w.draw_line(at,at-Vector2(0,10),Color("4d7a52"),2)
     for dx in [-5,3]:w.draw_rect(Rect2(at+Vector2(dx,-8),Vector2(5,3)),Color("85a15c"))
   for at in [Vector2(224,112),Vector2(336,160)]:w.draw_rect(Rect2(at,Vector2(10,3)),Color("7a4282"))
  "medical_chiyou_clearing":
   tree(w,Vector2(272,112));w.draw_rect(Rect2(348,188,9,8),Color("6d4774"))
   if s.get("poison_sealed",false):w.draw_line(Vector2(346,188),Vector2(360,188),Color("d4cfc4"),2)
   for at in [Vector2(80,96),Vector2(384,112),Vector2(432,192)]:w.draw_rect(Rect2(at,Vector2(16,3)),Color("7a4282"))
  "medical_forest_exit":
   if not s.get("books_packed",false):
    for x in [88,99]:w.draw_rect(Rect2(x,212,9,5),Color("d4cfc4"))
   for at in [Vector2(128,160),Vector2(352,128)]:tree(w,at)
 if s.get("target_position") is Array:w.draw_circle(p(s.target_position),5,Color("c99e44"),false,1)
