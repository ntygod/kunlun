class_name KunlunPlayer
extends CharacterBody2D
var enabled := true
var speed := 65.0
var visual: PixelActor
var bounds := Rect2(24, 55, 960, 120)
func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	shape.shape = rect
	add_child(shape)
	visual = PixelActor.new()
	add_child(visual)

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
