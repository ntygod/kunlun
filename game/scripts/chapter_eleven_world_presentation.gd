class_name ChapterElevenWorldPresentation
extends RefCounted
## Authored MG18 development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧":"char_liang_xiao","花晓霜":"char_hua_xiaoshuang","晓霜":"char_hua_xiaoshuang","花生":"char_huasheng","白痴儿":"follower_baichier","金灵儿":"follower_jinlinger","快雪":"animal_kuaixue","疯老人":"npc_shi_tianfeng","释天风":"npc_shi_tianfeng","吴常青":"npc_wu_changqing","了情":"npc_liaoqing","了情道姑":"npc_liaoqing","哑儿":"npc_yaer","公羊羽":"npc_gongyang_yu"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch11_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") and saved.get("phase","")==w.scene_data.get("id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch11_spatial_state",{})
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
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("465b58"))
 var ground:=Color("a8a18a") if style!="laoshan_cave" else Color("626872")
 w.draw_rect(r(m.walk_bounds),ground)
 w.draw_rect(Rect2(32,248,416,16),ground.lightened(0.13))
 for solid in m.solids:rock(w,Vector2(solid[0],solid[1]),Vector2(solid[2],solid[3]))
 match style:
  "laoshan_town":
   for x in [64,240]:
    w.draw_rect(Rect2(x,72,80,36),Color("c0b295"));w.draw_rect(Rect2(x-6,64,92,10),Color("695d55"))
   w.draw_rect(Rect2(352,232,40,6),Color("665c4c"))
  "laoshan_clinic":
   for at in [Vector2(80,160),Vector2(208,96),Vector2(400,176)]:
    tree(w,at)
    for q in [Vector2(-8,-40),Vector2(6,-46),Vector2(12,-34)]:w.draw_rect(Rect2(at+q,Vector2(4,3)),Color("e4c7b1"))
   for x in [224,272]:
    w.draw_rect(Rect2(x,168,24,4),Color("745f47"));w.draw_rect(Rect2(x,172,2,12),Color("745f47"));w.draw_rect(Rect2(x+22,172,2,12),Color("745f47"))
    for dx in [2,9,16]:w.draw_rect(Rect2(x+dx,166,5,2),Color("677d55"))
   for a in ["plum_1","plum_2","plum_3","plum_4"]:w.draw_circle(p(m.anchors[a]),3,Color("c6c1a9"),false,1)
  "laoshan_sunrise_peak":
   w.draw_rect(Rect2(0,0,480,64),Color("e3c59d"));w.draw_circle(Vector2(384,32),18,Color("eebc71"))
   for a in ["rest_1","rest_2"]:rock(w,p(m.anchors[a])-Vector2(12,14),Vector2(24,8))
   for x in [64,160,256]:w.draw_rect(Rect2(x,28,80,6),Color("ede5d2"))
  "laoshan_rear_path":
   for at in [Vector2(96,160),Vector2(256,112),Vector2(352,256)]:tree(w,at)
   w.draw_rect(Rect2(388,224,40,8),Color("414d50"));w.draw_rect(Rect2(400,232,16,16),Color("253b3c"))
  "laoshan_cave":
   for at in [Vector2(64,80),Vector2(256,80),Vector2(400,80)]:rock(w,at,Vector2(16,32))
   w.draw_rect(Rect2(212,176,72,8),Color("c2c5b9"));w.draw_rect(Rect2(212,184,72,12),Color("858e8e"))
  "laoshan_river_ferry":
   w.draw_rect(Rect2(0,0,480,64),Color("8d8370"))
   for x in range(0,480,48):w.draw_rect(Rect2(x,48,32,2),Color("c8c1a7"))
   rock(w,p(s.get("boulder_position",[272,224]))-Vector2(16,16),Vector2(32,24))
   w.draw_rect(Rect2(376,224,56,6),Color("735a42"));w.draw_rect(Rect2(380,230,3,18),Color("735a42"));w.draw_rect(Rect2(424,230,3,18),Color("735a42"))
 if s.get("target_position") is Array:w.draw_circle(p(s.target_position),5,Color("e0c37f"),false,1)
