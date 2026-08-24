class_name hono
extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


var direction = -1


func _ready() -> void:
	add_to_group("enemies")
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	velocity.x = 35 * direction
	$FlameParticle1.preprocess = 0.5
	$FlameParticle2.preprocess = 0.0
	$FlameParticle3.preprocess = 1.0
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
	queue_free()
func _on_hurt_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.

func _on_hit_detect_body_entered(body: Node2D) -> void:
	if body is iceballplr:
		hit()
		body.hit()
	if body is fireballplr:
		body.hit()
