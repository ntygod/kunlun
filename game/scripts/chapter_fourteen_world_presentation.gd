class_name ChapterFourteenWorldPresentation
extends RefCounted
## Authored MG21–22 development primitives, explicitly not final pixel assets.
## Pure projection: no rewards, timers, inventory mutation or objective completion.
const NAMES := {"梁萧":"char_liang_xiao","花晓霜":"char_hua_xiaoshuang","晓霜":"char_hua_xiaoshuang","柳莺莺":"char_liu_yingying","花生":"char_huasheng","幼帝":"npc_zhao_bing","赵昺":"npc_zhao_bing","郭守敬":"npc_guo_shoujing","九如":"npc_jiuru","九如和尚":"npc_jiuru","九如神僧":"npc_jiuru","全太后":"npc_quan_taihou","八思巴":"npc_basiba","萧玉翎":"char_xiao_yuling","萧千绝":"npc_xiao_qianjue","萧冷":"npc_xiao_leng","病人":"npc_ch14_patient","士卒":"npc_ch14_soldier"}
static func p(a:Array)->Vector2:return Vector2(a[0],a[1])
static func r(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func spatial(w:Node2D)->Dictionary:
 if not w.controlled_view.is_empty():return w.controlled_view
 var saved:Dictionary=w.runtime_context.get("world_objects",{}).get("ch14_spatial_state",{})
 return saved if saved.get("map_id","")==w.scene_data.get("map_id","") and saved.get("phase","")==w.scene_data.get("id","") else {}
static func project(w:Node2D,context:Dictionary)->void:
 var s:Dictionary=context.get("world_objects",{}).get("ch14_spatial_state",{})
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
static func draw(w:Node2D)->void:
 var m:Dictionary=w.layout;var s:=spatial(w);var style:String=m.get("style","")
 var woodland:bool=style in ["capital_zizhu","capital_dawn"]
 w.draw_rect(Rect2(Vector2.ZERO,w.map_size),Color("393146") if woodland else Color("494d58"))
 w.draw_rect(r(m.walk_bounds),Color("746a79") if woodland else Color("a3a19a"))
 for y in range(72,288,24):
  for x in range(40,448,32):w.draw_rect(Rect2(x,y,30,22),Color("79717f") if woodland else Color("b1ada3"),false,1)
 for solid in m.solids:
  w.draw_rect(r(solid),Color("504555") if woodland else Color("686b72"))
  w.draw_rect(Rect2(solid[0],solid[1],solid[2],4),Color("a7a7aa"))
 if woodland:
  for x in range(8,480,24):
   for y in [16,296]:
    w.draw_line(Vector2(x,y+32),Vector2(x+5,y),Color("4d5b53"),3)
    w.draw_line(Vector2(x+5,y+9),Vector2(x+15,y+4),Color("66725f"),2)
  if "char_xiao_yuling" in w.runtime_context.get("dead_actor_ids",[]):
   w.draw_rect(Rect2(184,168,40,14),Color("8b8190"));w.draw_line(Vector2(184,168),Vector2(224,168),Color("c5bec8"),1)
 else:
  w.draw_rect(Rect2(32,24,416,32),Color("59484b"));w.draw_rect(Rect2(24,20,432,8),Color("967b62"))
 match style:
  "capital_observatory":
   w.draw_circle(Vector2(136,112),24,Color("8f7954"),false,2)
   w.draw_line(Vector2(112,112),Vector2(160,112),Color("ccb875"),2)
   w.draw_line(Vector2(136,88),Vector2(136,136),Color("ccb875"),2)
   w.draw_rect(Rect2(316,90,8,88),Color("6b543c"));w.draw_rect(Rect2(264,176,136,8),Color("c4b28a"))
   for x in range(272,400,8):w.draw_line(Vector2(x,176),Vector2(x,180),Color("635b50"),1)
  "capital_alley":
   w.draw_rect(Rect2(72,80,96,48),Color("7b6046"));w.draw_rect(Rect2(68,76,104,8),Color("c8bfa1"))
   for x in [88,112,136]:w.draw_rect(Rect2(x,104,12,8),Color("798861"))
  "capital_festival":
   for x in range(64,416,64):
    w.draw_line(Vector2(x,32),Vector2(x,72),Color("b79665"),1);w.draw_rect(Rect2(x-6,58,12,14),Color("b2654b"))
   w.draw_rect(Rect2(320,64,96,16),Color("c2bfb5"))
  "capital_nunnery":
   w.draw_rect(Rect2(320,64,80,64),Color("5e555b"));w.draw_rect(Rect2(336,80,48,48),Color("282936"))
   if not s.get("local_objects",{}).get("abduction_discovered",false):
    for at in [Vector2(352,128),Vector2(368,144)]:w.draw_circle(at,14,Color("6c6078"))
  "capital_temple_gate":
   w.draw_rect(Rect2(336,64,64,112),Color("5a473b"));w.draw_rect(Rect2(344,72,48,96),Color("9d7d47"))
   if s.get("local_objects",{}).get("gate_open",false):w.draw_rect(Rect2(352,96,32,80),Color("30303b"))
   if s.get("carried_object","")!="stone_lion":
    w.draw_rect(Rect2(304,176,32,12),Color("a5a6a1"));w.draw_circle(Vector2(320,172),10,Color("bdbfb7"))
  "capital_temple_hall":
   w.draw_rect(Rect2(160,64,160,32),Color("a98d55"))
   for at in [Vector2(96,112),Vector2(384,112),Vector2(96,256),Vector2(384,256)]:
    w.draw_circle(at,14,Color("b09352"),false,3);w.draw_line(at-Vector2(10,0),at+Vector2(10,0),Color("cfba76"),2)
  "capital_dawn":
   w.draw_rect(Rect2(32,56,416,8),Color("c7b396"))
   if s.get("local_objects",{}).get("hands_held",false):w.draw_rect(Rect2(116,176,24,10),Color("bdaf9a"))
 if s.get("carried_object","")!="" and s.get("player_position") is Array:
  var pos:=p(s.player_position);w.draw_rect(Rect2(pos-Vector2(8,20),Vector2(16,10)),Color("b5b0a2"))
 if s.get("target_position") is Array:
  var at:=p(s.target_position);w.draw_rect(Rect2(at-Vector2(5,2),Vector2(10,4)),Color("d8b968"),false,1)
