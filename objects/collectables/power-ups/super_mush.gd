class_name supermushroom
extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var super_mush_collect: Area2D = $SuperMushCollect


var direction = 1


func _physics_process(delta: float) -> void:

	move_and_slide()
	

# movement
	if is_on_wall():
		direction *= -1
	velocity.x = 75 * direction


# gravity
	if not is_on_floor():
		velocity.y += 10







func _on_collect_body_entered(body: Node2D) -> void:
	if body is player:
		AudioManager.play_sfx(load("res://assets/audio/SFX/PowerUpCollect.wav"))
		body.Character.Mario
		if body.powerup_state == body.Powerupstate.Small:
			body.powerup_state = body.Powerupstate.Big
		queue_free()
