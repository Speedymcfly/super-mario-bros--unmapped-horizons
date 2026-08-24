class_name fire_pakkun
extends CharacterBody2D

@export var max_rotation := 120.0

@onready var plr = get_tree().get_first_node_in_group("player")
@onready var main_collision: CollisionShape2D = $MainCollision
@onready var rotation_joint: Node2D = $RotationJoint
@onready var head: AnimatedSprite2D = $RotationJoint/Head
@onready var stem: AnimatedSprite2D = $Stem
@onready var bite_shape: CollisionShape2D = $RotationJoint/BiteArea/BiteShape
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
@onready var shoot_timer: Timer = $ShootTimer
@onready var bite_timer: Timer = $BiteTimer
@onready var in_out_timer: Timer = $InOutTimer
@onready var sfx_chomp: AudioStreamPlayer2D = $SFXChomp
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var ice_collision_small: CollisionShape2D = $IceCollisionSmall
@onready var ice_collision_big: CollisionShape2D = $IceCollisionBig
@onready var freeze_timer: Timer = $FreezeTimer
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $OnScreenNotifier
@export var move_speed := 28.0
@export var wait_inside := 1.2
@export var wait_outside := 1.2
@export var pipe_check_distance := 40.0


var base_position: Vector2
var target_position: Vector2
var emerge_distance := 32.0

var hurt = false
var frozen = false
var frozen_rotation := 0.0
var hitsfxrandemizr = 1
@export_enum(
	"Green",
	"Blue",
	"Light_Blue",
	"Yellow",
	"Red",
	"Purple",
	"White",
	"Grey",
	"Black",
	"Gold"
	) var stem_colour = "Green"
@export_enum(
	"Short",
	"Tall"
	) var stem_size = "Short"
@export_enum(
	"Pipe",
	"Open"
	) var dwelling = "Pipe"
@export_enum(
	"Up",
	"Down",
	"Left",
	"Right"
	) var facing = "Up"

enum Pipestate{
	Out,
	Entering,
	In,
	Exiting
}
var pipe_state:Pipestate=Pipestate.In

func _ready() -> void:
	var stem_frames = load("res://characters/enemies/Pakkun_Stem_Shoot_" + str(stem_size) + "_" + str(stem_colour) + ".tres")
	stem.sprite_frames = stem_frames

	if stem_size == "Tall":
		stem.position.y = 8
		emerge_distance = 32.0
		wait_outside = 1.8
	else:
		stem.position.y = 4
		emerge_distance = 24.0
	base_position = global_position
	if dwelling == "Open":
		pipe_state = Pipestate.Out
	head.play()
	stem.play()
	if dwelling == "Open":
		pipe_state = Pipestate.Out
	else:
		start_pipe_cycle()
	$FrozenSpriteSmall.hide()
	$FrozenSpriteBig.hide()
	ice_collision_small.set_deferred("disabled", true)
	ice_collision_big.set_deferred("disabled", true)
	shoot_timer.start()
func _physics_process(delta):
	if hurt and not Globals.is_onscreen(global_position):
		queue_free()
	if hurt:
		head.play("hit")
		head.rotation += .1
		if dwelling == "Pipe" and pipe_state == Pipestate.Out:
			head.z_index = z_index + 1
		velocity.y += 8
		move_and_slide()
	if frozen:
		return
	match pipe_state:
		Pipestate.Exiting:
			global_position = global_position.move_toward(target_position, move_speed * delta)
			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position
				pipe_state = Pipestate.Out
				start_pipe_cycle()
		Pipestate.Entering:
			global_position = global_position.move_toward(target_position, move_speed * delta)
			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position
				pipe_state = Pipestate.In
				start_pipe_cycle()
	if not sfx_chomp.playing and !hurt:
		sfx_chomp.play()
	elif hurt:
		sfx_chomp.stop()
	if pipe_state != Pipestate.In and on_screen_notifier.is_on_screen():
		sfx_chomp.volume_db = 5
	elif pipe_state == Pipestate.In or !on_screen_notifier.is_on_screen():
		sfx_chomp.volume_db = -20
func _process(delta):
	if frozen:
		return

	var target_angle := 0.0

	# Only aim while the plant is fully out and not hurt.
	if pipe_state == Pipestate.Out and !hurt:
		target_angle = (
			plr.global_position - rotation_joint.global_position
		).angle() + PI / 2

		# Wrap the angle into the range -PI to PI.
		target_angle = wrapf(target_angle, -PI, PI)

		# Clamp the rotation.
		target_angle = clamp(
			target_angle,
			deg_to_rad(-max_rotation),
			deg_to_rad(max_rotation)
		)

	# Smoothly rotate toward the target.
	rotation_joint.rotation = lerp_angle(
		rotation_joint.rotation,
		target_angle,
		5.0 * delta
	)

	# Alternate hit sounds.
	if hitsfxrandemizr == 1:
		hitsfxrandemizr = 2
	else:
		hitsfxrandemizr = 1

	# Stem animation based on current rotation.
	var x_diff = plr.global_position.x - rotation_joint.global_position.x

	if x_diff < -8:
		stem.play("default_left")
	elif x_diff > 8:
		stem.play("default_right")
	else:
		stem.play("default_middle")
func _on_bite_area_body_entered(body: Node2D) -> void:
	if hurt:
		return
	if body is player and not body.damaged and not body.invincible and !frozen:
		body.damage()
		bite_shape.set_deferred("disabled", true)
		bite_timer.start()

func _on_bite_timer_timeout() -> void:
		bite_shape.set_deferred("disabled", false)


func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		hit()
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null
	if body != self and body.is_in_group("frozen_carriable") and body.velocity.x != 0:
		if frozen:
			unfreeze()
			unfreeze_reset()
		hit()
	if body is iceballplr and !hurt:
		if !frozen:
			freeze()
		freeze_timer.start()
		body.hit()
	if body is fireballplr and !hurt:
		if !frozen:
			hit()
		body.hit()

func hit():
	main_collision.set_deferred("disabled", true)
	$Stem.hide()
	hurt = true
	velocity.y = -20
	sfx_hit.play()
	if hitsfxrandemizr == 1:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/PakkunFlowerVoiceHit1.wav"))
	else:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/PakkunFlowerVoiceHit2.wav"), -10)

func start_pipe_cycle():
	match pipe_state:
		Pipestate.In:
			in_out_timer.start(wait_inside)
		Pipestate.Out:
			in_out_timer.start(wait_outside)
		Pipestate.Exiting:
			target_position = base_position + get_emerge_offset()
		Pipestate.Entering:
			target_position = base_position
func get_emerge_offset() -> Vector2:
	match facing:
		"Up":
			return Vector2(0, -emerge_distance)
		"Down":
			return Vector2(0, emerge_distance)
		"Left":
			return Vector2(-emerge_distance, 0)
		"Right":
			return Vector2(emerge_distance, 0)
	return Vector2.ZERO
func _on_in_out_timer_timeout() -> void:
	match pipe_state:
		Pipestate.In:
			var dist = global_position.distance_to(plr.global_position)
			if dist < pipe_check_distance:
				in_out_timer.start(0.5)
				return
			pipe_state = Pipestate.Exiting
			start_pipe_cycle()
		Pipestate.Out:
			pipe_state = Pipestate.Entering
			start_pipe_cycle()
func freeze():
	frozen = true
	add_to_group("frozen")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceballFreeze.wav"), -10)
	if stem_size != "Tall":
		ice_collision_small.set_deferred("disabled", false)
		$FrozenSpriteSmall.show()
	else:
		ice_collision_big.set_deferred("disabled", false)
		$FrozenSpriteBig.show()
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	bite_shape.set_deferred("disabled", true)
	head.stop()
	stem.stop()
func unfreeze():
	frozen = false
	frozen_rotation = rotation_joint.rotation
	remove_from_group("frozen")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	bite_shape.set_deferred("disabled", false)
func unfreeze_reset():
	$FrozenSpriteSmall.hide()
	$FrozenSpriteBig.hide()
	ice_collision_small.set_deferred("disabled", true)
	ice_collision_big.set_deferred("disabled", true)
	head.play()
	stem.play()
func _on_freeze_timer_timeout() -> void:
	if frozen:
		unfreeze()
	unfreeze_reset()
func _on_shoot_timer_timeout() -> void:
	shoot()
func shoot():
	bite_shape.set_deferred("disabled", true)
	head.play("shoot")
	await head.animation_finished
	head.play("closed")
	bite_shape.set_deferred("disabled", false)
	shoot_timer.start()
