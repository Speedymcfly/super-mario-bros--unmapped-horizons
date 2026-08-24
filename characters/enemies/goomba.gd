class_name kuribo

extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var hurt_shape_2: CollisionShape2D = $HurtPlayer2/HurtShape2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var squish_detect: Area2D = $SquishDetect
@onready var squish_shape: CollisionShape2D = $SquishDetect/SquishShape
@onready var hit_detect: Area2D = $HitDetect
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
@onready var sfx_squish: AudioStreamPlayer2D = $SFXSquish
@onready var sfx_helm_break: AudioStreamPlayer2D = $SFXHelmBreak
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var sfx_walk: AudioStreamPlayer2D = $SFXWalk
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spike_shape: CollisionShape2D = $Spike/SpikeShape
@onready var bite_timer: Timer = $BiteTimer
@onready var ice_collision_big: CollisionShape2D = $IceCollisionBig
@onready var ice_collision_small: CollisionShape2D = $IceCollisionSmall
@onready var freeze_timer: Timer = $FreezeTimer
@onready var freeze_pound_collision: CollisionShape2D = $FreezePoundArea/FreezePoundCollision
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $OnScreenNotifier
var turning = false
var bone_helmet = false
var frozen = false
var frozen_held = false
var holder: player = null
var throw_speed := 260.0
var slide_friction := 2.0
enum Freezestate{
	Unfrozen,
	Still,
	Held,
	Moving,
}
var freeze_state:Freezestate=Freezestate.Unfrozen
var timer = 1.0
var timerstarted : bool
var spawn_position: Vector2
var stomped = false
var hurt = false

var direction = -1

@export_enum(
	"Normal",
	"Gloomba",
	"Bone",
	"Spiked_Normal",
	"Spiked_Gloomba"
) var variant = "Normal"

func _ready() -> void:
	var new_sprite_frames = load("res://characters/enemies/" + str(variant) + "_Goomba.tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	if variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
		squish_shape.set_deferred("disabled", true)
		spike_shape.set_deferred("disabled", false)
	else:
		spike_shape.set_deferred("disabled", true)

	if variant == "Bone":
		bone_helmet = true

	add_to_group("enemies")

	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	ice_collision_big.set_deferred("disabled", true)
	ice_collision_small.set_deferred("disabled", true)
	$FrozenSpriteSmall.hide()
	$FrozenSpriteBig.hide()
func _physics_process(delta: float) -> void:
	if velocity.x != 0 and frozen:
		freeze_state = Freezestate.Moving
	if frozen and freeze_timer.time_left <= 4:
		animation_player.play("freeze_shake")
	if (stomped or hurt) and not Globals.is_onscreen(global_position):
		queue_free()
	if frozen:
		freeze_pound_collision.set_deferred("disabled", false)
		if variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
			freeze_pound_collision.position.y = -10
		else:
			freeze_pound_collision.position.y = -2
	else:
		freeze_pound_collision.set_deferred("disabled", true)
	if freeze_state == Freezestate.Moving:
		set_collision_layer_value(3, false)
		set_collision_mask_value(3, false)
	else:
		set_collision_layer_value(3, true)
		set_collision_mask_value(3, true)
# gravity
	if !is_on_floor():
		velocity.y += 10
		velocity.y = clamp(velocity.y, -INF, 500)
# movement
	if is_on_wall() and !frozen:
		direction *= -1
	if frozen:
		handle_frozen_state(delta)
		return
	if stomped or hurt:
		animated_sprite_2d.rotation += .1
		velocity.y += 8
		move_and_slide()
	else:
		velocity.x = 35 * direction
		move_and_slide()
	if is_on_floor() and not sfx_walk.playing:
		sfx_walk.play()
	if is_on_wall() and !hurt and !frozen and !turning:
		turn_around()
	if velocity.x > 0 and !stomped and !hurt and !frozen and !turning:
		if variant == "Bone" and !bone_helmet and (variant != "Spiked_Normal" or variant != "Spiked_Gloomba"):
			animated_sprite_2d.play("walking2")
		elif (variant == "Spiked_Normal" or variant == "Spiked_Gloomba"):
			animated_sprite_2d.play("walkingright")
		else:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * -1
		hurt_shape.position.x = 4
		hurt_shape_2.position.x = -4
	if velocity.x < 0 and !stomped and !hurt and !frozen and !turning:
		if variant == "Bone" and !bone_helmet and (variant != "Spiked_Normal" or variant != "Spiked_Gloomba"):
			animated_sprite_2d.play("walking2")
		elif (variant == "Spiked_Normal" or variant == "Spiked_Gloomba"):
			animated_sprite_2d.play("walkingleft")
		else:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
		hurt_shape.position.x = -4
		hurt_shape_2.position.x = 4

	if on_screen_notifier.is_on_screen():
		sfx_walk.volume_db = -15
	else:
		sfx_walk.volume_db = -50

func _on_squish_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0 and !frozen:
		if bone_helmet == true and variant == "Bone":
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
			if body.movement_state == body.Movementstate.Groundpound:
				squish()
			elif Input.is_action_pressed("jump"):
				body.velocity.y = -400
			else:
				body.velocity.y = -200
		else:
			squish()
			if Input.is_action_pressed("jump"):
				body.velocity.y = -400
			else:
				body.velocity.y = -200

func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		if variant == "Bone" and bone_helmet:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		if frozen:
			unfreeze()
			ice_collision_big.set_deferred("disabled", true)
			ice_collision_small.set_deferred("disabled", true)
			$FrozenSpriteSmall.hide()
			$FrozenSpriteBig.hide()
		hit()

	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		if variant == "Bone" and bone_helmet:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		if frozen:
			unfreeze()
			unfreeze_reset()
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null
	if body != self and body.is_in_group("frozen_carriable") and body.freeze_state == body.Freezestate.Moving:
		if frozen:
			unfreeze()
			unfreeze_reset()
		if bone_helmet == true:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		hit()
		if variant == "Bone" and bone_helmet:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		if frozen:
			unfreeze()
			unfreeze_reset()
	if body is fireballplr and (!stomped or !hurt):
		if frozen:
			unfreeze()
			unfreeze_reset()
		else:
			if !bone_helmet:
				hit()
		body.hit()
	if body is iceballplr and !stomped and !hurt:
		if !frozen:
			freeze()
		freeze_timer.start()
		body.hit()
func squish():
	collision_shape_2d.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	velocity.y = -70
	sfx_squish.play()
	animated_sprite_2d.animation = "squished"
	AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/KuriboVoiceHit.wav"), -10)
	stomped = true

func hit():
	collision_shape_2d.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	spike_shape.set_deferred("disabled", true)
	velocity.y = -70
	sfx_hit.play()
	if variant == "Bone" and bone_helmet:
		animated_sprite_2d.animation = "hit2"
	elif variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
		if direction == 1:
			animated_sprite_2d.animation = "hitright"
		else:
			animated_sprite_2d.animation = "hitleft"
	else:
		animated_sprite_2d.animation = "hit"
	AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/KuriboVoiceHit.wav"), -10)
	hurt = true
func turn_around():
	turning = true
	if bone_helmet:
		animated_sprite_2d.play("turn2")
	else:
		animated_sprite_2d.play("turn")
	animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
	await animated_sprite_2d.animation_finished
	turning = false
func on_hit_block():
	if hurt == true:
		return
	hit()

func bone_helm_break():
	for i in range(1):
		var d1 = preload("res://Particles/bone_helm_debris_1.tscn").instantiate()
		var d2 = preload("res://Particles/bone_helm_debris_2.tscn").instantiate()
		get_parent().add_child(d1)
		get_parent().add_child(d2)
		d1.global_position = global_position
		d2.global_position = global_position
		d1.scale.x = abs(d1.scale.x) * -direction
		d2.scale.x = abs(d2.scale.x) * -direction
		if animated_sprite_2d.scale.x == abs(animated_sprite_2d.scale.x) * -1:
			d1.velocity.x += 60
			d2.velocity.x += -60
		else:
			d1.velocity.x += -60
			d2.velocity.x += 60
func _on_spike_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not body.damaged and !frozen:
		body.damage()
func _on_hurt_player_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible and !frozen:
		body.damage()
		if variant == "Bone" and bone_helmet:
			animated_sprite_2d.animation = "bite2"
		elif variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
			if direction == 1:
				animated_sprite_2d.animation = "biteright"
			else:
				animated_sprite_2d.animation = "biteleft"
		else:
			animated_sprite_2d.animation = "bite"
		direction = 0
		hurt_shape.set_deferred("disabled", true)
		hurt_shape_2.set_deferred("disabled", true)
		bite_timer.start()
		turning = false
func _on_hurt_player_2_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible and !frozen:
		body.damage()
		direction *= -1
		if variant == "Bone" and bone_helmet:
			animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * direction * -1
			animated_sprite_2d.animation = "bite2"
		elif variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
			animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
			if direction == 1:
				animated_sprite_2d.animation = "biteright"
				animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * -1
			else:
				animated_sprite_2d.animation = "biteleft"
		else:
			animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * direction * -1
			animated_sprite_2d.animation = "bite"
		direction = 0
		hurt_shape.set_deferred("disabled", true)
		hurt_shape_2.set_deferred("disabled", true)
		bite_timer.start()
		turning = false

func _on_bite_timer_timeout() -> void:
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	hurt_shape.set_deferred("disabled", false)
	hurt_shape_2.set_deferred("disabled", false)
	bite_timer.stop()

func handle_frozen_state(delta):
	match freeze_state:
		Freezestate.Still:
			velocity.x = move_toward(velocity.x, 0, slide_friction)
			if !is_on_floor():
				velocity.y += 10
			move_and_slide()
		Freezestate.Held:
			velocity = Vector2.ZERO
			if holder:
				if holder.character == holder.Character.Mario:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -14)
					else:
						global_position = holder.global_position + Vector2(0, -25)
				elif holder.character == holder.Character.Luigi:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -16)
					else:
						global_position = holder.global_position + Vector2(0, -28)
		Freezestate.Moving:
			if !is_on_floor():
				velocity.y += 20
			else:
				velocity.y = 0
			move_and_slide()
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider.is_in_group("enemies") or collider.is_in_group("shelled_enemies"):
					if collider != self and collider.has_method("hit"):
						collider.hit()
				elif (collider.is_in_group("terrain") or collider.is_in_group("frozen_carriable")) and is_on_wall():
					unfreeze()
					unfreeze_reset()
					if bone_helmet == true:
						bone_helmet = false
						sfx_helm_break.play()
						bone_helm_break()
					hit()
					return
			velocity.x = move_toward(velocity.x, 0, slide_friction)
			if abs(velocity.x) < 15:
				velocity.x = 0
				freeze_state = Freezestate.Still
func pick_up(plr):
	if holder != null:
		return
	holder = plr
	freeze_state = Freezestate.Held
	remove_from_group("frozen_carriable")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
func throw(dir):
	holder = null
	freeze_state = Freezestate.Moving
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	velocity.x = throw_speed * dir
	velocity.y = 0
func drop(dir):
	global_position = holder.global_position + Vector2(16 * dir, 0)
	holder = null
	freeze_state = Freezestate.Still
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
func freeze():
	frozen = true
	turning = false
	add_to_group("frozen_carriable")
	freeze_state = Freezestate.Still
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceballFreeze.wav"), -10)
	direction = 0
	if is_on_floor():
		velocity.x = 0
	if variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
		ice_collision_big.set_deferred("disabled", false)
		$FrozenSpriteBig.show()
	else:
		ice_collision_small.set_deferred("disabled", false)
		$FrozenSpriteSmall.show()
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	animated_sprite_2d.stop()
func unfreeze():
	frozen = false
	if holder:
		holder.current_carried_obj = null
		holder.toss_timer.start()
	holder = null
	freeze_state = Freezestate.Unfrozen
	remove_from_group("frozen_carriable")
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
func _on_freeze_timer_timeout() -> void:
	if frozen:
		unfreeze()
	unfreeze_reset()
func unfreeze_reset():
	ice_collision_big.set_deferred("disabled", true)
	ice_collision_small.set_deferred("disabled", true)
	$FrozenSpriteSmall.hide()
	$FrozenSpriteBig.hide()
func _on_freeze_pound_area_body_entered(body: Node2D) -> void:
	if body is player and body.movement_state == body.Movementstate.Groundpound:
		unfreeze()
		unfreeze_reset()
		if bone_helmet:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		hit()
