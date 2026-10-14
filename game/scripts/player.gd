class_name KunlunPlayer
extends CharacterBody2D
var enabled := true
var speed := 65.0
var visual: PixelActor
var bounds := Rect2(24, 55, 960, 120)
var actor_id := "char_liang_wenjing"
var appearance := "adult"
var carried_by := ""
var blocked_rects: Array[Rect2] = []

func refresh_appearance() -> void:
	if visual:
		visual.actor_id = carried_by if not carried_by.is_empty() else actor_id
		visual.appearance = "carrying_child" if not carried_by.is_empty() else appearance
		visual.refresh_texture()

func is_walkable(at: Vector2) -> bool:
	if at.x < bounds.position.x or at.x > bounds.end.x or at.y < bounds.position.y or at.y > bounds.end.y:
		return false
	for rect in blocked_rects:
		if rect.grow_individual(8, 4, 8, 4).has_point(at):
			return false
	return true

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	shape.shape = rect
	add_child(shape)
	visual = PixelActor.new()
	add_child(visual)
	refresh_appearance()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") if enabled else Vector2.ZERO
	velocity = direction * speed
	move_and_slide()
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.y = clampf(position.y, bounds.position.y, bounds.end.y)
	visual.position = position.round() - position
	visual.walking = direction.length_squared() > 0.01
	if direction.x != 0:
		visual.facing = Vector2(signf(direction.x), 0)
	elif direction.y != 0:
		visual.facing = Vector2(0, signf(direction.y))
