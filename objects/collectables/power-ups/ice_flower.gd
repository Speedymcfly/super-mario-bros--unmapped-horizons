class_name iceflower
extends CharacterBody2D

@onready var fire_flower_collect: Area2D = $FireFlowerCollect
@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D

var direction = 1

func _ready() -> void:
	add_to_group("powerup")

func _physics_process(delta: float) -> void:

	move_and_slide()

# gravity
	if !is_on_floor():
		velocity.y += 10

func _on_collect_body_entered(body: Node2D) -> void:
	if body is player:
		AudioManager.play_sfx_2(load("res://assets/audio/SFX/PowerUpCollect.wav"), -4)
		body.powerup_state = body.Powerupstate.Ice
		body._ready()
		queue_free()
