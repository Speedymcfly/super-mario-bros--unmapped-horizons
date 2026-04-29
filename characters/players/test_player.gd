class_name player
extends CharacterBody2D

@onready var small_sprite: AnimatedSprite2D = $SmallSprite
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_small: CollisionShape2D = $CollisionSmall
@onready var collision_big: CollisionShape2D = $CollisionBig
@onready var crouch_small: CollisionShape2D = $CrouchSmall
@onready var crouch_big: CollisionShape2D = $CrouchBig
@onready var dive_big: CollisionShape2D = $DiveBig
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var damage_timer: Timer = $DamageTimer
@onready var ground_pound_timer: Timer = $GroundPoundTimer
@onready var sfx_jump: AudioStreamPlayer2D = $SFXJump
@onready var mario_jump: AudioStreamPlayer2D = $MarioJump
@onready var mario_third_jump: AudioStreamPlayer2D = $MarioThirdJump
@onready var mario_long_jump: AudioStreamPlayer2D = $MarioLongJump
@onready var wall_jump: AudioStreamPlayer2D = $WallJump
@onready var mario_hurt: AudioStreamPlayer2D = $MarioHurt
@onready var sfx_damage: AudioStreamPlayer2D = $SFXDamage
@onready var sfx_power_down: AudioStreamPlayer2D = $SFXPowerDown
@onready var sfx_die: AudioStreamPlayer2D = $SFXDie
@onready var sfx_die_final: AudioStreamPlayer2D = $SFXDieFinal
@onready var thanks_1: AudioStreamPlayer2D = $Thanks1
@onready var thanks_2: AudioStreamPlayer2D = $Thanks2


var facing_direction := 1
var current_held_obj: Node = null
var SPEED = 70.0
var JUMP_VELOCITY = -360


var jump_limit = 0
var jump_timer = 0

var triple_jump = false

var was_on_floor = false

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
	JumpThree,
	LongJump,
	Fall,
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

@export_enum(
	"Modern",
	"Retro"
)
var version = "Modern"

var holding_item = false
var p_speed = false

var invincible = false
var invincible_timer = 0

var damaged = false

func _ready() -> void:
	var path := "res://characters/players/%s%s%s.tres" % [
		Powerupstate.keys()[powerup_state],
		Character.keys()[character],
		Variant.keys()[variant]
	]
	sprite.sprite_frames = load(path)
	small_sprite.sprite_frames = load(path)

	if powerup_state == Powerupstate.Small:
		$Sprite.hide()
		$SmallSprite.show()
	else:
		$Sprite.show()
		$SmallSprite.hide()

	if version == "Modern":
		variant = Variant.Modern
	else:
		variant = Variant.Retro


func _physics_process(delta: float) -> void:

	holding_item = current_held_obj != null

	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Fire:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Fireball.wav"))
	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Ice:
		AudioManager.play_sfx(load("res://assets/audio/SFX/Iceball.wav"))

	#falling
	if movement_state not in [Movementstate.Groundpound, Movementstate.Dive, Movementstate.JumpThree]:
		if velocity.y > 0:
			movement_state = Movementstate.Fall

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


	#if (velocity.x > 1 || velocity.x < -1):
	if abs(velocity.x) > 1:
		if Input.is_action_pressed("run"):
			sprite.play("running")
			small_sprite.play("running")
		else:
			sprite.play("walking")
			small_sprite.play("walking")
	else:
		sprite.play("idle")
		small_sprite.play("idle")

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if movement_state == Movementstate.Jump or movement_state == Movementstate.JumpThree:
		if holding_item == false:
			sprite.play("jumping")
			small_sprite.play("jumping")

	if (is_on_floor() or is_on_wall()) and jump_limit == 0:
		triple_jump = false

	#Character Jump Height.
	if character == Character.Mario:
		JUMP_VELOCITY = -360
	if character == Character.Luigi:
		JUMP_VELOCITY = -400
	if character == Character.Toad:
		JUMP_VELOCITY = -260

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 0 and movement_state != Movementstate.Crouch:
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
		triple_jump = false
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
		triple_jump = true

	#Third Jump Flip Activate
	if not is_on_floor() and movement_state != Movementstate.Groundpound and movement_state != Movementstate.Dive:
		if triple_jump and holding_item == false:
			movement_state = Movementstate.JumpThree
		else:
			movement_state = Movementstate.Jump

	#Third Jump Flip
	if movement_state == Movementstate.JumpThree:
		small_sprite.rotation += .3 * facing_direction
		sprite.rotation += .3 * facing_direction
		collision_big.rotation += .3 * facing_direction
	else:
		small_sprite.rotation = 0
		sprite.rotation = 0
		collision_big.rotation = 0

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
	if not wall_jump_timer.time_left > 0.0:
		if direction:
			velocity.x = move_toward(velocity.x, direction*SPEED, 10)
		else:
			velocity.x = move_toward(velocity.x, 0, 20)


# Movement (still allowed in air)
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, 10)

# Facing (ground only)
	if direction != 0:
		if is_on_floor() or can_turn_in_air():
			facing_direction = direction
			sprite.scale.x = direction
			small_sprite.scale.x = direction


	#Running.
	if Input.is_action_pressed("run"):
		if is_on_floor():
			movement_state = Movementstate.Run
		if character == Character.Mario:
			SPEED = 160.0
	else:
		if is_on_floor():
			movement_state = Movementstate.Walk
		if character == Character.Mario:
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
				if character == Character.Mario:
					mario_long_jump.play()

	if not is_on_floor() and movement_state == Movementstate.LongJump:
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			sprite.play("long jumping")
			small_sprite.play("long jumping")


	#Wall Sliding/Jumping.
	if is_on_wall() and direction != 0 and not is_on_ceiling_only() and not holding_item and not is_on_floor():
		wall_slide_and_jump()


	#Ground Pound and Dive
	if Input.is_action_just_pressed("ui_down") and not is_on_floor() and holding_item == false and movement_state != Movementstate.Dive:
		movement_state = Movementstate.Groundpound
	if movement_state == Movementstate.Groundpound:
		velocity.x = 0
		velocity.y = 500
		jump_limit = 0
		if Input.is_action_just_pressed("jump") and not is_on_floor() and movement_state == Movementstate.Groundpound:
			velocity.x = 350 * direction
			velocity.y = -100
			movement_state = Movementstate.Dive

	if is_on_floor() and movement_state == Movementstate.Groundpound and ground_pound_timer.is_stopped():
		ground_pound_timer.start()
	if ground_pound_timer.time_left > 0:
		movement_state = Movementstate.Groundpound

	move_and_slide()

	var just_landed = is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()


	if Input.is_action_just_pressed("ui_cut"):
		thanks_1.play()
		thanks_2.play()


	#sprite_2d.speed_scale = (velocity.x /50)

	#if movement_state == Movementstate.Groundpound:
		#print("print")

func wall_slide_and_jump():
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.y = clamp(velocity.y, -INF, 50)
	movement_state = Movementstate.Wallslide
	if Input.is_action_just_pressed("jump"):
		velocity.y = -300
		velocity.x = 200 * -direction
		movement_state = Movementstate.Jump
		facing_direction = -direction
		sprite.scale.x = facing_direction
		small_sprite.scale.x = facing_direction
		wall_jump_timer.start()
		wall_jump.play()
		if AudioManager.voice_toggle == true:
			mario_jump.play()


func _on_wall_jump_timer_timeout() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction*SPEED, 10)
	else:
		velocity.x = move_toward(velocity.x, 0, 20)

func damage():
	if powerup_state != Powerupstate.Small:
		powerup_state = Powerupstate.Small
		damage_timer.start()
		if character == Character.Mario:
			mario_hurt.play()
		sfx_damage.play()
		sfx_power_down.play()
		damaged = true
		_ready()
		$Sprite.modulate.a = 0.5
		$SmallSprite.modulate.a = 0.5
	else:
		if character == Character.Mario and Globals.shared_lives == false:
			Globals.mario_lives -= 1
		if Globals.shared_lives == true:
			Globals.lives -= 1
		get_tree().get_first_node_in_group("player_ui").update_hud()
		die()

func _on_damage_timer_timeout() -> void:
	damaged = false
	damage_timer.stop()
	$Sprite.modulate.a = 1
	$SmallSprite.modulate.a = 1

func die():
	sfx_damage.play()
	if ((character == Character.Mario and Globals.mario_lives <= 0) or (character == Character.Luigi and Globals.luigi_lives <= 0) or (character == Character.Toad and Globals.toad_lives <= 0) or (character == Character.Toadette and Globals.toadette_lives <= 0) or (character == Character.Peach and Globals.peach_lives <= 0) or (character == Character.Daisy and Globals.daisy_lives <= 0) and Globals.shared_lives == false) or Globals.lives <= 0 and Globals.shared_lives == true:
		sfx_die_final.play()
	else:
		sfx_die.play()

func can_turn_in_air() -> bool:
	return movement_state == Movementstate.Jump \
		or movement_state == Movementstate.Fall \
		or movement_state == Movementstate.Wallslide
