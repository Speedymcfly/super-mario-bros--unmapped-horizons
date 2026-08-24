class_name kotori
extends CharacterBody2D

@onready var plr = get_tree().get_first_node_in_group("player")
@onready var bird_sprite: AnimatedSprite2D = $BirdSprite
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var wing_flap: AudioStreamPlayer2D = $WingFlap
@onready var chirp: AudioStreamPlayer2D = $Chirp
@export var player_check_distance := 60.0
@export var respawn_margin := 128.0
@export var respawn_time := 5.0
@export var fly_speed := 140.0
@export var fly_up_strength := -120.0
@export var gravity := 700.0
@export var min_delay := 5.0
@export var max_delay := 15.0
var rng := RandomNumberGenerator.new()
var fly_direction := Vector2.ZERO
var doing_idle_action := false
var colour = [
	"white",
	"blue",
	"red",
	"yellow",
	"green"
]
# current chosen colour
var current_colour := "white"
var spawn_position: Vector2
var idle_timer := 0.0
var facing := 1
var has_been_visible := false
enum State{
	onground,
	pecking,
	hopping,
	turning,
	flying
}
var state:State = State.onground
func _ready() -> void:
	randomize()
	# save spawn position
	spawn_position = global_position
	# choose random colour
	randomize_colour()
	# start idle animation
	play_current_animation("idle")
	idle_timer = randf_range(1.0, 3.0)
	rng.randomize()
	play_randomly()
func play_randomly():
	while true:
		# Wait random amount of time
		await get_tree().create_timer(rng.randf_range(min_delay, max_delay)).timeout
		chirp.play()
		chirp.volume_db = rng.randf_range(-10.0, 0)
		await chirp.finished
func randomize_colour():
	current_colour = colour.pick_random()
func play_current_animation(anim: String):
	var anim_name = current_colour + "_" + anim
	# prevents animation restart spam
	if bird_sprite.animation != anim_name:
		bird_sprite.play(anim_name)
func _process(delta):
	if !is_instance_valid(plr):
		return
	var dist = global_position.distance_to(plr.global_position)
	if dist < player_check_distance and state != State.flying:
		fly_away()
func _physics_process(delta):
	# gravity
	if !is_on_floor() and state != State.flying:
		velocity.y += gravity * delta
	match state:
		State.onground:
			play_current_animation("idle")
			velocity.x = 0
			if !doing_idle_action:
				idle_timer -= delta
				if idle_timer <= 0:
					idle_timer = randf_range(1.0, 3.0)
					doing_idle_action = true
					var choice = randi_range(0, 2)
					match choice:
						0:
							await do_peck()
						1:
							await do_hop()
						2:
							await do_turn()
					doing_idle_action = false
		State.pecking:
			play_current_animation("peck")
			velocity.x = 0
		State.turning:
			play_current_animation("turn")
			velocity.x = 0
		State.hopping:
			play_current_animation("idle")
			# keep hop momentum
		State.flying:
			play_current_animation("flying")
			velocity.x = fly_direction.x * fly_speed
			# KEEP BIRD FLYING UPWARD
			velocity.y = fly_up_strength * 0.35
	# sprite facing
	if velocity.x > 0:
		facing = -1
	if velocity.x < 0:
		facing = 1
	bird_sprite.scale.x = facing
	move_and_slide()
	# despawn once offscreen
	if state == State.flying:
		if screen_notifier.is_on_screen():
			has_been_visible = true
		if has_been_visible and !screen_notifier.is_on_screen():
			despawn()
	if state != State.flying:
		set_collision_layer_value(2, true)
		set_collision_mask_value(1, true)
func fly_away():
	state = State.flying
	wing_flap.play()
	# direction AWAY from player
	fly_direction = (
		global_position - plr.global_position
	).normalized()
	velocity.x = fly_direction.x * fly_speed
	velocity.y = fly_up_strength
	# tiny randomness
	velocity.x += randf_range(-20, 20)
	velocity.y += randf_range(-15, 10)
	# disable collisions
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
func do_peck() -> void:
	if state != State.onground:
		return
	state = State.pecking
	play_current_animation("peck")
	await bird_sprite.animation_finished
	state = State.onground
func do_hop() -> void:
	if state != State.onground:
		return
	state = State.hopping
	velocity.y = -90
	velocity.x = facing * 25
	await get_tree().create_timer(0.35).timeout
	velocity.x = 0
	state = State.onground
func do_turn() -> void:
	if state != State.onground:
		return
	state = State.turning
	play_current_animation("turn")
	await bird_sprite.animation_finished
	facing *= -1
	state = State.onground
func despawn():
	visible = false
	set_process(false)
	set_physics_process(false)
	await get_tree().create_timer(respawn_time).timeout
	# wait until spawn point is fully offscreen
	while !spawn_point_is_offscreen():
		await get_tree().process_frame
	respawn()
func spawn_point_is_offscreen() -> bool:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return true
	var viewport_size = get_viewport_rect().size
	# actual visible screen rectangle
	var screen_rect = Rect2(camera.global_position - viewport_size * 0.5, viewport_size)
	# expand the screen bounds
	screen_rect = screen_rect.grow(respawn_margin)
	# TRUE only if spawn point is OUTSIDE expanded screen
	return !screen_rect.has_point(spawn_position)
func respawn():
	global_position = spawn_position
	velocity = Vector2.ZERO
	state = State.onground
	randomize_colour()
	has_been_visible = false
	visible = true
	set_process(true)
	set_physics_process(true)
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	play_current_animation("idle")
