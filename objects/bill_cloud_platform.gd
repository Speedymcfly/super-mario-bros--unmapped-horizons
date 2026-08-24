class_name cloudkillerplatform
extends StaticBody2D
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var shrink = false

func _ready():
	timer.start()

func _process(delta: float) -> void:
	if shrink == true:
		#collision_shape_2d.size -= 0.05
		#sprite_2d.size -= 0.05
	#if collision_shape_2d.size <.1:
		queue_free()

func _on_timer_timeout() -> void:
	shrink = true
