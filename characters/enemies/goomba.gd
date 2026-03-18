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
@onready var spike_shape: CollisionShape2D = $Spike/SpikeShape
@onready var bite_timer: Timer = $BiteTimer


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

	add_to_group("enemies")

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
			sfx_helm_break.play()
			bone_helm_break()
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
	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.Spin:
		if variant == "Bone" and bone_helmet == true:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		hit()

	if (body is nokoq or body is nokob or body is metto) and body.shell_state == body.Shellstate.InShell and body.hold_comp.is_held == true and (body.hold_comp.holder.velocity.x != 0 or body.hold_comp.holder.velocity.y != 0):
		if variant == "Bone" and bone_helmet == true:
			bone_helmet = false
			sfx_helm_break.play()
			bone_helm_break()
		hit()
		body.hit()
		body.hold_comp.is_held = false
		body.hold_comp.holder.current_held_obj = null


func squish():
	collision_shape_2d.set_deferred("disabled", true)
	squish_detect.set_deferred("disabled", true)
	hurt_shape.set_deferred("disabled", true)
	hurt_shape_2.set_deferred("disabled", true)
	velocity.y = -70
	sfx_squish.play()
	animated_sprite_2d.animation = "squished"
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
	if variant == "Bone" and bone_helmet == true:
		animated_sprite_2d.animation = "hit2"
	elif variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
		if direction == 1:
			animated_sprite_2d.animation = "hitright"
		else:
			animated_sprite_2d.animation = "hitleft"
	else:
		animated_sprite_2d.animation = "hit"
	hurt = true

func on_hit_block():
	if hurt == true:
		return
	hit()

func bone_helm_break():
	for i in range(4):
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
	if body.is_in_group("player") and not body.damaged:
		body.damage()


func _on_hurt_player_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible:
		body.damage()
		if variant == "Bone" and bone_helmet == true:
			animated_sprite_2d.animation = "bite2"
		elif variant == "Spiked_Normal" or variant == "Spiked_Gloomba":
			if direction == 1:
				animated_sprite_2d.animation = "biteright"
			else:
				animated_sprite_2d.animation = "biteleft"
		else:
			animated_sprite_2d.animation = "bite"
		direction = 0
		bite_timer.start()

func _on_hurt_player_2_body_entered(body: Node2D) -> void:
	var plr = get_tree().get_first_node_in_group("player")
	if plr.global_position.y < global_position.y -2.5: 
		return
	if body is player and not body.damaged and not body.invincible:
		body.damage()
		direction *= -1
		if variant == "Bone" and bone_helmet == true:
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
		bite_timer.start()


func _on_bite_timer_timeout() -> void:
	var plr = get_tree().get_first_node_in_group("player")
	var sign_value = sign(plr.global_position.x - global_position.x)
	direction = 1 * sign_value
	bite_timer.stop()
