class_name PixelActor
extends Node2D
## Hand-authored development pixel silhouette, not final animation/portrait art.
var robe := Color("b9bcac")
var facing := Vector2.DOWN
var walking := false
var clock := 0.0
var is_body := false
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-8, -2, 16, 4), Color(0.08, 0.11, 0.14, 0.45))
	if is_body:
		draw_rect(Rect2(-17,-7,28,8),robe.darkened(0.35))
		draw_rect(Rect2(10,-8,7,7),Color("a39888"))
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
