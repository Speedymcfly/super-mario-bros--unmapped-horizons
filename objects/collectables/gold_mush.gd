class_name goldmushroom
extends CharacterBody2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var gold_mush_collect: Area2D = $SuperMushCollect
var direction = 1
func _ready() -> void:
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	add_to_group("powerup")
func _physics_process(delta: float) -> void:
	move_and_slide()
# movement
	if is_on_wall():
		direction *= -1
	velocity.x = 75 * direction
# gravity
	if !is_on_floor():
		velocity.y += 10
func _on_collect_body_entered(body: Node2D) -> void:
	if body is player:
		AudioManager.play_sfx_2(load("res://assets/audio/SFX/CoinCollect.wav"), -4)
		queue_free()
