class_name Dorabon
extends CharacterBody2D

@onready var big_sprite: AnimatedSprite2D = $BigSprite
@onready var small_sprite: AnimatedSprite2D = $SmallSprite
@onready var collision_big: CollisionShape2D = $CollisionBig
@onready var collision_small: CollisionShape2D = $CollisionSmall
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var hurt_shape_2: CollisionShape2D = $HurtPlayer2/HurtShape2
@onready var squish_detect: Area2D = $SquishDetect
@onready var squish_shape: CollisionShape2D = $SquishDetect/SquishShape
@onready var hit_detect: Area2D = $HitDetect
@onready var hit_shape: CollisionShape2D = $HitDetect/HitShape
@onready var ice_knock_shape: CollisionShape2D = $IceKnockArea/IceKnockShape
@onready var sfx_walk: AudioStreamPlayer2D = $SFXWalk
@onready var sfx_walk_fast: AudioStreamPlayer2D = $SFXWalkFast
@onready var sfx_squish: AudioStreamPlayer2D = $SFXSquish
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bite_timer: Timer = $BiteTimer
@onready var ice_collision_big: CollisionShape2D = $IceCollisionBig
@onready var ice_collision_small: CollisionShape2D = $IceCollisionSmall
@onready var frozen_sprite_small: Sprite2D = $FrozenSpriteSmall
@onready var freeze_timer: Timer = $FreezeTimer
@onready var freeze_pound_collision: CollisionShape2D = $FreezePoundArea/FreezePoundCollision
var turning = false
var frozen = false
var frozen_held = false
var holder: player = null
var throw_speed := 260.0
var slide_friction := 1.0
enum Freezestate{
	Unfrozen,
	Still,
	Held,
	Moving,
}
var freeze_state:Freezestate=Freezestate.Unfrozen
var small = false
var stomped = false
var hurt = false
var spawn_position: Vector2
var direction = -1

func _ready() -> void:
	spawn_position = global_position
	add_to_group("enemies")
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	ice_collision_big.set_deferred("disabled", true)
	ice_collision_small.set_deferred("disabled", true)
	$FrozenSpriteBig.hide()
	$FrozenSpriteSmall.hide()
func _physics_process(delta: float) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if (stomped or hurt) and not Globals.is_onscreen(global_position):
		queue_free()

	if frozen and freeze_timer.time_left <= 4:
		animation_player.play("freeze_shake")

	if frozen:
		freeze_pound_collision.set_deferred("disabled", false)
		if small:
			freeze_pound_collision.position.y = 0
		else:
			freeze_pound_collision.position.y = -16
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
		big_sprite.rotation += .1
		small_sprite.rotation += .1
		velocity.y += 8
		move_and_slide()
	else:
		velocity.x = (70 if small else 35) * direction
		move_and_slide()
	if is_on_floor() and velocity.x != 0:
		if small and not sfx_walk_fast.playing:
			sfx_walk_fast.play()
		elif !small and not sfx_walk.playing:
			sfx_walk.play()
	if is_on_wall() and !hurt and !frozen and !turning:
		turn_around()
	if velocity.x > 0 and !stomped and !hurt and !turning:
		big_sprite.play("walking")
		small_sprite.play("walking")
		big_sprite.scale.x = abs(big_sprite.scale.x) * -1
		small_sprite.scale.x = abs(big_sprite.scale.x) * -1
		hurt_shape.position.x = 4
		hurt_shape_2.position.x = -4
	if velocity.x < 0 and !stomped and !hurt and !turning:
		big_sprite.play("walking")
		small_sprite.play("walking")
		big_sprite.scale.x = abs(big_sprite.scale.x)
		small_sprite.scale.x = abs(big_sprite.scale.x)
		hurt_shape.position.x = -4
		hurt_shape_2.position.x = 4

	if !small and !stomped and !hurt:
		$BigSprite.show()
		$SmallSprite.hide()
		collision_big.set_deferred("disabled", false)
		collision_small.set_deferred("disabled", true)
		hurt_shape.position.y = -3
		hurt_shape_2.position.y = -3
		hurt_shape.scale.y = 1
		hurt_shape_2.scale.y = 1
		squish_shape.position.y = -15
	elif !stomped and !hurt:
		$BigSprite.hide()
		$SmallSprite.show()
		collision_big.set_deferred("disabled", true)
		collision_small.set_deferred("disabled", false)
		hurt_shape.position.y = 4.5
		hurt_shape_2.position.y = 4.5
		hurt_shape.scale.y = .5
		hurt_shape_2.scale.y = .5
		squish_shape.position.y = 0
		hit_shape.position.y = 8
		hit_shape.scale.y = .5
		ice_knock_shape.scale.y = 8
		ice_knock_shape.scale.y = .5


func _on_squish_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0:
		squish()
		turning = false
		if small == false:
			small = true
		if body.movement_state == body.Movementstate.Groundpound:
			small = true
			squish()
		else:
			if Input.is_action_pressed("jump"):
				body.velocity.y = -400
			else:
				body.velocity.y = -200
func turn_around():
	turning = true
	big_sprite.play("turn")
	small_sprite.play("turn")
	await big_sprite.animation_finished
	await small_sprite.animation_finished
	turning = false
func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		if frozen:
			unfreeze()
			_ready()
		hit()
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		if frozen:
			unfreeze()
			_ready()
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null
	if body != self and body.is_in_group("frozen_carriable") and body.velocity.x != 0:
		if frozen:
			unfreeze()
			_ready()
		hit()
	if body is fireballplr and !stomped and !hurt:
		if frozen:
			unfreeze()
			AudioManager.play_sfx(load("res://assets/audio/SFX/IceMelt.wav"), -10)
			_ready()
		else:
			hit()
		body.hit()
	if body is iceballplr and !stomped and !hurt:
		if !frozen:
			freeze()
		freeze_timer.start()
		body.hit()
func squish():
	if small:
		collision_big.set_deferred("disabled", true)
		collision_small.set_deferred("disabled", true)
		squish_detect.set_deferred("disabled", true)
		squish_shape.set_deferred("disabled", true)
		hurt_shape.set_deferred("disabled", true)
		hurt_shape_2.set_deferred("disabled", true)
		velocity.y = -70
		stomped = true
		small_sprite.animation = "squished"
		AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/DorabonVoiceHit.wav"), -15)
	sfx_squish.play()
func hit():
	collision_big.set_deferred("disabled", true)
	collision_small.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	squish_shape.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	velocity.y = -70
	sfx_hit.play()
	big_sprite.animation = "bite"
	small_sprite.animation = "bite"
	AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/DorabonVoiceHit.wav"), -15)
	hurt = true

func _on_hurt_player_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible:
		body.damage()
		big_sprite.animation = "bite"
		small_sprite.animation = "bite"
		direction = 0
		hurt_shape.set_deferred("disabled", true)
		hurt_shape_2.set_deferred("disabled", true)
		bite_timer.start()
		turning = false
func _on_hurt_player_2_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible:
		body.damage()
		big_sprite.animation = "bite"
		small_sprite.animation = "bite"
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
						global_position = holder.global_position + Vector2(0, -16)
					else:
						global_position = holder.global_position + Vector2(0, -27)
				elif holder.character == holder.Character.Luigi:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -18)
					else:
						global_position = holder.global_position + Vector2(0, -30)
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
						_ready()
				elif (collider.is_in_group("terrain") or collider.is_in_group("frozen_carriable")) and is_on_wall():
					unfreeze()
					_ready()
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
	collision_big.set_deferred("disabled", true)
	collision_small.set_deferred("disabled", true)
func throw(dir):
	holder = null
	freeze_state = Freezestate.Moving
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	if small:
		collision_small.set_deferred("disabled", false)
	else:
		collision_big.set_deferred("disabled", false)
	velocity.x = throw_speed * dir
	velocity.y = 0
func drop(dir):
	global_position = holder.global_position + Vector2(16 * dir, 0)
	holder = null
	freeze_state = Freezestate.Still
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	if small:
		collision_small.set_deferred("disabled", false)
	else:
		collision_big.set_deferred("disabled", false)
func freeze():
	frozen = true
	turning = false
	add_to_group("frozen_carriable")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceballFreeze.wav"), -10)
	direction = 0
	if is_on_floor():
		velocity.x = 0
	freeze_state = Freezestate.Still
	if small:
		ice_collision_small.set_deferred("disabled", false)
		$FrozenSpriteSmall.show()
	else:
		ice_collision_big.set_deferred("disabled", false)
		$FrozenSpriteBig.show()
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	big_sprite.stop()
	small_sprite.stop()
func unfreeze():
	frozen = false
	if holder:
		holder.current_carried_obj = null
		holder.toss_timer.start()
	holder = null
	freeze_state = Freezestate.Unfrozen
	remove_from_group("frozen_carriable")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceBreak.wav"), -10)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	hurt_shape.set_deferred("disabled", false)
	hurt_shape_2.set_deferred("disabled", false)
func _on_freeze_timer_timeout() -> void:
	if frozen:
		unfreeze()
	_ready()
func _on_freeze_pound_area_body_entered(body: Node2D) -> void:
	if body is player and body.movement_state == body.Movementstate.Groundpound:
		unfreeze()
		_ready()
		hit()
func _on_ice_knock_area_body_entered(body: Node2D) -> void:
	if frozen and body is player and body.velocity.x !=0:
		freeze_state = Freezestate.Moving
		velocity.x = 150.0 * body.facing_direction
