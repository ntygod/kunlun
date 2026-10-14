class_name GlyphBoard
extends Control
## Guided strokes: mouse endpoint pairs or keyboard cursor + Enter. No success button.
signal completed(proof: Dictionary)
var glyph := "文"
var stroke_index := 0
var pen_down := false
var cursor := Vector2.ZERO
var done := false
var strokes: Array = []
var trace_points: Array = []
func setup(value: String) -> void:
	glyph = value
	# Normalized hand-authored teaching paths, not a calligraphy scoring system.
	strokes = [
		[[0.18,0.12],[0.24,0.20]],[[0.13,0.31],[0.22,0.39]],[[0.12,0.60],[0.27,0.42]],
		[[0.38,0.17],[0.70,0.17],[0.65,0.45]],[[0.51,0.20],[0.38,0.43]],
		[[0.77,0.30],[0.85,0.39]],[[0.70,0.45],[0.82,0.51]],
		[[0.25,0.61],[0.83,0.61]],[[0.54,0.52],[0.54,0.93]],
		[[0.51,0.65],[0.22,0.89]],[[0.58,0.66],[0.88,0.91]]
	] if glyph == "梁" else [
		[[0.47,0.10],[0.56,0.22]],[[0.18,0.30],[0.84,0.30]],
		[[0.68,0.34],[0.49,0.64],[0.19,0.91]],[[0.31,0.35],[0.49,0.64],[0.84,0.91]]]
	if glyph == "靖":
		strokes = [[[0.22,0.10],[0.26,0.17]],[[0.08,0.24],[0.42,0.24]],[[0.14,0.34],[0.23,0.58]],[[0.35,0.31],[0.28,0.63]],[[0.07,0.71],[0.43,0.64]],[[0.49,0.17],[0.91,0.17]],[[0.52,0.29],[0.88,0.29]],[[0.71,0.08],[0.71,0.42]],[[0.45,0.42],[0.94,0.42]],[[0.54,0.52],[0.54,0.94]],[[0.54,0.52],[0.86,0.52],[0.86,0.94]],[[0.55,0.67],[0.85,0.67]],[[0.55,0.81],[0.85,0.81]]]
	trace_points = []
	custom_minimum_size = Vector2(260,170)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	stroke_index = 0
	pen_down = false
	done = false
	queue_redraw()
func point(normalized: Array) -> Vector2:
	var side := maxf(1,minf(size.x,size.y)-32)
	var origin := (size-Vector2.ONE*side)*0.5
	return origin+Vector2(normalized[0],normalized[1])*side
func current_start() -> Vector2:
	return point(strokes[stroke_index][0])
func current_end() -> Vector2:
	return point(strokes[stroke_index][-1])
func tap(at: Vector2) -> bool:
	if done: return false
	var target := current_end() if pen_down else current_start()
	if at.distance_to(target) > 14:
		if pen_down and not trace_points.is_empty(): trace_points.pop_back()
		pen_down = false
		queue_redraw()
		return false
	var side := maxf(1,minf(size.x,size.y)-32)
	var normalized := (at-(size-Vector2.ONE*side)*0.5)/side
	trace_points.append([normalized.x,normalized.y])
	if not pen_down:
		pen_down = true
	else:
		pen_down = false
		stroke_index += 1
		if stroke_index == strokes.size():
			done = true
			completed.emit({"glyph":glyph,"strokes":stroke_index,"points":trace_points.duplicate(true)})
		else:
			cursor = current_start()
	queue_redraw()
	return true
func _gui_input(event: InputEvent) -> void:
	if done: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		cursor = event.position
		tap(event.position)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if cursor == Vector2.ZERO: cursor = current_start()
		match event.keycode:
			KEY_LEFT: cursor.x -= 8
			KEY_RIGHT: cursor.x += 8
			KEY_UP: cursor.y -= 8
			KEY_DOWN: cursor.y += 8
			KEY_ENTER, KEY_SPACE: tap(cursor)
			_: return
		cursor = cursor.clamp(Vector2.ZERO,size)
		queue_redraw()
		accept_event()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("28352f"))
	for i in range(strokes.size()):
		var points := PackedVector2Array()
		for p in strokes[i]: points.append(point(p))
		draw_polyline(points,Color("d0c19a") if i < stroke_index else Color("46534a"),3)
	if not done and not strokes.is_empty():
		draw_circle(current_start(),7,Color("7fbdad") if not pen_down else Color("566a62"))
		draw_circle(current_end(),7,Color("e2b769") if pen_down else Color("6a6151"))
		if cursor != Vector2.ZERO: draw_circle(cursor,10,Color("ebe4c4"),false,1)
