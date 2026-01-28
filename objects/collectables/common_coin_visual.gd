extends AnimatedSprite2D

var y_speed := 0.0
var start_y := 0.0
var bounce_force := -300.0
var gravity := 900.0

func _ready() -> void:
	start_y = global_position.y
	y_speed = bounce_force

func _physics_process(delta: float) -> void:
	y_speed += gravity * delta
	global_position.y += y_speed * delta
	if global_position.y > start_y:
		queue_free()
