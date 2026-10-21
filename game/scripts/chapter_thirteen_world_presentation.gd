class_name ChapterThirteenWorldPresentation
extends RefCounted
## Authored MG20 development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧":"char_liang_xiao","花晓霜":"char_hua_xiaoshuang","晓霜":"char_hua_xiaoshuang","柳莺莺":"char_liu_yingying","花生":"char_huasheng","幼帝":"npc_zhao_bing","赵昺":"npc_zhao_bing","广王":"npc_zhao_bing","云殊":"npc_yun_shu","贺陀罗":"npc_hetuoluo","哈里斯":"npc_harris","阿滩":"npc_atan","陆秀夫":"npc_lu_xiufu","快雪":"animal_kuaixue","白痴儿":"follower_baichier","金灵儿":"follower_jinlinger","胭脂":"animal_yanzhi"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch13_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") and saved.get("phase","")==w.scene_data.get("id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch13_spatial_state",{})
 if s.get("map_id","")==w.scene_data.get("map_id","") and s.get("phase","")==w.scene_data.get("id",""):sync(w,{"world_state":s},false)
 w.player.movement_multiplier=1.0
static func sync(w:Node2D,view:Dictionary,apply_player_position:bool=true)->void:
 var s:Dictionary=view.get("world_state",{}).duplicate(true)
 if s.is_empty() or not w.player:return
 if s.get("map_id","")!=w.scene_data.get("map_id",""):w.controlled_view.clear();return
 w.controlled_view=s
 var id:String=s.get("control_actor_id","char_liang_xiao")
 if apply_player_position and s.has("control_actor_id"):
  w.player.actor_id=id;w.player.appearance="youth_age_18" if id=="char_liang_xiao" else "adult"
 # Historical receipts dress the scene; only a live controlled view owns movement.
 # configure/restore already chose the validated free-navigation position.
 if apply_player_position and s.has("player_position"):
  var movement:Vector2=p(s.player_position)-w.player.position;w.player.position=p(s.player_position)
  if movement!=Vector2.ZERO:w.player.visual.facing=movement.normalized()
 if apply_player_position and s.has("carrying_actor_id"):w.player.carrying_actor_id=s.carrying_actor_id
 w.player.refresh_appearance()
 for actor_id in w.cast_actors:
  var actor=w.cast_actors[actor_id]
  # Battle views deliberately carry only control and outcome; absent fields are not empty casts.
  if s.has("visible_actor_ids"):actor.visible=actor_id in s.visible_actor_ids
  actor.visible=actor.visible and actor_id!=w.player.actor_id and actor_id!=w.player.carrying_actor_id and actor_id not in w.runtime_context.get("dead_actor_ids",[]) and actor_id not in w.runtime_context.get("departed_actor_ids",[])
  if s.get("actor_positions",{}).has(actor_id):actor.position=p(s.actor_positions[actor_id])
  if s.get("actor_postures",{}).has(actor_id):actor.resting=s.actor_postures[actor_id] in ["resting","wounded","incapacitated","bandaged_incapacitated","guided_incapacitated"]
  actor.is_body=actor_id in w.runtime_context.get("dead_actor_ids",[])
  actor.refresh_texture()
 w.queue_redraw()
static func timber(w:Node2D,at:Vector2,color:Color=Color("95734c"))->void:
 w.draw_rect(Rect2(at-Vector2(12,5),Vector2(24,7)),color)
 w.draw_line(at+Vector2(-10,-3),at+Vector2(10,-3),Color("5f4938"),1)
static func boat(w:Node2D,at:Vector2,size:Vector2)->void:
 w.draw_rect(Rect2(at,size),Color("6e5540"))
 w.draw_rect(Rect2(at+Vector2(3,3),size-Vector2(6,6)),Color("a28a64"))
 for y in range(int(at.y)+8,int(at.y+size.y)-4,8):w.draw_line(Vector2(at.x+3,y),Vector2(at.x+size.x-3,y),Color("80694e"),1)
static func draw(w:Node2D)->void:
 var m:Dictionary=w.layout;var s:=spatial(w);var style:String=m.get("style","")
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("183b4b"))
 for y in range(12,int(w.map_size.y),24):
  for x in range(8,int(w.map_size.x),48):
   var phase:int=(y/24)%2*12
   w.draw_line(Vector2(x+phase,y),Vector2(x+20+phase,y),Color("365a65"),1)
 var land:bool=style in ["sea_island","sea_reef","sea_chaoyun"]
 if land:w.draw_rect(r(m.walk_bounds),Color("85816a") if style=="sea_reef" else Color("a9a180"))
 elif style=="sea_whale":
  w.draw_rect(r(m.walk_bounds),Color("49636b"));w.draw_rect(Rect2(48,80,384,16),Color("6b8186"))
  w.draw_rect(Rect2(96,64,128,8),Color("8c9ea0"));w.draw_rect(Rect2(320,192,48,16),Color("819497"))
 else:boat(w,Vector2(m.walk_bounds[0],m.walk_bounds[1]),Vector2(m.walk_bounds[2],m.walk_bounds[3]))
 for solid in m.solids:
  var at:=Vector2(solid[0],solid[1]);var size:=Vector2(solid[2],solid[3])
  w.draw_rect(Rect2(at,size),Color("484e4c") if land else Color("634b37"));w.draw_rect(Rect2(at,size*Vector2(1,0)+Vector2(0,3)),Color("9ba399") if land else Color("bca47a"))
 match style:
  "sea_yashan":
   for at in [Vector2(48,80),Vector2(400,112),Vector2(256,96)]:
    w.draw_rect(Rect2(at,Vector2(16,20)),Color("aa4d32"));w.draw_rect(Rect2(at+Vector2(4,-8),Vector2(7,21)),Color("d89b46"))
   if not s.get("local_objects",{}).get("fire_rope_cut",false):w.draw_line(Vector2(352,224),Vector2(464,176),Color("bf965a"),2)
  "sea_drift":
   for id in ["rigging_1","rigging_2"]:
    var at:=p(m.anchors[id]);w.draw_line(at,Vector2(240,112),Color("c9b27c") if id in s.get("secured_ropes",[]) else Color("78664c"),2)
   for id in ["plank_1","plank_2"]:
    if id not in s.get("placed_beams",[]) and s.get("carried_object","")!=id:timber(w,p(m.anchors[id]))
   for index in range(s.get("placed_beams",[]).size()):timber(w,Vector2(240+index*16,216))
   if s.get("local_objects",{}).get("stern_door_barred",false):timber(w,p(m.anchors.door))
   w.draw_rect(Rect2(104,180,16,6),Color("d8d0b3"))
  "sea_whale":
   w.draw_line(Vector2(176,144),Vector2(164,112),Color("c6d4cf"),2)
   w.draw_line(Vector2(176,144),Vector2(188,112),Color("c6d4cf"),2)
   if not s.get("harpoon_removed",false):w.draw_line(Vector2(352,208),Vector2(344,186),Color("ccbfa0"),2)
   if s.get("local_objects",{}).get("safety_line",false):w.draw_line(Vector2(272,208),Vector2(352,208),Color("bca477"),1)
  "sea_wreck":
   boat(w,Vector2(368,232),Vector2(64,48))
   for at in [Vector2(192,128),Vector2(256,192),Vector2(128,96)]:w.draw_rect(Rect2(at,Vector2(16,24)),Color("183b4b"))
   if s.get("local_objects",{}).get("rescue_rope",false):w.draw_line(p(m.anchors.rope),p(m.anchors.boat),Color("c4a978"),2)
  "sea_island":
   boat(w,Vector2(96,264),Vector2(64,16));boat(w,Vector2(320,264),Vector2(64,16))
   for id in ["rotten_wood","iron_wood_1","iron_wood_2"]:
    if id not in s.get("material_deliveries",[]) and s.get("carried_object","")!=id:timber(w,p(m.anchors[id]),Color("69543e") if id=="rotten_wood" else Color("ab895a"))
   for index in range(s.get("local_objects",{}).get("iron_wood",0)):timber(w,Vector2(336+index%3*12,248-index/3*8))
  "sea_reef":
   boat(w,Vector2(40,80),Vector2(64,32));w.draw_rect(Rect2(70,48,3,32),Color("bda47c"));w.draw_rect(Rect2(73,48,24,20),Color("ddd2ad"))
  "sea_homebound":
   w.draw_rect(Rect2(224,128,32,24),Color("c9b284"));w.draw_line(Vector2(240,144),Vector2(240,124),Color("514437"),2)
   for x in [96,160,224,288,352]:w.draw_rect(Rect2(x,280,5,8),Color("5a4637"))
  "sea_chaoyun":
   w.draw_rect(Rect2(128,174,32,18),Color("838879"));w.draw_rect(Rect2(232,96,16,32),Color("b6b8a6"))
   w.draw_rect(Rect2(238,100,4,20),Color("777c71"));w.draw_line(Vector2(64,80),Vector2(64,160),Color("66553d"),3)
   for dx in [-18,-8,8,18]:w.draw_line(Vector2(64,84),Vector2(64+dx,136),Color("637449"),2)
   if s.get("local_objects",{}).get("letter_left",false):w.draw_rect(Rect2(136,174,9,5),Color("ded7b8"))
 if not s.get("carried_object","").is_empty() and s.get("player_position") is Array:timber(w,p(s.player_position)-Vector2(0,20))
 if s.get("target_position") is Array:
  var at:=p(s.target_position);w.draw_rect(Rect2(at-Vector2(5,2),Vector2(10,4)),Color("c6a65b"),false,1)
