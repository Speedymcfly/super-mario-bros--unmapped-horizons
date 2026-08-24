class_name honepakkun
extends CharacterBody2D

@export var max_rotation := 60.0

@onready var plr = get_tree().get_first_node_in_group("player")
@onready var main_collision: CollisionShape2D = $MainCollision
@onready var head_bone: Bone2D = $Skeleton2D/StemBone/HeadBone
@onready var head: AnimatedSprite2D = $Skeleton2D/StemBone/HeadBone/Head
@onready var stem: AnimatedSprite2D = $Skeleton2D/StemBone/Stem
@onready var bite_shape: CollisionShape2D = $Skeleton2D/StemBone/HeadBone/BiteArea/BiteShape
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
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
var hitsfxrandemizer = 1
@export_enum(
	"Normal",
	"Dull"
	) var variant = "Normal"
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
	var head_frames = load("res://characters/enemies/Hone_Pakkun_Head_" + str(variant) + ".tres")
	head.sprite_frames = head_frames
	var stem_frames = load("res://characters/enemies/Hone_Pakkun_Stem_" + str(stem_size) + "_" + str(variant) + ".tres")
	stem.sprite_frames = stem_frames

	if stem_size == "Tall":
		stem.position.y = 4
		emerge_distance = 32.0
		wait_outside = 1.8
	else:
		stem.position.y = 0
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
	var angle = head_bone.get_angle_to(plr.global_position)
	angle -= deg_to_rad(-90)
	if facing == "Up" and pipe_state == Pipestate.Out and !hurt:
		angle = clamp(
			angle,
			deg_to_rad(-max_rotation),
			deg_to_rad(max_rotation)
		)
	elif facing == "Up" and pipe_state != Pipestate.Out or hurt:
		angle = 0
	head_bone.rotation = lerp_angle(head_bone.rotation, angle, 5.0 * delta)
	if hitsfxrandemizer == 1:
		hitsfxrandemizer += 1
	else:
		hitsfxrandemizer -= 1

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
		body.hit()

func hit():
	main_collision.set_deferred("disabled", true)
	$Skeleton2D/StemBone/Stem.hide()
	hurt = true
	velocity.y = -20
	sfx_hit.play()
	if hitsfxrandemizer == 1:
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
func player_blocking_pipe() -> bool:
	if !plr:
		return false
	match facing:
		"Up":
			return abs(plr.global_position.x - global_position.x) < 12.0 \
				and plr.global_position.y < global_position.y
		"Down":
			return abs(plr.global_position.x - global_position.x) < 12.0 \
				and plr.global_position.y > global_position.y
		"Left":
			return abs(plr.global_position.y - global_position.y) < 12.0 \
				and plr.global_position.x < global_position.x
		"Right":
			return abs(plr.global_position.y - global_position.y) < 12.0 \
				and plr.global_position.x > global_position.x
	return false
func _on_in_out_timer_timeout() -> void:
	match pipe_state:
		Pipestate.In:
			if plr:
				if is_normal_bone_piranha():
					var dist = global_position.distance_to(plr.global_position)
					if dist < pipe_check_distance:
						in_out_timer.start(0.5)
						return
				else:
					if player_blocking_pipe():
						in_out_timer.start(0.5)
						return
			pipe_state = Pipestate.Exiting
			start_pipe_cycle()
		Pipestate.Out:
			pipe_state = Pipestate.Entering
			start_pipe_cycle()
func is_normal_bone_piranha() -> bool:
	return variant == "Normal"
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
	frozen_rotation = head_bone.rotation
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
