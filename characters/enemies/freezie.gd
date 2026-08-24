class_name freezer
extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


var direction = -1


func _ready() -> void:
	add_to_group("enemies")
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	velocity.x = 35 * direction
func _physics_process(delta: float) -> void:
	var plr = get_tree().get_first_node_in_group("player")
# gravity
	if !is_on_floor():
		velocity.y += 10
		velocity.y = clamp(velocity.y, -INF, 500)
# movement
	if is_on_wall():
		direction *= -1
	velocity.x = 50 * direction
	move_and_slide()

func hit():
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	queue_free()
func melt():
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceMelt.wav"), -10)
	queue_free()
func _on_hurt_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func _on_hit_detect_body_entered(body: Node2D) -> void:
	if body is iceballplr:
		body.hit()
	if body is fireballplr:
		melt()
		body.hit()
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin and body.frozen == false:
		if body.frozen == false:
			body.freeze()
		body.freeze_timer.start()
		queue_free()
