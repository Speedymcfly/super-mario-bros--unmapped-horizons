class_name iceflower
extends CharacterBody2D

@onready var fire_flower_collect: Area2D = $FireFlowerCollect
@onready var animated_sprite_2d: AnimatedSprite2D = $Sprite2D

var direction = 1


func _physics_process(delta: float) -> void:

	move_and_slide()




# gravity
	if not is_on_floor():
		velocity.y += 10


func _on_collect_body_entered(body: Node2D) -> void:
	if body is player:
		AudioManager.play_sfx(load("res://assets/audio/SFX/PowerUpCollect.wav"))
		body.powerup_state = body.Powerupstate.Ice
		queue_free()
