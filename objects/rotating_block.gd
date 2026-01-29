extends AnimatableBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_collision: CollisionShape2D = $JumpArea/JumpCollision
@onready var sfx_bump: AudioStreamPlayer2D = $SFXBump
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer


var spinning = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_jump_area_body_entered(body: Node2D) -> void:
	if (body is player or body is jack) and body.velocity.y > 0:
		spinning = true
		sfx_bump.play()
		animation_player.play("bump_up")
		timer.start()
		collision_shape_2d.set_deferred("disabled", true)
		jump_collision.set_deferred("disabled", true)
		animated_sprite_2d.play("spinning")

func _on_side_hit_area_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		spinning = true
		animation_player.play("bump_up")
		timer.start()
		collision_shape_2d.set_deferred("disabled", true)
		jump_collision.set_deferred("disabled", true)
		animated_sprite_2d.play("spinning")


func _on_timer_timeout() -> void:
	spinning = false
	if spinning == false:
		timer.stop()
		collision_shape_2d.set_deferred("disabled", false)
		jump_collision.set_deferred("disabled", false)
		animated_sprite_2d.play("idle")
