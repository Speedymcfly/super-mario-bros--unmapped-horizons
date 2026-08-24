class_name rblock
extends AnimatableBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_collision: CollisionShape2D = $JumpArea/JumpCollision
@onready var pound_collision: CollisionShape2D = $PoundArea/PoundCollision
@onready var sfx_bump: AudioStreamPlayer2D = $SFXBump
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var top_check: Area2D = $TopCheck

var spinning = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_jump_area_body_entered(body: Node2D) -> void:
	if ((body is player or body is biroron) and body.velocity.y > 0) or ((body is nokoq or body is nokob or body is metto) and body.velocity.y > 0 and (body.shell_state == body.Shellstate.InShell or body.shell_state == body.Shellstate.Spin)):
		above_hit()
		spinning = true
		sfx_bump.play()
		animation_player.play("bump_up")
		timer.start()
		collision_shape_2d.set_deferred("disabled", true)
		jump_collision.set_deferred("disabled", true)
		pound_collision.set_deferred("disabled", true)
		animated_sprite_2d.play("spinning")

func _on_side_hit_area_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		above_hit()
		spinning = true
		sfx_bump.play()
		animation_player.play("bump_up")
		timer.start()
		collision_shape_2d.set_deferred("disabled", true)
		jump_collision.set_deferred("disabled", true)
		pound_collision.set_deferred("disabled", true)
		animated_sprite_2d.play("spinning")


func _on_timer_timeout() -> void:
	spinning = false
	timer.stop()
	timer.stop()
	collision_shape_2d.set_deferred("disabled", false)
	jump_collision.set_deferred("disabled", false)
	pound_collision.set_deferred("disabled", false)
	animated_sprite_2d.play("idle")

func above_hit():
	for body in top_check.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("hit"):
				body.hit()
				body.velocity.y -= 100
		if body.is_in_group("shelled_enemies"):
			if body.has_method("hit"):
				body.shell_state = body.Shellstate.InShell
				body.velocity.y -= 50
		if body is player or body.is_in_group("powerup"):
			body.velocity.y -= 50


func _on_pound_area_body_entered(body: Node2D) -> void:
	if body is player and (body.movement_state == body.Movementstate.Groundpound or body.velocity.y > 300):
		spinning = true
		sfx_bump.play()
		animation_player.play("bump_down")
		timer.start()
		collision_shape_2d.set_deferred("disabled", true)
		jump_collision.set_deferred("disabled", true)
		pound_collision.set_deferred("disabled", true)
		animated_sprite_2d.play("spinning")
