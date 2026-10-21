class_name ChapterFifteenWorldPresentation
extends RefCounted
## Authored MQ15/MG22/BaiZhangPing development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧": "char_liang_xiao", "花晓霜": "char_hua_xiaoshuang", "晓霜": "char_hua_xiaoshuang", "柳莺莺": "char_liu_yingying", "花生": "char_huasheng", "幼帝": "npc_zhao_bing", "赵昺": "npc_zhao_bing", "九如": "npc_jiuru", "九如和尚": "npc_jiuru", "释天风": "npc_shi_tianfeng", "萧千绝": "npc_xiao_qianjue", "公羊羽": "npc_gongyang_yu", "明三秋": "npc_ming_sanqiu", "秦伯符": "npc_qin_bofu", "花清渊": "npc_hua_qingyuan", "花无媸": "npc_hua_wuchi", "火真人": "npc_huozhenren", "忽赤因": "npc_huchi_yin", "贺陀罗": "npc_hetuoluo", "哈里斯": "npc_harris", "韩凝紫": "npc_han_ningzi", "常宁": "npc_chang_ning", "骆明绮": "npc_luo_mingqi", "中条五宝": "npc_ch15_wubao", "阿福": "npc_ch15_afu", "白痴儿": "follower_baichier", "金灵儿": "follower_jinlinger"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch15_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") and saved.get("phase","")==w.scene_data.get("id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch15_spatial_state",{})
 if s.get("map_id","")==w.scene_data.get("map_id","") and s.get("phase","")==w.scene_data.get("id",""):sync(w,{"world_state":s},false)
 # Ordinary dialogue/choice scenes may have no matching historical receipt.
 # Death/departure must still win over their authored cast.
 for actor_id in w.cast_actors:
  if actor_id in context.get("dead_actor_ids",[]) or actor_id in context.get("departed_actor_ids",[]):
   w.cast_actors[actor_id].visible=false
   w.cast_actors[actor_id].is_body=actor_id in context.get("dead_actor_ids",[])
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
static func draw(w:Node2D)->void:
 var m:Dictionary=w.layout;var s:=spatial(w);var style:String=m.get("style","")
 var cliff:bool=style=="baizhang_cliff"
 var tomb:bool=style in ["baizhang_tomb","baizhang_duel"]
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("3d4550") if cliff else Color("454c43"))
 w.draw_rect(r(m.walk_bounds),Color("8b929a") if cliff else Color("8a806b"))
 for y in range(72,288,24):
  for x in range(40,448,32):w.draw_rect(Rect2(x,y,30,22),Color("9d9e9a") if cliff else Color("a09277"),false,1)
 for solid in m.solids:
  w.draw_rect(r(solid),Color("555c62") if cliff else Color("655b4b"))
  w.draw_rect(Rect2(solid[0],solid[1],solid[2],4),Color("b6aa8a"))
 if tomb:
  w.draw_rect(Rect2(144,88,64,24),Color("646a63"));w.draw_rect(Rect2(160,64,32,36),Color("aaa99a"))
  w.draw_line(Vector2(168,76),Vector2(184,76),Color("4a5049"),1)
  if s.get("local_objects",{}).get("jing_inscribed",false) or w.runtime_context.get("world_objects",{}).get("ch15_burial",{}).get("inscription","")=="靖":
   w.draw_line(Vector2(171,80),Vector2(171,92),Color("343b36"),2);w.draw_line(Vector2(177,80),Vector2(184,80),Color("343b36"),1);w.draw_rect(Rect2(177,84,7,7),Color("343b36"),false,1)
  for at in [Vector2(96,96),Vector2(368,80),Vector2(368,256)]:
   w.draw_line(at,at+Vector2(0,24),Color("594c36"),4);w.draw_circle(at,16,Color("59684d"))
 match style:
  "baizhang_tongzhou","baizhang_road","baizhang_eastroad":
   w.draw_rect(Rect2(32,240,416,24),Color("b4a37f"))
   for x in range(56,448,64):w.draw_line(Vector2(x,32),Vector2(x+10,60),Color("625638"),4)
   if style=="baizhang_tongzhou":w.draw_rect(Rect2(208,144,48,16),Color("9c8864"))
   if style=="baizhang_eastroad":
    w.draw_rect(Rect2(0,40,480,8),Color("cda26f"));w.draw_line(Vector2(392,64),Vector2(392,104),Color("60533a"),3)
  "baizhang_baizhang":
   w.draw_rect(Rect2(144,128,192,96),Color("777d7e"));w.draw_rect(Rect2(152,136,176,80),Color("989b95"),false,2)
   if not s.get("local_objects",{}).get("lock_released",false):
    w.draw_rect(Rect2(232,152,16,44),Color("514a42"));w.draw_line(Vector2(216,176),Vector2(264,184),Color("333943"),3)
  "baizhang_cliff":
   w.draw_rect(Rect2(32,32,416,32),Color("242e3d"))
   for x in range(48,432,40):w.draw_line(Vector2(x,56),Vector2(x+20,72),Color("c2c8c8"),3)
   w.draw_rect(Rect2(288,112,64,16),Color("afb4af"))
   if "follower_baichier" in w.runtime_context.get("dead_actor_ids",[]) or s.get("local_objects",{}).get("dog_protected",false):
    w.draw_rect(Rect2(96,176,20,7),Color("a39c88"))
  "baizhang_clinic":
   w.draw_rect(Rect2(144,72,216,16),Color("5e4934"));w.draw_rect(Rect2(136,64,232,12),Color("b3a27a"))
   w.draw_circle(Vector2(112,96),16,Color("777c73"));w.draw_circle(Vector2(112,96),10,Color("354f59"))
   w.draw_rect(Rect2(160,192,32,10),Color("8d9d99"))
   if s.get("local_objects",{}).get("door_repaired",false):w.draw_rect(Rect2(312,88,16,32),Color("96764d"))
   if s.get("local_objects",{}).get("lantern_hung",false):
    w.draw_line(Vector2(352,176),Vector2(352,196),Color("69573b"),1);w.draw_rect(Rect2(347,192,10,12),Color("e3bc64"))
 if s.get("carried_object","")!="" and s.get("player_position") is Array:
  var pos:=p(s.player_position);w.draw_rect(Rect2(pos-Vector2(8,20),Vector2(16,10)),Color("b5b0a2"))
 if s.get("target_position") is Array:
  var at:=p(s.target_position);w.draw_rect(Rect2(at-Vector2(5,2),Vector2(10,4)),Color("d8b968"),false,1)
