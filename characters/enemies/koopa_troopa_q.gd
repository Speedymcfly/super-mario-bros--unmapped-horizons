class_name nokoq

extends CharacterBody2D

@onready var koopa_troopa_q: nokoq = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $HurtPlayer/HurtShape
@onready var hurt_shape_2: CollisionShape2D = $HurtPlayer2/HurtShape2
@onready var stomp_shape: CollisionShape2D = $StompDetect/StompShape
@onready var hit_detect: Area2D = $HitDetect
@onready var sfx_stomped: AudioStreamPlayer2D = $SFXStomped
@onready var sfx_bumped: AudioStreamPlayer2D = $SFXBumped
@onready var sfx_hit: AudioStreamPlayer2D = $SFXHit
@onready var sfx_knock: AudioStreamPlayer2D = $SFXKnock
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var hold_comp: Holdable = $Holdable


var direction = -1

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

enum Shellstate{
	Walk,
	InShell,
	Spin,
}

var shell_state:Shellstate=Shellstate.Walk
var shell_timer = 0



func _ready() -> void:
	var new_sprite_frames = load("res://characters/enemies/Noko_" + str(colour) + "_Q.tres")
	animated_sprite_2d.sprite_frames = new_sprite_frames

	if shell_state == Shellstate.Spin or shell_state == Shellstate.Walk:
		held = false

	add_to_group("shelled_enemies")



func _physics_process(delta: float) -> void:

	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)


	#if colour == "Yellow" and shell_state == Shellstate.Walk:
		#direction = sign_value
	#else:
		#direction = 1

	if hurt == true:
		animated_sprite_2d.rotation += .1
		velocity.y += 8
		move_and_slide()
	else:
		move_and_slide()

	if shell_state == Shellstate.Walk:
		hurt_shape.disabled = false
		hurt_shape_2.disabled = false
	else:
		hurt_shape.disabled = true
		hurt_shape_2.disabled = true

	if shell_state == Shellstate.Spin:
		koopa_troopa_q.set_collision_mask_value(4, true)
		koopa_troopa_q.set_collision_mask_value(3, false)
	else:
		koopa_troopa_q.set_collision_mask_value(4, false)
		koopa_troopa_q.set_collision_mask_value(3, true)


# movement
	if is_on_wall() and shell_state == Shellstate.Walk and colour != "Yellow":
		animated_sprite_2d.play("turn")
		direction *= -1
		if colour == "Blue":
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red"):
			velocity.x = 35 * direction
	if shell_state == Shellstate.Walk and (colour == "Red" or colour == "Blue"):
		if not ledge_check.is_colliding():
			direction *= -1
			animated_sprite_2d.animation = "turn"
		if colour == "Blue":
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red"):
			velocity.x = 35 * direction
		elif colour == "Yellow":
			velocity.x = 75 * sign_value
		ledge_check.position.x = 8.0 * direction


	if shell_state == Shellstate.Spin:
		animated_sprite_2d.play("spin")
		velocity.x = 150 * direction
		shell_timer = 1
		if is_on_wall():
			sfx_bumped.play()
			direction *= -1
			velocity.x = 150 * direction


	if velocity.x > 0:
		if shell_state == Shellstate.Walk and hurt == false:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * -1
		hurt_shape.position.x = 7
		hurt_shape_2.position.x = -4
		ledge_check.position.x = 8.0 * direction
	if velocity.x < 0:
		if shell_state == Shellstate.Walk and hurt == false:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
		hurt_shape.position.x = -7
		hurt_shape_2.position.x = 4
		ledge_check.position.x = 8.0 * direction


# gravity
	if not is_on_floor():
		velocity.y += 10

	# Holding component stuff
	if shell_state != Shellstate.InShell:
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
		if colour == "Blue":
			velocity.x = 50 * direction
		elif (colour == "Green" or colour == "Red"):
			velocity.x = 35 * direction
		elif colour == "Yellow":
			velocity.x = 75 * sign_value
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

func _on_stomp_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0 and shell_state == Shellstate.Walk:
		hold_comp.delay = 10
		delay = 10
		shell_state = Shellstate.InShell
		sfx_stomped.play()
		sfx_knock.play()
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

func _on_hit_detect_body_entered(body: Node2D) -> void:
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.Spin:
		hit()
		if shell_state == Shellstate.Spin:
			body.hit()
	if (body is nokoq or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and hold_comp.is_held == false and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null

func hit():
	collision_shape_2d.set_deferred("disabled", true)
	stomp_shape.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	velocity.y = -70
	sfx_hit.play()
	if shell_state == Shellstate.Walk:
		animated_sprite_2d.animation = "bite"
	else:
		animated_sprite_2d.animation = "shell"
	hurt = true


func _on_kicked(dir: int) -> void:
	delay = 10
	direction = dir
	shell_state = Shellstate.Spin
	sfx_knock.play()
