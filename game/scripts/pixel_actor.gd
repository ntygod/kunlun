class_name PixelActor
extends Node2D
## Hand-authored development pixel silhouette, not final animation/portrait art.
var actor_id := ""
var appearance := "adult"
var texture: Texture2D
var texture_key := ""
var sword_state := ""
var carrying_actor_id := ""
var mounted_on := ""
var pouch_visible := false
var inkstone_form := ""
var mount_texture: Texture2D
var riders_texture: Texture2D

func refresh_texture() -> void:
	var key := actor_id + ":" + appearance + ":" + carrying_actor_id
	if key == texture_key:
		return
	texture_key = key
	texture = null
	match actor_id:
		"char_xiao_yuling": robe = Color("a75952")
		"char_xiao_qianjue": robe = Color("333f49")
		"char_liang_wenjing": robe = Color("6b865d")
		"char_yun_shu": robe = Color("607987")
		"char_yun_wancheng": robe = Color("8b8772")
		"char_black_daoist": robe = Color("515567")
		"char_axue": robe = Color("789da4")
		"npc_bayan": robe = Color("486d8f")
		"npc_han_ningzi": robe = Color("8a6b94")
		"char_liu_yingying": robe = Color("668d64")
		"char_hua_xiaoshuang": robe = Color("adbdab")
		"char_qin_bofu": robe = Color("6d7479")
		"char_hua_qingyuan": robe = Color("769086")
		"char_hua_murong": robe = Color("a3818b")
		"char_ling_shuangjun": robe = Color("767888")
		"char_hua_wuchi": robe = Color("7b727e")
		"char_jiuru", "char_huasheng", "npc_jiu_ru", "npc_shi_haiyu": robe = Color("a79760")
		"npc_chu_wan": robe = Color("a5818d")
		"npc_chu_xianliu": robe = Color("a6ac9d")
		"npc_old_zhou": robe = Color("7c6a53")
		"char_zuo_yuan": robe = Color("747e80")
		"char_mei_ying": robe = Color("aa8f88")
		"char_liang_xiao": robe = Color("a99772")
	var file := ""
	if actor_id == "char_liang_xiao":
		file = "liang_xiao_tianji_16" if appearance in ["youth_age_16", "youth_age_17"] else "liang_xiao_young"
	elif actor_id == "animal_yanzhi":
		file = "horse_yanzhi"
	elif actor_id == "char_liu_yingying":
		file = "liu_carrying_liang" if carrying_actor_id == "char_liang_xiao" else "liu_yingying_jiangnan_16"
	elif actor_id == "char_axue":
		file = "axue_plain_16"
	elif actor_id == "char_hua_xiaoshuang":
		if appearance == "youth_age_15":
			file = "hua_xiaoshuang_tianji_15"
		elif appearance in ["child_age_10", "child_age_11"]:
			file = "hua_xiaoshuang_child"
	elif actor_id == "char_liang_wenjing":
		file = "liang_wenjing_carrying_xiao" if appearance == "carrying_child" else "liang_wenjing"
	elif actor_id == "char_liang_tiande":
		file = "liang_tiande"
	elif actor_id == "char_xiao_yuling":
		file = "xiao_yuling"
	var path := "res://assets/pixel_candidate/" + file + ".png"
	if not file.is_empty() and ResourceLoader.exists(path):
		texture = load(path)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

var robe := Color("b9bcac")
var facing := Vector2.DOWN
var walking := false
var clock := 0.0
var is_body := false
func _process(delta: float) -> void:
	clock += delta
	refresh_texture()
	queue_redraw()
func _draw() -> void:
	draw_set_transform(global_position.round() - global_position)
	draw_rect(Rect2(-8, -2, 16, 4), Color(0.08, 0.11, 0.14, 0.45))
	if mounted_on == "animal_yanzhi":
		if not mount_texture: mount_texture = load("res://assets/pixel_candidate/horse_yanzhi.png")
		if not riders_texture: riders_texture = load("res://assets/pixel_candidate/horse_yanzhi_riders.png")
		var row := 1 if facing == Vector2.UP else (2 if facing == Vector2.LEFT else (3 if facing == Vector2.RIGHT else 0))
		var frame := 1 + int(clock * 8) % 4 if walking else 0
		var source := Rect2(frame*64,row*64,64,64)
		draw_texture_rect_region(mount_texture,Rect2(-32,-58,64,64),source)
		draw_texture_rect_region(riders_texture,Rect2(-32,-58,64,64),source)
		return
	if is_body:
		draw_rect(Rect2(-17,-7,28,8),robe.darkened(0.35))
		draw_rect(Rect2(10,-8,7,7),Color("a39888"))
		return
	if actor_id == "animal_yanzhi":
		if texture:
			var row := 1 if facing == Vector2.UP else (2 if facing == Vector2.LEFT else (3 if facing == Vector2.RIGHT else 0))
			var frame := 1 + int(clock * 8) % 4 if walking else 0
			draw_texture_rect_region(texture,Rect2(-32,-58,64,64),Rect2(frame*64,row*64,64,64))
			return
		draw_rect(Rect2(-22,-28,40,22),Color("e4ded1"))
		draw_rect(Rect2(12,-43,12,24),Color("e4ded1"))
		for p in [Vector2(-12,-24),Vector2(2,-19),Vector2(15,-36)]: draw_rect(Rect2(p,Vector2(7,6)),Color("a85748"))
		for x in [-16,-8,8,15]: draw_rect(Rect2(x,-9,4,10),Color("d7cebc"))
		return
	if actor_id == "follower_jinlinger":
		draw_rect(Rect2(-5, -17, 10, 13), Color("b09a57"))
		draw_rect(Rect2(-6, -24, 12, 9), Color("c2aa70"))
		draw_rect(Rect2(-3, -20, 7, 5), Color("d6c5a0"))
		draw_line(Vector2(-5, -8), Vector2(-11, -4), Color("b09a57"), 2)
		draw_line(Vector2(-11, -4), Vector2(-13, -10), Color("b09a57"), 2)
		return
	if actor_id == "follower_baichier":
		draw_rect(Rect2(-8, -9, 13, 7), Color("b1b5aa"))
		draw_rect(Rect2(3, -13, 7, 8), Color("c5c8ba"))
		draw_rect(Rect2(3, -13, 3, 4), Color("626c67"))
		draw_rect(Rect2(-7, -3, 3, 3), Color("7f8981"))
		draw_rect(Rect2(2, -3, 3, 3), Color("7f8981"))
		return
	if actor_id == "char_axue" and not texture:
		# Dedicated modest plain-clothed candidate, not a reused named heroine.
		draw_rect(Rect2(-6,-24,12,22),Color("789da4"))
		draw_rect(Rect2(-5,-34,10,10),Color("c9b29f"))
		draw_rect(Rect2(-6,-36,12,5),Color("303b40"))
		draw_circle(Vector2(0,-39),3,Color("303b40"))
		draw_rect(Rect2(-7,-16,14,2),Color("d0d0bd"))
		draw_rect(Rect2(-5,-3,4,3),Color("394b52"));draw_rect(Rect2(1,-3,4,3),Color("394b52"))
		_draw_carried_passenger()
		return
	if texture:
		var row := 0
		if facing == Vector2.UP:
			row = 1
		elif facing == Vector2.LEFT:
			row = 2
		elif facing == Vector2.RIGHT:
			row = 3
		var frame := 1 + int(clock * 8) % 4 if walking else 0
		draw_texture_rect_region(texture, Rect2(-16, -44, 32, 48), Rect2(frame * 32, row * 48, 32, 48))
		_draw_story_weapon()
		_draw_carried_passenger()
		return
	if appearance.begins_with("child"):
		draw_rect(Rect2(-5, -5, 4, 5), Color("292d31"))
		draw_rect(Rect2(2, -5, 4, 5), Color("292d31"))
		draw_rect(Rect2(-7, -21, 14, 17), robe)
		draw_rect(Rect2(-5, -31, 10, 10), Color("c6ad8d"))
		draw_rect(Rect2(-6, -32, 12, 4), Color("252b31"))
		_draw_story_weapon()
		_draw_carried_passenger()
		return
	var step := (1 if int(clock * 8) % 2 == 0 else -1) if walking else 0
	draw_rect(Rect2(-8, -11, 6, 10 + step), Color("252b31"))
	draw_rect(Rect2(2, -11, 6, 10 - step), Color("252b31"))
	draw_rect(Rect2(-12, -29, 24, 22), Color("141820"))
	draw_rect(Rect2(-10, -28, 20, 19), robe.darkened(0.2))
	draw_rect(Rect2(-7, -28, 14, 17), robe)
	draw_rect(Rect2(-4, -26, 9, 3), robe.lightened(0.2))
	draw_rect(Rect2(3, -24, 3, 8), robe.darkened(0.45)) # Right lapel stays right.
	draw_rect(Rect2(-10,-14,20,3),Color("605449"))
	draw_rect(Rect2(-8,-39,16,13),Color("141820"))
	draw_rect(Rect2(-6,-35,12,9),Color("c6ad8d"))
	draw_rect(Rect2(-7,-39,14,5),Color("252b31"))
	draw_rect(Rect2(-3,-42,6,4),Color("252b31"))
	if facing == Vector2.UP:
		draw_rect(Rect2(-6,-35,12,9),Color("252b31"))
	else:
		var eye_x := -4 if facing.x < 0 else 3
		draw_rect(Rect2(eye_x,-32,2,2),Color("252b31"))
		if facing.x == 0:
			draw_rect(Rect2(-4,-32,2,2),Color("252b31"))

	if appearance == "carrying_child":
		# Composite body is one mover; the child's feet never walk ahead of the father.
		draw_rect(Rect2(0, -24, 13, 14), Color("727f76"))
		draw_rect(Rect2(3, -33, 10, 10), Color("c6ad8d"))
		draw_rect(Rect2(2, -34, 12, 4), Color("252b31"))
		draw_rect(Rect2(-4, -17, 16, 4), robe.lightened(0.1))

	_draw_story_weapon()
	_draw_carried_passenger()

func _draw_story_weapon() -> void:
	if pouch_visible:
		draw_rect(Rect2(-9,-17,5,7),Color("916b51"))
		draw_line(Vector2(-8,-18),Vector2(-4,-18),Color("b45b4d"),1)
	if not inkstone_form.is_empty():
		draw_rect(Rect2(-4,-24,5 if inkstone_form == "intact" else 3,3),Color("555e59"))
	if sword_state.is_empty():
		return
	draw_rect(Rect2(9, -26, 3, 25), Color("a3a58e") if sword_state == "wrapped" else Color("b7c0b8"))
	if sword_state != "wrapped":
		draw_rect(Rect2(6, -22, 8, 2), Color("827457"))

func _draw_carried_passenger() -> void:
	if actor_id == "char_liu_yingying" and carrying_actor_id == "char_liang_xiao" and texture:
		return # Hand-pixel composite already includes the passenger.
	if carrying_actor_id not in ["char_hua_xiaoshuang", "char_liu_yingying", "char_liang_xiao", "char_axue"]:
		return
	# Temporary piggyback silhouette: raised knees/feet and arms over the shoulder.
	# The passenger has no ground-contact feet and never becomes a second mover.
	var back_x := 5 if facing == Vector2.LEFT else -13
	if carrying_actor_id in ["char_liang_xiao","char_axue"]:
		var color:=Color("a99772") if carrying_actor_id=="char_liang_xiao" else Color("789da4")
		draw_rect(Rect2(back_x,-34,13,18),color)
		draw_rect(Rect2(back_x+1,-42,10,9),Color("c9b29f"))
		draw_rect(Rect2(back_x,-44,12,5),Color("333c3d"))
		draw_rect(Rect2(back_x-3,-20,19,4),color.darkened(0.2))
		return
	if carrying_actor_id == "char_liu_yingying":
		draw_rect(Rect2(back_x,-32,12,17),Color("638759"))
		draw_rect(Rect2(back_x+1,-41,10,10),Color("d3b398"))
		draw_rect(Rect2(back_x,-43,12,5),Color("26322d"))
		draw_circle(Vector2(back_x+6,-25),7,Color("a69b65"))
		draw_rect(Rect2(back_x-2,-18,17,4),Color("60845e"))
		return
	draw_rect(Rect2(back_x, -33, 9, 16), Color("869d8d"))
	draw_rect(Rect2(back_x + 1, -42, 9, 10), Color("c6bba0"))
	draw_rect(Rect2(back_x, -43, 11, 5), Color("28353b"))
	draw_rect(Rect2(back_x + 2, -39, 2, 1), Color("515651")) # Eyes closed, head rests on shoulder.
	if facing == Vector2.LEFT:
		draw_rect(Rect2(-1, -30, 12, 4), Color("adbdab"))
		draw_rect(Rect2(-4, -29, 5, 3), Color("c6bba0"))
		draw_rect(Rect2(2, -19, 12, 5), Color("adbdab"))
		draw_rect(Rect2(0, -16, 5, 6), Color("657874"))
		draw_rect(Rect2(-2, -11, 7, 3), Color("36474a"))
	else:
		draw_rect(Rect2(-9, -30, 13, 4), Color("adbdab"))
		draw_rect(Rect2(3, -29, 5, 3), Color("c6bba0"))
		draw_rect(Rect2(-13, -19, 12, 5), Color("adbdab"))
		draw_rect(Rect2(-3, -16, 5, 6), Color("657874"))
		draw_rect(Rect2(-3, -11, 7, 3), Color("36474a"))
