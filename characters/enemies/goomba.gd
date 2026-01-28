

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
@onready var spike_shape: CollisionShape2D = $Spike/SpikeShape


var bone_helmet = true

var timer = 1.0
var timerstarted : bool

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



func _physics_process(delta: float) -> void:


	if (stomped or hurt) and not Globals.is_onscreen(global_position):
		queue_free()


# movement
	if is_on_wall():
		direction *= -1


	if stomped == true or hurt == true:
		animated_sprite_2d.rotation += .1
		velocity.y += 8
		move_and_slide()
	elif stomped == false or hurt == false:
		velocity.x = 35 * direction
		move_and_slide()

# gravity
	if not is_on_floor():
		velocity.y += 10

	if velocity.x > 0 and stomped == false and hurt == false:
		if variant == "Bone" and bone_helmet == false and (variant != "Spiked_Normal" or variant != "Spiked_Gloomba"):
			animated_sprite_2d.play("walking2")
		elif (variant == "Spiked_Normal" or variant == "Spiked_Gloomba"):
			animated_sprite_2d.play("walkingright")
		else:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x) * -1
		hurt_shape.position.x = 4
		hurt_shape_2.position.x = -4
	if velocity.x < 0 and stomped == false and hurt == false:
		if variant == "Bone" and bone_helmet == false and (variant != "Spiked_Normal" or variant != "Spiked_Gloomba"):
			animated_sprite_2d.play("walking2")
		elif (variant == "Spiked_Normal" or variant == "Spiked_Gloomba"):
			animated_sprite_2d.play("walkingleft")
		else:
			animated_sprite_2d.play("walking")
		animated_sprite_2d.scale.x = abs(animated_sprite_2d.scale.x)
		hurt_shape.position.x = -4
		hurt_shape_2.position.x = 4




func _on_squish_detect_body_entered(body: Node2D) -> void:
	if body is player and body.velocity.y > 0:
		if bone_helmet == true and variant == "Bone":
			bone_helmet = false
			sfx_squish.play()
			sfx_helm_break.play()
			if Input.is_action_pressed("jump"):
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
	if body is nokoq and body.shell_state == body.Shellstate.Spin:
		hit()
		if variant == "Bone":
			bone_helmet = false
			sfx_helm_break.play()


func squish():
	collision_shape_2d.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	velocity.y = -70
	sfx_squish.play()
	animated_sprite_2d.animation = "squished"
	stomped = true

func hit():
	collision_shape_2d.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	hit_detect.set_deferred("disabled", true)
	velocity.y = -70
	sfx_hit.play()
	animated_sprite_2d.animation = "hit"
	hurt = true
