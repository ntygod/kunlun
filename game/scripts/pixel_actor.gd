class_name PixelActor
extends Node2D
## Hand-authored development pixel silhouette, not final animation/portrait art.
var actor_id := ""
var appearance := "adult"
var texture: Texture2D
var texture_key := ""
var sword_state := ""

func refresh_texture() -> void:
	var key := actor_id + ":" + appearance
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
	var file := ""
	if actor_id == "char_liang_xiao":
		file = "liang_xiao_young"
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
	if is_body:
		draw_rect(Rect2(-17,-7,28,8),robe.darkened(0.35))
		draw_rect(Rect2(10,-8,7,7),Color("a39888"))
		return
	if actor_id == "follower_baichier":
		draw_rect(Rect2(-8, -9, 13, 7), Color("b1b5aa"))
		draw_rect(Rect2(3, -13, 7, 8), Color("c5c8ba"))
		draw_rect(Rect2(3, -13, 3, 4), Color("626c67"))
		draw_rect(Rect2(-7, -3, 3, 3), Color("7f8981"))
		draw_rect(Rect2(2, -3, 3, 3), Color("7f8981"))
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
		if not sword_state.is_empty():
			draw_rect(Rect2(9, -26, 3, 25), Color("a3a58e") if sword_state == "wrapped" else Color("b7c0b8"))
			if sword_state != "wrapped":
				draw_rect(Rect2(6, -22, 8, 2), Color("827457"))
		return
	if appearance == "child_age_10":
		draw_rect(Rect2(-5, -5, 4, 5), Color("292d31"))
		draw_rect(Rect2(2, -5, 4, 5), Color("292d31"))
		draw_rect(Rect2(-7, -21, 14, 17), Color("727f76"))
		draw_rect(Rect2(-5, -31, 10, 10), Color("c6ad8d"))
		draw_rect(Rect2(-6, -32, 12, 4), Color("252b31"))
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
