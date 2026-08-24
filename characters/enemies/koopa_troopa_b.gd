class_name nokob

extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var hurt_shape_2: CollisionShape2D = $HurtPlayer2/HurtShape2
@onready var stomp_shape: CollisionShape2D = $StompDetect/StompShape
@onready var stomp_detect_2: Area2D = $StompDetect2
@onready var stomp_shape_2: CollisionShape2D = $StompDetect/StompShape2
@onready var hit_detect: Area2D = $HitDetect
@onready var sfx_walk: AudioStreamPlayer2D = $SFXWalk
@onready var sfx_slide: AudioStreamPlayer2D = $SFXSlide
@onready var sfx_stomped: AudioStreamPlayer2D = $SFXStomped
@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var sfx_knock: AudioStreamPlayer2D = $SFXKnock
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var hold_comp: Holdable = $Holdable
@onready var bite_timer: Timer = $BiteTimer
@onready var slide_timer: Timer = $SlideTimer
@onready var ice_collision_big: CollisionShape2D = $IceCollisionBig
@onready var ice_collision_long: CollisionShape2D = $IceCollisionLong
@onready var frozen_sprite_long: Sprite2D = $FrozenSpriteLong
@onready var freeze_timer: Timer = $FreezeTimer



var direction = -1
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
var hurt = false
var held = false
var delay = 10

@export_enum(
	"Green",
	"Red",
	"Blue",
	"Yellow",
	"Purple",
	"Gold"
) var colour = "Green"

@export_enum(
	"Grounded",
	"Winged"
) var traversal = "Grounded"

@export_enum(
	"In",
	"Out"
) var inoutshell = "In"

@export_enum(
	"Common",
	"Shades"
) var variant = "Common"

enum Shellstate{
	Walk,
	InShell,
	Spin,
	Slideout
}

var shell_state:Shellstate=Shellstate.Walk
var shell_timer = 0

var plr: Node2D

func _ready():
	plr = get_tree().get_first_node_in_group("player")

	var new_sprite_frames = load("res://characters/enemies/Noko_" + str(colour) + "_B_" + str(inoutshell) + "_" + str(variant) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	if shell_state == Shellstate.Spin or shell_state == Shellstate.Walk:
		held = false

	if inoutshell == "In":
		add_to_group("shelled_enemies")
		remove_from_group("enemies")
	else:
		remove_from_group("shelled_enemies")
		add_to_group("enemies")
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	ice_collision_big.set_deferred("disabled", true)
	ice_collision_long.set_deferred("disabled", true)
	$FrozenSpriteBig.hide()
	$FrozenSpriteLong.hide()
func _physics_process(delta: float) -> void:
	if velocity.x != 0 and frozen:
		freeze_state = Freezestate.Moving
	var sign_value = 0
	if plr:
		sign_value = sign(plr.global_position.x - global_position.x)

	if shell_state == Shellstate.Walk:
		hurt_shape.disabled = false
		hurt_shape_2.disabled = false
	else:
		hurt_shape.disabled = true
		hurt_shape_2.disabled = true

	if shell_state == Shellstate.Spin:
		set_collision_mask_value(4, true)
		set_collision_mask_value(3, false)
	else:
		set_collision_mask_value(4, false)
		set_collision_mask_value(3, true)

	if shell_state != Shellstate.Slideout:
		stomp_shape.scale.x = 1
		stomp_shape.position.x = 0
		stomp_shape.position.y = -.25
	else:
		stomp_shape.scale.x = 1.3
		stomp_shape.position.y = 4.25
		if direction == -1:
			stomp_shape.position.x = -4
		else:
			stomp_shape.position.x = 4
	if frozen and freeze_timer.time_left <= 4:
		if shell_state != Shellstate.Slideout:
			animation_player.play("shake")

	if freeze_state == Freezestate.Moving:
		set_collision_layer_value(3, false)
		set_collision_mask_value(3, false)
	elif shell_state != Shellstate.Spin:
		set_collision_layer_value(3, true)
		set_collision_mask_value(3, true)
# gravity
	if !is_on_floor():
		velocity.y += 10
		velocity.y = clamp(velocity.y, -INF, 500)
	if frozen:
		handle_frozen_state(delta)
		return
	if hurt:
		animated_sprite_2d.rotation += .1
		velocity.y += 8 * delta


# movement
	if is_on_wall() and shell_state == Shellstate.Walk and colour != "Yellow" and !hurt and !frozen and !turning:
		turn_around()
		direction *= -1
		if colour == "Blue":
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red"):
			velocity.x = 35 * direction
	if shell_state == Shellstate.Walk:
		if not ledge_check.is_colliding() and (colour == "Red" or colour == "Blue") and !hurt and !frozen and !turning:
			direction *= -1
			turn_around()
		if colour == "Blue":
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red"):
			velocity.x = 35 * direction
		elif colour == "Yellow":
			if !frozen:
				velocity.x = 50 * sign_value
		ledge_check.position.x = 8.0 * direction

	if shell_state == Shellstate.Walk and is_on_floor() and velocity.x != 0 and not sfx_walk.playing:
		sfx_walk.play()

	if shell_state == Shellstate.Spin:
		animated_sprite_2d.play("spin")
		velocity.x = 150 * direction
		shell_timer = 1
		if is_on_wall():
			sfx_bumped.play()
			direction *= -1
			velocity.x = 150 * direction

	if velocity.x > 0 and !turning:
		if shell_state == Shellstate.Walk and !hurt:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * -1
		hurt_shape.position.x = 4
		hurt_shape_2.position.x = -4
		ledge_check.position.x = 8.0 * direction
		ice_collision_long.position.x = 4
		frozen_sprite_long.position.x = 4
	if velocity.x < 0 and !turning:
		if shell_state == Shellstate.Walk and !hurt:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
		hurt_shape.position.x = -4
		hurt_shape_2.position.x = 4
		ledge_check.position.x = 8.0 * direction
		ice_collision_long.position.x = -4
		frozen_sprite_long.position.x = -4
	# Holding component stuff
	if shell_state != Shellstate.InShell or hurt:
		hold_comp.can_kick = false
		hold_comp.can_hold = false
	elif shell_state == Shellstate.InShell:
		hold_comp.can_kick = true
		if hold_comp.delay == 0:
			hold_comp.can_hold = true
	if hold_comp.is_held:
		velocity = Vector2.ZERO

	if shell_state == Shellstate.InShell:
		animated_sprite_2d.play("shell")
		velocity.x = 0
		shell_timer += 1
	if shell_timer >= 500 or shell_timer == 0:
		if colour == "Blue" and shell_state != Shellstate.Slideout:
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red") and shell_state != Shellstate.Slideout:
			velocity.x = 35 * direction
		elif colour == "Yellow" and shell_state != Shellstate.Slideout:
			velocity.x = 50 * sign_value
		if hold_comp.holder:
			hold_comp.is_held = false
			hold_comp.holder.current_held_obj = null
			hold_comp.holder = null
		shell_state = Shellstate.Walk
		shell_timer = 0

	if shell_timer >= 350 and shell_timer <= 500:
		$AnimationPlayer.play("shake")

	if delay > 0:
		delay -= 1

	if slide_timer.time_left != 0 and slide_timer.time_left !=2:
		shell_state = Shellstate.Slideout

	if shell_state == Shellstate.Slideout:
		animated_sprite_2d.animation = "slide"
		if is_on_floor():
			if velocity.x < 0:
				velocity.x += 1
			elif velocity.x > 0:
				velocity.x = move_toward(velocity.x, 0, 20 * delta)
		if velocity.x != 0 and not sfx_slide.playing:
			sfx_slide.play()
		elif shell_state == Shellstate.Walk or velocity.x == 0 or hurt:
			sfx_slide.stop()
	move_and_slide()
func update_shell_visual():
	var new_sprite_frames = load("res://characters/enemies/Noko_" + str(colour) + "_B_" + str(inoutshell) + "_" + str(variant) + ".tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

func _on_stomp_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0 and (shell_state == Shellstate.Walk or shell_state == Shellstate.Slideout) and !frozen:
		if inoutshell == "In":
			sfx_knock.play()
			slide_out()
		else:
			stomp()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200


	if body is player and body.velocity.y > 0 and shell_state == Shellstate.Spin:
		hold_comp.delay = 10
		delay = 10
		shell_state = Shellstate.InShell
		sfx_knock.play()
		if Input.is_action_pressed("jump"):
			body.velocity.y = -400
		else:
			body.velocity.y = -200

func slide_out():
	inoutshell = "Out"
	velocity.x = 220 * direction
	update_shell_visual()
	shell_state = Shellstate.Slideout
	slide_timer.start()
	spawn_shell()

func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		hit()
		if body.hold_comp.is_held == true and hold_comp.is_held == false and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
			body.hit()
			body.hold_comp.is_held = false
			body.hold_comp.holder.current_held_obj = null
		if shell_state == Shellstate.Spin:
			body.hit()
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and hold_comp.is_held == false and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null
	if body != self and body.is_in_group("frozen_carriable") and body.freeze_state == body.Freezestate.Moving:
		if frozen:
			unfreeze()
			_ready()
		hit()
	if body is fireballplr and !hurt:
		if frozen:
			unfreeze()
			AudioManager.play_sfx(load("res://assets/audio/SFX/IceMelt.wav"), -10)
			_ready()
		else:
			hit()
		body.hit()
	if body is iceballplr and !hurt:
		if !frozen:
			freeze()
		freeze_timer.start()
		body.hit()
func hit():
	collision_shape_2d.set_deferred("disabled", true)
	stomp_shape.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	velocity.y = -70
	sfx_hit.play()
	AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/NokoVoiceHit.wav"), -15)
	if shell_state == Shellstate.Walk:
		animated_sprite_2d.animation = "bite"
	else:
		animated_sprite_2d.animation = "shell"
	hurt = true

func stomp():
	collision_shape_2d.set_deferred("disabled", true)
	stomp_shape.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	velocity.y = -70
	sfx_stomped.play()
	AudioManager.play_sfx(load("res://assets/audio/SFX/Enemies/NokoVoiceHit.wav"), -15)
	if shell_state == Shellstate.Slideout:
		animated_sprite_2d.animation = "slide"
	else:
		animated_sprite_2d.animation = "bite"
	hurt = true


func _on_kicked(dir: int) -> void:
	delay = 10
	direction = dir
	shell_state = Shellstate.Spin
	sfx_knock.play()
func turn_around():
	turning = true
	animated_sprite_2d.play("turn")
	await animated_sprite_2d.animation_finished
	turning = false
func _on_hurt_player_body_entered(body: Node2D) -> void:
	if hurt:
		return
	var sign_value = sign(plr.global_position.x - global_position.x)
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible and !frozen:
		body.damage()
		animated_sprite_2d.animation = "bite"
		direction = 0
		sign_value = 0
		bite_timer.start()
		turning = false
func _on_hurt_player_2_body_entered(body: Node2D) -> void:
	if hurt:
		return
	var sign_value = sign(plr.global_position.x - global_position.x)
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible and !frozen:
		body.damage()
		direction *= -1
		animated_sprite_2d.animation = "bite"
		direction = 0
		sign_value = 0
		bite_timer.start()
		turning = false
func _on_bite_timer_timeout() -> void:
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	bite_timer.stop()

func _on_slide_timer_timeout() -> void:
	if !frozen:
		var sign_value = sign(plr.global_position.x - global_position.x)
		direction = 1 * sign_value
		shell_state = Shellstate.Walk
		velocity.y = -60
		slide_timer.stop()

func spawn_shell():
	for i in range(1):
		var s = preload("res://objects/koopa_troopa_shell_b.tscn").instantiate()
		get_parent().add_child(s)
		s.global_position = global_position + Vector2(0, 2)
		if colour == "Green":
			s.colour = "Green"
		s.direction = direction
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
						global_position = holder.global_position + Vector2(0, -18)
					else:
						global_position = holder.global_position + Vector2(0, -29)
				elif holder.character == holder.Character.Luigi:
					if holder.powerup_state == holder.Powerupstate.Small:
						global_position = holder.global_position + Vector2(0, -20)
					else:
						global_position = holder.global_position + Vector2(0, -32)
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
						unfreeze()
						_ready()
						hit()
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
func throw(dir):
	holder = null
	freeze_state = Freezestate.Moving
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	velocity.x = throw_speed * dir
	velocity.y = 0
func drop(dir):
	holder = null
	freeze_state = Freezestate.Still
	add_to_group("frozen_carriable")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
func freeze():
	frozen = true
	turning = false
	add_to_group("frozen_carriable")
	AudioManager.play_sfx(load("res://assets/audio/SFX/IceballFreeze.wav"), -10)
	direction = 0
	if is_on_floor():
		velocity.x = 0
	freeze_state = Freezestate.Still
	if shell_state == Shellstate.Walk:
		ice_collision_big.set_deferred("disabled", false)
		$FrozenSpriteBig.show()
	else:
		ice_collision_long.set_deferred("disabled", false)
		$FrozenSpriteLong.show()
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	animated_sprite_2d.stop()
	if shell_state == Shellstate.Spin:
		shell_state = Shellstate.InShell
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
func _on_freeze_timer_timeout() -> void:
	if frozen:
		unfreeze()
	_ready()
