
extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var super_mush_collect: Area2D = $SuperMushCollect


var direction = 1

func _ready() -> void:
	add_to_group("powerup")

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
		AudioManager.play_sfx(load("res://assets/audio/SFX/1up.wav"))
		if body.character == body.Character.Mario:
			Globals.mario_lives += 1
		if body.character == body.Character.Luigi:
			Globals.luigi_lives += 1
		if body.character == body.Character.Toad:
			Globals.toad_lives += 1
		if body.character == body.Character.Toadette:
			Globals.toadette_lives += 1
		if body.character == body.Character.Peach:
			Globals.peach_lives += 1
		if body.character == body.Character.Daisy:
			Globals.daisy_lives += 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		queue_free()
