class_name player
extends CharacterBody2D

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_small: CollisionShape2D = $CollisionSmall
@onready var collision_big: CollisionShape2D = $CollisionBig
@onready var crouch_small: CollisionShape2D = $CrouchSmall
@onready var crouch_big: CollisionShape2D = $CrouchBig
@onready var dive_big: CollisionShape2D = $DiveBig
@onready var sfx_jump: AudioStreamPlayer2D = $SFXJump
@onready var mario_jump: AudioStreamPlayer2D = $MarioJump
@onready var mario_third_jump: AudioStreamPlayer2D = $MarioThirdJump
@onready var mario_long_jump: AudioStreamPlayer2D = $MarioLongJump
@onready var wall_jump: AudioStreamPlayer2D = $WallJump
@onready var thanks_1: AudioStreamPlayer2D = $Thanks1
@onready var thanks_2: AudioStreamPlayer2D = $Thanks2


var SPEED = 70.0
const JUMP_VELOCITY = -360.0


var jump_limit = 0
var jump_timer = 0



enum Character {
	Mario,
	Luigi,
	Toad,
	Toadette,
	Peach,
	Daisy
}
var character:Character=Character.Mario

enum Movementstate{
	Walk,
	Run,
	Crouch,
	Jump,
	Wallslide,
	Groundpound,
	Dive,
	Swim,
	Shell,
	Swimshel
}
var movement_state:Movementstate=Movementstate.Walk

enum Powerupstate {
	Small,
	Big,
	Fire,
	Ice,
	Bubble,
	Cloud,
	Drill,
	Shell,
	Beetle,
	Lobster,
	Flying
}
var powerup_state:Powerupstate=Powerupstate.Small

enum Variant {
	Modern,
	Retro
}
var variant:Variant = Variant.Modern

var holding_item = false
var p_speed = false

var invincible = false
var invincible_timer = 0

func _ready() -> void:
	#var new_sprite_frames = load("res://characters/players/"+ str(powerup_state) + str(character) + str(variant) +".tres")
	#sprite_2d.sprite_frames = new_sprite_frames
	pass




func _physics_process(delta: float) -> void:


	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Fire:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Fireball.wav"))
	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Ice:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Iceball.wav"))

	if powerup_state == Powerupstate.Small:
		collision_small.set_deferred("disabled", false)
		collision_big.set_deferred("disabled", true)
		dive_big.set_deferred("disabled", true)
	else:
		collision_small.set_deferred("disabled", true)
		if movement_state == Movementstate.Dive:
			collision_big.set_deferred("disabled", true)
			dive_big.set_deferred("disabled", false)
		else:
			collision_big.set_deferred("disabled", false)
			dive_big.set_deferred("disabled", true)

	#Big Check
	if Input.is_action_just_pressed("ui_copy"):
		if powerup_state != Powerupstate.Small:
			powerup_state = Powerupstate.Small
		else:
			powerup_state = Powerupstate.Big

	#if (velocity.x > 1 || velocity.x < -1):
	if abs(velocity.x) > 1:
		if Input.is_action_pressed("run"):
			sprite_2d.play("running")
		else:
			sprite_2d.play("walking")
	else:
		sprite_2d.play("idle")

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_state == Movementstate.Jump:
		if holding_item == false:
			sprite_2d.play("jumping")

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 0 and not movement_state == Movementstate.Crouch:
		if movement_state == Movementstate.Run and not velocity.x == 0:
			velocity.y = JUMP_VELOCITY -40
		else:
			velocity.y = JUMP_VELOCITY
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				mario_jump.play()
		jump_limit += 1
		movement_state = Movementstate.Jump
	elif Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 1:
		velocity.y = JUMP_VELOCITY -60
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				mario_jump.play()
		jump_limit += 1
		movement_state = Movementstate.Jump
	elif Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 2:
		velocity.y = JUMP_VELOCITY -90
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				mario_third_jump.play()
		jump_limit -= 2
		movement_state = Movementstate.Jump

	if is_on_floor():
		jump_timer += 1
		if jump_timer >= 15:
			jump_limit = 0
			jump_timer = 0
	else:
		jump_timer = 0

	if not Input.is_action_pressed("run") and Input.is_action_just_pressed("jump"):
		jump_limit -= 1
	if holding_item == true and Input.is_action_just_pressed("jump"):
		jump_limit -= 1
	if is_on_ceiling():
		jump_limit = 0
	if jump_timer <= 0:
		jump_timer = 0





	if Input.is_action_just_released("jump"):
		velocity.y /= 2

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction*SPEED, 10)
	else:
		velocity.x = move_toward(velocity.x, 0, 20)



	move_and_slide()

	#Looking left.
	if Input.is_action_pressed("ui_left") and movement_state != Movementstate.Dive:
		sprite_2d.scale.x = abs(sprite_2d.scale.x) * -1
	if Input.is_action_pressed("ui_right") and movement_state != Movementstate.Dive:
		sprite_2d.scale.x = abs(sprite_2d.scale.x)

	#Running.
	if Input.is_action_pressed("run"):
		if is_on_floor():
			movement_state = Movementstate.Run
		SPEED = 160.0
	else:
		if is_on_floor():
			movement_state = Movementstate.Walk
		SPEED = 70.0

	#Crouching Small.
	if Input.is_action_pressed("ui_down") and is_on_floor():
		#sprite_2d.animation = "crouching"
		SPEED=0
		movement_state = Movementstate.Crouch
		if powerup_state == Powerupstate.Small:
			collision_small.set_deferred("disabled", true)
			crouch_small.set_deferred("disabled", false)
		if powerup_state != Powerupstate.Small:
			collision_big.set_deferred("disabled", true)
			crouch_big.set_deferred("disabled", false)
	else:
		crouch_small.disabled = true
		crouch_big.disabled = true



	#Long Jump.
	if Input.is_action_just_pressed("jump") and movement_state == Movementstate.Crouch and is_on_floor():
		velocity.x = 80 * -direction
		velocity.y = -400
		sfx_jump.play()
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			velocity.x = 350 * direction
			velocity.y = -250
			sfx_jump.play()
			if AudioManager.voice_toggle == true:
				mario_long_jump.play()

	if not is_on_floor() and movement_state == Movementstate.Crouch:
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			sprite_2d.play("long jumping")


	#Wall Sliding/Jumping.
	if is_on_wall() and direction != 0 and not is_on_ceiling_only() and holding_item == false:
		velocity.y = clamp(velocity.y, -INF, 50)
		movement_state = Movementstate.Wallslide
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			velocity.x = 185 * -direction
			movement_state = Movementstate.Jump
			wall_jump.play()
			if AudioManager.voice_toggle == true:
				mario_jump.play()

	#Ground Pound and Dive
	if Input.is_action_just_pressed("ui_down") and not is_on_floor() and holding_item == false and movement_state != Movementstate.Dive:
		movement_state = Movementstate.Groundpound
	if movement_state == Movementstate.Groundpound:
		velocity.x = 0
		velocity.y = 500
		jump_limit = 0
		if Input.is_action_just_pressed("jump") and not is_on_floor() and movement_state != Movementstate.Dive:
			velocity.x = 350 * direction
			velocity.y = -100
			movement_state = Movementstate.Dive




	if Input.is_action_just_pressed("ui_cut"):
		thanks_1.play()
		thanks_2.play()


	#sprite_2d.speed_scale = (velocity.x /50)

	#if movement_state == Movementstate.Groundpound:
		#print("print")
