class_name happyflower
extends CharacterBody2D


func _physics_process(delta: float) -> void:
	move_and_slide()
# gravity
	if !is_on_floor():
		velocity.y += 10
func _on_collect_body_entered(body: Node2D) -> void:
	if body is player:
		AudioManager.play_sfx_2(load("res://assets/audio/SFX/PowerUpCollect.wav"), -4)
		AudioManager.play_music(load("res://assets/audio/Music/Happy Flower.wav"), -15)
		Globals.coin_rain_timer = 15.0
		Globals.coin_flower_rain = true
		queue_free()
