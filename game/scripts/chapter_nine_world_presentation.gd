class_name ChapterNineWorldPresentation
extends RefCounted
## Hand-authored pixel primitives. Development candidates, never final commissioned art.
## Read-only projection: this layer cannot grant rewards, revive actors, or finish a puzzle.
const NAMES := {"梁萧":"char_liang_xiao","阿雪":"char_axue","郭守敬":"npc_guo_shoujing","公羊羽":"npc_gongyang_yu","萧千绝":"npc_xiao_qianjue","贺陀罗":"npc_he_tuoluo","阿术":"npc_ashu","李庭":"npc_li_ting","伯颜":"npc_bayan","哈里斯":"npc_halis","云殊":"char_yun_shu","靳飞":"npc_jin_fei","方澜":"npc_ch09_fang_lan","张郎中":"npc_ch09_physician","小喜子":"npc_ch09_xixizi"}
static func p(value: Array) -> Vector2:return Vector2(value[0],value[1])
static func r(value: Array) -> Rect2:return Rect2(value[0],value[1],value[2],value[3])
static func spatial(w: Node2D) -> Dictionary:
	if not w.controlled_view.is_empty():return w.controlled_view
	var prior:Dictionary=w.runtime_context.get("world_objects",{}).get("ch09_spatial_state",{})
	return prior if prior.get("map_id","")==w.scene_data.get("map_id","") else {}
static func project(w: Node2D,context: Dictionary) -> void:
	var s:Dictionary=context.get("world_objects",{}).get("ch09_spatial_state",{})
	if s.get("map_id","")==w.scene_data.get("map_id",""):
		for id in w.cast_actors:
			if s.get("actor_positions",{}).has(id):w.cast_actors[id].position=p(s.actor_positions[id])
			if s.has("visible_actor_ids"):w.cast_actors[id].visible=id in s.visible_actor_ids and id!=w.player.actor_id
	# A scene companion never becomes a combat member or receives a resource refill here.
	w.player.movement_multiplier=1.0
static func sync(w: Node2D,view: Dictionary) -> void:
	w.controlled_view=view.get("world_state",{}).duplicate(true)
	var s:Dictionary=w.controlled_view
	if s.is_empty() or not w.player:return
	if s.get("map_id","")!=w.scene_data.get("map_id",""):w.controlled_view.clear();return
	var id:String=s.get("control_actor_id","char_liang_xiao")
	w.player.actor_id=id;w.player.appearance="youth_age_18" if id=="char_liang_xiao" else "adult"
	if s.has("player_position"):
		var delta:Vector2=p(s.player_position)-w.player.position
		w.player.position=p(s.player_position)
		if delta!=Vector2.ZERO:w.player.visual.facing=delta.normalized()
	w.player.carrying_actor_id="";w.player.refresh_appearance()
	for actor_id in w.cast_actors:
		var actor:PixelActor=w.cast_actors[actor_id]
		var should_show:bool=actor_id in s.get("visible_actor_ids",[]) and actor_id!=id
		if actor_id in ["well_soldier_1","well_soldier_2"] and s.get("actor_positions",{}).has(actor_id):
			var next:Vector2=p(s.actor_positions[actor_id]);var path:Array=s.get("actor_paths",{}).get(actor_id,[])
			var seen:bool=actor.has_meta("ch09_seen_position")
			var previous:Vector2=actor.get_meta("ch09_seen_position",next)
			if seen and previous!=next and path.size()>1:
				if w.ch08_actor_tweens.has(actor_id) and w.ch08_actor_tweens[actor_id].is_valid():w.ch08_actor_tweens[actor_id].kill()
				actor.visible=true;actor.position=p(path[0]);actor.walking=true
				var motion:Tween=w.create_tween();w.ch08_actor_tweens[actor_id]=motion
				for at in path.slice(1):motion.tween_property(actor,"position",p(at),0.07)
				motion.tween_property(actor,"walking",false,0);motion.tween_property(actor,"visible",should_show,0)
			elif not seen or not w.ch08_actor_tweens.has(actor_id) or not w.ch08_actor_tweens[actor_id].is_running():actor.position=next;actor.visible=should_show
			actor.set_meta("ch09_seen_position",next)
		else:
			actor.visible=should_show
			if s.get("actor_positions",{}).has(actor_id):
				var next:Vector2=p(s.actor_positions[actor_id]);var delta:Vector2=next-actor.position
				actor.position=next
				if delta!=Vector2.ZERO:actor.facing=delta.normalized()
		actor.resting=s.get("actor_postures",{}).get(actor_id,"")=="resting"
		actor.is_body=actor_id in w.runtime_context.get("dead_actor_ids",[])
		actor.refresh_texture()
	w.queue_redraw()
static func pine(w: Node2D,at: Vector2,cut: bool=false) -> void:
	w.draw_rect(Rect2(at+Vector2(-4,-38 if not cut else -10),Vector2(8,38 if not cut else 10)),Color("66513a"))
	w.draw_rect(Rect2(at+Vector2(-2,-37 if not cut else -9),Vector2(2,37 if not cut else 9)),Color("9e8150"))
	if cut:
		w.draw_rect(Rect2(at+Vector2(-5,-12),Vector2(10,3)),Color("d7bd78"));return
	for row in [[-26,-42,52,10],[-21,-51,42,10],[-13,-60,30,10],[-9,-66,20,8]]:
		w.draw_rect(Rect2(at+Vector2(row[0],row[1]),Vector2(row[2],row[3])),Color("365548"))
		w.draw_rect(Rect2(at+Vector2(row[0]+3,row[1]),Vector2(row[2]-6,2)),Color("688471"))
	w.draw_rect(Rect2(at+Vector2(4,-44),Vector2(20,3)),Color("66513a"))
static func roof(w: Node2D,at: Vector2,width: int,color: Color,broken: bool=false) -> void:
	w.draw_rect(Rect2(at+Vector2(-width/2,0),Vector2(width,26)),Color("796d59"))
	for i in range(6):
		var inset:=i*4
		w.draw_rect(Rect2(at+Vector2(-width/2-8+inset,-i*4),Vector2(width+16-inset*2,4)),color.lightened(float(i%2)*0.08))
	w.draw_rect(Rect2(at+Vector2(-width/2-10,0),Vector2(width+20,3)),color.darkened(0.25))
	if broken:w.draw_rect(Rect2(at+Vector2(6,-10),Vector2(14,10)),Color("393e3e"))
	for x in [-width/2+8,width/2-12]:w.draw_rect(Rect2(at+Vector2(x,3),Vector2(4,23)),Color("574b3c"))
	w.draw_rect(Rect2(at+Vector2(-8,7),Vector2(16,19)),Color("393d35"))
static func tent(w: Node2D,at: Vector2,width: int,empty: bool=false) -> void:
	w.draw_colored_polygon(PackedVector2Array([at+Vector2(-width/2,18),at+Vector2(-width/2+8,-20),at+Vector2(0,-38),at+Vector2(width/2-8,-20),at+Vector2(width/2,18)]),Color("8d8975"))
	w.draw_line(at+Vector2(0,-38),at+Vector2(0,17),Color("c1b99a"),2)
	w.draw_colored_polygon(PackedVector2Array([at+Vector2(-12,18),at+Vector2(0,-12),at+Vector2(12,18)]),Color("353e39"))
	for x in [-width/2,width/2]:w.draw_line(at+Vector2(x,-3),at+Vector2(x+(-10 if x<0 else 10),24),Color("c1b99a"),1)
	if empty:w.draw_rect(Rect2(at+Vector2(-9,8),Vector2(18,3)),Color("665d4d"))
static func well(w: Node2D,at: Vector2) -> void:
	w.draw_rect(Rect2(at+Vector2(-15,-10),Vector2(30,18)),Color("727777"))
	w.draw_rect(Rect2(at+Vector2(-11,-12),Vector2(22,8)),Color("303c40"))
	for y in [-9,-2,5]:w.draw_line(at+Vector2(-15,y),at+Vector2(15,y),Color("a2a296"),1)
	w.draw_rect(Rect2(at+Vector2(-17,-13),Vector2(34,3)),Color("b6b5a3"))
static func table(w: Node2D,at: Vector2,width: int=48) -> void:
	w.draw_rect(Rect2(at+Vector2(-width/2,-13),Vector2(width,9)),Color("98724b"))
	w.draw_rect(Rect2(at+Vector2(-width/2,-14),Vector2(width,2)),Color("c4a66e"))
	for x in [-width/2+3,width/2-6]:w.draw_rect(Rect2(at+Vector2(x,-4),Vector2(3,8)),Color("614c38"))
static func medicine_box(w: Node2D,at: Vector2,s: Dictionary) -> void:
	w.draw_rect(Rect2(at+Vector2(-23,-31),Vector2(46,25)),Color("775434"))
	for row in range(4):
		for col in range(6):
			w.draw_rect(Rect2(at+Vector2(-21+col*7,-29+row*5),Vector2(6,4)),Color("b2a378") if s.get("unlocked",false) else Color("9c7850"))
	w.draw_rect(Rect2(at+Vector2(-22,-9),Vector2(44,4)),Color("c2a26c"))
	# Public left-leaf, middle-flower, right-fruit marks are visible on the actual chest.
	w.draw_line(at+Vector2(-13,-38),at+Vector2(-9,-43),Color("9fbe7e"),2)
	for q in [Vector2(0,-43),Vector2(-3,-40),Vector2(3,-40)]:w.draw_rect(Rect2(at+q,Vector2(3,3)),Color("dbbca2"))
	w.draw_rect(Rect2(at+Vector2(11,-42),Vector2(5,5)),Color("d29f56"))
	w.draw_rect(Rect2(at+Vector2(25,-20),Vector2(13,15)),Color("d3c8a6"));w.draw_line(at+Vector2(28,-17),at+Vector2(35,-17),Color("8a7b60"),1)
static func wood_bird(w: Node2D,s: Dictionary) -> void:
	var bird:Dictionary=s.get("wood_bird",{})
	if bird.is_empty():return
	var stage:String=bird.get("stage","")
	if stage in ["drifted","completed"]:return
	var at:Vector2=p(bird.get("position",[240,192]))
	var installed:Variant=bird.get("installed",s.get("installed",{}))
	var built:bool=stage not in ["collecting","assembling",""]
	w.draw_line(at+Vector2(-10,4),at+Vector2(10,4),Color("675339"),2)
	if built or "body" in installed:w.draw_rect(Rect2(at+Vector2(-13,-14),Vector2(26,16)),Color("bb9d65"))
	if built or "left_wing" in installed:
		w.draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-11),at+Vector2(-42,-19),at+Vector2(-34,-3),at+Vector2(-8,0)]),Color("d2bb80"));w.draw_line(at+Vector2(-10,-9),at+Vector2(-39,-15),Color("81673e"),2)
	if built or "right_wing" in installed:
		w.draw_colored_polygon(PackedVector2Array([at+Vector2(8,-11),at+Vector2(42,-19),at+Vector2(34,-3),at+Vector2(8,0)]),Color("d2bb80"));w.draw_line(at+Vector2(10,-9),at+Vector2(39,-15),Color("81673e"),2)
	if built or "tail" in installed:w.draw_rect(Rect2(at+Vector2(-4,1),Vector2(8,14)),Color("bba06a"))
	if built or "frame" in installed:w.draw_line(at+Vector2(-10,-14),at+Vector2(10,0),Color("725f3d"),2)
	if built or "linkage" in installed:
		for dx in [-24,-12,12,24]:
			var q:=at+Vector2(dx,-8);w.draw_line(q-Vector2(4,0),q+Vector2(4,0),Color("f0d494"),1);w.draw_line(q-Vector2(0,4),q+Vector2(0,4),Color("f0d494"),1)
	if stage=="stalled":w.draw_line(at+Vector2(-20,18),at+Vector2(-16,26),Color("d2d8d0"),2)
	if stage=="palm_lifted":w.draw_arc(at+Vector2(0,20),22,PI,TAU,12,Color("c8dfd8"),2)
static func draw(w: Node2D) -> void:
	var layout:Dictionary=w.layout;var style:String=layout.style;var s:=spatial(w)
	var objects:Dictionary=w.runtime_context.get("world_objects",{});var items:Dictionary=w.runtime_context.get("items",{})
	var ground:=Color({"shigong_platform":"7b8b82","pine_terrace":"788a70","tiandu_peak":"89989a","jingkou_camp":"91856b","changzhou_street":"938274","west_temple":"8b886f","command_tent":"85715d","linan_residence":"9e9c87"}.get(style,"87887a"))
	w.draw_rect(Rect2(Vector2.ZERO,w.map_size),ground.darkened(0.48))
	w.draw_rect(r(layout.walk_bounds),ground)
	var bounds:=r(layout.walk_bounds)
	for y in range(int(bounds.position.y)+4,int(bounds.end.y),16):
		for x in range(int(bounds.position.x)+4,int(bounds.end.x),32):
			w.draw_rect(Rect2(x,y,17,1),ground.darkened(0.09))
			w.draw_rect(Rect2(x+8,y+9,4,1),ground.lightened(0.08))
	# A continuous authored pale lane shows the bottom route between entrances.
	w.draw_rect(Rect2(32,int(layout.spawn[1])-7,int(layout.size[0])-64,14),ground.lightened(0.10))
	for obstacle in layout.solids:
		w.draw_rect(r(obstacle),ground.darkened(0.38));w.draw_rect(Rect2(obstacle[0],obstacle[1],obstacle[2],3),ground.lightened(0.23))
	match style:
		"shigong_platform":
			for at in [Vector2(48,72),Vector2(464,88)]:pine(w,at)
			for row in range(3):
				for col in range(5):
					var at:=Vector2(192+col*20,116+row*14);w.draw_rect(Rect2(at,Vector2(12,8)),Color("adaba0"));w.draw_line(at,at+Vector2(0,-9),Color("5a5141"),1)
			table(w,Vector2(112,155),30);w.draw_rect(Rect2(109,128,3,17),Color("baaa69"));w.draw_rect(Rect2(103,144,18,2),Color("d4be78"))
			w.draw_line(Vector2(312,184),Vector2(368,184),Color("d3c09a"),2)
			if s.get("stage",0)>0:w.draw_arc(Vector2(336,150),28,0,PI,16,Color("c7cbb4"),1)
		"pine_terrace":
			for at in [Vector2(48,88),Vector2(176,96),Vector2(344,88)]:pine(w,at)
			w.draw_rect(Rect2(108,132,40,14),Color("b0b2a0"));w.draw_rect(Rect2(111,135,34,8),Color("727f73"))
			for i in range(4):
				var at:=Vector2([96,176,256,320][i],152)
				if i<2:w.draw_line(at-Vector2(7,3),at+Vector2(7,3),Color("c1ae70"),2)
				else:w.draw_rect(Rect2(at-Vector2(4,8),Vector2(8,14)),Color("af8154"));w.draw_line(at-Vector2(0,14),at+Vector2(0,4),Color("d2b780"),1)
				if int(s.get("stage",0))>i:w.draw_arc(at,14,0,TAU,16,Color("c7cfb6"),1)
		"tiandu_peak":
			for y in [24,40,56]:
				for x in [24,152,344,472]:w.draw_rect(Rect2(x+y%24,y,86,4),Color("c5d0ce"))
			pine(w,Vector2(128,120),w.runtime_context.get("world_objects",{}).has("ch09_pine_materials"))
			for y in [188,196]:w.draw_line(Vector2(232,y),Vector2(312,y),Color("5e5b4b"),2)
			for x in range(232,313,16):w.draw_rect(Rect2(x,184,3,16),Color("b4a27a"))
			for at in [Vector2(176,144),Vector2(304,144),Vector2(176,240),Vector2(304,240)]:w.draw_circle(at,3,Color("c3b289"))
			wood_bird(w,s)
		"jingkou_camp":
			w.draw_rect(Rect2(0,0,608,64),Color("446d78"))
			for x in range(0,608,40):w.draw_line(Vector2(x,48),Vector2(x+20,48),Color("88a5a5"),1)
			tent(w,Vector2(240,112),112,true);tent(w,Vector2(440,112),72)
			if objects.get("ch09_wang_stone",{}).get("location","")=="jingkou_empty_tent":w.draw_rect(Rect2(216,154,14,7),Color("777b70"))
			if objects.get("ch09_charred_tag",{}).get("owner","") in ["npc_liting","npc_li_ting"]:w.draw_rect(Rect2(274,180,6,9),Color("4b4035"))
			if not items.has("item_ch09_wang_hammer"):
				w.draw_line(Vector2(300,204),Vector2(300,218),Color("916d45"),2);w.draw_rect(Rect2(293,201,14,6),Color("7e8885"))
		"changzhou_street":
			for at in [Vector2(144,108),Vector2(344,108),Vector2(464,108)]:roof(w,at,72,Color("6d6961"),true)
			well(w,Vector2(456,202));w.draw_rect(Rect2(288,157,40,15),Color("a89b78"))
			for x in [296,312]:w.draw_rect(Rect2(x,151,8,3),Color("ded3b4"))
			for x in [192,208,224]:w.draw_line(Vector2(x,172),Vector2(x+9,184),Color("736b5a"),2)
		"west_temple":
			roof(w,Vector2(112,94),72,Color("6c776d"),true);well(w,Vector2(416,88))
			medicine_box(w,Vector2(112,160),s if not s.is_empty() else {"unlocked":objects.get("ch09_l05",{}).get("complete",false)})
			for x in [184,280,376]:
				w.draw_rect(Rect2(x-4,112,8,48),Color("6a5541"));w.draw_rect(Rect2(x-6,152,12,8),Color("a29c7f"))
			if s.get("decoys",false):
				for x in [280,296,312]:w.draw_line(Vector2(x,238),Vector2(x,253),Color("65533b"),2);w.draw_rect(Rect2(x,238,8,6),Color("b7a581"))
			for i in range(1,4):
				var id:="npc_ch09_raider_%d"%i;var data:Dictionary=s.get("looters",{}).get(id,{})
				if data.get("disarmed",false):w.draw_line(Vector2(64+96*i,180),Vector2(74+96*i,184),Color("b9bcb1"),2)
		"command_tent":
			w.draw_rect(Rect2(24,40,208,12),Color("ad9a75"));table(w,Vector2(120,88),48)
			w.draw_rect(Rect2(107,69,24,9),Color("d9cba6"));w.draw_rect(Rect2(112,71,14,1),Color("8a7352"))
			for x in [32,220]:w.draw_line(Vector2(x,48),Vector2(x,160),Color("b2a079"),2)
		"linan_residence":
			roof(w,Vector2(160,108),120,Color("63766b"));roof(w,Vector2(336,108),88,Color("63766b"))
			table(w,Vector2(192,172),56);table(w,Vector2(320,172),48)
			for x in [176,192,208]:w.draw_rect(Rect2(x,155,5,4),Color("d7cfb5"))
			w.draw_rect(Rect2(360,196,18,13),Color("84694b"));w.draw_line(Vector2(369,196),Vector2(369,209),Color("c4a176"),1)
			w.draw_line(Vector2(432,172),Vector2(472,172),Color("71593e"),3)
			for x in [436,468]:w.draw_line(Vector2(x,156),Vector2(x,184),Color("71593e"),3)
			w.draw_rect(Rect2(502,224,6,48),Color("6c705e"));w.draw_rect(Rect2(530,224,6,48),Color("6c705e"));w.draw_rect(Rect2(500,220,38,6),Color("899279"))
	if style=="linan_residence":
		var court:Array=["item_ch09_general_seal","item_ch09_court_robe","item_ch09_merit_armor","item_ch09_award_chest"]
		for i in range(court.size()):
			var item:Dictionary=items.get(court[i],{})
			if item.get("owner","")!="camp" or item.get("location","")!="linan_tent_rack":continue
			match i:
				0:w.draw_rect(Rect2(433,166,7,6),Color("b6a16d"))
				1:w.draw_colored_polygon(PackedVector2Array([Vector2(443,173),Vector2(439,180),Vector2(441,190),Vector2(449,190),Vector2(451,180),Vector2(447,173)]),Color("907f59"))
				2:w.draw_rect(Rect2(453,174,10,14),Color("87928c"));w.draw_line(Vector2(454,178),Vector2(462,178),Color("bac1ab"),1)
				3:w.draw_rect(Rect2(470,177,19,13),Color("92713d"));w.draw_line(Vector2(471,181),Vector2(488,181),Color("c3a85b"),2)
	for point in w.interactions:w.draw_circle(point.position,5,Color("e9ce8f"),false,1)
	if s.get("target_position") is Array and s.target_position.size()==2:w.draw_circle(p(s.target_position),8,Color("ffe09b"),false,2)
