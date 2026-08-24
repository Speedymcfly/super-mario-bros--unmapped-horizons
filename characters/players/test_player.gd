class_name player
extends CharacterBody2D

@onready var small_sprite: AnimatedSprite2D = $SmallSprite
@onready var small_sprite_2: AnimatedSprite2D = $SmallSprite2
@onready var big_sprite: AnimatedSprite2D = $BigSprite
@onready var big_sprite_2: AnimatedSprite2D = $BigSprite2
@onready var collision_small: CollisionShape2D = $CollisionSmall
@onready var collision_big: CollisionShape2D = $CollisionBig
@onready var dive_big: CollisionShape2D = $DiveBig
@onready var carry_detect: Area2D = $CarryDetect
@onready var carry_collision: CollisionShape2D = $CarryDetect/CarryCollision
@onready var sfx_wall_slide: AudioStreamPlayer2D = $SFXWallSlide
@onready var sfx_walk: AudioStreamPlayer2D = $SFXWalk
@onready var sfx_run: AudioStreamPlayer2D = $SFXRun
#Timers
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var freeze_timer: Timer = $FreezeTimer
@onready var damage_timer: Timer = $DamageTimer
@onready var ground_pound_timer: Timer = $GroundPoundTimer
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var toss_timer: Timer = $TossTimer
#Jump SFX
@onready var sfx_jump: AudioStreamPlayer2D = $SFXJump
@onready var wall_jump: AudioStreamPlayer2D = $WallJump

@onready var sfx_damage: AudioStreamPlayer2D = $SFXDamage
@onready var sfx_power_down: AudioStreamPlayer2D = $SFXPowerDown
@onready var sfx_die: AudioStreamPlayer2D = $SFXDie
@onready var sfx_die_final: AudioStreamPlayer2D = $SFXDieFinal
@onready var thanks_1: AudioStreamPlayer2D = $Thanks1
@onready var thanks_2: AudioStreamPlayer2D = $Thanks2

const FIREBALLORANGE = preload("res://objects/fireball_orange_plr.tscn")
const FIREBALLGREEN = preload("res://objects/fireball_green_plr.tscn")
const FIREBALLPINK = preload("res://objects/fireball_pink_plr.tscn")
var active_fireballs := 0
const MAX_FIREBALLS := 2
const ICEBALL = preload("res://objects/iceball_plr.tscn")
var active_iceballs := 0
const MAX_ICEBALLS := 2

var facing_direction := 1
var knockback_direction := 0
var current_held_obj: Node = null
var current_carried_obj: Node = null
var carrying = false
var SPEED = 70.0
var JUMP_VELOCITY = -360
var jump_limit = 0
var jump_timer = 0
var triple_jump = false

const MAX_POWER_METER := 6.0
var power_full = false
var power = 0

var bump = false

var was_on_floor = false
var float_timer = 0.0
var float_used = false
var midair_jump = 1

var voicerandomizer = 1

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
	Jumpthree,
	Crouchjump,
	Longjump,
	Fall,
	Wallslide,
	Groundpound,
	Dive,
	Knockback,
	Swim,
	Shell,
	Swimshell,
	Airfloat
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

@export_enum(
	"Any",
	"Mario",
	"Luigi",
	"Toad",
	"Toadette",
	"Peach",
	"Daisy"
)
var locked_character = "Any"

var holding_item = false
var power_speed = false

var invincible = false
var invincible_timer = 0

var frozen = false
var damaged = false

func _ready() -> void:
	var path := "res://characters/players/%s%s%s.tres" % [
		Powerupstate.keys()[powerup_state],
		Character.keys()[character],
		Variant.keys()[variant]
	]
	small_sprite.sprite_frames = load(path)
	small_sprite_2.sprite_frames = load(path)
	big_sprite.sprite_frames = load(path)
	big_sprite_2.sprite_frames = load(path)
	if powerup_state == Powerupstate.Small:
		$BigSprite.hide()
		$BigSprite2.hide()
		if character == Character.Mario:
			$SmallSprite.show()
			$SmallSprite2.hide()
		else:
			$SmallSprite.hide()
			$SmallSprite2.show()
	elif character in [Character.Mario, Character.Toad, Character.Toadette]:
		$BigSprite.show()
		$BigSprite2.hide()
		$SmallSprite.hide()
		$SmallSprite2.hide()
	else:
		$BigSprite.hide()
		$BigSprite2.show()
		$SmallSprite.hide()
		$SmallSprite2.hide()

	if version == "Modern":
		variant = Variant.Modern
	else:
		variant = Variant.Retro

	if character != Character.Mario:
		locked_character = "Mario"
	if character != Character.Luigi:
		locked_character = "Luigi"
	if character != Character.Toad:
		locked_character = "Toad"
	if character != Character.Toadette:
		locked_character = "Toadette"
	if character != Character.Peach:
		locked_character = "Peach"
	if character != Character.Daisy:
		locked_character = "Daisy"
	z_index = 1
func _process(delta):
	if voicerandomizer == 1:
		voicerandomizer += 1
	else:
		voicerandomizer -= 1
func _physics_process(delta: float) -> void:
	handle_carrying()
	if Input.is_action_just_pressed("ui_copy"):
		if character != Character.Daisy:
			character += 1
		else:
			character = Character.Mario
		_ready()
		get_tree().get_first_node_in_group("player_ui").update_hud()

	if current_held_obj == null or current_carried_obj == null:
		holding_item = false
	elif current_held_obj != null or current_carried_obj != null:
		holding_item = true
	#if current_carried_obj == null and toss_timer.is_stopped():
		#toss_timer.start()
	#Fireball shoot
	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Fire and movement_state not in [Movementstate.Groundpound, Movementstate.Dive, Movementstate.Knockback] and !carrying:
		if active_fireballs >= MAX_FIREBALLS:
			return
		AudioManager.play_sfx(load("res://assets/audio/SFX/Fireball.wav"), -12)
		if character == Character.Luigi:
			var fireball = FIREBALLGREEN.instantiate()
			if Input.is_action_pressed("ui_up"):
				fireball.global_position = global_position + Vector2(16 * facing_direction, -8)
			else:
				fireball.global_position = global_position + Vector2(16 * facing_direction, 0)
			fireball.direction = facing_direction
			fireball.direction = facing_direction
			# Count this fireball
			active_fireballs += 1
			# When fireball disappears, reduce count
			fireball.tree_exited.connect(func():active_fireballs -= 1)
			get_parent().add_child(fireball)
		elif character in [Character.Toadette, Character.Peach]:
			var fireball = FIREBALLPINK.instantiate()
			if Input.is_action_pressed("ui_up"):
				fireball.global_position = global_position + Vector2(16 * facing_direction, -8)
			else:
				fireball.global_position = global_position + Vector2(16 * facing_direction, 0)
			fireball.direction = facing_direction
			# Count this fireball
			active_fireballs += 1
			# When fireball disappears, reduce count
			fireball.tree_exited.connect(func():active_fireballs -= 1)
			get_parent().add_child(fireball)
		else:
			var fireball = FIREBALLORANGE.instantiate()
			if Input.is_action_pressed("ui_up"):
				fireball.global_position = global_position + Vector2(16 * facing_direction, -8)
			else:
				fireball.global_position = global_position + Vector2(16 * facing_direction, 0)
			fireball.direction = facing_direction
			# Count this fireball
			active_fireballs += 1
			# When fireball disappears, reduce count
			fireball.tree_exited.connect(func():active_fireballs -= 1)
			get_parent().add_child(fireball)
	#Iceball shoot
	if Input.is_action_just_pressed("run") and powerup_state == Powerupstate.Ice and movement_state not in [Movementstate.Groundpound, Movementstate.Dive, Movementstate.Knockback] and !carrying:
		if active_iceballs >= MAX_ICEBALLS:
			return
		AudioManager.play_sfx(load("res://assets/audio/SFX/Iceball.wav"), -10)
		var iceball = ICEBALL.instantiate()
		if Input.is_action_pressed("ui_up"):
			iceball.global_position = global_position + Vector2(16 * facing_direction, -8)
		else:
			iceball.global_position = global_position + Vector2(16 * facing_direction, 0)
		iceball.direction = facing_direction
		# Count this iceball
		active_iceballs += 1
		# When iceeball disappears, reduce count
		iceball.tree_exited.connect(func():active_iceballs -= 1)
		get_parent().add_child(iceball)
	#falling
	if movement_state not in [Movementstate.Groundpound, Movementstate.Dive, Movementstate.Jumpthree, Movementstate.Airfloat, Movementstate.Longjump, Movementstate.Knockback, Movementstate.Crouchjump]:
		if velocity.y > 0:
			movement_state = Movementstate.Fall

	if powerup_state == Powerupstate.Small:
		collision_small.set_deferred("disabled", false)
		collision_big.set_deferred("disabled", true)
		dive_big.set_deferred("disabled", true)
	else:
		if movement_state == Movementstate.Dive:
			collision_big.set_deferred("disabled", true)
			dive_big.set_deferred("disabled", false)
		else:
			if movement_state not in [Movementstate.Crouch, Movementstate.Crouchjump]:
				collision_big.set_deferred("disabled", false)
				collision_small.set_deferred("disabled", true)
			else:
				collision_big.set_deferred("disabled", true)
				collision_small.set_deferred("disabled", false)
			dive_big.set_deferred("disabled", true)


	#if (velocity.x > 1 || velocity.x < -1):
	if abs(velocity.x) > 1:
		if Input.is_action_pressed("run"):
			big_sprite.play("running")
			big_sprite_2.play("running")
			small_sprite.play("running")
			small_sprite_2.play("running")
		else:
			big_sprite.play("walking")
			big_sprite_2.play("walking")
			small_sprite.play("walking")
			small_sprite_2.play("walking")
	else:
		big_sprite.play("idle")
		big_sprite_2.play("idle")
		small_sprite.play("idle")
		small_sprite_2.play("idle")
	#walking SFX
	#if is_on_floor() and movement_state == Movementstate.Walk and not sfx_walk.playing and velocity.x != 0:
		#sfx_walk.play()
	#Running SFX
	#if is_on_floor() and movement_state == Movementstate.Run and not sfx_run.playing:
		#sfx_run.play()
	# Add the gravity.
	if !is_on_floor():
		if movement_state != Movementstate.Airfloat:
			velocity += get_gravity() * delta
		velocity.y = clamp(velocity.y, -INF, 500)

	if movement_state == Movementstate.Jump or movement_state == Movementstate.Jumpthree:
		if holding_item == false:
			big_sprite.play("jumping")
			big_sprite_2.play("jumping")
			small_sprite.play("jumping")
			small_sprite_2.play("jumping")
	if movement_state == Movementstate.Dive:
		big_sprite.play("diving")
		big_sprite_2.play("diving")
		small_sprite.play("diving")
		small_sprite_2.play("diving")
	if (is_on_floor() or is_on_wall()) and jump_limit == 0:
		triple_jump = false

	#Character Jump Height.
	if character == Character.Mario:
		JUMP_VELOCITY = -360
	if character == Character.Luigi:
		JUMP_VELOCITY = -400
	if character == Character.Toad:
		JUMP_VELOCITY = -260
	if character == Character.Toadette:
		JUMP_VELOCITY = -360
	if character == Character.Peach:
		JUMP_VELOCITY = -360
	if character == Character.Daisy:
		JUMP_VELOCITY = -360

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 0 and movement_state not in [Movementstate.Crouch, Movementstate.Groundpound] and !bump:
		if movement_state == Movementstate.Run and not velocity.x == 0:
			velocity.y = JUMP_VELOCITY -40
		else:
			velocity.y = JUMP_VELOCITY
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump2.wav"), -15)
			if character == Character.Luigi:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump2.wav"), -15)
		jump_limit += 1
		movement_state = Movementstate.Jump
		triple_jump = false
	elif Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 1 and !bump:
		velocity.y = JUMP_VELOCITY -60
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump2.wav"), -15)
			if character == Character.Luigi:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump2.wav"), -15)
		jump_limit += 1
		movement_state = Movementstate.Jump
	elif Input.is_action_just_pressed("jump") and is_on_floor() and jump_limit == 2 and !bump and !holding_item:
		velocity.y = JUMP_VELOCITY -90
		sfx_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioThirdJump.wav"), -15)
			if character == Character.Luigi:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiThirdJump.wav"), -15)
		jump_limit -= 2
		triple_jump = true

	#Third Jump Flip Activate
	if !is_on_floor() and movement_state not in [
		Movementstate.Groundpound,
		Movementstate.Dive,
		Movementstate.Airfloat,
		Movementstate.Longjump,
		Movementstate.Wallslide,
		Movementstate.Crouchjump
	]:
		if triple_jump and !holding_item:
			movement_state = Movementstate.Jumpthree
		else:
			movement_state = Movementstate.Jump

	#Third Jump Flip
	if movement_state == Movementstate.Jumpthree:
		small_sprite.rotation += .3 * facing_direction
		small_sprite_2.rotation += .3 * facing_direction
		big_sprite.rotation += .3 * facing_direction
		big_sprite_2.rotation += .3 * facing_direction
		collision_big.rotation += .3 * facing_direction
	else:
		small_sprite.rotation = 0
		small_sprite_2.rotation = 0
		big_sprite.rotation = 0
		big_sprite_2.rotation = 0
		collision_big.rotation = 0

	if is_on_floor() or movement_state == Movementstate.Wallslide:
		jump_timer += 1
		if jump_timer >= 15:
			jump_limit = 0
			jump_timer = 0
	else:
		jump_timer = 0


	if not Input.is_action_pressed("run") and Input.is_action_just_pressed("jump"):
		jump_limit -= 1
	if holding_item and Input.is_action_just_pressed("jump"):
		jump_limit -= 1
	if is_on_ceiling():
		jump_limit = 0
	if jump_timer <= 0:
		jump_timer = 0



	if Input.is_action_just_released("jump") and movement_state != Movementstate.Airfloat:
		velocity.y /= 2

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if movement_state not in [
		Movementstate.Knockback,
		Movementstate.Groundpound,
	]:
		if not wall_jump_timer.time_left > 0.0:
			if direction:
				velocity.x = move_toward(velocity.x, direction * SPEED, 10)
			else:
				velocity.x = move_toward(velocity.x, 0, 20)


# Facing (ground only)
	if direction != 0 and movement_state != Movementstate.Knockback:
		if is_on_floor() or can_turn_in_air():
			facing_direction = direction
			small_sprite.scale.x = direction
			small_sprite_2.scale.x = direction
			big_sprite.scale.x = direction
			big_sprite_2.scale.x = direction
	#Running.
	if Input.is_action_pressed("run"):
		if is_on_floor() and !bump:
			movement_state = Movementstate.Run
		if character == Character.Mario:
			SPEED = 160.0
		if character == Character.Luigi:
			SPEED = 160.0
		if character == Character.Toad:
			SPEED = 180.0
		if character == Character.Toadette:
			SPEED = 140.0
		if character == Character.Peach:
			SPEED = 160.0
		if character == Character.Daisy:
			SPEED = 160.0
	else:
		if is_on_floor() and !bump:
			movement_state = Movementstate.Walk
		if character == Character.Mario:
			SPEED = 70.0
		if character == Character.Luigi:
			SPEED = 70.0
		if character == Character.Toad:
			SPEED = 90.0
		if character == Character.Toadette:
			SPEED = 60.0
		if character == Character.Peach:
			SPEED = 70.0
		if character == Character.Daisy:
			SPEED = 70.0

	#Crouching.
	if Input.is_action_pressed("ui_down") and is_on_floor() and movement_state not in [Movementstate.Groundpound, Movementstate.Knockback]:
		SPEED=0
		movement_state = Movementstate.Crouch
	if movement_state in [Movementstate.Crouch, Movementstate.Crouchjump]:
		small_sprite.animation = "crouching"
		small_sprite_2.animation = "crouching"
		big_sprite.animation = "crouching"
		big_sprite_2.animation = "crouching"
		if powerup_state == Powerupstate.Small:
			collision_small.position.y = 11
			collision_small.scale.y = 0.7
	else:
		collision_small.position.y = 9
		collision_small.scale.y = 1
	#Wall Sliding/Jumping.
	if is_on_wall() \
	and direction != 0 \
	and !is_on_ceiling_only() \
	and !holding_item \
	and !is_on_floor() \
	and movement_state != Movementstate.Knockback \
	and movement_state != Movementstate.Airfloat:
		wall_slide_and_jump()
	if movement_state == Movementstate.Wallslide and not sfx_wall_slide.playing:
		sfx_wall_slide.play()
	elif movement_state != Movementstate.Wallslide:
		sfx_wall_slide.stop()
	#Peach Mid-Air Float
	if character == Character.Peach:
		if !is_on_floor():
			# Start floating ONLY when falling + holding jump
			if movement_state != Movementstate.Airfloat:
				if velocity.y > 0 and Input.is_action_pressed("jump") and !float_used and !is_on_ceiling() and movement_state not in [Movementstate.Groundpound, Movementstate.Dive, Movementstate.Wallslide] and !bump:
					movement_state = Movementstate.Airfloat
		# While floating
			if movement_state == Movementstate.Airfloat:
				float_timer += delta
				# Apply gentle gravity instead of none
				velocity.y = 0
				# Limit float duration
				if float_timer >= 1.0:
					movement_state = Movementstate.Fall
					float_used = true
		# Cancel float
		if Input.is_action_just_released("jump"):
			if movement_state == Movementstate.Airfloat:
				movement_state = Movementstate.Fall
# Reset on landing
	if is_on_floor():
		float_timer = 0.0
		float_used = false
	if Input.is_action_just_released("jump"):
		if movement_state == Movementstate.Airfloat:
			movement_state = Movementstate.Fall
	#Daisy Double Jump
	if character == Character.Daisy and Input.is_action_just_pressed("jump") and midair_jump == 1 and !is_on_floor() and !is_on_wall() and movement_state not in [Movementstate.Dive, Movementstate.Groundpound, Movementstate.Wallslide] and !bump:
		midair_jump -= 1
		velocity.y = -300
		sfx_jump.play()
		movement_state = Movementstate.Jump
	if is_on_floor():
		midair_jump = 1
	#Long Jump.
	if Input.is_action_just_pressed("jump") and movement_state == Movementstate.Crouch and is_on_floor() and !bump:
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			movement_state = Movementstate.Longjump
			velocity.x = 350 * direction
			velocity.y = -250
			sfx_jump.play()
			if AudioManager.voice_toggle == true:
				if character == Character.Mario:
					if voicerandomizer == 1:
						AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioLongJump1.wav"), -22)
					else:
						AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioLongJump2.wav"), -22)
				if character == Character.Luigi:
					if voicerandomizer == 1:
						AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiLongJump1.wav"), -15)
					else:
						AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiLongJump2.wav"), -15)
		else:
			movement_state = Movementstate.Crouchjump
			velocity.y = JUMP_VELOCITY
			sfx_jump.play()
	if not is_on_floor() and movement_state == Movementstate.Longjump and !bump:
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			small_sprite.play("long jumping")
			small_sprite_2.play("long jumping")
			big_sprite.play("long jumping")
			big_sprite_2.play("long jumping")
	#Ground Pound and Dive
	# Ground Pound Start
	if (
		Input.is_action_just_pressed("ui_down")
		and !is_on_floor()
		and !holding_item
		and !bump
		and movement_state not in [
			Movementstate.Dive,
			Movementstate.Groundpound,
			Movementstate.Wallslide
		]
	):
		movement_state = Movementstate.Groundpound
	# Ground Pound Active
	if movement_state == Movementstate.Groundpound:
		velocity.x = 0
		velocity.y = 500
		jump_limit = 0
		move_and_slide()
		# LANDING DETECTION MUST HAPPEN AFTER move_and_slide()
		if is_on_floor():
			if ground_pound_timer.is_stopped():
				ground_pound_timer.start()
		# Dive cancel
		elif Input.is_action_just_pressed("jump"):
			velocity.x = 350 * direction
			velocity.y = -100
			movement_state = Movementstate.Dive
		return
	if is_on_floor() and movement_state == Movementstate.Groundpound:
		if ground_pound_timer.is_stopped():
			ground_pound_timer.start()
	if ground_pound_timer.time_left > 0:
		movement_state = Movementstate.Groundpound
	move_and_slide()
	#Knockback
	if movement_state in [Movementstate.Dive, Movementstate.Longjump] \
	and is_on_wall() \
	and movement_state != Movementstate.Knockback \
	and movement_state != Movementstate.Wallslide:
		knockback()
	if movement_state == Movementstate.Knockback and is_on_floor() and knockback_timer.is_stopped() and bump:
		knockback_timer.start()
	if movement_state == Movementstate.Knockback:
		velocity.x = move_toward(velocity.x, 0, 5)
	if bump == true:
		movement_state = Movementstate.Knockback
		SPEED = 0
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
		movement_state = Movementstate.Jump
		velocity.y = -300
		velocity.x = 200 * -direction
		movement_state = Movementstate.Jump
		facing_direction = -direction
		small_sprite.scale.x = facing_direction
		small_sprite_2.scale.x = facing_direction
		big_sprite.scale.x = facing_direction
		big_sprite_2.scale.x = facing_direction
		wall_jump_timer.start()
		wall_jump.play()
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioJump2.wav"), -15)
			if character == Character.Luigi:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiJump2.wav"), -15)

func knockback():
	bump = true
	# lock direction opposite of facing
	knockback_direction = -facing_direction
	velocity.x = 220 * knockback_direction
	velocity.y = -120
	movement_state = Movementstate.Knockback
	sfx_damage.play()
	if AudioManager.voice_toggle:
		if character == Character.Mario:
			if voicerandomizer == 1:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioDamage1.wav"), -15)
			else:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioDamage2.wav"), -15)
		if character == Character.Luigi:
			if voicerandomizer == 1:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiDamage1.wav"), -15)
			else:
				AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiDamage2.wav"), -15)
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
		if AudioManager.voice_toggle == true:
			if character == Character.Mario:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioDamage1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Mario/MarioDamage2.wav"), -15)
			if character == Character.Luigi:
				if voicerandomizer == 1:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiDamage1.wav"), -15)
				else:
					AudioManager.mario_voice(load("res://assets/audio/SFX/Luigi/LuigiDamage2.wav"), -15)
		sfx_damage.play()
		sfx_power_down.play()
		damaged = true
		_ready()
		$SmallSprite.modulate.a = 0.5
		$SmallSprite2.modulate.a = 0.5
		$BigSprite.modulate.a = 0.5
		$BigSprite2.modulate.a = 0.5
	else:
		if character == Character.Mario and Globals.shared_lives == false:
			Globals.mario_lives -= 1
		if Globals.shared_lives == true:
			Globals.lives -= 1
		if ((character == Character.Mario and Globals.mario_lives > -1) or (character == Character.Luigi and Globals.luigi_lives > -1) or (character == Character.Toad and Globals.toad_lives > -1) or (character == Character.Toadette and Globals.toadette_lives > -1) or (character == Character.Peach and Globals.peach_lives > -1) or (character == Character.Daisy and Globals.daisy_lives > -1) and Globals.shared_lives == false) or (Globals.lives > -1 and Globals.shared_lives == true):
			get_tree().get_first_node_in_group("player_ui").update_hud()
		die()

func _on_damage_timer_timeout() -> void:
	damaged = false
	damage_timer.stop()
	$SmallSprite.modulate.a = 1
	$SmallSprite2.modulate.a = 1
	$BigSprite.modulate.a = 1
	$BigSprite2.modulate.a = 1
func die():
	sfx_damage.play()
	if ((character == Character.Mario and Globals.mario_lives <= 0) or (character == Character.Luigi and Globals.luigi_lives <= 0) or (character == Character.Toad and Globals.toad_lives <= 0) or (character == Character.Toadette and Globals.toadette_lives <= 0) or (character == Character.Peach and Globals.peach_lives <= 0) or (character == Character.Daisy and Globals.daisy_lives <= 0) and Globals.shared_lives == false) or (Globals.lives <= 0 and Globals.shared_lives == true):
		sfx_die_final.play()
	else:
		sfx_die.play()
func can_turn_in_air() -> bool:
	return movement_state == Movementstate.Jump \
		or movement_state == Movementstate.Fall \
		or movement_state == Movementstate.Wallslide \
		or movement_state == Movementstate.Airfloat 
func _on_knockback_timer_timeout() -> void:
	bump = false
	movement_state = Movementstate.Fall
func _on_ground_pound_timer_timeout() -> void:
	if movement_state == Movementstate.Groundpound:
		movement_state = Movementstate.Walk
func handle_carrying():
	if Input.is_action_just_pressed("run"):
		# IF ALREADY CARRYING
		if current_carried_obj:
			if Input.is_action_pressed("ui_down"):
				current_carried_obj.drop(facing_direction)
			else:
				current_carried_obj.throw(facing_direction)
				AudioManager.play_sfx(load("res://assets/audio/SFX/Throw.wav"), -10)
			current_carried_obj = null
			toss_timer.start()
		# OTHERWISE PICK UP
		else:
			if Input.is_action_pressed("ui_down"):
				for body in $CarryDetect.get_overlapping_bodies():
					if body.is_in_group("frozen_carriable"):
						current_carried_obj = body
						body.pick_up(self)
						AudioManager.play_sfx(load("res://assets/audio/SFX/Pickup.wav"), -10)
						carrying = true
						break

func _on_toss_timer_timeout() -> void:
	carrying = false

func freeze():
	frozen = true
func unfreeze():
	frozen = false
func _on_freeze_timer_timeout() -> void:
	
	damage()
